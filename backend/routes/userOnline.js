const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.updateUserPresence = functions.database.ref('/status/{userId}')
    .onUpdate(async (change, context) => {
        const status = change.after.val();
        const userId = context.params.userId;

        const userRef = admin.firestore().collection('users').doc(userId);

        try {
            await userRef.set(
                {
                    isOnline: status.isOnline,
                    lastSeen: status.lastSeen,
                },
                { merge: true }
            );
            console.log(`Estado de usuario ${userId} actualizado en Firestore.`);
        } catch (error) {
            console.error(`Error al actualizar Firestore para el usuario ${userId}:`, error);
        }
    });