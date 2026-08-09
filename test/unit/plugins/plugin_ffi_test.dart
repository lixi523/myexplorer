import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/features/plugins/plugin_ffi.dart';

void main() {
  tearDown(PluginFfi.shutdown);

  group('PluginFfi', () {
    test('shutdown is safe before any worker exists', () {
      expect(() => PluginFfi.shutdown(), returnsNormally);
    });

    test('load never throws and returns a string or null', () async {
      final result = await PluginFfi.load('nonexistent/init.lua');
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('invoke never throws and returns a string or null', () async {
      final result = await PluginFfi.invoke(
        initLuaPath: 'nonexistent/init.lua',
        actionId: 'run',
        ctxJson: '{}',
      );
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('barUpdate never throws and returns a string or null', () async {
      final result = await PluginFfi.barUpdate(
        initLuaPath: 'nonexistent/init.lua',
        barId: 'b',
        ctxJson: '{}',
      );
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('barClick never throws and returns a string or null', () async {
      final result = await PluginFfi.barClick(
        initLuaPath: 'nonexistent/init.lua',
        barId: 'b',
        itemId: 'i',
        ctxJson: '{}',
      );
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('columnCompute never throws and returns a string or null', () async {
      final result = await PluginFfi.columnCompute(
        initLuaPath: 'nonexistent/init.lua',
        columnId: 'c',
        ctxJson: '{}',
      );
      expect(result, anyOf(isNull, isA<String>()));
    });

    test('worker survives repeated calls and shutdown', () async {
      await PluginFfi.load('a.lua');
      await PluginFfi.load('b.lua');
      PluginFfi.shutdown();
      final result = await PluginFfi.load('c.lua');
      expect(result, anyOf(isNull, isA<String>()));
      PluginFfi.shutdown();
      PluginFfi.shutdown();
    });
  });
}
