import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/metronome_provider.dart';
import 'screens/home_screen.dart';
import 'utils/notification_service.dart';
import 'utils/update_service.dart';
import 'widgets/update_dialog.dart';

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

  // 6. 启动 App（初始化由 MetronomeProvider 统一管理，避免多重初始化竞态）
  runApp(const MetronomeApp());
}

class MetronomeApp extends StatefulWidget {
  const MetronomeApp({super.key});

  @override
  State<MetronomeApp> createState() => _MetronomeAppState();
}

class _MetronomeAppState extends State<MetronomeApp> with WidgetsBindingObserver {
  bool _showHome = true;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 延迟到第一帧渲染后再检查更新，确保 MaterialApp 已完全初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdateOnStartup();
    });
  }

  Future<void> _checkUpdateOnStartup() async {
    if (kIsWeb) return;
    // 等待足够长时间确保 widget 树完全构建
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    // 使用 try-catch 包装，任何异常都不传播
    try {
      final result = await UpdateService().checkUpdate();
      if (!mounted) return;
      if (result case UpdateAvailable(:final release)) {
        // 注意：这里不能用 MetronomeApp 的 context（它在 MaterialApp 之上），否则会缺 MaterialLocalizations
        final dialogContext = _navigatorKey.currentContext;
        if (dialogContext != null && dialogContext.mounted) {
          await showUpdateDialog(dialogContext, release);
        }
      } else if (result case UpToDate(:final currentVersion)) {
        //已是最新版本，不打扰用户，静默
      } else if (result case UpdateCheckFailed()) {
        final ctx = _navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('检查新版本失败'),
              backgroundColor: Color(0xFF1A1A1A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // 强制卸载整个 HomeScreen 树，断开旧 Provider 的引用
      if (_showHome) {
        setState(() => _showHome = false);
      }
    } else if (state == AppLifecycleState.resumed) {
      // 重新挂载，UniqueKey() 强制创建全新的 Provider 实例
      if (!_showHome) {
        setState(() => _showHome = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
      home: _showHome
          ? ChangeNotifierProvider(
              key: UniqueKey(), // 每次进入强制生成全新实例，旧的必须滚蛋
              create: (_) => MetronomeProvider()..init(),
              child: const HomeScreen(),
            )
          : const Scaffold(backgroundColor: Color(0xFF0D0D0D)),
    );
  }
}
