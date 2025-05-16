const functions = require("firebase-functions");
const { GoogleAuth } = require("google-auth-library");
const fetch = require("node-fetch");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const location = "us-central1";
const model = "gemini-2.0-flash-001";
const axios = require("axios");
const project = functions.config().tigo?.project_id;
const GOOGLE_MAP_KEY = functions.config().tigo?.google_map_key;
const url = `https://${location}-aiplatform.googleapis.com/v1/projects/${project}/locations/${location}/publishers/google/models/${model}:generateContent`;

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

function stripCodeBlock(text) {
  if (!text) return "";

  // 1. 코드블록 제거 (```json, ``` 등)
  let cleaned = text
    .replace(/^\s*```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/i, "")
    .trim();

  // 2. 배열만 추출 (가장 바깥쪽 [])
  const firstBracket = cleaned.indexOf("[");
  const lastBracket = cleaned.lastIndexOf("]");
  if (firstBracket !== -1 && lastBracket !== -1 && lastBracket > firstBracket) {
    cleaned = cleaned.substring(firstBracket, lastBracket + 1);
  } else {
    // 혹시 배열이 아니라 객체로 올 경우, 가장 바깥쪽 {} 추출
    const firstCurly = cleaned.indexOf("{");
    const lastCurly = cleaned.lastIndexOf("}");
    if (firstCurly !== -1 && lastCurly !== -1 && lastCurly > firstCurly) {
      cleaned = cleaned.substring(firstCurly, lastCurly + 1);
    }
  }

  // 3. 앞뒤에 남은 쉼표, 세미콜론, 개행, 공백 등 제거
  cleaned = cleaned.replace(/^[,;\n\r\s]+|[,;\n\r\s]+$/g, "");

  // 4. 혹시 중간에 또 코드블록이 있으면 한 번 더 제거
  cleaned = cleaned
    .replace(/^\s*```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/i, "")
    .trim();

  return cleaned;
}

function jsObjectToJson(str) {
  // 1. key: value → "key": value
  str = str.replace(/([{,]\s*)([a-zA-Z0-9_]+)\s*:/g, '$1"$2":');
  // 2. 'value' → "value"
  str = str.replace(/'([^']*)'/g, '"$1"');
  return str;
}
// 자동으로 1씩 올려주는 카운터 함수
async function getNextAutoId(counterPath) {
  const counterRef = counterPath; // DocumentReference

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    let current = 0;
    if (snap.exists) {
      current = snap.data().value || 0;
    }
    const next = current + 1;
    tx.set(counterRef, { value: next }, { merge: true });
    return next;
  });

  return result.toString(); // Firestore docId는 string
}

// 5글자 userId로 전체 userId 찾기
async function getFullUserId(shortId) {
  const usersRef = db.collection("users");
  const snap = await usersRef
    .where("id", ">=", shortId)
    .where("id", "<", shortId + "\uf8ff")
    .limit(1)

    .get();
  if (snap.empty) {
    throw new Error("userId 매핑 실패: " + shortId);
  }
  const doc = snap.docs[0];
  return doc.id;
}

