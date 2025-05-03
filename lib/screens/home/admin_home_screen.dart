import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/providers/transaction_provider.dart';
import 'package:mensa_scolastica/screens/admin/manage_students_screen.dart';
import 'package:mensa_scolastica/screens/admin/manage_users_screen.dart';
import 'package:mensa_scolastica/screens/admin/qr_code_generator_screen.dart';
import 'package:mensa_scolastica/screens/admin/report_screen.dart';
import 'package:mensa_scolastica/screens/profile/profile_screen.dart';

//class AdminHomeScreen extends ConsumerWidget {
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> with SingleTickerProviderStateMixin {

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider);
    final transactionsAsync = ref.watch(todayTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Amministratore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _navigateToProfile(context),
            tooltip: 'Profilo',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(studentListProvider);
          ref.refresh(todayTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiche di riepilogo
              _buildSummaryCards(context, studentsAsync, transactionsAsync),
              const SizedBox(height: 24),

              // Menu delle funzioni
              const Text(
                'Gestione',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildFunctionGrid(context),
              const SizedBox(height: 24),

              // Transazioni recenti
              const Text(
                'Transazioni di oggi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentTransactions(context, transactionsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context,
      AsyncValue<List<dynamic>> studentsAsync,
      AsyncValue<List<dynamic>> transactionsAsync,
      ) {
    return Row(
      children: [
        _buildSummaryCard(
          context,
          'Studenti',
          studentsAsync.when(
            data: (students) => students.length.toString(),
            loading: () => '...',
            error: (_, __) => 'Errore',
          ),
          Icons.people,
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildSummaryCard(
          context,
          'Pasti Oggi',
          transactionsAsync.when(
            data: (transactions) => transactions
                .where((t) => t.type == 'pasto')
                .length
                .toString(),
            loading: () => '...',
            error: (_, __) => 'Errore',
          ),
          Icons.restaurant,
          Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildSummaryCard(
          context,
          'Ricariche Oggi',
          transactionsAsync.when(
            data: (transactions) => transactions
                .where((t) => t.type == 'ricarica')
                .length
                .toString(),
            loading: () => '...',
            error: (_, __) => 'Errore',
          ),
          Icons.account_balance_wallet,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Modifica la funzione _buildFunctionGrid per aggiungere il link alla schermata QR
  Widget _buildFunctionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFunctionCard(
          context,
          'Gestione Studenti',
          Icons.school,
          Colors.purple,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageStudentsScreen(),
            ),
          ),
        ),
        _buildFunctionCard(
          context,
          'Gestione Utenti',
          Icons.people_alt,
          Colors.indigo,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageUsersScreen(),
            ),
          ),
        ),
        _buildFunctionCard(
          context,
          'Report e Statistiche',
          Icons.bar_chart,
          Colors.teal,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportScreen(),
            ),
          ),
        ),
        _buildFunctionCard(
          context,
          'Genera QR Codes',
          Icons.qr_code,
          Colors.amber,
              () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QrCodeGeneratorScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFunctionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 48),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
      BuildContext context,
      AsyncValue<List<dynamic>> transactionsAsync,
      ) {
    return SizedBox(
      height: 300,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Center(
                  child: Text('Nessuna transazione oggi'),
                );
              }

              return ListView.builder(
                itemCount: transactions.length > 5 ? 5 : transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final isMeal = transaction.type == 'pasto';
                  final icon = isMeal ? Icons.restaurant : Icons.account_balance_wallet;
                  final color = isMeal ? Colors.red : Colors.green;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(icon, color: color),
                    ),
                    title: FutureBuilder(
                      future: ref.read(studentByIdProvider(transaction.studentId).future),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final student = snapshot.data!;
                          return Text('${student.firstName} ${student.lastName}');
                        }
                        return const Text('Caricamento...');
                      },
                    ),
                    subtitle: Text(
                      isMeal ? 'Pasto consumato' : 'Ricarica buoni',
                    ),
                    trailing: Text(
                      '${isMeal ? '-' : '+'}${transaction.amount.abs()}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Errore nel caricamento delle transazioni'),
            ),
          ),
        ),
      ),
    );
  }
}