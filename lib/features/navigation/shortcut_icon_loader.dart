import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;

import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';

/// Resolves Total Commander-style icon specs for shortcut bar buttons.
///
/// Supported specs:
/// - a raster image path (`.png`/`.jpg`/`.gif`/`.bmp`/`.webp`) → `FileImage`;
/// - an `.svg` path → handled by the caller via [svgIconPath];
/// - an executable/library/icon path, optionally with a `,index` suffix
///   (`shell32.dll,34`) → the embedded icon is extracted and cached as PNG.
///
/// Extraction uses `ExtractIconExW` + `GetDIBits` through raw FFI (same style
/// as `win32_attributes.dart`); extracted PNGs are cached under %TEMP%.

final _sha256 = sha256;

const Set<String> _rasterExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.bmp',
  '.webp',
};

const Set<String> _svgExtensions = {'.svg'};

final RegExp _indexSuffix = RegExp(r',\s*(-?\d+)\s*$');

String? _cacheDir;

String _iconCacheDir() {
  if (_cacheDir != null) return _cacheDir!;
  _cacheDir = p.join(p.dirname(Platform.resolvedExecutable), 'icon_cache');

  return _cacheDir!;
}

const int _cacheMaxFiles = 200;
bool _cacheCleanupScheduled = false;

void _scheduleCacheCleanup() {
  if (_cacheCleanupScheduled) return;
  _cacheCleanupScheduled = true;
  Future.microtask(() {
    _cacheCleanupScheduled = false;
    _trimCacheDir();
  });
}

/// Keeps the icon PNG cache under [_cacheMaxFiles] entries by deleting
/// the oldest files. Also clears the in-memory extraction cache so stale
/// paths are never returned — the next request re-extracts if the file
/// is still on disk, or re-writes it.
void _trimCacheDir() {
  try {
    final dir = Directory(_iconCacheDir());
    if (!dir.existsSync()) return;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
    if (files.length <= _cacheMaxFiles) return;
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
    final toRemove = files.sublist(0, files.length - _cacheMaxFiles);
    for (final f in toRemove) {
      try {
        f.deleteSync();
      } catch (_) {}
    }
    _extractCache.clear();
  } catch (_) {}
}

/// Splits `path,index` into its file part and icon index. Quoted specs and
/// environment variables are normalized first.
(String, int) parseIconSpec(String? iconSpec) {
  if (iconSpec == null) return ('', 0);
  var spec = PlatformPaths.expandEnvVars(iconSpec.trim());
  if (spec.length >= 2 &&
      ((spec.startsWith('"') && spec.endsWith('"')) ||
          (spec.startsWith("'") && spec.endsWith("'")))) {
    spec = spec.substring(1, spec.length - 1).trim();
  }
  if (spec.isEmpty) return ('', 0);
  final match = _indexSuffix.firstMatch(spec);
  if (match != null) {
    var file = spec.substring(0, match.start).trim();
    final index = int.tryParse(match.group(1)!) ?? 0;
    if (file.length >= 2 &&
        ((file.startsWith('"') && file.endsWith('"')) ||
            (file.startsWith("'") && file.endsWith("'")))) {
      file = file.substring(1, file.length - 1).trim();
    }

    return (file, index);
  }

  return (spec, 0);
}

/// Resolves bare system icon libraries like `shell32.dll` to their full path
/// under System32 so `ExtractIconExW` can find them.
String resolveIconFile(String file) {
  if (file.isEmpty) return file;
  if (Platform.isWindows &&
      !file.contains(RegExp(r'[/\\]')) &&
      !file.contains(':')) {
    final system32 = Platform.environment['SystemRoot'] ?? r'C:\Windows';
    final candidate = p.join(system32, 'System32', file);
    if (File(candidate).existsSync()) return candidate;
  }

  return file;
}

/// Whether [iconSpec] points at an SVG (rendered by the caller as a widget).
bool isSvgIconSpec(String? iconSpec) {
  final (file, _) = parseIconSpec(iconSpec);
  if (file.isEmpty) return false;

  return _svgExtensions.contains(p.extension(file).toLowerCase());
}

