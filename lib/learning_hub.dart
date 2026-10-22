import 'package:flutter/material.dart';
import 'staff_console.dart';
import 'offline_learning.dart';
import 'advanced_studio.dart';
import 'operations_console.dart';
import 'learning_model_viewer.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _navy=Color(0xFF0A3161), _red=Color(0xFFB31942), _orange=Color(0xFFF58220);
const modules=<({String name,String subtitle,IconData icon,String collection})>[
 (name:'Learning quests',subtitle:'Mission paths, XP, badges and mastery challenges',icon:Icons.emoji_events,collection:'quests'),
 (name:'Adaptive practice',subtitle:'Knowledge checks, flashcards and spaced repetition',icon:Icons.psychology,collection:'practice'),
 (name:'Interactive laboratories',subtitle:'Coding, SQL, simulations and approved H5P activities',icon:Icons.science,collection:'labs'),
 (name:'Skills Passport',subtitle:'Projects, evidence and verified competencies',icon:Icons.workspace_premium,collection:'portfolios'),
 (name:'Mentors & community',subtitle:'Study circles, mentor sessions and moderated challenges',icon:Icons.groups,collection:'communities'),
 (name:'Career studio',subtitle:'CV workshops, interview practice and career pathways',icon:Icons.work,collection:'careers'),
 (name:'Digital library',subtitle:'Instructor-reviewed resources and reading lists',icon:Icons.local_library,collection:'resources'),
 (name:'Innovation hub',subtitle:'Hackathons, robotics and startup projects',icon:Icons.rocket_launch,collection:'challenges'),
 (name:'Maker space',subtitle:'VR, 3D printing and workshop booking requests',icon:Icons.precision_manufacturing,collection:'equipment'),
 (name:'Learning experiences',subtitle:'3D/AR resources and 2D accessible alternatives',icon:Icons.view_in_ar,collection:'experiences'),
 (name:'Opportunities',subtitle:'Scholarships, exchanges and free events',icon:Icons.public,collection:'opportunities'),
 (name:'Live learning',subtitle:'Mentor office hours and workshop schedules',icon:Icons.video_call,collection:'sessions'),
];
class LearningHub extends StatelessWidget {
 const LearningHub({super.key});
 @override Widget build(BuildContext context)=>Scaffold(
 appBar:AppBar(title:const Text('Mtaani Learning Hub'),backgroundColor:_navy,foregroundColor:Colors.white,actions:[IconButton(tooltip:'Operations',icon:const Icon(Icons.terminal),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OperationsConsole()))),IconButton(tooltip:'Advanced learning',icon:const Icon(Icons.workspace_premium),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdvancedLearningStudio()))),IconButton(tooltip:'Staff studio',icon:const Icon(Icons.admin_panel_settings),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const StaffConsole()))) ]),
 body:ListView(padding:const EdgeInsets.all(16),children:[
  Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_navy,borderRadius:BorderRadius.circular(20)),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text('LEARN • CREATE • CONNECT',style:TextStyle(color:_orange,fontWeight:FontWeight.bold)),
   SizedBox(height:8),Text('Explore. Build. Grow.',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.bold)),
   SizedBox(height:4),Text('Everything here is free.',style:TextStyle(color:Colors.white70))])),
  const SizedBox(height:20),
  StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:FirebaseAuth.instance.currentUser==null?null:FirebaseFirestore.instance.doc('learningProfiles/${FirebaseAuth.instance.currentUser!.uid}').snapshots(),builder:(context,s){
    final d=s.data?.data()??{};return Card(child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[
      const Icon(Icons.stars,color:_orange),const SizedBox(width:12),
      Expanded(child:Text('Level ${d['level']??1} • ${d['xp']??0} XP',style:const TextStyle(fontWeight:FontWeight.bold))),
      const Text('Free learner account',style:TextStyle(color:_red,fontSize:12)),
    ])));}),
  const Text('Learning experiences',style:TextStyle(fontWeight:FontWeight.bold,fontSize:22)),
  const SizedBox(height:10),
  LayoutBuilder(builder:(context,c)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
    gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:c.maxWidth>750?3:c.maxWidth>450?2:1,childAspectRatio:c.maxWidth>450?1.5:3.4,crossAxisSpacing:10,mainAxisSpacing:10),
    itemCount:modules.length,itemBuilder:(context,i){final m=modules[i];return Card(clipBehavior:Clip.antiAlias,child:InkWell(
     onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>HubCollectionScreen(title:m.name,collection:m.collection))),
     child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(m.icon,color:i.isEven?_navy:_red),const SizedBox(height:7),Text(m.name,maxLines:1,style:const TextStyle(fontWeight:FontWeight.bold)),
      const SizedBox(height:3),Text(m.subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12))
     ]))));})),
 ]));
}
class HubCollectionScreen extends StatelessWidget {
 final String title, collection;
 const HubCollectionScreen({super.key,required this.title,required this.collection});
 @override
 Widget build(BuildContext context) {
  return Scaffold(
   appBar: AppBar(title: Text(title)),
   body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection(collection).where('published',isEqualTo:true).limit(30).snapshots(),
    builder: (context,snapshot) {
     if(snapshot.hasError) return const Center(child:Text('Content unavailable.'));
     if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
     final docs=snapshot.data!.docs;
     if(docs.isEmpty) return const Center(child:Text('Approved learning activities will appear here.'));
     return ListView.builder(
      itemCount:docs.length,
      itemBuilder:(context,index) {
       final data=docs[index].data();
       return Card(child:ListTile(
        title:Text('${data['title']??'Activity'}'),
        subtitle:Text('${data['description']??''}',maxLines:3),
        onTap:()=>showDialog<void>(
         context:context,
         builder:(dialogContext)=>AlertDialog(
          title:Text('${data['title']??'Activity'}'),
          content:SingleChildScrollView(child:SelectableText('${data['content']??data['description']??''}')),
          actions:[
           if(collection=='experiences' && data['modelUrl'] is String) TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LearningModelViewer(modelUrl:data['modelUrl'] as String,title:'${data['title']??'3D lesson'}',description:'${data['description']??''}'))),child:const Text('Explore in 3D')),
           if(data['url'] is String) TextButton(onPressed:()=>openApprovedLearningLink(data['url'] as String),child:const Text('Open activity')),
           TextButton(onPressed:()=>Navigator.pop(dialogContext),child:const Text('Close')),
          ],
         ),
        ),
       ));
      },
     );
    },
   ),
  );
 }
}
class ActivityCompletionButton extends StatefulWidget{
 final String questId;
 const ActivityCompletionButton({super.key,required this.questId});
 @override State<ActivityCompletionButton> createState()=>_ActivityCompletionButtonState();
}
class _ActivityCompletionButtonState extends State<ActivityCompletionButton>{
 bool busy=false;
 @override Widget build(BuildContext context)=>FilledButton.icon(
  onPressed:busy?null:()async{setState(()=>busy=true);try{
   final response=await FirebaseFunctions.instance.httpsCallable('completeQuest').call({'questId':widget.questId});
   if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Quest recorded: ${response.data['xpAwarded']??0} XP')));
  }catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Cannot record quest: $e')));}
  finally{if(mounted)setState(()=>busy=false);}},
  icon:const Icon(Icons.check_circle_outline),label:Text(busy?'Saving…':'Record verified completion'));
}
