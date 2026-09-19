import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/ocr/text_recognition_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/vocabulary_extractor.dart';

enum ScanStage {
  /// Choosing between camera and gallery.
  source,

  /// Reviewing the captured/picked photo before running OCR on it.
  reviewing,

  /// Running OCR on the confirmed photo.
  processing,

  /// OCR found text - tap-to-select the words worth learning.
  wordSelection,

  /// OCR found no readable text at all.
  empty,
}

class ScanController extends GetxController {
  TextRecognitionService get _textRecognitionService =>
      Get.find<TextRecognitionService>();

  final _picker = ImagePicker();

  final stage = ScanStage.source.obs;
  final imagePath = RxnString();
  final candidateWords = <String>[].obs;
  final selectedWords = <String>{}.obs;

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
      final words = VocabularyExtractor.extract(text);
      candidateWords.assignAll(words);
      selectedWords.clear();
      stage.value = words.isEmpty ? ScanStage.empty : ScanStage.wordSelection;
    } catch (_) {
      AppSnackbar.error(LocaleKeys.scanProcessingError.tr);
      stage.value = ScanStage.reviewing;
    }
  }

  void toggleWord(String word) {
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

  /// Vocabulary extraction ends here - turning the selection into saved
  /// flashcards/decks is a separate, not-yet-built step. Confirming just
  /// closes the scan flow and lets the user know what happened.
  void confirmSelection() {
    final count = selectedWords.length;
    Get.back();
    AppSnackbar.success(
      LocaleKeys.scanWordsCapturedSuccess.trParams({'count': '$count'}),
    );
  }
}
