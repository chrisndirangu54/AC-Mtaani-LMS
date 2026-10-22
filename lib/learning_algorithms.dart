/// SM-2-inspired spaced repetition; local scheduling logic, not a validated
/// personalized teaching model. Store history per authenticated learner.
class ReviewState {
 final int repetitions;
 final double ease;
 final int intervalDays;
 final DateTime due;
 const ReviewState({required this.repetitions,required this.ease,required this.intervalDays,required this.due});
 factory ReviewState.initial(DateTime now)=>ReviewState(repetitions:0,ease:2.5,intervalDays:0,due:now);
 ReviewState apply(int quality,DateTime now){
  if(quality<0||quality>5)throw ArgumentError.value(quality,'quality','Expected 0–5');
  final nextEase=(ease+0.1-(5-quality)*(0.08+(5-quality)*0.02)).clamp(1.3,3.5).toDouble();
  final passed=quality>=3;
  final reps=passed?repetitions+1:0;
  final interval=passed?(reps==1?1:reps==2?6:(intervalDays*nextEase).round().clamp(1,3650)):1;
  return ReviewState(repetitions:reps,ease:nextEase,intervalDays:interval,due:(now.isUtc ? DateTime.utc(now.year,now.month,now.day) : DateTime(now.year,now.month,now.day)).add(Duration(days:interval)));
 }
 Map<String,dynamic> toJson()=>{'repetitions':repetitions,'ease':ease,'intervalDays':intervalDays,'due':due.toIso8601String()};
 factory ReviewState.fromJson(Map<String,dynamic> json)=>ReviewState(repetitions:(json['repetitions'] as num?)?.toInt()??0,ease:(json['ease'] as num?)?.toDouble()??2.5,intervalDays:(json['intervalDays'] as num?)?.toInt()??0,due:DateTime.tryParse('${json['due']}')??DateTime.now());
}
/// Simple mastery estimator based on recent quiz accuracy; not a calibrated ML model.
double masteryFromScores(Iterable<double> scores){
 final values=scores.where((x)=>x.isFinite && x>=0 && x<=1).toList();
 if(values.isEmpty)return 0;
 double weight=1,sum=0,total=0;
 for(final value in values){sum+=value*weight;total+=weight;weight=(weight*1.25).clamp(0.0,10000.0);}
 return (sum/total).clamp(0,1).toDouble();
}
enum StudyDifficulty {foundation,intermediate,advanced}
StudyDifficulty recommendDifficulty(double mastery){
 if(mastery<0.5)return StudyDifficulty.foundation;
 if(mastery<0.82)return StudyDifficulty.intermediate;
 return StudyDifficulty.advanced;
}
