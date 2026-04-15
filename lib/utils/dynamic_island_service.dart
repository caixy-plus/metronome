import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dynamic Island Service - iOS Live Activity 控制
/// 仅在 iOS 平台有效，macOS/Android 调用时静默忽略
class DynamicIslandService {
  static const MethodChannel _channel = MethodChannel('com.example.metronome/dynamic_island');

  /// 检查是否为 iOS 平台
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// 启动 Live Activity（Dynamic Island）
  static Future<void> startLiveActivity({
    required int bpm,
    required int beatsPerMeasure,
  }) async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod('startLiveActivity', {
        'bpm': bpm,
        'beatsPerMeasure': beatsPerMeasure,
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to start Live Activity: ${e.message}');
    }
  }

  /// 更新 Live Activity
  static Future<void> updateLiveActivity({
    required int currentBeat,
    required int beatsPerMeasure,
    required bool isPlaying,
  }) async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod('updateLiveActivity', {
        'currentBeat': currentBeat,
        'beatsPerMeasure': beatsPerMeasure,
        'isPlaying': isPlaying,
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to update Live Activity: ${e.message}');
    }
  }

  /// 结束 Live Activity
  static Future<void> endLiveActivity() async {
    if (!_isIOS) return;
    try {
      await _channel.invokeMethod('endLiveActivity');
    } on PlatformException catch (e) {
      debugPrint('Failed to end Live Activity: ${e.message}');
    }
  }
}
