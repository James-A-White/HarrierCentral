// ignore_for_file: require_trailing_commas

import 'package:hcportal/imports.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;

class CheckinSheetController extends GetxController {
  CheckinSheetController({
    required this.publicKennelId,
    required this.kennelName,
    required this.kennelLogo,
  });

  String publicKennelId;
  String kennelName;
  String kennelLogo;

  RxDouble width = 0.0.obs;
  RxDouble height = 0.0.obs;

  int rowsPerColumn = 40;
  Rx<pdf_lib.PdfPageFormat> pageFormat = pdf_lib.PdfPageFormat.a4.obs;

  pw.MemoryImage? kennelLogoImage;

  int? runCountStart;
  DateTime? secondToLastEventDate;
  DateTime? lastEventDate;
  DateTime? nextEventDate;

  //PdfViewerController pdfViewerController = PdfViewerController();
  late pw.Document checkInDoc;
  Rx<Uint8List> checkInDocBytes = Uint8List(0).obs;
  List<KennelHashersModel> hashers = [];

  void updateSizeWithDebounce(double newWidth, double newHeight) {
    if (width.value != newWidth) {
      width.value = newWidth;
    }
    if (height.value != newHeight) {
      height.value = newHeight;
    }
  }

  @override
  void onInit() {
    super.onInit();
    publicKennelId = normalizeUuid(publicKennelId);

    final height = (box.get(HIVE_PAGE_HEIGHT) as int?) ?? 0;

    switch (height) {
      case 792:
        pageFormat.value = pdf_lib.PdfPageFormat.letter;
      case 1008:
        pageFormat.value = pdf_lib.PdfPageFormat.legal;
      default:
        pageFormat.value = pdf_lib.PdfPageFormat.a4;
    }

    unawaited(onInitAsync());
  }

  Future<void> onInitAsync() async {
    await getKennelImage();

    await getHasherDataFromDb();
    checkInDocBytes.value = await getPdfDoc(
      pdf_lib.PdfPageFormat.a4,
    );
  }

  Future<void> getKennelImage() async {
    if (kennelLogo.toLowerCase().startsWith('http')) {
      final response = await http.get(
        Uri.parse(
          kennelLogo,
        ),
      );

      if (response.statusCode == 200) {
        kennelLogoImage = pw.MemoryImage(response.bodyBytes);
      }
    }
  }

