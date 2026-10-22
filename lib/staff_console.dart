import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Instructor/admin console. Writes are mediated by callable Functions.
class StaffConsole extends StatefulWidget {
 const StaffConsole({super.key});
 @override State<StaffConsole> createState()=>_StaffConsoleState();
}
class _StaffConsoleState extends State<StaffConsole> {
 final title=TextEditingController(), description=TextEditingController(), body=TextEditingController();
 String collection='resources',result='';
 bool working=false;
 static const sections=['quests','practice','labs','portfolios','communities','careers','resources','challenges','equipment','experiences','opportunities','sessions'];
 @override void dispose(){title.dispose();description.dispose();body.dispose();super.dispose();}
 Future<void> call(String function,Map<String,dynamic> data) async{
  setState(()=>working=true);
  try{final r=await FirebaseFunctions.instance.httpsCallable(function).call(data);
   if(mounted)setState(()=>result='Saved: ${r.data}');}
  catch(e){if(mounted)setState(()=>result='Operation failed: $e');}
  finally{if(mounted)setState(()=>working=false);}
 }
 @override Widget build(BuildContext context){
 final u=FirebaseAuth.instance.currentUser;
 if(u==null)return const Scaffold(body:Center(child:Text('Staff sign-in required.')));
 return Scaffold(appBar:AppBar(title:const Text('Instructor & Admin Studio')),body:FutureBuilder<IdTokenResult>(
 future:u.getIdTokenResult(),builder:(context,s){
 final role=s.data?.claims?['role'];
 if(!['admin','instructor'].contains(role))return const Center(child:Text('Staff access requires an administrator-issued role claim.'));
 return ListView(padding:const EdgeInsets.all(18),children:[
  Text('Staff role: $role',style:Theme.of(context).textTheme.titleLarge),
  const SizedBox(height:12),
  DropdownButtonFormField<String>(value:collection,decoration:const InputDecoration(labelText:'Module'),items:sections.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>collection=v??collection)),
  TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),
  TextField(controller:description,decoration:const InputDecoration(labelText:'Description'),maxLines:2),
  TextField(controller:body,decoration:const InputDecoration(labelText:'Approved educational content'),maxLines:5),
  const SizedBox(height:10),
  FilledButton(onPressed:working?null:()=>call('addHubContent',{'collection':collection,'title':title.text,'description':description.text,'content':body.text}),child:const Text('Create draft')),
  const Divider(),
  const Text('Publish reviewed drafts',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection(collection).where('published',isEqualTo:false).limit(25).snapshots(),builder:(context,s){
   if(s.hasError)return const Text('Unable to load drafts; verify access.');
   if(!s.hasData)return const LinearProgressIndicator();
   return Column(children:s.data!.docs.map((d)=>ListTile(title:Text('${d.data()['title']}'),subtitle:Text(d.id),trailing:TextButton(onPressed:working?null:()=>call('publishHubContent',{'collection':collection,'id':d.id}),child:const Text('Publish')))).toList());
  }),
  const Divider(),
  const Text('Evidence awaiting review',style:TextStyle(fontSize:17,fontWeight:FontWeight.bold)),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('submissions').where('status',isEqualTo:'pending').limit(25).snapshots(),builder:(context,s){
   if(s.hasError)return const Text('Evidence list not available.');
   if(!s.hasData)return const LinearProgressIndicator();
   return Column(children:s.data!.docs.map((d)=>Card(child:ListTile(title:Text('${d.data()['activityId']}'),subtitle:Text('${d.data()['evidence']}',maxLines:3),trailing:Wrap(children:[
    IconButton(tooltip:'Approve',icon:const Icon(Icons.check),onPressed:working?null:()=>call('reviewLearningEvidence',{'submissionId':d.id,'approved':true})),
    IconButton(tooltip:'Reject',icon:const Icon(Icons.close),onPressed:working?null:()=>call('reviewLearningEvidence',{'submissionId':d.id,'approved':false}))
   ])))).toList());
  }),
  SelectableText(result)
 ]);
 }));
 }
}
