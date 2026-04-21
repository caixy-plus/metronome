import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/sound_type.dart';
import 'audio_service_interface.dart';
import 'volume_utils.dart';

/// 音效池
class _SoundPool {
  final Map<SoundType, AudioSource?> highSounds = {};
  final Map<SoundType, AudioSource?> lowSounds = {};
  final Map<SoundType, bool> loaded = {};

  double getVolume(SoundType type, bool isAccent) => VolumeUtils.getVolume(type, isAccent);
}

/// 音频服务 - 防御性最强版本 (Native)
/// 支持 iOS/Android/macOS/Windows/Linux
class AudioService extends AudioServiceInterface {
  /// 单例模式 - 确保全局只有一个 AudioService 实例
  static final AudioService _instance = AudioService._internal();
  static AudioService get instance => _instance;

  AudioService._internal();

  SoLoud? _soloud;
  final _SoundPool _pool = _SoundPool();
  SoundType _activeSoundType = SoundType.mechanical;
  SoundType _pendingSoundType = SoundType.mechanical;
  bool _isReady = false;
  bool get isReady => _isReady;
  bool _isInitializing = false;
  bool get _isWindows => Platform.isWindows;
  static Future<void>? _initTask; // 静态锁，全局只有一个初始化任务
  int _lastPlayTime = 0; // 上次播放时间，用于防止原生层重叠

  @override
  Future<void> init() async {
    // 如果已经初始化完成且引擎健在，直接返回
    if (_isReady && _soloud != null && _soloud!.isInitialized) {
      // 防止“引擎在，但资源池被清空/未加载”的无声状态
      if (_pool.loaded[SoundType.mechanical] != true) {
        await _loadSoundType(SoundType.mechanical);
      }
      return;
    }

    // 如果正在初始化，就等待那个 Future，而不是重开
    if (_initTask != null) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 初始化已在进行中，等待完成...');
      return _initTask;
    }

