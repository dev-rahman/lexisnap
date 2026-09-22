import 'package:flutter/material.dart';

import '../../data/models/vocabulary_language.dart';
import '../../data/vocabulary_languages.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A searchable picker over the curated language catalog
/// (`VocabularyLanguages.all`). Returns the picked language, or null if
/// dismissed without a selection.
Future<VocabularyLanguage?> showLanguageSelectSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
}) {
  return showModalBottomSheet<VocabularyLanguage>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colorPaper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) =>
        _LanguageSelectSheet(title: title, subtitle: subtitle),
  );
}

class _LanguageSelectSheet extends StatefulWidget {
  const _LanguageSelectSheet({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_LanguageSelectSheet> createState() => _LanguageSelectSheetState();
}

class _LanguageSelectSheetState extends State<_LanguageSelectSheet> {
  final _searchController = TextEditingController();
  List<VocabularyLanguage> _results = VocabularyLanguages.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _results = normalized.isEmpty
          ? VocabularyLanguages.all
          : VocabularyLanguages.all
                .where(
                  (language) =>
                      language.name.toLowerCase().contains(normalized),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.heading2),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.subtitle,
                      style: AppTextStyles.body.copyWith(
                        color: context.colorInkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          '—',
                          style: AppTextStyles.body.copyWith(
                            color: context.colorInkMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final language = _results[index];
                          return _LanguageRow(
                            language: language,
                            onTap: () => Navigator.pop(context, language),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.onTap});

  final VocabularyLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  language.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colorInk,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
