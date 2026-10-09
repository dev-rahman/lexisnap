import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/speech/text_to_speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/flashcard.dart';

/// Hands-free playback of a deck: word, pause, translation, pause, next.
///
/// This is the zero-effort end of the app - something to run while
/// walking or washing up, where any interaction at all would be too much.
/// Nothing here is graded and no schedule is touched: auto-grading cards
/// the learner never actually answered would quietly corrupt the spacing
/// that the review sessions depend on.
class ListenSessionView extends StatefulWidget {
  const ListenSessionView({super.key, required this.flashcards});

  final List<Flashcard> flashcards;

  @override
  State<ListenSessionView> createState() => _ListenSessionViewState();
}

class _ListenSessionViewState extends State<ListenSessionView> {
  /// Long enough to try to recall the word before the answer arrives.
  static const _recallGap = Duration(milliseconds: 1600);
  static const _betweenCardsGap = Duration(milliseconds: 900);

  /// Guards against a TTS engine that never reports completion, which
  /// would otherwise strand the playback loop forever.
  static const _utteranceTimeout = Duration(seconds: 15);

  TextToSpeechService get _tts => Get.find<TextToSpeechService>();

  int _index = 0;
  bool _isPlaying = false;
  bool _showTranslation = false;

  /// Incremented whenever playback is interrupted, so a loop started by an
  /// earlier tap can tell it has been superseded and bail out.
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame: the playback loop calls setState
    // on its very first pass, which isn't legal during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play();
    });
  }

  @override
  void dispose() {
    _runId++;
    _tts.stop();
    super.dispose();
  }

  bool _isStale(int runId) => !mounted || runId != _runId || !_isPlaying;

  void _play() {
    setState(() => _isPlaying = true);
    _runLoop(++_runId);
  }

  void _pause() {
    _runId++;
    setState(() => _isPlaying = false);
    _tts.stop();
  }

  void _jumpTo(int index) {
    _runId++;
    _tts.stop();
    setState(() {
      _index = index.clamp(0, widget.flashcards.length - 1);
      _showTranslation = false;
    });
    if (_isPlaying) _runLoop(++_runId);
  }

  Future<void> _speak(String text, String? languageCode) => _tts
      .speak(text, languageCode: languageCode)
      .timeout(_utteranceTimeout, onTimeout: () {});

  Future<void> _runLoop(int runId) async {
    while (!_isStale(runId)) {
      final card = widget.flashcards[_index];

      setState(() => _showTranslation = false);
      await _speak(card.word, card.sourceLanguage);
      if (_isStale(runId)) return;

      await Future.delayed(_recallGap);
      if (_isStale(runId)) return;

      setState(() => _showTranslation = true);
      await _speak(card.translation, card.targetLanguage);
      if (_isStale(runId)) return;

      await Future.delayed(_betweenCardsGap);
      if (_isStale(runId)) return;

      if (_index + 1 >= widget.flashcards.length) {
        setState(() => _isPlaying = false);
        return;
      }
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.flashcards[_index];
    final isLast = _index == widget.flashcards.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: Get.back,
        ),
        title: Text(LocaleKeys.listenTitle.tr, style: AppTextStyles.bodyMedium),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                LocaleKeys.listenHint.tr,
                style: AppTextStyles.caption.copyWith(
                  color: context.colorInkMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.colorSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.colorBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.word,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 36,
                          color: context.colorInk,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 260),
                        opacity: _showTranslation ? 1 : 0,
                        child: Text(
                          card.translation,
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.accent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_isPlaying && isLast)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    LocaleKeys.listenFinished.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: context.colorInkMuted,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: context.colorInk,
                    onPressed: _index == 0 ? null : () => _jumpTo(_index - 1),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton.filled(
                    iconSize: 40,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppSpacing.md),
                    ),
                    onPressed: () {
                      if (_isPlaying) {
                        _pause();
                      } else {
                        if (isLast) _jumpTo(0);
                        _play();
                      }
                    },
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: context.colorInk,
                    onPressed: isLast ? null : () => _jumpTo(_index + 1),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                LocaleKeys.studyProgress.trParams({
                  'current': '${_index + 1}',
                  'total': '${widget.flashcards.length}',
                }),
                style: AppTextStyles.caption.copyWith(
                  color: context.colorInkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
