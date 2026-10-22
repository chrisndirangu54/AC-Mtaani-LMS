import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class AdvancedLearningStudio extends StatefulWidget {
 const AdvancedLearningStudio({super.key});
 @override State<AdvancedLearningStudio> createState()=>_AdvancedLearningStudioState();
}
class _AdvancedLearningStudioState extends State<AdvancedLearningStudio>{
 String status='';
 bool busy=false;
 final course=TextEditingController(), certificate=TextEditingController();
 @override void dispose(){course.dispose();certificate.dispose();super.dispose();}
 Future<void> call(String fn,Map<String,dynamic> data)async{
  setState(()=>busy=true);
  try{final res=await FirebaseFunctions.instance.httpsCallable(fn).call(data);
   if(fn=='requestCertificate' && res.data is Map && res.data['pdfBase64'] is String){ final bytes=Uint8List.fromList(base64Decode(res.data['pdfBase64'] as String)); await Printing.sharePdf(bytes:bytes,filename:'AC_Mtaani_certificate.pdf'); }
   if(mounted)setState(()=>status=const JsonEncoder.withIndent('  ').convert(res.data is Map?Map.from(res.data)..remove('pdfBase64'):res.data));
  }catch(e){if(mounted)setState(()=>status='Unable to complete operation: $e');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
 appBar:AppBar(title:const Text('Advanced Learning Studio')),
 body:ListView(padding:const EdgeInsets.all(20),children:[
  const Text('Certificates and learning analytics',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
  const Text('Certificates require trusted, staff-approved verified completion. A PDF renderer and student records review are separate deployment steps.'),
  TextField(controller:course,decoration:const InputDecoration(labelText:'Completed course ID')),
  FilledButton(onPressed:busy?null:()=>call('requestCertificate',{'courseId':course.text.trim()}),child:const Text('Request verified certificate')),
  TextField(controller:certificate,decoration:const InputDecoration(labelText:'Certificate verification ID')),
  OutlinedButton(onPressed:busy?null:()=>call('verifyCertificate',{'certificateId':certificate.text.trim()}),child:const Text('Verify credential')),
  OutlinedButton(onPressed:busy?null:()=>call('getDashboardMetrics',{}),child:const Text('Load admin dashboard metrics')),
  const Divider(),
  const Text('Interactive learning providers',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
  const Text('Coding labs must execute remotely in isolated, ephemeral containers with no unrestricted network access. Never run learner code in the app or Firebase Functions.'),
  const Text('H5P, live classroom and 3D/VR materials are launched from instructor-approved HTTPS resources in the Learning Hub.'),
  const SizedBox(height:12),
  OutlinedButton.icon(onPressed:()=>launchUrl(Uri.parse('https://h5p.org'),mode:LaunchMode.externalApplication),icon:const Icon(Icons.open_in_new),label:const Text('H5P interoperability information')),
  const SizedBox(height:12),
  SelectableText(status),
 ]));
}
