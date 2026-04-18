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
  bool get _isWindows => Platform.isWindows;

  @override
  Future<void> init() async {
    try {
      _soloud = SoLoud.instance;
      if (_soloud == null) {
        _logError('SoLoud.instance 返回 null', null, null, true);
        _isReady = true;
        return;
      }

      if (!_soloud!.isInitialized) {
        debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 初始化音频引擎...');
        await _soloud!.init();
        debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 音频引擎初始化完成');
      }

      // 1. 强制加载基础音效，作为兜底
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 加载基础音效...');
      await _loadSoundType(SoundType.mechanical);

      // 2. 预热，直接播一声 0.01 音量的声音（不要 0 音量，有些系统会忽略）
      final s = _pool.highSounds[SoundType.mechanical];
      if (s != null) {
        await _soloud!.play(s, volume: 0.01);
        debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 音效预热完成');
      }

      _isReady = true;
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 初始化成功');
    } catch (e, stack) {
      _isReady = true;
      _logError('初始化异常', e, stack, true);
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
    if (_soloud == null) return false;
    try {
      final h = await _soloud!.loadAsset(SoundPackPaths.getHighClickPath(type));
      final l = await _soloud!.loadAsset(SoundPackPaths.getLowClickPath(type));
      _pool.highSounds[type] = h;
      _pool.lowSounds[type] = l;
      _pool.loaded[type] = true;
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 成功加载音效包: ${type.displayName}');
      return true;
    } catch (e) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 加载音效包失败: ${type.folderName}');
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 错误详情: $e');
      // Windows 特有提示
      if (_isWindows) {
        debugPrint('[AudioService] [Windows] 可能是音效文件路径问题，请确认 assets 正确配置');
      }
      return false;
    }
  }

  @override
  Future<void> preload() async {
    await init();
  }

  @override
  void playClick(bool isAccent) {
    if (_soloud == null) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 播放跳过: 音频引擎未初始化');
      return;
    }

    // 逃生出口：如果还没 Ready，尝试紧急初始化
    if (!_isReady) {
      debugPrint('[AudioService]${_isWindows ? ' [Windows]' : ''} 播放跳过: 引擎未就绪，尝试初始化...');
      init();
      return;
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
  void dispose() {
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
}