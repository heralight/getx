import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `toNamed` to a page already on the stack, with a
/// `PreventDuplicateHandlingMode` that pushes nothing (`doNothing`,
/// `popUntilOriginalRoute`): the future returned by `toNamed` must complete.
///
/// `_configureRouterDecoder` gives every call a fresh completer, and `_push`
/// returned its future even when the entry was never added to the stack, so
/// no pop could ever complete it and `await Get.toNamed(...)` hung forever.
void main() {
  Widget app(PreventDuplicateHandlingMode mode) => GetMaterialApp(
        initialRoute: '/a',
        getPages: [
          GetPage(name: '/a', page: () => const Scaffold(body: Text('a'))),
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

  String? result;

  /// Pushes /b then /c, then `toNamed('/b')` again. Returns whether the
  /// duplicate call's future completed within the (fake-async) delay.
  Future<bool> duplicateCompletes(
    WidgetTester tester,
    PreventDuplicateHandlingMode mode,
  ) async {
    await tester.pumpWidget(app(mode));
    Get.toNamed<void>('/b');
    await tester.pumpAndSettle();
    Get.toNamed<void>('/c');
    await tester.pumpAndSettle();

    var completed = false;
    result = 'pending';
    Get.toNamed<String>('/b')?.then((v) {
      completed = true;
      result = v;
    });
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    return completed;
  }

  testWidgets('doNothing: the duplicate toNamed future completes',
      (tester) async {
    final completed = await duplicateCompletes(
        tester, PreventDuplicateHandlingMode.doNothing);
    expect(stack(), ['/a', '/b', '/c']);
    expect(
      completed,
      isTrue,
      reason: 'MUTATION: return the new completer future when nothing is '
          'pushed and `await Get.toNamed` hangs forever.',
    );
    expect(result, isNull, reason: 'nothing was pushed: completes with null');
  });

  testWidgets('popUntilOriginalRoute: the duplicate toNamed future completes',
      (tester) async {
    final completed = await duplicateCompletes(
        tester, PreventDuplicateHandlingMode.popUntilOriginalRoute);
    expect(stack(), ['/a', '/b']);
    expect(
      completed,
      isTrue,
      reason: 'MUTATION: return the new completer future when nothing is '
          'pushed and `await Get.toNamed` hangs forever.',
    );
    expect(result, isNull, reason: 'nothing was pushed: completes with null');
  });

  testWidgets('reorderRoutes (control): the future follows the moved page',
      (tester) async {
    final completed = await duplicateCompletes(
        tester, PreventDuplicateHandlingMode.reorderRoutes);
    expect(stack(), ['/a', '/c', '/b']);
    expect(completed, isFalse,
        reason: 'the reordered /b is the pushed entry: pending until popped');

    Get.back<String>(result: 'done');
    await tester.pumpAndSettle();
    expect(stack(), ['/a', '/c']);
    expect(result, 'done');
  });
}
