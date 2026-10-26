import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'text_recognition_service.dart';

/// On-device OCR via Google ML Kit - offline, free, no API key, and fast
/// enough to run right after capture without a server round-trip.
///
/// Uses the Latin script model, which covers English/German/French/Spanish
/// (the app's non-CJK supported languages). Recognizing Korean text would
/// need a second `TextRecognizer(script: TextRecognitionScript.korean)`
/// instance selected by the target language - not wired up yet.
class MlKitTextRecognitionService implements TextRecognitionService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeText(String imagePath) async {
    final result = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    return result.text;
  }

  void dispose() => _recognizer.close();
}
