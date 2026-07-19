# 爱看书

[English](README_EN.md) · 中文

一款开源的 **Flutter 网络小说阅读器**。支持本地书源、书架管理、多种翻页方式与微信读书风格纸张主题。

| 包名 | Application ID | 许可 |
|------|----------------|------|
| `book` | `com.leetomlee.book` | [Apache-2.0](LICENSE) |

---

## 功能特性

- **书架 / 发现 / 我的** 三栏主页
- **本地书源引擎**（Legado 规则子集：HTTP + CSS/JSON/JS 规则）
- **阅读器**
  - 仿真 / 覆盖 / 无动画 / 纵向滚动
  - 微信风格纸张主题（白 / 米 / 绿 / 夜）
  - 自定义字体导入
  - 章节缓存与分页缓存（`reader.db`）
  - 阅读进度自动保存
  - 换源与目录同步
- **Firebase Analytics + Crashlytics**（可选，需 `google-services.json`）
- **Android** 优先；无维护 iOS 工程树

---

## 技术栈

| 类别 | 选型 |
|------|------|
| 语言 / SDK | Dart 3.12+ / Flutter 3.44+ |
| 状态管理 | Riverpod（`ChangeNotifierProvider`） |
| 网络 | Dio 5 |
| 路由 | Fluro |
| 本地存储 | sqflite（`reader.db`）+ shared_preferences |
| 书源 JS | flutter_js（本地补丁，见 `third_party/flutter_js`） |
| 分页 | Rust `book_pager`（可选）+ Dart `TextPainter` 回退 |
| 统计 / 崩溃 | Firebase Analytics / Crashlytics |

架构与模块划分详见 [CLAUDE.md](CLAUDE.md)。

---

## 环境要求

- Flutter **3.44** 稳定版（Dart **3.12**）
- Android SDK（`ANDROID_HOME` / `local.properties` 中 `sdk.dir`）
- Windows 上构建可选：MinGW（host 版 `libbook_pager`）、Android NDK（arm64 / x86_64）

```bash
flutter doctor
```

---

## 快速开始

```bash
# 依赖
flutter pub get

# 运行（已连接设备 / 模拟器）
flutter run

# 静态分析
flutter analyze

# 测试
flutter test
```

### 构建 APK

```bash
# Debug
flutter build apk --debug

# Release（全 ABI）
flutter build apk

# arm64 专用脚本（混淆 / split / SKSL 等，见脚本注释）
build_arm64.bat
# 或
build.bat
```

### GitHub Actions 打包

| Workflow | 文件 | 触发 |
|----------|------|------|
| **CI** | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | push / PR：`flutter analyze` + `flutter test` |
| **Build APK** | [`.github/workflows/build.yml`](.github/workflows/build.yml) | `master`/`main` push、标签 `v*`、手动 `workflow_dispatch`、`repository_dispatch: starred` |

**发布示例：**

```bash
# 打标签并推送 → 自动构建并创建 GitHub Release
git tag v1.0.0+10
git push origin v1.0.0+10
```

**可选签名 Secrets**（仓库 → Settings → Secrets and variables → Actions）：

| Secret | 说明 |
|--------|------|
| `ANDROID_KEYSTORE_BASE64` | keystore 文件 base64（`base64 -w0 key.jks`） |
| `ANDROID_KEYSTORE_PASSWORD` | store 密码 |
| `ANDROID_KEY_ALIAS` | key 别名 |
| `ANDROID_KEY_PASSWORD` | key 密码 |

未配置时与本地一致：release 回退 debug 签名。产物上传为 Artifact；`v*` 标签额外挂到 Release。

### 原生分页库（可选）

```bat
build_book_pager.bat              # Windows host DLL
build_book_pager.bat --android    # arm64-v8a + x86_64 → jniLibs
```

未打包对应 ABI 的 `libbook_pager.so` 时，自动回退到 Dart 分页。

### Firebase（可选）

1. 将 `google-services.json` 放到 `android/app/`
2. Firebase 控制台启用 **Analytics** 与 **Crashlytics**
3. 启动时由 `FirebaseBootstrap` 初始化；失败不阻塞 App

---

## 项目结构（摘要）

```
lib/
  view/book/          # 书架、搜索、详情、阅读器
  view/page_turn/     # 画布翻页
  model/              # ChangeNotifier 业务模型
  model/reader/       # 阅读器协作类（分页、缓存、换源…）
  data/               # reader.db + repositories
  source/             # 书源引擎
  common/             # Dio、SpUtil、布局等
  service/            # Firebase、缓存等
android/              # 声明式 Gradle（Kotlin DSL）
```

---

## 截图

| 书架 | 搜索 | 历史 |
|------|------|------|
| <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094941.6ui6kxf4hoc0.jpg" width="200" alt="书架" /> | <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094937.24cxmini4c8w.jpg" width="200" alt="搜索" /> | <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094933.3nokctuthdo0.jpg" width="200" alt="历史" /> |

| 阅读 | 设置 | 发现 |
|------|------|------|
| <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094929.53rt8w0s78s0.jpg" width="200" alt="阅读" /> | <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094921.2skc99dvu120.jpg" width="200" alt="设置" /> | <img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/微信图片_20210528094945.303pgmllpyy0.jpg" width="200" alt="发现" /> |

---

## 相关项目

- [听书楼](https://github.com/leetomlee123/flutter_voice) — 听书客户端

---

## Star 历史

[![Star History Chart](https://api.star-history.com/svg?repos=leetomlee123/book&type=Date)](https://star-history.com/#leetomlee123/book&Date)

---

## 致谢

感谢 [JetBrains](https://www.jetbrains.com/?from=fluttercandies) 为开源项目提供的 IDE 支持。

[<img src="https://cdn.jsdelivr.net/gh/leetomlee123/hugoblogtalks@master/20210528/下载.6f482qcio000.svg" width="160" alt="JetBrains" />](https://www.jetbrains.com)

---

## 许可

[Apache License 2.0](LICENSE)
