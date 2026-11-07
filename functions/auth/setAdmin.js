const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: "rdx-restaurant-3ca6c",
});

async function run() {
  const email = "z@gmail.com";
  const user = await admin.auth().getUserByEmail(email);

  await admin.auth().setCustomUserClaims(user.uid, {
    ...(user.customClaims || {}),
    role: "admin",
  });

  await admin.firestore().collection("staff_profiles").doc(user.uid).set(
    {
      email: email.toLowerCase(),
      role: "admin",
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  console.log("Success! z@gmail.com is now admin");
  console.log("UID:", user.uid);
  process.exit(0);
}

run().catch((err) => {
  console.error("Failed:", err.message);
  process.exit(1);
});