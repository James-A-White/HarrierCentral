import 'package:hcportal/imports.dart';
import 'package:pdf/pdf.dart';
import 'package:pdfrx/pdfrx.dart';

class CheckinSheetPage extends StatelessWidget {
  const CheckinSheetPage({
    required this.publicKennelId,
    required this.kennelName,
    required this.kennelLogo,
    super.key,
  });

  final String publicKennelId;
  final String kennelName;
  final String kennelLogo;

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is properly initialized or retrieved
    final formController = Get.put(
      CheckinSheetController(
        publicKennelId: publicKennelId,
        kennelName: kennelName,
        kennelLogo: kennelLogo,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back<void>(),
          icon: const Icon(
            MaterialCommunityIcons.arrow_left,
            color: Colors.black,
          ),
        ),
        title: const Text('Hash run check-in sheets'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          formController.updateSizeWithDebounce(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          return GetBuilder<CheckinSheetController>(
            id: 'pdfPage',
            builder: (controller) => Obx(
              () => Column(
                children: [
                  Expanded(
                    child: controller.checkInDocBytes.value.isEmpty
                        ? const HcCircularProgressIndicator(key: Key('232321'))
                        // : PdfPreview(
                        //     key: const Key('pdfPreviewKey'),
                        //     canChangePageFormat:
                        //         true, // Enables changing page format in print settings
                        //     initialPageFormat: controller.pageFormat.value,
                        //     onPageFormatChanged: (PdfPageFormat format) {
                        //       controller.pageFormat.value = format;
                        //       controller.getPdfDoc(format);
                        //       //controller.updateFormat(format); // Detect format change
                        //     },
                        //     build: (PdfPageFormat format) async {
                        //       //controller.updateFormat(format); // Update when PDF is built
                        //       return controller.checkInDocBytes.value;
                        //     },
                        //   ),

                        : PdfViewer.data(
                            // for some reason the PdfViewer zeros out the list
                            // after rendering, so we need to make a copy of the
                            // original list so it will still be available for
                            // printing
                            Uint8List.fromList(
                              formController.checkInDocBytes.value,
                            ),
                            sourceName: 'Test',
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: controller.checkInDocBytes.value.isEmpty
                              ? null
                              : () async {
                                  await Printing.layoutPdf(
                                    onLayout: (PdfPageFormat format) {
                                      return controller.getPdfDoc(
                                        controller.pageFormat.value,
                                      );
                                    },
                                  );
                                },
                          child: Text(
                            'Print Check-in Sheet ',
                            style: buttonLabelStyleMedium,
                          ),
                        ),
                        const SizedBox(width: 30),
                        DropdownButton(
                          value: controller.pageFormat.value,
                          items: const [
                            DropdownMenuItem(
                              value: PdfPageFormat.a4,
                              child: Text('A4'),
                            ),
                            DropdownMenuItem(
                              value: PdfPageFormat.letter,
                              child: Text('US Letter'),
                            ),
                            DropdownMenuItem(
                              value: PdfPageFormat.legal,
                              child: Text('US Legal'),
                            ),
                          ],
                          onChanged: (value) async {
                            await box.put(
                              HIVE_PAGE_HEIGHT,
                              value?.height.toInt() ?? 0,
                            );
                            controller.pageFormat.value =
                                value ?? PdfPageFormat.a4;
                            await controller.getPdfDoc(
                              value ?? PdfPageFormat.a4,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
