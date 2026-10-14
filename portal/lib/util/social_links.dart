import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// A kennel's social and chat links (E12.F4.S4, James 2026-10-10): one
/// entry of HC.Kennel.SocialLinksJson / the request's SocialLinksJson.
///
/// THE SAME platform → hosts list as HC6.SocialLinksProblem
/// (db/schema/functions), SocialLinks in api/Endpoints/
/// KennelFromWebsite.cs, the app's mobile-app/lib/util/social_links.dart and
/// the web's public-web/lib/social-links.ts. Change all five together.
class SocialLink {
  SocialLink({required this.platform, this.url, this.handle, this.qrImageUrl, this.label, String? audience})
    : audience = audience ?? (socialMembersByDefault.contains(platform) ? 'members' : 'public');

  factory SocialLink.fromJson(Map<String, dynamic> j) => SocialLink(
    platform: (j['platform'] as String?) ?? 'other',
    url: j['url'] as String?,
    handle: j['handle'] as String?,
    qrImageUrl: j['qrImageUrl'] as String?,
    label: j['label'] as String?,
    audience: j['audience'] as String?,
  );

  String platform;
  String? url;
  String? handle;
  String? qrImageUrl;
  String? label;

  /// 'public' or 'members'.
  String audience;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'platform': platform,
    'url': (url ?? '').trim().isEmpty ? null : url!.trim(),
    'handle': (handle ?? '').trim().isEmpty ? null : handle!.trim(),
    'qrImageUrl': qrImageUrl,
    'label': (label ?? '').trim().isEmpty ? null : label!.trim(),
    'audience': audience,
  };

  /// What is wrong with this link, or null — the same rules the SP applies.
  String? get problem {
    if (platform.isEmpty) return 'Choose a platform';
    final String u = (url ?? '').trim();
    if (u.isEmpty) {
      if (platform == 'wechat' && ((handle ?? '').trim().isNotEmpty || qrImageUrl != null)) return null;
      return platform == 'wechat' ? 'WeChat needs an ID or a QR image' : 'Paste the ${socialPlatformLabel(platform)} address';
    }
    final Uri? parsed = Uri.tryParse(u);
    if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) return 'The address must start with https://';
    if (platform == 'other') return (label ?? '').trim().isEmpty ? 'Give the link a name' : null;
    if (socialPlatformOf(parsed.host) != platform) {
      return 'That address is not ${socialPlatformLabel(platform)} (${parsed.host})';
    }
    return null;
  }
}

/// Every platform, in the order the picker shows them, with its label and the
/// hosts its links may point to.
const List<(String, String, List<String>)> socialPlatforms = [
  ('facebook', 'Facebook', ['facebook.com', 'fb.com', 'fb.me']),
  ('instagram', 'Instagram', ['instagram.com']),
  ('whatsapp', 'WhatsApp', ['whatsapp.com', 'wa.me']),
  ('signal', 'Signal', ['signal.group', 'signal.me']),
  ('telegram', 'Telegram', ['t.me', 'telegram.me']),
  ('wechat', 'WeChat', ['weixin.qq.com', 'wechat.com']),
  ('line', 'LINE', ['line.me', 'lin.ee']),
  ('kakaotalk', 'KakaoTalk', ['kakao.com']),
  ('zalo', 'Zalo', ['zalo.me']),
  ('viber', 'Viber', ['viber.com']),
  ('discord', 'Discord', ['discord.gg', 'discord.com']),
  ('strava', 'Strava', ['strava.com', 'strava.app.link']),
  ('meetup', 'Meetup', ['meetup.com']),
  ('x', 'X (Twitter)', ['x.com', 'twitter.com']),
  ('tiktok', 'TikTok', ['tiktok.com']),
  ('youtube', 'YouTube', ['youtube.com', 'youtu.be']),
  ('threads', 'Threads', ['threads.net', 'threads.com']),
  ('bluesky', 'Bluesky', ['bsky.app']),
  ('reddit', 'Reddit', ['reddit.com']),
  ('mailinglist', 'Mailing list', ['groups.google.com', 'groups.io']),
  ('other', 'Other', <String>[]),
];

/// Chat-group invite links are what spammers harvest: members-only by default.
const Set<String> socialMembersByDefault = {
  'whatsapp', 'signal', 'telegram', 'wechat', 'line', 'kakaotalk', 'zalo', 'viber', 'discord',
};

String socialPlatformLabel(String platform) =>
    socialPlatforms.firstWhere((p) => p.$1 == platform, orElse: () => (platform, platform, const <String>[])).$2;

String? socialPlatformOf(String host) {
  final String h = host.toLowerCase();
  for (final (String id, _, List<String> hosts) in socialPlatforms) {
    if (hosts.any((x) => h == x || h.endsWith('.$x'))) return id;
  }
  return null;
}

/// The platform's brand logo (Font Awesome 5 Brands, as the app uses);
/// Material stand-ins where FA5 has none. '' = no platform chosen yet.
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

/// The platform's brand colour (the same values as the app).
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
  'x' || 'tiktok' || 'threads' => const Color(0xFF000000),
  'youtube' => const Color(0xFFFF0000),
  'bluesky' => const Color(0xFF1185FE),
  'reddit' => const Color(0xFFFF4500),
  _ => const Color(0xFF455A64),
};

List<SocialLink> socialLinksFromJson(String? json) {
  if (json == null || json.trim().isEmpty) return <SocialLink>[];
  try {
    final Object? v = jsonDecode(json);
    if (v is! List) return <SocialLink>[];
    return v.whereType<Map<String, dynamic>>().map(SocialLink.fromJson).toList();
  } on Object {
    return <SocialLink>[];
  }
}

String? socialLinksToJson(List<SocialLink> links) =>
    links.isEmpty ? '' : jsonEncode(links.map((l) => l.toJson()).toList());
