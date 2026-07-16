# Local patches to flutter_js 0.8.7

## Built-in Kotlin (Flutter 3.44 / AGP 9)

- Removed `apply plugin: 'kotlin-android'` from `android/build.gradle`.
- Replaced deprecated `android.kotlinOptions` with top-level
  `kotlin { compilerOptions { jvmTarget = JVM_17 } }`.
- Added `compileOptions` Java 17.

Mirrors https://github.com/abner/flutter_js/pull/191.

Drop this vendored tree and switch `pubspec.yaml` back to a hosted
`flutter_js: ^0.8.8` (or later) once upstream publishes Built-in Kotlin support.
