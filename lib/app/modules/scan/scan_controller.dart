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
import '../../data/models/vocabulary_extraction_result.dart';
import '../../data/models/vocabulary_language.dart';
import '../../data/models/vocabulary_word.dart';
import '../decks/decks_controller.dart';

enum ScanStage {
  /// Choosing between camera and gallery.
  source,

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

  final stage = ScanStage.source.obs;
  final imagePath = RxnString();
  final candidateWords = <VocabularyWord>[].obs;
  final selectedWords = <VocabularyWord>{}.obs;
  final sourceLanguageCode = RxnString();
  final sourceLanguageName = RxnString();
  final suggestedDeckName = RxnString();

  bool get allSelected =>
      candidateWords.isNotEmpty &&
      selectedWords.length == candidateWords.length;

  Future<void> captureFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (file == null) return;
    imagePath.value = file.path;
    stage.value = ScanStage.reviewing;
  }

  Future<void> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (file == null) return;
    imagePath.value = file.path;
    stage.value = ScanStage.reviewing;
  }

  void retake() {
    imagePath.value = null;
    stage.value = ScanStage.source;
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
