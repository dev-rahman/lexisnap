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
import '../../data/models/deck.dart';
import '../../data/models/deck_word.dart';
import '../../data/models/scan_source.dart';
import '../../data/models/vocabulary_extraction_result.dart';
import '../../data/models/vocabulary_language.dart';
import '../../data/models/vocabulary_word.dart';
import '../../data/vocabulary_languages.dart';
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

  /// Which label the saving overlay shows - creating a deck and topping one
  /// up read differently, and a single scan can do both in turn.
  final savingLabel = RxnString();

  /// Total words saved so far in this scan, across every deck they were
  /// filed into. Drives the progress line on the selection screen and the
  /// summary shown when the flow closes.
  final filedWordCount = 0.obs;

  /// One entry per batch the user has filed, in order, for the closing
  /// summary. [isNew] distinguishes a deck this scan created from one it
  /// only added to, so the summary can word each case correctly.
  final List<({String name, int count, bool isNew})> _filed = [];

  bool get hasFiled => filedWordCount.value > 0;

  /// The decks the user already has, as a destination to add words to.
  /// Read from the always-alive [DecksController] rather than re-fetched.
  List<Deck> get existingDecks => Get.find<DecksController>().decks;

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

  /// Files the current selection into a brand-new deck, translating it into
  /// [targetLanguage] first. The chosen words leave the list afterwards so
  /// the rest can be filed elsewhere; the flow finishes once nothing is
  /// left, or when the user closes it.
  ///
  /// On failure the selection is kept and the user returns to the
  /// word-selection screen to retry.
  Future<void> fileToNewDeck(VocabularyLanguage targetLanguage) async {
    final selected = selectedWords.toList();
    if (selected.isEmpty) return;

    savingLabel.value = LocaleKeys.scanSavingDeck.tr;
    stage.value = ScanStage.savingDeck;
    try {
      final deckWords = await _translateSelection(
        selected,
        targetLanguageName: targetLanguage.name,
      );

      final deckName =
          suggestedDeckName.value ??
          '${sourceLanguageName.value ?? 'Scan'} → ${targetLanguage.name}';

      await _deckRepository.createDeck(
        name: deckName,
        sourceLanguage: sourceLanguageCode.value,
        targetLanguage: targetLanguage.code,
        words: deckWords,
      );

      // A deck's suggested name fits the first batch; a later batch going
      // to its own new deck should get a fresh, generic name rather than
      // reusing the AI's first guess.
      suggestedDeckName.value = null;

      await _onBatchFiled(
        selected,
        name: deckName,
        count: deckWords.length,
        isNew: true,
      );
    } catch (_) {
      AppSnackbar.error(LocaleKeys.scanDeckSaveError.tr);
      stage.value = ScanStage.wordSelection;
    }
  }

  /// Files the current selection into an existing [deck], translating it
  /// into that deck's own target language. Same batch behaviour and error
  /// handling as [fileToNewDeck].
  Future<void> fileToExistingDeck(Deck deck) async {
    final selected = selectedWords.toList();
    if (selected.isEmpty) return;

    savingLabel.value = LocaleKeys.scanSavingWords.tr;
    stage.value = ScanStage.savingDeck;
    try {
      // The deck stores a language code; translation is prompted with the
      // readable name. byCode is null for legacy free-text values, in which
      // case the stored text is passed through as-is.
      final targetName =
          VocabularyLanguages.byCode(deck.targetLanguage)?.name ??
          deck.targetLanguage;

      final deckWords = await _translateSelection(
        selected,
        targetLanguageName: targetName,
      );

      await _deckRepository.addWordsToDeck(
        deckId: deck.id,
        words: deckWords,
      );

      await _onBatchFiled(
        selected,
        name: deck.name,
        count: deckWords.length,
        isNew: false,
      );
    } catch (_) {
      AppSnackbar.error(LocaleKeys.scanDeckSaveError.tr);
      stage.value = ScanStage.wordSelection;
    }
  }

  /// Translates [selected] into [targetLanguageName] and builds the
  /// flashcard rows, dropping any word that came back without a
  /// translation. Throws if nothing usable is left.
  Future<List<DeckWord>> _translateSelection(
    List<VocabularyWord> selected, {
    required String targetLanguageName,
  }) async {
    final translations = await _translationAiService.translateWords(
      words: selected.map((word) => word.word).toList(),
      sourceLanguage: sourceLanguageCode.value,
      targetLanguage: targetLanguageName,
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
    return deckWords;
  }

  /// Records a saved batch, drops its words from the list, and either
  /// returns to selection for the remainder or finishes the flow.
  Future<void> _onBatchFiled(
    List<VocabularyWord> filed, {
    required String name,
    required int count,
    required bool isNew,
  }) async {
    _filed.add((name: name, count: count, isNew: isNew));
    filedWordCount.value += count;

    candidateWords.removeWhere(filed.contains);
    selectedWords.removeWhere(filed.contains);

    if (candidateWords.isEmpty) {
      await _finish();
    } else {
      stage.value = ScanStage.wordSelection;
    }
  }

  /// Closes the scan after at least one batch was filed: refreshes the
  /// decks list, leaves the flow, and sums up what was saved.
  Future<void> _finish() async {
    await Get.find<DecksController>().refreshDecks();
    Get.back();
    _showSummary();
  }

  /// Called when the user closes the selection screen themselves. Anything
  /// already filed is saved, so this finishes with a summary; if nothing
  /// was filed it is a plain cancel.
  void requestClose() {
    if (hasFiled) {
      _finish();
    } else {
      Get.back();
    }
  }

  void _showSummary() {
    if (_filed.isEmpty) return;

    if (_filed.length == 1) {
      final batch = _filed.first;
      AppSnackbar.success(
        batch.isNew
            ? LocaleKeys.scanDeckCreatedSuccess.trParams({
                'name': batch.name,
                'count': '${batch.count}',
              })
            : LocaleKeys.scanWordsAddedSuccess.trParams({
                'name': batch.name,
                'count': '${batch.count}',
              }),
      );
      return;
    }

    final deckCount = _filed.map((batch) => batch.name).toSet().length;
    AppSnackbar.success(
      LocaleKeys.scanWordsSavedSummary.trParams({
        'count': '${filedWordCount.value}',
        'decks': '$deckCount',
      }),
    );
  }
}
