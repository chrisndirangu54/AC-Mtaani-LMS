// SOTA backend foundations: strict authentication, restricted data collection,
// certificate signatures, classroom tokens (external provider must be configured).
const {onCall,HttpsError}=require('firebase-functions/v2/https');
const {defineSecret}=require('firebase-functions/params');
const admin=require('firebase-admin');
const crypto=require('node:crypto');
const {PDFDocument,StandardFonts,rgb}=require('pdf-lib');
if(!admin.apps.length)admin.initializeApp();
const db=admin.firestore();
const signingKey=defineSecret('CERTIFICATE_SIGNING_KEY');
function requireUser(r){if(!r.auth)throw new HttpsError('unauthenticated','Sign in first');return r.auth.uid;}
function requireAdmin(r){requireUser(r);if(r.auth.token.role!=='admin')throw new HttpsError('permission-denied','Admin only');}
function requireStaff(r){requireUser(r);if(!['admin','instructor'].includes(r.auth.token.role))throw new HttpsError('permission-denied','Staff only');}
const id=s=>typeof s==='string'&&/^[A-Za-z0-9_-]{1,100}$/.test(s);
exports.requestCertificate=onCall({secrets:[signingKey]},async r=>{
 const uid=requireUser(r),courseId=r.data?.courseId;
 if(!id(courseId))throw new HttpsError('invalid-argument','Invalid course');
 const course=await db.doc('courses/'+courseId).get();
 if(!course.exists||!course.data().published)throw new HttpsError('not-found','Course unavailable');
 const required=await course.ref.collection('lessons').get();
 const completed=await db.doc('users/'+uid+'/enrollments/'+courseId).get();
 // Do not issue certificates from client-maintained counters or claimed scores.
 // Completion must be audited and approved by trusted grading pipeline.
 if(!completed.exists||completed.data().verifiedComplete!==true||completed.data().approvedByStaff!==true)
  throw new HttpsError('failed-precondition','Verified staff-approved completion required');
 const certificateId=crypto.createHash('sha256').update(uid+':'+courseId).digest('hex').slice(0,32);
 const payload={certificateId,uid,courseId,courseTitle:String(course.data().title||''),issuedAt:new Date().toISOString(),schema:1};
 const proof=crypto.createHmac('sha256',signingKey.value()).update(JSON.stringify(payload)).digest('hex');
 await db.doc('certificates/'+certificateId).set({...payload,proof,revoked:false,requiredLessonCount:required.size},{merge:false});
 const pdf=await PDFDocument.create();
 const page=pdf.addPage([842,595]);
 const bold=await pdf.embedFont(StandardFonts.HelveticaBold);
 const normal=await pdf.embedFont(StandardFonts.Helvetica);
 page.drawRectangle({x:0,y:0,width:842,height:595,color:rgb(0.035,0.192,0.38)});
 page.drawRectangle({x:30,y:30,width:782,height:535,borderColor:rgb(0.97,0.51,0.13),borderWidth:5});
 page.drawText('AMERICAN CORNER MTAANI',{x:185,y:480,size:28,font:bold,color:rgb(1,1,1)});
 page.drawText('CERTIFICATE OF COMPLETION',{x:170,y:390,size:30,font:bold,color:rgb(1,1,1)});
 page.drawText('Course: '+payload.courseTitle.slice(0,65),{x:125,y:315,size:17,font:normal,color:rgb(1,1,1)});
 page.drawText('Issued: '+payload.issuedAt.slice(0,10),{x:125,y:265,size:16,font:normal,color:rgb(1,1,1)});
 page.drawText('Verification ID: '+certificateId,{x:125,y:170,size:12,font:normal,color:rgb(1,1,1)});
 page.drawText('Verify via the LMS; this is not an Embassy-accredited qualification.',{x:125,y:120,size:11,font:normal,color:rgb(1,1,1)});
 return {certificateId,pdfBase64:Buffer.from(await pdf.save()).toString('base64'),verificationPath:'/verify/'+certificateId};
});
exports.verifyCertificate=onCall({secrets:[signingKey]},async r=>{
 const certId=r.data?.certificateId;
 if(!id(certId))throw new HttpsError('invalid-argument','Invalid certificate');
 const doc=await db.doc('certificates/'+certId).get();
 if(!doc.exists||doc.data().revoked)return {valid:false};
 const d=doc.data();
 const signedPayload={certificateId:d.certificateId,uid:d.uid,courseId:d.courseId,courseTitle:d.courseTitle,issuedAt:d.issuedAt,schema:d.schema};
 const expected=crypto.createHmac('sha256',signingKey.value()).update(JSON.stringify(signedPayload)).digest('hex');
 if(typeof d.proof!=='string'||!(/^[a-f0-9]{64}$/.test(d.proof))||!crypto.timingSafeEqual(Buffer.from(expected,'hex'),Buffer.from(d.proof,'hex')))return {valid:false};
 // Public lookup intentionally returns minimal data: never expose learner UID.
 return {valid:true,certificateId:certId,courseTitle:d.courseTitle,issuedAt:d.issuedAt};
});
exports.getDashboardMetrics=onCall(async r=>{
 requireAdmin(r);
 const names=['courses','certificates','submissions','sessions','quests'];
 const out={};
 for(const name of names){const snap=await db.collection(name).count().get();out[name]=snap.data().count;}
 return {counts:out,generatedAt:new Date().toISOString(),note:'Aggregate totals; not unique active learners or outcomes'};
});
exports.createLiveSession=onCall(async r=>{
 requireStaff(r);
 const {courseId,title,url,scheduledAt}=r.data||{};
 if(!id(courseId)||typeof title!=='string'||title.length<3||typeof url!=='string')throw new HttpsError('invalid-argument','Invalid session');
 const link=new URL(url);
 if(link.protocol!=='https:'||!['meet.google.com','zoom.us','us06web.zoom.us','meet.jit.si'].includes(link.hostname))
  throw new HttpsError('invalid-argument','Use an approved meeting host');
 const ts=Date.parse(scheduledAt);
 if(!Number.isFinite(ts)||ts<Date.now())throw new HttpsError('invalid-argument','Schedule in the future');
 const course=await db.doc('courses/'+courseId).get();
 if(!course.exists)throw new HttpsError('not-found','Course not found');
 const ref=await db.collection('sessions').add({courseId,title:title.slice(0,140),url,scheduledAt:new Date(ts).toISOString(),published:true,createdBy:r.auth.uid});
 return {sessionId:ref.id};
});
exports.reviewCompletion=onCall(async r=>{
 requireStaff(r);const {uid,courseId,approved}=r.data||{};
 if(!id(uid)||!id(courseId)||typeof approved!=='boolean')throw new HttpsError('invalid-argument','Invalid review');
 const enroll=db.doc('users/'+uid+'/enrollments/'+courseId);
 const snapshot=await enroll.get();if(!snapshot.exists)throw new HttpsError('not-found','Enrollment missing');
 // Manual staff approval is recorded distinctly from server-verified completion.
 // Completion verification must be produced by an independent grading pipeline.
 await enroll.update({approvedByStaff:approved,reviewedBy:r.auth.uid,reviewedAt:admin.firestore.FieldValue.serverTimestamp()});
 return {approved};
});
