part of '../../kennel_website_page_ui.dart';

class _FeaturesTabContent extends StatelessWidget {
  const _FeaturesTabContent({required this.controller});

  final KennelWebsiteController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperWidgets().categoryLabelWidget('Pages'),
        const SizedBox(height: 8),
        _buildPageToggle(
          controller,
          key: 'showLanding',
          flag: controller.featShowLanding,
          label: 'Main landing page',
          description: 'Home page with hero, upcoming runs, and photo grid.',
        ),
        _buildPageToggle(
          controller,
          key: 'showRuns',
          flag: controller.featShowRuns,
          label: 'Runs',
          description: 'Run calendar with upcoming and past runs.',
        ),
        _buildPageToggle(
          controller,
          key: 'showAbout',
          flag: controller.featShowAbout,
          label: 'About Us',
          description: 'Club history and what is hashing.',
        ),
        _buildPageToggle(
          controller,
          key: 'showHistory',
          flag: controller.featShowHistory,
          label: 'History',
          description: 'Run archive and milestones. (Coming soon)',
        ),
        _buildPageToggle(
          controller,
          key: 'showEvents',
          flag: controller.featShowEvents,
          label: 'Events',
          description: 'Special events and social calendar. (Coming soon)',
        ),
        _buildPageToggle(
          controller,
          key: 'showStats',
          flag: controller.featShowStats,
          label: 'Stats',
          description: 'Attendance statistics and leaderboards. (Coming soon)',
        ),
        _buildPageToggle(
          controller,
          key: 'showSongs',
          flag: controller.featShowSongs,
          label: 'Songs',
          description: 'Hash song lyrics and audio.',
        ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Settings'),
        const SizedBox(height: 12),
        _PastRunsCountField(controller: controller),
      ],
    );
  }

  Widget _buildPageToggle(
    KennelWebsiteController controller, {
    required String key,
    required RxBool flag,
    required String label,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Obx(() {
        return SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text(description,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          value: flag.value,
          onChanged: (v) => controller.updateFeatureFlag(key, v),
          activeColor: Colors.teal.shade600,
        );
      }),
    );
  }
}

class _PastRunsCountField extends StatefulWidget {
  const _PastRunsCountField({required this.controller});
  final KennelWebsiteController controller;

  @override
  State<_PastRunsCountField> createState() => _PastRunsCountFieldState();
}

class _PastRunsCountFieldState extends State<_PastRunsCountField> {
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
        text: widget.controller.featPastRunsCount.value.toString());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentVal = widget.controller.featPastRunsCount.value.toString();
      if (_textCtrl.text != currentVal &&
          !_textCtrl.selection.isValid) {
        _textCtrl.text = currentVal;
      }
      return TextFormField(
        controller: _textCtrl,
        decoration: const InputDecoration(
          labelText: 'Past runs shown on home page (1–100)',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null) {
            widget.controller.updatePastRunsCount(parsed);
          }
        },
      );
    });
  }
}
