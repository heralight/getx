import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Absent {}

void main() {
  test('find() of an unregistered type throws a catchable Exception', () {
    // MUTATION: revert to `throw '"$S" not found...'` and both of these fail:
    // a bare String is neither Exception nor Error, so `on Exception catch`
    // and `on Error catch` both miss it and it escapes to the zone.
    expect(() => Get.find<_Absent>(), throwsA(isA<Exception>()));

    var caught = false;
    try {
      Get.find<_Absent>();
    } on Exception catch (_) {
      caught = true;
    }
    expect(caught, isTrue, reason: '`on Exception catch` must catch it');
  });

  test('the message is preserved', () {
    try {
      Get.find<_Absent>();
      fail('should have thrown');
    } on Exception catch (e) {
      expect(e.toString(), contains('_Absent'));
      expect(e.toString(), contains('Get.put'));
    }
  });
}
