import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prima riautentica l'utente
        final isAuthenticated = await ref
            .read(authNotifierProvider.notifier)
            .reauthenticate(_currentPasswordController.text);

        if (!isAuthenticated) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password attuale errata.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Se la riautenticazione è riuscita, procedi con il cambio password
        await ref
            .read(authNotifierProvider.notifier)
            .updatePassword(_newPasswordController.text);

        if (!mounted) return;

        if (!ref.read(authNotifierProvider).hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password aggiornata con successo.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambia password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aggiorna la tua password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password attuale',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureCurrentPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci la password attuale';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nuova password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci una nuova password';
                  }
                  if (value.length < 6) {
                    return 'La password deve contenere almeno 6 caratteri';
                  }
                  if (value == _currentPasswordController.text) {
                    return 'La nuova password deve essere diversa da quella attuale';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Conferma nuova password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Conferma la nuova password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Le password non corrispondono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || authState.isLoading) ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: (_isLoading || authState.isLoading)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Aggiorna password', style: TextStyle(fontSize: 16)),
                ),
              ),
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _getErrorMessage(authState.error.toString()),
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('wrong-password')) {
      return 'La password attuale è errata.';
    } else if (error.contains('weak-password')) {
      return 'La nuova password è troppo debole. Usa almeno 6 caratteri.';
    } else if (error.contains('requires-recent-login')) {
      return 'Per motivi di sicurezza, devi riaccedere prima di poter cambiare la password.';
    } else if (error.contains('network-request-failed')) {
      return 'Problema di connessione. Controlla la tua rete.';
    }
    return 'Errore: $error';
  }
}