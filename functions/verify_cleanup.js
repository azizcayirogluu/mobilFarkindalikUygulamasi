const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");

initializeApp({
    projectId: "tubitak-akran-zorbaligi"
});

const db = getFirestore();
const auth = getAuth();
const uid = "TO9BQLEakARUcDWTbI3btt1wLq33";

async function verify() {
    console.log("--- VERIFICATION START ---");
    console.log(`Checking data for UID: ${uid}`);

    // 1. Auth check
    try {
        const authUser = await auth.getUser(uid);
        console.log(`Auth user exists: true (${authUser.email || "No email"})`);
    } catch (e) {
        if (e.code === "auth/user-not-found") {
            console.log("Auth user exists: false");
        } else {
            console.error("Auth check error:", e.message);
        }
    }

    // 2. users/{uid}
    const userDoc = await db.collection("users").doc(uid).get();
    console.log("users document exists:", userDoc.exists);

    // 3. usersProgress/{uid}
    const progressDoc = await db.collection("usersProgress").doc(uid).get();
    console.log("usersProgress document exists:", progressDoc.exists);

    // 4. reports
    const reportsSnapshot = await db.collection("reports").where("gonderenUid", "==", uid).get();
    console.log("reports count for test UID:", reportsSnapshot.size);

    console.log("--- VERIFICATION END ---");
}

verify().catch(err => {
    console.error("Fatal error:", err);
    process.exit(1);
});
