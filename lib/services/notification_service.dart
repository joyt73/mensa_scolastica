import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Inizializza le notifiche
  Future<void> initialize(BuildContext context) async {
    // Richiedi il permesso per le notifiche
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Configurazione per Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configurazione per iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Inizializza le notifiche locali
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          // Gestisci il tap sulla notifica
          _handleNotification(details.payload, context);
        },
      );

      // Definisci i canali per Android
      await _setupNotificationChannels();

      // Ascolta i messaggi quando l'app è in primo piano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showNotification(message);
      });

      // Gestisci i messaggi quando l'app è in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotification(message.data['action'], context);
      });

      // Ottieni e salva il token FCM
      await _updateFcmToken();
    }
  }

  // Configura i canali di notifica per Android
  Future<void> _setupNotificationChannels() async {
    const lowBalanceChannel = AndroidNotificationChannel(
      'low_balance_channel',
      'Notifiche Saldo Basso',
      description: 'Notifiche quando il saldo buoni è basso',
      importance: Importance.high,
    );

    const mealChannel = AndroidNotificationChannel(
      'meal_channel',
      'Notifiche Pasti',
      description: 'Notifiche quando viene registrato un pasto',
      importance: Importance.high,
    );

    const rechargeChannel = AndroidNotificationChannel(
      'recharge_channel',
      'Notifiche Ricariche',
      description: 'Notifiche quando viene effettuata una ricarica',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(lowBalanceChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(mealChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(rechargeChannel);
  }

  // Mostra una notifica locale
  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      final androidDetails = AndroidNotificationDetails(
        message.data['channel'] ?? 'default_channel',
        message.data['channel_name'] ?? 'Default Channel',
        channelDescription: message.data['channel_description'] ?? 'Default channel for notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
      );

      final iosDetails = const DarwinNotificationDetails();

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: message.data['action'],
      );
    }
  }

  // Gestisci le azioni delle notifiche
  void _handleNotification(String? payload, BuildContext context) {
    if (payload == null) return;

    // Esempio di gestione delle azioni
    switch (payload) {
      case 'open_student_details':
        final studentId = payload.split(':')[1];
        // Naviga ai dettagli dello studente
        // Navigator.pushNamed(context, '/student_details', arguments: studentId);
        break;
      case 'open_recharge':
      // Naviga alla schermata di ricarica
      // Navigator.pushNamed(context, '/recharge');
        break;
      default:
      // Gestione predefinita
        break;
    }
  }

  // Aggiorna il token FCM
  Future<String?> _updateFcmToken() async {
    final token = await _messaging.getToken();

    // In un'app reale, qui dovresti salvare il token nel tuo backend
    // per inviare notifiche personalizzate a questo dispositivo
    print('FCM Token: $token');

    return token;
  }

  // Invia una notifica locale di test
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String channelId = 'default_channel',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Default Channel',
      channelDescription: 'Default channel for notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails();

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      title,
      body,
      platformDetails,
    );
  }

  // Invia una notifica di saldo basso
  Future<void> sendLowBalanceNotification({
    required String studentName,
    required int balance,
  }) async {
    await sendTestNotification(
      title: 'Saldo buoni basso',
      body: '$studentName ha solo $balance buoni pasto rimanenti. Ricarica il saldo.',
      channelId: 'low_balance_channel',
    );
  }

  // Invia una notifica di pasto registrato
  Future<void> sendMealNotification({
    required String studentName,
    required String operatorName,
  }) async {
    await sendTestNotification(
      title: 'Pasto registrato',
      body: 'Un pasto è stato registrato per $studentName da $operatorName.',
      channelId: 'meal_channel',
    );
  }

  // Invia una notifica di ricarica effettuata
  Future<void> sendRechargeNotification({
    required String studentName,
    required int amount,
  }) async {
    await sendTestNotification(
      title: 'Ricarica effettuata',
      body: 'Hai ricaricato $amount buoni pasto per $studentName.',
      channelId: 'recharge_channel',
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});