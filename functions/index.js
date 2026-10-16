const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { logger } = require("firebase-functions");
const crypto = require("crypto");
const nodemailer = require("nodemailer");

// SMTP credentials live only in Firebase Secret Manager. The secret is a
// standard SMTP connection URL and is bound only to e-mail sending functions.
const parentConsentSmtpUrl = defineSecret("PARENT_CONSENT_SMTP_URL");
const PARENT_CONSENT_FROM = "Kahraman Dostum <siberkahramanapp@gmail.com>";
const PARENT_CONSENT_SECRET_OPTIONS = { secrets: [parentConsentSmtpUrl] };

function createParentConsentTransporter() {
  const smtpUrl = parentConsentSmtpUrl.value();
  if (!smtpUrl) {
    throw new HttpsError(
      "failed-precondition",
      "Ebeveyn e-posta servisi henüz yapılandırılmadı. Lütfen daha sonra tekrar deneyin."
    );
  }

  let parsed;
  try {
    parsed = new URL(smtpUrl);
    if (!/^smtps?:$/.test(parsed.protocol) || !parsed.hostname) {
      throw new Error("Invalid SMTP URL");
    }
  } catch (_) {
    throw new HttpsError(
      "failed-precondition",
      "Ebeveyn e-posta servisi güvenli biçimde yapılandırılmadı."
    );
  }

  // Explicitly decode URL-encoded credentials to avoid misinterpretation
  // of special characters (e.g. +, /, = in Brevo API keys).
  const user = parsed.username ? decodeURIComponent(parsed.username) : undefined;
  const pass = parsed.password ? decodeURIComponent(parsed.password) : undefined;
  const port = parsed.port ? Number(parsed.port) : (parsed.protocol === "smtps:" ? 465 : 587);
  const isSecure = parsed.protocol === "smtps:" || port === 465;

  return nodemailer.createTransport({
    host: parsed.hostname,
    port,
    secure: isSecure,
    auth: user ? { user, pass } : undefined,
    requireTLS: !isSecure,
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 15000,
    tls: { minVersion: "TLSv1.2" },
  });
}

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
 * Uses the modern @google/genai SDK.
 */
