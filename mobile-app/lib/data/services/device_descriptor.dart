import 'package:harrier_central/imports.dart';

/// What the app knows about the phone it is running on, in the five fields
/// HC.LaunchAndLogin records — one reading, shared by the two calls that
/// write a login row. hcapp_approveLogin (every launch) built these inline;
/// hcapp_authorizeDevice (redeeming an invite code, the FIRST row a new
/// account ever writes) sent none of them, so a brand-new member's first
/// sign-in showed as `<no HC version>` with no device, and read like a web
/// sign-in in the portal's login list (James, 2026-10-12). Both now send
/// the same five, from here.
class DeviceDescriptor {
  const DeviceDescriptor({
    required this.deviceType,
    required this.deviceName,
    required this.systemName,
    required this.systemVersion,
    required this.manufacturer,
  });

  final String deviceType;
  final String deviceName;
  final String systemName;
  final String systemVersion;
  final String manufacturer;

  static Future<DeviceDescriptor> read() async {
    final DeviceInfoPlugin plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo a = await plugin.androidInfo;
        return DeviceDescriptor(
          deviceType: '${a.model} / device: ${a.device}',
          deviceName: '<unknown>',
          systemName: a.host,
          systemVersion:
              '${a.version.sdkInt} / release: ${a.version.release} / security patch: ${a.version.securityPatch ?? '<no Android security patch'}',
          manufacturer: a.brand,
        );
      }
      if (Platform.isIOS) {
        final IosDeviceInfo i = await plugin.iosInfo;
        return DeviceDescriptor(
          deviceType: i.model,
          deviceName: i.name,
          systemName: i.systemName,
          systemVersion: i.systemVersion,
          manufacturer: 'Apple',
        );
      }
    } catch (_) {
      // A plugin failure must not stop a sign-in; the row just says unknown.
    }
    return const DeviceDescriptor(
      deviceType: 'unknown',
      deviceName: 'unknown',
      systemName: 'unknown',
      systemVersion: 'unknown',
      manufacturer: 'unknown',
    );
  }

  /// The five fields as the request body carries them — the same keys for
  /// both stored procedures, which declare the same five parameters.
  Map<String, String> toParams() => <String, String>{
    'deviceType': deviceType,
    'deviceName': deviceName,
    'systemName': systemName,
    'systemVersion': systemVersion,
    'manufacturer': manufacturer,
  };
}
