import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// A controller given to `GetBuilder`/`GetX` with `global: false` is owned by
/// the widget: it is never registered, so `Get.delete` never reaches it.
/// Nothing else closed it either -- `onClose` never ran when the widget left
/// the tree.
class LocalController extends GetxController {
  int closed = 0;

  @override
  void onClose() {
    closed++;
    super.onClose();
  }
}

void main() {
  Future<void> removeWidget(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('GetBuilder(global: false) closes its controller on dispose',
      (tester) async {
    final controller = LocalController();
    await tester.pumpWidget(MaterialApp(
      home: GetBuilder<LocalController>(
        init: controller,
        global: false,
        builder: (_) => const Text('local'),
      ),
    ));
    expect(controller.initialized, isTrue);

    await removeWidget(tester);

    expect(
      controller.isClosed,
      isTrue,
      reason: 'MUTATION: drop the onDelete call for local controllers in '
          'BindElement.dispose and onClose never runs.',
    );
    expect(controller.closed, 1);
  });

  testWidgets('GetBuilder(global: false, autoRemove: false) leaves it open',
      (tester) async {
    final controller = LocalController();
    await tester.pumpWidget(MaterialApp(
      home: GetBuilder<LocalController>(
        init: controller,
        global: false,
        autoRemove: false,
        builder: (_) => const Text('local'),
      ),
    ));

    await removeWidget(tester);

    expect(controller.isClosed, isFalse);
  });
}
