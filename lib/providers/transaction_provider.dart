import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/transaction.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/repositories/student_repository.dart';
import 'package:mensa_scolastica/repositories/transaction_repository.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';
import 'package:mensa_scolastica/services/notification_service.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final studentTransactionsProvider = FutureProvider.family<List<MealTransaction>, String>(
      (ref, studentId) async {
    final repository = ref.watch(transactionRepositoryProvider);
    return await repository.getTransactionsByStudent(studentId);
  },
);

final todayTransactionsProvider = FutureProvider<List<MealTransaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final appUser = await ref.watch(userProvider.future);

  if (appUser == null) return [];

  if (appUser.isOperator() && appUser.school != null) {
    return await repository.getTodayTransactionsBySchool(appUser.school!);
  } else if (appUser.isAdmin()) {
    return await repository.getAllTodayTransactions();
  }

  return [];
});
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;
  final NotificationService _notificationService;
  final StudentRepository _studentRepository;

  TransactionNotifier(
      this._repository,
      this._notificationService,
      this._studentRepository
      ) : super(const AsyncValue.data(null));

  Future<bool> registerMeal(String studentId, String operatorId, String school, {String? note}) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.createMealTransaction(
        studentId: studentId,
        operatorId: operatorId,
        amount: -1, // Decremento di 1 buono pasto
        note: note ?? 'Pasto registrato a $school',
      );

      // Se la transazione è riuscita, invia una notifica
      if (success) {
        // Ottieni i dati dello studente e dell'operatore
        final student = await _studentRepository.getStudentById(studentId);

        if (student != null) {
          // Controlla se il saldo è basso
          if (student.credit <= 3) {
            await _notificationService.sendLowBalanceNotification(
              studentName: '${student.firstName} ${student.lastName}',
              balance: student.credit,
            );
          }
        }
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> rechargeCredit(String studentId, String parentId, int amount, {String? note}) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repository.createRechargeTransaction(
        studentId: studentId,
        parentId: parentId,
        amount: amount,
        note: note ?? 'Ricarica di $amount buoni',
      );

      // Se la ricarica è riuscita, invia una notifica
      if (success) {
        // Ottieni i dati dello studente
        final student = await _studentRepository.getStudentById(studentId);

        if (student != null) {
          await _notificationService.sendRechargeNotification(
            studentName: '${student.firstName} ${student.lastName}',
            amount: amount,
          );
        }
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

// Aggiorna il provider
final transactionNotifierProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<void>>(
      (ref) => TransactionNotifier(
    ref.watch(transactionRepositoryProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(studentRepositoryProvider),
  ),
);