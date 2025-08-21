const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onScreenUpdate = functions.firestore
    .document("Screens/{screenId}")
    .onWrite(async (change, context) => {
        // Get the document data
        const afterData = change.after.data(); // This will contain the latest document data
        const beforeData = change.before.data(); // This is the previous document data

        // If the document is newly created or updated, process the notification
        if (!afterData || !beforeData || JSON.stringify(afterData) !== JSON.stringify(beforeData)) {
            console.log(`Document updated or created: ${context.params.screenId}`);

            const pairingCode = afterData.pairingCode; // Assuming each document has a pairingCode field

            // Get the list of device tokens that have the pairing code
            const tokensSnapshot = await admin.firestore()
                .collection('DeviceTokens')
                .where('pairingCode', '==', pairingCode)
                .get();

            const tokens = tokensSnapshot.docs.map(doc => doc.data().token); // Get tokens

            if (tokens.length === 0) {
                console.log(`No devices found with pairingCode: ${pairingCode}`);
                return null; // No devices to notify
            }

            const message = {
                notification: {
                    title: 'Screen Update Available',
                    body: 'A new update is available for your screen setup.',
                },
                data: {
                    pairingCode: pairingCode,
                    screenId: context.params.screenId,
                    documentData: JSON.stringify(afterData), // Send the updated document data as a string
                },
                tokens: tokens,
            };

            // Send the notification
            try {
                const response = await admin.messaging().sendMulticast(message);
                console.log(`Successfully sent message: ${response}`);
            } catch (error) {
                console.error('Error sending message:', error);
            }
        }

        return null;
    });
