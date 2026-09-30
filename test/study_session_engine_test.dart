import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexisnap/app/data/models/flashcard.dart';
import 'package:lexisnap/app/data/models/review_grade.dart';
import 'package:lexisnap/app/data/models/study_mode.dart';
import 'package:lexisnap/app/modules/study_session/study_session_engine.dart';

/// A due card with its own translation, so every card has plenty of
/// distractors and multiple choice is always possible.
Flashcard card(int i, {int repetitions = 0}) => Flashcard(
  id: 'card-$i',
  word: 'word $i',
  translation: 'translation $i',
  exampleSentences: const [],
  targetLanguage: 'en',
  easeFactor: 2.5,
  intervalDays: 0,
  repetitions: repetitions,
  dueAt: DateTime(2020),
);

/// Runs a whole session answering every card right, and returns the kind
/// each card was asked as, in order.
List<StudyStepKind> kindsServed(
  StudyMode mode, {
  required int seed,
  int cards = 20,
  int repetitions = 0,
}) {
  final engine = StudySessionEngine(
    deck: [for (var i = 0; i < cards; i++) card(i, repetitions: repetitions)],
    cap: cards,
    mode: mode,
    random: Random(seed),
  );
  final kinds = <StudyStepKind>[];
  while (!engine.isComplete) {
    final step = engine.currentStep!;
    kinds.add(step.kind);
    engine.complete(step.card, ReviewGrade.good);
  }
  return kinds;
}

int longestRun(List<StudyStepKind> kinds) {
  var longest = 0;
  var run = 0;
  for (var i = 0; i < kinds.length; i++) {
    run = i > 0 && kinds[i] == kinds[i - 1] ? run + 1 : 1;
    longest = max(longest, run);
  }
  return longest;
}

void main() {
  group('Smart mode', () {
    test('mixes both kinds on a brand-new deck', () {
      for (var seed = 0; seed < 100; seed++) {
        final kinds = kindsServed(StudyMode.smart, seed: seed);
        expect(kinds, contains(StudyStepKind.choice), reason: 'seed $seed');
        expect(kinds, contains(StudyStepKind.recall), reason: 'seed $seed');
      }
    });

    test('ignores how well each card is known', () {
      for (var seed = 0; seed < 100; seed++) {
        final kinds = kindsServed(StudyMode.smart, seed: seed, repetitions: 8);
        expect(kinds, contains(StudyStepKind.choice), reason: 'seed $seed');
        expect(kinds, contains(StudyStepKind.recall), reason: 'seed $seed');
      }
    });

    test('never asks three of one kind in a row', () {
      for (var seed = 0; seed < 500; seed++) {
        final kinds = kindsServed(StudyMode.smart, seed: seed);
        expect(longestRun(kinds), lessThanOrEqualTo(2), reason: 'seed $seed');
      }
    });

    // Four cards is the smallest deck that can offer multiple choice at
    // all: it takes three other cards' translations as wrong answers.
    test('shows both kinds even in a four-card session', () {
      for (var seed = 0; seed < 100; seed++) {
        final kinds = kindsServed(StudyMode.smart, seed: seed, cards: 4);
        expect(kinds.toSet(), hasLength(2), reason: 'seed $seed');
      }
    });
  });

  test('Quiz mode is always multiple choice', () {
    expect(kindsServed(StudyMode.quiz, seed: 1).toSet(), {
      StudyStepKind.choice,
    });
  });

  test('Flip mode is always a flip card', () {
    expect(kindsServed(StudyMode.flip, seed: 1).toSet(), {
      StudyStepKind.recall,
    });
  });
}