/// File path when [iconSpec] is an SVG, otherwise null.
String? svgIconPath(String? iconSpec) {
  final (file, _) = parseIconSpec(iconSpec);
  if (file.isEmpty) return null;

  return isSvgIconSpec(iconSpec) ? file : null;
}

/// Resolves [iconSpec] to an [ImageProvider], or null when no icon could be
/// loaded (the caller then falls back to its default glyph).
Future<ImageProvider?> resolveShortcutIcon(String? iconSpec) async {
  try {
    final (file, index) = parseIconSpec(iconSpec);
    if (file.isEmpty) return null;
    var resolved = resolveIconFile(file);
    if (!File(resolved).existsSync()) {
      // TC-style "command with arguments" (e.g. `mstsc.exe /admin /v:`):
      // use the executable token so its embedded icon still resolves.
      final space = file.indexOf(' ');
      if (space > 0) {
        var head = file.substring(0, space).trim();
        if (head.length >= 2 && head.startsWith('"') && head.endsWith('"')) {
          head = head.substring(1, head.length - 1).trim();
        }
        final headResolved = resolveIconFile(head);
        if (File(headResolved).existsSync()) resolved = headResolved;
      }
    }
    if (!File(resolved).existsSync()) return null;

    final ext = p.extension(resolved).toLowerCase();
    if (_rasterExtensions.contains(ext)) {
      return FileImage(File(resolved));
    }
    if (_svgExtensions.contains(ext)) return null;

    final cached = await _extractIconPng(resolved, index);

    return cached == null ? null : FileImage(File(cached));
  } catch (_) {
    // Unreadable/guarded paths (e.g. WindowsApps) or extraction failures
    // degrade to the caller's default glyph.
    return null;
  }
}

/// ── Win32 icon extraction ────────────────────────────────────────────────

/// Minimal `SHFILEINFOW` layout: only [hIcon] is consumed; the remaining
/// fields keep the struct size correct for `SHGetFileInfoW`.
final class _SHFileInfo extends Struct {
  @IntPtr()
  external int hIcon;

  @Int32()
  external int iIcon;

  @Uint32()
  external int dwAttributes;

  @Array(260)
  external Array<Uint16> displayName;

  @Array(80)
  external Array<Uint16> typeName;
}

final class _IconInfo extends Struct {
  @Int32()
  external int fIcon;

  @Uint32()
  external int xHotspot;

  @Uint32()
  external int yHotspot;

  @IntPtr()
  external int hbmMask;

  @IntPtr()
  external int hbmColor;
}

final class _Bitmap extends Struct {
  @Int32()
  external int bmType;

  @Int32()
  external int bmWidth;

  @Int32()
  external int bmHeight;

  @Int32()
  external int bmWidthBytes;

  @Uint16()
  external int bmPlanes;

  @Uint16()
  external int bmBitsPixel;

  @IntPtr()
  external int bmBits;
}

final class _BitmapInfoHeader extends Struct {
  @Uint32()
  external int biSize;

  @Int32()
  external int biWidth;

  @Int32()
  external int biHeight;

  @Uint16()
  external int biPlanes;

  @Uint16()
  external int biBitCount;

  @Uint32()
  external int biCompression;

  @Uint32()
  external int biSizeImage;

  @Int32()
  external int biXPelsPerMeter;

  @Int32()
  external int biYPelsPerMeter;

  @Uint32()
  external int biClrUsed;

  @Uint32()
  external int biClrImportant;
}

