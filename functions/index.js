const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Sends a daily digest of new wallpapers at 6:00 PM (Server Time)
exports.sendDailyWallpaperDigest = functions.pubsub.schedule("0 18 * * *")
  .timeZone("UTC") 
  .onRun(async (context) => {
    
    // Check if there are any new wallpapers in the last 24 hours
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    const snapshot = await admin.firestore().collection("wallpapers")
        .where("createdAt", ">=", yesterday)
        .where("status", "==", "published")
        .get();

    if (snapshot.empty) {
      console.log("No new wallpapers in the last 24 hours. No notification sent.");
      return null;
    }

    const count = snapshot.size;
    console.log(`Found ${count} new wallpapers. Sending notification.`);

    // Notification Payload
    const payload = {
      notification: {
        title: "New Wallpapers Available!",
        body: `We just added ${count} new beautiful wallpapers. Tap to check them out!`,
      },
      data: {
        route: "/home", // Deep link route
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };

    // Send to 'all_users' topic
    try {
      const response = await admin.messaging().sendToTopic("all_users", payload);
      console.log("Successfully sent message:", response);
    } catch (error) {
      console.error("Error sending message:", error);
    }

    return null;
});
