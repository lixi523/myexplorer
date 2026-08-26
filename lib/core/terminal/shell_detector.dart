import 'dart:io';

/// A shell available on the system that the built-in terminal can launch.
class ShellOption {
  /// Stored setting value: an absolute path to the shell executable.
  final String path;

  /// Display name (e.g. `bash`, `PowerShell 7`).
  final String label;

  const ShellOption({required this.path, required this.label});
}

/// Discovers shells installed on the host so the user can pick one for the
/// built-in terminal. The detector only reports executables that actually
/// exist on disk; the caller adds a separate "system default" entry.
class ShellDetector {
  ShellDetector._();

  static List<ShellOption> detect() {
    return _detectWindows();
  }

  /// The concrete shell used when the preference is "system default":
  /// PowerShell on Windows (falling back to whatever is available).
  static String defaultShellPath() {
    final shells = _detectWindows();
    for (final s in shells) {
      if (s.label.contains('PowerShell')) return s.path;
    }

    return shells.isEmpty ? '' : shells.first.path;
  }

  static List<ShellOption> _detectWindows() {
    final env = Platform.environment;
    final seen = <String>{};
    final out = <ShellOption>[];
    void add(String? path, String label) {
      if (path == null) return;
      final p = path.trim();
      final key = p.toLowerCase();
      if (p.isEmpty || seen.contains(key) || !File(p).existsSync()) return;
      seen.add(key);
      out.add(ShellOption(path: p, label: label));
    }

    final sysRoot = env['SystemRoot'] ?? r'C:\Windows';
    final programFiles = env['ProgramFiles'] ?? r'C:\Program Files';

    add('$programFiles\\PowerShell\\7\\pwsh.exe', 'PowerShell 7');
    add(
      '$programFiles\\WindowsApps\\Microsoft.PowerShell_7.6.5.0_x64__8wekyb3d8bbwe\\pwsh.exe',
      'PowerShell 7',
    );
    add(
      '$sysRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
      'Windows PowerShell',
    );
    add(env['ComSpec'] ?? '$sysRoot\\System32\\cmd.exe', 'Command Prompt');
    add('$programFiles\\Git\\bin\\bash.exe', 'Git Bash');

    return out;
  }
}
