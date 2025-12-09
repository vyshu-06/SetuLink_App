const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Triggered when a job document is updated.
 * Checks if the job status changed to 'completed' and updates the Craftizen's stats.
 */
exports.onJobUpdate = functions.firestore
    .document("jobs/{jobId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Check if job was just completed
      if (before.jobStatus !== after.jobStatus && after.jobStatus === "completed") {
        const craftizenId = after.assignedTo; // Assuming 'assignedTo' holds the craftizen ID

        if (!craftizenId) {
          console.log("No craftizen assigned to completed job");
          return null;
        }

        const craftizenRef = admin.firestore().collection("users").doc(craftizenId);

        // Update completed jobs count and re-calculate average rating if a rating was added
        // This uses a transaction or atomic increment for safety
        try {
          const batch = admin.firestore().batch();

          // Update stats
          batch.update(craftizenRef, {
            "stats.completedJobs": admin.firestore.FieldValue.increment(1),
            "updatedAt": admin.firestore.FieldValue.serverTimestamp(),
          });

          // Credit Wallet (Simple logic: Add job budget to wallet)
          // In real app, deduct commission here.
          if (after.budget && after.budget > 0) {
            batch.update(craftizenRef, {
              "walletBalance": admin.firestore.FieldValue.increment(after.budget),
            });
          }

          await batch.commit();
          console.log(`Updated stats and wallet for craftizen ${craftizenId}`);
        } catch (error) {
          console.error("Error updating craftizen stats:", error);
        }
      }
      return null;
    });

/**
 * Scheduled function to anonymize data for users who requested deletion.
 * Runs every day at midnight.
 */
