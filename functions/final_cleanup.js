const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

initializeApp({
    projectId: "tubitak-akran-zorbaligi"
});

const db = getFirestore();
const auth = getAuth();
const uid = "TO9BQLEakARUcDWTbI3btt1wLq33";

async function cleanup() {
    console.log(`--- FINAL CLEANUP START for UID: ${uid} ---`);

    // 1. Find reports
    console.log("Searching for reports...");
    const reportFields = ["gonderenUid", "reporterId", "uid"];
    let allReportDocs = [];

    for (const field of reportFields) {
        const snapshot = await db.collection("reports").where(field, "==", uid).get();
        snapshot.forEach(doc => {
            if (!allReportDocs.find(d => d.id === doc.id)) {
                allReportDocs.push({ id: doc.id, ref: doc.ref, fieldMatch: field });
            }
        });
    }

    console.log(`Found ${allReportDocs.length} reports.`);
    allReportDocs.forEach(d => console.log(`- Report ID: ${d.id} (matched on ${d.fieldMatch})`));

    // 2. Delete reports
    if (allReportDocs.length > 0) {
        console.log("Deleting reports...");
        const batch = db.batch();
        allReportDocs.forEach(d => batch.delete(d.ref));
        await batch.commit();
        console.log("Reports deleted.");
    }

    // 3. Delete Firestore user docs (idempotent)
    console.log("Deleting users and usersProgress docs...");
    await db.collection("users").doc(uid).delete();
    await db.collection("usersProgress").doc(uid).delete();
    console.log("Firestore user docs deleted.");

    // 4. Delete Auth user
    console.log("Deleting Auth user...");
    try {
        await auth.deleteUser(uid);
        console.log("Auth user deleted successfully.");
    } catch (e) {
        if (e.code === "auth/user-not-found") {
            console.log("Auth user already deleted or doesn't exist.");
        } else {
            console.error("Auth deletion error:", e.message);
        }
    }

    // 5. Final Verification
    console.log("\n--- FINAL VERIFICATION ---");

    // Auth
    try {
        await auth.getUser(uid);
        console.log("Auth user exists: YES (FAIL)");
    } catch (e) {
        console.log("Auth user exists: NO (PASS)");
    }

    // Firestore Docs
    const uDoc = await db.collection("users").doc(uid).get();
    console.log(`users doc exists: ${uDoc.exists} (${uDoc.exists ? "FAIL" : "PASS"})`);

    const pDoc = await db.collection("usersProgress").doc(uid).get();
    console.log(`usersProgress doc exists: ${pDoc.exists} (${pDoc.exists ? "FAIL" : "PASS"})`);

    // Reports
    let remainingReports = 0;
    for (const field of reportFields) {
        const snapshot = await db.collection("reports").where(field, "==", uid).get();
        remainingReports += snapshot.size;
    }
    console.log(`Remaining reports for UID: ${remainingReports} (${remainingReports === 0 ? "PASS" : "FAIL"})`);

    console.log("--- CLEANUP FINISHED ---");
}

cleanup().catch(err => {
    console.error("Fatal error during cleanup:", err);
    process.exit(1);
});
