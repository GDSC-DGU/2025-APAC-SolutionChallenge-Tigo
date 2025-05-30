const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp({
  locationId: "asia-northeast3",
});

exports.signUp = functions
  .region("asia-northeast3") 
  .auth.user()
  .onCreate((user) => {
    const { uid, displayName, email, photoURL } = user;

    const nicknameTemp = displayName.replace(/\s/g, "");
    const nickname =
      nicknameTemp.length < 15 ? nicknameTemp : nicknameTemp.substring(0, 15);

    return admin
      .firestore()
      .collection("users")
      .doc(uid)
      .get()
      .then((docSnapshot) => {
        if (docSnapshot.exists) {
          return;
        } else {
          admin.firestore().collection("users").doc(uid).set({
            id: uid,
            nickname: nickname,
            email: email,
            photo_url: photoURL,
          });
        }
      })
      .catch((error) => {
        console.error("Error checking document existence:", error);
      });
  });
