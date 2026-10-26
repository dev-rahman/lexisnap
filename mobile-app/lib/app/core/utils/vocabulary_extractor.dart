/// Turns raw OCR text into a deduplicated list of candidate vocabulary
/// words, in first-seen order.
///
/// Deliberately light-touch: no stopword filtering, since the scanned text
/// can be in any of the app's supported languages and a one-size-fits-all
/// stopword list would silently drop valid vocabulary in some of them.
class VocabularyExtractor {
  VocabularyExtractor._();

  /// Caps how many chips the selection screen ever has to render.
  static const maxWords = 150;

  static final _wordPattern = RegExp(r"[\p{L}][\p{L}'-]*", unicode: true);

  static List<String> extract(String text) {
    final seen = <String>{};
    final words = <String>[];

    for (final match in _wordPattern.allMatches(text)) {
      final word = match.group(0)!;
      if (word.length < 2) continue;

      if (seen.add(word.toLowerCase())) {
        words.add(word);
        if (words.length >= maxWords) break;
      }
    }

    return words;
  }
}
