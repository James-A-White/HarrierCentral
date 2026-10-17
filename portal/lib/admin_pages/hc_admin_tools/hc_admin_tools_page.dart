import 'package:hcportal/imports.dart';

class HcAdminToolsPage extends StatelessWidget {
  const HcAdminToolsPage({
    super.key,
    this.allKennels = const [],
    this.canViewMonitor = false,
    this.canManageNewsflash = false,
    this.canManagePermissions = false,
    this.canEditKennel = false,
  });

  final List<HasherKennelsModel> allKennels;
  final bool canViewMonitor;
  final bool canManageNewsflash;
  final bool canManagePermissions;
  final bool canEditKennel;

  @override
  Widget build(BuildContext context) {
    // Each tool has its own colour, so the page reads at a glance (James,
    // 2026-10-17). The tiles flow into as many columns as the window fits.
    final List<_ToolCard> tools = [
      if (canViewMonitor)
        _ToolCard(
          title: 'Monitor',
          subtitle: 'Portal usage data and integration stats',
          icon: MaterialCommunityIcons.chart_line,
          colour: const Color(0xFF2563EB),
          onTap: () => Get.to<UsageDataPage>(UsageDataPage.new),
        ),
      if (canManageNewsflash) ...[
        _ToolCard(
          title: 'Newsflash',
          subtitle: 'Create and manage portal newsflashes',
          icon: MaterialCommunityIcons.bullhorn,
          colour: const Color(0xFFEA580C),
          onTap: () => Get.to<NewsflashManagementPage>(
            () => NewsflashManagementPage(allKennels: allKennels),
          ),
        ),
        _ToolCard(
          title: 'Version email',
          subtitle:
              'Email everyone still on an app version, with store buttons',
          icon: MaterialCommunityIcons.cellphone_arrow_down,
          colour: const Color(0xFF16A34A),
          onTap: () => Get.to<VersionEmailPage>(VersionEmailPage.new),
        ),
      ],
      if (canEditKennel) ...[
        _ToolCard(
          title: 'Kennel requests',
          subtitle: 'Review and approve kennels asking to join',
          icon: MaterialCommunityIcons.home_plus,
          colour: const Color(0xFF0D9488),
          onTap: () => Get.to<KennelRequestsPage>(KennelRequestsPage.new),
        ),
        _ToolCard(
          title: 'Merge accounts',
          subtitle:
              'One person, two accounts: move everything to one and disable the other',
          icon: MaterialCommunityIcons.account_multiple_check,
          colour: const Color(0xFF9333EA),
          onTap: () => Get.to<MergeHashersPage>(MergeHashersPage.new),
        ),
      ],
      if (canManagePermissions) ...[
        _ToolCard(
          title: 'Permissions',
          subtitle:
              'Global defaults — per-kennel overrides live in each kennel',
          icon: MaterialCommunityIcons.shield_key,
          colour: const Color(0xFFDC2626),
          onTap: () => Get.to<PermissionsPage>(PermissionsPage.new),
        ),
        _ToolCard(
          title: 'Platform admins',
          subtitle:
              'Who is Harrier Central staff: mint, change or remove a platform admin',
          icon: MaterialCommunityIcons.shield_account,
          colour: const Color(0xFF4F46E5),
          onTap: () => Get.to<PlatformAdminsPage>(PlatformAdminsPage.new),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('HC Admin Tools'),
        leading: GestureDetector(
          onTap: () => Get.back<void>(),
          child: const Icon(
            MaterialCommunityIcons.arrow_left,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: tools,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tool Card Widget
// ---------------------------------------------------------------------------

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colour,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color colour;
  final VoidCallback onTap;

  static const double width = 352;

  @override
  Widget build(BuildContext context) {
    // At most [width]; narrower when the window is (a phone), never overflowing.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: width),
      child: SizedBox(
        width: double.infinity,
        height: 108,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // The icon on a soft tile of its own colour.
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colour.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 30, color: colour),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    MaterialCommunityIcons.chevron_right,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
