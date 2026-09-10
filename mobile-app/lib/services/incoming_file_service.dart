import 'package:harrier_central/imports.dart';

/// A file the OS handed to the app — "Open in Harrier Central" from Files,
/// Mail or a file manager, or the iOS share extension (E5.F5.S6 tiers one and
/// two). The native side (ios/Runner/IncomingFileBridge.swift,
/// android MainActivity) copies it into the app's own cache and passes the
/// path over `harrier_central/incoming_file`; this service decides what to do
/// with it. Today the only kind of file we accept is GPX, so it opens the
/// import page.
///
/// Two arrival paths:
///  * The app was already running: native pushes `incomingFile(path)` and
///    the page opens at once.
///  * The file launched the app: native keeps it pending; boot calls
///    [flushPending] once the main page is up and a user is logged in.
/// A file that arrives before login is kept until [flushPending] is called.
class IncomingFileService extends GetxService {
  static const MethodChannel _channel = MethodChannel(
    'harrier_central/incoming_file',
  );

  static IncomingFileService ensure() {
    if (Get.isRegistered<IncomingFileService>()) {
      return Get.find<IncomingFileService>();
    }
    return Get.put(IncomingFileService(), permanent: true);
  }

  String? _pendingPath;

  /// True once boot has reached the main page with a signed-in user, so an
  /// incoming file can be acted on immediately.
  bool _ready = false;

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'incomingFile') {
        final String? path = call.arguments as String?;
        if (path != null && path.isNotEmpty) await _receive(path);
      }
      return null;
    });
  }

  /// Called by boot once the main page is showing for a signed-in user: takes
  /// anything native held from a cold start, plus anything that arrived
  /// before we were ready, and opens it.
  Future<void> flushPending() async {
    _ready = true;
    String? path = _pendingPath;
    _pendingPath = null;
    try {
      path ??= await _channel.invokeMethod<String>('takePending');
    } on MissingPluginException {
      // Desktop / test host: no native side.
    } catch (e, s) {
      BootLogger.logError('[IncomingFileService.flushPending]', e, s);
    }
    if (path != null && path.isNotEmpty) await _receive(path);
  }

  Future<void> _receive(String path) async {
    if (!_ready || currentUserId.isEmpty) {
      _pendingPath = path;
      return;
    }
    BootLogger.logBreadcrumb('Incoming file: $path');
    if (!path.toLowerCase().endsWith('.gpx')) {
      await Utilities.showAlert(
        'Not a GPX file',
        'Harrier Central can only import GPX track files.',
        'OK',
      );
      return;
    }
    final BuildContext? ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      _pendingPath = path;
      return;
    }
    await Navigator.push<dynamic>(
      ctx,
      MaterialPageRoute<dynamic>(
        settings: const RouteSettings(),
        builder: (BuildContext context) => ImportGpxPage(initialFilePath: path),
      ),
    );
  }
}
