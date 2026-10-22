import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
/// Durable at-least-once delivery of idempotent lesson-read events. Other edits
/// are intentionally not reconciled here and require field-specific policies.
class OfflineSyncQueue {
 static const _key='acm_offline_sync_v2';
 Future<void> enqueue({required String operationId,required String courseId,required String lessonId})async{
  final p=await SharedPreferences.getInstance();
  final items=List<Map<String,dynamic>>.from((jsonDecode(p.getString(_key)??'[]') as List).map((e)=>Map<String,dynamic>.from(e as Map)));
  if(items.any((e)=>e['operationId']==operationId))return;
  items.add({'operationId':operationId,'courseId':courseId,'lessonId':lessonId,'action':'mark_read'});
  await p.setString(_key,jsonEncode(items));
 }
 Future<int> flush()async{
  final p=await SharedPreferences.getInstance();
  final items=List<Map<String,dynamic>>.from((jsonDecode(p.getString(_key)??'[]') as List).map((e)=>Map<String,dynamic>.from(e as Map)));
  var done=0;
  for(final item in List<Map<String,dynamic>>.from(items)){
   try{
    await FirebaseFunctions.instance.httpsCallable('putSyncOperation').call(item);
    items.removeWhere((x)=>x['operationId']==item['operationId']);
    await p.setString(_key,jsonEncode(items));done++;
   }catch(_){break;} // retry on next app resume or online event
  }
  return done;
 }
}
