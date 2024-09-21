<#
.SYNOPSIS
    This script automates the build process for a Rust project targeting WebAssembly.

.DESCRIPTION
    The script performs the following tasks:
    1. Checks if `cargo` is installed and installs it if necessary.
    2. Checks if `wasm-pack` is installed and installs it if necessary.
    3. Removes the `pkg` directory if it exists.
    4. Parses command-line arguments to determine the manifest version and build mode.
    5. Builds the project using `wasm-pack` in either release or development mode.
    6. Copies the appropriate `manifest.json` file to the `pkg` directory based on the specified manifest version.
    7. Generates a `run_wasm.js` file in the `pkg` directory.

.PARAMETER --manifest-version
    Specifies the version of the manifest file to use (v2 or v3). Defaults to v2 if not specified.

.PARAMETER --release
    Builds the project in release mode. If not specified, the project is built in development mode.

.EXAMPLE
    ./build.ps1 --manifest-version=v3 --release
    This command builds the project in release mode using manifest version 3.

.NOTES
    Ensure that you have the necessary permissions to install software and modify files in the project directory.
#>

# 检查 cargo 是否安装
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "Installing cargo..."
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://sh.rustup.rs'))
}

# 检查 wasm-pack 是否安装
if (-not (Get-Command wasm-pack -ErrorAction SilentlyContinue)) {
    Write-Host "Installing wasm-pack..."
    cargo install wasm-pack
}

# 删除 pkg 目录
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue pkg

# 解析参数
$manifest_version = ""
$release = $false

foreach ($arg in $args) {
    if ($arg -like "--manifest-version=*") {
        $manifest_version = $arg -replace '--manifest-version=', ''
    }
    if ($arg -eq "--release") {
        $release = $true
    }
}

# 根据参数选择构建模式
if ($release) {
    wasm-pack build --target no-modules --release
    if ($LASTEXITCODE -ne 0) { exit 1 }
}
else {
    wasm-pack build --target no-modules --dev
    if ($LASTEXITCODE -ne 0) { exit 1 }
}

# 复制 manifest.json 到 pkg
if ($manifest_version -eq "v3" -or $manifest_version -eq "3") {
    Copy-Item manifest_v3.json pkg/manifest.json
}
elseif ($manifest_version -eq "v2" -or $manifest_version -eq "2") {
    Copy-Item manifest_v2.json pkg/manifest.json
}
else {
    Write-Host "Packaging with manifest version v2. Pass --manifest-version=v3 to package with manifest version 3."
    Copy-Item manifest_v2.json pkg/manifest.json
}

# 复制 background.js 到 pkg
Copy-Item background.js pkg/background.js


# 生成 run_wasm.js 文件
@"
const runtime = chrome.runtime || browser.runtime;

async function run() {
  await wasm_bindgen(runtime.getURL('demo02_bg.wasm'));
}

run();
"@ | Out-File -FilePath pkg/run_wasm.js -Encoding utf8 -Append