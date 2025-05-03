import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/models/user.dart';
import 'package:mensa_scolastica/utils/qr_utils.dart';

class FirebaseUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inizializza i dati di esempio per il test dell'app
  static Future<void> initializeTestData() async {
    // Crea un account amministratore (solo se non esiste già)
    try {
      final adminCredential = await _auth.createUserWithEmailAndPassword(
        email: 'admin@example.com',
        password: 'password123',
      );

      await _firestore.collection('users').doc(adminCredential.user!.uid).set({
        'email': 'admin@example.com',
        'role': 'admin',
        'displayName': 'Admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Se l'utente esiste già, ignoralo
    }

    // Crea un account operatore
    try {
      final operatorCredential = await _auth.createUserWithEmailAndPassword(
        email: 'operatore@example.com',
        password: 'password123',
      );

      await _firestore.collection('users').doc(operatorCredential.user!.uid).set({
        'email': 'operatore@example.com',
        'role': 'operatore',
        'displayName': 'Operatore',
        'school': 'Scuola Primaria Don Milani',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Se l'utente esiste già, ignoralo
    }

    // Crea un account genitore
    try {
      final parentCredential = await _auth.createUserWithEmailAndPassword(
        email: 'genitore@example.com',
        password: 'password123',
      );

      // Crea un documento per il genitore (inizialmente senza figli associati)
      await _firestore.collection('users').doc(parentCredential.user!.uid).set({
        'email': 'genitore@example.com',
        'role': 'genitore',
        'displayName': 'Genitore',
        'linkedStudents': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Crea alcuni studenti
      final studentsData = [
        {
          'firstName': 'Marco',
          'lastName': 'Rossi',
          'class': '1B',
          'school': 'Scuola Primaria Don Milani',
          'credit': 10,
          'allergies': ['glutine', 'latte'],
          'diet': 'vegetariana',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'firstName': 'Laura',
          'lastName': 'Bianchi',
          'class': '3A',
          'school': 'Scuola Primaria Don Milani',
          'credit': 5,
          'allergies': [],
          'diet': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Salva gli studenti e genera i QR code
      final linkedStudentIds = <String>[];

      for (final studentData in studentsData) {
        // Genera un QR code ID sicuro
        final salt = QrUtils.generateRandomSalt();

        // Aggiungi prima il documento studente senza QR code
        final studentRef = await _firestore.collection('students').add(studentData);

        // Genera un QR code basato sull'ID studente
        final qrCodeId = QrUtils.generateSecureQrId(studentRef.id, salt);

        // Aggiorna il documento con il QR code ID
        await studentRef.update({
          'qrCodeId': qrCodeId,
        });

        linkedStudentIds.add(studentRef.id);
      }

      // Associa gli studenti al genitore
      await _firestore.collection('users').doc(parentCredential.user!.uid).update({
        'linkedStudents': linkedStudentIds,
      });
    } catch (e) {
      // Se l'utente esiste già, ignoralo
    }
  }

  // Funzione per verificare se Firestore è vuoto (utile per l'inizializzazione)
  static Future<bool> isFirestoreEmpty() async {
    final userSnapshot = await _firestore.collection('users').limit(1).get();
    return userSnapshot.docs.isEmpty;
  }
}