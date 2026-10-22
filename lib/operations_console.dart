import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OperationsConsole extends StatefulWidget{
 const OperationsConsole({super.key});
 @override State<OperationsConsole> createState()=>_OperationsConsoleState();
}
class _OperationsConsoleState extends State<OperationsConsole>{
 final id=TextEditingController(),code=TextEditingController(),person=TextEditingController();
 String language='python',response='';
 bool busy=false;
 @override void dispose(){id.dispose();code.dispose();person.dispose();super.dispose();}
 Future<void> invoke(String fn,Map<String,dynamic> payload)async{
  setState(()=>busy=true);
  try{final result=await FirebaseFunctions.instance.httpsCallable(fn).call(payload);if(mounted)setState(()=>response='${result.data}');}
  catch(e){if(mounted)setState(()=>response='Operation failed: $e');}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Advanced Operations')),body:ListView(padding:const EdgeInsets.all(20),children:[
  const Text('Secure lab job submission',style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),
  const Text('Jobs are queued for an isolated execution worker. No code runs on your phone or the Firebase function.'),
  TextField(controller:id,decoration:const InputDecoration(labelText:'Published lab ID')),
  DropdownButton<String>(value:language,items:['python','javascript','sql'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>language=v??language)),
  TextField(controller:code,maxLines:6,decoration:const InputDecoration(labelText:'Practice code',border:OutlineInputBorder())),
  FilledButton(onPressed:busy?null:()=>invoke('requestLabRun',{'labId':id.text.trim(),'language':language,'source':code.text}),child:const Text('Queue sandbox run')),
  const Divider(),
  const Text('Course analytics',style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),
  OutlinedButton(onPressed:busy?null:()=>invoke('getCourseAnalytics',{'courseId':id.text.trim()}),child:const Text('View course enrollments (staff)')),
  const Divider(),
  const Text('Administrative controls',style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),
  TextField(controller:person,decoration:const InputDecoration(labelText:'Staff Firebase UID')),
  OutlinedButton(onPressed:busy?null:()=>invoke('setInstitutionalRole',{'uid':person.text.trim(),'role':'instructor'}),child:const Text('Assign instructor (admin only)')),
  OutlinedButton(onPressed:busy?null:()=>invoke('setInstitutionalRole',{'uid':person.text.trim(),'role':'learner'}),child:const Text('Revoke staff role (admin only)')),
  const Text('Admin access is issued server-side through Firebase custom claims. Role changes are audited.'),
  const Divider(),
  SelectableText(response)
 ]));
}
