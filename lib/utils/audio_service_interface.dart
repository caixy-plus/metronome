import '../models/sound_type.dart';

/// 音频服务接口 - 用于测试时的 mock
abstract class AudioServiceInterface {
  Future<void> init();
  Future<void> preload();
  Future<void> setSoundType(SoundType type);
  Future<void> playClick(bool isAccent);
  Future<void> dispose();
  void forceReinit();
}