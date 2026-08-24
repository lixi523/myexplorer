@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/features/navigation/shortcut_icon_loader.dart';
import 'package:myexplorer/features/navigation/toolbar_ini.dart';

void main() {
  test('every configured toolbar icon resolves', () async {
    final ini = File('build/windows/x64/runner/Release/快捷栏.ini');
    if (!ini.existsSync()) return;
    final items = parseToolbarIni(await ini.readAsString());
    var failures = 0;
    final failuresMsg = <String>[];
    for (final item in items) {
      if (item.label.isEmpty && item.target.isEmpty) continue;
      final explicit = item.icon;
      final spec =
          (explicit == null || explicit.isEmpty) &&
              item.target.trim().isNotEmpty
          ? item.target.trim()
          : explicit;
      if (spec == null || spec.isEmpty) continue;
      // WindowsApps is ACL-guarded; icon extraction there is expected to fail
      // and is not a code defect.
      if (spec.contains('WindowsApps')) continue;
      final provider = await resolveShortcutIcon(spec);
      if (provider == null) {
        failures++;
        failuresMsg.add('"${item.label}" spec="$spec"');
      }
    }
    expect(failures, 0, reason: failuresMsg.join('\n'));
  });
}
