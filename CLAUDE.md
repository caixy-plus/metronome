# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 构建命令

```bash
flutter pub get              # 安装依赖
flutter run                 # 开发模式运行
flutter test                # 运行所有测试
flutter test test/metronome_settings_test.dart  # 运行单个测试文件
flutter analyze             # 静态分析
flutter build macos         # macOS
flutter build windows       # Windows
flutter build apk           # Android
flutter build web           # Web
```

## 发布流程
**每次发版必须按以下顺序操作：**

1. 修改 `pubspec.yaml` 中的 `version` 字段
2. 创建 commit 并 push
3. 打 tag（tag 名必须与 version 一致，如 `v1.3.5`）
4. push tag

```
# 步骤 1: 修改 pubspec.yaml version: 1.3.5
# 步骤 2: commit & push
git add pubspec.yaml
git commit -m "chore: bump version to 1.3.5"
git push

# 步骤 3 & 4: 打 tag 并 push
git tag v1.3.5
git push origin v1.3.5
```

## 常见错误

**❌ 错误流程：先打 tag，再改版本**
```
git tag v1.3.5
# 修改 pubspec.yaml version: 1.3.5
git commit -m "bump version"
git push
git push v1.3.5
```
会导致：tag 指向的 commit 不包含版本号更新，CI 构建出的 app 版本号是旧的。

**❌ 错误流程：tag 和 version 不一致**
tag 名 `v1.3.5` 但 pubspec.yaml 写 `1.3.4`，导致版本检测永远提示有新版本。

## 为什么必须先改版本再打 tag

- tag 是指向某个 commit 的指针
- CI 通过 `on.push.tags` 触发 build
- 构建产物（APK/DMG）的版本号来自当前 commit 的 `pubspec.yaml`
- 如果 tag 指向的 commit 没有更新 version，构建出的就是旧版本

## GitHub Release 自动创建

CI 配置了 `on.push.tags: v*`，当 tag push 到远程后：
1. Flutter CI 启动（使用对应 Flutter 版本）
2. 构建 Android/macOS/Windows
3. 自动创建 GitHub Release（使用 tag 名作为版本号）

发布后，用户端检测版本时会拿到正确的新版本提示。

## 架构设计

```
┌─────────────────────────────────────────────┐
│                  UI Layer                    │
│              MetronomeProvider               │
│         (BPM 逻辑 + 高精度计时)              │
└──────────────────────┬──────────────────────┘
                       │ implements
┌──────────────────────▼──────────────────────┐
│            AudioServiceInterface             │
│         (统一播放协议：init / play)          │
└──────────────────────┬──────────────────────┘
                       │ conditional export
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────┐    ┌──────────────────┐
│ audio_service_   │    │ audio_service_    │
│ native.dart      │    │ web.dart          │
│ (flutter_soloud) │    │ (HTML5 Audio)    │
└──────────────────┘    └──────────────────┘
```

### 跨平台音频条件导出

`lib/utils/audio_service.dart` 通过条件导出实现平台适配：
- Native (iOS/Android/macOS/Windows/Linux): `flutter_soloud` 低延迟音频
- Web: HTML5 Audio API（受浏览器自动播放策略限制，首次需用户交互解锁）

### 高精度计时

`MetronomeProvider` 使用 `Stopwatch` 绝对时间戳补偿，实现长期运行零漂移。UI 闪烁先于音频播放，利用人脑听觉滞后实现物理级对齐。

### 状态管理

使用 `provider` 包。`MetronomeProvider` 是核心状态类，负责 BPM 逻辑、计时器管理、音效播放和生命周期观察。

## 音效资源

音效包放在 `assets/sounds/{folder}/` 下，每个包含 `click_high.wav` 和 `click_low.wav`。需要在 `pubspec.yaml` 中显式声明（Flutter 不支持目录递归注册）。

支持的音效：`mechanical`、`electronic`、`drum`、`woodblock`、`voice`。

## CI/CD

GitHub Actions 配置在 `.github/workflows/flutter.yml`，Flutter 版本通过 `env.flutter-version` 管理（当前 3.41.7）。触发 tag push 时自动构建并发布 Release。
