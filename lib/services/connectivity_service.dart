import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus {
  online,
  offline,
}

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityStatus> _controller = StreamController.broadcast();

  Stream<ConnectivityStatus> get status => _controller.stream;

  ConnectivityService() {
    // Inizializza lo stato iniziale
    _init();

    // Ascolta i cambiamenti di connettività
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      // Si passa da online a offline o viceversa
      _checkStatus(result);
    });
  }

  Future<void> _init() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    _checkStatus(result);
  }

  void _checkStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _controller.add(ConnectivityStatus.offline);
    } else {
      _controller.add(ConnectivityStatus.online);
    }
  }

  Future<bool> isOnline() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.status;
});