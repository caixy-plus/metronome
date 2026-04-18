import 'dart:math';
import '../models/sound_type.dart';

/// 音量工具类 - 消除 Native 和 Web 音频服务间的重复代码
class VolumeUtils {
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
}
