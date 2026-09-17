import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `RxList()`, `RxMap()` and `RxSet()` built without an argument defaulted
/// to a `const` collection: the first mutation threw `UnsupportedError`.
///
/// MUTATION: restore `[super.initial = const []]` (or `const {}`) in the
/// constructors and every test below throws.
void main() {
  test('RxList() is modifiable', () {
    final list = RxList<int>();
    list.add(1);
    list.addAll([2, 3]);
    expect(list, [1, 2, 3]);
    list.clear();
    list.assignAll([4]);
    expect(list, [4]);
  });

  test('RxMap() is modifiable', () {
    final map = RxMap<String, int>();
    map['a'] = 1;
    map.addAll({'b': 2});
    expect(map, {'a': 1, 'b': 2});
    map.clear();
    map.assignAll({'c': 3});
    expect(map, {'c': 3});
  });

  test('RxSet() is modifiable', () {
    final set = RxSet<int>();
    set.add(1);
    set.addAll({2});
    expect(set, {1, 2});
    set.clear();
    set.assignAll({3});
    expect(set, {3});
  });

  test('two default instances do not share their collection', () {
    final a = RxList<int>();
    final b = RxList<int>();
    a.add(1);
    expect(b, isEmpty);

    final m1 = RxMap<String, int>();
    final m2 = RxMap<String, int>();
    m1['a'] = 1;
    expect(m2, isEmpty);

    final s1 = RxSet<int>();
    final s2 = RxSet<int>();
    s1.add(1);
    expect(s2, isEmpty);
  });

  test('a default instance notifies its listeners', () {
    final list = RxList<int>();
    var calls = 0;
    list.listen((_) => calls++);
    list.add(1);
    return Future<void>.delayed(Duration.zero, () => expect(calls, 1));
  });
}
