part of '../application_form_ui.dart';

extension ApplicationProposal on TestFormPage {
  Widget _buildAppProposalForm({required int tabIndex}) {
    {
      // final isMobileScreen =
      //     formController.screenSize.value == EScreenSize.isMobileScreen;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextDropdownField(
                      controller: applicationGetxController,
                      label: 'Forms',
                      value: applicationGetxController.activeFormIndex,
                      items: Map.fromEntries(AppFormTypes.values
                          .map((e) => MapEntry(e.idx, e.title))),
                      width: 250,
                      updateValue: (value) {
                        applicationGetxController.activeFormIndex.value = value;
                        applicationGetxController.setSidebarData(
                          '',
                          shortDescription:
                              AppFormTypes.values[value].description,
                          icon: AppFormTypes.values[value].icon,
                          title: AppFormTypes.values[value].title,
                        );
                      }),
                ),
                Expanded(child: Container()),
              ],
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(15),
                width: 1000,
                decoration: BoxDecoration(
                  color: Colors.white, // Background color
                  border: Border.all(
                    color: Colors.grey, // Border color
                    width: 1, // Border width (1px)
                  ),
                ),
                child: Column(
                  children: [
                    Obx(
                      () {
                        int currentWordCount = applicationGetxController
                            .applicationFormWordCount.value;
                        int maxWordCount = applicationGetxController
                            .applicationFormMaxWordCount;
                        int minWordCount = applicationGetxController
                            .applicationFormMinWordCount;

                        int progressFileIdx = 99;
                        if (currentWordCount < minWordCount) {
                          progressFileIdx =
                              ((currentWordCount / minWordCount) * 8).toInt();
                          if (progressFileIdx > 7) {
                            progressFileIdx = 7;
                          }
                        } else if (currentWordCount <= maxWordCount) {
                          progressFileIdx =
                              ((currentWordCount / maxWordCount) * 13).toInt();
                          if (progressFileIdx < 8) {
                            progressFileIdx = 8;
                          } else if (progressFileIdx > 12) {
                            progressFileIdx = 12;
                          }
                        }

                        return Row(children: [
                          Expanded(child: Container()),
                          Text(
                            applicationGetxController
                                        .applicationFormWordCount.value <
                                    applicationGetxController
                                        .applicationFormMinWordCount
                                ? 'Word count = ${applicationGetxController.applicationFormWordCount.value}   (minimum required wordcount = ${applicationGetxController.applicationFormMinWordCount})'
                                : applicationGetxController
                                            .applicationFormWordCount.value >
                                        applicationGetxController
                                            .applicationFormMaxWordCount
                                    ? 'Word count = ${applicationGetxController.applicationFormWordCount.value}   (exceeded maximum wordcount by ${applicationGetxController.applicationFormWordCount.value - applicationGetxController.applicationFormMaxWordCount})'
                                    : 'Word count = ${applicationGetxController.applicationFormWordCount.value} of ${applicationGetxController.applicationFormMaxWordCount}',
                            style: headingStyleBlack,
                          ),
                          const SizedBox(width: 30),
                          Image.asset(
                            'images/progress_indicators/forms/progress_${(progressFileIdx.toString()).padLeft(2, '0')}.png',
                            height: 55,
                            width: 55,
                          ),
                          Expanded(child: Container()),
                        ]);
                      },
                    ),
                    Obx(
                      () {
                        final baseTheme = Get.theme;
                        final toolbarTheme = baseTheme.copyWith(
                          // Ensure toolbar icons remain visible on light backgrounds.
                          iconTheme: baseTheme.iconTheme
                              .copyWith(color: Colors.black87),
                          primaryIconTheme: baseTheme.primaryIconTheme
                              .copyWith(color: Colors.blueGrey.shade800),
                          disabledColor: Colors.grey.shade500,
                          canvasColor: Colors.white,
                          colorScheme: baseTheme.colorScheme.copyWith(
                            secondary: Colors.blueGrey.shade100,
                            onSecondary: Colors.black87,
                          ),
                        );

                        return Theme(
                          data: toolbarTheme,
                          child: fleather.FleatherToolbar.basic(
                            controller: applicationGetxController
                                .fleatherController.value,
                            editorKey: applicationGetxController.editorKey,
                          ),
                        );
                      },
                    ),
                    Divider(
                        height: 1, thickness: 1, color: Colors.grey.shade200),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Lockable(
                          lockState:
                              applicationGetxController.tabLocked[tabIndex],
                          child: Obx(
                            () => fleather.FleatherEditor(
                              controller: applicationGetxController
                                  .fleatherController.value,
                              focusNode:
                                  applicationGetxController.fleatherFocusNode,
                              embedBuilder: _embedBuilder,
                              editorKey: applicationGetxController.editorKey,
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: Get.mediaQuery.padding.bottom,
                              ),
                              onLaunchUrl: _launchUrl,
                              maxContentWidth: 950,

                              // spellCheckConfiguration: SpellCheckConfiguration(
                              //     spellCheckService: DefaultSpellCheckService(),
                              //     misspelledSelectionColor: Colors.red,
                              //     misspelledTextStyle:
                              //         DefaultTextStyle.of(context).style),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: defaultButtonStyle,
              onPressed: () async {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final Uint8List imageBytes = await image.readAsBytes();

                  final headers = <String, String>{
                    'x-ms-blob-type': 'BlockBlob',
                    'Access-Control-Allow-Origin': '*',
                    'Content-Type': 'image/jpeg',
                  };

                  String url = BASE_UPLOAD_URL +
                      await ServiceCommon.uploadData(
                          applicationGetxController
                              .originalData.applicationPublicId.uuid,
                          'form_image',
                          'jpg',
                          headers,
                          imageBytes);

                  final selection = applicationGetxController
                      .fleatherController.value.selection;
                  applicationGetxController.fleatherController.value
                      .replaceText(
                    selection.baseOffset,
                    selection.extentOffset - selection.baseOffset,
                    EmbeddableObject('image', inline: false, data: {
                      'source_type': 'url',
                      'source': url,
                    }),
                  );
                  applicationGetxController.fleatherController.value
                      .replaceText(
                    selection.baseOffset + 1,
                    0,
                    '\n',
                    selection: TextSelection.collapsed(
                        offset: selection.baseOffset + 2),
                  );
                }
              },
              child: Text(
                'Insert image',
                style: buttonLabelStyleMedium,
              ),
            ),
            const SizedBox(
              width: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    style: defaultButtonStyle,
                    onPressed: () {
                      applicationGetxController.tabController.index--;
                    },
                    child: Text(
                      'Back',
                      style: buttonLabelStyleMedium,
                    ),
                  ),
                ),
                Expanded(child: Container()),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: defaultButtonStyle,
                    onPressed: () {
                      applicationGetxController.tabController.index++;
                    },
                    child: Text(
                      'Next',
                      style: buttonLabelStyleMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _embedBuilder(BuildContext context, fleather.EmbedNode node) {
    if (node.value.type == 'icon') {
      final data = node.value.data;
      // Icons.rocket_launch_outlined
      return Icon(
        IconData(int.parse(data['codePoint']), fontFamily: data['fontFamily']),
        color: Color(int.parse(data['color'])),
        size: 18,
      );
    }

    if (node.value.type == 'image') {
      final sourceType = node.value.data['source_type'];
      ImageProvider? image;
      if (sourceType == 'assets') {
        image = AssetImage(node.value.data['source']);
      } else if (sourceType == 'file') {
        image = FileImage(File(node.value.data['source']));
      } else if (sourceType == 'url') {
        image = NetworkImage(node.value.data['source']);
      }
      if (image != null) {
        return Padding(
          // Caret takes 2 pixels, hence not symmetric padding values.
          padding: const EdgeInsets.only(left: 4, right: 2, top: 2, bottom: 2),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(image: image, fit: BoxFit.cover),
            ),
          ),
        );
      }
    }

    return Container();
  }

  void _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    }
  }
}
