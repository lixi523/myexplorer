import 'package:mime/mime.dart' as mime_pkg;

/// A resolved content type for a file (e.g. `image/png`).
class MimeType {
  final String value;

  const MimeType(this.value);

  static const unknown = MimeType('application/octet-stream');

  bool get isUnknown => value == unknown.value || value.isEmpty;

  @override
  String toString() => value;
}

/// Resolves a file path to its content type using the most authoritative
/// source available on the platform, falling back to extension-based lookup.
abstract class MimeResolver {
  Future<MimeType> resolve(String path);

  factory MimeResolver.platform() => _FallbackMimeResolver();
}

MimeType _fromExtension(String path) {
  final m = mime_pkg.lookupMimeType(path);

  return m == null ? MimeType.unknown : MimeType(m);
}

class _FallbackMimeResolver implements MimeResolver {
  @override
  Future<MimeType> resolve(String path) async => _fromExtension(path);
}
