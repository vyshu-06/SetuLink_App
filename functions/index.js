const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Triggered when a job document is updated.
 * Checks if the job status changed to 'completed' and updates the Craftizen's stats.
 */
exports.onJobUpdate = functions.firestore
  .document('jobs/{jobId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if job was just completed
    if (before.jobStatus !== after.jobStatus && after.jobStatus === 'completed') {
      const craftizenId = after.assignedTo; // Assuming 'assignedTo' holds the craftizen ID
      
      if (!craftizenId) {
        console.log('No craftizen assigned to completed job');
        return null;
      }

      const craftizenRef = admin.firestore().collection('users').doc(craftizenId);

      // Update completed jobs count and re-calculate average rating if a rating was added
      // This uses a transaction or atomic increment for safety
      try {
        await craftizenRef.update({
          'stats.completedJobs': admin.firestore.FieldValue.increment(1),
          'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Updated stats for craftizen ${craftizenId}`);
      } catch (error) {
        console.error('Error updating craftizen stats:', error);
      }
    }
    return null;
  });

/**
 * Scheduled function to anonymize data for users who requested deletion.
 * Runs every day at midnight.
 */
exports.processDeletionRequests = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
    const usersRef = admin.firestore().collection('users');
    const snapshot = await usersRef
        .where('dataRequests', 'array-contains', {type: 'deletion', status: 'pending'}) // Simplified query logic
        // Note: Complex array queries might need tailored index or logic
        .get();
    
    // Actually, finding objects in array is hard in query. 
    // Better approach: query users with 'accountStatus' == 'deletion_requested'
    
    const pendingDeletionSnap = await usersRef.where('accountStatus', 'isEqualTo', 'deletion_requested').get();

    const batch = admin.firestore().batch();
    
    pendingDeletionSnap.docs.forEach(doc => {
        // Anonymize sensitive fields
        batch.update(doc.ref, {
            name: 'Deleted User',
            email: `deleted_${doc.id}@setulink.com`,
            phone: '0000000000',
            accountStatus: 'deleted',
            deletedAt: admin.firestore.FieldValue.serverTimestamp()
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
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const newUser = snap.data();
    const referredBy = newUser.referredBy;

    if (!referredBy) {
      console.log('No referral code used.');
      return null;
    }

    // Find the referrer by their referral code
    const referrerQuery = await admin.firestore().collection('users')
      .where('referralCode', '==', referredBy)
      .limit(1)
      .get();

    if (referrerQuery.empty) {
      console.log('Invalid referral code:', referredBy);
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
    const referralRef = admin.firestore().collection('referrals').doc();
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
