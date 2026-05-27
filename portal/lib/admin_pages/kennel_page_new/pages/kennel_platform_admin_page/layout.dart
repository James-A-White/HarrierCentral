part of '../../kennel_page_new_ui.dart';

// Kennel Status enum values (from DomainValues.KennelStatusEnum):
//   1 = Active (default)
//   2 = Inactive
//   3 = Defunct
const Map<int, String> _kennelStatusLabels = {
  1: 'Active',
  2: 'Inactive',
  3: 'Defunct',
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
                  : 1,
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
            'Active kennels appear in the Harrier Central app and on hashruns.org.\n'
            'Inactive kennels are hidden from discovery but remain accessible to admins.\n'
            'Defunct kennels are permanently closed.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
