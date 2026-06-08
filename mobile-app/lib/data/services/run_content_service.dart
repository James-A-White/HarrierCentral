import 'package:harrier_central/imports.dart';

class RunContentService {
  Future<HashTrashModel?> getHashTrash({
    required String kennelId,
    required String eventId,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'getHashTrash',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_getHashTrash',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
      }),
    );

    if (result.startsWith(ERROR_PREFIX)) return null;

    try {
      final List<dynamic> rowsets = jsonDecode(result) as List<dynamic>;
      if (rowsets.isEmpty || (rowsets[0] as List).isEmpty) return null;
      return HashTrashModel.fromJson((rowsets[0] as List)[0] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveHashTrash({
    required String kennelId,
    required String eventId,
    required String headline,
    required String content,
    required int status,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'saveHashTrash',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_saveHashTrash',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
        'headline': headline,
        'content': content,
        'status': status,
      }),
    );

    return !result.startsWith(ERROR_PREFIX);
  }

  Future<String?> addDownDown({
    required String kennelId,
    required String eventId,
    required List<String> hasherIds,
    required String chargeText,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'addDownDown',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_addDownDown',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
        'hasherIds': hasherIds.join(','),
        'chargeText': chargeText,
      }),
    );

    if (result.startsWith(ERROR_PREFIX)) return null;

    try {
      final List<dynamic> rowsets = jsonDecode(result) as List<dynamic>;
      if (rowsets.isEmpty || (rowsets[0] as List).isEmpty) return null;
      return ((rowsets[0] as List)[0] as Map<String, dynamic>)['downDownId'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<({List<DownDownModel> downDowns, List<DownDownHasherModel> hashers})?> getDownDowns({
    required String kennelId,
    required String eventId,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'getDownDowns',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_getDownDowns',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
      }),
    );

    if (result.startsWith(ERROR_PREFIX)) return null;

    try {
      final List<dynamic> rowsets = jsonDecode(result) as List<dynamic>;
      final downDownRows = rowsets.isNotEmpty ? rowsets[0] as List<dynamic> : <dynamic>[];
      final hasherRows = rowsets.length > 1 ? rowsets[1] as List<dynamic> : <dynamic>[];

      final downDowns = downDownRows
          .map((r) => DownDownModel.fromJson(r as Map<String, dynamic>))
          .toList();
      final hashers = hasherRows
          .map((r) => DownDownHasherModel.fromJson(r as Map<String, dynamic>))
          .toList();

      return (downDowns: downDowns, hashers: hashers);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateDownDown({
    required String kennelId,
    required String eventId,
    required String downDownId,
    required String chargeText,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'updateDownDown',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_updateDownDown',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
        'downDownId': downDownId,
        'chargeText': chargeText,
      }),
    );

    return !result.startsWith(ERROR_PREFIX);
  }

  Future<bool> markDownDownDone({
    required String kennelId,
    required String eventId,
    required String downDownId,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'markDownDownDone',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_markDownDownDone',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
        'downDownId': downDownId,
      }),
    );

    return !result.startsWith(ERROR_PREFIX);
  }

  Future<bool> cancelDownDown({
    required String kennelId,
    required String eventId,
    required String downDownId,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'cancelDownDown',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_cancelDownDown',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
        'downDownId': downDownId,
      }),
    );

    return !result.startsWith(ERROR_PREFIX);
  }

  Future<bool> unmarkDownDownDone({
    required String kennelId,
    required String eventId,
    required String downDownId,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'unmarkDownDownDone',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_unmarkDownDownDone',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
        'downDownId': downDownId,
      }),
    );

    return !result.startsWith(ERROR_PREFIX);
  }

  Future<bool> uncancelDownDown({
    required String kennelId,
    required String eventId,
    required String downDownId,
  }) async {
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'uncancelDownDown',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          getStringPref(StringPrefsEnum.userId) ?? '',
          'hcapp_uncancelDownDown',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
        'downDownId': downDownId,
      }),
    );

    return !result.startsWith(ERROR_PREFIX);
  }
}
