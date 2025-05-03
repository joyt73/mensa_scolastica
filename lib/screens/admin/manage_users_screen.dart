import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/user.dart';
import 'package:mensa_scolastica/repositories/user_repository.dart';
import 'package:mensa_scolastica/screens/admin/user_details_screen.dart';

// Provider per la lista di utenti filtrati per ruolo
final usersByRoleProvider = FutureProvider.family<List<AppUser>, String>(
      (ref, role) async {
    final userRepository = ref.watch(userRepositoryProvider);
    return await userRepository.getUsersByRole(role);
  },
);

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToUserDetails(AppUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(user: user),
      ),
    ).then((_) {
      // Aggiorna la lista quando torna indietro
      ref.refresh(usersByRoleProvider('genitore'));
      ref.refresh(usersByRoleProvider('operatore'));
      ref.refresh(usersByRoleProvider('admin'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Utenti'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Genitori'),
            Tab(text: 'Operatori'),
            Tab(text: 'Admin'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra di ricerca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cerca utente',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('genitore'),
                _buildUserList('operatore'),
                _buildUserList('admin'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funzionalità in sviluppo'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserList(String role) {
    final usersAsync = ref.watch(usersByRoleProvider(role));

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(usersByRoleProvider(role));
      },
      child: usersAsync.when(
        data: (users) {
          // Filtra gli utenti in base alla ricerca
          final filteredUsers = users.where((user) {
            if (_searchQuery.isEmpty) {
              return true;
            }

            final displayName = user.displayName.toLowerCase();
            final email = user.email.toLowerCase();

            return displayName.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();

          if (filteredUsers.isEmpty) {
            return Center(
              child: _searchQuery.isEmpty
                  ? Text('Nessun ${_getRoleInItalian(role)} registrato')
                  : const Text('Nessun risultato trovato'),
            );
          }

          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserItem(user);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Errore: $error'),
        ),
      ),
    );
  }

  Widget _buildUserItem(AppUser user) {
    final roleColor = _getRoleColor(user.role);
    IconData roleIcon = _getRoleIcon(user.role);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.2),
          child: Icon(roleIcon, color: roleColor),
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            if (user.school != null)
              Text('Scuola: ${user.school}'),
            if (user.linkedStudents != null && user.linkedStudents!.isNotEmpty)
              Text('Figli associati: ${user.linkedStudents!.length}'),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => _navigateToUserDetails(user),
        ),
        onTap: () => _navigateToUserDetails(user),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'genitore':
        return Colors.blue;
      case 'operatore':
        return Colors.green;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'genitore':
        return Icons.family_restroom;
      case 'operatore':
        return Icons.assignment_ind;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _getRoleInItalian(String role) {
    switch (role) {
      case 'genitore':
        return 'genitore';
      case 'operatore':
        return 'operatore';
      case 'admin':
        return 'amministratore';
      default:
        return role;
    }
  }
}