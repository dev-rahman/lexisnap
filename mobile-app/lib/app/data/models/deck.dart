/// A saved deck, as shown in the Home list and deck-detail header.
class Deck {
  const Deck({
    required this.id,
    required this.name,
    this.sourceLanguage,
    required this.targetLanguage,
    required this.cardCount,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String name;
  final String? sourceLanguage;
  final String targetLanguage;
  final int cardCount;
  final DateTime createdAt;

  /// Reserved for future AI- or user-written deck notes; unused for now.
  final String? notes;
}
