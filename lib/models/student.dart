import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String className;
  final String school;
  final String qrCodeId;
  final int credit;
  final List<String> allergies;
  final String diet;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.className,
    required this.school,
    required this.qrCodeId,
    required this.credit,
    required this.allergies,
    required this.diet,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      className: data['class'] ?? '',
      school: data['school'] ?? '',
      qrCodeId: data['qrCodeId'] ?? '',
      credit: data['credit'] ?? 0,
      allergies: List<String>.from(data['allergies'] ?? []),
      diet: data['diet'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'class': className,
      'school': school,
      'qrCodeId': qrCodeId,
      'credit': credit,
      'allergies': allergies,
      'diet': diet,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Student copyWith({
    String? firstName,
    String? lastName,
    String? className,
    String? school,
    String? qrCodeId,
    int? credit,
    List<String>? allergies,
    String? diet,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      className: className ?? this.className,
      school: school ?? this.school,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      credit: credit ?? this.credit,
      allergies: allergies ?? this.allergies,
      diet: diet ?? this.diet,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}