import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/models/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalDatabaseService {
  static const String _pendingTransactionsBox = 'pendingTransactions';
  static const String _studentsCache = 'studentsCache';

  // Inizializza Hive - da chiamare all'avvio dell'app
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_pendingTransactionsBox);
    await Hive.openBox<String>(_studentsCache);
  }

  // Salva una transazione in attesa di sincronizzazione
  Future<void> savePendingTransaction(MealTransaction transaction) async {
    final box = Hive.box<String>(_pendingTransactionsBox);
    final key = 'pending_${transaction.id}_${DateTime.now().millisecondsSinceEpoch}';

    // Converte la transazione in json
    final Map<String, dynamic> transactionMap = {
      'id': transaction.id,
      'studentId': transaction.studentId,
      'type': transaction.type,
      'amount': transaction.amount,
      'timestamp': transaction.timestamp.toIso8601String(),
      'operatorId': transaction.operatorId,
      'parentId': transaction.parentId,
      'note': transaction.note,
    };

    await box.put(key, jsonEncode(transactionMap));
  }

  // Ottieni tutte le transazioni in attesa
  Future<List<MealTransaction>> getPendingTransactions() async {
    final box = Hive.box<String>(_pendingTransactionsBox);
    final List<MealTransaction> pendingTransactions = [];

    for (final key in box.keys) {
      final String transactionJson = box.get(key) ?? '';
      try {
        final Map<String, dynamic> transactionMap = jsonDecode(transactionJson);
        final transaction = MealTransaction(
          id: transactionMap['id'],
          studentId: transactionMap['studentId'],
          type: transactionMap['type'],
          amount: transactionMap['amount'],
          timestamp: DateTime.parse(transactionMap['timestamp']),
          operatorId: transactionMap['operatorId'],
          parentId: transactionMap['parentId'],
          note: transactionMap['note'],
        );

        pendingTransactions.add(transaction);
      } catch (e) {
        print('Errore nel parsing della transazione: $e');
      }
    }

    return pendingTransactions;
  }

  // Rimuovi una transazione in attesa
  Future<void> removePendingTransaction(String key) async {
    final box = Hive.box<String>(_pendingTransactionsBox);
    await box.delete(key);
  }

  // Rimuovi tutte le transazioni in attesa
  Future<void> clearPendingTransactions() async {
    final box = Hive.box<String>(_pendingTransactionsBox);
    await box.clear();
  }

  // Salva uno studente nella cache
  Future<void> cacheStudent(Student student) async {
    final box = Hive.box<String>(_studentsCache);
    final key = 'student_${student.id}';

    // Converte lo studente in json
    final Map<String, dynamic> studentMap = {
      'id': student.id,
      'firstName': student.firstName,
      'lastName': student.lastName,
      'className': student.className,
      'school': student.school,
      'qrCodeId': student.qrCodeId,
      'credit': student.credit,
      'allergies': student.allergies,
      'diet': student.diet,
      'createdAt': student.createdAt.toIso8601String(),
      'updatedAt': student.updatedAt.toIso8601String(),
    };

    await box.put(key, jsonEncode(studentMap));

    // Cache anche per qrCodeId per ricerca più veloce
    await box.put('qr_${student.qrCodeId}', jsonEncode(studentMap));
  }

  // Ottieni uno studente dalla cache per ID
  Future<Student?> getCachedStudentById(String id) async {
    final box = Hive.box<String>(_studentsCache);
    final key = 'student_$id';

    final String? studentJson = box.get(key);
    if (studentJson == null) {
      return null;
    }

    try {
      final Map<String, dynamic> studentMap = jsonDecode(studentJson);
      return Student(
        id: studentMap['id'],
        firstName: studentMap['firstName'],
        lastName: studentMap['lastName'],
        className: studentMap['className'],
        school: studentMap['school'],
        qrCodeId: studentMap['qrCodeId'],
        credit: studentMap['credit'],
        allergies: List<String>.from(studentMap['allergies']),
        diet: studentMap['diet'],
        createdAt: DateTime.parse(studentMap['createdAt']),
        updatedAt: DateTime.parse(studentMap['updatedAt']),
      );
    } catch (e) {
      print('Errore nel parsing dello studente: $e');
      return null;
    }
  }

  // Ottieni uno studente dalla cache per QR code
  Future<Student?> getCachedStudentByQrCode(String qrCodeId) async {
    final box = Hive.box<String>(_studentsCache);
    final key = 'qr_$qrCodeId';

    final String? studentJson = box.get(key);
    if (studentJson == null) {
      return null;
    }

    try {
      final Map<String, dynamic> studentMap = jsonDecode(studentJson);
      return Student(
        id: studentMap['id'],
        firstName: studentMap['firstName'],
        lastName: studentMap['lastName'],
        className: studentMap['className'],
        school: studentMap['school'],
        qrCodeId: studentMap['qrCodeId'],
        credit: studentMap['credit'],
        allergies: List<String>.from(studentMap['allergies']),
        diet: studentMap['diet'],
        createdAt: DateTime.parse(studentMap['createdAt']),
        updatedAt: DateTime.parse(studentMap['updatedAt']),
      );
    } catch (e) {
      print('Errore nel parsing dello studente: $e');
      return null;
    }
  }

  // Ottieni tutti gli studenti dalla cache
  Future<List<Student>> getAllCachedStudents() async {
    final box = Hive.box<String>(_studentsCache);
    final List<Student> cachedStudents = [];

    for (final key in box.keys) {
      if (key.startsWith('student_')) {
        final String studentJson = box.get(key) ?? '';
        try {
          final Map<String, dynamic> studentMap = jsonDecode(studentJson);
          final student = Student(
            id: studentMap['id'],
            firstName: studentMap['firstName'],
            lastName: studentMap['lastName'],
            className: studentMap['className'],
            school: studentMap['school'],
            qrCodeId: studentMap['qrCodeId'],
            credit: studentMap['credit'],
            allergies: List<String>.from(studentMap['allergies']),
            diet: studentMap['diet'],
            createdAt: DateTime.parse(studentMap['createdAt']),
            updatedAt: DateTime.parse(studentMap['updatedAt']),
          );

          cachedStudents.add(student);
        } catch (e) {
          print('Errore nel parsing dello studente: $e');
        }
      }
    }

    return cachedStudents;
  }

  // Aggiorna il credito di uno studente nella cache
  Future<bool> updateCachedStudentCredit(String studentId, int amount) async {
    final student = await getCachedStudentById(studentId);
    if (student == null) {
      return false;
    }

    // Aggiorna il credito
    final updatedStudent = student.copyWith(
      credit: student.credit + amount,
      updatedAt: DateTime.now(),
    );

    // Salva nella cache
    await cacheStudent(updatedStudent);

    return true;
  }

  // Svuota la cache degli studenti
  Future<void> clearStudentsCache() async {
    final box = Hive.box<String>(_studentsCache);
    await box.clear();
  }

  // Verifica se uno studente è nella cache
  Future<bool> isStudentCached(String id) async {
    final student = await getCachedStudentById(id);
    return student != null;
  }
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});