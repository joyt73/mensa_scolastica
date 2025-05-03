import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/models/user.dart';
import 'package:mensa_scolastica/screens/home/operator_tablet_screen.dart';
import 'package:mensa_scolastica/utils/responsive_layout.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:mensa_scolastica/providers/auth_provider.dart';
import 'package:mensa_scolastica/providers/student_provider.dart';
import 'package:mensa_scolastica/providers/transaction_provider.dart';
import 'package:mensa_scolastica/screens/profile/profile_screen.dart';
import 'package:mensa_scolastica/services/connectivity_service.dart';
import 'package:mensa_scolastica/services/sync_service.dart';
import 'package:mensa_scolastica/widgets/student_details_card.dart';
import 'package:workmanager/workmanager.dart';

class OperatorHomeScreen extends ConsumerStatefulWidget {
  const OperatorHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends ConsumerState<OperatorHomeScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  String? _scannedQrCode;
  bool _isProcessing = false;
  bool _isSyncing = false;
  bool _isOffline = false;
  Student? _offlineStudent;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _syncDataIfNeeded();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _checkConnectivity() {
    ref.listen<AsyncValue<ConnectivityStatus>>(
      connectivityStatusProvider,
          (_, next) {
        next.whenData((status) {
          setState(() {
            _isOffline = status == ConnectivityStatus.offline;
          });

          // Se torna online, sincronizza
          if (status == ConnectivityStatus.online) {
            _syncPendingTransactions();
          }
        });
      },
    );
  }

  Future<void> _syncDataIfNeeded() async {
    final user = await ref.read(userProvider.future);
    if (user == null || user.school == null) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncDataToLocal(user.school!);
      await syncService.syncPendingTransactions();
    } catch (e) {
      print('Errore durante la sincronizzazione: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _syncPendingTransactions() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncPendingTransactions();

      // Aggiorna il contatore delle transazioni pending
      ref.refresh(pendingTransactionsCountProvider);
    } catch (e) {
      print('Errore durante la sincronizzazione: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _processQrCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _scannedQrCode = qrCode;
      _offlineStudent = null;
    });

    try {
      if (_isOffline) {
        // Modalità offline: cerca nella cache locale
        final syncService = ref.read(syncServiceProvider);
        final student = await syncService.findStudentByQrCodeOffline(qrCode);

        setState(() {
          _offlineStudent = student;
        });
      }
    } catch (e) {
      print('Errore durante la ricerca offline: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _registerMeal(Student student) async {
    final appUser = await ref.read(userProvider.future);
    if (appUser == null) return;

    bool success = false;

    if (_isOffline) {
      // Modalità offline
      final syncService = ref.read(syncServiceProvider);
      success = await syncService.registerMealOffline(
        student.id,
        appUser.id,
        student.school,
        'Pasto registrato offline',
      );

      // Aggiorna il contatore delle transazioni pending
      ref.refresh(pendingTransactionsCountProvider);
    } else {
      // Modalità online
      success = await ref.read(transactionNotifierProvider.notifier).registerMeal(
        student.id,
        appUser.id,
        student.school,
      );
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOffline
              ? 'Pasto registrato in modalità offline. Verrà sincronizzato quando tornerai online.'
              : 'Pasto registrato con successo'),
          backgroundColor: Colors.green,
        ),
      );

      if (!_isOffline) {
        // Ricaricare i dati online
        ref.refresh(studentByQrProvider(_scannedQrCode!));
      } else {
        // In modalità offline, aggiorna lo studente nella cache
        final syncService = ref.read(syncServiceProvider);
        _offlineStudent = await syncService.findStudentByQrCodeOffline(_scannedQrCode!);
        setState(() {});
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nella registrazione del pasto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _resetScanner() {
    setState(() {
      _scannedQrCode = null;
      _offlineStudent = null;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _buildMobileLayout(context),
      tabletLayout: const OperatorTabletScreen(),
    );
  }

  @override
  Widget _buildMobileLayout(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final studentAsync = !_isOffline && _scannedQrCode != null
        ? ref.watch(studentByQrProvider(_scannedQrCode!))
        : null;
    final pendingCountAsync = ref.watch(pendingTransactionsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operatore Mensa'),
        actions: [
          // Badge per mostrare transazioni pending
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.sync),
                onPressed: _isOffline ? null : _syncPendingTransactions,
                tooltip: 'Sincronizza',
              ),
              pendingCountAsync.when(
                data: (count) {
                  if (count > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
            tooltip: 'Profilo',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Indicatore modalità offline
              if (_isOffline)
                Container(
                  color: Colors.orange,
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Modalità Offline - Le modifiche verranno sincronizzate quando tornerai online',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _scannedQrCode == null
                    ? MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _processQrCode(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                )
                    : _isOffline
                    ? _buildOfflineStudentView()
                    : _buildOnlineStudentView(userAsync, studentAsync),
              ),
            ],
          ),

          // Overlay di caricamento
          if (_isSyncing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Sincronizzazione in corso...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineStudentView() {
    if (_offlineStudent == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Studente non trovato nella cache offline',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Controlla la connessione o sincronizza nuovamente i dati quando tornerai online.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetScanner,
              child: const Text('Scansiona un altro QR'),
            ),
          ],
        ),
      );
    }

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            children: [
            StudentDetailsCard(student: _offlineStudent!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stai operando in modalità offline. I dati potrebbero non essere aggiornati.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
// Continua dal metodo _buildOfflineStudentView
              ElevatedButton(
                onPressed: () => _registerMeal(_offlineStudent!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                ),
                child: const Text(
                  'Registra Pasto (Offline)',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetScanner,
                child: const Text('Scansiona Nuovo QR'),
              ),
            ],
        ),
    );
  }

  Widget _buildOnlineStudentView(AsyncValue<AppUser?> userAsync, AsyncValue<Student?>? studentAsync) {
    return userAsync.when(
      data: (user) {
        if (user == null) return const Center(child: Text('Utente non trovato'));

        return studentAsync?.when(
          data: (student) {
            if (student == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('QR Code non valido'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resetScanner,
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  StudentDetailsCard(student: student),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _registerMeal(student),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                    ),
                    child: const Text(
                      'Registra Pasto',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _resetScanner,
                    child: const Text('Scansiona Nuovo QR'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Errore nel caricamento dei dati'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetScanner,
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ) ??
            const Center(child: CircularProgressIndicator());
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Errore nel caricamento dell\'utente')),
    );
  }
}