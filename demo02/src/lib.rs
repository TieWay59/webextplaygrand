use std::borrow::Cow;

use wasm_bindgen::prelude::*;
use web_sys::*;

#[macro_use]
mod util;

/// Decodes a percent-encoded URL string.
///
/// This function takes a percent-encoded URL string and returns a decoded version of it.
/// The decoded string is returned as a `Cow<str>`, which can be either a borrowed or owned string.
///
/// # Arguments
///
/// * `encoded` - A string slice that holds the percent-encoded URL.
///
/// # Returns
///
/// * `Cow<str>` - A decoded URL string, which can be either borrowed or owned.
fn decode_url(encoded: &str) -> Cow<str> {
    percent_encoding::percent_decode_str(encoded).decode_utf8_lossy()
}

#[wasm_bindgen(start)]
pub async fn main() {
    std::panic::set_hook(Box::new(console_error_panic_hook::hook));

    say_hello();

    tryout_history_example_1().await;
}

/// return a promise
#[wasm_bindgen]
pub async fn tryout_history_example_1() {
    // make js object as query
    // https://developer.chrome.com/docs/extensions/reference/api/history#method-search
    // use web_extensions api to do the same thing:
    let q = web_extensions::history::Query {
        text: "",
        max_results: Some(3),
        ..Default::default()
    };

    let res = web_extensions::history::search(&q).await;

    if let Ok(history_item) = res {
        for (i, item) in history_item.iter().enumerate() {
            log!("[wtw debug]: case {i}: {item:#?}");

            log!(
                "decoded url: {}",
                decode_url(item.url.as_deref().unwrap_or("no url found."))
            );
        }
    } else {
        log!("not found");
    }
}

/// example for getting `milliseconds since the epoch` from rust
#[wasm_bindgen]
pub fn get_raw_js_timestamp() -> i64 {
    let now = js_sys::Date::now();
    now as i64
}

/// 我有点好奇能不能用 chrono 库获取时间功能？答案可以的，需要 chrono 开启 feature `wasm-bindgen`
#[wasm_bindgen]
pub fn get_chrono_timestamp() -> i64 {
    let now = chrono::Local::now();

    // 用 chrono 获取 两个月前是时间戳：
    let two_months_ago = now - chrono::Duration::days(60);
    log!("two_months_ago: {:?}", two_months_ago.timestamp_millis());

    now.timestamp_millis()
}

/// A simple function that logs a message to the console.
/// integrated test by `wasm_bindgen.say_hello();`
#[wasm_bindgen]
pub fn say_hello() {
    log!("Hello from Rust!");
}
