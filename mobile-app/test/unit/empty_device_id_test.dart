import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/data/services/service_common.dart';

// sendHttpPost refuses a request whose deviceId is an empty STRING (the
// server cannot convert '' to an id: 5x 500 on 2026-10-17), but must still
// send sign-up's deliberate null and any request without the key.
void main() {
  test('an empty-string deviceId is refused', () {
    expect(ServiceCommon.hasEmptyDeviceId('{"queryType":"syncUserData","deviceId":""}'), isTrue);
    expect(ServiceCommon.hasEmptyDeviceId('{"deviceId":"   "}'), isTrue);
  });
  test("sign-up's null deviceId is allowed", () {
    expect(ServiceCommon.hasEmptyDeviceId('{"queryType":"addEditUser","deviceId":null}'), isFalse);
  });
  test('a real deviceId, no deviceId, or a non-JSON body is allowed', () {
    expect(ServiceCommon.hasEmptyDeviceId('{"deviceId":"3bcdbf85-2857-482a-8bb3-23601e3e6d6c"}'), isFalse);
    expect(ServiceCommon.hasEmptyDeviceId('{"queryType":"checkConnection"}'), isFalse);
    expect(ServiceCommon.hasEmptyDeviceId('not json'), isFalse);
  });
}
