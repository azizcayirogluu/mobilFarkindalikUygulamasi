const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { logger } = require("firebase-functions");

// Global initialization
initializeApp();

// Lazy-loaded clients to reduce cold start impact
let _db;
let _auth;
let _ttsClient;
let _genAI;

const getDb = () => _db || (_db = getFirestore());
const getAuthService = () => _auth || (_auth = getAuth());

/**
 * Lazy load Google Cloud TTS Client
 */
function getTtsClient() {
  if (!_ttsClient) {
    const { TextToSpeechClient } = require("@google-cloud/text-to-speech");
    _ttsClient = new TextToSpeechClient();
  }
  return _ttsClient;
}

/**
 * Lazy load Gemini AI Client
 * Note: Recommended to use "@google/generative-ai" package.
 */
function getGoogleAI(apiKey) {
  if (!_genAI) {
    const { GoogleGenerativeAI } = require("@google/generative-ai");
    _genAI = new GoogleGenerativeAI(apiKey);
  }
  return _genAI;
}

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const REGION = "europe-west1";
const GEMINI_MODEL = "gemini-1.5-flash";

// Constraints
const MAX_MESSAGE_LENGTH = 1000;
const MAX_HISTORY_MESSAGES = 12;
const MAX_TTS_TEXT_LENGTH = 500;
const GEMINI_RATE_LIMIT_MAX = 5;
const GEMINI_RATE_LIMIT_WINDOW = 60 * 1000;

const SYSTEM_INSTRUCTION = `
Sen "Kahraman Dostum" uygulamasının çocuk dostu yapay zeka asistanısın.
Görevlerin:
1. Akran zorbalığı, arkadaşlık ve duygular hakkında destek vermek.
2. Nazik, empatik ve güçlendirici bir dil kullanmak.
3. Asla intikam, şiddet veya gizlilik ihlali önermemek.
4. Tehlikeli durumlarda (kendine zarar verme, ağır şiddet) mutlaka bir yetişkine danışılmasını söylemek.
5. Cevapların 2-4 cümle arasında, net ve anlaşılır olsun.
6. Kişisel bilgileri (proje ID, API key) asla paylaşma.
`;

/**
 * Generic Rate Limiter using Firestore
 */
async function checkRateLimit(uid, action, maxCalls, windowMs) {
  const db = getDb();
  const limitRef = db.collection("rateLimits").doc(`${action}_${uid}`);
  const now = Date.now();

  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(limitRef);
    const data = doc.data() || { windowStart: now, count: 0 };

    if (now - data.windowStart < windowMs) {
      if (data.count >= maxCalls) {
        throw new HttpsError("resource-exhausted", "Çok hızlı gidiyorsun! Biraz dinlenelim mi? ⏳");
      }
      transaction.set(limitRef, { ...data, count: data.count + 1 }, { merge: true });
    } else {
      transaction.set(limitRef, { windowStart: now, count: 1 });
    }
  });
}

// ============================================================
// GEMINI CHAT FUNCTION
// ============================================================

exports.geminiChat = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 40,
    secrets: [geminiApiKey],
    // Emülatörde veya App Check yapılandırması tamamlanmamış ortamlarda 401 hatasını önlemek için
    enforceAppCheck: process.env.FUNCTIONS_EMULATOR === "true" ? false : true,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Giriş yapmalısın.");

    const uid = request.auth.uid;
    const rawMesaj = request.data?.mesaj || "";
    const mesaj = rawMesaj.toString().trim().slice(0, MAX_MESSAGE_LENGTH);

    if (!mesaj) throw new HttpsError("invalid-argument", "Mesaj boş olamaz.");

    const db = getDb();

    try {
      // 1. Rate Limit Check
      await checkRateLimit(uid, "gemini", GEMINI_RATE_LIMIT_MAX, GEMINI_RATE_LIMIT_WINDOW);

      // 2. User State Check
      const [userDoc, progressDoc] = await Promise.all([
        db.collection("users").doc(uid).get(),
        db.collection("usersProgress").doc(uid).get()
      ]);

      if (!userDoc.exists || !progressDoc.exists) {
        throw new HttpsError("not-found", "Kullanıcı profili bulunamadı.");
      }

      const userData = userDoc.data();
      const progressData = progressDoc.data();
      const isExempt = userData.isAdmin === true || userData.isPremium === true;
      const currentHak = progressData.gemini_hakki ?? 5;

      if (!isExempt && currentHak <= 0) {
        throw new HttpsError("resource-exhausted", "Enerjin bitti! Video izleyerek kazanabilirsin. ⚡");
      }

      // 3. Prepare AI
      const apiKey = geminiApiKey.value();
      const genAI = getGoogleAI(apiKey);

      const model = genAI.getGenerativeModel({
        model: GEMINI_MODEL,
        systemInstruction: SYSTEM_INSTRUCTION + `\nKullanıcı: ${userData.ad || "Kahraman"}, Yaş: ${userData.yasGrubu || "6-12"}.`,
      });

      const history = (progressData.sohbet_gecmisi || [])
        .slice(-MAX_HISTORY_MESSAGES)
        .map(m => ({
          role: m.rol === "user" ? "user" : "model",
          parts: [{ text: m.metin.slice(0, 500) }]
        }));

      // 4. Generate Content
      const chat = model.startChat({
        history: history,
        generationConfig: { maxOutputTokens: 1024, temperature: 0.7 },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_LOW_AND_ABOVE" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_LOW_AND_ABOVE" },
          { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_LOW_AND_ABOVE" },
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_LOW_AND_ABOVE" },
        ],
      });

      const result = await chat.sendMessage(mesaj);
      const response = await result.response;
      const cevap = response.text().trim();

      // 5. Update Progress (Atomic)
      const newHistoryItem = [
        { rol: "user", metin: mesaj },
        { rol: "assistant", metin: cevap }
      ];

      await db.runTransaction(async (t) => {
        const pRef = db.collection("usersProgress").doc(uid);
        const pSnap = await t.get(pRef);
        const pData = pSnap.data();

        const updatedHistory = [...(pData.sohbet_gecmisi || []), ...newHistoryItem].slice(-MAX_HISTORY_MESSAGES);

        const updateObj = {
          sohbet_gecmisi: updatedHistory,
          sonGuncelleme: FieldValue.serverTimestamp(),
        };

        if (!isExempt) {
          updateObj.gemini_hakki = FieldValue.increment(-1);
        }

        t.update(pRef, updateObj);
      });

      return { cevap, newLimit: isExempt ? 999 : currentHak - 1 };

    } catch (error) {
      logger.error("GEMINI_ERROR", { uid, error: error.message });
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "Şu an cevap veremiyorum, lütfen biraz sonra tekrar dene. 💙");
    }
  }
);