function getGoogleAI(apiKey) {
  if (!_genAI) {
    const { GoogleGenAI } = require("@google/genai");
    _genAI = new GoogleGenAI({ apiKey });
  }
  return _genAI;
}

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const REGION = "europe-west1";
const GEMINI_MODEL = "gemini-3.8-flash";

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
    enforceAppCheck: false,
    maxInstances: 10,
  },
  async (request) => {
    logger.info("GEMINI_CHAT_INVOKED", {
      hasAuth: !!request.auth,
      uid: request.auth?.uid || null,
      hasAppCheck: !!request.app,
      region: REGION,
      projectId: process.env.GCP_PROJECT || process.env.GHOST_PROJECT_ID || "tubitak-akran-zorbaligi",
    });

    if (!request.auth) {
      logger.warn("geminiChat rejected: User is not authenticated", {
        hasAuth: false,
        hasAppCheck: !!request.app,
      });
      throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
    }

    if (!request.app) {
      logger.warn("geminiChat notice: App Check token not present or unverified", {
        uid: request.auth.uid,
      });
    }

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

// 3. Prepare AI & Normalize Active Session Chat History (In-Memory Context)
const apiKey = geminiApiKey.value();
const genAI = getGoogleAI(apiKey);

// Geçici sohbet geçmişi istemciden (request.data.gecmis) gelir, Firestore'a yazılmaz
const rawHistory = Array.isArray(request.data?.gecmis)
  ? request.data.gecmis
  : (Array.isArray(request.data?.history) ? request.data.history : []);

// Chat geçmişini Gemini formatına dönüştür
const mappedHistory = rawHistory
  .slice(-MAX_HISTORY_MESSAGES)
  .map((m) => {
    const rawRole = String(m?.rol || m?.role || "").toLowerCase();

    const isUser =
      rawRole === "user" ||
      rawRole === "kullanici";

    const metin = String(
      m?.metin || m?.text || ""
    )
      .trim()
      .slice(0, 500);

    return {
      role: isUser ? "user" : "model",
      parts: [{ text: metin }],
    };
  })
  .filter((m) => m.parts[0].text.length > 0);

// İlk mesaj mutlaka user olmalı
while (
  mappedHistory.length > 0 &&
  mappedHistory[0].role !== "user"
) {
  mappedHistory.shift();
}

// Aynı role sahip ardışık mesajları birleştir
const history = [];

for (const item of mappedHistory) {
  if (
    history.length > 0 &&
    history[history.length - 1].role === item.role
  ) {
    const prevText =
      history[history.length - 1].parts[0].text;

    history[history.length - 1].parts[0].text =
      `${prevText}\n${item.parts[0].text}`.slice(0, 1000);
  } else {
    history.push(item);
  }
}

// 4. Generate Content
// Yeni kullanıcı mesajından önce history'nin model mesajıyla bitmesini garanti et.
if (history.length > 0 && history[history.length - 1].role === "user") {
  history.pop();
}

const contents = [
  ...history,
  {
    role: "user",
    parts: [{ text: mesaj }],
  },
];

const response = await genAI.models.generateContent({
  model: GEMINI_MODEL,
  contents: contents,
  config: {
    systemInstruction:
      SYSTEM_INSTRUCTION +
      `\nKullanıcı: ${userData.ad || "Kahraman"}, Yaş: ${userData.yasGrubu || "6-12"}.`,

    maxOutputTokens: 1024,
    temperature: 0.7,

    safetySettings: [
      {
        category: "HARM_CATEGORY_HARASSMENT",
        threshold: "BLOCK_LOW_AND_ABOVE",
      },
      {
        category: "HARM_CATEGORY_HATE_SPEECH",
        threshold: "BLOCK_LOW_AND_ABOVE",
      },
      {
        category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        threshold: "BLOCK_LOW_AND_ABOVE",
      },
      {
        category: "HARM_CATEGORY_DANGEROUS_CONTENT",
        threshold: "BLOCK_LOW_AND_ABOVE",
      },
    ],
  },
});

const cevap = (response.text || "").trim();

if (!cevap) {
  throw new Error("Gemini boş cevap döndürdü.");
}

      // 5. Update Progress - Only decrement quota and update timestamp (Sohbet geçmişi Firestore'a YAZILMAZ)
      const updateObj = {
        sonGuncelleme: FieldValue.serverTimestamp(),
      };

      if (!isExempt) {
        updateObj.gemini_hakki = FieldValue.increment(-1);
      }

      await db.collection("usersProgress").doc(uid).update(updateObj);

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
    enforceAppCheck: false,
  },
  async (request) => {
    logger.info("TEXT_TO_SPEECH_INVOKED", {
      hasAuth: !!request.auth,
      uid: request.auth?.uid || null,
      hasAppCheck: !!request.app,
    });
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
    enforceAppCheck: false,
  },
  async (request) => {
    logger.info("DELETE_SELF_ACCOUNT_INVOKED", {
      hasAuth: !!request.auth,
      uid: request.auth?.uid || null,
      hasAppCheck: !!request.app,
    });
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

// Admin / Utility functions (Geçici bellek mimarisinde sohbet geçmişi veritabanında tutulmadığı için başarı döndürür)
exports.clearGeminiHistory = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  logger.info("CLEAR_GEMINI_HISTORY_INVOKED", {
    hasAuth: !!request.auth,
    uid: request.auth?.uid || null,
  });
  if (!request.auth) throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
  return { success: true };
});

exports.grantAdReward = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  logger.info("GRANT_AD_REWARD_INVOKED", {
    hasAuth: !!request.auth,
    uid: request.auth?.uid || null,
  });
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

// ============================================================
// TASK COMPLETION & SCORING (ANTI-CHEAT)
// ============================================================

