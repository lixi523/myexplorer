// myexplorer_core: native filesystem helpers exposed over a tiny C ABI.
//
// Output buffers use a big-endian layout with magic 'WDIR' that Dart's
// `FileEntryCodec` decodes in one pass.

use std::ffi::c_char;

mod codec;
mod enumerate;
mod folder_scan;
mod list;
mod pdf;
mod plugin;
mod pty;
mod search;
mod sftp;
mod trash;
mod util;
mod walker;

pub use enumerate::myexplorer_enumerate;
pub use folder_scan::{
    myexplorer_folder_scan_cancel, myexplorer_folder_scan_free, myexplorer_folder_scan_poll,
    myexplorer_folder_scan_start, FolderScanSession,
};
pub use list::myexplorer_list;
pub use pdf::{myexplorer_pdf_page_sizes, myexplorer_pdf_render};
pub use plugin::{myexplorer_plugin_invoke, myexplorer_plugin_load, myexplorer_plugin_str_free};
pub use pty::{
    myexplorer_pty_alive, myexplorer_pty_close, myexplorer_pty_open, myexplorer_pty_read, myexplorer_pty_resize,
    myexplorer_pty_write,
};
pub use search::{
    myexplorer_search, myexplorer_search_cancel, myexplorer_search_free, myexplorer_search_poll,
    myexplorer_search_start, SearchSession,
};
pub use sftp::{
    myexplorer_sftp_free_cstr, myexplorer_sftp_list, myexplorer_sftp_mkdir, myexplorer_sftp_read,
    myexplorer_sftp_realpath, myexplorer_sftp_remove, myexplorer_sftp_rename, myexplorer_sftp_session_close,
    myexplorer_sftp_session_open, myexplorer_sftp_stat, myexplorer_sftp_write, myexplorer_sftp_write_chunk,
    SftpStat,
};
pub use trash::{myexplorer_trash, myexplorer_trash_list, myexplorer_trash_purge, myexplorer_trash_restore};

/// Releases a buffer returned by any `myexplorer_*` call.
///
/// # Safety
/// `ptr`/`len` must come from a previous `myexplorer_*` call and be used exactly once.
#[no_mangle]
pub unsafe extern "C" fn myexplorer_free(ptr: *mut u8, len: usize) {
    if ptr.is_null() {
        return;
    }
    drop(Vec::from_raw_parts(ptr, len, len));
}

#[no_mangle]
pub extern "C" fn myexplorer_core_abi() -> u32 {
    16
}

#[no_mangle]
pub extern "C" fn myexplorer_core_version() -> *const c_char {
    concat!(env!("MYEXPLORER_VERSION"), "\0").as_ptr() as *const c_char
}

#[no_mangle]
pub extern "C" fn myexplorer_core_git() -> *const c_char {
    concat!(env!("MYEXPLORER_GIT"), "\0").as_ptr() as *const c_char
}
