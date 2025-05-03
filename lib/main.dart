import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/app.dart';
import 'package:mensa_scolastica/firebase_options.dart';
import 'package:mensa_scolastica/services/local_database_service.dart';
import 'package:mensa_scolastica/services/payment_service.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inizializza il database locale per la modalità offline
  await LocalDatabaseService.initialize();

  // Inizializza WorkManager per i task in background
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Imposta su false per la produzione
  );

  // Registra un task periodico per sincronizzare i dati
  await Workmanager().registerPeriodicTask(
    'syncTask',
    'syncTransactions',
    frequency: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );

  // Inizializza il servizio di pagamento Stripe
  await PaymentService.initialize();

  runApp(
    const ProviderScope(
      child: MensaApp(),
    ),
  );
}

// Callback per WorkManager - deve essere al di fuori di qualsiasi classe
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Inizializza Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Inizializza il database locale
    await LocalDatabaseService.initialize();

    // Sincronizza le transazioni
    final localDb = LocalDatabaseService();
    final pendingTransactions = await localDb.getPendingTransactions();

    if (pendingTransactions.isEmpty) {
      return true;
    }

    // La logica di sincronizzazione effettiva sarebbe qui
    // In un'implementazione reale, dovresti utilizzare FirebaseAuth per autenticarti
    // e poi utilizzare un repository per sincronizzare le transazioni

    return true; // Restituisci true quando l'attività è completata con successo
  });
}