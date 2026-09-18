import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `toNamed` to a page already on the stack, with a
/// `PreventDuplicateHandlingMode` that replaces the stacked entry
/// (`reorderRoutes`, `recreate`): the future of the *first* call must
/// complete when its entry leaves the stack.
///
/// `_push` dropped the stacked entry with a bare `_activePages.remove`,
/// unlike `_unsafeHistoryRemoveAt` and `_popWithResult`, which always
/// complete the completer of the page they remove. The first
/// `await Get.toNamed(...)` therefore hung forever, even after the user
/// navigated back.
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

  /// Records the outcome of a `toNamed` future without ever awaiting it:
  /// an orphaned completer would hang the test instead of failing it.
  ({List<String?> values, bool Function() completed}) watch(
    Future<String?>? future,
  ) {
    final values = <String?>[];
    var done = false;
    future?.then((v) {
      done = true;
      values.add(v);
    });
    return (values: values, completed: () => done);
  }

  /// Bounded wait: enough fake time for any pending microtask or timer to
  /// run, so a future still pending here is pending forever.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
  }

  Future<void> firstCallCompletesOnReplacement(
    WidgetTester tester,
    PreventDuplicateHandlingMode mode,
  ) async {
    await tester.pumpWidget(app(mode));

    final first = watch(Get.toNamed<String>('/b'));
    await settle(tester);
    expect(stack(), ['/a', '/b']);
    expect(first.completed(), isFalse, reason: '/b is on the stack, pending');

    // Same URL again: the stacked entry is dropped and replaced.
    final second = watch(Get.toNamed<String>('/b'));
    await settle(tester);
    expect(stack(), ['/a', '/b'], reason: 'replaced, not stacked twice');

    expect(
      first.completed(),
      isTrue,
      reason: 'MUTATION: drop the stacked entry without completing it and '
          'the first `await Get.toNamed` hangs forever.',
    );
    expect(first.values, [null],
        reason: 'the first call yielded no user result: completes with null');
    expect(second.completed(), isFalse,
        reason: 'the new entry is on the stack: still pending');

    // The replacing entry still behaves normally on back.
    Get.back<String>(result: 'x');
    await settle(tester);
    expect(stack(), ['/a']);
    expect(second.completed(), isTrue);
    expect(second.values, ['x']);
    expect(first.values, [null], reason: 'completed once, never again');
  }

  testWidgets('reorderRoutes: the replaced page completes its first future',
      (tester) async {
    await firstCallCompletesOnReplacement(
        tester, PreventDuplicateHandlingMode.reorderRoutes);
  });

  testWidgets('recreate: the replaced page completes its first future',
      (tester) async {
    await firstCallCompletesOnReplacement(
        tester, PreventDuplicateHandlingMode.recreate);
  });

  testWidgets('control: a different URL stacks and completes nothing',
      (tester) async {
    await tester.pumpWidget(app(PreventDuplicateHandlingMode.reorderRoutes));

    final toB = watch(Get.toNamed<String>('/b'));
    await settle(tester);
    final toC = watch(Get.toNamed<String>('/c'));
    await settle(tester);

    expect(stack(), ['/a', '/b', '/c'], reason: 'no duplicate: stack grows');
    expect(toB.completed(), isFalse, reason: 'nothing was removed');
    expect(toC.completed(), isFalse);

    Get.back<String>(result: 'c-done');
    await settle(tester);
    expect(stack(), ['/a', '/b']);
    expect(toC.values, ['c-done']);
    expect(toB.completed(), isFalse, reason: '/b is still stacked');

    Get.back<String>(result: 'b-done');
    await settle(tester);
    expect(stack(), ['/a']);
    expect(toB.values, ['b-done']);
  });
}
