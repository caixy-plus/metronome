/// 节拍器设置模型
class MetronomeSettings {
  /// 每分钟节拍数
  final int bpm;

  /// 分子 - 每小节拍数 (1-16)
  final int beatsPerMeasure;

  /// 分母 - 拍号 (仅支持 1, 2, 4, 8, 16)
  final int beatUnit;

  const MetronomeSettings({
    this.bpm = 120,
    this.beatsPerMeasure = 4,
    this.beatUnit = 4,
  });

  /// 节拍间隔时间（毫秒）
  /// BPM 是绝对物理时间基准，拍号分母不影响物理时间
  /// 公式: 60000 / BPM（毫秒）
  int get intervalMs {
    if (bpm <= 0) return 500;
    return (60000 / bpm).round();
  }

  /// 显示节拍类型字符串
  String get timeSignature => '$beatsPerMeasure/$beatUnit';

  MetronomeSettings copyWith({
    int? bpm,
    int? beatsPerMeasure,
    int? beatUnit,
  }) {
    return MetronomeSettings(
      bpm: bpm ?? this.bpm,
      beatsPerMeasure: beatsPerMeasure ?? this.beatsPerMeasure,
      beatUnit: beatUnit ?? this.beatUnit,
    );
  }
}
