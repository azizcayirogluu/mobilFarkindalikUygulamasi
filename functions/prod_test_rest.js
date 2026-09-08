const https = require('https');

const API_KEY = process.env.FIREBASE_WEB_API_KEY;
const PROJECT_ID = 'tubitak-akran-zorbaligi';
const FUNCTION_URL = 'https://europe-west1-tubitak-akran-zorbaligi.cloudfunctions.net/deleteSelfAccount';

if (!API_KEY) {
    throw new Error('FIREBASE_WEB_API_KEY environment variable is required.');
}

function request(url, method, data, headers = {}) {
    return new Promise((resolve, reject) => {
        const parsedUrl = new URL(url);
        const options = {
            method: method,
            hostname: parsedUrl.hostname,
            path: parsedUrl.pathname + parsedUrl.search,
            headers: {
                'Content-Type': 'application/json',
                ...headers
            }
        };
        const req = https.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                try { resolve({ status: res.statusCode, data: JSON.parse(body || '{}') }); }
                catch (e) { resolve({ status: res.statusCode, data: body }); }
            });
        });
        req.on('error', reject);
        if (data) req.write(JSON.stringify(data));
        req.end();
    });
}

async function run() {
    console.log('1. Creating user via REST...');
    const authRes = await request(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=' + API_KEY,
        'POST',
        { email: 'test_prod_' + Date.now() + '@example.com', password: 'password123', returnSecureToken: true }
    );
    if (authRes.status !== 200) throw new Error('Auth failed: ' + JSON.stringify(authRes));
    
    const idToken = authRes.data.idToken;
    const uid = authRes.data.localId;
    console.log('Test UID:', uid);
    
    const headers = { 'Authorization': 'Bearer ' + idToken };
    
    console.log('2. Populating Firestore via REST...');
    // users/{uid}
    await request(
        'https://firestore.googleapis.com/v1/projects/' + PROJECT_ID + '/databases/(default)/documents/users/' + uid,
        'PATCH',
        { fields: { test: { booleanValue: true } } },
        headers
    );
    // usersProgress/{uid}
    await request(
        'https://firestore.googleapis.com/v1/projects/' + PROJECT_ID + '/databases/(default)/documents/usersProgress/' + uid,
        'PATCH',
        { fields: { test: { booleanValue: true } } },
        headers
    );
    // 3 reports
    for (let i = 0; i < 3; i++) {
        await request(
            'https://firestore.googleapis.com/v1/projects/' + PROJECT_ID + '/databases/(default)/documents/reports',
            'POST',
            { fields: { gonderenUid: { stringValue: uid }, test: { booleanValue: true } } },
            headers
        );
    }
    
    console.log('3. Calling deleteSelfAccount...');
    const callRes1 = await request(FUNCTION_URL, 'POST', { data: {} }, headers);
    console.log('Function response 1:', callRes1);
    
    console.log('4. Idempotency Check...');
    const callRes2 = await request(FUNCTION_URL, 'POST', { data: {} }, headers);
    console.log('Function response 2:', callRes2);
    
    console.log('5. Verifying Firestore Deletions...');
    const checkUser = await request('https://firestore.googleapis.com/v1/projects/' + PROJECT_ID + '/databases/(default)/documents/users/' + uid, 'GET', null, headers);
    console.log('users doc check (expect 404):', checkUser.status);
    
    const checkProg = await request('https://firestore.googleapis.com/v1/projects/' + PROJECT_ID + '/databases/(default)/documents/usersProgress/' + uid, 'GET', null, headers);
    console.log('usersProgress doc check (expect 404):', checkProg.status);
    
    console.log('6. Verifying Auth Deletion...');
    const checkAuth = await request('https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=' + API_KEY, 'POST', { idToken: idToken });
    console.log('Auth lookup (expect error):', checkAuth);
    
    console.log('Done.');
}
run().catch(console.error);
