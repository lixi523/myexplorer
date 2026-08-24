use std::ffi::{c_char, c_void, CStr, CString};
use std::sync::atomic::{AtomicBool, AtomicI32, AtomicU64, Ordering};
use std::sync::{Arc, Mutex};

const PROGRESS_CONTINUE: u32 = 0;
const PROGRESS_CANCEL: u32 = 1;
const COPY_FILE_FAIL_IF_EXISTS: u32 = 0x00000001;
const ERROR_REQUEST_ABORTED: u32 = 1235;

type CopyProgressRoutine = unsafe extern "system" fn(
    i64,
    i64,
    i64,
    i64,
    u32,
    u32,
    *mut c_void,
    *mut c_void,
    *mut c_void,
) -> u32;

extern "system" {
    fn CopyFileExW(
        existing: *const u16,
        new_file: *const u16,
        progress: Option<CopyProgressRoutine>,
        data: *mut c_void,
        cancel: *mut i32,
        flags: u32,
    ) -> i32;
    fn GetLastError() -> u32;
}

struct CopyState {
    cancel: AtomicBool,
    bytes: AtomicU64,
    done: AtomicBool,
    result: AtomicI32,
    thread: Mutex<Option<std::thread::JoinHandle<()>>>,
}

unsafe extern "system" fn progress_cb(
    _total: i64,
    transferred: i64,
    _stream_size: i64,
    _stream_transferred: i64,
    _stream_number: u32,
    _reason: u32,
    _source: *mut c_void,
    _dest: *mut c_void,
    data: *mut c_void,
) -> u32 {
    if data.is_null() {
        return PROGRESS_CANCEL;
    }
    let state = &*(data as *const CopyState);
    state.bytes.store(transferred.max(0) as u64, Ordering::Relaxed);
    if state.cancel.load(Ordering::Relaxed) {
        PROGRESS_CANCEL
    } else {
        PROGRESS_CONTINUE
    }
}

fn mark_done(state: &CopyState, result: i32) {
    state.result.store(result, Ordering::Relaxed);
    state.done.store(true, Ordering::Relaxed);
}

fn run_copy(state: Arc<CopyState>, src: CString, dst: CString) {
    let src_str = match src.to_str() {
        Ok(s) => s,
        Err(_) => {
            mark_done(&state, 2);

            return;
        }
    };
    let dst_str = match dst.to_str() {
        Ok(s) => s,
        Err(_) => {
            mark_done(&state, 2);

            return;
        }
    };
    let mut src_wide: Vec<u16> = src_str.encode_utf16().collect();
    src_wide.push(0);
    let mut dst_wide: Vec<u16> = dst_str.encode_utf16().collect();
    dst_wide.push(0);
    let data = Arc::as_ptr(&state) as *mut c_void;
    let ok = unsafe {
        CopyFileExW(
            src_wide.as_ptr(),
            dst_wide.as_ptr(),
            Some(progress_cb),
            data,
            std::ptr::null_mut(),
            COPY_FILE_FAIL_IF_EXISTS,
        )
    };
    if ok == 0 {
        let err = unsafe { GetLastError() };
        if state.cancel.load(Ordering::Relaxed) || err == ERROR_REQUEST_ABORTED {
            mark_done(&state, 1);
        } else {
            mark_done(&state, 2);
        }
    } else {
        mark_done(&state, 0);
    }
}

/// Starts an asynchronous CopyFileEx-based copy on a background thread.
/// Returns a handle (free with `myexplorer_copy_free`) or null on failure.
///
/// # Safety
/// `src`/`dst` must be valid NUL-terminated UTF-8 C strings.
#[no_mangle]
pub unsafe extern "C" fn myexplorer_copy_start(
    src: *const c_char,
    dst: *const c_char,
) -> *mut c_void {
    crate::util::guard(
        || {
            if src.is_null() || dst.is_null() {
                return std::ptr::null_mut();
            }
            let src = CStr::from_ptr(src).to_owned();
            let dst = CStr::from_ptr(dst).to_owned();
            let arc = Arc::new(CopyState {
                cancel: AtomicBool::new(false),
                bytes: AtomicU64::new(0),
                done: AtomicBool::new(false),
                result: AtomicI32::new(2),
                thread: Mutex::new(None),
            });
            let worker = arc.clone();
            let handle = std::thread::spawn(move || {
                run_copy(worker, src, dst);
            });
            *arc.thread.lock().unwrap() = Some(handle);

            Arc::into_raw(arc) as *mut c_void
        },
        std::ptr::null_mut(),
    )
}

/// Polls a copy started by `myexplorer_copy_start`. Returns 0 on success and
/// fills `out_bytes` (transferred), `out_done` (0/1) and `out_result`
/// (0 ok, 1 cancelled, 2 failed); -1 on invalid pointers.
///
/// # Safety
/// `handle` must come from `myexplorer_copy_start`; out pointers writable.
#[no_mangle]
pub unsafe extern "C" fn myexplorer_copy_poll(
    handle: *mut c_void,
    out_bytes: *mut u64,
    out_done: *mut i32,
    out_result: *mut i32,
) -> i32 {
    crate::util::guard(
        || {
            if handle.is_null() || out_bytes.is_null() || out_done.is_null() || out_result.is_null()
            {
                return -1;
            }
            let state = &*(handle as *const CopyState);
            *out_bytes = state.bytes.load(Ordering::Relaxed);
            *out_done = state.done.load(Ordering::Relaxed) as i32;
            *out_result = state.result.load(Ordering::Relaxed);
            0
        },
        -1,
    )
}

/// Requests cancellation of an in-flight copy. The background thread stops as
/// soon as CopyFileEx observes the flag via its progress routine.
///
/// # Safety
/// `handle` must come from `myexplorer_copy_start` and still be alive.
#[no_mangle]
pub unsafe extern "C" fn myexplorer_copy_cancel(handle: *mut c_void) {
    crate::util::guard(
        || {
            if handle.is_null() {
                return;
            }
            let state = &*(handle as *const CopyState);
            state.cancel.store(true, Ordering::Relaxed);
        },
        (),
    )
}

/// Frees a copy handle, joining its background thread first.
///
/// # Safety
/// `handle` must come from `myexplorer_copy_start` and be used exactly once.
#[no_mangle]
pub unsafe extern "C" fn myexplorer_copy_free(handle: *mut c_void) {
    crate::util::guard(
        || {
            if handle.is_null() {
                return;
            }
            let arc = Arc::from_raw(handle as *const CopyState);
            let join = {
                let mut guard = arc.thread.lock().unwrap();
                guard.take()
            };
            if let Some(t) = join {
                let _ = t.join();
            }
        },
        (),
    )
}
