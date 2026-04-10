import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// HC Admin Tools Hub Page
//
// Gate: hard-coded to HC_PORTAL_ADMIN_OPEE and HC_PORTAL_ADMIN_TUNA,
// same as the Monitor feature it replaces.
// ---------------------------------------------------------------------------

class HcAdminToolsPage extends StatelessWidget {
  const HcAdminToolsPage({super.key, this.allKennels = const []});

  final List<HasherKennelsModel> allKennels;

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
              _ToolCard(
                title: 'Monitor',
                subtitle: 'Portal usage data and integration stats',
                icon: MaterialCommunityIcons.chart_bar,
                onTap: () => Get.to<UsageDataPage>(UsageDataPage.new),
              ),
              const SizedBox(height: 16),
              _ToolCard(
                title: 'Newsflash',
                subtitle: 'Create and manage portal newsflashes',
                icon: MaterialCommunityIcons.bell_alert,
                onTap: () => Get.to<NewsflashManagementPage>(
                  () => NewsflashManagementPage(allKennels: allKennels),
                ),
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
