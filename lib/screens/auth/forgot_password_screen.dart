import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authNotifierProvider.notifier).resetPassword(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      // Se la richiesta è riuscita, mostra il messaggio di conferma
      if (!ref.read(authNotifierProvider).hasError) {
        setState(() {
          _resetSent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recupero Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _resetSent
                ? _buildSuccessMessage()
                : _buildResetForm(authState),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 80,
        ),
        const SizedBox(height: 24),
        const Text(
          'Email di reset inviata!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Abbiamo inviato un\'email con le istruzioni per reimpostare la tua password. Controlla la tua casella di posta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Torna al login'),
        ),
      ],
    );
  }

  Widget _buildResetForm(AsyncValue<void> authState) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Recupera la tua password',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Inserisci l\'indirizzo email associato al tuo account. Ti invieremo un link per reimpostare la password.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
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
              onPressed: authState.isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: authState.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Invia link di reset', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Torna al login'),
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
    );
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'Nessun utente trovato con questa email.';
    } else if (error.contains('invalid-email')) {
      return 'L\'indirizzo email non è valido.';
    } else if (error.contains('network-request-failed')) {
      return 'Problema di connessione. Controlla la tua rete.';
    } else if (error.contains('too-many-requests')) {
      return 'Troppe richieste. Riprova più tardi.';
    }
    return 'Errore: $error';
  }
}