exports.completeTask = onCall(
  {
    region: REGION,
    timeoutSeconds: 30,
    enforceAppCheck: false,
  },
  async (request) => {
    // Güvenli Teşhis Logu (Hassas veri içermez)
    logger.info("COMPLETE_TASK_INVOKED", {
      hasAuth: !!request.auth,
      uid: request.auth?.uid || null,
      hasApp: !!request.app,
      region: REGION,
      hasTaskId: !!request.data?.taskId,
      hasTaskType: !!request.data?.taskType,
    });

    if (!request.auth) throw new HttpsError("unauthenticated", "Giriş yapmalısın.");

    const uid = request.auth.uid;
    const { taskId, taskType, proof } = request.data || {};

    if (!taskId || typeof taskId !== "string" || !taskId.trim()) {
      throw new HttpsError("invalid-argument", "taskId gereklidir.");
    }
    if (!taskType || (taskType !== "senaryo" && taskType !== "dedektif")) {
      throw new HttpsError("invalid-argument", "Geçersiz görev tipi.");
    }

    const cleanTaskId = taskId.trim();
    const db = getDb();
    const progressRef = db.collection("usersProgress").doc(uid);

    try {
      return await db.runTransaction(async (transaction) => {
        const pDoc = await transaction.get(progressRef);
        if (!pDoc.exists) {
          throw new HttpsError("not-found", "Kullanıcı ilerleme kaydı bulunamadı.");
        }

        const pData = pDoc.data() || {};
        const tamamlananBolumler = Array.isArray(pData.tamamlanan_bolumler) ? pData.tamamlanan_bolumler : [];
        const bilinenDedektif = Array.isArray(pData.bilinen_dedektif_sorulari) ? pData.bilinen_dedektif_sorulari : [];
        const currentScore = typeof pData.toplam_puan === "number" ? pData.toplam_puan : 0;
        const currentBadges = Array.isArray(pData.rozetler) ? pData.rozetler : [];

        // Idempotency check: Already completed?
        if (taskType === "senaryo" && tamamlananBolumler.includes(cleanTaskId)) {
          logger.info(`Task already completed by ${uid}: ${cleanTaskId}`);
          return {
            success: true,
            alreadyCompleted: true,
            pointsAwarded: 0,
            newTotalPoints: currentScore,
          };
        }

        if (taskType === "dedektif" && bilinenDedektif.includes(cleanTaskId)) {
          logger.info(`Detective task already completed by ${uid}: ${cleanTaskId}`);
          return {
            success: true,
            alreadyCompleted: true,
            pointsAwarded: 0,
            newTotalPoints: currentScore,
          };
        }

        // Server-side point calculation
        let pointsAwarded = 0;
        if (taskType === "senaryo") {
          let correctCount = 0;
          if (Array.isArray(proof) && proof.length > 0) {
            correctCount = proof.filter((p) => p && (p.dogru === true || p.dogru === "true")).length;
          }
          pointsAwarded = Math.max(correctCount * 20, 20);
        } else if (taskType === "dedektif") {
          pointsAwarded = 30;
        }

        const newTotalPoints = currentScore + pointsAwarded;
        const newCompletedCount = tamamlananBolumler.length + (taskType === "senaryo" ? 1 : 0);

        // Badge evaluation
        const newlyAwardedBadges = [];
        const badgesSnap = await db.collection("badges").get();
        for (const bDoc of badgesSnap.docs) {
          if (currentBadges.includes(bDoc.id)) continue;
          const bData = bDoc.data();
          const tip = (bData.kriter_tipi || "").toString();
          const hedef = bData.hedef_deger;
          const hedefVal = typeof hedef === "number" ? hedef : (parseInt(hedef, 10) || 999);

          if (tip === "puan" && newTotalPoints >= hedefVal) {
            newlyAwardedBadges.push(bDoc.id);
          } else if (tip === "senaryo_sayisi" && newCompletedCount >= hedefVal) {
            newlyAwardedBadges.push(bDoc.id);
          }
        }

        // Skill increments
        const empati = Math.ceil(pointsAwarded * 0.3);
        const dikkat = Math.ceil(pointsAwarded * 0.4);
        const yardim = Math.ceil(pointsAwarded * 0.3);

        const updatePayload = {
          toplam_puan: FieldValue.increment(pointsAwarded),
          "istatistikler.karar_yapisi.empati": FieldValue.increment(empati),
          "istatistikler.karar_yapisi.dikkat": FieldValue.increment(dikkat),
          "istatistikler.karar_yapisi.yardim": FieldValue.increment(yardim),
          sonGuncelleme: FieldValue.serverTimestamp(),
        };

        if (taskType === "senaryo") {
          updatePayload.tamamlanan_bolumler = FieldValue.arrayUnion(cleanTaskId);
        } else if (taskType === "dedektif") {
          updatePayload.bilinen_dedektif_sorulari = FieldValue.arrayUnion(cleanTaskId);
        }

        if (newlyAwardedBadges.length > 0) {
          updatePayload.rozetler = FieldValue.arrayUnion(...newlyAwardedBadges);
        }

        transaction.update(progressRef, updatePayload);

        logger.info(`Task ${cleanTaskId} completed for ${uid}: +${pointsAwarded} pts, new total: ${newTotalPoints}`);

        return {
          success: true,
          alreadyCompleted: false,
          pointsAwarded,
          newTotalPoints,
          newlyAwardedBadges,
        };
      });
    } catch (error) {
      logger.error("COMPLETE_TASK_ERROR", { uid, taskId, error: error.message });
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "Görev kaydedilirken bir hata oluştu.");
    }
  }
);

