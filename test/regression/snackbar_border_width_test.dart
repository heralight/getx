import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `Get.snackbar` declares `double? borderWidth` (extension_navigation.dart)
/// and forwards it verbatim, so passing a `borderColor` without a
/// `borderWidth` sends an explicit null into `GetSnackBar` -- which overrides
/// its own `= 1.0` constructor default. The widget then evaluated
/// `width: widget.borderWidth!` and the null check threw.
///
/// A null check is an Error, not an Exception, and it is raised inside the
/// job `SnackbarController` runs on `GetQueue`: before the queue fix on this
/// branch, this single crash froze the queue and no snackbar was ever shown
/// again for the rest of the session.
void main() {
  Future<void> pumpBar(WidgetTester tester, GetSnackBar bar) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: bar)));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Iterable<double> borderWidths(WidgetTester tester) => tester
      .widgetList<Container>(find.byType(Container))
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .map((d) => d.border)
      .whereType<Border>()
      .map((b) => b.top.width);

  testWidgets('a borderColor with a null borderWidth does not crash',
      (tester) async {
    // Exactly what `Get.snackbar(borderColor: ...)` forwards.
    await pumpBar(
      tester,
      const GetSnackBar(
        message: 'message',
        borderColor: Colors.red,
        borderWidth: null,
        duration: Duration(milliseconds: 100),
      ),
    );

    // MUTATION: restore `width: widget.borderWidth!` in snackbar.dart and
    // this fails with "Null check operator used on a null value".
    expect(tester.takeException(), isNull);
    expect(borderWidths(tester), contains(1.0),
        reason: 'falls back to the documented default of 1.0');

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('an explicit borderWidth is still honoured', (tester) async {
    await pumpBar(
      tester,
      const GetSnackBar(
        message: 'm',
        borderColor: Colors.blue,
        borderWidth: 4,
        duration: Duration(milliseconds: 100),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(borderWidths(tester), contains(4.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('no borderColor means no border at all', (tester) async {
    await pumpBar(
      tester,
      const GetSnackBar(
        message: 'm',
        duration: Duration(milliseconds: 100),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(borderWidths(tester), isEmpty);

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });
}
