import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/app.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';
import 'package:mensa_scolastica/screens/profile/update_profile_screen.dart';
import 'package:mensa_scolastica/screens/profile/change_password_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utente non trovato'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Center(
                child: Text(
                  _getRoleInItalian(user.role),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeSelector(),
              const SizedBox(height: 32),
              const Divider(),
              _buildProfileOption(
                context,
                'Modifica profilo',
                Icons.edit,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpdateProfileScreen(),
                  ),
                ),
              ),
              _buildProfileOption(
                context,
                'Cambia password',
                Icons.lock_outline,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                ),
              ),
              const Divider(),
              _buildProfileOption(
                context,
                'Esci',
                Icons.logout,
                    () => _showSignOutDialog(context, ref),
                color: Colors.orange,
              ),
              _buildProfileOption(
                context,
                'Elimina account',
                Icons.delete_forever,
                    () => _showDeleteAccountDialog(context, ref),
                color: Colors.red,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, __) => Center(
          child: Text('Errore nel caricamento del profilo: $error'),
        ),
      ),
    );
  }

  String _getRoleInItalian(String role) {
    switch (role) {
      case 'genitore':
        return 'Genitore';
      case 'operatore':
        return 'Operatore mensa';
      case 'admin':
        return 'Amministratore';
      default:
        return role;
    }
  }

  Widget _buildProfileOption(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap, {
        Color? color,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma'),
        content: const Text('Sei sicuro di voler uscire dall\'account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Questa azione è irreversibile. Tutti i tuoi dati verranno eliminati. Per confermare, inserisci la tua password.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci la tua password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context);

                // Mostra un indicatore di caricamento
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Riautentica l'utente
                final isReauthenticated = await ref
                    .read(authNotifierProvider.notifier)
                    .reauthenticate(passwordController.text);

                if (!context.mounted) return;
                Navigator.pop(context); // Chiudi il loader

                if (isReauthenticated) {
                  // Elimina l'account
                  await ref.read(authNotifierProvider.notifier).deleteAccount();

                  if (!context.mounted) return;

                  if (!ref.read(authNotifierProvider).hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Il tuo account è stato eliminato.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Errore: ${ref.read(authNotifierProvider).error}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password errata. Operazione annullata.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themeMode = ref.watch(themeProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tema Applicazione',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<ThemeMode>(
              title: const Text('Tema Chiaro'),
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setTheme(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Tema Scuro'),
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setTheme(value);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Tema di Sistema'),
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setTheme(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}