exports.processDeletionRequests = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
  const usersRef = admin.firestore().collection("users");

  // Query users with 'accountStatus' == 'deletion_requested'
  const pendingDeletionSnap = await usersRef.where("accountStatus", "isEqualTo", "deletion_requested").get();

  const batch = admin.firestore().batch();

  pendingDeletionSnap.docs.forEach((doc) => {
    // Anonymize sensitive fields
    batch.update(doc.ref, {
      name: "Deleted User",
      email: `deleted_${doc.id}@setulink.com`,
      phone: "0000000000",
      accountStatus: "deleted",
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  console.log(`Processed ${pendingDeletionSnap.size} deletion requests.`);
  return null;
});

/**
 * Triggered when a new user is created.
 * Awards referral bonuses if the user signed up with a valid referral code.
 */
exports.awardReferralBonus = functions.firestore
    .document("users/{userId}")
    .onCreate(async (snap, context) => {
      const newUser = snap.data();
      const referredBy = newUser.referredBy;

      if (!referredBy) {
        console.log("No referral code used.");
        return null;
      }

      // Find the referrer by their referral code
      const referrerQuery = await admin.firestore().collection("users")
          .where("referralCode", "==", referredBy)
          .limit(1)
          .get();

      if (referrerQuery.empty) {
        console.log("Invalid referral code:", referredBy);
        return null;
      }

      const referrerDoc = referrerQuery.docs[0];
      const referrerId = referrerDoc.id;

      const batch = admin.firestore().batch();

      // 1. Update Referrer: Increment count and points
      batch.update(referrerDoc.ref, {
        referralCount: admin.firestore.FieldValue.increment(1),
        loyaltyPoints: admin.firestore.FieldValue.increment(100), // Bonus for referrer
      });

      // 2. Update Referee (New User): Award welcome points
      batch.update(snap.ref, {
        loyaltyPoints: admin.firestore.FieldValue.increment(50), // Bonus for referee
      });

      // 3. Log the referral transaction
      const referralRef = admin.firestore().collection("referrals").doc();
      batch.set(referralRef, {
        referrerId: referrerId,
        refereeId: snap.id,
        codeUsed: referredBy,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        rewardGiven: true,
      });

      await batch.commit();
      console.log(`Referral bonus awarded. Referrer: ${referrerId}, Referee: ${snap.id}`);
      return null;
    });

/**
 * Triggered when a new job is created.
 * Matches eligible Craftizens and sends notifications.
 */
exports.onJobCreate = functions.firestore
    .document("jobs/{jobId}")
    .onCreate(async (snap, context) => {
      const job = snap.data();
      const requiredSkills = job.requiredSkills || [];

      if (requiredSkills.length === 0) return null;

      // 1. Find matching Craftizens
      // In production, use Geofire for location + array-contains for skills
      const craftizensQuery = await admin.firestore().collection("users")
          .where("role", "==", "craftizen")
          .where("skills", "array-contains-any", requiredSkills)
          .where("kyc.verified", "==", true) // Only verified pros
          .limit(50)
          .get();

      if (craftizensQuery.empty) {
        console.log("No matching craftizens found for job " + context.params.jobId);
        return null;
      }

      const tokens = [];
      craftizensQuery.docs.forEach((doc) => {
        const userData = doc.data();
        if (userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      if (tokens.length === 0) return null;

      // 2. Send FCM Notification
      const payload = {
        notification: {
          title: "New Job Alert!",
          body: `A new job for ${job.title} matches your skills. Check it out!`,
        },
        data: {
          jobId: context.params.jobId,
          type: "new_job",
        },
      };

      try {
        await admin.messaging().sendToDevice(tokens, payload);
        console.log(`Sent job invite to ${tokens.length} craftizens.`);
      } catch (e) {
        console.error("Error sending FCM:", e);
      }

      return null;
    });

/**
 * Validates the price of a service before a job is created.
 */
exports.validateJobPrice = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated before proceeding
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
    );
  }

  const {serviceId, units, craftizenId, distanceKm} = data;

  if (!serviceId || !units) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: serviceId, units."
    );
  }

  // Fetch service data from Firestore
  const serviceRef = admin.firestore().collection("services").doc(serviceId);
  const serviceDoc = await serviceRef.get();

  if (!serviceDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Service not found");
  }

  const serviceData = serviceDoc.data();
  let craftMultiplier = 1.0;

  // Get Craftizen's custom pricing if available
  if (craftizenId) {
    const craftServiceRef = admin
        .firestore()
        .collection("craftizen_services")
        .doc(`${craftizenId}_${serviceId}`);
    const craftDoc = await craftServiceRef.get();
    if (craftDoc.exists) {
      craftMultiplier = craftDoc.data().customMultiplier || 1.0;
    }
  }

  // --- Start Price Calculation (Mirrors Frontend Logic) ---
  let totalPrice = serviceData.basePrice + serviceData.pricePerUnit * units;
  totalPrice *= craftMultiplier;
  totalPrice += (distanceKm || 0) * 10; // Use a default travel charge, e.g., ₹10/km

  // Peak pricing check (e.g., 8-10 AM and 5-7 PM)
  const now = new Date();

  // Calculate IST Hour (UTC + 5:30)
  let istHour = now.getUTCHours() + 5;
  const istMinute = now.getUTCMinutes() + 30;
  if (istMinute >= 60) {
    istHour += 1;
  }
  istHour = istHour % 24;

  const peakHours = [8, 9, 17, 18];
  if (peakHours.includes(istHour)) {
    totalPrice *= serviceData.surgeMultiplier || 1.5;
  }

  totalPrice = Math.max(totalPrice, serviceData.minPrice || 0);

  if (serviceData.maxPrice) {
    totalPrice = Math.min(totalPrice, serviceData.maxPrice);
  }

  // Round up to nearest 10
  totalPrice = Math.ceil(totalPrice / 10) * 10;
  // --- End Price Calculation ---

  const appCommission = totalPrice * (serviceData.appCommission || 0.12);

  return {
    totalPrice,
    appCommission,
    craftizenEarns: totalPrice - appCommission,
    valid: true,
    breakdown: {
      base: serviceData.basePrice,
      labor: serviceData.pricePerUnit * units,
      travel: (distanceKm || 0) * 10,
      craftPremium: craftMultiplier,
    },
  };
});
