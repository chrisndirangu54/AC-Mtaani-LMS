const {onCall,HttpsError}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');const crypto=require('node:crypto');
if(!admin.apps.length)admin.initializeApp();const db=admin.firestore();
const auth=r=>{if(!r.auth)throw new HttpsError('unauthenticated','Sign in');return r.auth.uid;};
const staff=r=>{auth(r);if(!['admin','instructor'].includes(r.auth.token.role))throw new HttpsError('permission-denied','Staff only');};
const adminOnly=r=>{auth(r);if(r.auth.token.role!=='admin')throw new HttpsError('permission-denied','Admin only');};
const valid=x=>typeof x==='string'&&/^[A-Za-z0-9_-]{1,100}$/.test(x);
const audit=async(uid,action,target,details={})=>db.collection('auditEvents').add({actor:uid,action,target,details,at:admin.firestore.FieldValue.serverTimestamp()});
exports.requestLabRun=onCall(async r=>{
 const uid=auth(r),{labId,source,language}=r.data||{};
 if(!valid(labId)||typeof source!=='string'||source.length>16000||!['python','javascript','sql'].includes(language))throw new HttpsError('invalid-argument','Invalid lab request');
 const lab=await db.doc('labs/'+labId).get();
 if(!lab.exists||lab.data().published!==true)throw new HttpsError('not-found','Lab not published');
 const day=new Date().toISOString().slice(0,10);
 const usage=db.doc('labUsage/'+uid+'_'+day);
 const quota=await db.runTransaction(async tx=>{
  const current=await tx.get(usage);const count=current.exists?Number(current.data().count||0):0;
  if(count>=30)throw new HttpsError('resource-exhausted','Daily lab run quota reached');
  tx.set(usage,{uid,day,count:count+1},{merge:true});
  return count+1;
 });
 const job=await db.collection('labJobs').add({uid,labId,language,source,status:'queued',quotaOrdinal:quota,createdAt:admin.firestore.FieldValue.serverTimestamp(),expiresAt:admin.firestore.Timestamp.fromMillis(Date.now()+3600000)});
 // An external isolated worker must claim and execute jobs with trusted service credentials.
 // No source execution occurs inside Firebase Functions.
 return {jobId:job.id,status:'queued'};
});
exports.getMyLabRun=onCall(async r=>{
 const uid=auth(r),id=r.data?.jobId;if(!valid(id))throw new HttpsError('invalid-argument','Invalid job');
 const snap=await db.doc('labJobs/'+id).get();
 if(!snap.exists||snap.data().uid!==uid)throw new HttpsError('not-found','Job unavailable');
 const {status,stdout='',stderr='',exitCode=null}=snap.data();
 return {status,stdout:String(stdout).slice(0,8000),stderr:String(stderr).slice(0,2000),exitCode};
});
exports.putSyncOperation=onCall(async r=>{
 const uid=auth(r),data=r.data||{};
 if(!valid(data.operationId)||!valid(data.courseId)||!valid(data.lessonId)||data.action!=='mark_read')throw new HttpsError('invalid-argument','Invalid offline operation');
 const op=db.doc('users/'+uid+'/syncOperations/'+data.operationId);
 const result=await db.runTransaction(async tx=>{
  const old=await tx.get(op);if(old.exists)return {duplicate:true};
  const enrollment=await tx.get(db.doc('users/'+uid+'/enrollments/'+data.courseId));
  if(!enrollment.exists)throw new HttpsError('failed-precondition','Enroll first');
  const lesson=await tx.get(db.doc('courses/'+data.courseId+'/lessons/'+data.lessonId));
  if(!lesson.exists)throw new HttpsError('not-found','Lesson unavailable');
  tx.create(op,{...{courseId:data.courseId,lessonId:data.lessonId,action:'mark_read'},createdAt:admin.firestore.FieldValue.serverTimestamp()});
  tx.set(db.doc('users/'+uid+'/lessonReads/'+data.courseId+'_'+data.lessonId),{courseId:data.courseId,lessonId:data.lessonId,lastReadAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  return {duplicate:false};
 });
 return {accepted:true,...result};
});
exports.bookMakerspace=onCall(async r=>{
 const uid=auth(r),{equipmentId,slotId}=r.data||{};
 if(!valid(equipmentId)||!valid(slotId))throw new HttpsError('invalid-argument','Invalid booking');
 const slot=db.doc('equipment/'+equipmentId+'/slots/'+slotId);
 return db.runTransaction(async tx=>{
  const s=await tx.get(slot);if(!s.exists||s.data().disabled)throw new HttpsError('not-found','Unavailable slot');
  const booked=Number(s.data().booked||0),capacity=Number(s.data().capacity||0);
  if(capacity<1||booked>=capacity)throw new HttpsError('resource-exhausted','Slot is full');
  const booking=db.doc('users/'+uid+'/bookings/'+equipmentId+'_'+slotId);
  const prior=await tx.get(booking);if(prior.exists)return {booked:true,existing:true};
  tx.update(slot,{booked:booked+1});
  tx.create(booking,{equipmentId,slotId,createdAt:admin.firestore.FieldValue.serverTimestamp()});
  return {booked:true,existing:false};
 });
});
exports.setInstitutionalRole=onCall(async r=>{
 adminOnly(r);
 const uid=String(r.data?.uid||''),role=String(r.data?.role||'');
 if(!valid(uid)||!['learner','instructor','admin'].includes(role)||uid===r.auth.uid)throw new HttpsError('invalid-argument','Invalid role change');
 const user=await admin.auth().getUser(uid);
 await admin.auth().setCustomUserClaims(uid,{...user.customClaims,role});
 await admin.auth().revokeRefreshTokens(uid);
 await audit(r.auth.uid,'role_changed',uid,{role});
 return {uid,role,requiresTokenRefresh:true};
});
exports.updateModeration=onCall(async r=>{
 staff(r);const {itemId,action}=r.data||{};
 if(!valid(itemId)||!['approve','reject','hide'].includes(action))throw new HttpsError('invalid-argument','Invalid moderation action');
 const ref=db.doc('moderationQueue/'+itemId),snap=await ref.get();
 if(!snap.exists)throw new HttpsError('not-found','Item missing');
 await ref.update({status:action,reviewer:r.auth.uid,updatedAt:admin.firestore.FieldValue.serverTimestamp()});
 await audit(r.auth.uid,'moderation_'+action,itemId);
 return {status:action};
});
exports.getCourseAnalytics=onCall(async r=>{
 staff(r);const cid=r.data?.courseId;if(!valid(cid))throw new HttpsError('invalid-argument','Course ID required');
 const course=await db.doc('courses/'+cid).get();if(!course.exists)throw new HttpsError('not-found','Unknown course');
 if(r.auth.token.role!=='admin'&&course.data().createdBy!==r.auth.uid)throw new HttpsError('permission-denied','Course ownership required');
 const enrolled=await db.collectionGroup('enrollments').where('courseId','==',cid).count().get();
 return {courseId:cid,enrollments:enrolled.data().count,note:'Aggregated enrollment count; requires Firestore collection group index'};
});
