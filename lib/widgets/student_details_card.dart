import 'package:flutter/material.dart';
import 'package:mensa_scolastica/models/student.dart';

class StudentDetailsCard extends StatelessWidget {
  final Student student;

  const StudentDetailsCard({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final creditColor = student.credit <= 2
        ? Colors.red
        : student.credit <= 5
        ? Colors.orange
        : Colors.green;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${student.firstName} ${student.lastName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: creditColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Saldo: ${student.credit}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Classe', student.className),
            _buildInfoRow('Scuola', student.school),
            if (student.allergies.isNotEmpty)
              _buildInfoRow('Allergie', student.allergies.join(', ')),
            if (student.diet.isNotEmpty) _buildInfoRow('Dieta', student.diet),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}