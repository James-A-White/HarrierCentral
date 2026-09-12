import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:harrier_central/data/services/service_common.dart';
import 'package:harrier_central/services/connectivity_service.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

/// The failure an iOS suspend leaves behind: a 500 with no body, from a socket
/// the OS tore down. The 599 stall is the same shape, synthesised after 30 s —
/// which is precisely why a ten-second wake window could never catch it.
void main() {
  // The settled path reaches the banner, which asks GetX for a context.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // The settled path consults the network service before it decides whether
    // to say anything. backendReachable stays false here, so nothing is shown
    // and the test is only counting sends.
    Get.put(NetworkService());
  });

  test('the first request after waking is retried once, silently', () async {
    int calls = 0;
    final MockClient client = MockClient((Request r) async {
      calls++;
      return calls == 1
          ? Response('', 500) // killed by the wake
          : Response('[[{"success":1}]]', 200);
    });

    ServiceCommon.notePaused();
    ServiceCommon.noteResumed();

    final String body = await ServiceCommon.sendHttpPost(
      () => '{"queryType":"syncUserData"}',
      client: client,
      bypassConnectionCheck: true,
      noRetries: true, // even a caller that forbids retries gets this one
    );

    expect(calls, 2, reason: 'the request should have been sent again');
    expect(body, '[[{"success":1}]]');
  });

  test('a success settles the wake, so the next failure is not excused',
      () async {
    int calls = 0;
    final MockClient client = MockClient((Request r) async {
      calls++;
      return calls == 1
          ? Response('[[{"success":1}]]', 200) // settles the wake
          : Response('', 500);
    });

    ServiceCommon.notePaused();
    ServiceCommon.noteResumed();

    await ServiceCommon.sendHttpPost(
      () => '{"queryType":"checkConnection"}',
      client: client,
      bypassConnectionCheck: true,
      noRetries: true,
    );
    expect(calls, 1);

    // Second call: the wake is settled, so the silent suspend retry must not
    // fire and a noRetries caller sends exactly once.
    await ServiceCommon.sendHttpPost(
      () => '{"queryType":"syncUserData"}',
      client: client,
      bypassConnectionCheck: true,
      noRetries: true,
    );
    expect(calls, 2, reason: 'no extra send once the wake has settled');
  });
}
