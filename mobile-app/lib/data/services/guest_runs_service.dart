import 'package:harrier_central/imports.dart';
import 'package:http/http.dart' as http;

class GuestRunsService {
  static Future<({bool success, int total, List<GuestRunModel> runs})>
      getGlobalRuns({
    required bool isFuture,
    int pageSize = 500,
    String? minEventDate,
  }) async {
    final Map<String, String> params = <String, String>{
      'queryType': 'getGlobalRuns',
      'IsFuture': isFuture ? '1' : '0',
      'PageSize': pageSize.toString(),
    };
    if (minEventDate != null) params['MinEventDate'] = minEventDate;

    final Uri uri =
        Uri.https(BASE_AF_URL, '/api/PublicWebApi', params);

    try {
      final http.Response response =
          await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return (success: false, total: 0, runs: <GuestRunModel>[]);
      }

      final List<dynamic> rowsets =
          jsonDecode(response.body) as List<dynamic>;

      if (rowsets.length < 2) {
        return (success: false, total: 0, runs: <GuestRunModel>[]);
      }

      // Rowset 0: { TotalMatchingEvents }
      final List<dynamic> countList = rowsets[0] as List<dynamic>;
      final int total = countList.isNotEmpty
          ? (countList[0] as Map<String, dynamic>)['TotalMatchingEvents']
                  as int? ??
              0
          : 0;

      // Rowset 1: one row per event
      final List<dynamic> eventList = rowsets[1] as List<dynamic>;
      final List<GuestRunModel> runs = eventList
          .map((dynamic r) =>
              GuestRunModel.fromJson(r as Map<String, dynamic>))
          .toList();

      return (success: true, total: total, runs: runs);
    } catch (_) {
      return (success: false, total: 0, runs: <GuestRunModel>[]);
    }
  }
}