DynamicLibrary? _user32;
DynamicLibrary? _gdi32;
DynamicLibrary? _shell32;
int Function(Pointer<Utf16>, int, Pointer<_SHFileInfo>, int, int)?
_shGetFileInfo;
int Function(Pointer<Utf16>, int, int, Pointer<IntPtr>, Pointer<IntPtr>, int)?
_shDefExtractIcon;
int Function(int, Pointer<_IconInfo>)? _getIconInfo;
int Function(int)? _destroyIcon;
int Function(int)? _deleteObject;
int Function(int)? _createCompatibleDC;
int Function(int, int)? _selectObject;
int Function(
  int,
  int,
  int,
  int,
  Pointer<Uint8>,
  Pointer<_BitmapInfoHeader>,
  int,
)?
_getDIBits;
int Function(int, int, Pointer<Void>)? _getObjectW;
int Function(int)? _deleteDC;

void _ensureIconApis() {
  if (_user32 != null) return;
  _user32 = DynamicLibrary.open('user32.dll');
  _gdi32 = DynamicLibrary.open('gdi32.dll');
  _shell32 = DynamicLibrary.open('shell32.dll');
  _shGetFileInfo = _shell32!
      .lookupFunction<
        UintPtr Function(
          Pointer<Utf16>,
          Uint32,
          Pointer<_SHFileInfo>,
          Uint32,
          Uint32,
        ),
        int Function(Pointer<Utf16>, int, Pointer<_SHFileInfo>, int, int)
      >('SHGetFileInfoW');
  _shDefExtractIcon = _shell32!
      .lookupFunction<
        Int32 Function(
          Pointer<Utf16>,
          Int32,
          Uint32,
          Pointer<IntPtr>,
          Pointer<IntPtr>,
          Uint32,
        ),
        int Function(
          Pointer<Utf16>,
          int,
          int,
          Pointer<IntPtr>,
          Pointer<IntPtr>,
          int,
        )
      >('SHDefExtractIconW');
  _getIconInfo = _user32!
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<_IconInfo>),
        int Function(int, Pointer<_IconInfo>)
      >('GetIconInfo');
  _destroyIcon = _user32!
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>('DestroyIcon');
  _deleteObject = _gdi32!
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'DeleteObject',
      );
  _createCompatibleDC = _gdi32!
      .lookupFunction<IntPtr Function(IntPtr), int Function(int)>(
        'CreateCompatibleDC',
      );
  _selectObject = _gdi32!
      .lookupFunction<IntPtr Function(IntPtr, IntPtr), int Function(int, int)>(
        'SelectObject',
      );
  _getDIBits = _gdi32!
      .lookupFunction<
        Int32 Function(
          IntPtr,
          IntPtr,
          Uint32,
          Uint32,
          Pointer<Uint8>,
          Pointer<_BitmapInfoHeader>,
          Uint32,
        ),
        int Function(
          int,
          int,
          int,
          int,
          Pointer<Uint8>,
          Pointer<_BitmapInfoHeader>,
          int,
        )
      >('GetDIBits');
  _getObjectW = _gdi32!
      .lookupFunction<
        Int32 Function(IntPtr, Int32, Pointer<Void>),
        int Function(int, int, Pointer<Void>)
      >('GetObjectW');
  _deleteDC = _gdi32!.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
    'DeleteDC',
  );
}

final Map<String, Future<String?>> _extractCache = {};

Future<String?> _extractIconPng(String file, int index) {
  final cacheKey = _extractCacheKey(file, index);
  final existing = _extractCache[cacheKey];
  if (existing != null) return existing;
  final future = _doExtractIconPng(file, index, cacheKey);
  _extractCache[cacheKey] = future;

  return future;
}

String _extractCacheKey(String file, int index) {
  var fingerprint = '$file|$index';
  try {
    final stat = File(file).statSync();
    fingerprint =
        '$file|$index|${stat.modified.millisecondsSinceEpoch}|${stat.size}';
  } catch (_) {}
  final bytes = utf8.encode(fingerprint);
  final digest = _sha256.convert(bytes);
  return digest.toString();
}

