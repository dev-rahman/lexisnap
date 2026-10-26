import 'package:supabase_flutter/supabase_flutter.dart';

import 'translation_ai_service.dart';

/// Calls the `translate-words` Supabase Edge Function - same pattern as
/// `SupabaseEdgeVocabularyService`: the Groq API key stays server-side,
/// and `functions.invoke` automatically attaches the signed-in user's
/// auth token.
class SupabaseEdgeTranslationService implements TranslationAiService {
  @override
  Future<Map<String, String>> translateWords({
    required List<String> words,
    String? sourceLanguage,
    required String targetLanguage,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'translate-words',
      body: {
        'words': words,
        if (sourceLanguage != null) 'source_language': sourceLanguage,
        'target_language': targetLanguage,
      },
    );

    if (response.status != 200) {
      throw Exception('translate-words returned ${response.status}');
    }

    final data = response.data as Map<String, dynamic>;
    final translations = data['translations'] as List;

    return {
      for (final entry in translations)
        (entry as Map<String, dynamic>)['word'] as String:
            entry['translation'] as String,
    };
  }
}
