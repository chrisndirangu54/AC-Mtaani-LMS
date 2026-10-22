const {onCall,HttpsError}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
if(!admin.apps.length)admin.initializeApp();
const db=admin.firestore();
const valid=x=>typeof x==='string'&&/^[a-zA-Z0-9_-]{1,100}$/.test(x);
const staff=r=>{if(!r.auth||!['admin','instructor'].includes(r.auth.token.role))throw new HttpsError('permission-denied','Staff role required');};
exports.finalizeCourseCompletion=onCall(async r=>{
 staff(r);
 const {uid,courseId}=r.data||{};
 if(!valid(uid)||!valid(courseId))throw new HttpsError('invalid-argument','Bad learner or course');
 const course=await db.doc('courses/'+courseId).get();
 if(!course.exists)throw new HttpsError('not-found','Course missing');
 if(r.auth.token.role!=='admin'&&course.data().createdBy!==r.auth.uid)throw new HttpsError('permission-denied','Not course instructor');
 const enrollment=db.doc('users/'+uid+'/enrollments/'+courseId);
 const enrolled=await enrollment.get();
 if(!enrolled.exists)throw new HttpsError('not-found','Enrollment missing');
 const lessons=await course.ref.collection('lessons').get();
 if(lessons.empty)throw new HttpsError('failed-precondition','No lessons published');
 const readDocs=await db.collection('users/'+uid+'/lessonReads').where('courseId','==',courseId).get();
 const readIds=new Set(readDocs.docs.map(d=>d.data().lessonId));
 if(lessons.docs.some(d=>!readIds.has(d.id)))throw new HttpsError('failed-precondition','Missing lesson completion evidence');
 // Require staff to approve independently; recorded lesson reads alone are
 // insufficient for competency credentialing.
 if(enrolled.data().approvedByStaff!==true)throw new HttpsError('failed-precondition','Staff approval required');
 await enrollment.update({verifiedComplete:true,verifiedBy:r.auth.uid,verifiedAt:admin.firestore.FieldValue.serverTimestamp(),verifiedLessonCount:lessons.size});
 await db.collection('auditEvents').add({actor:r.auth.uid,action:'completion_finalized',uid,courseId,at:admin.firestore.FieldValue.serverTimestamp()});
 return {verifiedComplete:true,lessonCount:lessons.size};
});
