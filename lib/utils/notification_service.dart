import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 通知服务 - 后台播放时显示节拍状态
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'metronome_playback';
  static const String _channelName = 'Metronome Playback';
  static const int _notificationId = 1;

  /// 初始化通知服务
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    const DarwinInitializationSettings macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macOSSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // 创建通知渠道（Android）
    await _createNotificationChannel();

    // 请求通知权限
    await _requestPermissions();
  }

  /// 请求通知权限
  static Future<void> _requestPermissions() async {
    // Android 13+ 需要请求 POST_NOTIFICATIONS 权限
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS 请求权限
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: false,
        );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // 点击通知的回调（目前不处理）
  }

  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '节拍器播放状态通知',
      importance: Importance.low, // 低优先级，不打扰用户
      playSound: false,
      enableVibration: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 显示播放通知
  static Future<void> showPlayingNotification({
    required int bpm,
    required int currentBeat,
    required int beatsPerMeasure,
  }) async {
    final beatText = '${currentBeat + 1}/$beatsPerMeasure';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '节拍器播放状态通知',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // 持续通知，不能被滑动删除
      autoCancel: false,
      showWhen: false,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
      styleInformation: const BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _notificationId,
      '🎵 节拍器 $bpm BPM',
      '第 $beatText 拍',
      details,
    );
  }

  /// 更新通知（播放时每拍更新）
  static Future<void> updatePlayingNotification({
    required int bpm,
    required int currentBeat,
    required int beatsPerMeasure,
  }) async {
    await showPlayingNotification(
      bpm: bpm,
      currentBeat: currentBeat,
      beatsPerMeasure: beatsPerMeasure,
    );
  }

  /// 取消通知
  static Future<void> cancelNotification() async {
    await _notifications.cancel(_notificationId);
  }
}
