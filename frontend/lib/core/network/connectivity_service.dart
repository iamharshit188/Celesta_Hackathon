import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamController<ConnectivityResult> _connectivityController;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  ConnectivityService() {
    _connectivityController = StreamController<ConnectivityResult>.broadcast();
    _initConnectivity();
  }

  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionStatus = result;
    _connectivityController.add(result);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
      );
    } catch (e) {
      _connectivityController.add(ConnectivityResult.none);
    }
  }

  bool get isConnected => _connectionStatus != ConnectivityResult.none;

  Future<ConnectivityResult> get currentConnectivity async {
    return await _connectivity.checkConnectivity();
  }

  bool isConnectivityResult(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  String connectivityResultToString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'None';
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _connectivityController.close();
  }
}

// Riverpod providers
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityStreamProvider = StreamProvider<ConnectivityResult>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});

final isConnectedProvider = Provider<bool>((ref) {
  final connectivityAsyncValue = ref.watch(connectivityStreamProvider);
  return connectivityAsyncValue.when(
    data: (connectivity) => connectivity != ConnectivityResult.none,
    loading: () => false,
    error: (_, __) => false,
  );
});

final currentConnectivityProvider = FutureProvider<ConnectivityResult>((ref) async {
  final service = ref.watch(connectivityServiceProvider);
  return service.currentConnectivity;
});
