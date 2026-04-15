# Metronome - AI 工程维护手册

> **致接手开发的 AI 助手**：本文档定义了项目的核心架构、物理限制及平台规避策略。在修改代码前，请务必完整检索本手册。**严禁违背下述工程红线。**

---

## 🏗️ 1. 核心架构逻辑

### 1.1 音频隔离抽象

```
AudioServiceInterface（接口）
    │
    ├── audio_service_native.dart  ← flutter_soloud
    │       └── SoLoud 实例、AudioSource 池
    │
    └── audio_service_web.dart     ← HTML5 Audio
            └── AudioElement 池

调用链：MetronomeProvider → AudioServiceInterface → 具体实现
```

**🔴 工程红线**：
- 禁止在 `MetronomeProvider`（业务层）直接调用任何平台特异性音频 API
- 必须通过 `AudioServiceInterface` 调度
- 严禁在 UI 层写 `dart:html` 或 `flutter_soloud` 引用

### 1.2 高精度计时算法（核心，严禁降级）

**问题**：Flutter `Timer.periodic` 会产生累积误差，长期运行节拍会漂移。

**解决方案**：Stopwatch 绝对时间戳追踪补偿法

```dart
// lib/providers/metronome_provider.dart

void _scheduleNextTick() {
  // 1. 计算下一拍的绝对目标时间（微秒）
  //    = 总拍数 × 每拍理论时长
  final nextTargetUs = _currentBeat * _tickIntervalUs;

  // 2. 获取 Stopwatch 实际流逝时间（硬件级精度）
  final nowUs = _stopwatch.elapsedMicroseconds;

  // 3. 计算需要等待的时间
  int delayUs = nextTargetUs - nowUs;

  // 4. 若已滞后（delay < 0），跳过到下一个完整周期
  //    防止多拍"挤在一起"（bunching）
  if (delayUs < 0) {
    final missedBeats = (-delayUs / _tickIntervalUs).ceil() + 1;
    delayUs += missedBeats * _tickIntervalUs;
  }

  // 5. 使用微秒级单次 Timer 调度下一拍
  _timer = Timer(Duration(microseconds: delayUs), _onTick);
}
```

**🔴 工程红线**：
- **严禁使用 `Timer.periodic`**，必须使用单次 `Timer` 动态计算延迟
- 禁止用 `Timer.periodic` + 累加偏移量的方式计算下一拍
- `Stopwatch` 是唯一时间基准，禁止用 `DateTime.now()` 替代

### 1.3 音效切换原子性

```
setSoundType(type) → 预加载 → 标记 loaded → 下一拍自动应用
```

**逻辑顺序**：
1. `_pendingSoundType = type`（请求）
2. `await _loadSoundType(type)`（异步加载）
3. `_pool.loaded[type] == true`（成功标记）
4. 下一拍 `_executeTick()` 时自动切换

**🔴 工程红线**：
- 音效切换必须是原子操作
- 禁止在 `playClick()` 内直接调用 `_loadSoundType()`
- 若音效未加载完成，必须 `return`，不能 fallback 强行播放

---

## 🌍 2. 全平台攻坚策略

| 平台 | 核心机制 | 必知坑位 | 防御措施 |
|------|---------|---------|---------|
| **Web** | AudioContext 唤醒 | 浏览器自动播放限制 | `initAudioForWeb()` 必须在用户点击事件中调用 |
| **Windows** | WASAPI 独占模式 | 声卡被独占导致初始化崩溃 | 增强 try-catch + 详细错误日志 + 故障排查提示 |
| **macOS** | SoLoud WASM | 无物理设备 | 同 Windows 增强日志 |
| **iOS** | Dynamic Island | 仅 iPhone 14 Pro+ 支持 | 平台检测 `_isIOS`，非 iOS 静默忽略 |
| **Android** | 后台服务 | 省电策略限制 | 后台通知 + 静音模式 fallback |

### 2.1 Web 平台（最复杂）

**限制**：浏览器禁止无用户交互的音频播放

