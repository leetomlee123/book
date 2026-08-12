# AiKanShu (爱看书)

[中文](README.md) · English

An open-source **Flutter novel reader**. Local book sources, bookshelf management, multiple page-turn modes, and WeChat Reading–style paper themes.

| Package | Application ID | License |
|---------|----------------|---------|
| `book` | `com.opensource.ikanshu` | [Apache-2.0](LICENSE) |

---

## Features

- **Bookshelf / Discover / Me** main tabs
- **Local book-source engine** (Legado-style rule subset: HTTP + CSS/JSON/JS)
- **Reader**
  - Simulation / cover / none / vertical scroll
  - Solid paper themes (white / cream / green / night)
  - Custom font import
  - Chapter body + page-layout cache (`reader.db`)
  - Auto reading-progress save
  - Source switch & TOC sync
- **Firebase Analytics + Crashlytics** (optional; needs `google-services.json`)
- **Android-first**; no maintained iOS tree

---

## Tech stack

| Area | Choice |
|------|--------|
| Language / SDK | Dart 3.12+ / Flutter 3.44+ |
| State | Riverpod (`ChangeNotifierProvider`) |
| HTTP | Dio 5 |
| Routing | Fluro |
| Storage | sqflite (`reader.db`) + shared_preferences |
| Book-source JS | flutter_js (local patch under `third_party/flutter_js`) |
| Pagination | Optional Rust `book_pager` + Dart `TextPainter` fallback |
| Analytics / crash | Firebase Analytics / Crashlytics |

Architecture notes: [CLAUDE.md](CLAUDE.md).

---

## Requirements

- Flutter **3.44** stable (Dart **3.12**)
- Android SDK (`ANDROID_HOME` / `sdk.dir` in `local.properties`)
- Optional on Windows: MinGW (host `libbook_pager`), Android NDK (arm64 / x86_64)

```bash
flutter doctor
```

---

## Quick start

```bash
# Dependencies
flutter pub get

# Run (device / emulator connected)
flutter run

# Analyze
flutter analyze

# Tests
flutter test
```

### Build APK

```bash
# Debug
flutter build apk --debug

# Release (all ABIs)
flutter build apk

# arm64-focused Windows scripts (obfuscation / split / SKSL — see script comments)
build_arm64.bat
# or
build.bat
```

### GitHub Actions

| Workflow | File | Trigger |
|----------|------|---------|
| **CI** | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | push / PR: `flutter analyze` + `flutter test` |
| **Build APK** | [`.github/workflows/build.yml`](.github/workflows/build.yml) | push `master`/`main`, tags `v*`, manual `workflow_dispatch`, `repository_dispatch: starred` |

**Release example:**

```bash
git tag v1.0.0+10
git push origin v1.0.0+10
```

**Optional signing secrets** (repo → Settings → Secrets and variables → Actions):

| Secret | Meaning |
|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | base64 of the keystore (`base64 -w0 key.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | store password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |

Without secrets, release falls back to debug signing (same as local). Artifacts are uploaded; `v*` tags also attach assets to a GitHub Release.

### Native pager (optional)

```bat
build_book_pager.bat              # Windows host DLL
build_book_pager.bat --android    # arm64-v8a + x86_64 → jniLibs
```

If `libbook_pager.so` is missing for the ABI, the app falls back to Dart pagination.

### Firebase (optional)

1. Place `google-services.json` under `android/app/`
2. Enable **Analytics** and **Crashlytics** in the Firebase console
3. `FirebaseBootstrap` initializes on boot; failure does not block startup

---

## Layout (summary)

```
lib/
  view/book/          # Shelf, search, detail, reader
  view/page_turn/     # Canvas page-turn
  model/              # ChangeNotifier models
  model/reader/       # Reader collaborators (paging, cache, source switch…)
  data/               # reader.db + repositories
  source/             # Book-source engine
  common/             # Dio, SpUtil, layout helpers
  service/            # Firebase, cache, etc.
android/              # Declarative Gradle (Kotlin DSL)
```

---

## Screenshots

| Shelf | Search | History |
|-------|--------|---------|
| <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094941.6ui6kxf4hoc0.jpg" width="200" alt="Shelf" /> | <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094937.24cxmini4c8w.jpg" width="200" alt="Search" /> | <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094933.3nokctuthdo0.jpg" width="200" alt="History" /> |

| Reader | Settings | Discover |
|--------|----------|----------|
| <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094929.53rt8w0s78s0.jpg" width="200" alt="Reader" /> | <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094921.2skc99dvu120.jpg" width="200" alt="Settings" /> | <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094945.303pgmllpyy0.jpg" width="200" alt="Discover" /> |

---

## Related

- [听书楼 / flutter_voice](https://github.com/leetomlee123/flutter_voice) — audiobook client

---

## Star history

[![Star History Chart](https://star-history.dera.page/svg?repos=leetomlee123/book&type=Date)](https://star-history.dera.page/#leetomlee123/book&Date)

---

## Acknowledgements

Thanks to [JetBrains](https://www.jetbrains.com/?from=fluttercandies) for open-source IDE support.

[<img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/下载.6f482qcio000.svg" width="160" alt="JetBrains" />](https://www.jetbrains.com)

---

## License

[Apache License 2.0](LICENSE)
