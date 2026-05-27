part of '../../kennel_page_new_ui.dart';

// Kennel Status enum values (from DomainValues.KennelStatusEnum):
//   2  = Active (default for new kennels)
//   1  = Inactive - Visible (visible in Kennel screen, inactive)
//   4  = Inactive - Hidden  (hidden from Kennel screen, inactive)
//  -1  = Defunct            (hidden from Kennel screen, permanently closed)
const Map<int, String> _kennelStatusLabels = {
  2: 'Active',
  1: 'Inactive - Visible',
  4: 'Inactive - Hidden',
  -1: 'Defunct',
};

class KennelPlatformAdminTabContent extends StatelessWidget {
  const KennelPlatformAdminTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelperWidgets().categoryLabelWidget('Kennel Status'),
          const SizedBox(height: 12),
          Obx(() {
            return DropdownButtonFormField<int>(
              initialValue: _kennelStatusLabels.containsKey(controller.kennelStatus.value)
                  ? controller.kennelStatus.value
                  : 2,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _kennelStatusLabels.entries
                  .map(
                    (e) => DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.updateKennelStatus(value);
              },
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Active: kennel appears in the Harrier Central app and on hashruns.org.\n'
            'Inactive - Visible: kennel is inactive but still listed in the Kennel screen.\n'
            'Inactive - Hidden: kennel is inactive and hidden from the Kennel screen.\n'
            'Defunct: permanently closed; hidden from the Kennel screen.\n'
            'Run history is always visible regardless of kennel status.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
