import 'package:signalr_netcore/signalr_client.dart';
import 'package:flutter/foundation.dart';

class SignalRService {
  HubConnection? _hubConnection;

  // Lấy port từ biến môi trường, mặc định là 5169 nếu không có (Cổng Data Service)
  final String backendPort = const String.fromEnvironment('BACKEND_PORT', defaultValue: '5169');

  // Khởi tạo kết nối
  Future<void> initConnection() async {
    // Ép cứng kết nối vào Data Service (5169)
    final serverUrl = 'http://localhost:5169/tuvihub';
    
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl)
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({error}) {
      debugPrint("SignalR Connection Closed: $error");
    });

    try {
      await _hubConnection?.start();
      debugPrint("SignalR Connected to $serverUrl");
    } catch (e) {
      debugPrint("Error connecting to SignalR: $e");
    }
  }

  // 1. Lắng nghe sự kiện thanh toán thành công
  void listenToPaymentSuccess(Function(List<Object?>?) onPaymentSuccess) {
    _hubConnection?.on('PaymentSuccess', onPaymentSuccess);
  }

  void removePaymentSuccessListener() {
    _hubConnection?.off('PaymentSuccess');
  }

  // 2. Các hàm liên quan tới phòng Stream AI Text
  Future<void> joinChartGroup(String chartId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('JoinChartGroup', args: [chartId]);
      debugPrint("Joined chart group: $chartId");
    }
  }

  Future<void> leaveChartGroup(String chartId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('LeaveChartGroup', args: [chartId]);
      debugPrint("Left chart group: $chartId");
    }
  }

  // Lắng nghe text AI stream về (dữ liệu trả về sẽ là mảng [chartId, textChunk])
  void listenToAiText(Function(List<Object?>?) onReceiveAiText) {
    _hubConnection?.on('ReceiveAiText', onReceiveAiText);
  }

  void removeAiTextListener() {
    _hubConnection?.off('ReceiveAiText');
  }

  // Đóng kết nối
  void stopConnection() {
    _hubConnection?.stop();
  }
}

// Khởi tạo instance Global để tái sử dụng ở mọi nơi
final signalRService = SignalRService();
