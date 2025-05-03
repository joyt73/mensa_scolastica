import 'package:cloud_firestore/cloud_firestore.dart';

class MealTransaction {
  final String id;
  final String studentId;
  final String type; // 'pasto' o 'ricarica'
  final int amount;
  final DateTime timestamp;
  final String? operatorId;
  final String? parentId;
  final String? note;

  const MealTransaction({
    required this.id,
    required this.studentId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.operatorId,
    this.parentId,
    this.note,
  });

  factory MealTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealTransaction(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      type: data['type'] ?? '',
      amount: data['amount'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      operatorId: data['operatorId'],
      parentId: data['parentId'],
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'studentId': studentId,
      'type': type,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };

    if (operatorId != null) {
      data['operatorId'] = operatorId;
    }

    if (parentId != null) {
      data['parentId'] = parentId;
    }

    return data;
  }

  bool isMeal() => type == 'pasto';
  bool isRecharge() => type == 'ricarica';
}