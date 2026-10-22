import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cached lesson text for explicitly downloaded course materials.
/// This is a starter offline reader cache; it does not sync progress or video.
class OfflineLessonStore {
 static const prefix='approved_lesson_v1_';
 Future<void> save(String courseId,String lessonId,Map<String,dynamic> lesson)async{
  final prefs=await SharedPreferences.getInstance();
  final safe={'title':lesson['title'],'content':lesson['content'],'downloadedAt':DateTime.now().toUtc().toIso8601String()};
  await prefs.setString('$prefix${courseId}_$lessonId',jsonEncode(safe));
 }
 Future<Map<String,dynamic>?> read(String courseId,String lessonId)async{
  final prefs=await SharedPreferences.getInstance();
  final data=prefs.getString('$prefix${courseId}_$lessonId');
  if(data==null)return null;
  return Map<String,dynamic>.from(jsonDecode(data) as Map);
 }
 Future<void> remove(String courseId,String lessonId)async{
  final prefs=await SharedPreferences.getInstance();
  await prefs.remove('$prefix${courseId}_$lessonId');
 }
}

/// Opens curated H5P, livestream and WebXR links using device browser.
/// Only trusted published https resources should be shown in the UI.
Future<bool> openApprovedLearningLink(String rawUrl)async{
 final uri=Uri.tryParse(rawUrl);
 if(uri==null||uri.scheme!='https'||uri.host.isEmpty||uri.userInfo.isNotEmpty)return false;
 return launchUrl(uri,mode:LaunchMode.externalApplication);
}
