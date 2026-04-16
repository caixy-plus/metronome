import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/metronome_settings.dart';
import '../models/sound_type.dart';
import '../utils/audio_service.dart';
import '../utils/dynamic_island_service.dart';
import '../utils/notification_service.dart';

/// 合法分母：乐理标准值
const List<int> validBeatUnits = [1, 2, 4, 8, 16];

/// Preference keys for persistent storage
const String _prefKeyBpm = 'metronome_bpm';
const String _prefKeyBeatsPerMeasure = 'metronome_beats_per_measure';
const String _prefKeyBeatUnit = 'metronome_beat_unit';
const String _prefKeySoundType = 'metronome_sound_type';

/// 节拍器状态提供者 - 高精度版本
class MetronomeProvider extends ChangeNotifier {
  MetronomeSettings _settings = const MetronomeSettings();
  bool _isPlaying = false;
  int _currentBeat = 0;
  int _currentPlayingBeat = -1;
  SoundType _soundType = SoundType.mechanical;

  Timer? _timer;
  int _timerSeq = 0; // 计时器序列号，用于检测过期回调
  final AudioServiceInterface _audioService;
  final Stopwatch _stopwatch = Stopwatch();

  // 长按连续调节
  Timer? _bpmAdjustTimer;
  int _bpmAdjustDirection = 0;

  // BPM 调节防抖
  Timer? _bpmDebounceTimer;
  int _bpmDebounceSeq = 0;

  /// 记录播放历史的列表，用于测试验证
  final List<bool> _playedAccents = [];

  /// Tap Tempo: 最近 4 次点击的时间戳队列
  final List<int> _tapTimestamps = [];
  static const int _maxTapCount = 4;
  static const int _tapTimeoutMs = 2000; // 超过 2 秒重置

  /// 静音模式 - 只显示视觉节拍，不播放声音
  bool _isSilentMode = false;
  bool get isSilentMode => _isSilentMode;
  set isSilentMode(bool value) {
    if (_isSilentMode != value) {
      _isSilentMode = value;
      notifyListeners();
    }
  }

  /// 获取播放历史（测试用）
  List<bool> get playedAccents => List.unmodifiable(_playedAccents);

  MetronomeProvider({AudioServiceInterface? audioService})
      : _audioService = audioService ?? AudioService.instance;

  /// 记录上一拍的实际触发时间（微秒），用于 BPM 切换时精确计算下一拍时间
  /// 当 BPM 改变时，下一拍时间 = _lastTickTimeUs + 新 intervalUs
  int _lastTickTimeUs = 0;

  MetronomeSettings get settings => _settings;
  bool get isPlaying => _isPlaying;
  int get currentBeat => _currentBeat;
  int get currentPlayingBeat => _currentPlayingBeat;
  SoundType get soundType => _soundType;
  set soundType(SoundType type) {
    if (_soundType == type) return;
    _soundType = type;
    _saveSettings();

    // 如果 audioService 是 AudioService 实例，切换音效
    final audioService = _audioService;
    if (audioService is AudioService) {
      // 等待音效加载完成后再预览
      audioService.setSoundType(type).then((_) {
        audioService.playPreview();
      });
    }
    notifyListeners();
  }

  /// BPM getter/setter
  int get bpm => _settings.bpm;
  set bpm(int value) {
    if (value < 40) value = 40;
    if (value > 240) value = 240;
    if (value == _settings.bpm) return; // 没变化不处理

    _settings = _settings.copyWith(bpm: value);
    notifyListeners();
    _saveSettings(); // 持久化保存

    // 如果正在播放，使用防抖重启定时器
    if (_isPlaying) {
      _scheduleBpmRestart();
    }
  }

