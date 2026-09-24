class WslPath {
  final String distro;
  final String root;
  final List<String> rest;

  const WslPath({required this.distro, required this.root, required this.rest});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WslPath &&
          runtimeType == other.runtimeType &&
          distro == other.distro &&
          root == other.root &&
          _listEquals(rest, other.rest);

  @override
  int get hashCode => Object.hash(distro, root, Object.hashAll(rest));

  @override
  String toString() => 'WslPath(distro: $distro, root: $root, rest: $rest)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

WslPath? parseWslPath(String path) {
  final s = path.replaceAll('/', r'\');
  if (!s.startsWith(r'\\')) return null;
  final body = s.substring(2);
  final slash = body.indexOf(r'\');
  if (slash < 0) return null;
  final host = body.substring(0, slash);
  final lower = host.toLowerCase();
  if (lower != 'wsl.localhost' && lower != r'wsl$') return null;
  final parts = body
      .substring(slash + 1)
      .split(r'\')
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;

  return WslPath(
    distro: parts.first,
    root: '\\\\$host\\${parts.first}',
    // List.unmodifiable 创建防御性拷贝，防止外部篡改内部状态
    rest: List.unmodifiable(parts.skip(1)),
  );
}
