import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef SignalREventCallback = void Function(List<Object?>? args);

/// SignalRService — Singleton & Resilient Real-Time Hub Client (Chuẩn Công Nghệ 2026)
/// - Áp dụng Singleton Pattern tuyệt đối: ngăn chặn tạo hàng chục kết nối trùng lặp.
/// - Kiểm tra trạng thái chặt chẽ (Connected / Connecting / Reconnecting) & gộp Future đang kết nối.
/// - Tích hợp withAutomaticReconnect(retryDelays: [0, 2000, 10000, 30000]) + Stream onReconnected
///   để các màn hình tự động đồng bộ lại dữ liệu bị lỡ (missed messages) sau khi rớt mạng.
class SignalRService {
  static final SignalRService _instance = SignalRService._internal();

  factory SignalRService() => _instance;

  static SignalRService get instance => _instance;

  SignalRService._internal();

  static const List<int> automaticReconnectDelays = <int>[0, 2000, 10000, 30000];

  HubConnection? _hubConnection;
  Timer? _retryTimer;
  Future<void>? _connectingFuture;

  // Lấy port từ biến môi trường, mặc định là 5169 nếu không có (Cổng Data Service)
  final String backendPort =
      const String.fromEnvironment('BACKEND_PORT', defaultValue: '5169');

  // --- FORUM HUB (Port 5000) ---
  HubConnection? _forumHubConnection;
  Timer? _forumRetryTimer;
  Future<void>? _forumConnectingFuture;
  int _forumRetryCount = 0;

  // Stream phát tín hiệu khi kết nối WebSocket được khôi phục sau sự cố mạng
  final StreamController<String?> _reconnectedController =
      StreamController<String?>.broadcast();

  Stream<String?> get onReconnected => _reconnectedController.stream;

  final List<VoidCallback> _forumReconnectedCallbacks = [];

  // Bộ điều phối sự kiện đa màn hình an toàn (tránh lỗi cast của HubConnection.off trong Dart 3
  // và tránh việc đóng 1 màn hình con làm mất listener của màn hình cha).
  final Map<String, Set<SignalREventCallback>> _mainHubListeners = {};
  final Set<String> _boundMainHubEvents = {};

  final Map<String, Set<SignalREventCallback>> _forumHubListeners = {};
  final Set<String> _boundForumHubEvents = {};

  HubConnection? get hubConnection => _hubConnection;
  HubConnection? get forumHubConnection => _forumHubConnection;
  HubConnectionState? get hubState => _hubConnection?.state;
  HubConnectionState? get forumHubState => _forumHubConnection?.state;