  /// 防抖调度 BPM 变更（50ms 内的多次变更只执行一次重启）
  void _scheduleBpmRestart() {
    _bpmDebounceTimer?.cancel();
    final int seq = ++_bpmDebounceSeq;
    _bpmDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      // 序列号检查：防止过期回调干扰
      if (seq != _bpmDebounceSeq) return;
      _restartTimer();
      _bpmDebounceTimer = null;
    });
  }

  /// 分子 getter/setter
  int get beatsPerMeasure => _settings.beatsPerMeasure;
  set beatsPerMeasure(int value) {
    if (value < 1) value = 1;
    if (value > 16) value = 16;
    if (value == _settings.beatsPerMeasure) return; // 没变化不处理

    // 相位保护：如果当前拍位置已经超过新设置的总拍数，
    // 必须立即将当前拍重置为 0，防止越界崩溃
    if (_currentBeat >= value) {
      _currentBeat = 0;
    }

    _settings = _settings.copyWith(beatsPerMeasure: value);
    notifyListeners();
    _saveSettings(); // 持久化保存

    // 如果正在播放，重启定时器以应用新节拍间隔
    if (_isPlaying) {
      _restartTimer();
    }
  }

  /// 分母 getter/setter - 只允许乐理标准值
  int get beatUnit => _settings.beatUnit;
  set beatUnit(int value) {
    // 分母必须是乐理标准值
    if (!validBeatUnits.contains(value)) {
      value = 4; // 默认设为四分音符
    }
    if (value == _settings.beatUnit) return; // 没变化不处理

    _settings = _settings.copyWith(beatUnit: value);
    notifyListeners();
    _saveSettings(); // 持久化保存

    // 如果正在播放，重启计时器以应用新节拍间隔
    if (_isPlaying) {
      _restartTimer();
    }
  }

  /// 计算单次节拍所需的微秒数
  /// BPM 是绝对物理时间基准，与拍号分母无关
  /// 例如：BPM=120 时，无论拍号是 4/4、4/8 还是 4/2，每拍物理间隔都是 500ms
  int get _tickIntervalUs {
    if (bpm <= 0) return 500000;
    // 公式: 60 * 1000000 / BPM（微秒）
    // 拍号分母（beatUnit）仅影响音符时值表示，不影响物理时间
    return (60 * 1000000 / bpm).round();
  }

  /// 初始化音频服务
  Future<void> init() async {
    await _audioService.init();
    await _loadSettings();
  }

  /// Web 平台音频解锁初始化
  /// 必须在用户交互事件中调用，以解锁浏览器自动播放限制
  Future<void> initAudioForWeb() async {
    debugPrint('[MetronomeProvider] Web 音频解锁中...');
    await _audioService.init();
    // Web 平台初始化后，预加载所有音效以确保后续播放流畅
    for (final type in SoundType.values) {
      await _audioService.setSoundType(type);
    }
    debugPrint('[MetronomeProvider] Web 音频解锁完成');
  }

  /// 从持久化存储加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBpm = prefs.getInt(_prefKeyBpm);
      final savedBeatsPerMeasure = prefs.getInt(_prefKeyBeatsPerMeasure);
      final savedBeatUnit = prefs.getInt(_prefKeyBeatUnit);
      final savedSoundTypeIndex = prefs.getInt(_prefKeySoundType);

      // 如果有保存的值，就应用它们
      if (savedBpm != null ||
          savedBeatsPerMeasure != null ||
          savedBeatUnit != null) {
        _settings = MetronomeSettings(
          bpm: savedBpm ?? _settings.bpm,
          beatsPerMeasure: savedBeatsPerMeasure ?? _settings.beatsPerMeasure,
          beatUnit: savedBeatUnit ?? _settings.beatUnit,
        );
      }

      // 加载音效类型
      if (savedSoundTypeIndex != null &&
          savedSoundTypeIndex >= 0 &&
          savedSoundTypeIndex < SoundType.values.length) {
        _soundType = SoundType.values[savedSoundTypeIndex];
        // 切换到对应的音效
        final audioService = _audioService;
        if (audioService is AudioService) {
          audioService.setSoundType(_soundType);
        }
      }

      notifyListeners();
    } catch (e) {
      // 如果读取失败，使用默认设置
      debugPrint('Failed to load settings: $e');
    }
  }

  /// 保存设置到持久化存储
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyBpm, _settings.bpm);
      await prefs.setInt(_prefKeyBeatsPerMeasure, _settings.beatsPerMeasure);
      await prefs.setInt(_prefKeyBeatUnit, _settings.beatUnit);
      await prefs.setInt(_prefKeySoundType, _soundType.index);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  /// 切换播放/暂停
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      stop();
    } else {
      await start();
    }
  }

  /// 开始播放
  Future<void> start() async {
    if (_isPlaying) return;

    // 确保硬件就绪
    await _audioService.init();

    _isPlaying = true;
    _currentBeat = 0;
    _stopwatch.reset();
    _stopwatch.start();

    // 启动 Dynamic Island Live Activity
    DynamicIslandService.startLiveActivity(
      bpm: bpm,
      beatsPerMeasure: beatsPerMeasure,
    );

    // 显示后台通知
    NotificationService.showPlayingNotification(
      bpm: bpm,
      currentBeat: 0,
      beatsPerMeasure: beatsPerMeasure,
    );

    // 物理第一声：立即触发
    _executeTick();

    // 启动动态修正计时器
    _scheduleNextTick();
    notifyListeners();
  }

  void _scheduleNextTick() {
    if (!_isPlaying) return;

    // 取消旧计时器，防止多重调度
    _timer?.cancel();

    // 计算下一拍应该发生的绝对时间点
    // 关键：使用 _lastTickTimeUs（上一拍绝对时间）+ 新 intervalUs
    // 而不是 _currentBeat * intervalUs（会因 BPM 切换导致间隔累积误差）
    final int nextTargetUs = _lastTickTimeUs + _tickIntervalUs;
    final int nowUs = _stopwatch.elapsedMicroseconds;
    int delayUs = nextTargetUs - nowUs;

    // 生成新的序列号，使旧回调失效
    final int seq = ++_timerSeq;

    if (delayUs <= 0) {
      // 已经滞后了：计算需要跳过多少个完整周期
      // 跳过周期后，delayUs 变为正数（下一个合理的目标时间）
      final int missedBeats = (-delayUs / _tickIntervalUs).ceil() + 1;
      delayUs = delayUs + missedBeats * _tickIntervalUs;
      // 再次检查，确保 delayUs 为正
      if (delayUs <= 0) {
        delayUs = _tickIntervalUs;
      }
    }

    _timer = Timer(Duration(microseconds: delayUs), () => _onTick(seq));
  }

  /// 执行的回调，使用序列号检测是否为过期回调
  void _onTick(int seq) {
    // 序列号不匹配说明是过期回调（如 stop() 后被调度的定时器）
    if (seq != _timerSeq || !_isPlaying) return;

    _executeTick();
    _scheduleNextTick();
  }

  void _executeTick() {
    // 记录本拍触发时的绝对时间，用于精确计算 BPM 切换后的下一拍时间
    _lastTickTimeUs = _stopwatch.elapsedMicroseconds;

    // 判断当前小节位置
    final bool isAccent = (_currentBeat % beatsPerMeasure) == 0;

    // 更新 UI 状态（视觉先于听觉，人脑对声音有微小延迟）
    _currentPlayingBeat = _currentBeat % beatsPerMeasure;

    // 记录播放历史
    _playedAccents.add(isAccent);

    // 更新 Dynamic Island Live Activity
    DynamicIslandService.updateLiveActivity(
      currentBeat: _currentPlayingBeat,
      beatsPerMeasure: beatsPerMeasure,
      isPlaying: true,
    );

    // 更新后台通知
    NotificationService.updatePlayingNotification(
      bpm: bpm,
      currentBeat: _currentPlayingBeat,
      beatsPerMeasure: beatsPerMeasure,
    );

    // 移动到下一拍
    _currentBeat++;

    // 通知 UI 更新（提前触发，视觉先行）
    notifyListeners();

    // 最后播放声音（听觉同步）
    if (!_isSilentMode) {
      _audioService.playClick(isAccent);
    }
  }

  /// 停止播放
  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _timerSeq++; // 使任何待处理的回调失效
    _bpmDebounceTimer?.cancel();
    _bpmDebounceTimer = null;
    _stopwatch.stop();
    _currentBeat = 0;
    _lastTickTimeUs = 0; // 重置上一拍时间
    _currentPlayingBeat = -1;
    _playedAccents.clear(); // 停止时清空历史

    // 结束 Dynamic Island Live Activity
    DynamicIslandService.endLiveActivity();

    // 取消后台通知
    NotificationService.cancelNotification();

    notifyListeners();
  }

  /// 原子化重启计时器
  /// 先销毁旧计时器，再重置状态，最后启动新计时器
  void _restartTimer() {
    if (!_isPlaying) return;

    // 1. 立即销毁旧计时器，防止新旧重叠
    _timer?.cancel();
    _timerSeq++; // 使旧回调失效

    // 2. 不要重置 Stopwatch！让它继续运行
    //    _scheduleNextTick 会根据当前流逝时间 + 新 BPM 自动找准下一拍位置
    // 3. 启动新计时器
    _scheduleNextTick();
  }

  /// 开始长按连续调节 BPM
  void startBpmAdjust(int direction) {
    _bpmAdjustDirection = direction;
    _bpmAdjustTimer?.cancel();
    // 先立即调节一次并重启计时器（立即响应）
    _adjustBpm(immediate: true);
    // 然后每 100ms 连续调节
    _bpmAdjustTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _adjustBpm(immediate: true),
    );
  }

  /// 调节 BPM（长按模式）
  /// [immediate] 为 true 时立即重启计时器，为 false 时使用防抖
  void _adjustBpm({bool immediate = false}) {
    final newBpm = (_settings.bpm + _bpmAdjustDirection).clamp(40, 240);
    if (newBpm != _settings.bpm) {
      _settings = _settings.copyWith(bpm: newBpm);
      notifyListeners();
      if (_isPlaying) {
        if (immediate) {
          _restartTimer();
        } else {
          _scheduleBpmRestart();
        }
      }
    }
  }

  /// 停止长按连续调节
  void stopBpmAdjust() {
    _bpmAdjustTimer?.cancel();
    _bpmAdjustTimer = null;
    // 长按结束后，如果之后有 slider 变化会通过 _scheduleBpmRestart 处理
    // 这里不需要额外处理
  }

  /// Tap Tempo: 记录一次点击，计算平均间隔并更新 BPM
  void tap() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 如果距离上次点击超过 2 秒，重置队列
    if (_tapTimestamps.isNotEmpty && now - _tapTimestamps.last > _tapTimeoutMs) {
      _tapTimestamps.clear();
    }

    _tapTimestamps.add(now);

    // 保持最近 4 次点击
    if (_tapTimestamps.length > _maxTapCount) {
      _tapTimestamps.removeAt(0);
    }

    // 至少需要 2 次点击才能计算 BPM
    if (_tapTimestamps.length >= 2) {
      int totalInterval = 0;
      for (int i = 1; i < _tapTimestamps.length; i++) {
        totalInterval += _tapTimestamps[i] - _tapTimestamps[i - 1];
      }
      final avgIntervalMs = totalInterval / (_tapTimestamps.length - 1);

      // 将平均间隔转换为 BPM: bpm = 60000 / avgIntervalMs
      final calculatedBpm = (60000 / avgIntervalMs).round().clamp(40, 240);

      if (calculatedBpm != _settings.bpm) {
        _settings = _settings.copyWith(bpm: calculatedBpm);
        notifyListeners();
        _saveSettings();

        if (_isPlaying) {
          _scheduleBpmRestart();
        }
      }
    }
  }

  /// 重置 Tap Tempo 队列
  void resetTap() {
    _tapTimestamps.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bpmAdjustTimer?.cancel();
    _bpmDebounceTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}