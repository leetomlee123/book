# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter novel reader app (小书屋 / 即刻追书). Package name: `book`. Application ID: `com.leetomlee.book`. Open-source (Apache-2.0).

Tech stack: Dart 3 / Flutter 3.44+, **Riverpod** (`flutter_riverpod` + `ChangeNotifierProvider`), event_bus, Dio 5, Fluro, sqflite, protobuf, shared_preferences (via local `SpUtil` facade).

**SDK constraint:** `sdk: ^3.12.0` — sound null safety. Target Flutter 3.44 stable (Dart 3.12).

## Commands

```bash
# Install dependencies
flutter pub get

# Analyze (flutter_lints via analysis_options.yaml)
flutter analyze

# Run on a connected device/emulator
flutter run

# Run tests
flutter test
flutter test test/widget_test.dart   # single test file

# Debug APK (requires a valid Android SDK / ANDROID_HOME)
flutter build apk --debug

# Release APK (CI-style)
flutter build apk

# Release APK matching build.bat (obfuscated, arm64 split, SKSL warm-up)
flutter build apk --obfuscate --split-debug-info=HLQ_Struggle --target-platform android-arm64 --split-per-abi --build-name=4.2.3 --build-number=3 --bundle-sksl-path flutter_01.sksl.json

# Regenerate json_serializable code (optional; *.g.dart are also hand-maintained)
dart run build_runner build --delete-conflicting-outputs
```

`build.bat` is the project’s release build script (Windows). CI (`.github/workflows/dart.yml`) runs `flutter pub get` then `flutter build apk` on `repository_dispatch` type `starred`.

There is no separate lint script beyond `flutter analyze`. `file_names` is enabled (all lib paths are snake_case). Residual SpUtil/API-shaped identifiers still suppress `non_constant_identifier_names` / `constant_identifier_names`.

`pubspec.yaml` uses `dependency_overrides.platform: ^3.1.6` because transitive `sqflite_platform_interface` otherwise pulls `platform 3.0.0`, which references removed `io.Platform.packageRoot` on Dart 3.12.

## Architecture

### Boot sequence

1. `main()` → `AppInit.init()` then `runApp(const ProviderScope(child: MyApp()))`.
2. `AppInit` (`lib/app_init.dart`) requests media/storage permission (mobile), initializes local `SpUtil` (`lib/common/local_store.dart`), registers `TelAndSmsService` on global `GetIt` (`locator` in `lib/main.dart`), configures Fluro (`Routes`), loads package version, and fetches remote parse/font config from `Common.config`.
3. `MyApp` is a `ConsumerWidget` watching `colorModelProvider` for theming; home is `MainShell` (书架 / 发现 / 我); routes via `Routes.router.generator`; toasts via BotToast.

### State management

- **Riverpod** via `lib/store/providers.dart` (providers only; no `Store` facade class):
  - Root: `ProviderScope` in `main.dart`
  - Providers: `searchModelProvider`, `exploreModelProvider`, `colorModelProvider`, `shelfModelProvider`, `readModelProvider`, `sourceModelProvider` (`ChangeNotifierProvider`)
  - Models remain `ChangeNotifier` subclasses under snake_case files (`search_model.dart`, `explore_model.dart`, `color_model.dart`, `shelf_model.dart`, `read_model.dart`, `source_model.dart`)
  - UI uses `ConsumerWidget` / `ConsumerStatefulWidget` with `ref.watch` / `ref.read` directly.
- **event_bus** (`lib/event/event.dart`) for cross-widget signals (reading progress, shelf sync, page controller, download progress, etc.). Global: `eventBus`.
- **GetIt** for a few services (`locator`), not for the main UI models.

### Layers

| Path | Role |
|------|------|
| `lib/view/book/` | Core UI: shelf, search, detail, reader (`read_book.dart`), chapters, sort shelf |
| `lib/view/page_turn/` | Canvas page-turn: `novel_page_painter.dart`, `reader_page_manager.dart` |
| `lib/view/person/` | Account: login, register, me, skin, cache |
| `lib/view/system/` | Reader chrome: font, menu, battery, log viewer |
| `lib/model/` | `ChangeNotifier` business logic (snake_case: `read_model.dart`, `shelf_model.dart`, …) |
| `lib/entity/` | DTOs: `json_annotation` + checked-in `*.g.dart` (camelCase fields; no legacy JSON key compat) |
| `lib/common/` | Shared infra: API URLs (`common.dart`), Dio (`Http.dart`), text layout (`text_composition.dart`), interceptors, `Screen`, **`local_store.dart` (SpUtil/DateUtil/NumUtil)** |
| `lib/data/` | Local persistence: `ReaderDatabase` (`reader.db`), `BookRepository`, `ChapterRepository`, `SourceRepository` |
| `lib/route/` | Fluro route table (`Routes.dart`) and handlers (`RouteHandler.dart`) |
| `lib/animation/` | Custom page-turn animations used by the reader |
| `lib/widgets/` | Reusable UI pieces |
| `lib/service/` | Cache manager, tel/SMS helper |

### Networking

