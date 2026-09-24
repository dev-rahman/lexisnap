import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/services/speech/text_to_speech_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/flashcard.dart';

/// A four-option recognition prompt, used for cards the learner is still
/// learning.
///
/// One tap answers it and the tap itself is the grade, so there's no
/// self-assessment step at all. The distractors come from the same deck,
/// which costs nothing to author and keeps the choice about the word
/// rather than about which option looks out of place.
class ChoiceRound extends StatefulWidget {
  const ChoiceRound({
    super.key,
    required this.card,
    required this.options,
    required this.answerIndex,
    required this.sourceLanguage,
    required this.onAnswer,
  });

  final Flashcard card;
  final List<String> options;
  final int answerIndex;
  final String? sourceLanguage;

  /// Fired once the result has been shown long enough to read. The
  /// reported duration is measured to the tap itself, not to this
  /// callback, so the hold delay never inflates the inferred grade.
  final void Function(bool correct, Duration timeToAnswer) onAnswer;

  @override
  State<ChoiceRound> createState() => _ChoiceRoundState();
}

class _ChoiceRoundState extends State<ChoiceRound> {
  /// A correct answer only needs long enough to register as a win; a wrong
  /// one has to stay up long enough to read the right answer off it.
  static const _correctHold = Duration(milliseconds: 620);
  static const _wrongHold = Duration(milliseconds: 1600);

  final _shownAt = DateTime.now();

  int? _selectedIndex;
  Timer? _advanceTimer;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _select(int index) {
    if (_selectedIndex != null) return;

    final isCorrect = index == widget.answerIndex;
    final timeToAnswer = DateTime.now().difference(_shownAt);
    setState(() => _selectedIndex = index);

    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    _advanceTimer = Timer(
      isCorrect ? _correctHold : _wrongHold,
      () => widget.onAnswer(isCorrect, timeToAnswer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The prompt hugs its content and floats centred rather than
        // stretching: a word marooned in a screen-tall card reads as an
        // empty screen, and it pushes the options out of thumb reach.
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(child: _buildPrompt(context)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < widget.options.length; index++) ...[
          _OptionTile(
            label: widget.options[index],
            state: _stateFor(index),
            onTap: () => _select(index),
          ),
          if (index != widget.options.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  _OptionState _stateFor(int index) {
    if (_selectedIndex == null) return _OptionState.idle;
    if (index == widget.answerIndex) return _OptionState.correct;
    if (index == _selectedIndex) return _OptionState.wrong;
    return _OptionState.dimmed;
  }

  Widget _buildPrompt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.studyChoicePrompt.tr,
            style: AppTextStyles.caption.copyWith(color: context.colorInkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.card.word,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 34,
              color: context.colorInk,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            color: AppColors.accent,
            onPressed: () => Get.find<TextToSpeechService>().speak(
              widget.card.word,
              languageCode: widget.sourceLanguage,
            ),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (state) {
      _OptionState.idle => (
        context.colorSurface,
        context.colorInk,
        context.colorBorder,
      ),
      _OptionState.correct => (
        AppColors.success.withValues(alpha: 0.16),
        AppColors.success,
        AppColors.success,
      ),
      _OptionState.wrong => (
        AppColors.error.withValues(alpha: 0.16),
        AppColors.error,
        AppColors.error,
      ),
      _OptionState.dimmed => (
        context.colorSurface.withValues(alpha: 0.5),
        context.colorInkMuted,
        Colors.transparent,
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: state == _OptionState.idle ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                if (state == _OptionState.correct)
                  const Icon(Icons.check_rounded, color: AppColors.success),
                if (state == _OptionState.wrong)
                  const Icon(Icons.close_rounded, color: AppColors.error),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
