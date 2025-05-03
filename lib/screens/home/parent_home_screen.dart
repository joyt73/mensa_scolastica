import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/screens/parent/student_details_screen.dart';
import 'package:mensa_scolastica/screens/parent/recharge_credit_screen.dart';
import 'package:mensa_scolastica/screens/profile/profile_screen.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({Key? key}) : super(key: key);

  void _navigateToStudentDetails(BuildContext context, String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailsScreen(studentId: studentId),
      ),
    );
  }

  void _navigateToRechargeCredit(BuildContext context, String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RechargeScreenCredit(studentId: studentId),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final studentsAsync = ref.watch(studentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genitore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _navigateToProfile(context),
            tooltip: 'Profilo',
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Utente non trovato'));

          return studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return const Center(
                  child: Text('Nessun figlio associato a questo account'),
                );
              }

              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final creditColor = student.credit <= 2
                      ? Colors.red
                      : student.credit <= 5
                      ? Colors.orange
                      : Colors.green;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                                  fontSize: 18,
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
                          const SizedBox(height: 8),
                          Text('Classe: ${student.className}'),
                          Text('Scuola: ${student.school}'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _navigateToStudentDetails(
                                  context,
                                  student.id,
                                ),
                                child: const Text('Dettagli'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _navigateToRechargeCredit(
                                  context,
                                  student.id,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text(
                                  'Ricarica',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text('Errore nel caricamento degli studenti: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Errore nel caricamento dell\'utente: $error'),
        ),
      ),
    );
  }
}