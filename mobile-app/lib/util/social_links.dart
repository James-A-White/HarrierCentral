import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A kennel's social and chat links (E12.F4.S4, James 2026-10-10): one entry
/// of HC.Kennel.SocialLinksJson, as handed to this caller by
/// HC6.hcapp_getKennelSocialLinks. Read-only in the app — the portal edits.
///
/// THE SAME platform → label → hosts list lives in FIVE places. Change all of
/// them together:
///   - portal/lib/util/social_links.dart
///   - db/schema/functions/HC6.SocialLinksProblem.Function.sql
///   - api/Endpoints/KennelFromWebsite.cs
///   - public-web/lib/social-links.ts
///   - this file
///
/// Not synced on purpose: the kennels table goes to every phone, and the
/// members-only entries are chat-group invite links, so the SP hands them out
/// per caller when the kennel page opens.
class SocialLink {
  const SocialLink({
    required this.platform,
    this.url,
    this.handle,
    this.qrImageUrl,
    this.label,
    this.audience = 'public',
  });

  /// Tolerant of missing and wrongly-typed fields. A missing audience takes
  /// the platform's default ([socialMembersByDefault]) — the same rule as
  /// HC6.KennelSocialLinksVisible and the portal, so the lock badge agrees
  /// with what the server decided.
  factory SocialLink.fromJson(Map<String, dynamic> j) {
    String? s(String k) {
      final Object? v = j[k];
      if (v is! String) return null;
      final String t = v.trim();
      return t.isEmpty ? null : t;
    }

    final String platform = (s('platform') ?? 'other').toLowerCase();
    final String? audience = s('audience');
    return SocialLink(
      platform: platform,
      url: s('url'),
      handle: s('handle'),
      qrImageUrl: s('qrImageUrl'),
      label: s('label'),
      audience: switch (audience) {
        'members' => 'members',
        'public' => 'public',
        _ => socialMembersByDefault.contains(platform) ? 'members' : 'public',
      },
    );
  }

  final String platform;
  final String? url;

  /// A WeChat ID (WeChat groups have no shareable URL).
  final String? handle;

  /// A QR image to scan (WeChat), shown whole.
  final String? qrImageUrl;

  /// The kennel's own name for it ("Run chat"), or null.
  final String? label;

  /// 'public' or 'members'.
  final String audience;

  bool get isMembersOnly => audience == 'members';

  /// What the icon's tooltip and screen reader say: the kennel's label, then
  /// the platform ("Run chat (WhatsApp)").
  String get displayName {
    final String p = socialPlatformLabel(platform);
    final String? l = label;
    if (l == null || l == p) return p;
    return platform == 'other' ? l : '$l ($p)';
  }

  /// True when tapping opens a dialog (WeChat ID / QR) rather than a link.
  bool get opensDialog => url == null;

  SocialLink _withoutUrl() => SocialLink(
    platform: platform,
    handle: handle,
    qrImageUrl: qrImageUrl,
    label: label,
    audience: audience,
  );

  SocialLink _withoutQr() => SocialLink(
    platform: platform,
    url: url,
    handle: handle,
    label: label,
    audience: audience,
  );
}

/// Every platform, in the order the portal picker shows them, with its label
/// and the hosts its links may point to. 'other' takes any https host.
const List<(String, String, List<String>)> socialPlatforms =
    <(String, String, List<String>)>[
      ('facebook', 'Facebook', <String>['facebook.com', 'fb.com', 'fb.me']),
      ('instagram', 'Instagram', <String>['instagram.com']),
      ('whatsapp', 'WhatsApp', <String>['whatsapp.com', 'wa.me']),
      ('signal', 'Signal', <String>['signal.group', 'signal.me']),
      ('telegram', 'Telegram', <String>['t.me', 'telegram.me']),
      ('wechat', 'WeChat', <String>['weixin.qq.com', 'wechat.com']),
      ('line', 'LINE', <String>['line.me', 'lin.ee']),
      ('kakaotalk', 'KakaoTalk', <String>['kakao.com']),
      ('zalo', 'Zalo', <String>['zalo.me']),
      ('viber', 'Viber', <String>['viber.com']),
      ('discord', 'Discord', <String>['discord.gg', 'discord.com']),
      ('strava', 'Strava', <String>['strava.com', 'strava.app.link']),
      ('meetup', 'Meetup', <String>['meetup.com']),
      ('x', 'X (Twitter)', <String>['x.com', 'twitter.com']),
      ('tiktok', 'TikTok', <String>['tiktok.com']),
      ('youtube', 'YouTube', <String>['youtube.com', 'youtu.be']),
      ('threads', 'Threads', <String>['threads.net', 'threads.com']),
      ('bluesky', 'Bluesky', <String>['bsky.app']),
      ('reddit', 'Reddit', <String>['reddit.com']),
      ('mailinglist', 'Mailing list', <String>[
        'groups.google.com',
        'groups.io',
      ]),
      ('other', 'Other', <String>[]),
    ];

/// Chat-group invite links are what spammers harvest: the portal makes these
/// members-only by default — and so is an entry of theirs with no audience
/// (the same rule as the portal and HC6.KennelSocialLinksVisible).
const Set<String> socialMembersByDefault = <String>{
  'whatsapp',
  'signal',
  'telegram',
  'wechat',
  'line',
  'kakaotalk',
  'zalo',
  'viber',
  'discord',
};

