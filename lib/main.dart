import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/metronome_provider.dart';
import 'screens/home_screen.dart';
import 'utils/audio_service.dart';
import 'utils/notification_service.dart';

Future<void> main() async {
  // 1. 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 设置音频会话（同步设置，无需等待）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D0D),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // 4. 初始化通知服务
  await NotificationService.init();

  // 5. 桌面端：配置窗口初始化（防止闪烁）
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      backgroundColor: Color(0xFF0D0D0D), // 统一背景色
      titleBarStyle: TitleBarStyle.normal, // 显示标题栏（包含最小化/最大化/关闭按钮）
      size: Size(400, 800),
      center: true,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 6. 音频引擎预热（与 UI 渲染并行）
  // 使用单例，确保与 MetronomeProvider 使用同一实例
  final audioFuture = () async {
    await AudioService.instance.init();
    await AudioService.instance.preload();
    // 静默播放一次进行硬件握手
    AudioService.instance.playClick(false);
  }();

  // 7. 启动 App（音频初始化并行执行）
  runApp(const MetronomeApp());

  // 8. 等待音频初始化完成
  await audioFuture;
}

class MetronomeApp extends StatefulWidget {
  const MetronomeApp({super.key});

  @override
  State<MetronomeApp> createState() => _MetronomeAppState();
}

class _MetronomeAppState extends State<MetronomeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 安卓滑动退出后重新打开时，音频引擎可能处于无效状态
      // 强制重新初始化以恢复音频功能
      debugPrint('[MetronomeApp] App resumed, reinitializing audio engine...');
      AudioService.instance.init().then((_) {
        debugPrint('[MetronomeApp] Audio engine reinitialized');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MetronomeProvider()..init(),
      child: MaterialApp(
        title: 'Metronome',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
