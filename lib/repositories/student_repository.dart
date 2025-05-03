import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/student.dart';

class StudentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'students';

  Future<Student?> getStudentById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Student.fromFirestore(doc);
  }

  Future<Student?> getStudentByQrCode(String qrCodeId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('qrCodeId', isEqualTo: qrCodeId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return Student.fromFirestore(querySnapshot.docs.first);
  }

  Future<List<Student>> getStudentsByIds(List<String> ids) async {
    // Firestore non supporta where('id', in: ids) direttamente,
    // quindi dobbiamo fare più query
    if (ids.isEmpty) return [];

    // Limitare il numero di query parallele a 10 per evitare problemi
    final batches = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? i + 10 : ids.length;
      batches.add(ids.sublist(i, end));
    }

    final results = await Future.wait(
      batches.map((batch) async {
        final List<Student> students = [];
        for (final id in batch) {
          final student = await getStudentById(id);
          if (student != null) {
            students.add(student);
          }
        }
        return students;
      }),
    );

    return results.expand((list) => list).toList();
  }

  Future<List<Student>> getStudentsBySchool(String school) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('school', isEqualTo: school)
        .get();

    return querySnapshot.docs
        .map((doc) => Student.fromFirestore(doc))
        .toList();
  }

  Future<List<Student>> getAllStudents() async {
    final querySnapshot = await _firestore.collection(_collection).get();
    return querySnapshot.docs
        .map((doc) => Student.fromFirestore(doc))
        .toList();
  }

  Future<String> createStudent(Student student) async {
    final docRef = await _firestore.collection(_collection).add(student.toFirestore());
    return docRef.id;
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  Future<bool> updateCredit(String id, int amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection(_collection).doc(id);
        final doc = await transaction.get(docRef);

        if (!doc.exists) throw Exception('Studente non trovato');

        final currentCredit = doc.data()?['credit'] ?? 0;
        final newCredit = currentCredit + amount;

        // Verifica se il credito diventa negativo (solo per i pasti)
        if (amount < 0 && newCredit < 0) {
          throw Exception('Credito insufficiente');
        }

        transaction.update(docRef, {
          'credit': newCredit,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> generateQrCode(String studentId) {
    // Implementazione della generazione del QR code
    // In una implementazione reale, potresti utilizzare un algoritmo di hashing
    // o un altro metodo per generare un ID univoco e sicuro
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrCodeId = 'stu_${studentId.substring(0, 4)}_$timestamp';

    return Future.value(qrCodeId);
  }
}