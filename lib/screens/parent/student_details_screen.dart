import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/models/transaction.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/providers/transaction_provider.dart';
import 'package:mensa_scolastica/screens/parent/recharge_credit_screen.dart';
import 'package:mensa_scolastica/widgets/student_details_card.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final String studentId;

  const StudentDetailsScreen({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  void _navigateToRechargeCredit(BuildContext context, String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RechargeScreenCredit(studentId: studentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentByIdProvider(studentId));
    final transactionsAsync = ref.watch(studentTransactionsProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Studente'),
      ),
      body: Column(
        children: [
          // Dettagli dello studente
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: studentAsync.when(
              data: (student) {
                if (student == null) {
                  return const Center(child: Text('Studente non trovato'));
                }

                return Column(
                  children: [
                    StudentDetailsCard(student: student),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToRechargeCredit(context, studentId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      child: const Text('Ricarica Buoni Pasto'),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Errore: $error'),
              ),
            ),
          ),

          // Titolo sezione transazioni
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Divider(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Storico Movimenti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(),
                ),
              ],
            ),
          ),

          // Lista delle transazioni
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Text('Nessun movimento trovato'),
                    );
                  }

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionItem(context, transaction);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Errore nel caricamento dei movimenti: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, MealTransaction transaction) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = formatter.format(transaction.timestamp);

    final isMeal = transaction.type == 'pasto';
    final icon = isMeal ? Icons.restaurant : Icons.account_balance_wallet;
    final color = isMeal ? Colors.red : Colors.green;
    final sign = isMeal ? '-' : '+';
    final amount = transaction.amount.abs();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          isMeal ? 'Pasto consumato' : 'Ricarica buoni',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formattedDate),
        trailing: Text(
          '$sign$amount',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}