// ============================================================
// AUTH TRIGGER: USER CREATION
// ============================================================
const functionsV1 = require("firebase-functions/v1");
const INITIAL_MESSAGES = 5;

exports.onUserCreated = functionsV1.region(REGION).auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const db = getDb();
  const emailHash = crypto.createHash("sha256").update(user.email || uid).digest("hex");

  try {
    const deletedDoc = await db.collection("deletedAccounts").doc(emailHash).get();
    const batch = db.batch();

    batch.set(
      db.collection("users").doc(uid),
      {
        uid,
        kayitTarihi: FieldValue.serverTimestamp(),
        sonGorulme: FieldValue.serverTimestamp(),
        isAdmin: false,
        isPremium: false,
      },
      { merge: true }
    );

    batch.set(
      db.collection("usersProgress").doc(uid),
      {
        uid,
        gemini_hakki: INITIAL_MESSAGES,
        toplam_puan: 0,
        rozetler: [],
        sonGuncelleme: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await batch.commit();
    logger.info(`onUserCreated success for uid: ${uid}`);
  } catch (error) {
    logger.error("ON_USER_CREATED_ERROR", { uid, error: error.message });
  }
});

// ============================================================
// EBEVEYN ONAYI SİSTEMİ (PARENT CONSENT SYSTEM)
// ============================================================

const PARENT_CONSENT_WINDOW_MS = 10 * 60 * 1000;
const PARENT_CONSENT_MIN_INTERVAL_MS = 60 * 1000;
const PARENT_CONSENT_MAX_REQUESTS = 3;

function tokenHashMatches(storedHash, rawToken) {
  if (typeof storedHash !== "string" || !rawToken) return false;
  const expected = Buffer.from(storedHash, "hex");
  const actual = crypto.createHash("sha256").update(rawToken).digest();
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
}

async function checkParentConsentRateLimit(uid) {
  const limitRef = getDb().collection("rateLimits").doc(`parentConsentReq_${uid}`);
  const now = Date.now();

  await getDb().runTransaction(async (transaction) => {
    const current = transaction.get(limitRef);
    const snapshot = await current;
    const data = snapshot.data() || {};
    const windowStart = Number(data.windowStart || now);
    const count = Number(data.count || 0);
    const lastSentAt = Number(data.lastSentAt || 0);

    if (lastSentAt && now - lastSentAt < PARENT_CONSENT_MIN_INTERVAL_MS) {
      throw new HttpsError("resource-exhausted", "Yeni bir e-posta istemeden önce 60 saniye bekleyin.");
    }

    const inWindow = now - windowStart < PARENT_CONSENT_WINDOW_MS;
    if (inWindow && count >= PARENT_CONSENT_MAX_REQUESTS) {
      throw new HttpsError("resource-exhausted", "Kısa süre içinde çok fazla e-posta istendi. Lütfen daha sonra tekrar deneyin.");
    }

    transaction.set(limitRef, {
      windowStart: inWindow ? windowStart : now,
      count: inWindow ? count + 1 : 1,
      lastSentAt: now,
    });
  });
}

/**
 * 1. requestParentConsent: Ebeveyn Onay İsteği Başlatma
 * Enforces authenticated UID, verifies 6-12 age group in Firestore, generates cryptographic token hash, saves pending request, and sends email.
 */
