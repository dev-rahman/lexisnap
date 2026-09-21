import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/vocabulary_extraction_result.dart';
import '../../../data/models/vocabulary_word.dart';
import 'vocabulary_ai_service.dart';

/// Calls the `extract-vocabulary` Supabase Edge Function, which holds the
/// Groq API key server-side and does the actual AI call - the key never
/// ships inside the app. `functions.invoke` automatically attaches the
/// signed-in user's auth token, so only authenticated LexiSnap users can
/// trigger a (billable) call.
class SupabaseEdgeVocabularyService implements VocabularyAiService {
  @override
  Future<VocabularyExtractionResult> extractVocabulary(String text) async {
    final response = await Supabase.instance.client.functions.invoke(
      'extract-vocabulary',
      body: {'text': text},
    );

    if (response.status != 200) {
      throw Exception('extract-vocabulary returned ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    final words = data['words'] as List;

    return VocabularyExtractionResult(
      words: words
          .map((word) => VocabularyWord.fromJson(word as Map<String, dynamic>))
          .toList(),
      sourceLanguageCode: data['language_code'] as String?,
      sourceLanguageName: data['language_name'] as String?,
      suggestedDeckName: data['suggested_deck_name'] as String?,
    );
  }
}
