import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `bindStream` only handed its subscription to `reportAdd`, which records
/// it solely while an `Obx`/`GetX` build is running. Called anywhere else --
/// typically `onInit` -- the subscription was never cancelled: closing the
/// Rx left the source stream listened to for the lifetime of the process.
void main() {
  test('closing the Rx cancels a stream bound outside a build', () async {
    var cancelled = false;
    final source = StreamController<int>(onCancel: () => cancelled = true);
    final rx = 0.obs;

    rx.bindStream(source.stream);
    source.add(1);
    await Future<void>.delayed(Duration.zero);
    expect(rx.value, 1, reason: 'the binding works while the Rx is open');

    rx.close();
    await Future<void>.delayed(Duration.zero);

    expect(
      cancelled,
      isTrue,
      reason: 'MUTATION: stop cancelling the bound subscriptions in close() '
          'and the source keeps its listener forever.',
    );
    expect(source.hasListener, isFalse);
  });

  test('every bound stream is cancelled', () async {
    final a = StreamController<int>();
    final b = StreamController<int>();
    final rx = RxList<int>();

    rx.bindStream(a.stream.map((v) => [v]));
    rx.bindStream(b.stream.map((v) => [v]));
    rx.close();
    await Future<void>.delayed(Duration.zero);

    expect(a.hasListener || b.hasListener, isFalse);
  });
}
