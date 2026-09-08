const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { initializeApp, getApps } = require('firebase-admin/app');
const fs = require('fs');

const logFile = '../cleanup_final_log.txt';

function log(msg) {
    console.log(msg);
    fs.appendFileSync(logFile, msg + '\n');
}

async function doCleanup(uid) {
    fs.writeFileSync(logFile, '--- CLEANUP STARTED ---\n');
    if (getApps().length === 0) {
        initializeApp();
    }
    const auth = getAuth();
    const db = getFirestore();
    const reportFields = ['gonderenUid', 'reporterId', 'uid'];
    const reportIds = [];

    log("Starting Auth Deletion for: " + uid);
    try {
        await auth.deleteUser(uid);
        log("Auth User Deleted.");
    } catch (e) {
        log("Auth Deletion Note: " + e.message);
    }

    log("Starting Reports Deletion...");
    for (const field of reportFields) {
        const snapshot = await db.collection('reports').where(field, '==', uid).get();
        log(`Field ${field}: Found ${snapshot.size} docs`);
        for (const doc of snapshot.docs) {
            reportIds.push(doc.id);
            await doc.ref.delete();
            log(`Deleted Report: ${doc.id}`);
        }
    }
    log("Reports Deletion Finished. Total: " + reportIds.length);

    log("Starting Firestore User Docs Deletion...");
    await db.collection('users').doc(uid).delete();
    await db.collection('usersProgress').doc(uid).delete();
    log("User Docs Deleted.");

    log("Verification...");
    const uDoc = await db.collection('users').doc(uid).get();
    const pDoc = await db.collection('usersProgress').doc(uid).get();
    log(`Users doc exists: ${uDoc.exists}`);
    log(`Progress doc exists: ${pDoc.exists}`);

    let rem = 0;
    for (const field of reportFields) {
        const s = await db.collection('reports').where(field, '==', uid).get();
        rem += s.size;
    }
    log(`Remaining reports: ${rem}`);

    log("--- CLEANUP FINISHED ---");

    return {
        authDeleted: true,
        reportIds: reportIds,
        docsDeleted: true,
        remainingReports: rem
    };
}

module.exports = doCleanup;
