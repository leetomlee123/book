@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem  Build Rust book_pager for Windows host and/or Android arm64
rem  Requires: rustup + cargo
rem  Host link: MinGW at D:\tools\mingw64  (or any gcc on PATH)
rem  Android: NDK (default D:\sdk\ndk\latest-ish)
rem ============================================================

cd /d "%~dp0"

set "CRATE_DIR=native"
if not exist "%CRATE_DIR%\book_pager\Cargo.toml" (
  echo [book_pager] missing native\book_pager\Cargo.toml
  exit /b 1
)

where cargo >nul 2>nul
if errorlevel 1 (
  echo [book_pager] cargo not found. Install: https://rustup.rs
  exit /b 1
)

rem Prefer project MinGW if present (needed for windows-gnu host builds)
if exist "D:\tools\mingw64\bin\gcc.exe" set "PATH=D:\tools\mingw64\bin;%PATH%"

set "DO_HOST=1"
set "DO_ANDROID=0"
if /I "%~1"=="--android" set "DO_ANDROID=1"
if /I "%~1"=="android" set "DO_ANDROID=1"
if /I "%~1"=="--android-only" (
  set "DO_HOST=0"
  set "DO_ANDROID=1"
)
if /I "%~1"=="--all" set "DO_ANDROID=1"

if "%DO_HOST%"=="1" (
  echo [book_pager] building host release...
  pushd "%CRATE_DIR%"
  cargo build -p book_pager --release
  if errorlevel 1 (
    popd
    echo [book_pager] host build failed
    exit /b 1
  )
  popd
  echo [book_pager] host OK: native\target\release\book_pager.dll
)

if "%DO_ANDROID%"=="0" (
  echo [book_pager] skip Android ^(pass --android or --all^)
  endlocal
  exit /b 0
)

echo [book_pager] ensuring aarch64-linux-android target...
rustup target add aarch64-linux-android >nul 2>nul

if not defined ANDROID_NDK_HOME (
  if exist "%ANDROID_HOME%\ndk" (
    for /f "delims=" %%D in ('dir /b /ad /o-n "%ANDROID_HOME%\ndk" 2^>nul') do (
      if not defined ANDROID_NDK_HOME set "ANDROID_NDK_HOME=%ANDROID_HOME%\ndk\%%D"
    )
  )
)
if not defined ANDROID_NDK_HOME if exist "D:\sdk\ndk" (
  for /f "delims=" %%D in ('dir /b /ad /o-n "D:\sdk\ndk" 2^>nul') do (
    if not defined ANDROID_NDK_HOME set "ANDROID_NDK_HOME=D:\sdk\ndk\%%D"
  )
)
echo [book_pager] ANDROID_NDK_HOME=!ANDROID_NDK_HOME!
if not defined ANDROID_NDK_HOME (
  echo [book_pager] ANDROID_NDK_HOME not set
  exit /b 1
)

rem Ensure cargo config points at NDK clang (native\.cargo\config.toml)
if not exist "native\.cargo\config.toml" (
  echo [book_pager] missing native\.cargo\config.toml with aarch64 linker
  exit /b 1
)

echo [book_pager] building aarch64-linux-android release...
pushd "%CRATE_DIR%"
cargo build -p book_pager --release --target aarch64-linux-android
if errorlevel 1 (
  popd
  echo [book_pager] android build failed
  exit /b 1
)
popd

set "SO=native\target\aarch64-linux-android\release\libbook_pager.so"
set "OUT=android\app\src\main\jniLibs\arm64-v8a"
if not exist "%OUT%" mkdir "%OUT%"
copy /Y "%SO%" "%OUT%\libbook_pager.so" >nul
echo [book_pager] android OK: %OUT%\libbook_pager.so
endlocal
exit /b 0
