import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<List<AppUser>> getUsersByRole(String role) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('role', isEqualTo: role)
        .get();

    return querySnapshot.docs
        .map((doc) => AppUser.fromFirestore(doc))
        .toList();
  }

  Future<void> createUser(String uid, AppUser user) async {
    await _firestore.collection(_collection).doc(uid).set(user.toFirestore());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(uid).update(data);
  }

  // Metodo per eliminare un utente da Firestore
  Future<void> deleteUser(String uid) async {
    await _firestore.collection(_collection).doc(uid).delete();
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection(_collection).doc(uid).update({
      'fcmToken': token,
    });
  }

  Future<void> linkStudentToParent(String parentId, String studentId) async {
    await _firestore.collection(_collection).doc(parentId).update({
      'linkedStudents': FieldValue.arrayUnion([studentId]),
    });
  }

  Future<void> unlinkStudentFromParent(String parentId, String studentId) async {
    await _firestore.collection(_collection).doc(parentId).update({
      'linkedStudents': FieldValue.arrayRemove([studentId]),
    });
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});