mod layout;

pub use layout::{
    cancel_job, paginate, paginate_pages, LayoutInput, PaginateResult, TextLineOut, TextPageOut,
};

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::panic::{catch_unwind, AssertUnwindSafe};

/// ABI version for Dart-side capability checks.
///
/// History:
/// - 1: initial export
/// - 2: Android system fonts + catch_unwind + shared FontSystem
/// - 3: semantic lines (top/height/justify/target_width), no dx/dy,
///      required font_path, range/cancel, PaginateResult envelope
pub const BOOK_PAGER_ABI_VERSION: i32 = 3;

/// Returns [`BOOK_PAGER_ABI_VERSION`].
#[no_mangle]
pub extern "C" fn book_pager_abi_version() -> i32 {
    BOOK_PAGER_ABI_VERSION
}

/// Full-chapter or range paginate.
///
/// Input: UTF-8 JSON of [`LayoutInput`].
/// Output: UTF-8 JSON of [`PaginateResult`] or `{"error":"..."}`.
/// Free with [`book_pager_free_string`].
#[no_mangle]
pub extern "C" fn book_pager_paginate(input_json: *const c_char) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| paginate_inner(input_json)));
    match result {
        Ok(ptr) => ptr,
        Err(_) => to_c_string(r#"{"error":"panic in book_pager"}"#),
    }
}

/// Alias for range/incremental pagination (same as paginate; controlled by
/// `first_page_only` / `start_char` / `max_pages` in the input JSON).
#[no_mangle]
pub extern "C" fn book_pager_paginate_range(input_json: *const c_char) -> *mut c_char {
    book_pager_paginate(input_json)
}

/// Cancel an in-flight job started with the given `job_id`.
#[no_mangle]
pub extern "C" fn book_pager_cancel(job_id: u64) {
    let _ = catch_unwind(AssertUnwindSafe(|| {
        cancel_job(job_id);
    }));
}

fn paginate_inner(input_json: *const c_char) -> *mut c_char {
    if input_json.is_null() {
        return to_c_string(r#"{"error":"null input"}"#);
    }
    let cstr = unsafe { CStr::from_ptr(input_json) };
    let input_str = match cstr.to_str() {
        Ok(s) => s,
        Err(e) => {
            return to_c_string(&format!(r#"{{"error":"utf8: {}"}}"#, e));
        }
    };
    let input: LayoutInput = match serde_json::from_str(input_str) {
        Ok(v) => v,
        Err(e) => {
            return to_c_string(&format!(r#"{{"error":"json: {}"}}"#, e));
        }
    };
    match layout::paginate(&input) {
        Ok(result) => match serde_json::to_string(&result) {
            Ok(s) => to_c_string(&s),
            Err(e) => to_c_string(&format!(r#"{{"error":"encode: {}"}}"#, e)),
        },
        Err(e) => to_c_string(&format!(r#"{{"error":"{}"}}"#, e.replace('"', "'"))),
    }
}

/// Free a string returned by paginate APIs.
#[no_mangle]
pub extern "C" fn book_pager_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(ptr));
    }
}

fn to_c_string(s: &str) -> *mut c_char {
    if s.bytes().any(|b| b == 0) {
        let cleaned: String = s.chars().filter(|c| *c != '\0').collect();
        return CString::new(cleaned)
            .map(|c| c.into_raw())
            .unwrap_or(std::ptr::null_mut());
    }
    CString::new(s)
        .map(|c| c.into_raw())
        .unwrap_or(std::ptr::null_mut())
}
