import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

const navy = Color(0xFF0A3161);
const red = Color(0xFFB31942);
const knlsOrange = Color(0xFFF37A00);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MtaaniLmsApp());
}

class MtaaniLmsApp extends StatelessWidget {
  const MtaaniLmsApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'American Corner Mtaani LMS',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: navy), scaffoldBackgroundColor: const Color(0xFFF8FAFC)),
    home: const CourseHome(),
  );
}

class CourseHome extends StatefulWidget {
  const CourseHome({super.key});
  @override
  State<CourseHome> createState() => _CourseHomeState();
}

class _CourseHomeState extends State<CourseHome> {
  String search = '';
  Future<void> signIn() async {
    final email = TextEditingController(), password = TextEditingController();
    final register = ValueNotifier(false);
    try {
      final submit = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: const Text('Free learning account'),
        content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          ValueListenableBuilder<bool>(valueListenable: register, builder: (_, value, __) => SwitchListTile(title: const Text('Create an account'), value: value, onChanged: (v) => register.value = v)),
        ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue'))],
      ));
      if (submit != true) return;
      if (register.value) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
    } finally {
      email.dispose(); password.dispose(); register.dispose();
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy, foregroundColor: Colors.white,
        title: const Text('American Corner Mtaani'),
        actions: [TextButton(onPressed: user == null ? signIn : () async { await FirebaseAuth.instance.signOut(); setState(() {}); }, child: Text(user == null ? 'Sign in' : 'Sign out', style: const TextStyle(color: Colors.white)))],
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(18)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LEARN • INNOVATE • CONNECT', style: TextStyle(color: Color(0xFFFFD8A5))),
            SizedBox(height: 10),
            Text('Your future starts here.', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('100% free courses • Learn at your own pace', style: TextStyle(color: Colors.white)),
          ])),
        const SizedBox(height: 18),
        TextField(decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.search), hintText: 'Search courses'), onChanged: (v) => setState(() => search = v.toLowerCase())),
        const SizedBox(height: 16),
        const Text('Free courses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('courses').where('published', isEqualTo: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Course catalog unavailable. Check Firebase settings.');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.where((d) => '${d.data()['title']} ${d.data()['category']}'.toLowerCase().contains(search)).toList();
            if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No published courses yet.'));
            return Column(children: docs.map((doc) => Card(child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFFE5BD), child: Icon(Icons.school, color: navy)),
              title: Text('${doc.data()['title'] ?? 'Course'}'),
              subtitle: Text('${doc.data()['category'] ?? 'Learning'} • FREE'),
              trailing: const Icon(Icons.chevron_right, color: red),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetails(courseId: doc.id, course: doc.data()))),
            ))).toList());
          },
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: user == null ? signIn : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorScreen())), icon: const Icon(Icons.auto_awesome), label: const Text('Ask the AI tutor')),
        const Divider(color: knlsOrange),
      ]),
    );
  }
}

class CourseDetails extends StatelessWidget {
  final String courseId;
  final Map<String, dynamic> course;
  const CourseDetails({super.key, required this.courseId, required this.course});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('${course['title'] ?? 'Course'}')), body: ListView(padding: const EdgeInsets.all(20), children: [
    Text('${course['description'] ?? ''}'),
    const SizedBox(height: 8),
    const Text('This course is FREE.', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
    FilledButton(onPressed: () async {
      try {
        await FirebaseFunctions.instance.httpsCallable('enrollFree').call({'courseId': courseId});
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrolled for free')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not enroll: $e')));
      }
    }, child: const Text('Enroll for free')),
    const SizedBox(height: 20),
    const Text('Lessons', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('courses').doc(courseId).collection('lessons').orderBy('position').snapshots(), builder: (context, s) {
      if (!s.hasData) return const LinearProgressIndicator();
      return Column(children: s.data!.docs.map((d) => ListTile(title: Text('${d.data()['title'] ?? 'Lesson'}'), subtitle: Text('${d.data()['content'] ?? ''}', maxLines: 3), leading: const Icon(Icons.menu_book))).toList());
    }),
  ]));
}

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});
  @override
  State<TutorScreen> createState() => _TutorScreenState();
}
class _TutorScreenState extends State<TutorScreen> {
  final courseId = TextEditingController(), question = TextEditingController();
  String answer = '';
  bool busy = false;
  @override
  void dispose() { courseId.dispose(); question.dispose(); super.dispose(); }
  Future<void> ask() async {
    setState(() => busy = true);
    try {
      final res = await FirebaseFunctions.instance.httpsCallable('aiTutor').call({'courseId': courseId.text.trim(), 'question': question.text.trim()});
      if (mounted) setState(() => answer = '${res.data['answer']}');
    } catch (e) {
      if (mounted) setState(() => answer = 'Tutor unavailable: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('AI Learning Companion')), body: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Answers use approved published course content; verify important facts with your instructor.'),
    const SizedBox(height: 12),
    TextField(controller: courseId, decoration: const InputDecoration(labelText: 'Course ID', border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: question, maxLines: 3, decoration: const InputDecoration(labelText: 'Your question', border: OutlineInputBorder())),
    const SizedBox(height: 12),
    FilledButton(onPressed: busy ? null : ask, child: Text(busy ? 'Thinking…' : 'Ask AI tutor')),
    const SizedBox(height: 16),
    SelectableText(answer),
  ]));
}
