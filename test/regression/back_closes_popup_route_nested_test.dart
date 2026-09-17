import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Nested navigation for the `Get.back()` overlay fix: a dialog pushed on a
/// nested navigator (`Get.dialog(id:)`) is closed by `Get.back(id:)`, which
/// inspects that navigator's top route, and not by a `Get.back()` aimed at
/// the root navigator, nor the other way round.
void main() {
  const nested = '/home';

  Widget app() => GetMaterialApp(
        initialRoute: '/home/one',
        getPages: [
          GetPage(
            name: '/home',
            participatesInRootNavigator: true,
            page: () => Scaffold(
              body: GetRouterOutlet(
                initialRoute: '/home/one',
                anchorRoute: nested,
              ),
            ),
            children: [
              GetPage(
                name: '/one',
                page: () => const Scaffold(body: Text('one')),
              ),
            ],
          ),
        ],
      );

  NavigatorState nestedNavigator() =>
      Get.nestedKey(nested)!.navigatorKey.currentState!;

  testWidgets('Get.back(id:) closes a dialog open on the nested navigator',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('one'), findsOneWidget);

    String? result;
    Get.dialog<String>(const AlertDialog(content: Text('dialog')), id: nested)
        .then((v) => result = v);
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);
    expect(ModalRoute.of(tester.element(find.text('dialog'))),
        isA<PopupRoute>());
    expect(nestedNavigator().canPop(), isTrue,
        reason: 'the dialog is on the nested navigator');

    Get.back<String>(result: 'picked', id: nested);
    await tester.pumpAndSettle();

    expect(
      find.text('dialog'),
      findsNothing,
      reason: 'MUTATION: drop the PopupRoute check in Get.back() and the '
          'nested dialog stays open.',
    );
    expect(result, 'picked');
    expect(find.text('one'), findsOneWidget);
    expect(Get.rootController.rootDelegate.activePages.length, 1);
  });

  testWidgets('Get.back() without id leaves a nested dialog alone',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    Get.dialog(const AlertDialog(content: Text('dialog')), id: nested);
    await tester.pumpAndSettle();

    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('dialog'), findsOneWidget,
        reason: 'the root navigator top route is a page, not the dialog');
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('Get.back(id:) leaves a dialog on the root navigator alone',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    Get.dialog(const AlertDialog(content: Text('dialog')));
    await tester.pumpAndSettle();
    expect(nestedNavigator().canPop(), isFalse,
        reason: 'the dialog is on the root navigator');

    Get.back(id: nested);
    await tester.pumpAndSettle();

    expect(find.text('dialog'), findsOneWidget);
    expect(find.text('one'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsNothing);
  });
}