exports.tripPlan = functions
  .region(location)
  .runWith({
    memory: "512MB",
    timeoutSeconds: 60,
  })
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }
    let { userId: shortId, dialogId } = req.body;
    if (!shortId || !dialogId) {
      return res.status(400).json({ error: "userId 또는 dialogId 누락" });
    }
    let userId;
    try {
      userId = await getFullUserId(shortId);
    } catch (e) {
      return res.status(404).json({ error: e.message });
    }
    const dialogRef = db
      .collection("users")
      .doc(shortId)
      .collection("dialogs")
      .doc(dialogId);
    const dialogDoc = await dialogRef.get();
    if (!dialogDoc.exists) {
      return res.status(404).json({ error: "대화방이 없습니다." });
    }
    const dialogData = dialogDoc.data();

    if (!dialogData.createdAt) {
    }
    const messagesRef = dialogDoc.ref.collection("messages");
    const snapshot = await messagesRef.get(); // 이 줄 추가!
    if (!snapshot.size) {
      return res.status(404).json({ error: "대화가 없습니다." });
    }
    const dialogDocs = snapshot.docs;
    const dialog = dialogDocs.map((doc) => doc.data());

    const dialogText = dialog
      .map(
        (msg) =>
          `${msg.role === "assistant" ? "model" : "user"}: ${msg.content}`
      )
      .join("\n");

    const systemPrompt = `
Below is the actual conversation history between a travel chatbot and a user.

${dialogText}

Based on the above conversation history,  
create a travel itinerary in **English** and output it as a **JSON array** as shown below.

Each itinerary spot must include **all** of the following fields:

- "date": "2024-05-20" (Visit date, ISO 8601 format)
- "time": "09:00" (Visit time, 24-hour format)
- "local": "Seoul" (Region visited on that date, e.g., Busan, Jeju, etc.)
- "place": "Gyeongbokgung Palace" (Place name)
- "category": "Palace" (Place category, e.g., Palace, Museum, Cafe, etc.)
- "openTime": "09:00" (Opening time, 24-hour format)
- "closeTime": "18:00" (Closing time, 24-hour format)
- "info": "Gyeongbokgung Palace is the main royal palace of the Joseon dynasty..." (Brief description of the place)
- "fee": 3000 (Admission fee, number)
- "latitude": 37.579617 (Latitude, float)
- "longitude": 126.977041 (Longitude, float)
- "thumbnail": "https://..." (**Only use real, accessible image URLs, preferably from Google Images, Wikimedia, or official websites. Do not use example text, empty values, icons, logos, or descriptions.**)

**The thumbnail field must be a real, accessible image URL. Do not use example text, empty values, icons, logos, or descriptions.**
**Only use image URLs from Google Images, Wikimedia, or official websites.**

**Output only a JSON array as shown below, with no explanations or extra text.**
Example:

[
  {
    "date": "2024-05-20",
    "time": "09:00",
    "local": "Seoul",
    "place": "Gyeongbokgung Palace",
    "category": "Palace",
    "openTime": "09:00",
    "closeTime": "18:00",
    "info": "Gyeongbokgung Palace is the main royal palace of the Joseon dynasty...",
    "fee": 3000,
    "latitude": 37.579617,
    "longitude": 126.977041,
    "thumbnail": "https://upload.wikimedia.org/wikipedia/commons/6/6d/Korea-Seoul-Gyeongbokgung-01.jpg"
  }
]

**Do not include any explanations or extra text, only output the JSON array.**
**The itinerary must cover at least 3 days (3 different dates), and each day should have at least 3 spots.**
**Each date must be different, and multiple spots can be assigned to a single day.**
`;

    const messagesForGemini = [
      { role: "user", parts: [{ text: systemPrompt }] },
    ];

    try {
      const auth = new GoogleAuth({
        scopes: "https://www.googleapis.com/auth/cloud-platform",
      });
      const client = await auth.getClient();
      const accessToken = await client.getAccessToken();

      const response = await fetch(url, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken.token || accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: messagesForGemini,
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 2048,
            topK: 40,
            topP: 0.95,
          },
        }),
      });

      const data = await response.json();
      const text =
        data.candidates?.[0]?.content?.parts?.[0]?.text ||
        data.candidates?.[0]?.content?.text ||
        JSON.stringify(data);
      const cleanText = stripCodeBlock(text);

      let schedules = [];
      try {
        let tryText = jsObjectToJson(cleanText);
        if (!tryText.trim().startsWith("[")) {
          tryText = `[${tryText}]`;
        }
        schedules = JSON.parse(tryText);
        if (!Array.isArray(schedules)) schedules = [];
      } catch (e) {
        schedules = [];
      }

      const createdAt = new Date().toISOString();
      const enriched = (await enrichAllSchedules(schedules)).map((spot) => ({
        ...spot,
        createdAt,
      }));

      const counterPath = db
        .collection("tripPlans")
        .doc(shortId)
        .collection("meta")
        .doc("counter");
      const planId = await getNextAutoId(counterPath);

      await db
        .collection("tripPlans")
        .doc(shortId)
        .collection("plans")
        .doc(planId)
        .set({
          userId: shortId,
          createdAt,
          schedules: enriched,
        });
      const firstSpot = enriched[0] || {};
      const firstLocation = firstSpot.local || "알 수 없음";

      // 유효한 썸네일만 필터링해서 랜덤 추출
      const validThumbnails = enriched
        .map((s) => s.thumbnail)
        .filter(
          (url) =>
            typeof url === "string" &&
            url.startsWith("http") &&
            url.trim() !== "" &&
            url !== "undefined"
        );

      let planThumbnailImage = "";
      if (validThumbnails.length > 0) {
        const randomIdx = Math.floor(Math.random() * validThumbnails.length);
        planThumbnailImage = validThumbnails[randomIdx];
      }
      // 플랜 요약 정보 생성
      const planName = `${firstLocation} ${
        [...new Set(enriched.map((s) => s.date))].length
      }-day trip`;
      const days = [...new Set(enriched.map((s) => s.date))].length;
      const mainSpots = enriched.slice(0, 3).map((s) => s.place);

      // users/{userId}/plans/{planId}에 요약 정보 저장
      await db
        .collection("users")
        .doc(shortId)
        .collection("plans")
        .doc(planId)
        .set({
          planId,
          planName,
          planThumbnailImage,
          createdAt,
          location: firstLocation,
          days,
          mainSpots,
          dialogId,
        });

      // 기존 대화방에도 플랜 정보 저장 (겸용)
      await db
        .collection("users")
        .doc(userId)
        .collection("dialogs")
        .doc(dialogId)
        .set(
          {
            userId: shortId,
            planId,
            location: firstLocation,
            thumbnail: planThumbnailImage,
            createdAt,
          },
          { merge: true }
        );

      const responseData = { success: true, planId, schedules: enriched };
      res.json(responseData);
    } catch (e) {
      console.error("에러 발생:", e);
      res.status(500).json({ error: e.toString() });
    }
  });

