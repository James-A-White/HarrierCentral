import 'package:hcportal/imports.dart';
import 'package:hcportal/admin_pages/usage_data_page/usage_data_page_controller.dart';
import 'package:intl/intl.dart';

class LoginHistoryDialog extends StatelessWidget {
  const LoginHistoryDialog({
    required this.userId,
    required this.userName,
    this.realName = '',
    required this.controller,
    super.key,
  });

  final String userId;
  final String userName;
  final String realName;
  final UsageDataPageController controller;

  @override
  Widget build(BuildContext context) {
    final _historyFuture = controller.getLoginHistory(userId);
    return Dialog(
      child: Container(
        width: 700,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              realName.isNotEmpty
                  ? 'Login History – $userName ($realName)'
                  : 'Login History – $userName',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<UdLoginHistoryModel>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${snapshot.data!.length} logins in the last 365 days',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: Colors.grey.shade200,
              child: const Row(
                children: <Widget>[
                  Expanded(
                      flex: 3,
                      child: Text('Date',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(
                      flex: 2,
                      child: Text('App Version',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(flex: 1, child: SizedBox()),
                  Expanded(
                      flex: 2,
                      child: Text('OS Version',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(
                      flex: 3,
                      child: Text('Location',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const Divider(height: 1),
            // Data rows
            Expanded(
              child: FutureBuilder<List<UdLoginHistoryModel>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Text('Failed to load login history'),
                    );
                  }

                  final history = snapshot.data!;
                  if (history.isEmpty) {
                    return const Center(
                      child: Text('No login history found'),
                    );
                  }

                  final sevenDaysAgo =
                      DateTime.now().subtract(const Duration(days: 7));

                  return Column(
                    children: <Widget>[
                      Expanded(
                        child: ListView.separated(
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = history[index];
                            final dateStr = DateFormat('MMM d, yyyy  h:mm a')
                                .format(entry.loginDate);
                            final hasLocation =
                                entry.latitude != 0.0 || entry.longitude != 0.0;
                            final locationStr = hasLocation
                                ? entry.locationName.isNotEmpty
                                    ? entry.locationName
                                    : '${entry.latitude.toStringAsFixed(4)}, ${entry.longitude.toStringAsFixed(4)}'
                                : '—';
                            final isRecent =
                                entry.loginDate.isAfter(sevenDaysAgo);
                            final textColor =
                                isRecent ? Colors.blue.shade900 : Colors.black;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: Text(dateStr,
                                        style: TextStyle(color: textColor)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(entry.hcVersion,
                                        style: TextStyle(color: textColor)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Icon(
                                      entry.isIphone == 1
                                          ? MaterialCommunityIcons.apple
                                          : MaterialIcons.android,
                                      color: entry.isIphone == 1
                                          ? Colors.grey.shade700
                                          : Colors.green.shade700,
                                      size: 16,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(entry.systemVersion,
                                        style: TextStyle(color: textColor)),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: hasLocation
                                        ? GestureDetector(
                                            onTap: () {
                                              openWindow(
                                                'https://www.google.com/maps?q=${entry.latitude},${entry.longitude}',
                                                '_blank',
                                              );
                                            },
                                            child: Text(
                                              locationStr,
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          )
                                        : Text(locationStr,
                                            style: TextStyle(color: textColor)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