  bool get _isFlutterTestEnvironment {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // 1. DATA SERVICE HUB (http://localhost:5169/tuvihub)
  // ===========================================================================

  /// Hàm chuẩn mở kết nối có kiểm soát trạng thái chống Spam Console
  Future<void> startConnection() async {
    final hubConnection = _hubConnection;
    if (hubConnection != null &&
        (hubConnection.state == HubConnectionState.Connected ||
            hubConnection.state == HubConnectionState.Connecting ||
            hubConnection.state == HubConnectionState.Reconnecting)) {
      return;
    }

    if (_isFlutterTestEnvironment) {
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

  /// Giữ tương thích ngược với các điểm gọi cũ
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
        debugPrint('✅ SignalR: Đã phục hồi kết nối ($connectionId)');
        _emitReconnected(connectionId);
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
    if (_isFlutterTestEnvironment) {
      return;
    }
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

  void _addMainListener(String eventName, SignalREventCallback callback) {
    _mainHubListeners
        .putIfAbsent(eventName, () => <SignalREventCallback>{})
        .add(callback);
    _bindMainHubEvent(eventName);
  }

  void _removeMainListener(String eventName, [SignalREventCallback? callback]) {
    if (callback != null) {
      _mainHubListeners[eventName]?.remove(callback);
    } else {
      _mainHubListeners[eventName]?.clear();
    }
  }

  // 1. Lắng nghe sự kiện thanh toán thành công
  void listenToPaymentSuccess(SignalREventCallback onPaymentSuccess) {
    _addMainListener('PaymentSuccess', onPaymentSuccess);
  }

  void removePaymentSuccessListener([SignalREventCallback? callback]) {
    _removeMainListener('PaymentSuccess', callback);
  }

  // 2. Các hàm liên quan tới phòng Stream AI Text
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

  // Lắng nghe text AI stream về (dữ liệu trả về sẽ là mảng [chartId, textChunk])
  void listenToAiText(SignalREventCallback onReceiveAiText) {
    _addMainListener('ReceiveAiText', onReceiveAiText);
  }

  void removeAiTextListener([SignalREventCallback? callback]) {
    _removeMainListener('ReceiveAiText', callback);
  }

  // ===========================================================================
  // 2. FORUM HUB (http://localhost:5000/forumhub)
  // ===========================================================================

  void addForumReconnectedListener(VoidCallback callback) {
    if (!_forumReconnectedCallbacks.contains(callback)) {
      _forumReconnectedCallbacks.add(callback);
    }
  }

  void removeForumReconnectedListener(VoidCallback callback) {
    _forumReconnectedCallbacks.remove(callback);
  }

  void _emitReconnected(String? connectionId) {
    if (!_reconnectedController.isClosed) {
      _reconnectedController.add(connectionId);
    }
    for (final cb in List<VoidCallback>.of(_forumReconnectedCallbacks)) {
      try {
        cb();
      } catch (e) {
        debugPrint('Error in onreconnected callback: $e');
      }
    }
  }

  @visibleForTesting
  void simulateReconnected([String? connectionId = 'reconnected-test-id']) {
    _emitReconnected(connectionId);
  }

  @visibleForTesting
  void attachTestHubConnections({
    HubConnection? mainHub,
    HubConnection? forumHub,
  }) {
    if (mainHub != null) {
      _hubConnection = mainHub;
    }
    if (forumHub != null) {
      _forumHubConnection = forumHub;
    }
  }

  /// Khởi tạo kết nối ForumHub chuẩn Singleton + Chống Spam Console tuyệt đối
  Future<void> startForumConnection() async {
    final hubConnection = _forumHubConnection;
    if (hubConnection != null &&
        (hubConnection.state == HubConnectionState.Connected ||
            hubConnection.state == HubConnectionState.Connecting ||
            hubConnection.state == HubConnectionState.Reconnecting)) {
      return;
    }

    if (_isFlutterTestEnvironment) {
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

  /// Giữ tương thích ngược với các điểm gọi cũ
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
        _emitReconnected(connectionId);
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
          'ℹ️ SignalR ForumHub: Đang thử kết nối lại theo Exponential Backoff ($e)...');
      _scheduleForumRetry();
    }
  }

  void _scheduleForumRetry() {
    _forumRetryTimer?.cancel();
    if (_isFlutterTestEnvironment) {
      return;
    }
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

  @visibleForTesting
  void dispatchForumEventForTest(String eventName, List<Object?>? args) {
    final callbacks = _forumHubListeners[eventName];
    if (callbacks == null || callbacks.isEmpty) return;
    for (final cb in List<SignalREventCallback>.of(callbacks)) {
      cb(args);
    }
  }

  // Lắng nghe sự kiện Category cập nhật
  void listenToCategoryUpdated(SignalREventCallback onCategoryUpdated) {
    _addForumListeners(const ['OnCategoryUpdated'], onCategoryUpdated);
  }

  void removeCategoryUpdatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnCategoryUpdated'], callback);
  }

  // Lắng nghe sự kiện Topic cập nhật
  void listenToTopicUpdated(SignalREventCallback onTopicUpdated) {
    _addForumListeners(
        const ['OnTopicUpdated', 'topic-updated', 'TopicCreated'],
        onTopicUpdated);
  }

  void removeTopicUpdatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(
        const ['OnTopicUpdated', 'topic-updated', 'TopicCreated'], callback);
  }

  final Map<String, Map<String, SignalREventCallback>> _forumHubSubscribers = {};

  // Khóa Đăng Ký Đa Tuyến (Multi-Stream SignalR Guard 2026) bằng Subscriber ID
  void listenToReplyCreatedWithId(String subscriberId, SignalREventCallback onReplyCreated) {
    for (final eventName in const ['ReplyCreated', 'OnReplyCreated', 'reply-created']) {
      _forumHubSubscribers.putIfAbsent(eventName, () => {})[subscriberId] = onReplyCreated;
      _forumHubListeners.putIfAbsent(eventName, () => <SignalREventCallback>{}).add(onReplyCreated);
      _bindForumHubEvent(eventName);
    }
    unawaited(startForumConnection());
  }

  void removeReplyCreatedListenerWithId(String subscriberId) {
    for (final eventName in const ['ReplyCreated', 'OnReplyCreated', 'reply-created']) {
      final cb = _forumHubSubscribers[eventName]?.remove(subscriberId);
      if (cb != null) {
        _forumHubListeners[eventName]?.remove(cb);
      }
    }
  }

  // Lắng nghe sự kiện ReplyCreated (Thêm trả lời Real-Time chuẩn 2026)
  void listenToReplyCreated(SignalREventCallback onReplyCreated) {
    _addForumListeners(
        const ['ReplyCreated', 'OnReplyCreated', 'reply-created'],
        onReplyCreated);
  }

  void removeReplyCreatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(
        const ['ReplyCreated', 'OnReplyCreated', 'reply-created'], callback);
  }

