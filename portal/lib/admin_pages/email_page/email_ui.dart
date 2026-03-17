// ignore_for_file: unused_element

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fleather/fleather.dart' as fleather;
import 'package:hcportal/admin_pages/email_page/email_ui_controller.dart';
import 'package:hcportal/imports.dart';

class EmailPage extends StatelessWidget {
  const EmailPage({super.key});

  EmailTabbedUiController get c => Get.find<EmailTabbedUiController>();

  @override
  Widget build(BuildContext context) {
    try {
      return GetBuilder<EmailTabbedUiController>(
          init: EmailTabbedUiController(),
          id: 'refreshApplicationFormBuilder',
          builder: (unusedController) {
            return ColoredBox(
              color: Colors.white,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  c.updateSizeWithDebounce(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return Scaffold(
                    appBar: AppBar(
                      actions: <Widget>[
                        Row(
                          children: [
                            SizedBox(
                              width: 150,
                              child: Obx(() {
                                if (!c.doAutoSave.value) {
                                  return const SizedBox();
                                } else if (c.autoSaveCounter.value == -1) {
                                  return Center(
                                    child: Text('Saving',
                                        style: titleStyleBlack.copyWith(
                                          color: Colors.blue.shade700,
                                        )),
                                  );
                                }
                                return LinearProgressIndicator(
                                    minHeight: 15,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                    value: c.autoSaveCounter.value /
                                        AUTOSAVE_PERIOD_IN_SECONDS);
                              }),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              'Auto save',
                              style: headingStyleBlack,
                            ),
                            const SizedBox(width: 10),
                            Obx(
                              () => Switch(
                                value: c.doAutoSave.value,
                                onChanged: (value) {
                                  c.doAutoSave.value = !c.doAutoSave.value;
                                },
                              ),
                            ),
                            const SizedBox(width: 30),
                          ],
                        )
                      ],
                      title: Text('Editing', style: headingStyleBlack),
                      leading: GestureDetector(
                        onTap: () {
                          Get.back<void>();
                        },
                        child: const Icon(
                          MaterialCommunityIcons.arrow_left,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    body: DefaultTabController(
                      length: c.allTabs.length,
                      child: Builder(
                        builder: (context) {
                          return Column(
                            children: <Widget>[
                              Container(
                                color: Colors.blue.shade600,
                                padding: const EdgeInsets.only(top: 10),
                                child: Form(
                                  key: c.formKey,
                                  child: TabBar(
                                      controller: c.tabController,
                                      labelColor: Colors.black,
                                      unselectedLabelColor: Colors.white,
                                      indicatorSize: TabBarIndicatorSize.label,
                                      indicator: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                        ),
                                        color: Colors.white,
                                      ),
                                      tabs: _getTabs()),
                                ),
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: c.tabController,
                                  children: <Widget>[..._getTabBodies()],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          });
    } on Exception catch (ex) {
      if (kDebugMode) debugPrint('Email UI error: $ex');
    }
    return Container(color: Colors.amber);
  }

  List<Widget> _getTabs() {
    return c.allTabs
        .map(
          (item) => TabWithIcon<EmailTabbedUiController>(
            label: item.title,
            tabIndex: item.tabIndex,
            controller: c,
          ),
        )
        .toList();
  }

  Widget _getTabBody(int idx) {
    Widget body = Container(
      color: Colors.pink.shade200,
      height: 300,
      width: 300,
    );

    switch (idx) {
      case 0:
        body = EmailPageSendAdHocEmail(c, idx,
            '${c.allTabs[idx].key}_title');
    }
    return body;
  }

  List<Widget> _getTabBodies() {
    return c.allTabs
        .map(
          (tabData) => TabPageStandardLayout(
            title: tabData.title,
            icon: tabData.sidebarData.icon,
            description: tabData.sidebarData.description,
            tabLocked: c.tabLocked[tabData.tabIndex],
            formController: c,
            showCloseTabGroupButton: true,
            child: _getTabBody(tabData.tabIndex),
          ),
        )
        .toList();
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    }
  }
}

/// This is an example insert rule that will insert a new line before and
/// after inline image embed.
class ForceNewlineForInsertsAroundInlineImageRule extends fleather.InsertRule {
  @override
  fleather.Delta? apply(fleather.Delta document, int index, Object data) {
    if (data is! String) return null;

    final iter = fleather.DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();
    final cursorBeforeInlineEmbed = _isInlineImage(target.data);
    final cursorAfterInlineEmbed =
        previous != null && _isInlineImage(previous.data);

    if (cursorBeforeInlineEmbed || cursorAfterInlineEmbed) {
      final delta = fleather.Delta()..retain(index);
      if (cursorAfterInlineEmbed && !data.startsWith('\n')) {
        delta.insert('\n');
      }
      delta.insert(data);
      if (cursorBeforeInlineEmbed && !data.endsWith('\n')) {
        delta.insert('\n');
      }
      return delta;
    }
    return null;
  }

  bool _isInlineImage(Object data) {
    if (data is fleather.EmbeddableObject) {
      return data.type == 'image' && data.inline;
    }
    if (data is Map) {
      // return data[fleather.EmbeddableObject.kTypeKey] == 'image' &&
      //     data[fleather.EmbeddableObject.kInlineKey];
    }
    return false;
  }
}
