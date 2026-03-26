/// Kennel Logo Tab Layout
///
/// UI widget for the kennel logo upload tab, with a live background preview panel.

part of '../../kennel_page_new_ui.dart';

// ---------------------------------------------------------------------------
// Logo Tab Content Widget
// ---------------------------------------------------------------------------

class KennelLogoTabContent extends StatelessWidget {
  const KennelLogoTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    final controlKey = '${KennelTabType.kennelLogo.key}_logo';
    final uiControl = controller.uiControls[controlKey];
    if (uiControl == null) return const SizedBox.shrink();

    controller.uploadingState[controlKey] ??= false.obs;
    controller.uploadStatusState[controlKey] ??= ''.obs;

    final availableHeight = MediaQuery.of(context).size.height - 400;
    final imageSize = availableHeight.clamp(150.0, 500.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperWidgets().categoryLabelWidget('Kennel Logo'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload / display section (left)
            SizedBox(
              width: imageSize,
              child: DocumentManagerField(
                controller: controller,
                uiControl: uiControl,
                fieldName: controlKey,
                recordId: controller.originalData.kennelPublicId.uuid,
                uploading: controller.uploadingState[controlKey]!,
                uploadStatus: controller.uploadStatusState[controlKey],
                height: imageSize,
                width: imageSize,
                expandToFit: true,
                allowedExtensions: const ['png', 'avif'],
                preserveFormat: true,
                imageOverlay: FractionallySizedBox(
                  widthFactor: 0.55,
                  child: AutoSizeText(
                    controller.originalData.kennelShortName,
                    style: const TextStyle(
                      fontFamily: 'AvenirNextCondensedBold',
                      fontSize: 400,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 1,
                  ),
                ),
                placeholderText: 'No logo\n\nClick to upload',
                filenamePrefix:
                    '${controller.originalData.kennelUniqueShortName}_',
                imageValidator: (int w, int h) {
                  if (w != h) {
                    return 'Logo must be square. This image is $w×$h pixels.';
                  }
                  if (w < 400 || w > 800) {
                    return 'Logo must be between 400×400 and 800×800 pixels. '
                        'This image is $w×$h pixels.';
                  }
                  return null;
                },
                onUploadComplete: (String fileName) {
                  final fullUrl = BASE_KENNEL_LOGOS_URL + fileName;
                  uiControl.editedFieldValue = fullUrl;
                  controller.editedData.value =
                      controller.editedData.value.copyWith(kennelLogo: fullUrl);
                  controller.checkIfFormIsDirty();
                },
                onRemoveDocument: () {
                  // Revert display to a random bundle asset so there is always
                  // a logo visible. Save the bundle URL to the DB so the app
                  // and web clients render the same generic logo.
                  final hue = (Random().nextInt(12) * 30);
                  final bundleUrl =
                      'bundle://C-${hue.toString().padLeft(3, '0')}';
                  uiControl.editedFieldValue = bundleUrl;
                  controller.editedData.value =
                      controller.editedData.value.copyWith(
                    kennelLogo: bundleUrl,
                  );
                },
                onAfterRemove: () => controller.checkIfFormIsDirty(),
              ),
            ),
            const SizedBox(width: 40),
            // Preview panel (right)
            Expanded(
              child: _LogoPreviewPanel(
                controller: controller,
                controlKey: controlKey,
                uiControl: uiControl,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preview Panel
// ---------------------------------------------------------------------------

class _LogoPreviewPanel extends StatelessWidget {
  const _LogoPreviewPanel({
    required this.controller,
    required this.controlKey,
    required this.uiControl,
  });

  final KennelPageFormController controller;
  final String controlKey;
  final UiControlDefinition uiControl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read these Rx values so Obx rebuilds after uploads and removals.
      controller.uploadingState[controlKey]?.value;
      controller.uploadStatusState[controlKey]?.value;

      final logoUrl = uiControl.editedFieldValue;
      final hasLogo =
          logoUrl != null && logoUrl != '<null>' && logoUrl.isNotEmpty;

      if (!hasLogo) {
        return SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'Upload a logo to see\nbackground previews',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      // Only show the short name overlay for bundle assets — real logos don't
      // need it and the text would obscure the kennel's actual logo image.
      final isBundleAsset = logoUrl.startsWith('bundle://');
      final shortNameOverlay = isBundleAsset
          ? controller.originalData.kennelShortName
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HelperWidgets().categoryLabelWidget('Background Preview'),
          const SizedBox(height: 16),
          _LogoPreviewTile(
            url: logoUrl,
            shortName: shortNameOverlay,
            label: 'Light',
            backgroundColor: const Color(0xFFF2F2F2),
            stripeColor: const Color(0xFFD8D8D8),
          ),
          const SizedBox(height: 16),
          _LogoPreviewTile(
            url: logoUrl,
            shortName: shortNameOverlay,
            label: 'Mid-tone',
            backgroundColor: const Color(0xFF787878),
            stripeColor: const Color(0xFF636363),
          ),
          const SizedBox(height: 16),
          _LogoPreviewTile(
            url: logoUrl,
            shortName: shortNameOverlay,
            label: 'Dark',
            backgroundColor: const Color(0xFF1A1A1A),
            stripeColor: const Color(0xFF2E2E2E),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Preview Tile
// ---------------------------------------------------------------------------

class _LogoPreviewTile extends StatelessWidget {
  const _LogoPreviewTile({
    required this.url,
    required this.label,
    required this.backgroundColor,
    required this.stripeColor,
    this.shortName,
  });

  final String url;
  final String? shortName;
  final String label;
  final Color backgroundColor;
  final Color stripeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _DiagonalStripesPainter(
                backgroundColor: backgroundColor,
                stripeColor: stripeColor,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 160,
                child: Center(
                  // Fixed 120×120 box mirrors the logo's rendered size (160px tile
                  // minus 20px padding each side), so FractionallySizedBox matches
                  // the 0.55 widthFactor used by the KennelLogo widget.
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        url.startsWith('bundle://')
                            ? Image.asset(
                                'images/generic_logos/${url.replaceAll('bundle://', '')}.png'
                                    .toLowerCase(),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey.shade500,
                                  size: 40,
                                ),
                              )
                            : HcNetworkImage(
                                url,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey.shade500,
                                  size: 40,
                                ),
                              ),
                        if (shortName != null)
                          FractionallySizedBox(
                            widthFactor: 0.55,
                            child: AutoSizeText(
                              shortName!,
                              style: const TextStyle(
                                fontFamily: 'AvenirNextCondensedBold',
                                fontSize: 400,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              minFontSize: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Diagonal Stripe Texture Painter
// ---------------------------------------------------------------------------

class _DiagonalStripesPainter extends CustomPainter {
  const _DiagonalStripesPainter({
    required this.backgroundColor,
    required this.stripeColor,
  });

  final Color backgroundColor;
  final Color stripeColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 1.5;

    const double spacing = 14.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalStripesPainter old) =>
      old.backgroundColor != backgroundColor || old.stripeColor != stripeColor;
}
