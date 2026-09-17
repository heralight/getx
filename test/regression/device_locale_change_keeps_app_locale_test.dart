import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_root.dart';

/// `didChangeLocales` applied the device locale unconditionally, so a
/// system language change replaced the language the application had
/// chosen with `Get.updateLocale` or `GetMaterialApp(locale:)`.
void main() {
  Widget app({Locale? locale}) => GetMaterialApp(
        locale: locale,
        home: const Scaffold(),
      );

  Future<void> changeDeviceLocale(WidgetTester tester, Locale l) async {
    tester.platformDispatcher.localeTestValue = l;
    tester.platformDispatcher.localesTestValue = [l];
    await tester.pumpAndSettle();
  }

  tearDown(() {
    Get.locale = null;
    GetRootState.localeSetExplicitly = false;
  });

  testWidgets('without an explicit choice, the device locale is followed',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await changeDeviceLocale(tester, const Locale('fr', 'FR'));
    expect(Get.locale, const Locale('fr', 'FR'));

    await changeDeviceLocale(tester, const Locale('es', 'ES'));
    expect(
      Get.locale,
      const Locale('es', 'ES'),
      reason: 'a locale adopted from the device keeps following the device',
    );
  });

  testWidgets('a locale set with Get.updateLocale survives a device change',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    Get.updateLocale(const Locale('de', 'DE'));
    await tester.pumpAndSettle();

    await changeDeviceLocale(tester, const Locale('fr', 'FR'));

    expect(
      Get.locale,
      const Locale('de', 'DE'),
      reason: 'MUTATION: apply the device locale unconditionally in '
          'didChangeLocales and the app language is replaced.',
    );
  });

  testWidgets(
      'Get.updateLocale to the locale last adopted from the device is '
      'still an explicit choice', (tester) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await changeDeviceLocale(tester, const Locale('fr', 'FR'));
    expect(Get.locale, const Locale('fr', 'FR'));

    Get.updateLocale(const Locale('fr', 'FR'));
    await tester.pumpAndSettle();

    await changeDeviceLocale(tester, const Locale('es', 'ES'));
    expect(
      Get.locale,
      const Locale('fr', 'FR'),
      reason: 'MUTATION: drop the flag set by Get.updateLocale and this '
          'choice is indistinguishable from an automatic adoption.',
    );
  });

  testWidgets('a locale given to GetMaterialApp survives a device change',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(app(locale: const Locale('de', 'DE')));
    await tester.pumpAndSettle();

    await changeDeviceLocale(tester, const Locale('fr', 'FR'));

    expect(Get.locale, const Locale('de', 'DE'));
  });
}
