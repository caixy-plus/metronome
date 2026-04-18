import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/metronome_provider.dart';
import '../widgets/bpm_dial.dart';
import '../widgets/beat_type_selector.dart';
import '../widgets/beat_indicator.dart';
import 'home_screen/web_unlock_screen.dart';
import 'home_screen/play_button.dart';
import 'home_screen/help_dialog.dart';
import 'home_screen/settings_bottom_sheet.dart';

/// 节拍器主页面 - Cyber-Noir 设计
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _webAudioUnlocked = false;

  Future<void> _unlockWebAudio(BuildContext context) async {
    if (!kIsWeb) {
      setState(() => _webAudioUnlocked = true);
      return;
    }
    final provider = context.read<MetronomeProvider>();
    await provider.initAudioForWeb();
    setState(() => _webAudioUnlocked = true);
    if (context.mounted) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && !_webAudioUnlocked) {
      return WebUnlockScreen(onUnlock: () => _unlockWebAudio(context));
    }
    return const _MetronomeHome();
  }
}

class _MetronomeHome extends StatelessWidget {
  const _MetronomeHome();

  void _showHelpDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const HelpDialog());
  }

  void _showSettingsSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SettingsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF00F0FF)),
          onPressed: () => _showSettingsSheet(context),
        ),
        title: const Text(
          'METRONOME',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontWeight: FontWeight.w300,
            letterSpacing: 8,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF00F0FF)),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            final height = isDesktop
                ? constraints.maxHeight.clamp(500.0, 700.0)
                : constraints.maxHeight;

            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: CyberNoirBackgroundPainter()),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        BeatIndicator(),
                        SizedBox(height: 8),
                        BeatTypeSelector(),
                        SizedBox(height: 4),
                        BpmDial(),
                        PlayButton(),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
