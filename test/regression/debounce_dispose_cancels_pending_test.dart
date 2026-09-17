import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Disposing a `debounce` worker cancelled its stream subscription but not
/// the `Debouncer` timer already armed: the callback still fired after
/// `dispose()`, typically on a controller that had just been closed.
void main() {
  const delay = Duration(milliseconds: 50);
  Future<void> waitPastDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  test('dispose() cancels a pending debounce callback', () async {
    final rx = 0.obs;
    var calls = 0;
    final worker = debounce<int>(rx, (_) => calls++, time: delay);

    rx.value = 1;
    await Future<void>.delayed(Duration.zero); // event delivered, timer armed
    worker.dispose();
    await waitPastDelay();

    expect(
      calls,
      0,
      reason: 'MUTATION: stop cancelling the Debouncer in the worker '
          'disposer and the callback fires after dispose().',
    );
  });

  test('without dispose, the debounced callback still fires once', () async {
    final rx = 0.obs;
    final values = <int>[];
    final worker = debounce<int>(rx, values.add, time: delay);

    rx.value = 1;
    rx.value = 2;
    await waitPastDelay();

    expect(values, [2]);
    worker.dispose();
  });
}
