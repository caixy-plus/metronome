// 音频服务入口 - 条件导出实现跨平台支持
//
// 根据编译目标平台，选择正确的音频服务实现：
// - Native 平台 (iOS/Android/macOS/Windows/Linux): 使用 flutter_soloud
// - Web 平台: 使用 HTML5 Audio API
//
// 使用方式:
// import 'audio_service.dart';  // 会自动选择正确的实现

export 'audio_service_interface.dart';
export 'audio_service_native.dart'
    if (dart.library.html) 'audio_service_web.dart';
