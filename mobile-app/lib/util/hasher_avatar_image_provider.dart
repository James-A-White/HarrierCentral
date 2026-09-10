import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import 'package:harrier_central/util/avatar.dart';
import 'package:harrier_central/util/boot_logger.dart';
import 'package:harrier_central/util/constants.dart';
import 'package:harrier_central/services/network_meter.dart';

/// Loads a hasher's profile photo from the network (through the shared
/// `flutter_cache_manager` cache, like `CachedNetworkImageProvider`), and when
/// it cannot, shows the default bundled avatar instead of a blank or a raw
/// Flutter error box.
///
/// Every avatar in the app is resolved through `avatarImageProvider`, so doing
/// the fallback in the provider fixes every list, pin and profile page at once
/// without touching a call site — and works for `Image`, `CircleAvatar` and
/// `DecorationImage` alike, which have three different error hooks.
///
/// The fallback is the same in every case; what differs is what happens next:
///
///  * Storage answered **404 / 410** — the blob is gone. That is a fact about
///    the data, not this phone, so it is reported to the server
///    ([BrokenPhotoReporter]), which checks for itself and swaps the photo for
///    a bundled avatar in the database. The corrected row reaches every client
///    on its next sync. The fallback image is cached for the URL, since it
///    will never load.
///  * Anything else (no signal, timeout, a 5xx, a cached file that will not
///    decode) — probably this phone, probably transient. The fallback is shown
///    but NOT cached, so the next build tries the network again.
class HasherAvatarImageProvider
    extends ImageProvider<HasherAvatarImageProvider> {
  const HasherAvatarImageProvider(this.url, {this.scale = 1.0});

  final String url;
  final double scale;

  @override
  Future<HasherAvatarImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture<HasherAvatarImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    HasherAvatarImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: key.scale,
      debugLabel: url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<String>('URL', url),
      ],
    );
  }

  Future<ui.Codec> _load(
    HasherAvatarImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    if (BrokenPhotoReporter.isKnownMissing(url)) {
      return _defaultAvatarCodec(decode);
    }

    Uint8List? bytes;
    try {
      final File file = await DefaultCacheManager().getSingleFile(url);
      bytes = await file.readAsBytes();
    } catch (e) {
      if (BrokenPhotoReporter.isMissingBlob(e)) {
        // A server answer, not a network fault: the file is gone.
        unawaited(BrokenPhotoReporter.report(url));
      } else {
        _forgetSoon(key);
      }
      return _defaultAvatarCodec(decode);
    }

    try {
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (e) {
      // The bytes are not an image (an error page cached as one, a truncated
      // download). Drop the cached file so the next attempt refetches, and do
      // not pin the fallback in the image cache.
      unawaited(DefaultCacheManager().removeFile(url));
      _forgetSoon(key);
      return _defaultAvatarCodec(decode);
    }
  }

  /// Evicts this key from Flutter's in-memory image cache once the current
  /// resolve has settled, so the fallback image is shown now but the next
  /// build goes back to the network. Mirrors what the framework does for a
  /// provider that reports an error, without surfacing the error.
  void _forgetSoon(HasherAvatarImageProvider key) {
    scheduleMicrotask(() {
      PaintingBinding.instance.imageCache.evict(key);
    });
  }

  static Future<ui.Codec> _defaultAvatarCodec(
    ImageDecoderCallback decode,
  ) async {
    final ByteData data = await rootBundle.load(kDefaultAvatarAsset);
    return decode(
      await ui.ImmutableBuffer.fromUint8List(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HasherAvatarImageProvider &&
      other.url == url &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => 'HasherAvatarImageProvider("$url", scale: $scale)';
}

/// Tells the server about a profile photo whose blob storage says is gone.
///
/// The phone does not decide anything: the server HEADs the URL itself and
/// only replaces the photo (with a bundled avatar, via
/// `HC6.nonApi_replaceBrokenPhoto`) when storage confirms 404/410. So a bad
/// connection can never wipe a photo, and neither can a hostile client naming
/// somebody else's URL. Each URL is reported at most once per app session —
/// the fix arrives through the normal sync, after which the URL is no longer
/// in any row and is never asked for again.
class BrokenPhotoReporter {
  BrokenPhotoReporter._();

  static const Duration _timeout = Duration(seconds: 15);

  /// URLs reported this session (whatever the outcome) — no repeats.
  static final Set<String> _reported = <String>{};

  /// URLs the server confirmed missing this session: short-circuited to the
  /// default avatar without another network round trip.
  static final Set<String> _confirmedMissing = <String>{};

  /// True when [e] is storage saying the file does not exist (404 / 410) —
  /// as opposed to the phone failing to reach storage at all.
  static bool isMissingBlob(Object e) =>
      e is HttpExceptionWithStatus &&
      (e.statusCode == HttpStatus.notFound || e.statusCode == HttpStatus.gone);

  static bool isKnownMissing(String url) => _confirmedMissing.contains(url);

  /// Only our own profile-photos container is ever reported; the server
  /// refuses anything else, so do not bother it.
  static bool _isOurs(String url) =>
      url.toLowerCase().startsWith('$kAvatarBaseUrl/'.toLowerCase());

  @visibleForTesting
  static void resetForTest() {
    _reported.clear();
    _confirmedMissing.clear();
  }

  static Future<void> report(String url, {http.Client? httpClient}) async {
    if (!_isOurs(url) || !_reported.add(url)) return;

    final String requestBody = json.encode(<String, String>{'url': url});
    final Uri uri = Uri.parse(REPORT_BROKEN_PHOTO_URL);
    final Map<String, String> headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      'X-Api-Key': GET_POSITIONS_API_KEY,
    };
    final int started = NetworkMeter.begin(requestBody);
    try {
      final http.Response response =
          await (httpClient != null
                  ? httpClient.post(uri, headers: headers, body: requestBody)
                  : http.post(uri, headers: headers, body: requestBody))
              .timeout(_timeout);
      NetworkMeter.end(started, response);
      if (response.statusCode != 200) {
        BootLogger.logBreadcrumb(
          'Avatar: broken-photo report → HTTP ${response.statusCode} ($url)',
        );
        return;
      }
      final dynamic decoded = json.decode(response.body);
      final bool verified = decoded is Map && decoded['verified'] == true;
      if (verified) _confirmedMissing.add(url);
      BootLogger.logBreadcrumb(
        'Avatar: broken-photo report → verified=$verified '
        'status=${decoded is Map ? decoded['status'] : '?'} '
        'hasherRows=${decoded is Map ? decoded['hasherRows'] : '?'} ($url)',
      );
    } catch (e) {
      NetworkMeter.end(started, null);
      BootLogger.logBreadcrumb('Avatar: broken-photo report failed: $e ($url)');
    }
  }
}
