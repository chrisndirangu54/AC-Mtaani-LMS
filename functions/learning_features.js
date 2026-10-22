const {onCall,HttpsError}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
if(!admin.apps.length)admin.initializeApp();
const db=admin.firestore();
const requireUid=r=>{if(!r.auth)throw new HttpsError('unauthenticated','Sign in to continue');return r.auth.uid;};
const requireStaff=r=>{requireUid(r);if(!['admin','instructor'].includes(r.auth.token.role))throw new HttpsError('permission-denied','Staff only');};
exports.completeQuest=onCall(async r=>{
 const uid=requireUid(r),questId=String(r.data?.questId||'');
 if(!/^[a-zA-Z0-9_-]{1,100}$/.test(questId))throw new HttpsError('invalid-argument','Invalid quest');
 const quest=db.doc('quests/'+questId),profile=db.doc('learningProfiles/'+uid),completion=db.doc('learningProfiles/'+uid+'/completions/'+questId);
 return db.runTransaction(async tx=>{
  const [q,c,p]=await Promise.all([tx.get(quest),tx.get(completion),tx.get(profile)]);
  if(!q.exists||q.data().published!==true)throw new HttpsError('not-found','Quest not available');
  if(c.exists)return {xpAwarded:0,alreadyCompleted:true};
  // XP is only awarded for quests which explicitly allow self-verification.
  // Assessed activities must use a separate instructor-approved completion path.
  if(q.data().verification!=='self')throw new HttpsError('failed-precondition','Instructor verification required');
  const xp=Math.max(0,Math.min(50,Number(q.data().xp)||0)),total=(p.data()?.xp||0)+xp;
  tx.create(completion,{questId,xp,createdAt:admin.firestore.FieldValue.serverTimestamp()});
  tx.set(profile,{xp:total,level:Math.floor(total/500)+1,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  return {xpAwarded:xp,totalXp:total};
 });
});
exports.submitLearningEvidence=onCall(async r=>{
 const uid=requireUid(r),activityId=String(r.data?.activityId||''),text=String(r.data?.evidence||'').trim();
 if(!/^[a-zA-Z0-9_-]{1,100}$/.test(activityId)||text.length<20||text.length>4000)throw new HttpsError('invalid-argument','Evidence must be 20-4000 characters');
 const ref=await db.collection('submissions').add({activityId,uid,evidence:text,status:'pending',createdAt:admin.firestore.FieldValue.serverTimestamp()});
 return {submissionId:ref.id,status:'pending'};
});
exports.reviewLearningEvidence=onCall(async r=>{
 requireStaff(r);const id=String(r.data?.submissionId||''),approve=r.data?.approved===true;
 const ref=db.doc('submissions/'+id),snap=await ref.get();
 if(!snap.exists)throw new HttpsError('not-found','Submission not found');
 await ref.update({status:approve?'approved':'rejected',reviewedBy:r.auth.uid,reviewedAt:admin.firestore.FieldValue.serverTimestamp(),feedback:String(r.data?.feedback||'').slice(0,1200)});
 return {status:approve?'approved':'rejected'};
});
exports.addHubContent=onCall(async r=>{
 requireStaff(r);
 const allowed=['quests','practice','labs','portfolios','communities','careers','resources','challenges','equipment','experiences','opportunities','sessions'];
 const collection=String(r.data?.collection||''),title=String(r.data?.title||'').trim(),description=String(r.data?.description||'').trim();
 if(!allowed.includes(collection)||title.length<3||title.length>150)throw new HttpsError('invalid-argument','Invalid content');
 const doc=await db.collection(collection).add({title,description:description.slice(0,2000),content:String(r.data?.content||'').slice(0,18000),published:false,createdBy:r.auth.uid,createdAt:admin.firestore.FieldValue.serverTimestamp()});
 return {id:doc.id};
});
exports.publishHubContent=onCall(async r=>{
 requireStaff(r);
 const allowed=['quests','practice','labs','portfolios','communities','careers','resources','challenges','equipment','experiences','opportunities','sessions'];
 const collection=String(r.data?.collection||''),id=String(r.data?.id||'');
 if(!allowed.includes(collection)||!/^[a-zA-Z0-9_-]{1,100}$/.test(id))throw new HttpsError('invalid-argument','Invalid document');
 const doc=db.doc(collection+'/'+id),snap=await doc.get();if(!snap.exists)throw new HttpsError('not-found','Item missing');
 if(r.auth.token.role!=='admin'&&snap.data().createdBy!==r.auth.uid)throw new HttpsError('permission-denied','Not owner');
 await doc.update({published:true,approvedBy:r.auth.uid,approvedAt:admin.firestore.FieldValue.serverTimestamp()});
 return {published:true};
});
