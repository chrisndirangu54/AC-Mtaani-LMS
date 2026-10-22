import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminGovernanceScreen extends StatefulWidget {
 const AdminGovernanceScreen({super.key});
 @override State<AdminGovernanceScreen> createState()=>_AdminGovernanceScreenState();
}
class _AdminGovernanceScreenState extends State<AdminGovernanceScreen> {
 List<dynamic> users=[],events=[];
 bool loading=false;
 String message='';
 Future<void> load()async {
  setState(()=>loading=true);
  try {
   final auth=FirebaseAuth.instance.currentUser;
   final claims=await auth?.getIdTokenResult();
   if(claims?.claims?['role']!='admin')throw StateError('Administrator role required');
   final results=await Future.wait([
    FirebaseFunctions.instance.httpsCallable('adminListUsers').call({'limit':25}),
    FirebaseFunctions.instance.httpsCallable('adminAuditTrail').call({}),
   ]);
   if(mounted)setState((){users=List<dynamic>.from(results[0].data['users']);events=List<dynamic>.from(results[1].data['events']);});
  }catch(e){if(mounted)setState(()=>message='Could not load admin records: $e');}
  finally{if(mounted)setState(()=>loading=false);}
 }
 Future<void> disable(String uid,bool value)async {
  try{await FirebaseFunctions.instance.httpsCallable('adminSetDisabled').call({'uid':uid,'disabled':value});await load();}
  catch(e){if(mounted)setState(()=>message='Change rejected: $e');}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:const Text('Administration & audit')),
  body:ListView(padding:const EdgeInsets.all(16),children:[
   FilledButton.icon(onPressed:loading?null:load,icon:const Icon(Icons.refresh),label:const Text('Load administrator records')),
   if(loading)const LinearProgressIndicator(),
   const SizedBox(height:12),
   const Text('User accounts',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
   ...users.map((item){
    final u=Map<String,dynamic>.from(item as Map),uid='${u['uid']}',disabled=u['disabled']==true;
    return ListTile(title:Text('${u['email']??uid}'),subtitle:Text('Role: ${u['role']??'learner'}'),trailing:TextButton(onPressed:()=>disable(uid,!disabled),child:Text(disabled?'Enable':'Disable')));
   }),
   const Divider(),
   const Text('Recent audit history',style:TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
   ...events.map((item){final e=Map<String,dynamic>.from(item as Map);
    return ListTile(title:Text('${e['action']??'Action'}'),subtitle:Text('${e['actor']??''} • ${e['at']??''}'));
   }),
   Text(message)
  ]),
 );
}
