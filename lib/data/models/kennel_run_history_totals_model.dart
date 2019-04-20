
import 'dart:convert';
import 'dart:core';

class KennelRunHistoryTotals {
  KennelRunHistoryTotals(
      {this.kennelId,
      this.kennelLogo,
      this.kennelName,
      this.totalRunsThisKennel,
      this.totalPackRunsThisKennel,
      this.totalHaringThisKennel,
      this.following,
      this.kennelShortName
      });

	final String kennelId;
	final String kennelLogo;
	final String kennelName;
  int totalRunsThisKennel;
  int totalPackRunsThisKennel;
  int totalHaringThisKennel;
  int following;
	final String kennelShortName;


    static List<KennelRunHistoryTotals> itemsFromJson(String jsonResult)
  {
    final List<KennelRunHistoryTotals> items = <KennelRunHistoryTotals>[];

    KennelRunHistoryTotals item;

    json.decode(jsonResult).forEach(
      (dynamic jsonItem) {
        item = KennelRunHistoryTotals(
          kennelId: jsonItem['kennelId'],
          kennelLogo: jsonItem['kennelLogo'],
          kennelName: jsonItem['kennelName'],
          totalRunsThisKennel: jsonItem['totalRunsThisKennel'],
          totalHaringThisKennel: jsonItem['totalHaringThisKennel'],
          totalPackRunsThisKennel: jsonItem['totalPackRunsThisKennel'],
          following: jsonItem['following'],
          kennelShortName: jsonItem['kennelShortName'],
        );

        items.add(item);
      },
    );

    if (items.isEmpty)
    {
      return null;
    }

    return items;
  }





  @override
  String toString() => '$kennelName';
}
