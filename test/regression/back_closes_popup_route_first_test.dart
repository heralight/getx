import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Dialogs and bottom sheets are pageless `PopupRoute`s pushed on the
/// Navigator above the current `GetPage`. `Get.back()` only looked at the
/// `GetPage` stack, so with an overlay open it popped the page *under* the
/// overlay and left the overlay on screen.
void main() {
  Widget app() => GetMaterialApp(
        initialRoute: '/first',
        getPages: [
          GetPage(name: '/first', page: () => const Scaffold(body: Text('1'))),
          GetPage(name: '/second', page: () => const Scaffold(body: Text('2'))),
        ],
      );

  testWidgets('Get.back() closes an open dialog, not the page under it',
      (tester) async {
    await tester.pumpWidget(app());
    Get.toNamed('/second');
    await tester.pumpAndSettle();

    Get.dialog(const AlertDialog(content: Text('dialog')));
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();

    expect(
      find.text('dialog'),
      findsNothing,
      reason: 'MUTATION: drop the PopupRoute check in Get.back() and the '
          'dialog stays open while the page under it is popped.',
    );
    expect(Get.currentRoute, '/second');
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Get.back() closes an open bottom sheet, not the page under it',
      (tester) async {
    await tester.pumpWidget(app());
    Get.toNamed('/second');
    await tester.pumpAndSettle();

    Get.bottomSheet(const Material(child: Text('sheet')));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('sheet'), findsNothing);
    expect(Get.currentRoute, '/second');
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Get.back() closes a dialog opened on the root page',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    Get.dialog(const AlertDialog(content: Text('dialog')));
    await tester.pumpAndSettle();

    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('dialog'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Get.back(result:) completes the future of the dialog',
      (tester) async {
    await tester.pumpWidget(app());
    Get.toNamed('/second');
    await tester.pumpAndSettle();

    String? result;
    Get.dialog<String>(const AlertDialog(content: Text('dialog')))
        .then((v) => result = v);
    await tester.pumpAndSettle();

    Get.back<String>(result: 'picked');
    await tester.pumpAndSettle();

    expect(result, 'picked');
    expect(Get.currentRoute, '/second');
  });

  testWidgets('without an overlay, Get.back() still pops the page',
      (tester) async {
    await tester.pumpWidget(app());
    Get.toNamed('/second');
    await tester.pumpAndSettle();

    Get.back();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/first');
    expect(find.text('1'), findsOneWidget);
  });
}
