/// Contract for turning a photo of text into text. Controllers talk only to
/// this interface, never to a specific OCR engine/SDK.
///
/// To swap the on-device ML Kit recognizer for a cloud OCR provider later,
/// write a new class that implements this interface and swap the single
/// registration in `lib/app/core/services/service_locator.dart`. Nothing
/// else changes.
abstract class TextRecognitionService {
  /// Runs OCR on the image at [imagePath] and returns the recognized text
  /// (empty string if nothing was found).
  Future<String> recognizeText(String imagePath);
}
