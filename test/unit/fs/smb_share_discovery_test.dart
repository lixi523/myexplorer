import 'package:flutter_test/flutter_test.dart';
import 'package:myexplorer/core/fs/smb_share_discovery.dart';

void main() {
  group('SmbShareDiscovery.parseNetView', () {
    test('parses Windows net view output', () {
      const text = '''
Shared resources at \\\\nas1

Share name   Type   Used as   Comment
-------------------------------------
public       Disk             Public files
media        Disk
IPC\$         IPC              Remote IPC
The command completed successfully.
''';
      final shares = SmbShareDiscovery.parseNetView(text);
      expect(shares.map((s) => s.name), ['public', 'media']);
      expect(shares[0].comment, 'Public files');
    });

    test('parses localized net view output (no English "Disk")', () {
      const text = '''
Zasoby udostępnione w \\\\nas1

Nazwa udziału   Typ    Używane jako   Komentarz
-------------------------------------------------
public          Dysk                  Pliki publiczne
media           Dysk
IPC\$            IPC                   Zdalne IPC
Polecenie zostało wykonane pomyślnie.
''';
      final shares = SmbShareDiscovery.parseNetView(text);
      expect(shares.map((s) => s.name), ['public', 'media']);
      expect(shares[0].comment, 'Pliki publiczne');
    });
  });
}
