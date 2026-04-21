# Extreme Metronome | 极致全平台节拍器

<div align="center">

[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Windows%20%7C%20Web-blue?logo=buymeacoffee)]()
[![License](https://img.shields.io/badge/license-MIT-green?logo=mit)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-4.x-blue?logo=flutter)](https://flutter.dev)
[![Release](https://img.shields.io/github/v/release/caixy-plus/metronome?logo=github)](https://github.com/caixy-plus/metronome/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/caixy-plus/metronome/release.yml?logo=github-actions)](https://github.com/caixy-plus/metronome/actions)

**微秒级精度节拍器 | 一套代码 · 五端覆盖 | 零漂移计时**

[功能预览](#功能预览) · [快速开始](#快速开始) · [构建指南](#构建指南) · [架构设计](#架构设计) · [更新日志](./CHANGELOG.md) · [许可协议](./LICENSE)

</div>

---

## 功能预览

| 特性 | 说明 |
|:---|:---|
| **微秒级精度** | Stopwatch 绝对时间戳补偿，长期运行零漂移 |
| **六端全覆盖** | iOS / Android / Web / Windows / macOS 一套代码 |
| **感官同步** | UI 闪烁先于音频，利用人脑听觉滞后实现物理级对齐 |
| **音效池** | 5 套音效原子切换，内置音量标准化补偿 |
| **防御式编程** | 全局 null 检查、过期回调检测、资源自动释放 |

### 支持的平台

| iOS | Android | macOS | Windows | Web |
|:---:|:-------:|:-----:|:-------:|:---:|
| ✅ | ✅ | ✅ | ✅ | ✅* |

> Web 需首次点击解锁音频（浏览器自动播放策略限制）

---

## 快速开始

### 安装

下载对应平台的安装包：

- **macOS**: [Metronome.dmg](./release/Metronome.dmg)
- **Windows**: [Metronome.msi](./release/Metronome.msi)
- **Web**: 访问 [caixy-plus.github.io/metronome](https://caixy-plus.github.io/metronome)

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/caixy-plus/metronome.git
cd metronome

# 安装依赖
flutter pub get

# 运行（开发模式）
flutter run

# 构建发布版
flutter build macos    # macOS
flutter build windows  # Windows
flutter build apk      # Android
flutter build web      # Web
```

---

## 构建指南

### 平台要求

| 平台 | 要求 |
|:---|:---|
| macOS | Flutter SDK + Xcode |
| Windows | Flutter SDK + Visual Studio |
| Android | Flutter SDK + Android SDK |
| Web | Flutter SDK + Chrome |

### Web 首次使用

Web 浏览器有自动播放限制，首次打开会显示 **"TAP TO START"** 解锁界面，点击屏幕任意位置即可启用节拍音效。

---

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

### 目录结构

```
lib/
├── main.dart                           # 应用入口
├── models/                             # 数据模型
│   ├── metronome_settings.dart        # BPM、节拍配置
│   └── sound_type.dart                # 音效类型枚举
├── providers/                          # 状态管理
│   └── metronome_provider.dart         # 核心计时逻辑
├── screens/                            # 页面
│   ├── home_screen/                    # 主页面（含子组件）
│   │   ├── home_screen.dart
│   │   ├── play_button.dart
│   │   ├── help_dialog.dart
│   │   └── settings_bottom_sheet.dart
│   └── settings_screen.dart           # 设置页面
├── widgets/                            # 通用组件
│   ├── beat_indicator.dart             # 节拍指示器
│   ├── beat_type_selector.dart        # 节拍类型选择器
│   ├── bpm_dial.dart                  # BPM 旋钮
│   └── sound_type_tile.dart           # 音效类型磁贴
└── utils/                             # 工具类
    ├── audio_service.dart             # 条件导出入口
    ├── audio_service_native.dart      # Native 音频实现
    ├── audio_service_web.dart         # Web 音频实现
    ├── dynamic_island_service.dart    # iOS Dynamic Island
    ├── notification_service.dart      # 后台通知
    └── volume_utils.dart              # 音量工具
```

---

## 音效资源

### 目录结构

```
assets/sounds/{folder_name}/
├── click_high.wav   # 重拍（强音）
└── click_low.wav    # 轻拍（弱音）
```

### 支持的音效

| 音效 | folder | 特点 |
|:---|:---|:---|
| 经典机械音 | `mechanical` | 清脆短促，古典首选 |
| 电子合成音 | `electronic` | 80年代风格 |
| 鼓机音效 | `drum` | 现代动感 |
| 木鱼/梆子 | `woodblock` | 最高穿透力 |
| 人声倒数 | `voice` | 直观友好 |

> **注意**: Flutter 不支持目录递归注册，新增音效包需在 `pubspec.yaml` 中显式声明。

### 音频规格

| 要求 | 规格 |
|:---|:---|
| 格式 | 16-bit PCM WAV |
| 采样率 | 44100 Hz |
| 启动延迟 | 0 ms |

---

## 常见问题

**Q: Windows 没有声音？**

检查日志是否包含以下输出：
```
[AudioService] [Windows] 初始化音频引擎...
[AudioService] [Windows] 成功加载音效包
```

**Q: Web 没有声音？**

1. 确认显示 "TAP TO START" 界面
2. 点击屏幕任意位置解锁音频
3. 查看日志 `[AudioService] Web 初始化完成`

---

## 贡献

欢迎提交 Issue 和 Pull Request！

---

## 许可协议

本项目基于 [MIT License](./LICENSE) 开源。
