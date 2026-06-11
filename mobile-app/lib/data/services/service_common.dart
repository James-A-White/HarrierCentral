import 'package:harrier_central/imports.dart';

//int httpCounter = 1000;

class ServiceCommon {
  // the variable below is there to suppress a warning about defining classes with only static members
  int? unusedVariableToSuppressWarning;

  /// Redacts sensitive fields from a JSON request body before it is written to
  /// BootLogger. Prevents accessToken, deviceId, and deviceSecret from being
  /// persisted in plain-text log storage on the device.
  static String _redactBody(String body) {
    return body
        .replaceAll(
          RegExp(r'"accessToken":"[^"]*"'),
          '"accessToken":"[REDACTED]"',
        )
        .replaceAll(
          RegExp(r'"deviceId":"[^"]*"'),
          '"deviceId":"[REDACTED]"',
        )
        .replaceAll(
          RegExp(r'"deviceSecret":"[^"]*"'),
          '"deviceSecret":"[REDACTED]"',
        );
  }

  static const int _maxRetryAttempts = 6;
  static const int _baseBackoffMs = 500;
  static final Random _retryRandom = Random();

  // Per-request timeout. If a single POST stalls longer than this the call is
  // treated as a non-retryable connection failure (status 0) so the caller
  // moves on instead of hanging forever. 30 s covers slow Azure cold-starts
  // while still preventing the infinite-boot-hang on partially-connected networks.
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Sends a session-level error log to HC.ClientErrorLog on the server.
  /// Token validation is skipped server-side so this can be called even when
  /// the device secret is unavailable.
  static Future<void> recordClientErrorLog(String errorLog) async {
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';

    final String body = jsonEncode(<String, String>{
      'queryType': 'logClientErrors',
      'deviceId': deviceId,
      'accessToken': '<not required>',
      'errorLog': errorLog,
    });

    await post(
      Uri.parse(BASE_AF_API_URL),
      headers: <String, String>{'content-type': 'application/json'},
      body: body,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => Response('', 408),
    ).catchError((dynamic error) {
      return Future<Response>.value(Response('', 500));
    });
  }

  // [bodyFactory] is called once per attempt so the access token embedded in
  // the body is always freshly generated at the moment the POST fires.  This
  // prevents "Invalid Access Token" errors when iOS suspends the Dart isolate
  // while the app is backgrounded, causing queued requests to arrive at the
  // server outside their 30-second token window.
  static Future<String> sendHttpPost(
    String Function() bodyFactory, {
    Function? errorCallback,
    Client? client,
    bool bypassConnectionCheck = false,
    bool noRetries = false,
  }) async {
    // if the connection check is bypassed, it is because we are doing an initial
    // connection check
    if ((!bypassConnectionCheck) && Utilities.isNotConnected()) {
      return ERROR_NO_CONNECTION;
    }

    // print('>>> http post $httpCounter $requestBody');
    // httpCounter++;
    final int maxAttempts = noRetries ? 1 : _maxRetryAttempts;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final String requestBody = bodyFactory();
      final Response response = await _postWithClient(
        requestBody,
        client: client,
      );

      final bool hasErrorId = response.body.contains('"errorId"');
      final bool isSuccess =
          (response.statusCode >= 200) &&
          (response.statusCode < 300) &&
          !hasErrorId;

      if (isSuccess) {
        return response.body;
      }

      // Remote DB errors are not retried to avoid repeating side effects.
      if (hasErrorId) {
        return checkHttpPostResponse(
          response,
          requestBody,
          errorCallback: errorCallback,
        );
      }

      final bool isRetryable = _isRetryableStatus(response.statusCode);
      final bool isLastAttempt = attempt == maxAttempts;

      if (!isRetryable) {
        return checkHttpPostResponse(
          response,
          requestBody,
          errorCallback: errorCallback,
        );
      }

      if (isLastAttempt) {
        _showSnackbarSafely(
          title: response.statusCode == 0
              ? 'Request Timed Out'
              : 'Connection Issue',
          message: response.statusCode == 0
              ? 'The server took too long to respond. Please try again.'
              : 'Unable to connect. Please check your connection.',
          backgroundColor: hc_red,
        );

        return checkHttpPostResponse(
          response,
          requestBody,
          errorCallback: errorCallback,
        );
      }

      BootLogger.logError(
        '[ERROR][HTTP]',
        'Retry $attempt failed: ${response.statusCode} → $BASE_AF_API_URL\nBody: ${_redactBody(requestBody)}\nResponse: ${response.body}',
        null,
      );

      if (attempt == 3) {
        _showSnackbarSafely(
          title: 'Reconnecting',
          message: 'Experiencing connection issues, retrying…',
          backgroundColor: hc_blue,
          duration: const Duration(seconds: 4),
        );
      }

      final Duration delay = _computeBackoffDelay(attempt);
      await Future<void>.delayed(delay);
    }

