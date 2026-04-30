import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:metronome/providers/metronome_provider.dart';
import 'package:metronome/screens/home_screen.dart';
import 'package:metronome/theme/app_colors.dart';

// Mock MethodChannel for audioplayers
void setupMockAudioPlayers() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final binding = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // Mock multiple audioplayers channels
  for (final channel in [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers',
  ]) {
    binding.setMockMethodCallHandler(
      MethodChannel(channel),
      (MethodCall methodCall) async {
        return null;
      },
    );
  }
}

void main() {
  setupMockAudioPlayers();

  group('HomeScreen Widget Tests', () {
    late MetronomeProvider provider;

    setUp(() {
      provider = MetronomeProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: [AppColors.dark],
        ),
        home: ChangeNotifierProvider<MetronomeProvider>.value(
          value: provider,
          child: const HomeScreen(),
        ),
      );
    }

    testWidgets('显示正确的标题', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('METRONOME'), findsOneWidget);
    });

    testWidgets('显示 BPM 标签', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('BPM'), findsOneWidget);
    });

    testWidgets('显示节拍标签', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // "节拍" 出现多次：BeatIndicator 和 BeatTypeSelector 都有
      expect(find.text('节拍'), findsWidgets);
    });

    testWidgets('默认显示 BPM 120', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // "120" 出现两次：一个是大 BPM 显示，一个是快速按钮选中状态
      expect(find.text('120'), findsWidgets);
    });

    testWidgets('显示播放按钮（play_arrow 图标）', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('点击播放按钮后显示暂停图标', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 初始状态显示播放图标
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);

      // 直接调用 provider 方法（异步）
      await provider.togglePlayPause();
      await tester.pump();

      // 验证播放状态切换
      expect(provider.isPlaying, true);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      // 停止播放以清理定时器
      provider.stop();
      await tester.pump();
    });

    testWidgets('再次点击暂停按钮恢复播放图标', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 开始播放
      await provider.togglePlayPause();
      await tester.pump();

      // 验证播放中
      expect(provider.isPlaying, true);

      // 停止播放
      provider.stop();
      await tester.pump();

      // 验证停止状态
      expect(provider.isPlaying, false);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('显示快速 BPM 按钮', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 快速 BPM 按钮包含这些文本（可能与主 BPM 显示重复）
      // 验证至少存在这些快速选项
      expect(find.text('60'), findsWidgets);
      expect(find.text('90'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('点击快速 BPM 按钮更新 BPM', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 将 BPM 改为 90（避免与默认 120 重复）
      await tester.tap(find.text('90'));
      await tester.pump();

      expect(provider.bpm, 90);
    });

    testWidgets('BPM 滑块存在且范围正确', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // 获取 Slider widget
      final sliderWidget = tester.widget<Slider>(slider);
      expect(sliderWidget.min, 40);
      expect(sliderWidget.max, 240);
    });

    testWidgets('节拍类型选择器显示 4/4', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 节拍类型选择器区域包含 / 分隔符
      expect(find.text('/'), findsOneWidget);
    });
  });
}