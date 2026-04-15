import 'package:flutter_test/flutter_test.dart';
import 'package:metronome/models/metronome_settings.dart';

void main() {
  group('MetronomeSettings', () {
    test('默认构造函数设置正确的默认值', () {
      const settings = MetronomeSettings();

      expect(settings.bpm, 120);
      expect(settings.beatsPerMeasure, 4);
      expect(settings.beatUnit, 4);
    });

    test('构造函数接受自定义值', () {
      const settings = MetronomeSettings(
        bpm: 100,
        beatsPerMeasure: 3,
        beatUnit: 4,
      );

      expect(settings.bpm, 100);
      expect(settings.beatsPerMeasure, 3);
      expect(settings.beatUnit, 4);
    });

    test('intervalMs 计算正确', () {
      const settings120 = MetronomeSettings(bpm: 120);
      expect(settings120.intervalMs, 500);

      const settings60 = MetronomeSettings(bpm: 60);
      expect(settings60.intervalMs, 1000);

      const settings240 = MetronomeSettings(bpm: 240);
      expect(settings240.intervalMs, 250);
    });

    test('timeSignature 返回正确格式', () {
      const settings = MetronomeSettings(
        beatsPerMeasure: 4,
        beatUnit: 4,
      );
      expect(settings.timeSignature, '4/4');

      const settings2 = MetronomeSettings(
        beatsPerMeasure: 3,
        beatUnit: 4,
      );
      expect(settings2.timeSignature, '3/4');

      const settings3 = MetronomeSettings(
        beatsPerMeasure: 6,
        beatUnit: 8,
      );
      expect(settings3.timeSignature, '6/8');
    });

    test('copyWith 创建新实例并保留未修改的值', () {
      const original = MetronomeSettings(
        bpm: 120,
        beatsPerMeasure: 4,
        beatUnit: 4,
      );

      final modified = original.copyWith(bpm: 100);

      expect(modified.bpm, 100);
      expect(modified.beatsPerMeasure, 4);
      expect(modified.beatUnit, 4);

      // 原始实例不变
      expect(original.bpm, 120);
    });

    test('copyWith 可以修改多个值', () {
      const original = MetronomeSettings(
        bpm: 120,
        beatsPerMeasure: 4,
        beatUnit: 4,
      );

      final modified = original.copyWith(
        bpm: 90,
        beatsPerMeasure: 3,
        beatUnit: 8,
      );

      expect(modified.bpm, 90);
      expect(modified.beatsPerMeasure, 3);
      expect(modified.beatUnit, 8);
    });
  });
}