**正确流程**：
```dart
// home_screen.dart
class _HomeScreenState extends State<HomeScreen> {
  bool _webAudioUnlocked = false;

  Future<void> _unlockWebAudio(BuildContext context) async {
    if (!kIsWeb) {  // 非 Web 平台直接通过
      setState(() => _webAudioUnlocked = true);
      return;
    }
    // Web：必须在同步点击事件中调用
    await provider.initAudioForWeb();
    setState(() => _webAudioUnlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && !_webAudioUnlocked) {
      return _WebAudioUnlockScreen(onUnlock: () => _unlockWebAudio(context));
    }
    return _MetronomeHome();
  }
}
```

**🔴 工程红线**：
- `initAudioForWeb()` 禁止在 `initState` 中自动调用
- 禁止写 `if (kIsWeb) { return; }` 拦截 Web 逻辑
- Web 有自己的 `AudioService` 实现（`audio_service_web.dart`）

### 2.2 Windows 平台

**限制**：WASAPI 独占模式可能导致 `SoLoud.instance` 返回 null

**增强日志示例**：
```dart
void _logError(String msg, [Object? e, StackTrace? stack, bool isWindows = false]) {
  debugPrint('[AudioService]${isWindows ? ' [Windows]' : ''} $msg');
  if (isWindows) {
    debugPrint('[AudioService] [Windows] 故障排查:');
    debugPrint('[AudioService] [Windows] 1. 检查音频驱动是否正常');
    debugPrint('[AudioService] [Windows] 2. 确认没有其他程序占用音频设备');
    debugPrint('[AudioService] [Windows] 3. 尝试重启 Windows 音频服务');
  }
}
```

### 2.3 iOS Dynamic Island

**限制**：仅 iPhone 14 Pro 及以上支持

```dart
class DynamicIslandService {
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> startLiveActivity({...}) async {
    if (!_isIOS) return;  // 非 iOS 静默忽略
    await _channel.invokeMethod('startLiveActivity', {...});
  }
}
```

**🔴 工程红线**：
- 禁止在非 iOS 平台抛出异常
- 必须使用 `defaultTargetPlatform` 而非 `kIsWeb` / `Platform.isIOS`

---

## 📂 3. 资源管理规范

### 3.1 路径逻辑

```
assets/sounds/{folder_name}/click_high.wav
assets/sounds/{folder_name}/click_low.wav
```

| 音效 | folder_name | 示例路径 |
|------|-------------|---------|
| 经典机械音 | mechanical | assets/sounds/mechanical/click_high.wav |
| 电子合成音 | electronic | assets/sounds/electronic/click_high.wav |
| 鼓机音效 | drum | assets/sounds/drum/click_high.wav |
| 木鱼/梆子 | woodblock | assets/sounds/woodblock/click_high.wav |
| 人声倒数 | voice | assets/sounds/voice/click_high.wav |

**🔴 工程红线**：
- Flutter 不支持目录递归注册
- 新增音效包时，必须在 `pubspec.yaml` 中显式声明每个子目录

### 3.2 音频规格

| 要求 | 规格 |
|------|------|
| 格式 | 16-bit PCM WAV |
| 采样率 | 44100 Hz |
| 启动延迟 | 0 毫秒（起音必须在第 0 毫秒） |
| 禁止 | MP3（有头部静音）、OGG（兼容性差） |

### 3.3 Fallback 机制

当音效加载失败时，按以下顺序 fallback：

```
1. 尝试播放目标音效
2. 失败 → fallback 到 mechanical
3. mechanical 也失败 → 静默忽略（不崩溃）
```

---

## 🛠️ 4. 维护者守则

### 4.1 永不言弃（No-Surrender）

**❌ 禁止**：
```dart
// 严禁这样写
if (kIsWeb) {
  _isReady = true;
  return;  // 直接放弃！
}
```

**✅ 正确**：
```dart
// Web 有自己的完整实现（audio_service_web.dart）
// 若 flutter_soloud 在 Web 上失败，提供 HTML5 Audio 回退
```

### 4.2 同步优先

**感官同步原理**：人脑对声音的感知有 ~10ms 滞后

```
旧代码顺序：playClick() → notifyListeners()  ❌
新代码顺序：notifyListeners() → playClick()  ✅
         （UI 先闪，声音后到，感官同步）
```

### 4.3 防御式编程

| 场景 | 防御措施 |
|------|---------|
| `_soloud` 可能为 null | `if (_soloud == null) return;` |
| `_pool.loaded[type]` 可能为 null | `if (_pool.loaded[type] != true) return;` |
| `_timerSeq` 过期回调 | 序列号检查 `if (seq != _timerSeq) return;` |
| 窗口关闭时资源泄漏 | `dispose()` 释放所有 AudioSource + 调用 `deinit()` |

