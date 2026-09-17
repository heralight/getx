import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `GetPage.copyWith` dropped `restorationId` (it read the parameter
/// instead of `this.restorationId`) and did not carry
/// `preventDuplicateHandlingMode` at all. The router copies every matched
/// page, so the mode declared on a `GetPage` always fell back to
/// `reorderRoutes`.
void main() {
  test('copyWith keeps restorationId and preventDuplicateHandlingMode', () {
    final page = GetPage(
      name: '/a',
      page: () => const SizedBox(),
      restorationId: 'restore-a',
      preventDuplicateHandlingMode: PreventDuplicateHandlingMode.doNothing,
    );

    final copy = page.copyWith(title: 'copy');

    expect(
      copy.restorationId,
      'restore-a',
      reason: 'MUTATION: `restorationId ?? restorationId` loses it.',
    );
    expect(
      copy.preventDuplicateHandlingMode,
      PreventDuplicateHandlingMode.doNothing,
      reason: 'MUTATION: stop forwarding preventDuplicateHandlingMode and it '
          'falls back to reorderRoutes.',
    );
  });

  test('copyWith can override both fields', () {
    final copy = GetPage(name: '/a', page: () => const SizedBox()).copyWith(
      restorationId: 'other',
      preventDuplicateHandlingMode: PreventDuplicateHandlingMode.recreate,
    );
    expect(copy.restorationId, 'other');
    expect(copy.preventDuplicateHandlingMode,
        PreventDuplicateHandlingMode.recreate);
  });

  testWidgets('the mode declared on a GetPage reaches the router',
      (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/a',
      getPages: [
        GetPage(
          name: '/a',
          page: () => const Scaffold(body: Text('a')),
          preventDuplicateHandlingMode: PreventDuplicateHandlingMode.doNothing,
        ),
        GetPage(name: '/b', page: () => const Scaffold(body: Text('b'))),
      ],
    ));
    Get.toNamed('/b');
    await tester.pumpAndSettle();

    Get.toNamed('/a');
    await tester.pumpAndSettle();

    expect(
      Get.rootController.rootDelegate.activePages.map((e) => e.route?.name),
      ['/a', '/b'],
      reason: 'doNothing leaves the stack alone; the reorderRoutes fallback '
          'moves /a to the top.',
    );
  });
}
