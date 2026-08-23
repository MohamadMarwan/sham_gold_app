import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../config/app_config.dart';
import 'http_api_service.dart';

/// Singleton Socket.io client for the Gold Sham app.
///
/// Using a Singleton ensures only one persistent WebSocket connection is ever
/// open, regardless of how many times the service is referenced across widgets.
class SocketService {
  // ─── Singleton ─────────────────────────────────────────────────────────────
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late socket_io.Socket socket;
  final HttpApiService _httpApiService = HttpApiService();

  // ─── Broadcast Streams ─────────────────────────────────────────────────────
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final StreamController<dynamic> _priceUpdateController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get priceUpdateStream => _priceUpdateController.stream;

  final StreamController<dynamic> _bannerUpdateController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get bannerUpdateStream => _bannerUpdateController.stream;

  final StreamController<dynamic> _settingsUpdateController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get settingsUpdateStream => _settingsUpdateController.stream;

  final StreamController<dynamic> _notificationController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get notificationStream => _notificationController.stream;

  final StreamController<dynamic> _alertTriggeredController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get alertTriggeredStream => _alertTriggeredController.stream;

  bool isConnected = false;
  bool _initialized = false;

  Timer? _pingTimer;
  Timer? _pollingTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 10;

  // ─── Init ───────────────────────────────────────────────────────────────────
  void initSocket() {
    if (_initialized) return; // Prevent double-initialization
    _initialized = true;

    socket = socket_io.io(
        AppConfig.baseUrl,
        socket_io.OptionBuilder()
            .setTransports(AppConfig.socketOptions['transports'] as List<String>)
            .setAuth({'apiKey': AppConfig.apiAccessKey})
            .setExtraHeaders({'x-api-key': AppConfig.apiAccessKey})
            .disableAutoConnect()
            .setReconnectionDelay(AppConfig.socketOptions['reconnectionDelay'] as int)
            .setReconnectionAttempts(AppConfig.socketOptions['reconnectionAttempts'] as int)
            .build());

    socket.connect();

    socket.onConnect((_) {
      isConnected = true;
      _reconnectionAttempts = 0;
      _stopPollingFallback(); // WebSocket restored — stop HTTP polling
      if (!_connectionController.isClosed) _connectionController.add(true);
      _startPingTimer();
    });

    socket.on('price_update', (data) {
      if (!_priceUpdateController.isClosed) _priceUpdateController.add(data);
    });
    socket.on('banner_update', (data) {
      if (!_bannerUpdateController.isClosed) _bannerUpdateController.add(data);
    });
    socket.on('settings_update', (data) {
      if (!_settingsUpdateController.isClosed) _settingsUpdateController.add(data);
    });
    socket.on('notification', (data) {
      if (!_notificationController.isClosed) _notificationController.add(data);
    });
    socket.on('alert_triggered', (data) {
      if (!_alertTriggeredController.isClosed) _alertTriggeredController.add(data);
    });

    socket.onDisconnect((_) {
      isConnected = false;
      if (!_connectionController.isClosed) _connectionController.add(false);
      _pingTimer?.cancel();
      _reconnectionAttempts++;
      if (_reconnectionAttempts >= _maxReconnectionAttempts) {
        debugPrint('[SocketService] Max reconnection attempts reached. Starting HTTP polling fallback.');
        _startPollingFallback();
      }
    });

    socket.onError((_) {
      if (!_connectionController.isClosed) _connectionController.add(false);
    });

    socket.onReconnectFailed((_) {
      debugPrint('[SocketService] Reconnection failed. Starting HTTP polling fallback.');
      _startPollingFallback();
    });
  }

  // ─── Ping Timer (keep-alive) ───────────────────────────────────────────────
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (isConnected) {
        try {
          await _httpApiService.get('/api/health');
        } catch (_) {}
      }
    });
  }

  // ─── HTTP Polling Fallback ─────────────────────────────────────────────────
  /// Falls back to polling /api/prices every 30 seconds when WebSocket is unavailable.
  void _startPollingFallback() {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (isConnected) {
        timer.cancel(); // WebSocket recovered — stop polling
        return;
      }
      try {
        final data = await _httpApiService.get('/api/prices');
        if (!_priceUpdateController.isClosed) _priceUpdateController.add(data);
      } catch (_) {}
    });
  }

  void _stopPollingFallback() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  void pause() {
    if (isConnected) {
      socket.disconnect();
      _pingTimer?.cancel();
    }
  }

  void resume() {
    if (!isConnected) {
      socket.connect();
      _stopPollingFallback(); // Attempt WebSocket first
    }
  }

  void dispose() {
    _pingTimer?.cancel();
    _pollingTimer?.cancel();
    socket.dispose();
    _connectionController.close();
    _priceUpdateController.close();
    _bannerUpdateController.close();
    _settingsUpdateController.close();
    _notificationController.close();
    _alertTriggeredController.close();
    _initialized = false;
  }
}

