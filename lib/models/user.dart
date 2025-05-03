import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String role;
  final String displayName;
  final String? fcmToken;
  final List<String>? linkedStudents;
  final String? school;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
    this.fcmToken,
    this.linkedStudents,
    this.school,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      displayName: data['displayName'] ?? '',
      fcmToken: data['fcmToken'],
      linkedStudents: data['linkedStudents'] != null
          ? List<String>.from(data['linkedStudents'])
          : null,
      school: data['school'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'email': email,
      'role': role,
      'displayName': displayName,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (linkedStudents != null) {
      data['linkedStudents'] = linkedStudents;
    }

    if (school != null) {
      data['school'] = school;
    }

    return data;
  }

  bool isParent() => role == 'genitore';
  bool isOperator() => role == 'operatore';
  bool isAdmin() => role == 'admin';
}