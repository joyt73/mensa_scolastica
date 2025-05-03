import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';

class UpdateProfileScreen extends ConsumerStatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends ConsumerState<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();

    // Caricamento dei dati iniziali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await ref.read(userProvider.future);
    if (user != null) {
      setState(() {
        _nameController.text = user.displayName;
        _emailController.text = user.email;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await ref.read(userProvider.future);
        if (user != null) {
          // Verifica se i dati sono stati modificati
          final nameChanged = _nameController.text.trim() != user.displayName;
          final emailChanged = _emailController.text.trim() != user.email;

          if (nameChanged || emailChanged) {
            await ref.read(authNotifierProvider.notifier).updateProfile(
              displayName: nameChanged ? _nameController.text.trim() : null,
              email: emailChanged ? _emailController.text.trim() : null,
            );

            if (!mounted) return;

            if (!ref.read(authNotifierProvider).hasError) {
              // Aggiorna il provider per ricaricare i dati utente
              ref.invalidate(userProvider);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profilo aggiornato con successo.'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          } else {
            // Nessuna modifica fatta
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nessuna modifica effettuata.'),
              ),
            );
            Navigator.pop(context);
          }
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
        title: const Text('Modifica profilo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modifica i tuoi dati',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome e Cognome',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il tuo nome e cognome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci la tua email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Inserisci un indirizzo email valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || authState.isLoading) ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: (_isLoading || authState.isLoading)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salva modifiche', style: TextStyle(fontSize: 16)),
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
    if (error.contains('email-already-in-use')) {
      return 'Questa email è già utilizzata da un altro account.';
    } else if (error.contains('invalid-email')) {
      return 'L\'indirizzo email non è valido.';
    } else if (error.contains('requires-recent-login')) {
      return 'Per motivi di sicurezza, devi riaccedere prima di poter modificare l\'email.';
    } else if (error.contains('network-request-failed')) {
      return 'Problema di connessione. Controlla la tua rete.';
    }
    return 'Errore: $error';
  }
}