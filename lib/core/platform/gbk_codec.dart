import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Minimal GBK (codepage 936) codec backed by the Windows ANSI conversion
/// APIs. Total Commander button bars are written in the system ANSI codepage,
/// which on a Chinese Windows is GBK, so `dart:convert` (UTF-8 only) cannot
/// read them. The FFI calls below mirror `win32_attributes.dart`'s style.

const int _codePageGbk = 936;

DynamicLibrary? _kernel32;
int Function(int, int, Pointer<Uint8>, int, Pointer<Utf16>, int)?
_multiByteToWideChar;
int Function(
  int,
  int,
  Pointer<Utf16>,
  int,
  Pointer<Uint8>,
  int,
  Pointer<Uint8>,
  Pointer<Int32>,
)?
_wideCharToMultiByte;

void _ensureKernel32() {
  if (_kernel32 != null) return;
  _kernel32 = DynamicLibrary.open('kernel32.dll');
  _multiByteToWideChar = _kernel32!
      .lookupFunction<
        Int32 Function(
          Uint32,
          Uint32,
          Pointer<Uint8>,
          Int32,
          Pointer<Utf16>,
          Int32,
        ),
        int Function(int, int, Pointer<Uint8>, int, Pointer<Utf16>, int)
      >('MultiByteToWideChar');
  _wideCharToMultiByte = _kernel32!
      .lookupFunction<
        Int32 Function(
          Uint32,
          Uint32,
          Pointer<Utf16>,
          Int32,
          Pointer<Uint8>,
          Int32,
          Pointer<Uint8>,
          Pointer<Int32>,
        ),
        int Function(
          int,
          int,
          Pointer<Utf16>,
          int,
          Pointer<Uint8>,
          int,
          Pointer<Uint8>,
          Pointer<Int32>,
        )
      >('WideCharToMultiByte');
}

/// Decodes [bytes] as GBK. Returns null when the conversion fails (empty
/// result or no code page support).
String? decodeGbkBytes(List<int> bytes) {
  if (bytes.isEmpty) return '';
  if (!Platform.isWindows) return null;
  _ensureKernel32();
  final input = calloc<Uint8>(bytes.length);
  try {
    input.asTypedList(bytes.length).setAll(0, bytes);
    final size = _multiByteToWideChar!(
      _codePageGbk,
      0,
      input,
      bytes.length,
      nullptr,
      0,
    );
    if (size <= 0) return null;
    final output = calloc<Uint16>(size).cast<Utf16>();
    try {
      final written = _multiByteToWideChar!(
        _codePageGbk,
        0,
        input,
        bytes.length,
        output,
        size,
      );
      if (written <= 0) return null;

      return output.toDartString(length: written);
    } finally {
      calloc.free(output);
    }
  } finally {
    calloc.free(input);
  }
}

/// Encodes [text] as GBK bytes. Returns null when the conversion fails.
/// Primarily used by tests to produce Total Commander bar fixtures.
Uint8List? encodeGbkBytes(String text) {
  if (!Platform.isWindows) return null;
  _ensureKernel32();
  final input = text.toNativeUtf16();
  try {
    final size = _wideCharToMultiByte!(
      _codePageGbk,
      0,
      input,
      text.length,
      nullptr,
      0,
      nullptr,
      nullptr,
    );
    if (size <= 0) return null;
    final output = calloc<Uint8>(size);
    try {
      final written = _wideCharToMultiByte!(
        _codePageGbk,
        0,
        input,
        text.length,
        output,
        size,
        nullptr,
        nullptr,
      );
      if (written <= 0) return null;

      return output.asTypedList(written);
    } finally {
      calloc.free(output);
    }
  } finally {
    calloc.free(input);
  }
}