// 대화 세션(방) 생성
exports.createDialog = functions
  .region(location)
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }
    let { userId: shortId, dialog } = req.body;
    if (!shortId || !dialog || !Array.isArray(dialog)) {
      return res
        .status(400)
        .json({ error: "userId 또는 dialog 파라미터 누락" });
    }
    let userId;
    try {
      userId = await getFullUserId(shortId);
    } catch (e) {
      return res.status(404).json({ error: e.message });
    }
    // 대화방 생성
    const dialogCounterPath = db
      .collection("users")
      .doc(userId)
      .collection("meta")
      .doc("counter");
    const dialogId = await getNextAutoId(dialogCounterPath);
    const dialogRef = db
      .collection("users")
      .doc(shortId)
      .collection("dialogs")
      .doc(dialogId);
    await dialogRef.set({ createdAt: new Date().toISOString() });

    // 첫 메시지들 저장
    const messagesRef = dialogRef.collection("messages");
    for (const msg of dialog) {
      const msgData = { ...msg, createdAt: new Date().toISOString() };
      const msgDoc = await messagesRef.add(msgData);
    }

    res.json({ success: true, userId, dialogId });
  });

// 메시지 저장
exports.saveMessage = functions
  .region(location)
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }
    const { userId: shortId, dialogId, message } = req.body;
    if (!shortId || !dialogId || !message) {
      return res.status(400).json({ error: "파라미터 누락" });
    }
    const userId = await getFullUserId(shortId);
    const messagesRef = db
      .collection("users")
      .doc(shortId)
      .collection("dialogs")
      .doc(dialogId)
      .collection("messages");
    const msgDoc = await messagesRef.add({
      ...message,
      createdAt: new Date().toISOString(),
    });
    res.json({ success: true, userId, dialogId, messageId: msgDoc.id });
  });

async function searchPlace(placeName) {
  const url = `https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${encodeURIComponent(
    placeName
  )}&inputtype=textquery&fields=place_id&key=${GOOGLE_MAP_KEY}`;
  const res = await axios.get(url);
  return res.data.candidates?.[0]?.place_id;
}
async function getPlaceDetails(placeId) {
  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,geometry,opening_hours,photos,formatted_address,international_phone_number,website&key=${GOOGLE_MAP_KEY}`;
  const res = await axios.get(url);
  return res.data.result;
}

function getPhotoUrl(photoReference) {
  return `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${photoReference}&key=${GOOGLE_MAP_KEY}`;
}
async function enrichSchedule(schedule) {
  const placeId = await searchPlace(schedule.place);
  if (!placeId) return { ...schedule, error: "장소 검색 실패" };
  const details = await getPlaceDetails(placeId);

  return {
    ...schedule,
    address: details.formatted_address,
    latitude: details.geometry.location.lat,
    longitude: details.geometry.location.lng,
    openTime: details.opening_hours?.periods?.[0]?.open?.time || null,
    closeTime: details.opening_hours?.periods?.[0]?.close?.time || null,
    phone: details.international_phone_number,
    website: details.website,
    thumbnail: details.photos?.[0]
      ? getPhotoUrl(details.photos[0].photo_reference)
      : null,
  };
}

async function enrichAllSchedules(schedules) {
  return Promise.all(schedules.map(enrichSchedule));
}
