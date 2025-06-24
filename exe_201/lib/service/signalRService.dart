import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/itransport.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  final storage = const FlutterSecureStorage();
  String? _currentChatHubId;

  Function(Map<String, dynamic>)? onMessageReceived;
  Function(String)? onUserJoined;
  Function(String)? onUserLeft;

  Future<void> connect() async {
    int retryCount = 0;
    const maxRetries = 3;
    const timeoutDuration = Duration(seconds: 45);
    const baseUrl = 'https://mom-and-baby-e7dnhsgjcpgdb8cc.southeastasia-01.azurewebsites.net/chathub';

    final accessToken = await storage.read(key: 'access_token');
    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    // Pass token as query parameter like Java code
    final hubUrl = '$baseUrl?access_token=Bearer%20$accessToken';

    while (retryCount < maxRetries) {
      try {
        _hubConnection = HubConnectionBuilder()
            .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            transport: HttpTransportType.LongPolling, // Force LongPolling
            skipNegotiation: false,
            requestTimeout: timeoutDuration.inMilliseconds,
            logMessageContent: true,
          ),
        )
            .withAutomaticReconnect(retryDelays: [2000, 5000, 10000])
            .build();

        _hubConnection!.on('ReceiveMessage', (arguments) {
          if (arguments != null && arguments.isNotEmpty && arguments[0] is Map) {
            onMessageReceived?.call(Map<String, dynamic>.from(arguments[0] as Map));
          }
        });

        _hubConnection!.on('UserJoined', (arguments) {
          if (arguments != null && arguments.isNotEmpty) {
            onUserJoined?.call(arguments[0].toString());
          }
        });

        _hubConnection!.on('UserLeft', (arguments) {
          if (arguments != null && arguments.isNotEmpty) {
            onUserLeft?.call(arguments[0].toString());
          }
        });

        await _hubConnection!.start();
        return;
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          throw Exception('Failed to connect after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2));
      }
    }
    throw Exception('Failed to connect with LongPolling');
  }

  Future<void> joinChatHub(String chatHubId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      _currentChatHubId = chatHubId;
    } else {
      throw Exception('SignalR not connected. State: ${_hubConnection?.state}');
    }
  }

  Future<void> leaveChatHub(String chatHubId) async {
    _currentChatHubId = null;
  }

  Future<void> sendMessage(String chatHubId, String message) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('SendMessage', args: [chatHubId, message]);
      } catch (e) {
      }
    } else {
      throw Exception('SignalR not connected');
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
    }
  }

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  String? get currentChatHubId => _currentChatHubId;
}