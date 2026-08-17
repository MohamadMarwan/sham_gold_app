import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../config/app_config.dart';
import 'http_api_service.dart';

class SocketService {
  late socket_io.Socket socket;
  final HttpApiService _httpApiService = HttpApiService();
  
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
  Timer? _pingTimer;

  void initSocket() {
    socket = socket_io.io(
        AppConfig.baseUrl,
        socket_io.OptionBuilder()
            .setTransports(AppConfig.socketOptions['transports'])
            .setAuth({'apiKey': AppConfig.apiAccessKey})
            .setExtraHeaders({'x-api-key': AppConfig.apiAccessKey})
            .disableAutoConnect()
            .setReconnectionDelay(AppConfig.socketOptions['reconnectionDelay'])
            .setReconnectionAttempts(AppConfig.socketOptions['reconnectionAttempts'])
            .build());

    socket.connect();

    socket.onConnect((_) {
      isConnected = true;
      _connectionController.add(true);
      _startPingTimer();
    });

    socket.on('price_update', (data) => _priceUpdateController.add(data));
    socket.on('banner_update', (data) => _bannerUpdateController.add(data));
    socket.on('settings_update', (data) => _settingsUpdateController.add(data));
    socket.on('notification', (data) => _notificationController.add(data));
    socket.on('alert_triggered', (data) => _alertTriggeredController.add(data));

    socket.onDisconnect((_) {
      isConnected = false;
      _connectionController.add(false);
      _pingTimer?.cancel();
    });

    socket.onError((_) {
      _connectionController.add(false);
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (isConnected) {
        try {
          await _httpApiService.get('/api/status/ping');
        } catch (_) {}
      }
    });
  }

  void dispose() {
    _pingTimer?.cancel();
    socket.dispose();
    _connectionController.close();
    _priceUpdateController.close();
    _bannerUpdateController.close();
    _settingsUpdateController.close();
    _notificationController.close();
    _alertTriggeredController.close();
  }
}
