const functions = require("firebase-functions");
const { GoogleAuth } = require("google-auth-library");
const fetch = require("node-fetch");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const project = functions.config().tigo.project_id;
const location = "us-central1";
const model = "gemini-2.0-flash-001";
const axios = require("axios");
const GOOGLE_API_KEY =  functions.config().tigo.google_map_key;

const url = `https://${location}-aiplatform.googleapis.com/v1/projects/${project}/locations/${location}/publishers/google/models/${model}:generateContent`;

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

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

exports.tripPlan = functions
  .region(location)
  .runWith({
    memory: "512MB",
    timeoutSeconds: 60,
  })

  .https.onRequest(async (req, res) => {
    console.log("🔥 tripPlan 함수가 호출되었습니다!");

    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // 테스트 환경에서는 userId를 무조건 'test1'로 강제
    let { userId } = req.body;
    userId = "test1";
    // Firestore에서 대화 불러오기
    const messagesRef = db
      .collection("dialogs")
      .doc(userId)
      .collection("messages");
    const snapshot = await messagesRef.orderBy("timestamp").get();
    const dialog = snapshot.docs.map((doc) => doc.data());
    console.log("받은 대화:", dialog);

    if (!dialog || !Array.isArray(dialog)) {
      res.status(400).json({ error: "dialog 파라미터 누락" });
      return;
    }

    // 2. role-content 텍스트로 변환
    const dialogText = dialog
      .map(
        (msg) =>
          `${msg.role === "assistant" ? "model" : "user"}: ${msg.content}`
      )
      .join("\n");

    // 3. 프롬프트와 결합
    const systemPrompt = `
아래는 여행 챗봇과 사용자의 실제 대화 내역입니다.

${dialogText}

위 대화 히스토리를 참고해서, 
여행 일정표를 **한국어**로, 그리고 아래와 같은 **JSON 배열** 형태로 만들어줘.

각 일정(spot)은 반드시 아래의 모든 필드를 포함해야 해.

- "date": "2024-05-20" (방문 날짜, ISO 8601 형식)
- "time": "09:00" (방문 시간, 24시간제)
- "place": "경복궁" (장소명)
- "category": "궁궐" (장소 카테고리, 예: 궁궐, 박물관, 카페 등)
- "openTime": "09:00" (오픈 시간, 24시간제)
- "closeTime": "18:00" (마감 시간, 24시간제)
- "info": "경복궁은 조선시대의 대표 궁궐로..." (장소에 대한 간단한 설명)
- "fee": 3000 (입장료, 숫자)
- "latitude": 37.579617 (위도, 소수점)
- "longitude": 126.977041 (경도, 소수점)
- "thumbnail": "https://..." (**실제 존재하는 이미지의 URL만 사용, 반드시 구글 이미지, 위키미디어, 공식 홈페이지 등 신뢰할 수 있는 이미지 링크만 사용**)

**thumbnail 필드는 반드시 실제로 접근 가능한 이미지의 URL이어야 하며, 예시나 임의의 텍스트, 빈 값, 아이콘, 로고, 설명 등은 절대 넣지 마.**
**반드시 구글 이미지, 위키미디어, 공식 홈페이지 등에서 실제 이미지를 찾아서 그 URL만 넣어.**

**반드시 아래와 같은 JSON 배열 형태로만 출력해줘.**
예시:

[
  {
    "date": "2024-05-20",
    "time": "09:00",
    "place": "경복궁",
    "category": "궁궐",
    "openTime": "09:00",
    "closeTime": "18:00",
    "info": "경복궁은 조선시대의 대표 궁궐로...",
    "fee": 3000,
    "latitude": 37.579617,
    "longitude": 126.977041,
    "thumbnail": "https://upload.wikimedia.org/wikipedia/commons/6/6d/Korea-Seoul-Gyeongbokgung-01.jpg"
  }
]

**설명이나 부가 텍스트 없이, 반드시 JSON만 출력해줘.**
**여행 일정은 반드시 최소 3일(3개 날짜) 이상으로 각 날에 3개이상의 일정으로 분배해서 작성해줘.**
**각 날짜(date)는 서로 달라야 하며, 하루에 여러 spot이 배정될 수 있어.**
`;

    // 4. Gemini API 호출용 messages
    const messagesForGemini = [
      { role: "user", parts: [{ text: systemPrompt }] },
    ];

    try {
      // Google 인증 토큰 발급
      const auth = new GoogleAuth({
        scopes: "https://www.googleapis.com/auth/cloud-platform",
      });
      const client = await auth.getClient();
      const accessToken = await client.getAccessToken();

      // Gemini generateContent API 호출
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
      // 실제 텍스트 추출
      const text =
        data.candidates?.[0]?.content?.parts?.[0]?.text ||
        data.candidates?.[0]?.content?.text ||
        JSON.stringify(data);

      // Gemini가 JSON만 출력하도록 프롬프트를 줬으니, 코드블록 제거 후 파싱 시도
      const cleanText = stripCodeBlock(text);
      let schedules;
      try {
        let tryText = jsObjectToJson(cleanText);
        if (!tryText.trim().startsWith("[")) {
          tryText = `[${tryText}]`;
        }
        // 1차 시도: 전체 파싱
        try {
          schedules = JSON.parse(tryText);
        } catch (e) {
          // 2차 시도: 개별 객체만 추출해서 파싱
          schedules = [];
          // 객체 단위로 추출 (중괄호로 감싼 부분)
          const objectRegex = /{[\s\S]*?}/g;
          const matches = tryText.match(objectRegex);
          if (matches) {
            for (const objStr of matches) {
              try {
                schedules.push(JSON.parse(jsObjectToJson(objStr)));
              } catch (e) {
                // 파싱 실패한 객체는 무시
              }
            }
          }
          // 혹시 배열인데 내부가 객체가 아닐 수도 있으니, 마지막 방어
          if (!Array.isArray(schedules)) schedules = [];
        }
        // schedules가 비어있으면 최소 빈 배열 반환
        if (!Array.isArray(schedules)) schedules = [];
      } catch (e) {
        // 이 블록까지 오면 정말 심각한 문제, 그래도 빈 배열 반환
        schedules = [];
      }

      // 구글맵 상세정보 enrich
      console.log("before enrich schedules:", schedules);
      const enriched = await enrichAllSchedules(schedules);
      console.log("after enrich schedules:", enriched);
      res.json({ result: JSON.stringify(enriched) });
    } catch (e) {
      console.error("에러 발생:", e);
      res.status(500).json({ error: e.toString() });
    }
  });

exports.saveDialog = functions
  .region(location)
  .https.onRequest(async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }
    let { userId, dialog } = req.body;
    userId = "test1";
    if (!dialog) {
      res.status(400).json({ error: "userId, dialog 파라미터 누락" });
      return;
    }
    // dialog: [{role, content}, ...]
    const batch = db.batch();
    const messagesRef = db
      .collection("dialogs")
      .doc(userId)
      .collection("messages");
    dialog.forEach((msg) => {
      const docRef = messagesRef.doc(); // 자동 ID
      batch.set(docRef, {
        ...msg,
        timestamp: FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
    res.json({ success: true });
  });

async function searchPlace(placeName) {
  const url = `https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${encodeURIComponent(
    placeName
  )}&inputtype=textquery&fields=place_id&key=${GOOGLE_API_KEY}`;
  const res = await axios.get(url);
  return res.data.candidates?.[0]?.place_id;
}
async function getPlaceDetails(placeId) {
  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=name,geometry,opening_hours,photos,formatted_address,international_phone_number,website&key=${GOOGLE_API_KEY}`;
  const res = await axios.get(url);
  return res.data.result;
}

function getPhotoUrl(photoReference) {
  return `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=${photoReference}&key=${GOOGLE_API_KEY}`;
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
