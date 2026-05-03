import 'kennel_website_page_controller.dart';
import 'kennel_website_page_enums.dart';
import 'package:hcportal/imports.dart';
import 'package:hcportal/tabbed_ui/widgets/tri_state_checkbox_field.dart';

part 'pages/identity_tab/layout.dart';
part 'pages/appearance_tab/layout.dart';
part 'pages/images_tab/layout.dart';
part 'pages/content_tab/layout.dart';
part 'pages/seo_tab/layout.dart';
part 'pages/advanced_tab/layout.dart';

// ---------------------------------------------------------------------------
// Entry widget
// ---------------------------------------------------------------------------

class KennelWebsiteEditPage extends GetView<KennelWebsiteController> {
  const KennelWebsiteEditPage({
    required this.websiteData,
    required this.publicKennelId,
    required this.kennelName,
    required this.kennelUniqueShortName,
    super.key,
  });

  final KennelWebsiteModel websiteData;
  final String publicKennelId;
  final String kennelName;
  final String kennelUniqueShortName;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<KennelWebsiteController>()) {
      Get.put(
        KennelWebsiteController(
          websiteData,
          publicKennelId: publicKennelId,
          kennelName: kennelName,
          kennelUniqueShortName: kennelUniqueShortName,
        ),
        permanent: true,
      );
    }
    return GetBuilder<KennelWebsiteController>(
      id: 'websitePageBuilder',
      builder: (_) => _WebsiteScaffold(controller: controller),
    );
  }
}

// ---------------------------------------------------------------------------
// Scaffold
// ---------------------------------------------------------------------------

class _WebsiteScaffold extends StatelessWidget {
  const _WebsiteScaffold({required this.controller});

  final KennelWebsiteController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          controller.updateSizeWithDebounce(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          return Scaffold(
            appBar: _buildAppBar(),
            body: _buildBody(),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: GestureDetector(
        onTap: () => Get.back<void>(),
        child: const Icon(
          MaterialCommunityIcons.arrow_left,
          color: Colors.black,
        ),
      ),
      title: Obx(
        () => Text(
          'Website — ${controller.kennelName}',
          style: headingStyleBlack,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return DefaultTabController(
      length: KennelWebsiteTabType.values.length,
      child: Column(
        children: [
          ResponsiveTabBar<KennelWebsiteController>(
            controller: controller,
            formKey: controller.formKey,
            tabBarColor: Colors.teal.shade600,
          ),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: _buildTabBodies(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabBodies() {
    return KennelWebsiteTabType.values.map((tab) {
      return TabPageStandardLayout(
        title: tab.title,
        icon: tab.icon,
        description: tab.description,
        formController: controller,
        showCloseTabGroupButton: true,
        tabLocked: controller.tabLocked[tab.index],
        child: _buildTabContent(tab),
      );
    }).toList();
  }

  Widget _buildTabContent(KennelWebsiteTabType tab) {
    return switch (tab) {
      KennelWebsiteTabType.identity =>
        _IdentityTabContent(controller: controller),
      KennelWebsiteTabType.appearance =>
        _AppearanceTabContent(controller: controller),
      KennelWebsiteTabType.images =>
        _ImagesTabContent(controller: controller),
      KennelWebsiteTabType.content =>
        _ContentTabContent(controller: controller),
      KennelWebsiteTabType.seo => _SeoTabContent(controller: controller),
      KennelWebsiteTabType.advanced =>
        _AdvancedTabContent(controller: controller),
    };
  }
}