---

## 🧪 5. 自我审计清单

在提交任何修改前，请自问：

| # | 问题 | 若"是"则回滚 |
|---|------|-------------|
| 1 | 我是否引入了 `Timer.periodic`？ | 必须重写为单次 Timer |
| 2 | 我的修改是否破坏了 Web 端的"手势唤醒"链路？ | 检查 `initAudioForWeb()` 调用链 |
| 3 | 我是否处理了音效文件 404 时的 Fallback？ | 必须有回退到 mechanical 的逻辑 |
| 4 | Windows/macOS 路径下我是否验证了正斜杠兼容性？ | Flutter AssetManager 自动处理 |
| 5 | 我的修改是否在非 iOS 平台抛出了 Dynamic Island 异常？ | 必须静默忽略 |
| 6 | 我是否在 `initState` 中自动调用了音频 `init()`？ | Web 端禁止，必须在用户事件中 |
| 7 | `dispose()` 是否正确释放了所有资源？ | 必须调用 `deinit()` |

---

## 📊 6. 文件速查

| 文件 | 职责 | 禁止修改的内容 |
|------|------|--------------|
| `audio_service.dart` | 条件导出入口 | 导出逻辑 |
| `audio_service_native.dart` | Native 音频实现 | 类名 `AudioService` |
| `audio_service_web.dart` | Web 音频实现 | 类名 `AudioService` |
| `metronome_provider.dart` | 计时 + 状态 | `_scheduleNextTick()` 算法 |
| `dynamic_island_service.dart` | iOS Live Activity | `_isIOS` 平台判断 |
| `sound_type.dart` | 音效类型 + 路径 | `folderName` 映射 |

---

## ⚠️ 7. 违规示例与正确对照

### 7.1 Timer.periodic 违规

```dart
// ❌ 错误：会累积误差
_timer = Timer.periodic(Duration(milliseconds: interval), (_) {
  _executeTick();
});

// ✅ 正确：单次 Timer + 动态计算
_timer = Timer(Duration(microseconds: delayUs), _onTick);
```

### 7.2 Web 拦截违规

```dart
// ❌ 错误：直接放弃 Web
if (kIsWeb) {
  return;
}

// ✅ 正确：Web 有自己的实现
// audio_service_web.dart 中的 AudioService 会被条件导出
```

### 7.3 音效切换违规

```dart
// ❌ 错误：非原子操作
void playClick(bool isAccent) {
  if (_pendingSoundType != _activeSoundType) {
    _loadSoundType(_pendingSoundType);  // 异步！来不及
    _activeSoundType = _pendingSoundType;
  }
}

// ✅ 正确：等待加载完成后才切换
void playClick(bool isAccent) {
  if (_pendingSoundType != _activeSoundType) {
    if (_pool.loaded[_pendingSoundType] == true) {
      _activeSoundType = _pendingSoundType;  // 原子切换
    }
  }
}
```

---

## 🚀 9. 图标更新

### 9.1 使用图标更新脚本

当需要更换 App 图标时，使用脚本自动更新所有平台的图标：

```bash
# 赋予执行权限（首次使用）
chmod +x scripts/update_icon.sh

# 运行脚本（传入新图标路径）
./scripts/update_icon.sh ~/Downloads/icon.png
```

**脚本功能：**
1. 裁切图标中心 800x800 区域（去除水印）
2. 添加圆角效果
3. 自动更新 Android/iOS/macOS/Windows 图标

**前提条件：**
- 安装 ImageMagick: `brew install imagemagick`

---

## 🚀 8. 项目目标

- **精度**：长期运行误差 < 1 拍/小时
- **兼容**：支持 iOS/Android/macOS/Windows/Web
- **稳定**：无崩溃、无静默失败、无资源泄漏
- **可维护**：任何 AI 接手都能遵循工程红线

---

**最后**：当你面对一个平台限制时，请记住项目采用的是 **Layer 2 降级策略**：

```
Layer 1（理想态）：SoLoud 正常工作
Layer 2（受限态）：HTML5 Audio / 静默降级 / 引导用户授权
```

**永不言弃！** 🚀
