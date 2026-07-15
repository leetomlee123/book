mod layout;

pub use layout::{paginate, LayoutInput, TextLineOut, TextPageOut};

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// Paginate chapter text.
///
/// * `input_json` — UTF-8 JSON of [`LayoutInput`]
/// * returns heap-allocated C string JSON of `Vec<TextPageOut>`; free with
///   [`book_pager_free_string`].
///
/// On error returns a JSON object `{"error":"..."}`.
#[no_mangle]
pub extern "C" fn book_pager_paginate(input_json: *const c_char) -> *mut c_char {
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
    let pages = layout::paginate(&input);
    match serde_json::to_string(&pages) {
        Ok(s) => to_c_string(&s),
        Err(e) => to_c_string(&format!(r#"{{"error":"encode: {}"}}"#, e)),
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
    CString::new(s).map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut())
}
