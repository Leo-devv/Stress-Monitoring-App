/**
 * Firebase Cloud Functions for Stress Monitor Thesis App
 *
 * This represents the "Cloud Tier" (Tier 3) of the hybrid Edge/Cloud architecture
 * for the Engineering Thesis: "The Role of AI in Personal Stress Monitoring"
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function: analyzeStressCloud
 *
 * Performs "heavy" AI stress analysis on the cloud
 * Called when battery > 20% and WiFi is available
 *
 * Input: { bvp, eda, temperature, userId }
 * Output: { stressLevel, confidence, mode, timestamp }
 */
exports.analyzeStressCloud = functions.https.onCall(async (data, context) => {
  const { bvp, eda, temperature, userId } = data;

  // Validate input
  if (typeof bvp !== 'number' || typeof eda !== 'number' || typeof temperature !== 'number') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required sensor values (bvp, eda, temperature)'
    );
  }

  // Perform stress calculation (simulating "heavy" AI model)
  const stressResult = calculateStressLevel(bvp, eda, temperature);

  // Store result in Firestore if userId provided
  if (userId) {
    try {
      await db.collection('users').doc(userId).collection('stress_readings').add({
        level: stressResult.level,
        confidence: stressResult.confidence,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        mode: 'CLOUD',
        raw: { bvp, eda, temperature },
        model_version: '1.0.0'
      });
    } catch (error) {
      console.error('Error storing result:', error);
      // Continue even if storage fails
    }
  }

  return {
    stressLevel: stressResult.level,
    confidence: stressResult.confidence,
    mode: 'CLOUD',
    timestamp: new Date().toISOString(),
    contributions: stressResult.contributions
  };
});

/**
 * Cloud Function: getStressHistory
 *
 * Retrieves stress history for a user
 * Useful for generating reports and visualizations
 */
exports.getStressHistory = functions.https.onCall(async (data, context) => {
  const { userId, limit = 100 } = data;

  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId is required');
  }

  try {
    const snapshot = await db
      .collection('users')
      .doc(userId)
      .collection('stress_readings')
      .orderBy('processedAt', 'desc')
      .limit(limit)
      .get();

    const readings = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      processedAt: doc.data().processedAt?.toDate()?.toISOString()
    }));

    return { readings, count: readings.length };
  } catch (error) {
    console.error('Error fetching history:', error);
    throw new functions.https.HttpsError('internal', 'Failed to fetch history');
  }
});

/**
 * Cloud Function: deleteUserData (GDPR Compliance)
 *
 * Deletes all data for a user - implements "Right to Erasure"
 */
exports.deleteUserData = functions.https.onCall(async (data, context) => {
  const { userId } = data;

  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId is required');
  }

  try {
    // Get reference to user's stress readings
    const readingsRef = db.collection('users').doc(userId).collection('stress_readings');

    // Delete all readings in batches
    const snapshot = await readingsRef.get();
    const batch = db.batch();

    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Delete the user document itself
    batch.delete(db.collection('users').doc(userId));

    await batch.commit();

    return {
      success: true,
      deletedCount: snapshot.size,
      message: 'All user data has been permanently deleted'
    };
  } catch (error) {
    console.error('Error deleting user data:', error);
    throw new functions.https.HttpsError('internal', 'Failed to delete user data');
  }
});

/**
 * Scheduled Function: cleanupOldData
 *
 * Runs daily to remove data older than retention period
 * Default retention: 90 days
 */
exports.cleanupOldData = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const retentionDays = 90;
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - retentionDays);

    try {
      const usersSnapshot = await db.collection('users').get();
      let totalDeleted = 0;

      for (const userDoc of usersSnapshot.docs) {
        const readingsRef = userDoc.ref.collection('stress_readings');
        const oldReadings = await readingsRef
          .where('processedAt', '<', cutoffDate)
          .get();

        const batch = db.batch();
        oldReadings.docs.forEach(doc => {
          batch.delete(doc.ref);
          totalDeleted++;
        });

        if (oldReadings.size > 0) {
          await batch.commit();
        }
      }

      console.log(`Cleanup complete: ${totalDeleted} old readings deleted`);
      return null;
    } catch (error) {
      console.error('Cleanup error:', error);
      return null;
    }
  });

// ============================================
// STRESS CALCULATION ALGORITHM
// ============================================

/**
 * Calculates stress level from sensor inputs
 * This is a simplified algorithm for the thesis prototype
 *
 * @param {number} bvp - Blood Volume Pulse (correlates to heart rate)
 * @param {number} eda - Electrodermal Activity (skin conductance)
 * @param {number} temperature - Skin temperature in Celsius
 * @returns {object} - { level, confidence, contributions }
 */
function calculateStressLevel(bvp, eda, temperature) {
  // Normalize inputs to 0-1 scale
  const hrNormalized = normalizeHeartRate(bvp);
  const edaNormalized = normalizeEDA(eda);
  const tempNormalized = normalizeTemperature(temperature);

  // Weighted combination (these weights would be learned in a real ML model)
  // HR: 45%, EDA: 40%, Temperature: 15%
  const weights = { hr: 0.45, eda: 0.40, temp: 0.15 };

  const contributions = {
    heart_rate: hrNormalized * weights.hr,
    eda: edaNormalized * weights.eda,
    temperature: tempNormalized * weights.temp
  };

  const rawStress = contributions.heart_rate + contributions.eda + contributions.temperature;

  // Apply sigmoid smoothing for more natural distribution
  const smoothedStress = sigmoidSmooth(rawStress);

  // Calculate confidence based on input validity
  const confidence = calculateConfidence(bvp, eda, temperature);

  // Convert to 0-100 scale
  const level = Math.round(Math.min(100, Math.max(0, smoothedStress * 100)));

  return { level, confidence, contributions };
}

function normalizeHeartRate(hr) {
  const minHR = 50;
  const maxHR = 140;
  return Math.min(1, Math.max(0, (hr - minHR) / (maxHR - minHR)));
}

function normalizeEDA(eda) {
  const minEDA = 0;
  const maxEDA = 10;
  return Math.min(1, Math.max(0, (eda - minEDA) / (maxEDA - minEDA)));
}

function normalizeTemperature(temp) {
  const minTemp = 31;
  const maxTemp = 38;
  return Math.min(1, Math.max(0, (temp - minTemp) / (maxTemp - minTemp)));
}

function sigmoidSmooth(x) {
  // Modified sigmoid for 0-1 range
  return 1 / (1 + Math.exp(-6 * (x - 0.5)));
}

function calculateConfidence(bvp, eda, temp) {
  let confidence = 1.0;

  // Reduce confidence for out-of-range values
  if (bvp < 40 || bvp > 200) confidence -= 0.2;
  if (eda < 0 || eda > 20) confidence -= 0.2;
  if (temp < 28 || temp > 40) confidence -= 0.2;

  return Math.max(0, Math.min(1, confidence));
}
