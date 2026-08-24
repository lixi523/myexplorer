import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/features/navigation/bookmark_store.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('bookmark_store_test_');
    BookmarkStore.instance.directoryOverride = tmp.path;
    BookmarkStore.instance.bookmarks.value = [];
  });

  tearDown(() {
    BookmarkStore.instance.directoryOverride = null;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('persists bookmarks to 书签.ini in the root directory', () async {
    final store = BookmarkStore.instance;
    await store.addLocation(r'C:\work', label: '工作');
    await store.addLocation(r'D:\backup', label: '备份');

    final file = File(store.filePath);
    expect(file.existsSync(), isTrue);
    expect(file.path.endsWith('书签.ini'), isTrue);
    final content = await file.readAsString();
    expect(content, contains('[书签]'));
    expect(content, contains('${r'C:\work'}=工作'));
    expect(content, contains('${r'D:\backup'}=备份'));
  });

  test('loads bookmarks back from the INI preserving order', () async {
    final store = BookmarkStore.instance;
    await store.addLocation(r'C:\work', label: '工作');
    await store.addLocation(r'D:\backup', label: '备份');

    store.bookmarks.value = [];
    await store.load();

    expect(store.bookmarks.value.length, 2);
    expect(store.bookmarks.value.map((b) => b.label), ['工作', '备份']);
    expect(store.bookmarks.value.map((b) => b.path), [
      r'C:\work',
      r'D:\backup',
    ]);
  });

  test('remove drops the line from the INI', () async {
    final store = BookmarkStore.instance;
    await store.addLocation(r'C:\work', label: '工作');
    await store.addLocation(r'D:\backup', label: '备份');

    await store.remove(store.bookmarks.value.first);

    expect(store.bookmarks.value.length, 1);
    final content = await File(store.filePath).readAsString();
    expect(content, isNot(contains(r'C:\work')));
    expect(content, contains(r'D:\backup'));
  });
}
