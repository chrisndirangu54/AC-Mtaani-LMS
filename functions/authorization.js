'use strict';
const {HttpsError}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
if(!admin.apps.length)admin.initializeApp();

/** Fresh authorization checks for privileged operations.
 * Firebase callable auth verifies signature; this checks revocation and the
 * current authoritative custom claims, not merely a potentially stale JWT.
 */
async function requireCurrentRole(request, allowedRoles, {requireRecentLogin=false}={}) {
 if(!request.auth?.uid)throw new HttpsError('unauthenticated','Authentication required');
 let user;
 try{user=await admin.auth().getUser(request.auth.uid);}
 catch(err){throw new HttpsError('unauthenticated','Account not available');}
 if(user.disabled)throw new HttpsError('permission-denied','Account disabled');
 const role=user.customClaims?.role ?? 'learner';
 if(!allowedRoles.includes(role))throw new HttpsError('permission-denied','Insufficient privileges');
 const issued=Number(request.auth.token.iat);
 const validAfter=Date.parse(user.tokensValidAfterTime??'1970-01-01T00:00:00Z')/1000;
 if(!Number.isFinite(issued)||issued<validAfter)throw new HttpsError('unauthenticated','Session revoked; sign in again');
 if(requireRecentLogin){
  const authTime=Number(request.auth.token.auth_time);
  if(!Number.isFinite(authTime)||Date.now()/1000-authTime>15*60)
   throw new HttpsError('unauthenticated','Recent sign-in required');
 }
 return {uid:user.uid,role,user};
}
module.exports={requireCurrentRole};
