import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../utils/app_theme.dart';

/// Player de áudio autônomo com barra de progresso e controle play/pause.
/// Extraído do detail_screen.dart para ter seu próprio ciclo de vida isolado.
class SumaAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String title;

  const SumaAudioPlayer({super.key, required this.audioUrl, required this.title});

  @override
  State<SumaAudioPlayer> createState() => _SumaAudioPlayerState();
}

class _SumaAudioPlayerState extends State<SumaAudioPlayer> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  ProcessingState _processingState = ProcessingState.idle;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() { isPlaying = state.playing; _processingState = state.processingState; });
    });
    _audioPlayer.durationStream.listen((d) {
      if (mounted) setState(() => duration = d ?? Duration.zero);
    });
    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => position = p);
    });
    try {
      _audioPlayer.setAudioSource(LockCachingAudioSource(
        Uri.parse(widget.audioUrl),
        tag: MediaItem(id: widget.audioUrl, album: 'Sumaúma', title: widget.title),
      ));
    } catch (e) {
      debugPrint('Erro ao precarregar áudio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _seekTo(double value) {
    if (duration != Duration.zero) _audioPlayer.seek(Duration(milliseconds: value.toInt()));
  }

  String _fmt(Duration d) {
    if (d.inMilliseconds <= 0) return '00:00';
    return '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : SumaColors.greenLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (isPlaying) { setState(() => isPlaying = false); _audioPlayer.pause(); }
              else { setState(() => isPlaying = true); _audioPlayer.play(); }
            },
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: SumaColors.greenBright, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: SumaColors.greenBright.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: _processingState == ProcessingState.loading || _processingState == ProcessingState.buffering
                  ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2, color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Row(children: [
                  Text(_fmt(position), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: SumaColors.greenBright,
                        inactiveTrackColor: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
                        thumbColor: SumaColors.greenBright,
                      ),
                      child: Slider(
                        min: 0,
                        max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
                        value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1),
                        onChanged: _seekTo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_fmt(duration), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
