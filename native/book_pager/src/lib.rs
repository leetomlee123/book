mod layout;

pub use layout::{paginate, LayoutInput, TextLineOut, TextPageOut};

use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::panic::{catch_unwind, AssertUnwindSafe};

/// ABI version for Dart-side capability checks.
///
/// Bump when the C API or required runtime behaviour changes in a way that
/// older packaged `.so` files must not be used.
///
/// History:
/// - 1: initial export (no version symbol; Android crashed without fonts)
/// - 2: Android system fonts + catch_unwind + shared FontSystem
pub const BOOK_PAGER_ABI_VERSION: i32 = 2;

/// Returns [`BOOK_PAGER_ABI_VERSION`]. Safe to call before any other export.
#[no_mangle]
pub extern "C" fn book_pager_abi_version() -> i32 {
    BOOK_PAGER_ABI_VERSION
}

/// Paginate chapter text.
///
/// * `input_json` — UTF-8 JSON of [`LayoutInput`]
/// * returns heap-allocated C string JSON of `Vec<TextPageOut>`; free with
///   [`book_pager_free_string`].
///
/// On error returns a JSON object `{"error":"..."}`.
///
/// **Safety:** panics inside cosmic-text / layout are caught so they never
/// unwind across the Dart FFI boundary (which would abort the process).
#[no_mangle]
pub extern "C" fn book_pager_paginate(input_json: *const c_char) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| paginate_inner(input_json)));
    match result {
        Ok(ptr) => ptr,
        Err(_) => to_c_string(r#"{"error":"panic in book_pager"}"#),
    }
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
        Ok(pages) => match serde_json::to_string(&pages) {
            Ok(s) => to_c_string(&s),
            Err(e) => to_c_string(&format!(r#"{{"error":"encode: {}"}}"#, e)),
        },
        Err(e) => to_c_string(&format!(r#"{{"error":"{}"}}"#, e.replace('"', "'"))),
    }
}

/// Free a string returned by [`book_pager_paginate`].
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
    // Strip interior NULs so CString::new never fails on chapter text edges.
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
