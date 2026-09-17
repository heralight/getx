import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `GetX(global: false)` starts the controller it is given but never
/// registers it, so `Get.delete` never reaches it and `onClose` never ran
/// when the widget left the tree.
class LocalController extends GetxController {
  final count = 0.obs;
  int closed = 0;

  @override
  void onClose() {
    closed++;
    super.onClose();
  }
}

void main() {
  Widget app(LocalController controller, {bool autoRemove = true}) =>
      MaterialApp(
        home: GetX<LocalController>(
          init: controller,
          global: false,
          autoRemove: autoRemove,
          builder: (c) => Text('${c.count.value}'),
        ),
      );

  testWidgets('GetX(global: false) closes its controller on dispose',
      (tester) async {
    final controller = LocalController();
    await tester.pumpWidget(app(controller));
    expect(controller.initialized, isTrue);

    await tester.pumpWidget(const SizedBox());

    expect(
      controller.isClosed,
      isTrue,
      reason: 'MUTATION: drop the onDelete call for local controllers in '
          'GetXState.dispose and onClose never runs.',
    );
    expect(controller.closed, 1);
  });

  testWidgets('GetX(global: false, autoRemove: false) leaves it open',
      (tester) async {
    final controller = LocalController();
    await tester.pumpWidget(app(controller, autoRemove: false));

    await tester.pumpWidget(const SizedBox());

    expect(controller.isClosed, isFalse);
  });
}
