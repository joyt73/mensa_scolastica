import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/models/transaction.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/providers/transaction_provider.dart';
import 'package:mensa_scolastica/repositories/student_repository.dart';
import 'package:mensa_scolastica/repositories/transaction_repository.dart';
import 'package:mensa_scolastica/services/connectivity_service.dart';
import 'package:mensa_scolastica/services/local_database_service.dart';

class SyncService {
  final StudentRepository _studentRepository;
  final TransactionRepository _transactionRepository;
  final LocalDatabaseService _localDatabaseService;
  final ConnectivityService _connectivityService;

  SyncService(
      this._studentRepository,
      this._transactionRepository,
      this._localDatabaseService,
      this._connectivityService,
      );

  // Sincronizza i dati da Firebase al database locale (cache)
  Future<void> syncDataToLocal(String schoolName) async {
    // Verifica se è online
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      return;
    }

    try {
      // Ottieni tutti gli studenti della scuola
      final students = await _studentRepository.getStudentsBySchool(schoolName);

      // Salva ogni studente nella cache
      for (final student in students) {
        await _localDatabaseService.cacheStudent(student);
      }
    } catch (e) {
      print('Errore durante la sincronizzazione degli studenti: $e');
      rethrow;
    }
  }

  // Sincronizza le transazioni pending da locale a Firebase
  Future<bool> syncPendingTransactions() async {
    // Verifica se è online
    final isOnline = await _connectivityService.isOnline();
    if (!isOnline) {
      return false;
    }

    try {
      // Ottieni tutte le transazioni pending
      final pendingTransactions = await _localDatabaseService.getPendingTransactions();

      if (pendingTransactions.isEmpty) {
        return true;
      }

      // Per ogni transazione, inviala a Firebase
      for (final transaction in pendingTransactions) {
        // Crea un nuovo ID per la transazione
        final newTransaction = MealTransaction(
          id: '', // Sarà generato da Firestore
          studentId: transaction.studentId,
          type: transaction.type,
          amount: transaction.amount,
          timestamp: transaction.timestamp,
          operatorId: transaction.operatorId,
          parentId: transaction.parentId,
          note: transaction.note,
        );

        // Se è un pasto, decrementa il credito su Firebase
        if (transaction.type == 'pasto') {
          await _studentRepository.updateCredit(
            transaction.studentId,
            transaction.amount,
          );
        }

        // Crea la transazione su Firebase
        if (transaction.type == 'pasto') {
          await _transactionRepository.createMealTransaction(
            studentId: transaction.studentId,
            operatorId: transaction.operatorId!,
            amount: transaction.amount,
            note: transaction.note,
          );
        } else {
          await _transactionRepository.createRechargeTransaction(
            studentId: transaction.studentId,
            parentId: transaction.parentId!,
            amount: transaction.amount,
            note: transaction.note,
          );
        }
      }

      // Rimuovi tutte le transazioni pending
      await _localDatabaseService.clearPendingTransactions();

      return true;
    } catch (e) {
      print('Errore durante la sincronizzazione delle transazioni: $e');
      return false;
    }
  }

  // Registra un pasto in modalità offline
  Future<bool> registerMealOffline(
      String studentId,
      String operatorId,
      String school,
      String? note,
      ) async {
    try {
      // Verifica se lo studente è nella cache
      final student = await _localDatabaseService.getCachedStudentById(studentId);
      if (student == null) {
        return false;
      }

      // Verifica se c'è abbastanza credito
      if (student.credit <= 0) {
        return false;
      }

      // Decrementa il credito localmente
      await _localDatabaseService.updateCachedStudentCredit(studentId, -1);

      // Crea una transazione locale
      final transaction = MealTransaction(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        studentId: studentId,
        type: 'pasto',
        amount: -1,
        timestamp: DateTime.now(),
        operatorId: operatorId,
        note: note ?? 'Pasto registrato a $school (offline)',
      );

      // Salva la transazione come pending
      await _localDatabaseService.savePendingTransaction(transaction);

      return true;
    } catch (e) {
      print('Errore durante la registrazione del pasto offline: $e');
      return false;
    }
  }

  // Cerca uno studente per QR code (modalità offline)
  Future<Student?> findStudentByQrCodeOffline(String qrCodeId) async {
    return _localDatabaseService.getCachedStudentByQrCode(qrCodeId);
  }

  // Ottieni numero transazioni pending
  Future<int> getPendingTransactionsCount() async {
    final transactions = await _localDatabaseService.getPendingTransactions();
    return transactions.length;
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(studentRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(localDatabaseServiceProvider),
    ref.watch(connectivityServiceProvider),
  );
});

// Provider per il numero di transazioni pending
final pendingTransactionsCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.getPendingTransactionsCount();
});