// ============================================================
// TEXT TO SPEECH FUNCTION
// ============================================================

exports.textToSpeech = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    enforceAppCheck: process.env.FUNCTIONS_EMULATOR === "true" ? false : true,
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Giriş yapmalısın.");

    const metin = (request.data?.metin || "").toString().trim().slice(0, MAX_TTS_TEXT_LENGTH);
    if (!metin) throw new HttpsError("invalid-argument", "Metin boş.");

    try {
      await checkRateLimit(request.auth.uid, "tts", 10, 60000);

      const client = getTtsClient();
      const [response] = await client.synthesizeSpeech({
        input: { text: metin },
        voice: { languageCode: "tr-TR", name: request.data?.voiceName || "tr-TR-Wavenet-C" },
        audioConfig: { audioEncoding: "MP3" },
      });

      return { audioContent: response.audioContent.toString("base64") };
    } catch (error) {
      logger.error("TTS_ERROR", { error: error.message });
      throw new HttpsError("internal", "Ses oluşturulamadı.");
    }
  }
);

// ============================================================
// ACCOUNT MANAGEMENT
// ============================================================

exports.deleteSelfAccount = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    enforceAppCheck: process.env.FUNCTIONS_EMULATOR === "true" ? false : true,
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
    const uid = request.auth.uid;
    const db = getDb();

    try {
      // 1. Delete associated data in batches
      const collections = ["reports", "admobRewardTransactions", "rateLimits"];
      for (const collName of collections) {
        let snapshot;
        do {
          snapshot = await db.collection(collName).where("uid", "==", uid).limit(100).get();
          if (collName === "admobRewardTransactions") {
             snapshot = await db.collection(collName).where("userId", "==", uid).limit(100).get();
          }
          const batch = db.batch();
          snapshot.docs.forEach(doc => batch.delete(doc.ref));
          await batch.commit();
        } while (snapshot.size >= 100);
      }

      // 2. Delete core profile
      await db.collection("usersProgress").doc(uid).delete();
      await db.collection("users").doc(uid).delete();

      // 3. Delete Auth User
      await getAuthService().deleteUser(uid);

      return { success: true };
    } catch (error) {
      logger.error("DELETE_ACCOUNT_ERROR", { uid, error: error.message });
      throw new HttpsError("internal", "Hesap silinirken bir hata oluştu.");
    }
  }
);

// Admin / Utility functions
exports.clearGeminiHistory = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
  await getDb().collection("usersProgress").doc(request.auth.uid).update({
    sohbet_gecmisi: [],
    sonGuncelleme: FieldValue.serverTimestamp()
  });
  return { success: true };
});

exports.grantAdReward = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
  const uid = request.auth.uid;
  await checkRateLimit(uid, "adReward", 10, 24 * 60 * 60 * 1000);

  await getDb().collection("usersProgress").doc(uid).update({
    gemini_hakki: FieldValue.increment(5),
    sonGuncelleme: FieldValue.serverTimestamp()
  });
  return { success: true };
});

/**
 * Sync Admin Claim when users document is updated
 */
exports.syncAdminClaim = onDocumentUpdated({
  document: "users/{userId}",
  region: REGION,
}, async (event) => {
  const newValue = event.data.after.data();
  const previousValue = event.data.before.data();

  // Eğer isAdmin alanı değiştiyse Custom Claim'i güncelle
  if (newValue.isAdmin !== previousValue.isAdmin) {
    const uid = event.params.userId;
    try {
      await getAuthService().setCustomUserClaims(uid, { admin: newValue.isAdmin === true });
      logger.info(`Admin claim synced for user ${uid}: ${newValue.isAdmin}`);
    } catch (error) {
      logger.error("Admin claim sync error", { uid, error });
    }
  }
});
