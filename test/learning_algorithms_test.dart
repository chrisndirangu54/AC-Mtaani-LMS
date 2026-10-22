import 'package:flutter_test/flutter_test.dart';
import 'package:american_corner_mtaani_lms/learning_algorithms.dart';
void main(){
 test('new learner begins with foundation practice',(){
  expect(recommendDifficulty(masteryFromScores([])),StudyDifficulty.foundation);
 });
 test('high recent scores recommend advanced material',(){
  expect(recommendDifficulty(masteryFromScores([0.85,0.92,0.95])),StudyDifficulty.advanced);
 });
 test('spaced repetition schedules passed answers',(){
  final day=DateTime.utc(2026,10,22);
  final x=ReviewState.initial(day).apply(5,day);
  expect(x.repetitions,1);
  expect(x.intervalDays,1);
  expect(x.due,DateTime.utc(2026,10,23));
 });
 test('failed review resets repetition',(){
  final day=DateTime.utc(2026,10,22);
  final x=ReviewState.initial(day).apply(5,day).apply(1,day);
  expect(x.repetitions,0);
  expect(x.intervalDays,1);
 });
}