Future<String?> _doExtractIconPng(
  String file,
  int index,
  String cacheKey,
) async {
  if (!Platform.isWindows) return null;
  _ensureIconApis();
  final cached = File(p.join(_iconCacheDir(), '$cacheKey.png'));
  try {
    if (cached.existsSync()) return cached.path;
  } catch (_) {}

  final filePtr = file.toNativeUtf16();
  final shInfo = calloc<_SHFileInfo>();
  final large = calloc<IntPtr>();
  final small = calloc<IntPtr>();
  var hIcon = 0;
  var hbm = 0;
  try {
    if (index > 0) {
      // An explicit index: extract exactly that icon via SHDefExtractIconW.
      final hr = _shDefExtractIcon!(filePtr, index, 0, large, small, 0);
      if (hr != 0) return null;
      hIcon = large.value != 0 ? large.value : small.value;
    } else {
      // SHGFI_ICON | SHGFI_LARGEICON: read the file's embedded icon without
      // visiting the defaults (SHGFI_USEFILEATTRIBUTES would skip exe icons).
      final result = _shGetFileInfo!(
        filePtr,
        0,
        shInfo,
        sizeOf<_SHFileInfo>(),
        0x100,
      );
      if (result == 0) return null;
      hIcon = shInfo.ref.hIcon;
    }
    if (hIcon == 0) return null;

    final info = calloc<_IconInfo>();
    try {
      if (_getIconInfo!(hIcon, info) == 0) return null;
      hbm = info.ref.hbmColor;
      if (hbm == 0) return null;

      final bm = calloc<_Bitmap>();
      try {
        if (_getObjectW!(hbm, sizeOf<_Bitmap>(), bm.cast()) == 0) return null;
        final w = bm.ref.bmWidth;
        final h = bm.ref.bmHeight;
        if (w <= 0 || h <= 0 || w > 512 || h > 512) return null;

        final dc = _createCompatibleDC!(0);
        if (dc == 0) return null;
        try {
          _selectObject!(dc, hbm);
          final bmi = calloc<_BitmapInfoHeader>();
          final pixels = calloc<Uint8>(w * h * 4);
          try {
            bmi.ref.biSize = sizeOf<_BitmapInfoHeader>();
            bmi.ref.biWidth = w;
            bmi.ref.biHeight = -h; // top-down
            bmi.ref.biPlanes = 1;
            bmi.ref.biBitCount = 32;
            bmi.ref.biCompression = 0; // BI_RGB
            final got = _getDIBits!(dc, hbm, 0, h, pixels, bmi.cast(), 0);
            if (got == 0) return null;

            final count = w * h;
            final rgba = Uint8List(count * 4);
            for (var i = 0; i < count; i++) {
              rgba[i * 4] = pixels[i * 4 + 2];
              rgba[i * 4 + 1] = pixels[i * 4 + 1];
              rgba[i * 4 + 2] = pixels[i * 4];
              rgba[i * 4 + 3] = pixels[i * 4 + 3];
            }
            final png = await _encodePng(rgba, w, h);
            if (png == null) return null;

            final dir = Directory(_iconCacheDir());
            await dir.create(recursive: true);
            await cached.writeAsBytes(png, flush: true);
            _scheduleCacheCleanup();

            return cached.path;
          } finally {
            calloc.free(bmi);
            calloc.free(pixels);
          }
        } finally {
          _deleteDC!(dc);
        }
      } finally {
        calloc.free(bm);
      }
    } finally {
      calloc.free(info);
    }
  } catch (e, st) {
    log.warn('shortcut', 'icon extraction failed', error: e, stack: st);

    return null;
  } finally {
    calloc.free(filePtr);
    calloc.free(shInfo);
    calloc.free(large);
    calloc.free(small);
    if (hbm != 0) _deleteObject!(hbm);
    if (hIcon != 0) _destroyIcon!(hIcon);
  }
}

Future<Uint8List?> _encodePng(Uint8List rgba, int width, int height) {
  final completer = Completer<Uint8List?>();
  try {
    ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, (
      image,
    ) async {
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        completer.complete(data?.buffer.asUint8List());
      } catch (_) {
        completer.complete(null);
      } finally {
        image.dispose();
      }
    });
  } catch (e) {
    log.warn('shortcut', 'png encode failed', error: e);
    completer.complete(null);
  }

  return completer.future;
}
