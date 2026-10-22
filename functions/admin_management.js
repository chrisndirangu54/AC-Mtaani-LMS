const {onCall,HttpsError}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
if(!admin.apps.length)admin.initializeApp();
const db=admin.firestore();
const requireAdmin=r=>{if(!r.auth||r.auth.token.role!=='admin')throw new HttpsError('permission-denied','Admin only');};
const safe=x=>typeof x==='string'&&/^[A-Za-z0-9_-]{1,100}$/.test(x);
exports.adminListUsers=onCall(async r=>{
 requireAdmin(r);
 const limit=Math.max(1,Math.min(50,Number(r.data?.limit)||25));
 const pageToken=r.data?.pageToken;
 const page=await admin.auth().listUsers(limit,typeof pageToken==='string'?pageToken:undefined);
 return {users:page.users.map(u=>({uid:u.uid,email:u.email||null,disabled:u.disabled,role:u.customClaims?.role||'learner',createdAt:u.metadata.creationTime})),nextPageToken:page.pageToken||null};
});
exports.adminSetDisabled=onCall(async r=>{
 requireAdmin(r);
 const uid=r.data?.uid,disabled=r.data?.disabled;
 if(!safe(uid)||typeof disabled!=='boolean'||uid===r.auth.uid)throw new HttpsError('invalid-argument','Invalid account change');
 await admin.auth().updateUser(uid,{disabled});
 await db.collection('auditEvents').add({actor:r.auth.uid,action:disabled?'user_disabled':'user_enabled',target:uid,at:admin.firestore.FieldValue.serverTimestamp()});
 return {uid,disabled};
});
exports.adminAuditTrail=onCall(async r=>{
 requireAdmin(r);
 const snap=await db.collection('auditEvents').orderBy('at','desc').limit(40).get();
 return {events:snap.docs.map(d=>({id:d.id,actor:d.data().actor||'',action:d.data().action||'',target:d.data().target||'',at:d.data().at?.toDate?.()?.toISOString()||null}))};
});
exports.adminRevokeCertificate=onCall(async r=>{
 requireAdmin(r);const id=r.data?.certificateId;
 if(!safe(id))throw new HttpsError('invalid-argument','Invalid certificate');
 const ref=db.doc('certificates/'+id),snap=await ref.get();
 if(!snap.exists)throw new HttpsError('not-found','Certificate missing');
 await ref.update({revoked:true,revokedBy:r.auth.uid,revokedAt:admin.firestore.FieldValue.serverTimestamp()});
 await db.collection('auditEvents').add({actor:r.auth.uid,action:'certificate_revoked',target:id,at:admin.firestore.FieldValue.serverTimestamp()});
 return {revoked:true};
});
