import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';
import 'package:mensa_scolastica/screens/auth/login_screen.dart';
import 'package:mensa_scolastica/screens/home/operator_home_screen.dart';
import 'package:mensa_scolastica/screens/home/parent_home_screen.dart';
import 'package:mensa_scolastica/screens/home/admin_home_screen.dart';
import 'package:mensa_scolastica/theme/app_theme.dart';

import 'services/notification_service.dart';

// Provider per il tema
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// Notifier per gestire il tema
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_loadTheme());

  // Carica il tema iniziale
  static ThemeMode _loadTheme() {
    // In un'app reale, qui caricheresti il tema dalle preferenze
    // Per ora, useremo il tema di sistema
    return ThemeMode.system;
  }

  // Cambia il tema
  void setTheme(ThemeMode theme) {
    state = theme;
    // In un'app reale, qui salveresti il tema nelle preferenze
  }

  // Alterna tra tema chiaro e scuro
  void toggleTheme() {
    state = state == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}

class MensaApp extends ConsumerStatefulWidget {
  const MensaApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MensaApp> createState() => _MensaAppState();
}

class _MensaAppState extends ConsumerState<MensaApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Mensa Scolastica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: ref.watch(authStateProvider).when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }

          // Determina il tipo di utente e reindirizza alla schermata appropriata
          return ref.watch(userRoleProvider).when(
            data: (role) {
              switch (role) {
                case 'operatore':
                  return const OperatorHomeScreen();
                case 'genitore':
                  return const ParentHomeScreen();
                case 'admin':
                  return const AdminHomeScreen();
                default:
                  return const LoginScreen();
              }
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const LoginScreen(),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}