import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// An `interval` worker waits `time` after the first change before calling
/// back. Disposing the worker during that wait cancelled the subscription
/// but not the wait: the callback still fired after `dispose()`.
void main() {
  const time = Duration(milliseconds: 50);
  Future<void> waitPastTime() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  test('dispose() cancels a pending interval callback', () async {
    final rx = 0.obs;
    var calls = 0;
    final worker = interval<int>(rx, (_) => calls++, time: time);

    rx.value = 1;
    await Future<void>.delayed(Duration.zero); // event delivered, wait begun
    worker.dispose();
    await waitPastTime();

    expect(
      calls,
      0,
      reason: 'MUTATION: remove the disposed check after the wait and the '
          'callback fires after dispose().',
    );
  });

  test('without dispose, interval still delivers the first value', () async {
    final rx = 0.obs;
    final values = <int>[];
    final worker = interval<int>(rx, values.add, time: time);

    rx.value = 1;
    await Future<void>.delayed(Duration.zero);
    rx.value = 2;
    await waitPastTime();

    expect(values, [1]);
    worker.dispose();
  });
}
