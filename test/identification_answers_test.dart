import 'package:flutter_test/flutter_test.dart';
import 'package:stimsys/models/assessment_model.dart';
import 'package:stimsys/screens/admin/desktop_assessment_screen.dart';

void main() {
  group('Identification answer key (one question · many answers)', () {
    test('splits the stored pipe-separated key into answers', () {
      expect(splitAnswers('Rizal | Jose Rizal'), ['Rizal', 'Jose Rizal']);
      expect(splitAnswers(' Rizal | | Jose Rizal '),
          ['Rizal', 'Jose Rizal']);
      expect(splitAnswers('Rizal'), ['Rizal']);
      expect(splitAnswers(''), isEmpty);
    });

    test('joins answers, dropping blanks and duplicates', () {
      expect(joinAnswers(['Rizal', 'Jose Rizal']), 'Rizal | Jose Rizal');
      expect(joinAnswers(['  Rizal ', '', 'jose rizal', 'RIZAL']),
          'Rizal | jose rizal');
      expect(joinAnswers([]), '');
    });

    test('handles [IC] prefix for interchangeable answers', () {
      expect(splitAnswers('[IC]CPU | RAM'), ['CPU', 'RAM']);
      expect(splitAnswers('  [IC]  CPU | RAM '), ['CPU', 'RAM']);
      expect(joinAnswers(['CPU', 'RAM'], isInterchangeable: true),
          '[IC]CPU | RAM');
      expect(joinAnswers(['CPU', 'RAM'], isInterchangeable: false),
          'CPU | RAM');
    });

    test('round-trips through split → join with interchangeable flag', () {
      const key = '[IC]CPU | RAM | GPU';
      final answers = splitAnswers(key);
      expect(joinAnswers(answers, isInterchangeable: true), key);
    });
  });

  group('Identification question grading & interchangeable logic', () {
    test('strict order identification requires exact blank sequence', () {
      const q = AssessmentQuestion(
        assessmentId: 'test_a',
        questionOrder: 0,
        questionText: 'Name the two components in order:',
        questionType: 'identification',
        correctAnswer: 'CPU | RAM',
        points: 2,
      );

      expect(q.isInterchangeable, isFalse);
      expect(q.identificationBlanks, ['CPU', 'RAM']);

      // Exact order
      expect(q.checkAnswer('cpu||ram'), isTrue);
      expect(q.computePoints('cpu||ram'), 2.0);

      // Reversed order fails strict check
      expect(q.checkAnswer('ram||cpu'), isFalse);
      // Partial credit: neither matches its required slot
      expect(q.computePoints('ram||cpu'), 0.0);

      // 1 of 2 correct
      expect(q.computePoints('cpu||storage'), 1.0);
    });

    test('interchangeable identification accepts any blank order', () {
      const q = AssessmentQuestion(
        assessmentId: 'test_a',
        questionOrder: 0,
        questionText: 'Name any two system components:',
        questionType: 'identification',
        correctAnswer: '[IC]CPU | RAM',
        points: 4,
      );

      expect(q.isInterchangeable, isTrue);
      expect(q.identificationBlanks, ['CPU', 'RAM']);

      // Regular order
      expect(q.checkAnswer('cpu||ram'), isTrue);
      expect(q.computePoints('cpu||ram'), 4.0);

      // Swapped / reversed order works
      expect(q.checkAnswer('ram||cpu'), isTrue);
      expect(q.computePoints('ram||cpu'), 4.0);

      // Case insensitive
      expect(q.checkAnswer('RAM||CPU'), isTrue);

      // Duplicate answer does not give double credit
      expect(q.checkAnswer('cpu||cpu'), isFalse);
      expect(q.computePoints('cpu||cpu'), 2.0); // only 1 matched

      // Partial credit (1 of 2 correct)
      expect(q.checkAnswer('cpu||monitor'), isFalse);
      expect(q.computePoints('cpu||monitor'), 2.0);
    });
  });
}