exports.requestParentConsent = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    enforceAppCheck: false,
    ...PARENT_CONSENT_SECRET_OPTIONS,
  },
  async (request) => {
    // Rule 1: Strictly enforce request.auth.uid
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
    }
    const uid = request.auth.uid;

    const rawEmail = request.data?.parentEmail || "";
    const parentEmail = String(rawEmail).trim().toLowerCase();

    if (!parentEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(parentEmail)) {
      throw new HttpsError("invalid-argument", "Geçerli bir e-posta adresi giriniz.");
    }

    const db = getDb();

    // Rule 2: Backend age verification against Firestore user document
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Kullanıcı profili bulunamadı.");
    }

    const userData = userDoc.data() || {};
    const yasGrubu = userData.yasGrubu;

    if (yasGrubu !== "6-12") {
      throw new HttpsError("failed-precondition", "Ebeveyn onayı sadece 6-12 yaş grubu içindir.");
    }

    const transporter = createParentConsentTransporter();
    try {
      await transporter.verify();
    } catch (error) {
      logger.error("PARENT_CONSENT_SMTP_UNAVAILABLE", { uid, error: error.message });
      throw new HttpsError("unavailable", "Ebeveyn e-postası şu anda gönderilemiyor. Lütfen daha sonra tekrar deneyin.");
    }

    // Minimum 60 seconds; maximum 3 requests in 10 minutes.
    await checkParentConsentRateLimit(uid);

    // Revoke any existing pending requests for UID
    const existingReqs = await db.collection("parentConsentRequests")
      .where("uid", "==", uid)
      .where("status", "==", "pending")
      .get();

    const batch = db.batch();
    existingReqs.docs.forEach((doc) => {
      batch.update(doc.ref, { status: "revoked", revokedAt: FieldValue.serverTimestamp() });
    });

    // Rule 5: Cryptographically secure random token (32 bytes)
    const rawToken = crypto.randomBytes(32).toString("hex");
    const tokenHash = crypto.createHash("sha256").update(rawToken).digest("hex");

    const reqRef = db.collection("parentConsentRequests").doc();
    const requestId = reqRef.id;
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    batch.set(reqRef, {
      requestId,
      uid,
      parentEmail,
      tokenHash, // Stored as SHA-256 hash ONLY
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
      status: "pending",
      approvedAt: null,
      usedAt: null,
    });

    // Rule 3: Backend-only critical consent fields update
    batch.set(
      db.collection("users").doc(uid),
      {
        parentConsent: {
          required: true,
          status: "pending",
          parentEmail: parentEmail,
          requestedAt: FieldValue.serverTimestamp(),
          approvedAt: null,
          verificationMethod: "email_link",
        },
      },
      { merge: true }
    );

    await batch.commit();

    const approvalUrl = `https://kahraman-dostum.web.app/parent-consent.html#requestId=${encodeURIComponent(requestId)}&token=${encodeURIComponent(rawToken)}`;

    try {
      await transporter.sendMail({
        from: PARENT_CONSENT_FROM,
        to: parentEmail,
        subject: "Kahraman Dostum — Ebeveyn Onayı",
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 20px; background-color: #ffffff;">
              <h2 style="color: #4f46e5; text-align: center; margin-top: 0;">Kahraman Dostum</h2>
              <p style="color: #1e293b; font-size: 15px;">Merhaba,</p>
              <p style="color: #475569; font-size: 14px; line-height: 1.5;">
                Çocuğunuz <strong>Kahraman Dostum</strong> siber güvenlik eğitimi ve arkadaşlık uygulamasına kayıt olmak için onayınızı istemektedir.
              </p>
              <p style="color: #475569; font-size: 14px; line-height: 1.5;">
                Çocuğunuzun güvenliği bizim için en önemli önceliktir. Yapay zekâ sohbetlerimiz kalıcı olarak veritabanında saklanmaz; sadece aktif oturum sırasında işlenip ekrandan ayrılınca silinir.
              </p>
              <div style="text-align: center; margin: 32px 0;">
                <a href="${approvalUrl}" style="background-color: #4f46e5; color: #ffffff; padding: 14px 32px; text-decoration: none; border-radius: 14px; font-weight: bold; font-size: 15px; display: inline-block;">Çocuğuma Onay Ver</a>
              </div>
              <p style="font-size: 12px; color: #94a3b8; text-align: center; line-height: 1.4;">
                Bu onay bağlantısı 24 saat geçerlidir ve yalnızca bir kez kullanılabilir. Eğer kayıt işlemini siz başlatmadıysanız bu e-postayı dikkate almayabilirsiniz.
              </p>
            </div>
        `,
      });
      logger.info("PARENT_CONSENT_EMAIL_SENT", { uid, requestId });
    } catch (error) {
      await reqRef.update({ status: "revoked", revokedAt: FieldValue.serverTimestamp() });
      logger.error("PARENT_CONSENT_EMAIL_ERROR", { uid, requestId, error: error.message });
      throw new HttpsError("unavailable", "Ebeveyn e-postası gönderilemedi. Lütfen daha sonra tekrar deneyin.");
    }

    return { success: true, message: "Onay e-postası başarıyla gönderildi." };
  }
);

/**
 * 2. getConsentRequestDetails: Web Sayfası İçin İstek Detayı Sorgulama
 * Validates request ID and SHA-256 token hash. Returns status without exposing child username or PII (Rule 7).
 */
exports.getConsentRequestDetails = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 20,
    enforceAppCheck: false,
  },
  async (request) => {
    const requestId = String(request.data?.requestId || "").trim();
    const rawToken = String(request.data?.token || "").trim();

    if (!requestId || !rawToken) {
      throw new HttpsError("invalid-argument", "Geçersiz parametreler.");
    }

    const db = getDb();
    const reqDoc = await db.collection("parentConsentRequests").doc(requestId).get();

    if (!reqDoc.exists) {
      throw new HttpsError("not-found", "Onay isteği bulunamadı.");
    }

    const reqData = reqDoc.data();
    if (!tokenHashMatches(reqData.tokenHash, rawToken)) {
      throw new HttpsError("permission-denied", "Geçersiz onay anahtarı.");
    }

    const isExpired = reqData.expiresAt ? reqData.expiresAt.toDate() < new Date() : false;

    // Rule 7 Data Minimization: Return status only, no username or PII
    return {
      status: isExpired ? "expired" : reqData.status,
      isExpired,
    };
  }
);

/**
 * 3. approveParentConsent: Ebeveyn Onayını Doğrulayıp Onaylama
 * Validates requestId, SHA-256 token hash, 24h expiration, pending status, usedAt null, and atomically updates Firestore.
 */
exports.approveParentConsent = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    enforceAppCheck: false,
  },
  async (request) => {
    const requestId = String(request.data?.requestId || "").trim();
    const rawToken = String(request.data?.token || "").trim();

    if (!requestId || !rawToken) {
      throw new HttpsError("invalid-argument", "Geçersiz parametreler.");
    }

    const db = getDb();
    const reqRef = db.collection("parentConsentRequests").doc(requestId);
    const outcome = await db.runTransaction(async (transaction) => {
      const reqDoc = await transaction.get(reqRef);
      if (!reqDoc.exists) return { state: "not-found" };

      const reqData = reqDoc.data();
      if (!tokenHashMatches(reqData.tokenHash, rawToken)) return { state: "invalid-token" };
      if (reqData.status === "approved" || reqData.usedAt != null) return { state: "used" };
      if (reqData.status !== "pending") return { state: "invalid-status" };

      const isExpired = !reqData.expiresAt || reqData.expiresAt.toDate() <= new Date();
      if (isExpired) {
        transaction.update(reqRef, { status: "expired", expiredAt: FieldValue.serverTimestamp() });
        return { state: "expired" };
      }

      const now = FieldValue.serverTimestamp();
      transaction.update(reqRef, { status: "approved", approvedAt: now, usedAt: now });
      transaction.set(
        db.collection("users").doc(reqData.uid),
        {
          parentConsent: {
            required: true,
            status: "approved",
            approvedAt: now,
            verificationMethod: "email_link",
          },
        },
        { merge: true }
      );
      return { state: "approved", uid: reqData.uid };
    });

    if (outcome.state === "not-found") throw new HttpsError("not-found", "Onay isteği bulunamadı.");
    if (outcome.state === "invalid-token") throw new HttpsError("permission-denied", "Geçersiz onay anahtarı.");
    if (outcome.state === "used") throw new HttpsError("already-exists", "Bu onay bağlantısı daha önce kullanılmış.");
    if (outcome.state === "expired") throw new HttpsError("deadline-exceeded", "Onay bağlantısının süresi dolmuş.");
    if (outcome.state !== "approved") throw new HttpsError("failed-precondition", "Bu onay bağlantısı artık geçerli değil.");

    logger.info("PARENT_CONSENT_APPROVED", { uid: outcome.uid, requestId });

    return { success: true, message: "Ebeveyn onayı başarıyla doğrulandı ve tamamlandı." };
  }
);

/**
 * 4. updateParentEmail: Ebeveyn E-Posta Değiştirme ve Yeniden Gönderme
 * Enforces authenticated UID, invalidates previous requests, updates parent email, and triggers a new request.
 */
exports.updateParentEmail = onCall(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
    enforceAppCheck: false,
    ...PARENT_CONSENT_SECRET_OPTIONS,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
    }
    const uid = request.auth.uid;

    const rawEmail = request.data?.newParentEmail || "";
    const newParentEmail = String(rawEmail).trim().toLowerCase();

    if (!newParentEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newParentEmail)) {
      throw new HttpsError("invalid-argument", "Geçerli bir e-posta adresi giriniz.");
    }

    const db = getDb();
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Profil bulunamadı.");
    }

    const userData = userDoc.data() || {};
    if (userData.yasGrubu !== "6-12") {
      throw new HttpsError("failed-precondition", "Sadece 6-12 yaş grubu içindir.");
    }

    const transporter = createParentConsentTransporter();
    try {
      await transporter.verify();
    } catch (error) {
      logger.error("PARENT_CONSENT_SMTP_UNAVAILABLE", { uid, error: error.message });
      throw new HttpsError("unavailable", "Ebeveyn e-postası şu anda gönderilemiyor. Lütfen daha sonra tekrar deneyin.");
    }

    await checkParentConsentRateLimit(uid);

    // Revoke old pending requests for this account before issuing a new token.
    const existingReqs = await db.collection("parentConsentRequests")
      .where("uid", "==", uid)
      .where("status", "==", "pending")
      .get();

    const batch = db.batch();
    existingReqs.docs.forEach((doc) => {
      batch.update(doc.ref, { status: "revoked", revokedAt: FieldValue.serverTimestamp() });
    });

    // Generate new token & hash
    const rawToken = crypto.randomBytes(32).toString("hex");
    const tokenHash = crypto.createHash("sha256").update(rawToken).digest("hex");

    const reqRef = db.collection("parentConsentRequests").doc();
    const requestId = reqRef.id;
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

    batch.set(reqRef, {
      requestId,
      uid,
      parentEmail: newParentEmail,
      tokenHash,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
      status: "pending",
      approvedAt: null,
      usedAt: null,
    });

    batch.set(
      db.collection("users").doc(uid),
      {
        parentConsent: {
          required: true,
          status: "pending",
          parentEmail: newParentEmail,
          requestedAt: FieldValue.serverTimestamp(),
          approvedAt: null,
          verificationMethod: "email_link",
        },
      },
      { merge: true }
    );

    await batch.commit();

    const approvalUrl = `https://kahraman-dostum.web.app/parent-consent.html#requestId=${encodeURIComponent(requestId)}&token=${encodeURIComponent(rawToken)}`;

    try {
      await transporter.sendMail({
          from: PARENT_CONSENT_FROM,
          to: newParentEmail,
          subject: "Kahraman Dostum — Ebeveyn Onayı",
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 20px; background-color: #ffffff;">
              <h2 style="color: #4f46e5; text-align: center; margin-top: 0;">Kahraman Dostum</h2>
              <p style="color: #1e293b; font-size: 15px;">Merhaba,</p>
              <p style="color: #475569; font-size: 14px; line-height: 1.5;">
                Çocuğunuz <strong>Kahraman Dostum</strong> ebeveyn onay e-posta adresini güncelledi ve onayınızı istemektedir.
              </p>
              <div style="text-align: center; margin: 32px 0;">
                <a href="${approvalUrl}" style="background-color: #4f46e5; color: #ffffff; padding: 14px 32px; text-decoration: none; border-radius: 14px; font-weight: bold; font-size: 15px; display: inline-block;">Çocuğuma Onay Ver</a>
              </div>
              <p style="font-size: 12px; color: #94a3b8; text-align: center; line-height: 1.4;">
                Bu onay bağlantısı 24 saat geçerlidir ve yalnızca bir kez kullanılabilir.
              </p>
            </div>
          `,
      });
      logger.info("PARENT_CONSENT_EMAIL_UPDATED_SENT", { uid, requestId });
    } catch (error) {
      await reqRef.update({ status: "revoked", revokedAt: FieldValue.serverTimestamp() });
      logger.error("PARENT_CONSENT_EMAIL_UPDATED_ERROR", { uid, requestId, error: error.message });
      throw new HttpsError("unavailable", "Ebeveyn e-postası gönderilemedi. Lütfen daha sonra tekrar deneyin.");
    }

    return { success: true, message: "Ebeveyn e-postası güncellendi ve yeni onay linki gönderildi." };
  }
);
