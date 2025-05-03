class StripeConfig {
  // Utilizza la chiave pubblica di test di Stripe; nel codice di produzione sostituisci con quella reale
  static const String publishableKey = 'pk_test_51NxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

  // URL del tuo server che gestirà la creazione del payment intent
  // In un ambiente reale, questo dovrebbe essere un endpoint del tuo backend
  static const String paymentIntentEndpoint = 'https://tuoserver.com/api/create-payment-intent';

  // Valuta predefinita
  static const String currency = 'EUR';

  // Prezzo per unità (in centesimi)
  static const int pricePerUnit = 500; // 5€
}