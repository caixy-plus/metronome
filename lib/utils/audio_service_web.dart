import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_non_web
import 'dart:html' as html;
import '../models/sound_type.dart';
import 'audio_service_interface.dart';

/// Web 平台音频服务实现 - 使用 HTML5 Audio API
// ignore: non_constant_identifier_names
class AudioService extends AudioServiceInterface {
  /// 单例模式 - 确保全局只有一个 AudioService 实例
  static final AudioService _instance = AudioService._internal();
  static AudioService get instance => _instance;

  AudioService._internal();

  final Map<SoundType, html.AudioElement> _highSounds = {};
  final Map<SoundType, html.AudioElement> _lowSounds = {};
  final Map<SoundType, bool> _loaded = {};
  bool _isReady = false;
  SoundType _activeSoundType = SoundType.mechanical;

  static const Map<SoundType, double> gainOffsets = {
    SoundType.mechanical: 0.0,
    SoundType.electronic: -3.0,
    SoundType.drumMachine: -2.0,
    SoundType.woodblock: -6.0,
    SoundType.voiceCount: -4.0,
  };

  static const double kBaseVolume = 0.8;

  static double _dbToLinear(double db) {
    return pow(10, db / 20).toDouble();
  }

  static double getVolume(SoundType type, bool isAccent) {
    final offset = gainOffsets[type] ?? 0.0;
    final linearOffset = isAccent
        ? kBaseVolume * _dbToLinear(offset)
        : kBaseVolume * 0.6 * _dbToLinear(offset);
    return linearOffset.clamp(0.0, 1.0);
  }

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
      final high = html.AudioElement(highPath);
      final low = html.AudioElement(lowPath);

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
  void playClick(bool isAccent) {
    if (!_isReady) return;

    final source = isAccent
        ? _highSounds[_activeSoundType]
        : _lowSounds[_activeSoundType];

    if (source != null) {
      final vol = getVolume(_activeSoundType, isAccent);
      source.volume = vol;
      source.currentTime = 0;
      source.play().catchError((e) {
        debugPrint('[AudioService] Web 播放异常: $e');
      });
      debugPrint('[AudioService] Web 播放: ${_activeSoundType.displayName}, vol: $vol');
    } else {
      debugPrint('[AudioService] Web 播放失败: 资源未加载');
    }
  }

  void playPreview() {
    playClick(true);
  }

  @override
  void dispose() {
    _highSounds.clear();
    _lowSounds.clear();
    _loaded.clear();
    _isReady = false;
  }
}
