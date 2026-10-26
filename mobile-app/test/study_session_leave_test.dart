import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexisnap/app/core/localization/app_translations.dart';
import 'package:lexisnap/app/core/services/streak/streak_service.dart';
import 'package:lexisnap/app/core/services/study/study_preferences_service.dart';
import 'package:lexisnap/app/data/models/flashcard.dart';
import 'package:lexisnap/app/modules/study_session/study_session_view.dart';

Flashcard card(int i) => Flashcard(
  id: 'card-$i',
  word: 'word $i',
  translation: 'translation $i',
  exampleSentences: const [],
  targetLanguage: 'en',
  easeFactor: 2.5,
  intervalDays: 0,
  repetitions: 0,
  dueAt: DateTime(2020),
);

/// A home screen with a button that opens a session over [cards].
Future<void> openSession(WidgetTester tester, List<Flashcard> cards) async {
  await tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Get.to(
              () => StudySessionView(flashcards: cards, practiceOnly: true),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(StudySessionView), findsOneWidget);
}

void main() {
  setUp(() {
    Get.reset();
    Get.put(StreakService());
    Get.put(StudyPreferencesService());
  });

  testWidgets('the X asks first; keep studying stays, leave leaves', (
    tester,
  ) async {
    await openSession(tester, [for (var i = 0; i < 5; i++) card(i)]);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Leave this session?'), findsOneWidget);
    expect(
      find.text(
        "You have 5 cards left. The ones you've already answered still count.",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep studying'));
    await tester.pumpAndSettle();
    expect(find.byType(StudySessionView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave session'));
    await tester.pumpAndSettle();
    expect(find.byType(StudySessionView), findsNothing);
  });

  testWidgets('the system back button asks too', (tester) async {
    await openSession(tester, [for (var i = 0; i < 5; i++) card(i)]);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Leave this session?'), findsOneWidget);
    expect(find.byType(StudySessionView), findsOneWidget);
  });

  testWidgets('nothing to ask once the session is over', (tester) async {
    // No cards means the session opens straight onto its summary.
    await openSession(tester, const []);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Leave this session?'), findsNothing);
    expect(find.byType(StudySessionView), findsNothing);
  });
}
