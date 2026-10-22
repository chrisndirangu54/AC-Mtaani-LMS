import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Uses the open-source glTF viewer. Model URLs must be curated and hosted
/// under a school-controlled asset origin; do not accept arbitrary learner URLs.
class ImmersiveLesson extends StatelessWidget {
 final String title;
 final String modelUrl;
 final String? description;
 final String? accessibleAlternativeUrl;
 const ImmersiveLesson({super.key,required this.title,required this.modelUrl,this.description,this.accessibleAlternativeUrl});
 @override Widget build(BuildContext context) {
  final uri=Uri.tryParse(modelUrl);
  final valid=uri!=null && uri.scheme=='https' &&
     uri.userInfo.isEmpty && (uri.path.toLowerCase().endsWith('.glb')||uri.path.toLowerCase().endsWith('.gltf'));
  return Scaffold(
   appBar:AppBar(title:Text(title)),
   body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Interactive 3D laboratory',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const SizedBox(height:8),
    if(description!=null) SelectableText(description!),
    const SizedBox(height:12),
    if(valid) SizedBox(height:420,child:ModelViewer(src:modelUrl,alt:'Interactive 3D model: $title',ar:true,autoRotate:false,cameraControls:true))
    else const Text('This learning experience requires an approved HTTPS GLB/glTF model.'),
    const SizedBox(height:12),
    const Text('Use touch or pointer gestures to inspect the model. AR mode requires a compatible device. Reduced-motion mode is the default.'),
    if(accessibleAlternativeUrl!=null) SelectableText('Accessible 2D alternative: $accessibleAlternativeUrl'),
   ]),
  );
 }
}
