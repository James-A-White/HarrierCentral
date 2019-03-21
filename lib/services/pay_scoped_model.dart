
import 'package:harrier_central/data_models/pay_for_event_model.dart';
import 'package:harrier_central/services/pay_for_event_service.dart';
import 'package:harrier_central/data_models/user_model.dart';

import 'package:scoped_model/scoped_model.dart';

class PayScopedModel extends Model {
  PayForEventModel _payResult;
  PayForEventModel get payResult => _payResult;

  // int getPackCount() {
  //   return _payResult.length;
  // }

  Future<List<PayForEventModel>> payForEvent(
      List<UserModel> packList, int index, int paymentType, num paymentAmount, num minimumAttendenceValue) {
    // if ((rsvpState != -1) && (rsvpState != run.rsvpState)) {
    //   run.requestedRsvpState = rsvpState;
    //   run.rsvpState = -1;
    //   isDirty = true;
    // }

    // if ((isHare != -1) && (isHare != run.isHare)) {
    //   run.requestedHaringState = isHare;
    //   run.isHare = -1;
    //   isDirty = true;
    // }

    // if ((attendenceState != -1) && (run.attendenceState != attendenceState)) {
    //   run.requestedAttendenceState = attendenceState;
    //   run.attendenceState = -1;
    //   isDirty = true;
    // }

    notifyListeners();
    final PayForEventService srv = PayForEventService();

    return srv
        .payForEvent(packList[index].hasherId, packList[index].eventId,
            packList[index].hasherEventMapId, paymentType, paymentAmount, minimumAttendenceValue);
       // .then<dynamic>((List<PayForEventModel> result) {

      // if (paymentType == paymentNotPaid.value) {
      //   packList[index].isPaid = 0;
      // } else {
      //   packList[index].isPaid = 1;
      // } 

      

      // if ((rsvpState != -1) && (rsvpState != run.rsvpState)) {
      //   run.rsvpState = rsvpState;
      //   run.requestedRsvpState = -1;
      // }

      // if ((isHare != -1) && (isHare != run.isHare)) {
      //   run.isHare = isHare;
      //   run.requestedHaringState = -1;
      // }

      // if ((attendenceState != -1) && (run.attendenceState != attendenceState)) {
      //   run.attendenceState = attendenceState;
      //   run.requestedAttendenceState = -1;
      // }

      // run.rsvpYesCount = result.rsvpYesCount;
      // run.rsvpNoCount = result.rsvpNoCount;
      // run.rsvpMaybeCount = result.rsvpMaybeCount;
      // run.haresCount = result.haresCount;

    //   notifyListeners();
    // });

    //// return Future<void>(() {});((){});
  }
}
