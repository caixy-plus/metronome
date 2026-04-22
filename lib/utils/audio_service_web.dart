import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import '../models/sound_type.dart';
import 'audio_service_interface.dart';
import 'volume_utils.dart';

/// Web 平台音频服务实现 - 使用 HTML5 Audio API
// ignore: non_constant_identifier_names
class AudioService extends AudioServiceInterface {
  /// 单例模式 - 确保全局只有一个 AudioService 实例
  static final AudioService _instance = AudioService._internal();
  static AudioService get instance => _instance;

  AudioService._internal();

  final Map<SoundType, web.HTMLAudioElement> _highSounds = {};
  final Map<SoundType, web.HTMLAudioElement> _lowSounds = {};
  final Map<SoundType, bool> _loaded = {};
  bool _isReady = false;
  SoundType _activeSoundType = SoundType.mechanical;

  @override
  Future<void> init() async {
    debugPrint('[AudioService] Web 平台初始化中...');
    // Web 平台：直接标记为就绪
    // 音频上下文会在用户首次交互后自动唤醒
    _isReady = true;
    debugPrint('[AudioService] Web 平台初始化完成');
  }

  Future<bool> _loadSoundType(SoundType type) async {
    if (_loaded[type] == true) return true;
    try {
      final highPath = _getSoundPath(type, true);
      final lowPath = _getSoundPath(type, false);

      // 使用 HTML5 AudioElement 加载音频
      final high = web.HTMLAudioElement()..src = highPath;
      final low = web.HTMLAudioElement()..src = lowPath;

      // 预加载音频
      high.preload = 'auto';
      low.preload = 'auto';

      _highSounds[type] = high;
      _lowSounds[type] = low;
      _loaded[type] = true;
      debugPrint('[AudioService] Web 成功加载: ${type.displayName}');
      return true;
    } catch (e) {
      debugPrint('[AudioService] Web 加载失败: ${type.folderName}, 错误: $e');
      return false;
    }
  }

  String _getSoundPath(SoundType type, bool isHigh) {
    final folder = type.folderName;
    final prefix = isHigh ? 'click_high' : 'click_low';
    return 'assets/sounds/$folder/$prefix.wav';
  }

  @override
  Future<void> preload() async {
    await init();
  }

  @override
  Future<void> setSoundType(SoundType type) async {
    debugPrint('[AudioService] Web 请求切换到: ${type.displayName}');
    await _loadSoundType(type);
    _activeSoundType = type;
  }

  @override
  Future<void> playClick(bool isAccent) async {
    if (!_isReady) return;

    final source = isAccent
        ? _highSounds[_activeSoundType]
        : _lowSounds[_activeSoundType];

    if (source != null) {
      final vol = VolumeUtils.getVolume(_activeSoundType, isAccent);
      source.volume = vol;
      source.currentTime = 0;
      source.play();
      debugPrint('[AudioService] Web 播放: ${_activeSoundType.displayName}, vol: $vol');
    } else {
      debugPrint('[AudioService] Web 播放失败: 资源未加载');
    }
  }

  void playPreview() {
    playClick(true);
  }

  @override
  Future<void> dispose() async {
    _highSounds.clear();
    _lowSounds.clear();
    _loaded.clear();
    _isReady = false;
  }

  @override
  void forceReinit() {
    // Web 不存在原生音频设备重建问题；这里做一次软重置即可
    //（并保持 fire-and-forget 语义与 Native 一致）
    scheduleMicrotask(() async {
      await dispose();
      await init();
      // 重新加载当前音效包（忽略失败，后续用户交互会再次触发加载/播放）
      await _loadSoundType(_activeSoundType);
    });
  }
}
