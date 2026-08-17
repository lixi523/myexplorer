use std::ffi::OsStr;

pub(crate) const EXCLUDED: &[&str] = &[
    ".git",
    "node_modules",
    ".cache",
    ".venv",
    "__pycache__",
    "target",
    "build",
    ".gradle",
    ".idea",
];

pub(crate) fn os_bytes(s: &OsStr) -> Vec<u8> {
    s.to_string_lossy().into_owned().into_bytes()
}

pub(crate) fn path_depth(path: &[u8]) -> usize {
    path.iter().filter(|&&b| b == b'/' || b == b'\\').count()
}

pub(crate) fn num_cpus() -> usize {
    std::thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4)
}

pub(crate) fn search_threads() -> usize {
    num_cpus().saturating_sub(1).max(1)
}

pub(crate) fn mtime_ms(meta: &std::fs::Metadata) -> i64 {
    match meta.modified() {
        Ok(t) => match t.duration_since(std::time::UNIX_EPOCH) {
            Ok(d) => d.as_millis() as i64,
            Err(e) => -(e.duration().as_millis() as i64),
        },
        Err(_) => 0,
    }
}

pub(crate) fn null_with_len(out_len: *mut usize) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    unsafe {
        *out_len = 0;
    }
    std::ptr::null_mut()
}

/// Runs [f] inside a panic barrier so a panic in FFI-exposed code returns
/// [default] instead of unwinding across the C ABI (which is UB).
pub(crate) fn guard<T>(f: impl FnOnce() -> T, default: T) -> T {
    match std::panic::catch_unwind(std::panic::AssertUnwindSafe(f)) {
        Ok(value) => value,
        Err(_) => default,
    }
}