    _initTask = _realInit();
    return _initTask;
  }

  Future<void> _realInit() async {
    try {
      _isInitializing = true;
      _soloud = SoLoud.instance;
      if (_soloud == null) {
        _logError('SoLoud.instance 返回 null', null, null, true);
        _isReady = false;
        return;
      }

      // 关键：如果已经初始化好了，直接退出，不准重复 init()
      // 注意：即便 native 侧显示“已初始化”，也不能跳过 _soloud.init()。
      // Android/iOS 在 Activity/Engine 重建后，Dart 侧 loader 可能是新实例，
      // 临时目录未 initialize，直接 loadAsset 会抛 TemporaryFolderFailed。
      // flutter_soloud 的 init() 内部会在发现 native 已 init 时先 deinit 再重建，
      // 并重新初始化 loader 临时目录。

      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 开始物理初始化原生引擎...');
      await _soloud!.init();

      // 关键：加载资源前加个微小延迟，确保临时文件夹被 OS 准备好
      await Future.delayed(const Duration(milliseconds: 200));

      // 1. 强制加载基础音效，作为兜底
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 加载基础音效...');
      await _loadSoundType(SoundType.mechanical);

      // 2. 预热，直接播一声 0.01 音量的声音（不要 0 音量，有些系统会忽略）
      final s = _pool.highSounds[SoundType.mechanical];
      if (s != null) {
        _soloud!.play(s, volume: 0.01);
        debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 音效预热完成');
      }

      _isReady = true;
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 初始化成功');
    } catch (e, stack) {
      _isReady = false;
      _soloud = null;
      _logError('初始化异常', e, stack, true);
    } finally {
      _isInitializing = false;
      _initTask = null; // 结束后清除缓存
    }
  }

  /// 统一错误日志
  void _logError(String msg, [Object? e, StackTrace? stack, bool isWindows = false]) {
    final prefix = '[AudioService]${isWindows ? ' [Windows]' : ''}';
    debugPrint('$prefix $msg');
    if (e != null) {
      debugPrint('$prefix 错误详情: $e');
    }
    if (stack != null) {
      debugPrint('$prefix 堆栈: $stack');
    }
    if (isWindows) {
      debugPrint('$prefix Windows 音频故障排查:');
      debugPrint('$prefix 1. 检查音频驱动是否正常');
      debugPrint('$prefix 2. 确认没有其他程序占用音频设备');
      debugPrint('$prefix 3. 尝试重启 Windows 音频服务');
    }
  }

  Future<bool> _loadSoundType(SoundType type) async {
    if (_pool.loaded[type] == true) return true;
    // 防止在 init 尚未完成（loader 临时目录尚未初始化）时触发 loadAsset()
    if (!_isReady && !_isInitializing) {
      await init();
    }
    if (_soloud == null) return false;

    // Android/iOS 有时会在引擎 init() 刚完成时，临时目录仍未就绪，
    // 这会导致 loadAsset() 抛出 SoLoudTemporaryFolderFailedException。
    // 这里做有限次重试，避免首拍无声。
    const int maxAttempts = 5;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final h = await _soloud!.loadAsset(SoundPackPaths.getHighClickPath(type));
        final l = await _soloud!.loadAsset(SoundPackPaths.getLowClickPath(type));
        _pool.highSounds[type] = h;
        _pool.lowSounds[type] = l;
        _pool.loaded[type] = true;
        debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 成功加载音效包: ${type.displayName}');
        return true;
      } catch (e) {
        final msg = e.toString();
        final bool isTempFolderNotReady = msg.contains('SoLoudTemporaryFolderFailedException') ||
            msg.contains("Temporary directory hasn't been initialized");

        debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 加载音效包失败: ${type.folderName} (attempt $attempt/$maxAttempts)');
        debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 错误详情: $e');

        if (isTempFolderNotReady && attempt < maxAttempts) {
          // 递增等待：200ms, 300ms, 400ms, ...
          await Future.delayed(Duration(milliseconds: 100 + 100 * attempt));
          continue;
        }

        // Windows 特有提示
        if (_isWindows) {
          debugPrint('[AudioService] [Windows] 可能是音效文件路径问题，请确认 assets 正确配置');
        }
        return false;
      }
    }

    return false;
  }

  @override
  Future<void> preload() async {
    await init();
  }

  @override
  Future<void> playClick(bool isAccent) async {
    // 时间防护：50ms 内不准播两次，防止原生层重叠
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPlayTime < 50) return;
    _lastPlayTime = now;

    if (_soloud == null) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 播放跳过: 音频引擎未初始化');
      return;
    }

    // 逃生出口：如果还没 Ready，紧急初始化并等待完成后再播放
    if (!_isReady) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 引擎未就绪，紧急初始化中...');
      await init();
      // init() 完成后 _isReady 应为 true，继续执行下面的播放逻辑
    }

    // 自动提交切换逻辑
    if (_pendingSoundType != _activeSoundType) {
      if (_pool.loaded[_pendingSoundType] == true) {
        _activeSoundType = _pendingSoundType;
        debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 自动切换到: $_activeSoundType');
      }
    }

    // 获取资源：当前选中的 -> 默认机械音
    AudioSource? source = isAccent
        ? _pool.highSounds[_activeSoundType]
        : _pool.lowSounds[_activeSoundType];

    // Fallback 兜底逻辑
    if (source == null) {
      source = isAccent
          ? _pool.highSounds[SoundType.mechanical]
          : _pool.lowSounds[SoundType.mechanical];
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 使用 Fallback 音效');
    }

    if (source != null) {
      final vol = _pool.getVolume(_activeSoundType, isAccent);
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 播放: ${_activeSoundType.displayName}, 音量: $vol, isAccent: $isAccent');
      _soloud!.play(source, volume: vol);
    } else {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 彻底没声音了！');
    }
  }

  @override
  Future<void> setSoundType(SoundType type) async {
    debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 请求切换到: ${type.displayName}');
    // 确保引擎/loader 已初始化，否则 loadAsset 会因临时目录未就绪而失败
    await init();
    _pendingSoundType = type;
    await _loadSoundType(type);
  }

  void playPreview() {
    if (_soloud == null) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 预览跳过: 音频引擎未初始化');
      return;
    }
    if (!_isReady) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 预览跳过: 引擎未就绪');
      return;
    }

    // 预览时直接使用 pending 类型
    SoundType typeToPlay = _pendingSoundType;
    // 如果目标类型未加载，不播放（用户会再次点击预览）
    if (_pool.loaded[typeToPlay] != true) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 预览跳过: ${typeToPlay.displayName} 未加载');
      return;
    }

    final source = _pool.highSounds[typeToPlay];
    if (source != null) {
      final vol = _pool.getVolume(typeToPlay, true);
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 预览: $typeToPlay, 音量: $vol');
      _soloud!.play(source, volume: vol);
    }
  }

  @override
  Future<void> dispose() async {
    // 不再设置 _forceReinit，因为强制重初始化会导致竞态问题
    // 引擎由 App 生命周期管理，不需要显式销毁

    if (_soloud == null) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} dispose: 音频引擎已清理');
      return;
    }

    debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 开始释放音频资源...');

    // 释放所有加载的音效源
    for (final type in SoundType.values) {
      if (_pool.loaded[type] == true) {
        final high = _pool.highSounds[type];
        final low = _pool.lowSounds[type];
        try {
          if (high != null) _soloud!.disposeSource(high);
          if (low != null) _soloud!.disposeSource(low);
          debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 已释放: ${type.displayName}');
        } catch (e) {
          debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 释放失败: ${type.displayName}, $e');
        }
      }
    }

    // 清空池
    _pool.highSounds.clear();
    _pool.lowSounds.clear();
    _pool.loaded.clear();

    // 关闭音频引擎
    try {
      _soloud!.deinit();
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 音频引擎已关闭');
    } catch (e) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 引擎关闭失败: $e');
    }

    // 防止后续误用
    _soloud = null;
    _isReady = false;
  }

  /// 重新初始化音频引擎（仅在必要时调用）
  @override
  void forceReinit() {
    // iOS/Android 在后台->前台切换时，底层音频设备/焦点可能丢失，
    // 但 SoLoud 仍然保持“已初始化”状态，导致看似正常却无声。
    // 这里做一次“硬重建”：清空资源池、关闭引擎、再 init 并重新加载。
    //
    // 注意：forceReinit 是 fire-and-forget（接口是 void），通过 _initTask 串行化避免竞态。
    if (_initTask != null) return;

    _initTask = () async {
      // 这里不能在持有 _initTask 锁的情况下 await init()（会自我等待）
      // 所以分两段：先彻底清理 -> 释放锁 -> 再 init。
      try {
        _isInitializing = true;

        // 1) 清空资源池，避免 _loadSoundType() 误判已加载
        _pool.highSounds.clear();
        _pool.lowSounds.clear();
        _pool.loaded.clear();

        // 2) 关闭引擎（如果存在）
        try {
          if (_soloud != null && _soloud!.isInitialized) {
            _soloud!.deinit();
          }
        } catch (e, stack) {
          _logError('forceReinit: 引擎关闭异常', e, stack, _isWindows);
        }

        _soloud = null;
        _isReady = false;
      } finally {
        _isInitializing = false;
        _initTask = null; // 先释放锁，允许后续 init() 正常执行
      }

      // 3) 重新 init 并确保当前音效包可用（fire-and-forget 的异步链）
      await init();
      await _loadSoundType(_pendingSoundType);
    }();
  }
}
