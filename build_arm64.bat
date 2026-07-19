@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem  爱看书 - Android arm64-v8a only release APK
rem  Usage:
rem    build_arm64.bat
rem    build_arm64.bat 4.2.3 3
rem    build_arm64.bat 4.2.3 3 --no-obfuscate
rem
rem  Note: every "flutter" invocation must use "call" because
rem  flutter is a .bat; without call, this script exits early.
rem ============================================================

cd /d "%~dp0"

set "BUILD_NAME=1.0.0"
set "BUILD_NUMBER=1"
set "OBFUSCATE=1"

if not "%~1"=="" if /I not "%~1"=="--no-obfuscate" set "BUILD_NAME=%~1"
if not "%~2"=="" if /I not "%~2"=="--no-obfuscate" set "BUILD_NUMBER=%~2"
if /I "%~1"=="--no-obfuscate" set "OBFUSCATE=0"
if /I "%~2"=="--no-obfuscate" set "OBFUSCATE=0"
if /I "%~3"=="--no-obfuscate" set "OBFUSCATE=0"

rem Prefer project-local SDK path; fall back to env / D:\sdk
if exist "android\local.properties" (
  for /f "usebackq tokens=1,* delims==" %%A in (`findstr /b "sdk.dir=" "android\local.properties"`) do (
    set "SDK_DIR=%%B"
  )
)
if defined SDK_DIR (
  set "SDK_DIR=!SDK_DIR:\\=\!"
  set "ANDROID_HOME=!SDK_DIR!"
  set "ANDROID_SDK_ROOT=!SDK_DIR!"
)
if not defined ANDROID_HOME if exist "D:\sdk" set "ANDROID_HOME=D:\sdk"
if not defined ANDROID_SDK_ROOT if defined ANDROID_HOME set "ANDROID_SDK_ROOT=%ANDROID_HOME%"

echo.
echo [build_arm64] Flutter:
call flutter --version
if errorlevel 1 (
  echo [build_arm64] flutter not found in PATH
  exit /b 1
)
echo.
echo [build_arm64] ANDROID_HOME=%ANDROID_HOME%
echo [build_arm64] versionName=%BUILD_NAME%  versionCode=%BUILD_NUMBER%
echo [build_arm64] abi=android-arm64 only
if "%OBFUSCATE%"=="1" (echo [build_arm64] obfuscate=ON) else (echo [build_arm64] obfuscate=OFF)
echo.

echo [build_arm64] flutter pub get
call flutter pub get
if errorlevel 1 (
  echo [build_arm64] flutter pub get failed
  exit /b 1
)

set "ARGS=apk --release --target-platform android-arm64 --build-name=%BUILD_NAME% --build-number=%BUILD_NUMBER%"
if "%OBFUSCATE%"=="1" (
  if not exist "HLQ_Struggle" mkdir "HLQ_Struggle"
  set "ARGS=!ARGS! --obfuscate --split-debug-info=HLQ_Struggle"
)

echo [build_arm64] flutter build !ARGS!
echo.
call flutter build !ARGS!
if errorlevel 1 (
  echo.
  echo [build_arm64] BUILD FAILED
  exit /b 1
)

set "OUT_DIR=build\app\outputs\flutter-apk"
echo.
echo [build_arm64] BUILD OK
echo [build_arm64] Output directory: %CD%\%OUT_DIR%
if exist "%OUT_DIR%" (
  dir /b "%OUT_DIR%\*.apk"
)
echo.
echo Tip: install with:
echo   adb install -r %OUT_DIR%\app-release.apk
echo.
endlocal
exit /b 0