    // Should never reach here; return a sensible default.
    return ERROR_UNKNOWN_HTTP_ERROR;
  }

  static Future<Response> _postWithClient(
    String requestBody, {
    Client? client,
  }) async {
    if (client == null) {
      return post(
            Uri.parse(BASE_AF_API_URL),
            headers: <String, String>{'content-type': 'application/json'},
            body: requestBody,
          )
          .timeout(
            _requestTimeout,
            // Status 0 = our internal "request timed out" sentinel.
            // _isRetryableStatus treats 0 as non-retryable so a hung request
            // fails fast instead of burning all 6 retry slots at 30 s each.
            onTimeout: () => Response('', 0),
          )
          .catchError((dynamic error) {
            BootLogger.logError('[ERROR][HTTP]', 'network error → $BASE_AF_API_URL: ${error.toString()}\nBody: ${_redactBody(requestBody)}', null);
            return Future<Response>.value(Response('', 500));
          });
    }

    return client
        .post(
          Uri.parse(BASE_AF_API_URL),
          headers: <String, String>{'content-type': 'application/json'},
          body: requestBody,
        )
        .timeout(_requestTimeout, onTimeout: () => Response('', 0))
        .catchError((dynamic error) {
          BootLogger.logError('[ERROR][HTTP]', 'network error → $BASE_AF_API_URL: ${error.toString()}\nBody: ${_redactBody(requestBody)}', null);
          return Future<Response>.value(Response('', 500));
        });
  }

  static bool _isRetryableStatus(int statusCode) {
    // 0 = our request-timed-out sentinel — don't retry, fail fast.
    if (statusCode == 0) return false;
    if (statusCode == 408 || statusCode == 429) return true;
    if (statusCode >= 500) return true;
    return false;
  }

  static Duration _computeBackoffDelay(int attempt) {
    final int baseMs = _baseBackoffMs * (1 << (attempt - 1));
    final double jitterFactor =
        0.25 + (_retryRandom.nextDouble() * 1.5); // 25%-175% => 75% jitter band
    final int delayMs = (baseMs * jitterFactor).round();
    return Duration(milliseconds: delayMs);
  }

  static BuildContext? _snackbarContext() {
    return Get.context ?? Get.overlayContext ?? Get.key.currentContext;
  }

  static void _showSnackbarSafely({
    required String title,
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 5),
  }) {
    void show() {
      Get.closeAllSnackbars();
      Get.showSnackbar(
        GetSnackBar(
          title: title,
          message: message,
          duration: duration,
          backgroundColor: backgroundColor,
        ),
      );
    }

    if (_snackbarContext() != null) {
      show();
      return;
    }

    // During bootstrap there may be no GetX context yet; retry next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_snackbarContext() != null) {
        show();
      }
    });
  }

  /// Removes the write-SP success envelope (rowset 0) from a response before
  /// it reaches the data ingestion engine.
  ///
  /// Write SPs return [[{"success":1,...}], [data…], …].  The base ingestion
  /// engine does not recognise the success envelope and logs debug warnings for
  /// it.  Read SPs return [[{data}],…] with no envelope — those are returned
  /// unchanged.
  static String stripSuccessEnvelope(String responseBody) {
    if (!responseBody.startsWith('[[{"success"') &&
        !responseBody.startsWith('[[{"Success"')) {
      return responseBody;
    }
    try {
      final List<dynamic> rowsets = jsonDecode(responseBody) as List<dynamic>;
      if (rowsets.length <= 1) return responseBody;
      rowsets.removeAt(0);
      return jsonEncode(rowsets);
    } catch (_) {
      return responseBody;
    }
  }

  // ── Migration note ────────────────────────────────────────────────────────
  // [checkHttpPostResponse] predates [ServiceResult] and returns raw String
  // sentinel values (ERROR_UNKNOWN_HTTP_ERROR, ERROR_HANDLED, etc.). Existing
  // callers depend on this string-based contract.
  //
  // For NEW service methods, prefer [ServiceResult<T>] instead:
  //
  //   Future<ServiceResult<MyModel>> fetchSomething() async {
  //     final body = await sendHttpPost(...);
  //     if (body.startsWith('ERROR')) {
  //       return ServiceResult.failure(body);
  //     }
  //     return ServiceResult.success(MyModel.fromJson(jsonDecode(body)));
  //   }
  //
  // See lib/data/models/service_result.dart for the full API.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<String> checkHttpPostResponse(
    Response response,
    String requestBody, {
    Function? errorCallback,
  }) async {
    String returnValue = ERROR_UNKNOWN_HTTP_ERROR;

    // Check for an SP-level error before checking HTTP status. AppApiHC6 returns
    // 400 for SP errors, so checking status first would swallow the errorCallback.
    if (response.body.contains('"errorId"')) {
      BootLogger.logError(
        '[ERROR][HTTP]',
        '${response.statusCode} ${response.reasonPhrase ?? ""} → $BASE_AF_API_URL\nBody: ${_redactBody(requestBody)}\nResponse: ${response.body}',
        null,
      );
      returnValue = ERROR_UNKNOWN_REMOTE_DB_ERROR;

      // AppApiHC6 returns SP errors in two formats:
      //   1. Flat object  {"errorType":N,"errorUserMessage":"...","errorId":"..."}
      //      (produced by the shim's HC6 error detection reading rowset 0)
      //   2. Nested rowsets [[{...}],[{...}]] for 200 responses with SP errors
      final dynamic decoded = json.decode(response.body);
      Map<String, dynamic> errorRow;

      if (decoded is List) {
        final rowsets = decoded;
        final firstRowset = rowsets.isNotEmpty
            ? (rowsets[0] as List<dynamic>)
            : <dynamic>[];
        Map<String, dynamic> firstRow = firstRowset.isNotEmpty
            ? (firstRowset[0] as Map<String, dynamic>)
            : <String, dynamic>{};
        // HC6 write SPs: rowset 0 is the success envelope {success, errorCode, errorType};
        // human-readable detail is at rowset 1. Redirect when detected.
        if (firstRow.containsKey('success') &&
            firstRow['success'] == 0 &&
            rowsets.length > 1) {
          final secondRowset = rowsets[1] as List<dynamic>;
          errorRow = secondRowset.isNotEmpty
              ? secondRowset[0] as Map<String, dynamic>
              : firstRow;
        } else {
          errorRow = firstRow;
        }
      } else if (decoded is Map<String, dynamic>) {
        // Flat object from AppApiHC6's error detection — errorType is present,
        // errorUserMessage/errorId may be null if read from the wrong rowset.
        errorRow = decoded;
      } else {
        errorRow = <String, dynamic>{};
      }

      final DbErrorModel errorResult = DbErrorModel.fromJson(errorRow);

      if (errorCallback != null) {
        final bool errorCallbackResult = await errorCallback(errorResult);
        returnValue = errorCallbackResult ? ERROR_HANDLED : ERROR_NOT_HANDLED;
      } else {
        final bool alertResult =
            (await Utilities.showAlert(
              errorResult.errorTitle ?? '',
              (errorResult.errorUserMessage ?? '').replaceAll('~', '\r\n'),
              'Quit',
            )) ??
            false;

        returnValue = alertResult
            ? ERROR_KEY_OK_BTN_PRESSED
            : ERROR_KEY_CANCEL_BTN_PRESSED;
      }
    } else if ((response.statusCode < 200) || (response.statusCode >= 300)) {
      if (response.reasonPhrase == 'Site Disabled') {
        await Utilities.showAlert(
          'Down for Maintenance',
          'The Harrier Central server is temporarily offline for maintenance.\r\n\r\nYou may continue using the app in Offline Mode with cached data. Press the \'Offline Mode\' ribbon to find out when the last time the data was updated.',
          'Use Offline',
        );
        BootLogger.logError(
          '[ERROR][HTTP]',
          'Site Disabled: ${response.statusCode} ${response.reasonPhrase ?? ""} → $BASE_AF_API_URL\nBody: ${_redactBody(requestBody)}\nResponse: ${response.body}',
          null,
        );
      } else {
        BootLogger.logError(
          '[ERROR][HTTP]',
          '${response.statusCode} ${response.reasonPhrase ?? ""} → $BASE_AF_API_URL\nBody: ${_redactBody(requestBody)}\nResponse: ${response.body}',
          null,
        );

        // Network-level failures (timeout, server error): run the full backend
        // check so the ribbon reflects the correct state. Only show a snackbar
        // if the backend is confirmed reachable — i.e. the error was transient.
        // Application errors (4xx) are not connectivity issues; always snackbar.
        final isNetworkFailure = response.statusCode == 0 ||
            response.statusCode == 408 ||
            response.statusCode >= 500;

        if (isNetworkFailure) {
          await networkService.handleApiFailure();
          if (networkService.backendReachable.value) {
            _showSnackbarSafely(
              title: 'Unknown Server Error',
              message: response.reasonPhrase ?? ' - ${response.body}',
              backgroundColor: hc_blue,
            );
          }
        } else {
          _showSnackbarSafely(
            title: 'Unknown Server Error',
            message: response.reasonPhrase ?? ' - ${response.body}',
            backgroundColor: hc_blue,
          );
        }
      }
    } else {
      returnValue = response.body;
    }

    return returnValue;
  }
}
