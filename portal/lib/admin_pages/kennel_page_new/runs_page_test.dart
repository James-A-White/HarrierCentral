import 'package:hcportal/imports.dart';
import 'package:http/http.dart' as http;

/// The kennel editor's runs-page Test (2026-10-04). Reads the page at [url]
/// right now — the address in the editor, saved or not — and shows every run
/// the reader found and what importing would do to it. Nothing is written
/// until the admin presses "Import these runs".
Future<void> showRunsPageTest({
  required String publicKennelId,
  required String url,
}) async {
  final RxBool busy = true.obs;
  final Rxn<Map<String, dynamic>> result = Rxn<Map<String, dynamic>>();
  final RxString error = ''.obs;

  Future<void> call({required bool import}) async {
    busy.value = true;
    error.value = '';
    try {
      final Map<String, dynamic> reply =
          await _runsPageTest(publicKennelId, url, import: import);
      if (reply['success'] == true) {
        result.value = reply;
      } else {
        error.value = '${reply['errorUserMessage'] ?? 'The test failed.'}';
      }
    } catch (e) {
      error.value = 'The test could not reach Harrier Central. Please try again.';
    }
    busy.value = false;
  }

  unawaited(call(import: false));

  await Get.dialog<void>(
    AlertDialog(
      title: const Text('Runs page test', textAlign: TextAlign.center),
      content: SizedBox(
        width: 760,
        child: Obx(() {
          final bool working = busy.value;
          final Map<String, dynamic>? r = result.value;
          final String err = error.value;
          if (working) {
            return const SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Reading the page… (up to half a minute)'),
                  ],
                ),
              ),
            );
          }
          if (err.isNotEmpty) {
            return Text(err, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red));
          }
          if (r == null) return const SizedBox.shrink();
          final List<dynamic> runs = (r['runs'] as List<dynamic>?) ?? <dynamic>[];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                r['imported'] == true ? 'Imported. ${r['status']}' : '${r['status']}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade800),
              ),
              const SizedBox(height: 10),
              if (runs.isEmpty)
                const Text(
                  'No runs were found on this page. Check the address points at the page that lists your upcoming runs.',
                  textAlign: TextAlign.center,
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 14,
                        headingRowHeight: 32,
                        dataRowMinHeight: 30,
                        dataRowMaxHeight: 64,
                        columns: const <DataColumn>[
                          DataColumn(label: Text('Run')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Time')),
                          DataColumn(label: Text('Hares')),
                          DataColumn(label: Text('Start')),
                          DataColumn(label: Text('Map')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Result')),
                        ],
                        rows: <DataRow>[
                          for (final dynamic run in runs)
                            if (run is Map)
                              DataRow(
                                cells: <DataCell>[
                                  DataCell(Text('#${run['number'] ?? '?'}')),
                                  DataCell(Text('${run['date'] ?? '—'}')),
                                  DataCell(Text('${run['time'] ?? '—'}')),
                                  DataCell(_wrap('${run['hares'] ?? '—'}')),
                                  DataCell(_wrap('${run['start'] ?? '—'}')),
                                  DataCell(Text(run['lat'] != null ? '✓' : '—')),
                                  DataCell(_wrap(<String>[
                                    if ((run['title'] ?? '').toString().isNotEmpty) '${run['title']}',
                                    if (run['special'] == true) '🎉 special',
                                  ].join(' · '))),
                                  DataCell(_outcome('${run['outcome'] ?? ''}')),
                                ],
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Runs your kennel already has in Harrier Central are never changed. '
                'Anything you edit on an imported run stays as you set it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
              ),
            ],
          );
        }),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        Obx(() {
          final Map<String, dynamic>? r = result.value;
          final bool canImport = !busy.value &&
              r != null &&
              r['imported'] != true &&
              ((r['counts']?['inserted'] ?? 0) as int) + ((r['counts']?['updated'] ?? 0) as int) > 0;
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: <Widget>[
              TextButton(
                style: hcDialogButtonStyle(hcDialogCancelColor),
                onPressed: () => Get.back<void>(),
                child: const Text('Close', textAlign: TextAlign.center),
              ),
              if (canImport)
                TextButton(
                  style: hcDialogButtonStyle(hcDialogPrimaryColor),
                  onPressed: () => unawaited(call(import: true)),
                  child: const Text('Import these runs', textAlign: TextAlign.center),
                ),
            ],
          );
        }),
      ],
    ),
    barrierDismissible: false,
  );
}

Widget _wrap(String text) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 180),
  child: Text(text, softWrap: true, maxLines: 3, overflow: TextOverflow.ellipsis),
);

Widget _outcome(String o) {
  final Color c = switch (o) {
    'new' => Colors.green.shade700,
    'update' => Colors.orange.shade800,
    'unchanged' => Colors.blueGrey,
    'already in Harrier Central' => Colors.blueGrey,
    _ => Colors.red.shade700,
  };
  return Text(o, style: TextStyle(color: c, fontWeight: FontWeight.w600));
}

Future<Map<String, dynamic>> _runsPageTest(
  String publicKennelId,
  String url, {
  required bool import,
}) async {
  final Box<dynamic> box = Hive.box(HIVE_NAME);
  final String deviceId = (box.get(HIVE_DEVICE_ID) as String?) ?? '';
  final String deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
  // Bound to the kennel, as every kennel-editor call is.
  final String accessToken = Utilities.generateToken(
    deviceId,
    'hcportal_runsPageTest',
    paramString: '$deviceSecret:${publicKennelId.toLowerCase()}',
  );
  final http.Response res = await http
      .post(
        Uri.parse(RUNS_PAGE_TEST_URL),
        headers: <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'deviceId': deviceId,
          'accessToken': accessToken,
          'publicKennelId': publicKennelId.toLowerCase(),
          'url': url,
          'import': import,
        }),
      )
      .timeout(const Duration(seconds: 90));
  try {
    return jsonDecode(res.body) as Map<String, dynamic>;
  } catch (_) {
    return <String, dynamic>{
      'success': false,
      'errorUserMessage': 'The test failed (${res.statusCode}).',
    };
  }
}
