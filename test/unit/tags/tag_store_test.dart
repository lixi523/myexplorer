import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/features/tags/tag_store.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('tag_store_test_');
    TagStore.instance.directoryOverride = tmp.path;
    TagStore.instance.tags.value = [];
    TagStore.instance.fileTagsByName.value = {};
  });

  tearDown(() {
    TagStore.instance.directoryOverride = null;
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('creates 标签.ini in the root directory', () async {
    final store = TagStore.instance;
    await store.createTag('红', const Color(0xFFE5484D));
    await store.addFileTag(r'C:\a.txt', 1);

    final file = File(store.filePath);
    expect(file.existsSync(), isTrue);
    expect(file.path.endsWith('标签.ini'), isTrue);
    final content = await file.readAsString();
    expect(content, contains('[标签]'));
    expect(content, contains('红=0xFFE5484D'));
    expect(content, contains('[文件]'));
    expect(content, contains(r'C:\a.txt=红'));
  });

  test('loads tags and file assignments back from the INI', () async {
    final store = TagStore.instance;
    await store.createTag('红', const Color(0xFFE5484D));
    await store.createTag('绿', const Color(0xFF46A758));
    await store.addFileTag(r'C:\a.txt', 1);
    await store.addFileTag(r'C:\a.txt', 2);

    store.tags.value = [];
    store.fileTagsByName.value = {};
    await store.load();

    expect(store.tags.value.length, 2);
    expect(store.tags.value.map((t) => t.name), ['红', '绿']);
    expect(store.tags.value.first.color.toARGB32(), 0xFFE5484D);
    expect(store.fileTagsByName.value[r'C:\a.txt'], {'红', '绿'});
  });

  test('fileTagsById resolves names to ids', () async {
    final store = TagStore.instance;
    await store.createTag('红', const Color(0xFFE5484D));
    await store.addFileTag(r'C:\a.txt', 1);

    expect(store.fileTagsById[r'C:\a.txt'], {1});
  });

  test('deleteTag removes the definition and assignments', () async {
    final store = TagStore.instance;
    await store.createTag('红', const Color(0xFFE5484D));
    await store.createTag('绿', const Color(0xFF46A758));
    await store.addFileTag(r'C:\a.txt', 1);
    await store.addFileTag(r'C:\a.txt', 2);

    await store.deleteTag(1);

    expect(store.tags.value.map((t) => t.name), ['绿']);
    expect(store.fileTagsByName.value[r'C:\a.txt'], {'绿'});
  });
}
