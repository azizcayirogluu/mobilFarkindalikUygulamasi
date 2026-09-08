const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const https = require('https');

initializeApp({ projectId: 'tubitak-akran-zorbaligi' });
const db = getFirestore();
const auth = getAuth();

const API_KEY = process.env.FIREBASE_WEB_API_KEY;
const FUNCTION_URL = 'https://europe-west1-tubitak-akran-zorbaligi.cloudfunctions.net/deleteSelfAccount';

if (!API_KEY) {
    throw new Error('FIREBASE_WEB_API_KEY environment variable is required.');
}

async function exchangeCustomToken(customToken) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({ token: customToken, returnSecureToken: true });
        const req = https.request('https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=' + API_KEY, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Content-Length': data.length }
        }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => resolve(JSON.parse(body).idToken));
        });
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function callFunction(idToken) {
    return new Promise((resolve, reject) => {
        const data = JSON.stringify({ data: {} });
        const req = https.request(FUNCTION_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + idToken,
                'Content-Length': data.length
            }
        }, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
        });
        req.on('error', reject);
        req.write(data);
        req.end();
    });
}

async function run() {
    console.log('Creating test user...');
    const userRecord = await auth.createUser({ email: 'test_delete_prod_' + Date.now() + '@example.com', password: 'password123' });
    const uid = userRecord.uid;
    console.log('Test UID:', uid);
    
    console.log('Populating Firestore...');
    await db.collection('users').doc(uid).set({ test: true });
    await db.collection('usersProgress').doc(uid).set({ test: true });
    for (let i = 0; i < 3; i++) {
        await db.collection('reports').add({ gonderenUid: uid, test: true });
    }
    
    console.log('Minting token...');
    const customToken = await auth.createCustomToken(uid);
    const idToken = await exchangeCustomToken(customToken);
    
    console.log('Calling deleteSelfAccount...');
    const res1 = await callFunction(idToken);
    console.log('Function response 1:', res1);
    
    console.log('Calling deleteSelfAccount (Idempotency check)...');
    const res2 = await callFunction(idToken);
    console.log('Function response 2:', res2);
    
    console.log('Verifying Auth...');
    try {
        await auth.getUser(uid);
        console.log('Auth exists: true');
    } catch (e) {
        console.log('Auth exists: false (' + e.code + ')');
    }
    
    console.log('Verifying Firestore...');
    const userDoc = await db.collection('users').doc(uid).get();
    console.log('users doc exists:', userDoc.exists);
    const progressDoc = await db.collection('usersProgress').doc(uid).get();
    console.log('usersProgress doc exists:', progressDoc.exists);
    const reports = await db.collection('reports').where('gonderenUid', '==', uid).get();
    console.log('reports count:', reports.size);
    
    console.log('Cleanup just in case...');
    if (userDoc.exists) await db.collection('users').doc(uid).delete();
    if (progressDoc.exists) await db.collection('usersProgress').doc(uid).delete();
    for (const doc of reports.docs) await doc.ref.delete();
    try { await auth.deleteUser(uid); } catch (e) {}
}

run().catch(console.error);
