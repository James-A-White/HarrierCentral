import 'package:hcportal/imports.dart';

class HcAdminToolsPage extends StatelessWidget {
  const HcAdminToolsPage({
    super.key,
    this.allKennels = const [],
    this.canViewMonitor = false,
    this.canManageNewsflash = false,
    this.canManagePermissions = false,
  });

  final List<HasherKennelsModel> allKennels;
  final bool canViewMonitor;
  final bool canManageNewsflash;
  final bool canManagePermissions;

  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              if (canViewMonitor) ...[
                _ToolCard(
                  title: 'Monitor',
                  subtitle: 'Portal usage data and integration stats',
                  icon: MaterialCommunityIcons.chart_bar,
                  onTap: () => Get.to<UsageDataPage>(UsageDataPage.new),
                ),
                const SizedBox(height: 16),
              ],
              if (canManageNewsflash) ...[
                _ToolCard(
                  title: 'Newsflash',
                  subtitle: 'Create and manage portal newsflashes',
                  icon: MaterialCommunityIcons.bell_alert,
                  onTap: () => Get.to<NewsflashManagementPage>(
                    () => NewsflashManagementPage(allKennels: allKennels),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (canManagePermissions)
                _ToolCard(
                  title: 'Permissions',
                  subtitle: 'Global defaults — per-kennel overrides live in each kennel',
                  icon: MaterialCommunityIcons.shield_key,
                  onTap: () => Get.to<PermissionsPage>(PermissionsPage.new),
                ),
            ],
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
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 32, color: const Color(0xFF1E40AF)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
    );
  }
}
