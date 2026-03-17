/// Kennel Developer Page Layout
///
/// This file defines the UI layout for the Kennel Developer tab.
/// Features a modern, card-based design with clean visual hierarchy.

part of '../../kennel_page_new_ui.dart';

// ---------------------------------------------------------------------------
// Developer Tab Content Widget
// ---------------------------------------------------------------------------

/// Content widget for the Kennel Developer tab.
///
/// Displays developer resources organized in modern cards:
/// - Digital Identifiers (Public Kennel ID, API Secret Key)
/// - HashRuns.org Links
/// - Web Components
/// - Data APIs
/// - WordPress Toolbox
class KennelDeveloperTabContent extends StatelessWidget {
  const KennelDeveloperTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      return Lockable(
        lockState: controller.tabLocked[KennelTabType.developer.index],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDigitalIdentifiersSection(isMobileScreen),
              const SizedBox(height: 24),
              _buildHashRunsLinksSection(isMobileScreen),
              const SizedBox(height: 24),
              _buildWebComponentsSection(isMobileScreen),
              const SizedBox(height: 24),
              _buildDataApisSection(isMobileScreen),
              const SizedBox(height: 24),
              _buildWordPressSection(isMobileScreen),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Section Builders
  // ---------------------------------------------------------------------------

  /// Builds the Digital Identifiers section with Public ID and API Key.
  Widget _buildDigitalIdentifiersSection(bool isMobileScreen) {
    final kennelName = controller.editedData.value.kennelName;

    return _DeveloperCard(
      title: 'Digital Identifiers for $kennelName',
      icon: FontAwesome5Solid.fingerprint,
      children: [
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_publicKennelId',
          label: 'Public Kennel ID',
          value: controller.originalData.kennelPublicId.toString(),
          copyValue: controller.originalData.kennelPublicId.toString(),
          copyMessage: 'Public Kennel ID copied to clipboard',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 16),
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_extApiKey',
          label: 'API Secret Key',
          value: controller.originalData.extApiKey,
          copyValue: controller.originalData.extApiKey,
          copyMessage: 'API Secret Key copied to clipboard',
          showRegenerateButton: true,
          onRegenerate: () => _regenerateApiKey(),
          isMobile: isMobileScreen,
        ),
      ],
    );
  }

  /// Regenerates the API key.
  Future<void> _regenerateApiKey() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Regenerate API Key?'),
        content: const Text(
          'This will invalidate your current API key. Any integrations '
          'using the old key will stop working. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement API key regeneration
      Get.snackbar(
        'API Key',
        'API key regeneration is not yet implemented',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Builds the HashRuns.org Links section.
  Widget _buildHashRunsLinksSection(bool isMobileScreen) {
    final data = controller.originalData;

    return _DeveloperCard(
      title: 'Links for www.hashruns.org',
      icon: FontAwesome5Solid.link,
      children: [
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_hashRunsKennel',
          label: 'HashRuns.org link for ${data.kennelName}',
          url:
              'https://www.hashruns.org/#/RD?publicKennelIds=${data.kennelPublicId}',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_hashRunsCity',
          label: 'HashRuns.org link for ${data.cityName}',
          url: 'https://www.hashruns.org/#/RD?cityIds=${data.cityId}',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_hashRunsRegion',
          label: 'HashRuns.org link for ${data.regionName}',
          url:
              'https://www.hashruns.org/#/RD?regionIds=${data.provinceStateId}',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_hashRunsCountry',
          label: 'HashRuns.org link for ${data.countryName}',
          url: 'https://www.hashruns.org/#/RD?countryIds=${data.countryId}',
          isMobile: isMobileScreen,
        ),
      ],
    );
  }

  /// Builds the Web Components section.
  Widget _buildWebComponentsSection(bool isMobileScreen) {
    final publicId = controller.originalData.kennelPublicId;
    final leaderboardUrl =
        'https://www.harriercentral.com/kennelrunsshort?PublicKennelId=$publicId&Report=allRuns&NumRecords=500&SortByColNum=4&SortAscending=0&ShowTools=yes';
    final iframeCode =
        '<iframe src="$leaderboardUrl" style="border-width:0" width="650" height="7300" frameborder="0" scrolling="no"></iframe>';

    return _DeveloperCard(
      title: 'Web Components',
      icon: FontAwesome5Solid.puzzle_piece,
      children: [
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_leaderboard',
          label: 'Run Count / Leaderboard web component',
          url: leaderboardUrl,
          additionalCopyValue: iframeCode,
          additionalCopyLabel: 'Copy iframe',
          additionalCopyMessage: 'iframe HTML copied to clipboard',
          isMobile: isMobileScreen,
        ),
      ],
    );
  }

  /// Builds the Data APIs section.
  Widget _buildDataApisSection(bool isMobileScreen) {
    final data = controller.originalData;
    final baseUrl = BASE_API_URL;

    final eventsApiUrl =
        '$baseUrl/PublicApi?PublicKennelId=${data.kennelPublicId}&ApiKey=${data.extApiKey}&queryType=getEvents&numberOfRecords=1000&pastOrFuture=future&sortOrder=ASC&fullDetails=0&weeksToDisplay=104';
    final nextRunApiUrl =
        '$baseUrl/PublicApi?PublicKennelId=${data.kennelPublicId}&ApiKey=${data.extApiKey}&queryType=getEvents&numberOfRecords=1&pastOrFuture=future&sortOrder=ASC&fullDetails=1&weeksToDisplay=104';
    final leaderboardApiUrl =
        '$baseUrl/PublicApi?PublicKennelId=${data.kennelPublicId}&ApiKey=${data.extApiKey}&queryType=getRunCounts&numberOfRecords=10&pastOrFuture=past&sortOrder=ASC&fullDetails=1&weeksToDisplay=104';

    return _DeveloperCard(
      title: 'Data APIs',
      icon: FontAwesome5Solid.database,
      children: [
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_eventsApi',
          label: 'API for ${data.kennelName} future event list',
          url: eventsApiUrl,
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_nextRunApi',
          label: 'API call to return next run for ${data.kennelName}',
          url: nextRunApiUrl,
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperLinkRow(
          controller: controller,
          sidebarKey: 'developer_leaderboardApi',
          label: 'API call to return run counts for ${data.kennelName}',
          url: leaderboardApiUrl,
          isMobile: isMobileScreen,
        ),
      ],
    );
  }

  /// Builds the WordPress Toolbox section.
  Widget _buildWordPressSection(bool isMobileScreen) {
    final data = controller.originalData;
    final apiKey = data.extApiKey;
    final publicId = data.kennelPublicId;

    return _DeveloperCard(
      title: 'WordPress Toolbox',
      icon: FontAwesome5Brands.wordpress,
      children: [
        _DeveloperDownloadRow(
          controller: controller,
          sidebarKey: 'developer_wordpressPlugin',
          label:
              'Harrier Central WordPress Toolbox plug-in (version 0.9 / Dec 31, 2024)',
          downloadUrl:
              'https://harriercentral.blob.core.windows.net/wordpress-plugin/harrier-central-wordpress-toolbox-0_9.zip',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 16),
        _DeveloperShortcodeRow(
          controller: controller,
          sidebarKey: 'developer_shortcodeMasterDetail',
          label: 'List/Detail Shortcode',
          shortcode:
              '[harrier_runs timeframe="past" bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="$apiKey" publickennelid="$publicId" showmapbutton="true"]',
          demoUrl:
              'https://harriercentral.com/demomasterdetailpast?apikey=$apiKey&publickennelid=$publicId',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperShortcodeRow(
          controller: controller,
          sidebarKey: 'developer_shortcodeGallery',
          label: 'Runs Gallery Shortcode',
          shortcode:
              '[harrier_gallery timeframe="past" bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="$apiKey" publickennelid="$publicId" columns="3" hidedescription="true" showmapbutton="true"]',
          demoUrl:
              'https://harriercentral.com/demogallerypast?apikey=$apiKey&publickennelid=$publicId',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperShortcodeRow(
          controller: controller,
          sidebarKey: 'developer_shortcodeTable',
          label: 'Runs Table Shortcode',
          shortcode:
              '[harrier_grid timeframe="past" bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="$apiKey" publickennelid="$publicId" columns="3" hidedescription="true" showmapbutton="true"]',
          demoUrl:
              'https://harriercentral.com/demogridpast?apikey=$apiKey&publickennelid=$publicId',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperShortcodeRow(
          controller: controller,
          sidebarKey: 'developer_shortcodeNextRun',
          label: 'Next Run Shortcode',
          shortcode:
              '[next_run bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="$apiKey" publickennelid="$publicId" showmapbutton="true"]',
          demoUrl:
              'https://harriercentral.com/nextrun?apikey=$apiKey&publickennelid=$publicId',
          isMobile: isMobileScreen,
        ),
        const SizedBox(height: 12),
        _DeveloperShortcodeRow(
          controller: controller,
          sidebarKey: 'developer_shortcodeLeaderboard',
          label: 'Run Counts / Leaderboard Shortcode',
          shortcode:
              '[harrier_leaderboard bgcolor="#f0f8ff" fontfamily="Georgia, serif" fontcolor="#000000" apikey="$apiKey" publickennelid="$publicId"]',
          demoUrl:
              'https://harriercentral.com/leaderboard?apikey=$apiKey&publickennelid=$publicId',
          isMobile: isMobileScreen,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Components
// ---------------------------------------------------------------------------

/// A modern card container for developer sections.
class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade500,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row widget for displaying a copyable/openable link.
class _DeveloperLinkRow extends StatelessWidget {
  const _DeveloperLinkRow({
    required this.controller,
    required this.sidebarKey,
    required this.label,
    this.value,
    this.url,
    this.copyValue,
    this.copyMessage,
    this.showRegenerateButton = false,
    this.onRegenerate,
    this.additionalCopyValue,
    this.additionalCopyLabel,
    this.additionalCopyMessage,
    required this.isMobile,
  });

  final KennelPageFormController controller;
  final String sidebarKey;
  final String label;
  final String? value;
  final String? url;
  final String? copyValue;
  final String? copyMessage;
  final bool showRegenerateButton;
  final VoidCallback? onRegenerate;
  final String? additionalCopyValue;
  final String? additionalCopyLabel;
  final String? additionalCopyMessage;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? url ?? '';
    final valueToCopy = copyValue ?? url ?? displayValue;

    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(sidebarKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.developer.key}_generic'),
      child: isMobile
          ? _buildMobileLayout(displayValue, valueToCopy)
          : _buildDesktopLayout(displayValue, valueToCopy),
    );
  }

  Widget _buildDesktopLayout(String displayValue, String valueToCopy) {
    return Row(
      children: [
        // Action buttons
        if (url != null) ...[
          _ActionButton(
            label: 'Try it',
            icon: FontAwesome5Solid.external_link_alt,
            color: Colors.green.shade600,
            onPressed: () => launchUrl(Uri.parse(url!)),
          ),
          const SizedBox(width: 8),
        ],
        _ActionButton(
          label: 'Copy',
          icon: FontAwesome5Solid.copy,
          color: Colors.blue.shade700,
          onPressed: () {
            unawaited(Clipboard.setData(ClipboardData(text: valueToCopy)));
            Get.snackbar(
              'Copied',
              copyMessage ?? 'Copied to clipboard',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
        ),
        if (showRegenerateButton) ...[
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Regenerate Key',
            icon: FontAwesome5Solid.sync_alt,
            color: Colors.orange.shade700,
            onPressed: onRegenerate,
          ),
        ],
        if (additionalCopyValue != null) ...[
          const SizedBox(width: 8),
          _ActionButton(
            label: additionalCopyLabel ?? 'Copy',
            icon: FontAwesome5Solid.code,
            color: Colors.orange.shade700,
            onPressed: () {
              unawaited(
                  Clipboard.setData(ClipboardData(text: additionalCopyValue!)));
              Get.snackbar(
                'Copied',
                additionalCopyMessage ?? 'Copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
        ],
        const SizedBox(width: 20),
        // Label and value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(String displayValue, String valueToCopy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (url != null)
              _ActionButton(
                label: 'Try it',
                icon: FontAwesome5Solid.external_link_alt,
                color: Colors.green.shade600,
                onPressed: () => launchUrl(Uri.parse(url!)),
              ),
            _ActionButton(
              label: 'Copy',
              icon: FontAwesome5Solid.copy,
              color: Colors.blue.shade700,
              onPressed: () {
                unawaited(Clipboard.setData(ClipboardData(text: valueToCopy)));
                Get.snackbar(
                  'Copied',
                  copyMessage ?? 'Copied to clipboard',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            if (showRegenerateButton)
              _ActionButton(
                label: 'Regenerate',
                icon: FontAwesome5Solid.sync_alt,
                color: Colors.orange.shade700,
                onPressed: onRegenerate,
              ),
          ],
        ),
      ],
    );
  }
}

/// A row widget for WordPress shortcodes with demo and copy buttons.
class _DeveloperShortcodeRow extends StatelessWidget {
  const _DeveloperShortcodeRow({
    required this.controller,
    required this.sidebarKey,
    required this.label,
    required this.shortcode,
    required this.demoUrl,
    required this.isMobile,
  });

  final KennelPageFormController controller;
  final String sidebarKey;
  final String label;
  final String shortcode;
  final String demoUrl;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(sidebarKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.developer.key}_generic'),
      child: Row(
        children: [
          _ActionButton(
            label: 'Try it',
            icon: FontAwesome5Solid.external_link_alt,
            color: Colors.green.shade600,
            onPressed: () => launchUrl(Uri.parse(demoUrl)),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Copy',
            icon: FontAwesome5Solid.copy,
            color: Colors.blue.shade700,
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: shortcode)));
              Get.snackbar(
                'Copied',
                '$label copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row widget for download links.
class _DeveloperDownloadRow extends StatelessWidget {
  const _DeveloperDownloadRow({
    required this.controller,
    required this.sidebarKey,
    required this.label,
    required this.downloadUrl,
    required this.isMobile,
  });

  final KennelPageFormController controller;
  final String sidebarKey;
  final String label;
  final String downloadUrl;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(sidebarKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.developer.key}_generic'),
      child: Row(
        children: [
          _ActionButton(
            label: 'Download',
            icon: FontAwesome5Solid.download,
            color: Colors.purple.shade600,
            onPressed: () => launchUrl(Uri.parse(downloadUrl)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A modern action button with icon.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
