import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:mensa_scolastica/firebase_options.dart';
import 'package:mensa_scolastica/utils/firebase_utils.dart';

// Questo script può essere eseguito per inizializzare Firebase con dati di esempio
// Utile per lo sviluppo e il testing
void main() async {
  // Inizializza Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Verificando se Firestore è vuoto...');
  final isEmpty = await FirebaseUtils.isFirestoreEmpty();

  if (isEmpty) {
    print('Firestore è vuoto. Inizializzazione dei dati di esempio...');
    await FirebaseUtils.initializeTestData();
    print('Dati di esempio inizializzati con successo!');
  } else {
    print('Firestore contiene già dei dati. Vuoi reinizializzare? (y/n)');
    final input = stdin.readLineSync()?.toLowerCase();

    if (input == 'y') {
      print('Reinizializzazione dei dati di esempio...');
      await FirebaseUtils.initializeTestData();
      print('Dati di esempio reinizializzati con successo!');
    } else {
      print('Operazione annullata.');
    }
  }

  print('Credenziali di accesso:');
  print('- Admin: admin@example.com / password123');
  print('- Operatore: operatore@example.com / password123');
  print('- Genitore: genitore@example.com / password123');

  exit(0);
}