String socialPlatformLabel(String platform) {
  for (final (String id, String label, _) in socialPlatforms) {
    if (id == platform) return label;
  }
  return platform;
}

/// The platform a host belongs to (exact host or a subdomain of it), or null.
String? socialPlatformOf(String host) {
  final String h = host.toLowerCase();
  for (final (String id, _, List<String> hosts) in socialPlatforms) {
    if (hosts.any((String x) => h == x || h.endsWith('.$x'))) return id;
  }
  return null;
}

bool _isKnownPlatform(String platform) =>
    socialPlatforms.any(((String, String, List<String>) p) => p.$1 == platform);

/// An https URL with a host, or null.
Uri? _httpsUri(String? raw) {
  if (raw == null) return null;
  final Uri? u = Uri.tryParse(raw);
  if (u == null || u.scheme.toLowerCase() != 'https' || u.host.isEmpty) {
    return null;
  }
  return u;
}

/// The entry as safe to show, or null to drop it. The SP passes the stored
/// entries through unchanged, so the app checks again what the portal and
/// HC6.SocialLinksProblem check on save: a link the app will open must be
/// https and point at its own platform's hosts. An old row, a hand edit or a
/// future platform must never turn an icon labelled WhatsApp into a link to
/// somewhere else.
SocialLink? _vetted(SocialLink l) {
  if (!_isKnownPlatform(l.platform)) return null;
  SocialLink link = l;
  // A QR image is only ever shown, never opened — but it is still fetched,
  // so it must be https too.
  if (link.qrImageUrl != null && _httpsUri(link.qrImageUrl) == null) {
    link = link._withoutQr();
  }
  final Uri? u = _httpsUri(link.url);
  final bool urlOk =
      u != null &&
      (link.platform == 'other' || socialPlatformOf(u.host) == link.platform);
  if (urlOk) return link;
  // WeChat groups have no URL: an ID and/or a QR image is the whole entry.
  if (link.platform == 'wechat' &&
      (link.handle != null || link.qrImageUrl != null)) {
    return link._withoutUrl();
  }
  return null;
}

/// The links to show, in stored order. Defensive: null, empty or broken JSON
/// is an empty list, and an entry that fails [_vetted] is dropped.
List<SocialLink> socialLinksFromJson(String? json) {
  if (json == null || json.trim().isEmpty) return const <SocialLink>[];
  try {
    final Object? v = jsonDecode(json);
    if (v is! List) return const <SocialLink>[];
    return v
        .whereType<Map<String, dynamic>>()
        .map(SocialLink.fromJson)
        .map(_vetted)
        .whereType<SocialLink>()
        .toList(growable: false);
  } on Object {
    return const <SocialLink>[];
  }
}

/// The platform's own mark where the app's icon font (Font Awesome 5 Brands,
/// via flutter_vector_icons 2.0.0) has one. Signal has its own drawn glyph
/// (MessagingPlatformGlyph) and is handled by the widget, not here. FA5 has no
/// X, KakaoTalk, Zalo, Threads or Bluesky mark: X uses the Twitter bird, the
/// rest fall back to Material icons.
IconData socialPlatformIcon(String platform) => switch (platform) {
  'facebook' => FontAwesome5Brands.facebook,
  'instagram' => FontAwesome5Brands.instagram,
  'whatsapp' => FontAwesome5Brands.whatsapp,
  'telegram' => FontAwesome5Brands.telegram,
  'wechat' => FontAwesome5Brands.weixin,
  'line' => FontAwesome5Brands.line,
  'viber' => FontAwesome5Brands.viber,
  'discord' => FontAwesome5Brands.discord,
  'strava' => FontAwesome5Brands.strava,
  'meetup' => FontAwesome5Brands.meetup,
  'x' => FontAwesome5Brands.twitter,
  'tiktok' => FontAwesome5Brands.tiktok,
  'youtube' => FontAwesome5Brands.youtube,
  'reddit' => FontAwesome5Brands.reddit,
  'signal' || 'kakaotalk' || 'zalo' => Icons.chat_outlined,
  'threads' || 'bluesky' => Icons.alternate_email,
  'mailinglist' => Icons.mail_outline,
  _ => Icons.link,
};

/// The platform's brand colour, for the glyph on its white disc.
Color socialPlatformColor(String platform) => switch (platform) {
  'facebook' => const Color(0xFF1877F2),
  'instagram' => const Color(0xFFE4405F),
  'whatsapp' => const Color(0xFF25D366),
  'signal' => const Color(0xFF3A76F0),
  'telegram' => const Color(0xFF26A5E4),
  'wechat' => const Color(0xFF07C160),
  'line' => const Color(0xFF06C755),
  'kakaotalk' => const Color(0xFF3C1E1E),
  'zalo' => const Color(0xFF0068FF),
  'viber' => const Color(0xFF7360F2),
  'discord' => const Color(0xFF5865F2),
  'strava' => const Color(0xFFFC4C02),
  'meetup' => const Color(0xFFED1C40),
  'x' => const Color(0xFF000000),
  'tiktok' => const Color(0xFF000000),
  'youtube' => const Color(0xFFFF0000),
  'threads' => const Color(0xFF000000),
  'bluesky' => const Color(0xFF1185FE),
  'reddit' => const Color(0xFFFF4500),
  _ => const Color(0xFF455A64),
};
