import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `PreventDuplicateHandlingMode.popUntilOriginalRoute`: pushing a route
/// already on the stack pops the pages above the original entry until it is
/// the top page again, without popping the original itself.
///
/// The loop condition was inverted (`while (last == original)`): with the
/// original below the top nothing happened; with the original on top it was
/// popped itself.
void main() {
  const mode = PreventDuplicateHandlingMode.popUntilOriginalRoute;

  Widget app() => GetMaterialApp(
        initialRoute: '/a',
        getPages: [
          GetPage(
            name: '/a',
            page: () => const Scaffold(body: Text('a')),
            preventDuplicateHandlingMode: mode,
          ),
          GetPage(
            name: '/b',
            page: () => const Scaffold(body: Text('b')),
            preventDuplicateHandlingMode: mode,
          ),
          GetPage(name: '/c', page: () => const Scaffold(body: Text('c'))),
        ],
      );

  List<String?> stack() => Get.rootController.rootDelegate.activePages
      .map((e) => e.route?.name)
      .toList();

  testWidgets('pops the pages above the original route', (tester) async {
    await tester.pumpWidget(app());
    var bSettled = false;
    var cSettled = false;
    Get.toNamed<void>('/b')?.then((_) => bSettled = true);
    await tester.pumpAndSettle();
    Get.toNamed<void>('/c')?.then((_) => cSettled = true);
    await tester.pumpAndSettle();
    expect(stack(), ['/a', '/b', '/c']);

    Get.toNamed('/a');
    await tester.pumpAndSettle();

    expect(
      stack(),
      ['/a'],
      reason: 'MUTATION: `while (_activePages.last == onStackPage)` leaves '
          'the stack untouched.',
    );
    expect(find.text('a'), findsOneWidget);
    expect(bSettled && cSettled, isTrue,
        reason: 'the popped pages complete their futures');
  });

  testWidgets('does not pop the original route when it is already on top',
      (tester) async {
    await tester.pumpWidget(app());
    Get.toNamed('/b');
    await tester.pumpAndSettle();

    Get.toNamed('/b');
    await tester.pumpAndSettle();

    expect(
      stack(),
      ['/a', '/b'],
      reason: 'MUTATION: the inverted loop pops /b itself.',
    );
    expect(find.text('b'), findsOneWidget);
  });
}
