import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Immersive 3D model view with accessibility-friendly lesson description.
/// The model must be instructor-approved and hosted on an HTTPS endpoint.
class LearningModelViewer extends StatelessWidget{
 final String modelUrl,title,description;
 const LearningModelViewer({super.key,required this.modelUrl,required this.title,required this.description});
 @override
 Widget build(BuildContext context){
  final uri=Uri.tryParse(modelUrl);
  final valid=uri!=null&&uri.scheme=='https'&&uri.userInfo.isEmpty&&uri.path.toLowerCase().endsWith('.glb');
  return Scaffold(appBar:AppBar(title:Text(title)),body:ListView(children:[
   SizedBox(height:400,child:valid?ModelViewer(src:modelUrl,alt:description.isEmpty?title:description,ar:true,autoRotate:false,cameraControls:true,disableZoom:false):const Center(child:Text('The course has no approved 3D model.'))),
   Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:Theme.of(context).textTheme.titleLarge),
    const SizedBox(height:8),
    SelectableText(description.isEmpty?'An accessible text alternative has not yet been supplied.':description),
    const SizedBox(height:8),
    const Text('AR availability depends on your browser and device. Use touch or mouse controls for the 3D alternative.'),
   ])),
  ]));
 }
}
