import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/transaction.dart';
import 'package:mensa_scolastica/repositories/student_repository.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'transactions';
  final StudentRepository _studentRepository = StudentRepository();

  Future<List<MealTransaction>> getTransactionsByStudent(String studentId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => MealTransaction.fromFirestore(doc))
        .toList();
  }

  Future<List<MealTransaction>> getAllTodayTransactions() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final querySnapshot = await _firestore
        .collection(_collection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => MealTransaction.fromFirestore(doc))
        .toList();
  }

  Future<List<MealTransaction>> getTodayTransactionsBySchool(String school) async {
    // Questa è un'implementazione semplificata. In un'applicazione reale,
    // potrebbe essere necessario prima ottenere tutti gli studenti della scuola
    // e poi filtrare le transazioni per quelli studenti.
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // Per semplicità, assumiamo che possiamo filtrare per note contenenti il nome della scuola
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('note', isGreaterThanOrEqualTo: school)
        .where('note', isLessThanOrEqualTo: school + '\uf8ff') // Trick per ricerca substring
        .orderBy('note')
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => MealTransaction.fromFirestore(doc))
        .toList();
  }

  Future<bool> createMealTransaction({
    required String studentId,
    required String operatorId,
    required int amount,
    String? note,
  }) async {
    // Utilizziamo una transazione Firestore per garantire l'atomicità
    try {
      bool success = false;
      await _firestore.runTransaction((transaction) async {
        // Prima aggiorniamo il credito dello studente
        success = await _studentRepository.updateCredit(studentId, amount);
        if (!success) throw Exception('Impossibile aggiornare il credito');

        // Poi creiamo la transazione
        final transactionData = MealTransaction(
          id: '', // Sarà generato da Firestore
          studentId: studentId,
          type: 'pasto',
          amount: amount,
          timestamp: DateTime.now(),
          operatorId: operatorId,
          note: note,
        ).toFirestore();

        final docRef = _firestore.collection(_collection).doc();
        transaction.set(docRef, transactionData);
      });
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createRechargeTransaction({
    required String studentId,
    required String parentId,
    required int amount,
    String? note,
  }) async {
    try {
      bool success = false;
      await _firestore.runTransaction((transaction) async {
        // Prima aggiorniamo il credito dello studente
        success = await _studentRepository.updateCredit(studentId, amount);
        if (!success) throw Exception('Impossibile aggiornare il credito');

        // Poi creiamo la transazione
        final transactionData = MealTransaction(
          id: '', // Sarà generato da Firestore
          studentId: studentId,
          type: 'ricarica',
          amount: amount,
          timestamp: DateTime.now(),
          parentId: parentId,
          note: note,
        ).toFirestore();

        final docRef = _firestore.collection(_collection).doc();
        transaction.set(docRef, transactionData);
      });
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<List<MealTransaction>> getAllTransactions() async {
    final querySnapshot = await _firestore.collection('transactions').get();
    return querySnapshot.docs.map((doc) => MealTransaction.fromFirestore(doc)).toList();
  }

}