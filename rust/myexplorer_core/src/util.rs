use std::ffi::OsStr;
use std::io::Write;

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

pub(crate) fn mtime_ms(meta: &std::fs::Metadata) -> Option<i64> {
    match meta.modified() {
        Ok(t) => match t.duration_since(std::time::UNIX_EPOCH) {
            Ok(d) => i64::try_from(d.as_millis()).ok(),
            Err(e) => i64::try_from(e.duration().as_millis())
                .ok()
                .map(|v| -v),
        },
        Err(_) => None,
    }
}

/// # Safety
/// `out_len` 必须指向一块有效、已对齐且至少可写入 `sizeof(usize)` 字节的内存。
/// 调用方负责保证指针的生命周期和排他性。
pub(crate) unsafe fn null_with_len(out_len: *mut usize) -> *mut u8 {
    if out_len.is_null() {
        return std::ptr::null_mut();
    }
    debug_assert!(
        out_len.align_offset(std::mem::align_of::<usize>()) == 0,
        "out_len pointer is not properly aligned"
    );
    unsafe {
        *out_len = 0;
    }
    std::ptr::null_mut()
}

/// Runs [f] inside a panic barrier so a panic in FFI-exposed code returns
/// [default] instead of unwinding across the C ABI (which is UB). The panic
/// message is written to `%TEMP%\myexplorer_core_panic.log` for diagnostics.
pub(crate) fn guard<T>(f: impl FnOnce() -> T, default: T) -> T {
    match std::panic::catch_unwind(std::panic::AssertUnwindSafe(f)) {
        Ok(value) => value,
        Err(payload) => {
            log_panic(payload);
            default
        }
    }
}

/// Records a caught panic payload (message or `&str`) so a swallowed panic can
/// be diagnosed even when the app has no console. Best effort: logging a panic
/// must never itself panic.
pub(crate) fn log_panic(payload: Box<dyn std::any::Any + Send>) {
    // 通过 downcast 恢复 panic 消息文本，避免 `dyn Any` 直接 Debug 输出地址。
    let msg = if let Some(s) = payload.downcast_ref::<&str>() {
        s.to_string()
    } else if let Some(s) = payload.downcast_ref::<String>() {
        s.clone()
    } else {
        format!("{payload:?}")
    };
    let line = format!("myexplorer_core panic: {msg}\n");
    // FFI 边界场景下 stderr 通常不可用，写入仅为调试兜底；
    // 真正的诊断信息通过 TEMP 日志文件捕获。
    if std::env::var("MYEXPLORER_PANIC_TO_STDERR").is_ok() {
        let mut err = std::io::stderr();
        let _ = err.write_all(line.as_bytes());
    }
    if let Ok(temp) = std::env::var("TEMP") {
        let path = std::path::Path::new(&temp).join("myexplorer_core_panic.log");
        if let Ok(mut f) = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(path)
        {
            let _ = std::io::Write::write_all(&mut f, line.as_bytes());
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn guard_swallows_panics_and_returns_default() {
        let value = guard(|| -> i32 { panic!("boom") }, 42);
        assert_eq!(value, 42);
    }

    #[test]
    fn guard_passes_through_success() {
        let value = guard(|| 7 + 1, 0);
        assert_eq!(value, 8);
    }
}
