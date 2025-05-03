import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:mensa_scolastica/config/stripe_config.dart';

class PaymentService {
  // Inizializza Stripe - da chiamare all'avvio dell'app
  static Future<void> initialize() async {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  }

  // Crea un intent di pagamento
  static Future<Map<String, dynamic>> createPaymentIntent(int amount, String currency) async {
    try {
      // In un'app reale, questa richiesta dovrebbe essere inviata al tuo server backend
      // Il server creerebbe l'intent di pagamento utilizzando la chiave segreta di Stripe

      // Questo è un esempio semplificato per scopi dimostrativi
      // NOTA: In produzione, NON dovresti mai esporre la chiave segreta nell'app client
      final response = await http.post(
        Uri.parse(StripeConfig.paymentIntentEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount, // L'importo deve essere in centesimi
          'currency': currency,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Errore nella creazione del payment intent: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Errore nella comunicazione con Stripe: $e');
    }
  }

  // Gestione di un pagamento dimostrativo (per ambiente di test)
  static Future<Map<String, dynamic>> createMockPaymentIntent(int amount, String currency) {
    // Questo è un intent di pagamento simulato per l'ambiente di test
    // In un'app reale, dovresti ottenere questo dal tuo server
    return Future.value({
      'id': 'mock_payment_intent_id',
      'client_secret': 'mock_client_secret',
      'amount': amount,
      'currency': currency,
    });
  }

  // Processa un pagamento
  static Future<bool> processPayment(int amount, {String currency = StripeConfig.currency}) async {
    try {
      // In un ambiente reale, utilizza createPaymentIntent
      // Per la demo, utilizziamo il mock
      final paymentIntent = await createMockPaymentIntent(
        amount,
        currency,
      );

      // Se stai utilizzando un server reale, usa questo codice:
      /*
      // Configura i dettagli di pagamento
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Conferma il pagamento
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethod.id,
          ),
        ).toJson(),
      );
      */

      // Simula un pagamento di successo
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      print('Errore durante il pagamento: $e');
      return false;
    }
  }

  // Calcola l'importo del pagamento in base al numero di buoni
  static int calculatePaymentAmount(int numberOfMeals) {
    return numberOfMeals * StripeConfig.pricePerUnit;
  }
}