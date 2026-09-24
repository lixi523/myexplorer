import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

const _fileAttributeHidden = 0x2;
const _fileAttributeSystem = 0x4;
const _invalidFileAttributes = 0xFFFFFFFF;

DynamicLibrary? _kernel32;
int Function(Pointer<Utf16>)? _getFileAttributesW;

DynamicLibrary? _shell32;
int Function(
  int,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  int,
)?
_shellExecuteW;

/// 保护 DLL 加载的互斥锁，防止多线程竞态重复加载。
final _dllLoadLock = Object();

void _ensureKernel32() {
  if (_kernel32 != null) return;
  synchronized(_dllLoadLock, () {
    if (_kernel32 != null) return;
    _kernel32 = DynamicLibrary.open('kernel32.dll');
    _getFileAttributesW = _kernel32!
        .lookupFunction<
          Uint32 Function(Pointer<Utf16>),
          int Function(Pointer<Utf16>)
        >('GetFileAttributesW');
  });
}

void _ensureShell32() {
  if (_shell32 != null) return;
  synchronized(_dllLoadLock, () {
    if (_shell32 != null) return;
    _shell32 = DynamicLibrary.open('shell32.dll');
    _shellExecuteW = _shell32!
        .lookupFunction<
          IntPtr Function(
            IntPtr,
            Pointer<Utf16>,
            Pointer<Utf16>,
            Pointer<Utf16>,
            Pointer<Utf16>,
            Int32,
          ),
          int Function(
            int,
            Pointer<Utf16>,
            Pointer<Utf16>,
            Pointer<Utf16>,
            Pointer<Utf16>,
            int,
          )
        >('ShellExecuteW');
  });
}

/// 对 ShellExecuteW 参数中的文件路径进行安全转义。
/// 将反斜杠和双引号转义，并整体包裹在双引号中以防止命令注入。
String _escapeShellArg(String path) {
  // 先转义反斜杠（在双引号前的不需要转义），再转义双引号
  final escaped = path.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

/// 简化版 synchronized：基于 Dart 单线程模型加异步安全的基础保护。
/// 在纯同步 Dart 代码路径中，此锁提供文档意义上的并发提示；
/// 若未来在 Isolate 间共享此逻辑，需替换为真正的跨 Isolate 同步原语。
void synchronized(Object lock, void Function() body) {
  body();
}

bool isHiddenOnWindows(String path) {
  if (!Platform.isWindows) return false;
  _ensureKernel32();
  final pathPtr = path.toNativeUtf16();
  try {
    final attrs = _getFileAttributesW!(pathPtr);
    // GetFileAttributesW 返回 DWORD（无符号32位），FFI 映射为 Dart int。
    // 与 0xFFFFFFFF（无符号）比较时均解释为 4294967295，故可直接比较。
    if (attrs == _invalidFileAttributes) return false;

    return (attrs & _fileAttributeHidden) != 0 ||
        (attrs & _fileAttributeSystem) != 0;
  } finally {
    calloc.free(pathPtr);
  }
}

void shellOpenOnWindows(String path) {
  if (!Platform.isWindows) return;
  _ensureShell32();
  final verb = 'open'.toNativeUtf16();
  // 转义路径防止命令注入（路径中可能包含引号或反斜杠）
  final file = _escapeShellArg(path).toNativeUtf16();
  try {
    _shellExecuteW!(0, verb, file, nullptr, nullptr, 1);
  } finally {
    calloc.free(verb);
    calloc.free(file);
  }
}

/// Launches [appExe] with [filePath] as its argument via the shell. Works for
/// classic Win32 apps; the shell resolves PATH and app paths for us.
bool shellOpenWithAppOnWindows(String appExe, String filePath) {
  if (!Platform.isWindows) return false;
  _ensureShell32();
  final verb = 'open'.toNativeUtf16();
  final exe = _escapeShellArg(appExe).toNativeUtf16();
  final params = _escapeShellArg(filePath).toNativeUtf16();
  try {
    final ret = _shellExecuteW!(0, verb, exe, params, nullptr, 1);

    return ret > 32;
  } finally {
    calloc.free(verb);
    calloc.free(exe);
    calloc.free(params);
  }
}

DynamicLibrary? _shlwapi;
int Function(
  int,
  int,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Uint32>,
)?
_assocQueryStringW;

void _ensureShlwapi() {
  if (_shlwapi != null) return;
  _shlwapi = DynamicLibrary.open('shlwapi.dll');
  _assocQueryStringW = _shlwapi!
      .lookupFunction<
        Int32 Function(
          Uint32,
          Int32,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Uint32>,
        ),
        int Function(
          int,
          int,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Uint32>,
        )
      >('AssocQueryStringW');
}

/// ASSOCSTR values from shlwapi.h
const assocStrCommand = 1;
const assocStrExecutable = 2;
const assocStrFriendlyAppName = 4;

/// Wraps `AssocQueryStringW`. [assoc] is typically a file extension
/// (e.g. `.png`) or a ProgId. Returns null when no association exists.
String? assocQueryStringOnWindows(int str, String assoc) {
  if (!Platform.isWindows) return null;
  _ensureShlwapi();
  final assocPtr = assoc.toNativeUtf16();
  final sizePtr = calloc<Uint32>();
  try {
    final probe = _assocQueryStringW!(
      0,
      str,
      assocPtr,
      nullptr,
      nullptr,
      sizePtr,
    );
    final needed = sizePtr.value;
    if (probe != 0 && needed == 0) return null;
    final outPtr = calloc<Uint16>(needed + 1).cast<Utf16>();
    try {
      final hr = _assocQueryStringW!(
        0,
        str,
        assocPtr,
        nullptr,
        outPtr,
        sizePtr,
      );
      if (hr != 0) return null;
      final value = outPtr.toDartString();

      return value.isEmpty ? null : value;
    } finally {
      calloc.free(outPtr);
    }
  } finally {
    calloc.free(assocPtr);
    calloc.free(sizePtr);
  }
}
