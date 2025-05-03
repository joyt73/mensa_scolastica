import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/config/stripe_config.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/providers/transaction_provider.dart';
import 'package:mensa_scolastica/services/payment_service.dart';

class RechargeScreenCredit extends ConsumerStatefulWidget {
  final String studentId;

  const RechargeScreenCredit({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  ConsumerState<RechargeScreenCredit> createState() => _RechargeScreenCreditState();
}

class _RechargeScreenCreditState extends ConsumerState<RechargeScreenCredit> {
  int _selectedAmount = 5;
  final List<int> _rechargeOptions = [5, 10, 20, 50];
  bool _isProcessing = false;
  final _formKey = GlobalKey<FormState>();
  final _customAmountController = TextEditingController();
  bool _useCustomAmount = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _rechargeCredit() async {
    if (_useCustomAmount && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = _useCustomAmount
          ? int.parse(_customAmountController.text.trim())
          : _selectedAmount;

      // Calcola l'importo del pagamento in centesimi (5€ per buono)
      final paymentAmount = PaymentService.calculatePaymentAmount(amount);

      // Processa il pagamento con Stripe
      final paymentSuccess = await PaymentService.processPayment(paymentAmount);

      if (!paymentSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento fallito. Riprova.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Se il pagamento è riuscito, procedi con la ricarica
      final user = await ref.read(userProvider.future);
      if (user == null) {
        throw Exception('Utente non trovato');
      }

      final success = await ref.read(transactionNotifierProvider.notifier).rechargeCredit(
        widget.studentId,
        user.id,
        amount,
        note: 'Ricarica di $amount buoni pasto (€${amount * (StripeConfig.pricePerUnit / 100)})',
      );

      if (!mounted) return;

      if (success) {
        // Aggiorna i dati dello studente
        ref.refresh(studentByIdProvider(widget.studentId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ricarica completata con successo!'),
            backgroundColor: Colors.green,
          ),
        );

        // Torna alla schermata precedente
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la ricarica'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildPaymentInfo() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Informazioni di pagamento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Prezzo: €${StripeConfig.pricePerUnit / 100} per buono pasto',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Totale: €${_getTotalPrice()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pagamento sicuro tramite Stripe. Verrai reindirizzato alla pagina di pagamento dopo aver cliccato su "Ricarica".',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/stripe_logo.png',
                  height: 30,
                ),
                const SizedBox(width: 16),
                Image.asset(
                  'assets/card_icons.png',
                  height: 30,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTotalPrice() {
    final amount = _useCustomAmount
        ? (_customAmountController.text.isEmpty ? 0 : int.parse(_customAmountController.text))
        : _selectedAmount;
    final totalCents = amount * StripeConfig.pricePerUnit;
    return (totalCents / 100).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentByIdProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ricarica Buoni Pasto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: studentAsync.when(
          data: (student) {
            if (student == null) {
              return const Center(child: Text('Studente non trovato'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentInfoCard(student),
                const SizedBox(height: 24),
                const Text(
                  'Seleziona importo ricarica',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAmountSelection(),
                const SizedBox(height: 16),
                _buildCustomAmountField(),
                const SizedBox(height: 24),
                _buildRechargeButton(),
                const SizedBox(height: 32),
                _buildPaymentInfo(),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Errore: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard(Student student) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${student.firstName} ${student.lastName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${student.className} - ${student.school}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Saldo attuale',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student.credit} buoni',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _rechargeOptions.map((amount) {
        final isSelected = !_useCustomAmount && amount == _selectedAmount;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedAmount = amount;
              _useCustomAmount = false;
            });
          },
          child: Container(
            width: 70,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomAmountField() {
    return Row(
      children: [
        Checkbox(
          value: _useCustomAmount,
          onChanged: (value) {
            setState(() {
              _useCustomAmount = value ?? false;
            });
          },
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: TextFormField(
              controller: _customAmountController,
              enabled: _useCustomAmount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Importo personalizzato',
                border: OutlineInputBorder(),
                helperText: 'Inserisci il numero di buoni',
              ),
              validator: (value) {
                if (_useCustomAmount) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un importo';
                  }
                  try {
                    final amount = int.parse(value);
                    if (amount <= 0) {
                      return 'L\'importo deve essere maggiore di 0';
                    }
                    if (amount > 100) {
                      return 'L\'importo massimo è 100';
                    }
                  } catch (e) {
                    return 'Inserisci un numero valido';
                  }
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRechargeButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _rechargeCredit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          'Ricarica ${_useCustomAmount ? (_customAmountController.text.isEmpty ? "0" : _customAmountController.text) : _selectedAmount} buoni',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

}