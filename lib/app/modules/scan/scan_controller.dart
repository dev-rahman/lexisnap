import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/deck/deck_repository.dart';
import '../../core/services/ocr/text_recognition_service.dart';
import '../../core/services/translation/translation_ai_service.dart';
import '../../core/services/vocabulary/vocabulary_ai_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/vocabulary_extractor.dart';
import '../../data/models/deck_word.dart';
import '../../data/models/scan_source.dart';
import '../../data/models/vocabulary_extraction_result.dart';
import '../../data/models/vocabulary_language.dart';
import '../../data/models/vocabulary_word.dart';
import '../decks/decks_controller.dart';

enum ScanStage {
  /// Waiting on the system camera or photo picker. The route shows almost
  /// nothing here because the picker covers it immediately - this stage
  /// exists so the flow has somewhere to stand while that happens.
  pickingImage,

  /// Reviewing the captured/picked photo before running OCR on it.
  reviewing,

  /// Running OCR + AI vocabulary extraction on the confirmed photo.
  processing,

  /// Text was found - tap-to-select the words worth learning.
  wordSelection,

  /// Translating the selection and saving the deck to Supabase.
  savingDeck,

  /// OCR found no readable text at all.
  empty,
}

class ScanController extends GetxController {
  TextRecognitionService get _textRecognitionService =>
      Get.find<TextRecognitionService>();

  VocabularyAiService get _vocabularyAiService =>
      Get.find<VocabularyAiService>();

  TranslationAiService get _translationAiService =>
      Get.find<TranslationAiService>();

  DeckRepository get _deckRepository => Get.find<DeckRepository>();

  final _picker = ImagePicker();

  final stage = ScanStage.pickingImage.obs;
  final imagePath = RxnString();
  final candidateWords = <VocabularyWord>[].obs;
  final selectedWords = <VocabularyWord>{}.obs;
  final sourceLanguageCode = RxnString();
  final sourceLanguageName = RxnString();
  final suggestedDeckName = RxnString();

  bool get allSelected =>
      candidateWords.isNotEmpty &&
      selectedWords.length == candidateWords.length;

  /// Where the photo comes from, chosen before this route was pushed (see
  /// `startScanFlow`) and kept so Retake can reopen the same picker.
  ScanSource? _source;

  @override
  void onInit() {
    super.onInit();
    final source = Get.arguments;
    if (source is! ScanSource) return;
    _source = source;
    // Deferred by a frame: the picker can complete (or be cancelled, which
    // pops this route) before the route has finished being built.
    SchedulerBinding.instance.addPostFrameCallback((_) => _pickImage());
  }

  Future<void> _pickImage() async {
    final source = _source;
    if (source == null) return;

    stage.value = ScanStage.pickingImage;
    final file = await _picker.pickImage(
      source: source == ScanSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );

    if (file == null) {
      // Nothing was picked and there is no source screen to fall back to
      // any more, so leave the flow rather than sitting on a blank stage.
      Get.back();
      return;
    }

    imagePath.value = file.path;
    stage.value = ScanStage.reviewing;
  }

  /// Reopens whichever picker the user started from. "Retake" on a camera
  /// scan should mean the camera, not a source menu they never saw.
  void retake() {
    imagePath.value = null;
    _pickImage();
  }

  Future<void> confirmImage() async {
    final path = imagePath.value;
    if (path == null) return;

    stage.value = ScanStage.processing;
    try {
      final text = await _textRecognitionService.recognizeText(path);
      if (text.trim().isEmpty) {
        stage.value = ScanStage.empty;
        return;
      }

      VocabularyExtractionResult result;
      try {
        result = await _vocabularyAiService.extractVocabulary(text);
      } catch (_) {
        // No network, API error, etc. - degrade to the local word list
        // instead of failing the whole scan. No language/deck-name
        // suggestion is possible from the regex fallback.
        result = VocabularyExtractionResult(
          words: VocabularyExtractor.extract(text)
              .map((word) => VocabularyWord(word: word))
              .toList(),
        );
      }

      candidateWords.assignAll(result.words);
      selectedWords.clear();
      sourceLanguageCode.value = result.sourceLanguageCode;
      sourceLanguageName.value = result.sourceLanguageName;
      suggestedDeckName.value = result.suggestedDeckName;
      stage.value = result.words.isEmpty
          ? ScanStage.empty
          : ScanStage.wordSelection;
    } catch (_) {
      AppSnackbar.error(LocaleKeys.scanProcessingError.tr);
      stage.value = ScanStage.reviewing;
    }
  }

  void toggleWord(VocabularyWord word) {
    if (!selectedWords.remove(word)) {
      selectedWords.add(word);
    }
  }

  void toggleSelectAll() {
    if (allSelected) {
      selectedWords.clear();
    } else {
      selectedWords.assignAll(candidateWords);
    }
  }

  /// Translates the current selection into [targetLanguage] and saves it
  /// as a new deck in Supabase. On failure, the selection is preserved and
  /// the user stays on the word-selection screen to retry.
  Future<void> saveDeck(VocabularyLanguage targetLanguage) async {
    final selected = selectedWords.toList();
    if (selected.isEmpty) return;

    stage.value = ScanStage.savingDeck;
    try {
      final translations = await _translationAiService.translateWords(
        words: selected.map((word) => word.word).toList(),
        sourceLanguage: sourceLanguageCode.value,
        targetLanguage: targetLanguage.name,
      );

      final deckWords = [
        for (final word in selected)
          DeckWord(
            word: word.word,
            level: word.level,
            wordDescription: word.wordDescription,
            exampleSentence: word.exampleSentence,
            translation: translations[word.word] ?? '',
          ),
      ]..removeWhere((word) => word.translation.isEmpty);

      if (deckWords.isEmpty) {
        throw Exception('No translations were returned');
      }

      final deckName =
          suggestedDeckName.value ??
          '${sourceLanguageName.value ?? 'Scan'} → ${targetLanguage.name}';

      await _deckRepository.createDeck(
        name: deckName,
        sourceLanguage: sourceLanguageCode.value,
        targetLanguage: targetLanguage.code,
        words: deckWords,
      );

      final count = deckWords.length;
      await Get.find<DecksController>().refreshDecks();
      Get.back();
      AppSnackbar.success(
        LocaleKeys.scanDeckCreatedSuccess.trParams({
          'name': deckName,
          'count': '$count',
        }),
      );
    } catch (_) {
      AppSnackbar.error(LocaleKeys.scanDeckSaveError.tr);
      stage.value = ScanStage.wordSelection;
    }
  }
}
