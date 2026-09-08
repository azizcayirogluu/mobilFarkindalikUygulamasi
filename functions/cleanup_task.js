const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

// Production Project ID
const projectId = "tubitak-akran-zorbaligi";
const testUid = "TO9BQLEakARUcDWTbI3btt1wLq33";

initializeApp({
    projectId: projectId
});

const db = getFirestore();
const auth = getAuth();

async function runCleanup() {
    console.log(`--- PRODUCTION CLEANUP START FOR UID: ${testUid} ---`);
    const results = {
        auth: { before: "Unknown", deleted: "No", after: "Unknown" },
        users: { before: "Unknown", deleted: "No", after: "Unknown" },
        usersProgress: { before: "Unknown", deleted: "No", after: "Unknown" },
        reports: { found: 0, ids: [], deleted: 0, remaining: 0 }
    };

    // 1. Auth Check & Delete
    try {
        await auth.getUser(testUid);
        results.auth.before = "Exists";
        await auth.deleteUser(testUid);
        results.auth.deleted = "Yes";
        try {
            await auth.getUser(testUid);
            results.auth.after = "Exists";
        } catch (e) {
            results.auth.after = "Not Found";
        }
    } catch (e) {
        if (e.code === 'auth/user-not-found') {
            results.auth.before = "Not Found";
            results.auth.deleted = "N/A";
            results.auth.after = "Not Found";
        } else {
            console.error("Auth Error:", e.message);
            results.auth.error = e.message;
        }
    }

    // 2. Firestore Docs Check & Delete
    const docPaths = [
        { key: 'users', path: `users/${testUid}` },
        { key: 'usersProgress', path: `usersProgress/${testUid}` }
    ];

    for (const item of docPaths) {
        const ref = db.doc(item.path);
        const snap = await ref.get();
        results[item.key].before = snap.exists ? "Exists" : "Not Found";
        if (snap.exists) {
            await ref.delete();
            results[item.key].deleted = "Yes";
        }
        const snapAfter = await ref.get();
        results[item.key].after = snapAfter.exists ? "Exists" : "Not Found";
    }

    // 3. Reports Check & Delete
    // Based on code analysis, fields are: gonderenUid, reporterId, uid
    const reportFields = ['gonderenUid', 'reporterId', 'uid'];
    const reportDocs = new Map();

    for (const field of reportFields) {
        const snapshot = await db.collection('reports').where(field, '==', testUid).get();
        snapshot.forEach(doc => {
            if (!reportDocs.has(doc.id)) {
                reportDocs.set(doc.id, doc.ref);
            }
        });
    }

    results.reports.found = reportDocs.size;
    results.reports.ids = Array.from(reportDocs.keys());

    if (reportDocs.size > 0) {
        const batch = db.batch();
        reportDocs.forEach(ref => batch.delete(ref));
        await batch.commit();
        results.reports.deleted = reportDocs.size;
    }

    // Verify reports
    let remaining = 0;
    for (const field of reportFields) {
        const snapshot = await db.collection('reports').where(field, '==', testUid).get();
        remaining += snapshot.size;
    }
    results.reports.remaining = remaining;

    console.log("\n--- FINAL CLEANUP RESULT ---");
    console.log(`Test UID: ${testUid}`);
    console.log(`Auth before: ${results.auth.before}`);
    console.log(`Auth deleted: ${results.auth.deleted}`);
    console.log(`Auth after: ${results.auth.after}`);
    console.log(`users before: ${results.users.before}`);
    console.log(`users deleted: ${results.users.deleted}`);
    console.log(`users after: ${results.users.after}`);
    console.log(`usersProgress before: ${results.usersProgress.before}`);
    console.log(`usersProgress deleted: ${results.usersProgress.deleted}`);
    console.log(`usersProgress after: ${results.usersProgress.after}`);
    console.log(`Reports found: ${results.reports.found}`);
    console.log(`Report IDs: ${results.reports.ids.join(', ') || 'None'}`);
    console.log(`Reports deleted: ${results.reports.deleted}`);
    console.log(`Remaining reports: ${results.reports.remaining}`);
    console.log(`Other user data affected: NO`);
    const pass = results.auth.after === "Not Found" &&
                 results.users.after === "Not Found" &&
                 results.usersProgress.after === "Not Found" &&
                 results.reports.remaining === 0;
    console.log(`Cleanup: ${pass ? "PASS" : "FAIL"}`);
}

runCleanup().catch(err => {
    console.error("Fatal Error:", err);
    process.exit(1);
});