- Singleton `HttpUtil` (`lib/common/Http.dart`): Dio 5 + `AuthInterceptor` (adds `auth` header from SpUtil + UA) + `ErrorInterceptor` (`DioException` → BotToast).
- Timeouts use `Duration` (Dio 5), not raw ints.
- Base URLs and path constants live in `lib/common/common.dart` (`Common.domain`, shelf/search/chapter endpoints, SpUtil key names). Prefer adding endpoints there rather than hardcoding URLs in views.
- JSON decode off the UI isolate via top-level `parseJson` + `compute`.
- Backend may be HTTP cleartext; Android keeps `android:usesCleartextTraffic="true"`.

### Local data

- **sqflite** single-file **`reader.db`** (`lib/data/db/reader_database.dart`): tables `books` + `chapters` + `sources` (FK cascade on chapters, page-layout cache on chapter rows).
  - Access via `BookRepository` / `ChapterRepository` / `SourceRepository` under `lib/data/repositories/` (`ShelfModel`, `ReadModel`, `SourceModel`, shelf UI).
  - Boot (`AppInit`) calls `ReaderDatabase.wipeLegacyDatabases()` — deletes old `books.db` / `chapters.db` / `sources.db` (and dead video/voice DBs). **No data migration.** Also scrubs legacy SpUtil `*pages*` keys.
- **SpUtil** is a **local facade** over `shared_preferences` in `lib/common/local_store.dart` (not flustars). Same key strings as before (`auth`, theme, fonts, reading style, remote config). Login: `SpUtil.haveKey("token")` / `"auth"`. Also provides `DateUtil` / `NumUtil` / `DirectoryUtil` used by call sites.

### Reader pipeline (high level)

`ReadModel` owns the active book, chapter list (`List<ChapterTocEntry>`), pre/cur/next `ReadPage`, background, and menu state. Content is laid out by `TextComposition.parseContentAsync` (preferred) / `parseContent`:

1. Metrics (`fontSize`, box size, padding…) are read on the **UI isolate** (`SpUtil` / `Screen`).
2. **Rust** `book_pager` runs via `BookPager.paginateAsync` → `Isolate.run` so long chapters do **not** block frames (each worker isolate loads `libbook_pager` itself).
3. If the native lib is missing, falls back to Dart `TextPainter` on the caller isolate (after one event-loop yield).

Pages are painted by `NovelPagePainter` / `ReadModel.drawContent` (per-page, cached), and flipped via `ReaderPageManager`. Progress is persisted locally and can sync with the server when authenticated.

**Rust pager build**

```bat
build_book_pager.bat              # host DLL for Windows
build_book_pager.bat --android    # arm64-v8a + x86_64 → android/app/src/main/jniLibs
build_book_pager.bat --android-only
```

Requires `rustup`/`cargo`. Android needs NDK. Host GNU builds need a working MinGW (`D:\tools\mingw64` or update `native\.cargo\config.toml`).

`libbook_pager.so` is only packaged for ABIs present under `android/app/src/main/jniLibs/`.  
x86_64 emulators need `jniLibs/x86_64/libbook_pager.so` — without it the app falls back to Dart `TextPainter` (works, just slower / noisier logs). Physical arm64 devices use the existing arm64 build.

### Navigation

Fluro paths are constants on `Routes` (e.g. `/read`, `/search`, `/detail`, `/login`). Use `Routes.navigateTo(context, path, params: {...})` so query values are URI-encoded. Handlers deserialize JSON route args into entities (e.g. `Book`, `BookInfo`).

### Platform notes

- **Android-only** target for this migration. No `ios/` tree is maintained.
- **Android** uses declarative Flutter Gradle plugin (Kotlin DSL):
  - `android/settings.gradle.kts`, `android/build.gradle.kts`, `android/app/build.gradle.kts`
  - AGP / Kotlin versions follow the Flutter 3.44 template (currently AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0)
  - `namespace` / `applicationId`: `com.leetomlee.book`
  - Release signing loads `android/key.properties` only if present; keystore is `android/app/key.jks` (resolved as `app/key.jks` from project root). Without keystore, release falls back to debug signing.
- Removed / not wired: JPush, flustars, keframe, flutter_swiper, flutter_statusbar_manager, flutter_xupdate.
- Assets under `images/` (declared in `pubspec.yaml`).
- SKSL warm-up file: `flutter_01.sksl.json` (used by release build).
- Android SDK is at `D:\sdk`. Flutter config (`%APPDATA%\.flutter_settings` → `android-sdk`) must match; a wrong path (e.g. `D:\asdk`) overrides `ANDROID_HOME` and makes doctor report SDK missing.
- `android/local.properties` should contain `sdk.dir=D:\\sdk` and `flutter.sdk=...`.
- Requires `cmdline-tools/latest` under the SDK and accepted licenses (`sdkmanager --licenses` / `flutter doctor --android-licenses`).

## Conventions when changing code

- Follow existing patterns: Riverpod providers (`ref.watch`/`ref.read`) for models, `HttpUtil.instance.dio` for HTTP, `Common.*` for URLs/keys, `eventBus.fire/on` for loose coupling. Do not reintroduce a `Store` facade.
- Prefer `package:book/common/local_store.dart` for prefs/date/num helpers — do not reintroduce flustars.
- Entity JSON: models use `fromJson`/`toJson` with sibling `*.g.dart`. Core entity/model files use **snake_case** paths and **camelCase** fields (no legacy JSON key compat).
- Prefer Chinese UI strings consistent with the rest of the app.
- Release obfuscation dumps go under `HLQ_Struggle/` (gitignored).