  Future<void> getHasherDataFromDb() async {
    final deviceId = box.get(HIVE_DEVICE_ID) as String;
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';
    final accessToken = Utilities.generateToken(
      deviceId,
      'hcportal_getKennelHashers',
      paramString: deviceSecret,
    );

    final body = <String, dynamic>{
      'queryType': 'getKennelHashers',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'publicKennelId': publicKennelId,
    };
    final jsonString = await ServiceCommon.sendHttpPostToHC6Api(body);
    debugPrint(jsonString.startsWith(ERROR_PREFIX)
        ? 'SP 12b (a-b) [getKennelHashers] called — FAILED'
        : 'SP 12b (a-b) [getKennelHashers] called — success');

    if (jsonString.length > 10) {
      final decodedJson = (json.decode(jsonString) as List<dynamic>)[0];
      final decodedHashers = (decodedJson as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      hashers
        ..clear()
        ..addAll(decodedHashers.map(KennelHashersModel.fromJson).toList())
        ..sort((a, b) {
          // If both dates are non-null, compare normally
          if (b.dateOfLastRun != null && a.dateOfLastRun != null) {
            return b.dateOfLastRun!.compareTo(a.dateOfLastRun!);
          }
          // If b's date is null, put it after a
          if (b.dateOfLastRun == null && a.dateOfLastRun != null) {
            return -1; // a comes first
          }
          // If a's date is null, put it after b
          if (a.dateOfLastRun == null && b.dateOfLastRun != null) {
            return 1; // b comes first
          }
          // If both are null, maintain the current order (return 0)
          return 0;
        });
    }
  }

  Future<Uint8List> getPdfDoc(pdf_lib.PdfPageFormat pgFormat) async {
    checkInDoc = pw.Document();
    checkInDocBytes.value = Uint8List(0);
    update(['pdfPage']);
    var margin = 40.0;

    // A4	1.414
    // A5	1.414
    // A3	1.414
    // US 1.294
    // US 1.647

    switch (pgFormat) {
      case pdf_lib.PdfPageFormat.a4:
        rowsPerColumn = NUM_COLS_A4;
      case pdf_lib.PdfPageFormat.letter:
        rowsPerColumn = NUM_COLS_LETTER;
        margin = 72;
      case pdf_lib.PdfPageFormat.legal:
        rowsPerColumn = NUM_COLS_LEGAL;
        margin = 72;
    }

    var days = 90;
    var recentHashCutoff = DateTime.now().subtract(Duration(days: days));
    final hashersWithRuns = hashers
        .where(
          (hasher) => hasher.dateOfLastRun != null,
        )
        .toList()
        .length;

    // loop through and increase the days until we fill the first page
    do {
      // Calculate the date 3 months ago
      recentHashCutoff = DateTime.now().subtract(Duration(days: days));
      final count = hashers
          .where(
            (hasher) =>
                hasher.dateOfLastRun != null &&
                hasher.dateOfLastRun!.isAfter(recentHashCutoff),
          )
          .toList()
          .length;

      // if we've exceeded one page, reduce the number of Hashers so we
      // get back to one page but in no case show less than 90 days
      // worth of runners (which may result in multiple pages of recent runners)
      if (count > rowsPerColumn * 2) {
        days = max(90, days - 10);
        recentHashCutoff = DateTime.now().subtract(Duration(days: days));
        break;
      }

      if (count == hashersWithRuns) {
        break;
      }

      days += 10;
    } while (days < 9000);

    // Split hashers into two lists based on dateOfLastRun
    final recentHashers = hashers
        .where(
          (hasher) =>
              hasher.dateOfLastRun != null &&
              hasher.dateOfLastRun!.isAfter(recentHashCutoff),
        )
        .toList();

    final otherHashers = hashers
        .where(
          (hasher) =>
              hasher.dateOfLastRun == null ||
              hasher.dateOfLastRun!.isBefore(recentHashCutoff),
        )
        .toList();

    // Step 3: Alphabetize both lists based on hasher name
    recentHashers
        .sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));
    otherHashers
        .sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));

    // this is a hack... we need a better
    // way to get the run number and start dates
    for (final hasher in recentHashers) {
      if ((hasher.atSecondToLastEvent != null) &&
          (hasher.atSecondToLastEvent!.isNotEmpty)) {
        final regExp = RegExp(r'\d+'); // Regex to match digits

        // Find the first match
        final match = regExp.firstMatch(hasher.atSecondToLastEvent!);

        if (match != null) {
          final numericPart = match.group(0)!;
          runCountStart ??= int.tryParse(numericPart) ?? 0;
          secondToLastEventDate ??= hasher.secondToLastEventDate;
          lastEventDate ??= hasher.lastEventDate;
          nextEventDate ??= hasher.nextEventDate;
        }
      }
    }

    while (recentHashers.isNotEmpty) {
      final nextHasherBatch = recentHashers.take(rowsPerColumn * 2).toList();

      var pageTitleStr = 'Check-in Sheet (Hashed in last $days days)';

      if (days > 547) {
        pageTitleStr = 'Check-in Sheet (Hashed in last ${days ~/ 365} years)';
      } else if (days > 120) {
        pageTitleStr = 'Check-in Sheet (Hashed in last ${days ~/ 30.5} months)';
      }

      checkInDoc.addPage(
        pw.Page(
          pageFormat: pgFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) => buildPdfTable(
            nextHasherBatch,
            pageTitleStr,
          ),
        ),
      );

      final rangeEnd = min((rowsPerColumn * 2), recentHashers.length);

      recentHashers.removeRange(0, rangeEnd);
    }

    while (otherHashers.isNotEmpty) {
      final nextHasherBatch = otherHashers.take(rowsPerColumn * 2).toList();

      checkInDoc.addPage(
        pw.Page(
          pageFormat: pgFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) => buildPdfTable(
            nextHasherBatch,
            'Check-in Sheet (past Hashers & followers)',
          ),
        ),
      );

      final rangeEnd = min((rowsPerColumn * 2), otherHashers.length);

      otherHashers.removeRange(0, rangeEnd);
    }

    checkInDocBytes.value = await checkInDoc.save();
    update(['pdfPage']);
    return checkInDocBytes.value;
  }

  pw.TableRow toElement(KennelHashersModel hasher) {
    final r = RegExp(r'^\d+-?');
    final atLastEvent = hasher.atLastEvent?.replaceFirst(r, '') ?? '';
    final atSecondToLastEvent =
        hasher.atSecondToLastEvent?.replaceFirst(r, '') ?? '';

    final r2 = RegExp('[^A-Za-z0-9 ]',
        unicode: true); // Keep word characters and spaces
    final displayName = hasher.displayName?.replaceAll(r2, '') ?? '';
    final hasherRunCount =
        hasher.hcTotalRunCount + hasher.historicTotalRuns + 1;
    final isSpecialRun = checkSpecialRun(hasherRunCount);
    return pw.TableRow(
      children: [
        pw.Container(
          color: hasher.isMember.toLowerCase() == 'no'
              ? pdf_lib.PdfColors.white
              : pdf_lib.PdfColors.blue50,
          padding: const pw.EdgeInsets.only(left: 3, top: 2.5),
          width: col1width,
          height: ROW_HEIGHT,
          child: pw.Text(
            displayName,
            style: pw.TextStyle(
              fontWeight: hasher.isMember.toLowerCase() == 'no'
                  ? pw.FontWeight.normal
                  : pw.FontWeight.bold,
            ),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ),
        pw.Container(
          //padding: const pw.EdgeInsets.only(top: 1),
          height: 20,
          color: isSpecialRun
              ? pdf_lib.PdfColors.green200
              : pdf_lib.PdfColors.white,
          alignment: pw.Alignment.center,
          width: col2width,
          child: pw.Text(
            (hasherRunCount).toString(),
            style: pw.TextStyle(
              fontWeight:
                  isSpecialRun ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 2.5),
          alignment: pw.Alignment.center,
          width: col3width,
          child: pw.Text(
            atSecondToLastEvent,
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 2.5),
          alignment: pw.Alignment.center,
          width: col4width,
          child: pw.Text(
            atLastEvent,
          ),
        ),
      ],
    );
  }

  pw.Widget buildPdfTable(
    List<KennelHashersModel> hashers,
    String subtitle,
  ) {
    final int rowCount = min(hashers.length ~/ 2, rowsPerColumn);

    return pw.Stack(
      alignment: pw.Alignment.center,
      children: [
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
                'Printed on: ${DateFormat('MMM d, yyyy').format(DateTime.now())}'),
            pw.Text(
              kennelName,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
              ),
            ),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 16,
              ),
            ),
            pw.Expanded(
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  buildColumn(hashers.skip(0).take(rowCount).toList()),
                  pw.SizedBox(width: 20),
                  buildColumn(
                    hashers.skip(rowCount).toList(),
                  ),
                ],
              ),
            ),
            pw.Align(
              child: pw.Text('Legend'),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    //constraints: const pw.BoxConstraints.expand(),
                    //color: pdf_lib.PdfColors.amber,
                    //height: 30,
                    child: pw.Text(
                        'F = Free Run\r\nC = Paid with cash\r\nB = Paid with bank transfer\r\nX = Not paid'),
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Expanded(
                  child: pw.Container(
                    //color: pdf_lib.PdfColors.amber,
                    //height: 30,
                    child: pw.Text(
                        'H = Paid with hash credit\r\nC? = Other amount paid with cash\r\nB? = Other amount paid with bank transfer\r\nH? = Other amount paid with hash cash'),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Align(
              child: pw.Text(
                'NOTE: The RC column shows how many runs the Hasher will have on run #${(runCountStart ?? 0) + 2} if they attend',
              ),
            ),
          ],
        ),
        if (kennelLogoImage != null) ...[
          pw.Opacity(
            opacity: 0.22,
            child: pw.Image(
              kennelLogoImage!,
              width: 400,
              height: 400,
            ),
          ),
        ],
      ],
    );
  }

  final double col1width = 90;
  final double col2width = 20;
  final double col3width = COL_WIDTH;
  final double col4width = COL_WIDTH;
  final double col5width = COL_WIDTH;
  final double col6width = COL_WIDTH;

  pw.Widget buildColumn(List<KennelHashersModel> hashers) {
    final numBlankRows = rowsPerColumn - hashers.length;
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Container(
                width: col1width,
                child: pw.Text(
                  '',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Container(
                width: col2width,
                child: pw.Text(
                  '',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            _getColumnDate(secondToLastEventDate),
            _getColumnDate(lastEventDate),
            _getColumnDate(nextEventDate),

            //_getColumnHeader(runCountStart + 5),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Container(
                width: col1width,
                child: pw.Text(
                  'Name',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Container(
                width: col2width,
                child: pw.Text(
                  'RC',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
            _getColumnHeader(runCountStart ?? 0),
            _getColumnHeader((runCountStart ?? 0) + 1),
            _getColumnHeader((runCountStart ?? 0) + 2),
            _getColumnHeader((runCountStart ?? 0) + 3),
            _getColumnHeader((runCountStart ?? 0) + 4),
            //_getColumnHeader(runCountStart + 5),
          ],
        ),
        ...hashers.map(toElement),
        for (int i = 0; i < numBlankRows; i++) ...[
          pw.TableRow(
            children: [
              pw.Container(
                height: 20,
              ),
            ],
          )
        ],
      ],
    );
  }

  pw.Widget _getColumnHeader(int runNumber) {
    return pw.Container(
      height: 40,
      width: 20,
      alignment: pw.Alignment.center,
      child: pw.Transform.rotate(
        angle: pi / 2,
        child: pw.FittedBox(
          child: pw.Text(
            runNumber.toString(),
            tightBounds: true,
            textAlign: pw.TextAlign.center,
            maxLines: 1,
            style: pw.TextStyle(
              color: pdf_lib.PdfColors.black,
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget _getColumnDate(DateTime? eventDate) {
    return pw.Container(
      height: 50,
      width: 20,
      alignment: pw.Alignment.center,
      child: eventDate == null
          ? pw.SizedBox()
          : pw.Transform.rotate(
              angle: pi / 2,
              child: pw.FittedBox(
                child: pw.Text(
                  DateFormat('MMM d').format(eventDate),
                  tightBounds: true,
                  textAlign: pw.TextAlign.center,
                  maxLines: 1,
                  style: pw.TextStyle(
                    color: pdf_lib.PdfColors.black,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
    );
  }

  static bool checkSpecialRun(int runCount) {
    var result = false;

    if (runCount == 5) {
      result = true;
    } else if (runCount == 10) {
      result = true;
    } else if (runCount % 100 == 69) {
      result = true;
    } else if (runCount > 0) {
      if (runCount % 25 == 0) {
        result = true;
      }

      if (runCount % 100 == 0) {
        result = true;
      }

      if (runCount % 250 == 0) {
        result = true;
      }

      if (runCount % 1000 == 0) {
        result = true;
      }
    }

    if ((result == false) && (runCount > 10)) {
      final s = runCount.toString();
      final reversed = s.split('').reversed.join();

      if (s == reversed) {
        result = true;
      }
    }

    return result;
  }
}
