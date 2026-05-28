// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter/foundation.dart' as foundation;
import 'package:hcportal/imports.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;

class ServiceCommon {
  static Future<String> uploadFile(
    List<int> bytes,
    String uniqueId,
    String fileTypeName,
    UiControlType controlType, {
    String? filenamePrefix,
    String? filenameExtension,
  }) async {
    // NOTE: If we run into errors testing this locally, run the following command in the flutter terminal
    // fluttercors --disable
    // then when you are done editing, run this command
    // fluttercors --enable

    var fileExtension = '';

    final headers = <String, String>{
      'x-ms-blob-type': 'BlockBlob',
      'Access-Control-Allow-Origin': '*',
    };

    if (filenameExtension != null) {
      fileExtension = filenameExtension;
      headers['content-type'] = switch (filenameExtension) {
        'png' => 'image/png',
        'avif' => 'image/avif',
        _ => 'image/jpeg',
      };
    } else if (controlType == UiControlType.imageUpload) {
      fileExtension = 'jpg';
      headers['content-type'] = 'image/jpeg';
    } else if (controlType == UiControlType.pdfUpload) {
      fileExtension = 'pdf';
      headers['content-type'] = 'application/pdf';
    }

    return uploadData(
      uniqueId,
      fileTypeName,
      fileExtension,
      headers,
      bytes,
      filenamePrefix: filenamePrefix,
    );
  }

  static Future<String> uploadData(
    String publicEventId,
    String fileTypeName,
    String fileExtension,
    Map<String, String> headers,
    List<int> bytes, {
    String? filenamePrefix,
  }) async {
    final datetime = intl.DateFormat('yyyyMMddkkmmss').format(DateTime.now());
    final prefix = filenamePrefix ?? 'dos_';

    final bool isKennelLogo = fileTypeName == DocumentType.kennelLogo.name;
    final bool isNewsflashImage =
        fileTypeName == DocumentType.newsflashImage.name;
    final bool isKennelWebsiteImage =
        fileTypeName == DocumentType.kennelWebsiteBanner.name ||
        fileTypeName == DocumentType.kennelWebsiteBackground.name ||
        fileTypeName == DocumentType.kennelWebsiteOgImage.name;

    final String fileName = (isKennelLogo || isNewsflashImage || isKennelWebsiteImage)
        ? '$prefix$datetime.$fileExtension'
        : '$prefix${publicEventId}_${fileTypeName}_$datetime.$fileExtension';

    final String container = isNewsflashImage
        ? 'newsflash'
        : (isKennelLogo || isKennelWebsiteImage)
            ? 'harrier'
            : 'event-images';

    // Get portal credentials from Hive (box is already open at app start)
    final box = Hive.box(HIVE_NAME);
    final deviceId = (box.get(HIVE_DEVICE_ID) as String?) ?? '';
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getPortalUploadSas',
      paramString: deviceSecret,
    );

