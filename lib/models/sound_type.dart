/// 音效类型枚举
enum SoundType {
  /// 经典机械音 - 模仿传统木制节拍器
  mechanical('mechanical', '经典机械音', '清脆短促，古典音乐练习首选'),

  /// 电子合成音 - 正弦波/方波
  electronic('electronic', '电子合成音', '80年代风格，高噪音环境'),

  /// 鼓机音效 - 现代架子鼓
  drumMachine('drum', '鼓机音效', '现代动感，流行/摇滚'),

  /// 木鱼/梆子 - 最高穿透力
  woodblock('woodblock', '木鱼/梆子', '穿透力最强，管弦乐'),

  /// 人声倒数 - "One Two Three Four"
  voiceCount('voice', '人声倒数', '直观友好，舞蹈练习');

  final String folderName;
  final String displayName;
  final String description;

  const SoundType(this.folderName, this.displayName, this.description);
}

/// 音效包路径映射 - 单一数据源，使用枚举的 folderName
class SoundPackPaths {
  static String getHighClickPath(SoundType type) {
    return 'assets/sounds/${type.folderName}/click_high.wav';
  }

  static String getLowClickPath(SoundType type) {
    return 'assets/sounds/${type.folderName}/click_low.wav';
  }
}