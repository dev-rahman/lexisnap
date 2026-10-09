import 'dart:math';
import 'dart:ui' show lerpDouble;

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

/// A free-recall prompt: tap the card to flip it, then swipe right if you
/// knew it or left if you didn't.
///
/// Swiping replaces Anki's four grade buttons. The learner answers the
/// only question they can answer honestly - did you know it? - with a
/// gesture rather than a precise tap, and the session infers the actual
/// SM-2 grade from how long the flip took. The two buttons underneath do
/// the same thing, because a gesture nobody discovers is not an interface.
class SwipeFlashcard extends StatefulWidget {
  const SwipeFlashcard({super.key, required this.card, required this.onAnswer});

  final Flashcard card;

  /// Reports whether the word was recalled, and how long it took to get
  /// there - measured to the moment the card was flipped, which is when
  /// the learner actually committed. The session turns the pair into an
  /// SM-2 grade.
  final void Function(bool recalled, Duration timeToAnswer) onAnswer;

  @override
  State<SwipeFlashcard> createState() => _SwipeFlashcardState();
}

class _SwipeFlashcardState extends State<SwipeFlashcard>
    with TickerProviderStateMixin {
  /// Drag distance past which releasing commits an answer.
  static const _commitDistance = 96.0;
  static const _commitVelocity = 650.0;

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );

  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..addListener(_onSettleTick);

  final _shownAt = DateTime.now();

  double _dragX = 0;
  double _settleFrom = 0;
  double _settleTo = 0;
  bool _revealed = false;
  bool _answered = false;
  Duration _timeToReveal = Duration.zero;

  @override
  void dispose() {
    _flip.dispose();
    _settle.dispose();
    super.dispose();
  }

  void _onSettleTick() {
    setState(() {
      _dragX = lerpDouble(
        _settleFrom,
        _settleTo,
        Curves.easeOut.transform(_settle.value),
      )!;
    });
  }

  double get _commitProgress =>
      (_dragX.abs() / _commitDistance).clamp(0.0, 1.0);

  void _reveal() {
    if (_revealed) return;
    _timeToReveal = DateTime.now().difference(_shownAt);
    setState(() => _revealed = true);
    _flip.forward();
    HapticFeedback.selectionClick();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_revealed || _answered) return;
    setState(() => _dragX += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_revealed || _answered) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final committed =
        _dragX.abs() > _commitDistance || velocity.abs() > _commitVelocity;

    if (!committed) {
      _animateTo(0);
      return;
    }

    final recalled = (_dragX.abs() > 4 ? _dragX : velocity) > 0;
    _commit(recalled);
  }

  /// Flings the card away and reports the answer. Also drives the two
  /// buttons, so tapping and swiping look identical.
  void _commit(bool recalled) {
    if (_answered) return;
    _answered = true;

    HapticFeedback.mediumImpact();
    final offscreen = MediaQuery.sizeOf(context).width * 1.3;
    _animateTo(
      recalled ? offscreen : -offscreen,
      then: () => widget.onAnswer(recalled, _timeToReveal),
    );
  }

  void _animateTo(double target, {VoidCallback? then}) {
    _settleFrom = _dragX;
    _settleTo = target;
    _settle.forward(from: 0).whenComplete(() => then?.call());
  }

  void _speak(String text, String? languageCode) =>
      Get.find<TextToSpeechService>().speak(text, languageCode: languageCode);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _reveal,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Transform.translate(
              offset: Offset(_dragX, _commitProgress * 8),
              child: Transform.rotate(
                angle: _dragX / 2200,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildFace(context)),
                    if (_revealed) ..._buildStamps(),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _AnswerControls(
          enabled: _revealed && !_answered,
          commitProgress: _dragX == 0 ? 0 : _commitProgress,
          leaningRecalled: _dragX > 0,
          onAnswer: _commit,
        ),
      ],
    );
  }

  Widget _buildFace(BuildContext context) {
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final angle = _flip.value * pi;
        final showingBack = angle > pi / 2;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: showingBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _backFace(context),
                )
              : _frontFace(context),
        );
      },
    );
  }

  Widget _frontFace(BuildContext context) {
    final card = widget.card;

    return _CardShell(
      level: card.level,
      onSpeak: () => _speak(card.word, card.sourceLanguage),
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
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 16,
                color: context.colorInkMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                LocaleKeys.studyTapToReveal.tr,
                style: AppTextStyles.caption.copyWith(
                  color: context.colorInkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backFace(BuildContext context) {
    final card = widget.card;

    return _CardShell(
      level: card.level,
      onSpeak: () => _speak(card.translation, card.targetLanguage),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.word,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colorInkMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              card.translation,
              style: AppTextStyles.heading1.copyWith(
                fontSize: 32,
                color: AppColors.accent,
              ),
              textAlign: TextAlign.center,
            ),
            if (card.wordDescription != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                card.wordDescription!,
                style: AppTextStyles.body.copyWith(
                  color: context.colorInkMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (card.exampleSentences.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.colorPaper,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  card.exampleSentences.first,
                  style: AppTextStyles.body.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The drag-direction stamps, mirroring the physical sense of sorting a
  /// card into a "knew it" or "didn't" pile as you move it.
  List<Widget> _buildStamps() {
    final draggingRight = _dragX > 0;
    final opacity = _commitProgress;

    return [
      Positioned(
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        child: Opacity(
          opacity: draggingRight ? opacity : 0,
          child: Transform.rotate(
            angle: -0.24,
            child: _Stamp(
              label: LocaleKeys.studyGotIt.tr,
              color: AppColors.success,
            ),
          ),
        ),
      ),
      Positioned(
        top: AppSpacing.lg,
        right: AppSpacing.lg,
        child: Opacity(
          opacity: draggingRight ? 0 : opacity,
          child: Transform.rotate(
            angle: 0.24,
            child: _Stamp(
              label: LocaleKeys.studyForgot.tr,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    ];
  }
}

/// The shared paper-card frame both faces sit in.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.level, required this.onSpeak});

  final Widget child;
  final String? level;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colorBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: isDark ? 0.4 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg * 2,
              AppSpacing.lg,
              AppSpacing.lg * 2,
            ),
            child: Center(child: child),
          ),
          if (level != null)
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: _LevelBadge(level: level!),
            ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: IconButton(
              icon: const Icon(Icons.volume_up_rounded),
              color: AppColors.accent,
              onPressed: onSpeak,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.button.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// The two-choice fallback for the swipe, which also previews what the
/// current drag would commit to.
class _AnswerControls extends StatelessWidget {
  const _AnswerControls({
    required this.enabled,
    required this.commitProgress,
    required this.leaningRecalled,
    required this.onAnswer,
  });

  final bool enabled;
  final double commitProgress;
  final bool leaningRecalled;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _AnswerButton(
                    label: LocaleKeys.studyForgot.tr,
                    icon: Icons.refresh_rounded,
                    color: AppColors.error,
                    emphasis: leaningRecalled ? 0 : commitProgress,
                    onPressed: () => onAnswer(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _AnswerButton(
                    label: LocaleKeys.studyGotIt.tr,
                    icon: Icons.check_rounded,
                    color: AppColors.success,
                    emphasis: leaningRecalled ? commitProgress : 0,
                    onPressed: () => onAnswer(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.studySwipeHint.tr,
              style: AppTextStyles.caption.copyWith(
                color: context.colorInkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.emphasis,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;

  /// 0 to 1, tracking how close the current drag is to committing to this
  /// side - the buttons light up as the card approaches its threshold.
  final double emphasis;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.lerp(
        color.withValues(alpha: 0.10),
        color,
        Curves.easeOut.transform(emphasis),
      ),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Color.lerp(color, Colors.white, emphasis),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: Color.lerp(color, Colors.white, emphasis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        level,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
