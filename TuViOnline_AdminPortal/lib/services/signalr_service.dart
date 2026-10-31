import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef SignalREventCallback = void Function(List<Object?>? args);

/// SignalRService (Admin Portal) — Singleton & Resilient Real-Time Hub Client
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();

  factory SignalRService() => _instance;

  static SignalRService get instance => _instance;

  SignalRService._internal();

  static const List<int> automaticReconnectDelays = <int>[0, 2000, 10000, 30000];

  HubConnection? _hubConnection;
  Timer? _retryTimer;
  Future<void>? _connectingFuture;

  final String backendPort =
      const String.fromEnvironment('BACKEND_PORT', defaultValue: '5169');

  HubConnection? _forumHubConnection;
  Timer? _forumRetryTimer;
  Future<void>? _forumConnectingFuture;
  int _forumRetryCount = 0;

  final StreamController<String?> _reconnectedController =
      StreamController<String?>.broadcast();

  Stream<String?> get onReconnected => _reconnectedController.stream;

  final Map<String, Set<SignalREventCallback>> _mainHubListeners = {};
  final Set<String> _boundMainHubEvents = {};

  final Map<String, Set<SignalREventCallback>> _forumHubListeners = {};
  final Set<String> _boundForumHubEvents = {};

  Future<void> startConnection() async {
    final hubConnection = _hubConnection;
    if (hubConnection != null &&
        (hubConnection.state == HubConnectionState.Connected ||
            hubConnection.state == HubConnectionState.Connecting ||
            hubConnection.state == HubConnectionState.Reconnecting)) {
      return;
    }

    if (_connectingFuture != null) {
      return _connectingFuture!;
    }

    _connectingFuture = _doStartConnection();
    try {
      await _connectingFuture;
    } finally {
      _connectingFuture = null;
    }
  }

  Future<void> initConnection() => startConnection();

  Future<void> _doStartConnection() async {
    _retryTimer?.cancel();
    const serverUrl = 'http://localhost:5169/tuvihub';

    if (_hubConnection == null) {
      _hubConnection = HubConnectionBuilder()
          .withUrl(serverUrl)
          .withAutomaticReconnect(retryDelays: automaticReconnectDelays)
          .build();

      _boundMainHubEvents.clear();
      _bindAllMainHubEvents();

      _hubConnection?.onclose(({error}) {
        debugPrint(
            'SignalR: Kết nối đã đóng ($error), đang chuẩn bị kết nối lại...');
        _scheduleRetry();
      });

      _hubConnection?.onreconnected(({connectionId}) {
        if (!_reconnectedController.isClosed) {
          _reconnectedController.add(connectionId);
        }
      });
    } else {
      _bindAllMainHubEvents();
    }

    if (_hubConnection?.state == HubConnectionState.Connected ||
        _hubConnection?.state == HubConnectionState.Connecting ||
        _hubConnection?.state == HubConnectionState.Reconnecting) {
      return;
    }

    try {
      await _hubConnection?.start();
      debugPrint('✅ SignalR: Đã kết nối thành công tới $serverUrl');
    } catch (e) {
      debugPrint(
          'ℹ️ SignalR: Backend chưa sẵn sàng (đang đợi Backend mở cổng 5169). Sẽ tự động kết nối lại sau 5s...');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () {
      final state = _hubConnection?.state;
      if (state != HubConnectionState.Connected &&
          state != HubConnectionState.Connecting &&
          state != HubConnectionState.Reconnecting) {
        startConnection();
      }
    });
  }

  void _bindMainHubEvent(String eventName) {
    final hub = _hubConnection;
    if (hub == null || _boundMainHubEvents.contains(eventName)) return;
    _boundMainHubEvents.add(eventName);
    hub.on(eventName, (args) {
      final callbacks = _mainHubListeners[eventName];
      if (callbacks == null || callbacks.isEmpty) return;
      for (final cb in List<SignalREventCallback>.of(callbacks)) {
        try {
          cb(args);
        } catch (e) {
          debugPrint('SignalR [$eventName] listener error: $e');
        }
      }
    });
  }

  void _bindAllMainHubEvents() {
    for (final eventName in _mainHubListeners.keys) {
      _bindMainHubEvent(eventName);
    }
  }

  void listenToPaymentSuccess(SignalREventCallback onPaymentSuccess) {
    _mainHubListeners
        .putIfAbsent('PaymentSuccess', () => <SignalREventCallback>{})
        .add(onPaymentSuccess);
    _bindMainHubEvent('PaymentSuccess');
  }

  void removePaymentSuccessListener([SignalREventCallback? callback]) {
    if (callback != null) {
      _mainHubListeners['PaymentSuccess']?.remove(callback);
    } else {
      _mainHubListeners['PaymentSuccess']?.clear();
    }
  }

  Future<void> joinChartGroup(String chartId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('JoinChartGroup', args: [chartId]);
      debugPrint('Joined chart group: $chartId');
    }
  }

  Future<void> leaveChartGroup(String chartId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('LeaveChartGroup', args: [chartId]);
      debugPrint('Left chart group: $chartId');
    }
  }

  void listenToAiText(SignalREventCallback onReceiveAiText) {
    _mainHubListeners
        .putIfAbsent('ReceiveAiText', () => <SignalREventCallback>{})
        .add(onReceiveAiText);
    _bindMainHubEvent('ReceiveAiText');
  }

  void removeAiTextListener([SignalREventCallback? callback]) {
    if (callback != null) {
      _mainHubListeners['ReceiveAiText']?.remove(callback);
    } else {
      _mainHubListeners['ReceiveAiText']?.clear();
    }
  }

  Future<void> startForumConnection() async {
    final hubConnection = _forumHubConnection;
    if (hubConnection != null &&
        (hubConnection.state == HubConnectionState.Connected ||
            hubConnection.state == HubConnectionState.Connecting ||
            hubConnection.state == HubConnectionState.Reconnecting)) {
      return;
    }

    if (_forumConnectingFuture != null) {
      return _forumConnectingFuture!;
    }

    _forumConnectingFuture = _doStartForumConnection();
    try {
      await _forumConnectingFuture;
    } finally {
      _forumConnectingFuture = null;
    }
  }

  Future<void> initForumConnection() => startForumConnection();

  Future<void> _doStartForumConnection() async {
    _forumRetryTimer?.cancel();
    const serverUrl = 'http://localhost:5000/forumhub';

    if (_forumHubConnection == null) {
      _forumHubConnection = HubConnectionBuilder()
          .withUrl(serverUrl)
          .withAutomaticReconnect(retryDelays: automaticReconnectDelays)
          .build();

      _boundForumHubEvents.clear();
      _bindAllForumHubEvents();

      _forumHubConnection?.onclose(({error}) {
        debugPrint(
            'SignalR ForumHub: Kết nối đã đóng ($error), đang chuẩn bị kết nối lại...');
        _scheduleForumRetry();
      });

      _forumHubConnection?.onreconnected(({connectionId}) {
        debugPrint(
            '✅ SignalR ForumHub: Đã phục hồi kết nối ($connectionId), đồng bộ dữ liệu mới nhất...');
        _forumRetryCount = 0;
        if (!_reconnectedController.isClosed) {
          _reconnectedController.add(connectionId);
        }
      });
    } else {
      _bindAllForumHubEvents();
    }

    if (_forumHubConnection?.state == HubConnectionState.Connected ||
        _forumHubConnection?.state == HubConnectionState.Connecting ||
        _forumHubConnection?.state == HubConnectionState.Reconnecting) {
      return;
    }

    try {
      await _forumHubConnection?.start();
      debugPrint('✅ SignalR ForumHub: Đã kết nối thành công tới $serverUrl');
      _forumRetryCount = 0;
    } catch (e) {
      debugPrint(
          'ℹ️ SignalR ForumHub: Backend chưa sẵn sàng ($e). Sẽ tự động kết nối lại...');
      _scheduleForumRetry();
    }
  }

  void _scheduleForumRetry() {
    _forumRetryTimer?.cancel();
    final delaySeconds = (_forumRetryCount < 5) ? (1 << _forumRetryCount) : 30;
    _forumRetryCount++;
    _forumRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      final state = _forumHubConnection?.state;
      if (state != HubConnectionState.Connected &&
          state != HubConnectionState.Connecting &&
          state != HubConnectionState.Reconnecting) {
        startForumConnection();
      }
    });
  }

  void _bindForumHubEvent(String eventName) {
    final hub = _forumHubConnection;
    if (hub == null || _boundForumHubEvents.contains(eventName)) return;
    _boundForumHubEvents.add(eventName);
    hub.on(eventName, (args) {
      final callbacks = _forumHubListeners[eventName];
      if (callbacks == null || callbacks.isEmpty) return;
      for (final cb in List<SignalREventCallback>.of(callbacks)) {
        try {
          cb(args);
        } catch (e) {
          debugPrint('SignalR ForumHub [$eventName] listener error: $e');
        }
      }
    });
  }

  void _bindAllForumHubEvents() {
    for (final eventName in _forumHubListeners.keys) {
      _bindForumHubEvent(eventName);
    }
  }

  void _addForumListeners(
      List<String> eventNames, SignalREventCallback callback) {
    for (final eventName in eventNames) {
      _forumHubListeners
          .putIfAbsent(eventName, () => <SignalREventCallback>{})
          .add(callback);
      _bindForumHubEvent(eventName);
    }
    unawaited(startForumConnection());
  }

  void _removeForumListeners(List<String> eventNames,
      [SignalREventCallback? callback]) {
    for (final eventName in eventNames) {
      if (callback != null) {
        _forumHubListeners[eventName]?.remove(callback);
      } else {
        _forumHubListeners[eventName]?.clear();
      }
    }
  }

  void listenToCategoryUpdated(SignalREventCallback onCategoryUpdated) {
    _addForumListeners(const ['OnCategoryUpdated'], onCategoryUpdated);
  }

  void removeCategoryUpdatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnCategoryUpdated'], callback);
  }

  void listenToTopicUpdated(SignalREventCallback onTopicUpdated) {
    _addForumListeners(
        const ['OnTopicUpdated', 'topic-updated', 'TopicCreated'],
        onTopicUpdated);
  }

  void removeTopicUpdatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(
        const ['OnTopicUpdated', 'topic-updated', 'TopicCreated'], callback);
  }

  void listenToCategoryLockedStatusChanged(
      SignalREventCallback onCategoryLocked) {
    _addForumListeners(
        const ['OnCategoryLockedStatusChanged'], onCategoryLocked);
  }

  void removeCategoryLockedStatusChangedListener(
      [SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnCategoryLockedStatusChanged'], callback);
  }

  void listenToTopicLockedStatusChanged(SignalREventCallback onTopicLocked) {
    _addForumListeners(const ['OnTopicLockedStatusChanged'], onTopicLocked);
  }

  void removeTopicLockedStatusChangedListener(
      [SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnTopicLockedStatusChanged'], callback);
  }

  void listenToUserRoleChanged(SignalREventCallback onUserRoleChanged) {
    _addForumListeners(const ['OnUserRoleChanged'], onUserRoleChanged);
  }

  void removeUserRoleChangedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnUserRoleChanged'], callback);
  }

  void listenToUserStatusChanged(SignalREventCallback onUserStatusChanged) {
    _addForumListeners(const ['OnUserStatusChanged'], onUserStatusChanged);
  }

  void removeUserStatusChangedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnUserStatusChanged'], callback);
  }

  void listenToUserRoleRevoked(SignalREventCallback onUserRoleRevoked) {
    _addForumListeners(const ['OnUserRoleRevoked'], onUserRoleRevoked);
  }

  void removeUserRoleRevokedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnUserRoleRevoked'], callback);
  }

  void listenToUserRankChanged(SignalREventCallback onUserRankChanged) {
    _addForumListeners(const ['OnUserRankChanged'], onUserRankChanged);
  }

  void removeUserRankChangedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnUserRankChanged'], callback);
  }

  void listenToBoardMembersChanged(SignalREventCallback onBoardChanged) {
    _addForumListeners(const ['OnBoardMembersChanged'], onBoardChanged);
  }

  void removeBoardMembersChangedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnBoardMembersChanged'], callback);
  }

  void listenToMasterProfileUpdated(SignalREventCallback onMasterUpdated) {
    _addForumListeners(const ['OnMasterProfileUpdated'], onMasterUpdated);
  }

  void removeMasterProfileUpdatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnMasterProfileUpdated'], callback);
  }

  void stopConnection() {
    _retryTimer?.cancel();
    _forumRetryTimer?.cancel();
    _hubConnection?.stop();
    _forumHubConnection?.stop();
  }
}

final signalRService = SignalRService();
