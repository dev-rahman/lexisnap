import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/deck/deck_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/flashcard.dart';

/// Edits one card's content: its word, translation, an optional
/// description, and any number of example sentences. Pushed from
/// [CardDetailView]; pops back with the updated [Flashcard] on save, or
/// with nothing if the user backs out.
///
/// Only the content is editable here - the spaced-repetition schedule is
/// left to the study sessions that own it.
class CardEditView extends StatefulWidget {
  const CardEditView({super.key, required this.card});

  final Flashcard card;

  @override
  State<CardEditView> createState() => _CardEditViewState();
}

class _CardEditViewState extends State<CardEditView> {
  final _formKey = GlobalKey<FormState>();

  late final _wordController = TextEditingController(text: widget.card.word);
  late final _translationController = TextEditingController(
    text: widget.card.translation,
  );
  late final _descriptionController = TextEditingController(
    text: widget.card.wordDescription ?? '',
  );
  late final List<TextEditingController> _exampleControllers = [
    for (final sentence in widget.card.exampleSentences)
      TextEditingController(text: sentence),
  ];

  final _isSaving = false.obs;

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    _descriptionController.dispose();
    for (final controller in _exampleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addExample() {
    setState(() => _exampleControllers.add(TextEditingController()));
  }

  void _removeExample(int index) {
    setState(() => _exampleControllers.removeAt(index).dispose());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving.value) return;

    final description = _descriptionController.text.trim();
    final sentences = [
      for (final controller in _exampleControllers)
        if (controller.text.trim().isNotEmpty) controller.text.trim(),
    ];

    _isSaving.value = true;
    try {
      await Get.find<DeckRepository>().updateFlashcard(
        flashcardId: widget.card.id,
        word: _wordController.text.trim(),
        translation: _translationController.text.trim(),
        wordDescription: description.isEmpty ? null : description,
        exampleSentences: sentences,
      );

      final updated = widget.card.copyWith(
        word: _wordController.text.trim(),
        translation: _translationController.text.trim(),
        wordDescription: description.isEmpty ? null : description,
        exampleSentences: sentences,
      );

      Get.back(result: updated);
      AppSnackbar.success(LocaleKeys.cardEditSavedSuccess.tr);
    } catch (_) {
      _isSaving.value = false;
      AppSnackbar.error(LocaleKeys.cardEditSaveError.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: Text(LocaleKeys.cardEditTitle.tr),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: LocaleKeys.cardEditWord.tr,
                  controller: _wordController,
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? LocaleKeys.validatorFieldRequired.tr
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: LocaleKeys.cardEditTranslation.tr,
                  controller: _translationController,
                  maxLines: 2,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? LocaleKeys.validatorFieldRequired.tr
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: LocaleKeys.cardEditDescription.tr,
                  controller: _descriptionController,
                  hintText: LocaleKeys.cardEditDescriptionHint.tr,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  LocaleKeys.cardEditExamples.tr,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < _exampleControllers.length; i++) ...[
                  _ExampleField(
                    controller: _exampleControllers[i],
                    onRemove: () => _removeExample(i),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addExample,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(LocaleKeys.cardEditAddExample.tr),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(
                  () => AppButton(
                    label: LocaleKeys.commonSave.tr,
                    isLoading: _isSaving.value,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One example-sentence row: a multi-line field with a remove button beside
/// it, so a sentence can be dropped without clearing it by hand first.
class _ExampleField extends StatelessWidget {
  const _ExampleField({required this.controller, required this.onRemove});

  final TextEditingController controller;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: LocaleKeys.cardEditExampleHint.tr,
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.remove_circle_outline_rounded,
            color: AppColors.alert,
          ),
          onPressed: onRemove,
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
        ),
      ],
    );
  }
}
