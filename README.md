# 🚀 Extreme Metronome | 极致全平台节拍器

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS%20%7C%20Windows%20%7C%20Web-999?logo=buymeacoffee)]()
[![License](https://img.shields.io/badge/license-MIT-green?logo=mit)](LICENSE)

> ⚠️ **致开发者与 AI 助手**：本项目包含大量针对各平台底层差异的优化。在进行任何代码修改前，请务必阅读 [工程约束](#-工程约束-ai-context) 章节，**严禁破坏核心计时算法与平台兼容性策略**。

---

## ✨ 项目特性

| 特性 | 说明 |
|------|------|
| 🎯 **微秒级精度** | 基于硬件时钟动态补偿，长期运行零漂移 |
| 🌍 **六端全覆盖** | 一套代码完美适配 iOS, Android, Web, Windows, macOS |
| 📳 **感官同步** | UI 闪烁先于音频触发，利用人脑听觉滞后实现物理级对齐 |
| 🔊 **智能音效池** | 支持 5 套音效原子切换，内置音量标准化补偿 |
| 🛡️ **防御式编程** | 全局 null 检查、过期回调检测、资源自动释放 |

---

## 🏗️ 核心架构

项目采用 **策略模式 + 条件导入** 隔离平台差异：

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer                              │
│              MetronomeProvider                          │
│         (BPM 逻辑 + 状态调度 + 高精度计时)               │
└─────────────────────┬───────────────────────────────────┘
                      │ implements
┌─────────────────────▼───────────────────────────────────┐
│              AudioServiceInterface                      │
│           (统一播放协议：init / play / setSound)         │
└─────────────────────┬───────────────────────────────────┘
                      │ conditional export
          ┌───────────┴───────────┐
          │                       │
┌─────────▼─────────┐   ┌─────────▼─────────┐
│ audio_service_   │   │ audio_service_     │
│ native.dart      │   │ web.dart          │
│                  │   │                   │
│ flutter_soloud   │   │ HTML5 Audio API   │
│ (C++ 引擎)       │   │ (浏览器兼容)       │
└──────────────────┘   └───────────────────┘
```

### 目录结构

```
lib/
├── main.dart                          # 应用入口
│
├── models/                            # 📦 Data Layer
│   ├── metronome_settings.dart       # BPM、分子、分母配置
│   └── sound_type.dart               # 音效类型 + 路径映射
│
├── providers/                        # ⚙️ Business Logic
│   └── metronome_provider.dart      # ⭐ 核心：Stopwatch 计时 + 状态管理
│
├── screens/                          # 🖥️ UI Layer
│   └── home_screen.dart              # 主页面 + Web 音频解锁
│
│   └── widgets/
│       ├── beat_indicator.dart       # 发光圆点节拍指示器
│       ├── beat_type_selector.dart   # 分子/分母选择器
│       └── bpm_dial.dart           # 旋钮 BPM 控制
│
└── utils/                            # 🔧 工具
    ├── audio_service.dart            # 条件导出入口
    ├── audio_service_native.dart     # Native 音频实现
    ├── audio_service_web.dart        # Web 音频实现
    ├── dynamic_island_service.dart   # iOS Dynamic Island
    └── notification_service.dart     # 后台通知
```

---

## 🛠️ 工程约束 (AI Context)

> 🔴 **所有接手此项目的 AI 必须严格遵守以下规则**

### 1. 核心计时算法（严禁修改）

**问题**：`Timer.periodic` 会产生累积误差，长期运行节拍会漂移。

**解决方案**：Stopwatch 绝对时间戳追踪补偿法

```dart
// ⭐ 核心算法（位于 metronome_provider.dart）
void _scheduleNextTick() {
  // 1. 计算下一拍的绝对目标时间（微秒）
  final nextTargetUs = _currentBeat * _tickIntervalUs;

  // 2. 获取 Stopwatch 实际流逝时间
  final nowUs = _stopwatch.elapsedMicroseconds;

  // 3. 计算补偿后的等待时间
  int delayUs = nextTargetUs - nowUs;

  // 4. 若已滞后，跳过到下一个完整周期（防止 bunching）
  if (delayUs < 0) {
    final missedBeats = (-delayUs / _tickIntervalUs).ceil() + 1;
    delayUs += missedBeats * _tickIntervalUs;
  }

  // 5. 微秒级单次 Timer
  _timer = Timer(Duration(microseconds: delayUs), _onTick);
}
```

| 检查项 | 要求 |
|--------|------|
| 🔴 `Timer.periodic` | **严禁使用**，必须用单次 Timer |
| 🔴 `DateTime.now()` | **严禁替代** Stopwatch |
| 🔴 累加偏移量 | **严禁**用上一拍时间 + 间隔 |

### 2. 全平台攻坚策略（No-Surrender Rule）

面对平台限制，必须采用 **分层防御**：

| 层级 | 定义 | 行为 |
|------|------|------|
| **Layer 1** | 理想态 | 直接调用高性能引擎（如 SoLoud） |
| **Layer 2** | 受限态 | 交互触发 / 降级引擎 / 静默 fallback |

> 🚫 **严禁**：写 `if (kIsWeb) return;` 直接放弃

### 3. 平台差异手册

| 平台 | 关键限制 | 防御措施 |
|------|---------|---------|
| **Web** | 自动播放拦截 | `init()` 必须在用户点击事件中触发；Web 有独立 `AudioService` 实现 |
| **Windows** | WASAPI 独占异常 | 增强 try-catch + 详细错误日志 + 故障排查提示 |
| **iOS** | Dynamic Island 独占 | 平台检测 `_isIOS`，非 iOS 静默忽略 |
| **Android** | 省电策略 | 后台通知 + 静音模式 fallback |

### 4. 音效切换原子性

```
setSoundType(type)
    │
    ├─→ _pendingSoundType = type     (标记请求)
    │
    ├─→ await _loadSoundType(type)   (异步加载)
    │
    └─→ _pool.loaded[type] == true    (成功标记)
            │
            └─→ 下一拍自动应用（不是立即应用！）
```

> 🚫 **严禁**：在 `playClick()` 内直接调用 `_loadSoundType()`

---

## 📂 资源注册规范

### 路径结构

```
assets/sounds/{folder_name}/click_high.wav
assets/sounds/{folder_name}/click_low.wav
```

| 音效 | folder_name | 示例 |
|------|-------------|------|
| 经典机械音 | `mechanical` | `assets/sounds/mechanical/click_high.wav` |
| 电子合成音 | `electronic` | `assets/sounds/electronic/click_high.wav` |
| 鼓机音效 | `drum` | `assets/sounds/drum/click_high.wav` |
| 木鱼/梆子 | `woodblock` | `assets/sounds/woodblock/click_high.wav` |
| 人声倒数 | `voice` | `assets/sounds/voice/click_high.wav` |

### 音频规格

| 要求 | 规格 |
|------|------|
| 格式 | 16-bit PCM WAV |
| 采样率 | 44100 Hz |
| 启动延迟 | 0 毫秒（起音必须在第 0 毫秒） |
| 禁止 | MP3（头部静音）、OGG（兼容性差） |

### ⚠️ pubspec.yaml 坑

> Flutter **不支持目录递归注册**。新增音效包时，必须在 `pubspec.yaml` 中逐一显式声明：
>
> ```yaml
> assets:
>   - assets/sounds/mechanical/
>   - assets/sounds/electronic/
>   - assets/sounds/drum/
> ```

---

## 🧪 质量保证

| 检查项 | 标准 |
|--------|------|
| `flutter analyze` | 零警告 |
| `Timer.periodic` | 严禁引入 |
| Web 手势唤醒 | 链路完整 |
| Fallback 逻辑 | 音效加载失败时回退到 mechanical |
| 资源释放 | `dispose()` 必须调用 `deinit()` |

---

## ⚡ 快速构建

```bash
# 安装依赖
flutter pub get

# macOS
flutter build macos --release

# iOS（需 Xcode）
flutter build ios --release --no-codesign

# Android
flutter build apk --release

# Windows（需 Visual Studio）
flutter build windows --release

# Web
flutter build web
```

### Web 首次使用

Web 浏览器有自动播放限制，首次打开会显示 **"TAP TO START"** 解锁界面。

---

## 📊 平台特性矩阵

| 功能 | iOS | Android | macOS | Windows | Web |
|------|:---:|:-------:|:-----:|:-------:|:---:|
| 高精度计时 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 音效播放 | ✅ | ✅ | ✅ | ✅ | ✅* |
| Dynamic Island | ✅ | ❌ | ❌ | ❌ | ❌ |
| 后台通知 | ✅ | ✅ | ✅ | ❌ | ❌ |
| 静音模式 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Tap Tempo | ✅ | ✅ | ✅ | ✅ | ✅ |

> Web*：需首次点击解锁音频

---

## ❓ 常见问题

**Q: Windows 没有声音？**
```
检查日志是否包含：
[AudioService] [Windows] 初始化音频引擎...
[AudioService] [Windows] 加载基础音效...
[AudioService] [Windows] 成功加载音效包: xxx
若卡在某步，查看错误详情。
```

**Q: Web 没有声音？**
```
1. 确认显示 "TAP TO START" 界面
2. 点击屏幕任意位置解锁音频
3. 查看日志 [AudioService] Web 初始化完成
```

---

## 📖 相关文档

| 文档 | 受众 | 说明 |
|------|------|------|
| `README.md` | 人类开发者 | 项目介绍、构建指南 |
| `README_AI_CONTEXT.md` | AI 助手 | 工程红线、违规示例 |

---

## 📜 License

[MIT License](LICENSE)

---

> **💡 给 AI 助手的话**：当你面对平台限制时，请记住项目采用的是 **Layer 2 降级策略**。**永不言弃！** 🚀
