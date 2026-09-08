import 'dart:async';
import 'package:edu_gym/features/account/presentation/screens/payment_canceled_screen.dart';
import 'package:edu_gym/features/account/presentation/screens/payment_success_screen.dart';
import 'package:edu_gym/main.dart';
import 'package:edu_gym/modal/subscription_details.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/api/api.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  final _paymentEventController = StreamController<String>.broadcast();
  Stream<String> get paymentEvents => _paymentEventController.stream;

  void initSocket(String deviceId) async {
    if (_socket != null && _socket!.connected) return;

    final cookie = await TokenApi.getCookie();
    final accessToken = await TokenApi().getAccessToken();

    // SOCKET_URL is the domain part of baseUrl
    final socketUrl = Api.baseUrl.replaceAll('/api/v1', '');

    // print('🔌 Initializing Socket connection to: $socketUrl');

    _socket = IO.io(socketUrl, 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({
          'Authorization': 'Bearer $accessToken',
          'Cookie': cookie ?? '',
        })
        .enableAutoConnect()
        .build()
    );

    _socket!.onConnect((_) {
      // print('✅ Socket Connected');
      // Mirroring React: Register the device with the backend
      // print('📤 Emitting register with deviceID: $deviceId');
      _socket!.emit('register', {'deviceID': deviceId});
    });

    _socket!.onDisconnect((_) {
      // print('❌ Socket Disconnected');
    });

    _socket!.onConnectError((err) {
      // Mirroring React: Silent connect error
    });

    _socket!.on('message', (data) {
      // Mirroring React: Silent message handler
    });

    _socket!.on('payment_success', (data) async {
      // print('💰 Payment Success Socket Event Received: $data');
      await _handleSubscriptionUpdate();
      _paymentEventController.add('payment_success');
      String? sessionId;
      if (data is Map) {
        sessionId = data['session_id']?.toString() ?? data['sessionId']?.toString();
      }
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(sessionId: sessionId),
          ),
        );
      }
    });

    _socket!.on('payment_failed', (data) async {
      // print('❌ Payment Failed Socket Event Received: $data');
      await _handleSubscriptionUpdate();
      _paymentEventController.add('payment_failed');
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => const PaymentCanceledScreen(),
          ),
        );
      }
    });

    _socket!.on('subscription_canceled', (data) async {
      // print('📉 Subscription Canceled Socket Event Received: $data');
      await _handleSubscriptionUpdate();
      _paymentEventController.add('subscription_canceled');
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => const PaymentCanceledScreen(),
          ),
        );
      }
    });

    _socket!.onError((data) {
      // Silent error
    });
  }

  Future<void> _handleSubscriptionUpdate() async {
    // 1. Fetch latest subscription from API
    final result = await Api.instance.getLatestSubscription();
    
    await result.fold(
      (failure) async {
        // print('❌ Failed to fetch latest subscription: ${failure.message}');
      },
      (data) async {
        // 2. Update local state
        if (data['data'] != null && data['data']['subscription'] != null) {
          final subJson = data['data']['subscription'];
          final latestSub = SubscriptionDetails.fromJson(subJson);
          await TokenApi().updateSubscriptionDetails(latestSub);
          // print('✅ Local subscription state updated from Socket Event');
        }
      }
    );
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      // print('🔌 Socket Manually Disconnected');
    }
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      // print('⚠️ Cannot emit $event: Socket not connected');
    }
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }
}
