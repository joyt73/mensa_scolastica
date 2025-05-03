import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();
const fcm = admin.messaging();

// Costante per la soglia di buoni pasto sotto la quale inviare una notifica
const LOW_CREDIT_THRESHOLD = 3;

// Funzione Cloud che si attiva quando un documento nella collezione students viene aggiornato
exports.checkLowCredit = functions.firestore
  .document('students/{studentId}')
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    // Controlla se il credito è sceso sotto la soglia
    if (
      newValue.credit <= LOW_CREDIT_THRESHOLD &&
      previousValue.credit > LOW_CREDIT_THRESHOLD
    ) {
      try {
        // Cerca tutti i genitori associati a questo studente
        const usersSnapshot = await db
          .collection('users')
          .where('linkedStudents', 'array-contains', context.params.studentId)
          .where('role', '==', 'genitore')
          .get();

        if (usersSnapshot.empty) {
          console.log('Nessun genitore trovato per lo studente');
          return null;
        }

        // Per ogni genitore, invia una notifica
        const notificationPromises = usersSnapshot.docs.map(async (userDoc) => {
          const userData = userDoc.data();
          const fcmToken = userData.fcmToken;

          if (!fcmToken) {
            console.log('Token FCM non trovato per l\'utente', userDoc.id);
            return null;
          }

          // Prepara il messaggio
          const message = {
            notification: {
              title: 'Saldo buoni pasto basso',
              body: `${newValue.firstName} ${newValue.lastName} ha soltanto ${newValue.credit} buoni pasto rimanenti. Ricarica il saldo.`,
            },
            token: fcmToken,
          };

          // Invia la notifica
          return fcm.send(message);
        });

        await Promise.all(notificationPromises);
        return null;
      } catch (error) {
        console.error('Errore nell\'invio della notifica:', error);
        return null;
      }
    }

    return null;
  });

// Funzione Cloud che registra le transazioni nel log
exports.logTransaction = functions.firestore
  .document('transactions/{transactionId}')
  .onCreate(async (snapshot, context) => {
    const transactionData = snapshot.data();
    console.log('Nuova transazione registrata:', transactionData);

    return null;
  });