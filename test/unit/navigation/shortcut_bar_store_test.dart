import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:myexplorer/features/navigation/shortcut_bar_store.dart';

void main() {
  final file = File(p.join(p.dirname(Platform.resolvedExecutable), '快捷栏.ini'));

  setUp(() async {
    if (file.existsSync()) file.deleteSync();
    final tmp = File('${file.path}.tmp');
    if (tmp.existsSync()) tmp.deleteSync();
    ShortcutBarStore.instance.items.value = const [];
    await ShortcutBarStore.instance.load();
  });

  tearDown(() {
    if (file.existsSync()) file.deleteSync();
    final tmp = File('${file.path}.tmp');
    if (tmp.existsSync()) tmp.deleteSync();
  });

  group('ShortcutBarStore', () {
    test('starts empty when the INI file is missing', () {
      expect(ShortcutBarStore.instance.items.value, isEmpty);
    });

    test('filePath targets the executable directory', () {
      expect(p.basename(ShortcutBarStore.instance.filePath), '快捷栏.ini');
      expect(
        p.dirname(ShortcutBarStore.instance.filePath),
        p.dirname(Platform.resolvedExecutable),
      );
    });

    test('load reads a hand-written INI file', () async {
      file.writeAsStringSync(
        '[Toolbar]\n'
        'Home | C:\\Users\\me | C:\\Users\\me\\icon.ico\n'
        'Docs | D:\\Docs\n'
        '|\n',
      );
      await ShortcutBarStore.instance.load();
      final items = ShortcutBarStore.instance.items.value;
      expect(items, hasLength(3));
      expect(items[0].label, 'Home');
      expect(items[0].target, r'C:\Users\me');
      expect(items[0].icon, r'C:\Users\me\icon.ico');
      expect(items[1].target, r'D:\Docs');
      expect(items[2].label, isEmpty);
    });

    test('load reads a file with a UTF-8 BOM', () async {
      file.writeAsBytesSync([
        0xEF,
        0xBB,
        0xBF,
        ...'[Toolbar]\nA | C:\\A\n'.codeUnits,
      ]);
      await ShortcutBarStore.instance.load();
      expect(ShortcutBarStore.instance.items.value, hasLength(1));
      expect(ShortcutBarStore.instance.items.value.single.label, 'A');
    });

    test('add assigns incrementing ids and updates the list', () async {
      final store = ShortcutBarStore.instance;
      await store.add('One', r'C:\One');
      await store.add('Two', r'C:\Two', icon: r'C:\Two\i.ico');
      final items = store.items.value;
      expect(items, hasLength(2));
      expect(items[0].id, 0);
      expect(items[0].label, 'One');
      expect(items[0].icon, isNull);
      expect(items[1].id, 1);
      expect(items[1].label, 'Two');
      expect(items[1].icon, r'C:\Two\i.ico');
    });

    test('add persists to disk and reloads', () async {
      final store = ShortcutBarStore.instance;
      await store.add('Home', r'C:\Users\me');
      expect(file.existsSync(), isTrue);
      store.items.value = const [];
      await store.load();
      final items = store.items.value;
      expect(items, hasLength(1));
      expect(items.single.label, 'Home');
      expect(items.single.target, r'C:\Users\me');
    });

    test('addAll appends multiple items in order', () async {
      final store = ShortcutBarStore.instance;
      await store.addAll([
        (label: 'A', target: r'C:\A', icon: null),
        (label: '', target: '', icon: null),
        (label: 'B', target: r'C:\B', icon: r'C:\B\i.ico'),
      ]);
      final items = store.items.value;
      expect(items, hasLength(3));
      expect(items[0].label, 'A');
      expect(items[1].label, isEmpty);
      expect(items[2].label, 'B');
      expect(items[2].icon, r'C:\B\i.ico');
    });

    test('remove deletes the matching item', () async {
      final store = ShortcutBarStore.instance;
      await store.add('One', r'C:\One');
      await store.add('Two', r'C:\Two');
      await store.remove(0);
      final items = store.items.value;
      expect(items, hasLength(1));
      expect(items.single.label, 'Two');
    });

    test('reorder reorders items and rewrites orderIndex', () async {
      final store = ShortcutBarStore.instance;
      await store.add('One', r'C:\One');
      await store.add('Two', r'C:\Two');
      await store.add('Three', r'C:\Three');
      final ids = store.items.value.map((e) => e.id).toList();
      await store.reorder([ids[2], ids[0], ids[1]]);
      final items = store.items.value;
      expect(items.map((e) => e.label).toList(), ['Three', 'One', 'Two']);
      expect(items.map((e) => e.orderIndex).toList(), [0, 1, 2]);
    });

    test('reorder persists the new order', () async {
      final store = ShortcutBarStore.instance;
      await store.add('One', r'C:\One');
      await store.add('Two', r'C:\Two');
      final ids = store.items.value.map((e) => e.id).toList();
      await store.reorder([ids[1], ids[0]]);
      store.items.value = const [];
      await store.load();
      expect(store.items.value.map((e) => e.label).toList(), ['Two', 'One']);
    });
  });
}