  // Lắng nghe sự kiện DraftSaved (Đồng bộ bản nháp Real-Time chuẩn 2026)
  void listenToDraftSaved(SignalREventCallback onDraftSaved) {
    _addForumListeners(
        const ['DraftSaved', 'draft-updated', 'OnDraftSaved'],
        onDraftSaved);
  }

  void removeDraftSavedListener([SignalREventCallback? callback]) {
    _removeForumListeners(
        const ['DraftSaved', 'draft-updated', 'OnDraftSaved'], callback);
  }

  // Lắng nghe sự kiện Topic bị Xóa hàng loạt
  void listenToTopicBatchDeleted(SignalREventCallback onTopicBatchDeleted) {
    _addForumListeners(
        const ['TopicBatchDeleted', 'OnTopicBatchDeleted'],
        onTopicBatchDeleted);
  }

  void removeTopicBatchDeletedListener([SignalREventCallback? callback]) {
    _removeForumListeners(
        const ['TopicBatchDeleted', 'OnTopicBatchDeleted'], callback);
  }

  // Lắng nghe sự kiện Topic bị Xóa đơn lẻ
  void listenToTopicDeleted(SignalREventCallback onTopicDeleted) {
    _addForumListeners(
        const ['TopicDeleted', 'OnTopicDeleted'], onTopicDeleted);
  }

  void removeTopicDeletedListener([SignalREventCallback? callback]) {
    _removeForumListeners(
        const ['TopicDeleted', 'OnTopicDeleted'], callback);
  }

  // Lắng nghe sự kiện Category bị Khóa / Mở khóa
  void listenToCategoryLockedStatusChanged(
      SignalREventCallback onCategoryLocked) {
    _addForumListeners(
        const ['OnCategoryLockedStatusChanged'], onCategoryLocked);
  }

  void removeCategoryLockedStatusChangedListener(
      [SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnCategoryLockedStatusChanged'], callback);
  }

  // Lắng nghe sự kiện Topic bị Khóa / Mở khóa
  void listenToTopicLockedStatusChanged(SignalREventCallback onTopicLocked) {
    _addForumListeners(const ['OnTopicLockedStatusChanged'], onTopicLocked);
  }

  void removeTopicLockedStatusChangedListener(
      [SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnTopicLockedStatusChanged'], callback);
  }

  // Lắng nghe sự kiện Role người dùng thay đổi (RBAC)
  void listenToUserRoleChanged(SignalREventCallback onUserRoleChanged) {
    _addForumListeners(const ['OnUserRoleChanged'], onUserRoleChanged);
  }

  void removeUserRoleChangedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnUserRoleChanged'], callback);
  }

  // Lắng nghe sự kiện Hủy vị trí quản trị viên (Revoke Role)
  void listenToUserRoleRevoked(SignalREventCallback onUserRoleRevoked) {
    _addForumListeners(const ['OnUserRoleRevoked'], onUserRoleRevoked);
  }

  void removeUserRoleRevokedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnUserRoleRevoked'], callback);
  }

  // Lắng nghe sự kiện Cấp bậc sao / Đẳng vị thay đổi
  void listenToUserRankChanged(SignalREventCallback onUserRankChanged) {
    _addForumListeners(const ['OnUserRankChanged'], onUserRankChanged);
  }

  void removeUserRankChangedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnUserRankChanged'], callback);
  }

  // Lắng nghe sự kiện Ban Quản Trị thay đổi
  void listenToBoardMembersChanged(SignalREventCallback onBoardChanged) {
    _addForumListeners(const ['OnBoardMembersChanged'], onBoardChanged);
  }

  void removeBoardMembersChangedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnBoardMembersChanged'], callback);
  }

  // Lắng nghe sự kiện Hồ sơ Chuyên gia (MasterProfiles) cập nhật
  void listenToMasterProfileUpdated(SignalREventCallback onMasterUpdated) {
    _addForumListeners(const ['OnMasterProfileUpdated'], onMasterUpdated);
  }

  void removeMasterProfileUpdatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(const ['OnMasterProfileUpdated'], callback);
  }

  // Đóng kết nối
  void stopConnection() {
    _retryTimer?.cancel();
    _forumRetryTimer?.cancel();
    _hubConnection?.stop();
    _forumHubConnection?.stop();
  }
}

// Khởi tạo instance Global duy nhất để tái sử dụng ở mọi nơi
final signalRService = SignalRService();
