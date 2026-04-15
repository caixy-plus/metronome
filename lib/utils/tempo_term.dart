/// 速度术语映射表
/// 根据 BPM 返回对应的意大利语音乐术语
class TempoTerm {
  final String term;
  final String meaning;
  final int minBpm;
  final int maxBpm;

  const TempoTerm({
    required this.term,
    required this.meaning,
    required this.minBpm,
    required this.maxBpm,
  });

  bool contains(int bpm) => bpm >= minBpm && bpm <= maxBpm;
}

/// 意大利语速度术语列表（按 BPM 从慢到快排序）
const List<TempoTerm> tempoTerms = [
  TempoTerm(term: 'Grave', meaning: '庄板', minBpm: 25, maxBpm: 45),
  TempoTerm(term: 'Largo', meaning: '广板', minBpm: 40, maxBpm: 60),
  TempoTerm(term: 'Adagio', meaning: '柔板', minBpm: 55, maxBpm: 76),
  TempoTerm(term: 'Andante', meaning: '行板', minBpm: 73, maxBpm: 120),
  TempoTerm(term: 'Moderato', meaning: '中板', minBpm: 108, maxBpm: 132),
  TempoTerm(term: 'Allegro', meaning: '快板', minBpm: 120, maxBpm: 156),
  TempoTerm(term: 'Vivace', meaning: '活板', minBpm: 144, maxBpm: 176),
  TempoTerm(term: 'Presto', meaning: '急板', minBpm: 168, maxBpm: 240),
];

/// 根据 BPM 获取对应的速度术语
String getTempoTerm(int bpm) {
  for (final term in tempoTerms) {
    if (term.contains(bpm)) {
      return term.term;
    }
  }
  // 边界情况
  if (bpm < 25) return 'Grave';
  return 'Presto';
}

/// 根据 BPM 获取速度术语及其中文含义
(String term, String meaning) getTempoTermWithMeaning(int bpm) {
  for (final term in tempoTerms) {
    if (term.contains(bpm)) {
      return (term.term, term.meaning);
    }
  }
  // 边界情况
  if (bpm < 25) return ('Grave', '庄板');
  return ('Presto', '急板');
}
