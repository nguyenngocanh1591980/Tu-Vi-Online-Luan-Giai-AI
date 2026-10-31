import 'dart:async';
import 'package:flutter/material.dart';
import '../models/forum_stats_model.dart';
import '../services/forum_stats_repository.dart';

class ForumStatsProvider extends ChangeNotifier {
  final ForumStatsRepository repository;
  final Duration refreshInterval;
  final bool autoStartTimer;
  final bool autoFetch;

  ForumGeneralStats _generalStats = ForumGeneralStats.defaults();
  ForumOnlineStats _onlineStats = ForumOnlineStats.defaults();
  bool _isLoading = false;
  Timer? _refreshTimer;
  bool _isDisposed = false;

  ForumStatsProvider({
    ForumStatsRepository? repository,
    this.refreshInterval = const Duration(minutes: 60),
    this.autoStartTimer = true,
    this.autoFetch = true,
  }) : repository = repository ?? HttpForumStatsRepository() {
    if (autoFetch) {
      refreshAll();
    }
    if (autoStartTimer) {
      _startTimer();
    }
  }

  ForumGeneralStats get generalStats => _generalStats;
  ForumOnlineStats get onlineStats => _onlineStats;
  bool get isLoading => _isLoading;
  bool get isTimerActive => _refreshTimer?.isActive ?? false;

  void _startTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      pingOnline();
      _fetchGeneralQuietly();
    });
  }

  Future<void> notifyUserLogin(
    String username, {
    bool isInvisible = false,
    String? color,
    bool isBold = true,
    String? sessionId,
  }) async {
    if (_isDisposed) return;
    try {
      final res = await repository.notifyLogin(
        username: username,
        isInvisible: isInvisible,
        color: color,
        isBold: isBold,
        sessionId: sessionId,
      );
      if (res != null && !_isDisposed) {
        _onlineStats = res;
        notifyListeners();
      }
    } catch (_) {}
    await refreshGeneralStats();
  }

  Future<void> notifyUserLogout({String? sessionId}) async {
    if (_isDisposed) return;
    try {
      final res = await repository.notifyLogout(sessionId: sessionId);
      if (res != null && !_isDisposed) {
        _onlineStats = res;
        notifyListeners();
      }
    } catch (_) {}
    await refreshGeneralStats();
  }

  Future<void> pingOnline({
    String? username,
    bool? isRegistered,
    String? color,
    bool? isBold,
    String? sessionId,
  }) async {
    if (_isDisposed) return;
    try {
      final res = await repository.pingOnline(
        username: username,
        isRegistered: isRegistered,
        color: color,
        isBold: isBold,
        sessionId: sessionId,
      );
      if (res != null && !_isDisposed) {
        _onlineStats = res;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _fetchGeneralQuietly() async {
    if (_isDisposed) return;
    await _fetchGeneral();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_isDisposed) return;
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _fetchGeneral(),
      _pingOrFetchOnline(),
    ]);

    if (!_isDisposed) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _pingOrFetchOnline() async {
    try {
      final pingRes = await repository.pingOnline();
      if (pingRes != null && !_isDisposed) {
        _onlineStats = pingRes;
        return;
      }
    } catch (_) {}
    await _fetchOnline();
  }

  Future<void> refreshGeneralStats() async {
    if (_isDisposed) return;
    await _fetchGeneral();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> refreshOnlineUsers() async {
    if (_isDisposed) return;
    await _fetchOnline();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _fetchGeneral() async {
    try {
      final res = await repository.fetchGeneralStats();
      if (res != null && !_isDisposed) {
        _generalStats = res;
      }
    } catch (_) {}
  }

  Future<void> _fetchOnline() async {
    try {
      final res = await repository.fetchOnlineUsers();
      if (res != null && !_isDisposed) {
        _onlineStats = res;
      }
    } catch (_) {}
  }

  void updateStatsExplicitly({ForumGeneralStats? general, ForumOnlineStats? online}) {
    if (_isDisposed) return;
    if (general != null) _generalStats = general;
    if (online != null) _onlineStats = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }
}