    // Request a short-lived SAS token from the server
    http.Response sasResponse;
    try {
      sasResponse = await http
          .post(
            Uri.parse(BASE_GET_PORTAL_UPLOAD_SAS_URL),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'deviceId': deviceId,
              'accessToken': accessToken,
              'container': container,
              'filename': fileName,
            }),
          )
          .timeout(const Duration(seconds: DEFAULT_HTTP_TIMEOUT));
    } on Exception catch (error) {
      if (foundation.kDebugMode) {
        debugPrint('GetPortalUploadSas request error: $error');
      }
      await CoreUtilities.showAlert(
        'Upload failed',
        'The file was unable to be uploaded at this time. Please try again later.',
        'OK',
      );
      return '';
    }

    if (sasResponse.statusCode < 200 || sasResponse.statusCode >= 300) {
      await CoreUtilities.showAlert(
        'Upload failed',
        'The file was unable to be uploaded at this time. Please try again later.',
        'OK',
      );
      return '';
    }

    final String sasUrl;
    try {
      final sasJson = jsonDecode(sasResponse.body) as Map<String, dynamic>;
      sasUrl = sasJson['sasUrl'] as String;
    } on Exception {
      await CoreUtilities.showAlert(
        'Upload failed',
        'The file was unable to be uploaded at this time. Please try again later.',
        'OK',
      );
      return '';
    }

    http.Response response;
    try {
      response = await http.put(
        Uri.parse(sasUrl),
        headers: headers,
        body: Uint8List.fromList(bytes),
      );
    } on Exception catch (error) {
      if (foundation.kDebugMode) {
        debugPrint('Upload error: $error');
      }
      await CoreUtilities.showAlert(
        'Upload failed',
        'The file was unable to be uploaded at this time. Please try again later.',
        'OK',
      );
      return '';
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await CoreUtilities.showAlert(
        'Upload failed',
        'The file was unable to be uploaded at this time. Please try again later.',
        'OK',
      );
      return '';
    }

    return fileName;
  }

  // HC5 methods — commented out after full HC6 migration (2026-03-19)
  // static Future<String> sendHttpPostToAzureFunctionApiCached(
  //   String requestBody, {
  //   Function? errorCallback,
  // }) async {
  //   if (requestBody.contains('getLandingPageData')) {
  //     return landingPageData;
  //   }
  //   if (requestBody.contains('getEvents')) {
  //     return eventData;
  //   }
  //   if (requestBody.contains('getKennel')) {
  //     return kennelData;
  //   }
  //   return Future.value('');
  // }

  // static Future<String> sendHttpPostToAzureFunctionApi(
  //   Map<String, dynamic> requestBody,
  // ) async {
  //   try {
  //     final body = jsonEncode(requestBody);
  //     http.Response response;
  //     try {
  //       response = await http
  //           .post(
  //             Uri.parse(BASE_AF_API_URL),
  //             headers: <String, String>{
  //               'content-type': 'application/json',
  //               'Access-Control-Allow-Origin': '*',
  //             },
  //             body: body,
  //           )
  //           .timeout(const Duration(seconds: DEFAULT_HTTP_TIMEOUT));
  //     } on Exception catch (error) {
  //       if (foundation.kDebugMode) {
  //         debugPrint('HTTP error: $error');
  //       }
  //       return ERROR_UNKNOWN_HTTP_ERROR;
  //     }
  //     var returnValue = ERROR_UNKNOWN_HTTP_ERROR;
  //     if ((response.statusCode < 200) || (response.statusCode >= 300)) {
  //       returnValue = ERROR_UNKNOWN_HTTP_ERROR;
  //     } else {
  //       if (response.body.contains('"errorId"')) {
  //         returnValue = ERROR_UNKNOWN_REMOTE_DB_ERROR;
  //         final errorResult =
  //             IveDbUtilities.checkResultsForErrors(response.body);
  //         if (errorResult != null) {
  //           final alertResult = await IveCoreUtilities.showAlert(
  //                 navigatorKey.currentContext!,
  //                 errorResult.errorTitle,
  //                 errorResult.errorUserMessage,
  //                 'OK',
  //               ) ??
  //               true;
  //           returnValue = alertResult
  //               ? ERROR_KEY_OK_BTN_PRESSED
  //               : ERROR_KEY_CANCEL_BTN_PRESSED;
  //         }
  //       } else {
  //         returnValue = response.body;
  //       }
  //     }
  //     return returnValue;
  //   } on Exception catch (e) {
  //     if (foundation.kDebugMode) {
  //       debugPrint('sendHttpPostToAzureFunctionApi exception: $e');
  //     }
  //   }
  //   return ERROR_UNKNOWN_HTTP_ERROR;
  // }

  static Future<String> sendHttpPostToHC6Api(
    Map<String, dynamic> requestBody,
  ) async {
    try {
      final body = jsonEncode(requestBody);
      http.Response response;
      try {
        response = await http
            .post(
              Uri.parse(BASE_HC6_API_URL),
              headers: <String, String>{
                'content-type': 'application/json',
                'Access-Control-Allow-Origin': '*',
              },
              body: body,
            )
            .timeout(const Duration(seconds: DEFAULT_HTTP_TIMEOUT));
      } on Exception catch (error) {
        if (foundation.kDebugMode) {
          debugPrint('HTTP error: $error');
        }
        return ERROR_UNKNOWN_HTTP_ERROR;
      }

      if ((response.statusCode < 200) || (response.statusCode >= 300)) {
        // HC6 API returns 400 with {"success":false,"errorMessage":"..."} for SP errors
        if (response.body.isNotEmpty) {
          try {
            final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
            final errorMessage =
                errorJson['errorMessage'] as String? ?? 'An error occurred';
            await IveCoreUtilities.showAlert(
              navigatorKey.currentContext!,
              'Error',
              errorMessage,
              'OK',
            );
            return ERROR_KEY_OK_BTN_PRESSED;
          } on Exception {
            // body wasn't JSON — fall through to generic error
          }
        }
        return ERROR_UNKNOWN_HTTP_ERROR;
      }

      return response.body;
    } on Exception catch (e) {
      if (foundation.kDebugMode) {
        debugPrint('sendHttpPostToHC6Api exception: $e');
      }
    }

    return ERROR_UNKNOWN_HTTP_ERROR;
  }
}
