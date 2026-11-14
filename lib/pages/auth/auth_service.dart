import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'member_session.dart';

abstract class AuthApi {
  Future<Map<String, dynamic>> sendOtp(String phone);

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp);

  Future<Map<String, dynamic>> refreshAccess();

  Future<Map<String, dynamic>> fetchMe();

  Future<void> logoutRemote();
}

class AuthService extends ChangeNotifier {
  AuthService({required AuthApi api, FlutterSecureStorage? storage})
    : _api = api,
      _storage = storage ?? const FlutterSecureStorage();

  final AuthApi _api;
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'access_token';

  MemberSession? _session;
  String? _accessToken;

  bool _ready = false;
  bool _disposed = false;
  Future<MemberSession?>? _refreshInFlight;

  MemberSession? get member => _session;

  String? get accessToken => _accessToken;

  bool get isReady => _ready;

  bool get isLoggedIn =>
      _session != null && _accessToken != null && _accessToken!.isNotEmpty;

  Map<String, dynamic>? get memberListing => _session?.listing;

  bool get isRoot => _session?.isRoot ?? false;

  bool get isStaff => _session?.isStaff ?? false;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<MemberSession?> applySession(Map<String, dynamic>? payload) async {
    final token = payload?['accessToken'];
    final memberData = payload?['member'];

    if (token == null || token.toString().isEmpty || memberData is! Map) {
      _session = null;
      _accessToken = null;

      await _storage.delete(key: _tokenKey);
      _notify();

      return null;
    }

    _accessToken = token.toString();

    _session = MemberSession.fromJson(Map<String, dynamic>.from(memberData));

    await _storage.write(key: _tokenKey, value: _accessToken);

    _notify();

    return _session;
  }

  Future<void> bootstrapAuth() async {
    try {
      await _storage.delete(key: 'ilyfMember');

      await refreshSession();
    } catch (_) {
      _session = null;
      _accessToken = null;

      await _storage.delete(key: _tokenKey);
    } finally {
      _ready = true;
      _notify();
    }
  }

  Future<MemberSession?> refreshSession() {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final future = _refreshSessionInternal();

    _refreshInFlight = future;

    return future.whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<MemberSession?> _refreshSessionInternal() async {
    final payload = await _api.refreshAccess();
    return applySession(payload);
  }

  Future<Map<String, dynamic>> requestOtp(String phone) {
    return _api.sendOtp(phone);
  }

  Future<MemberSession?> loginWithOtp(String phone, String otp) async {
    final payload = await _api.verifyOtp(phone, otp);
    return applySession(payload);
  }

  Future<void> clearSession() async {
    _session = null;
    _accessToken = null;

    await _storage.delete(key: _tokenKey);

    _notify();
  }

  Future<void> handleUnauthorized() async {
    await clearSession();
  }

  Future<MemberSession?> reloadSession() async {
    final payload = await _api.fetchMe();
    return applySession(payload);
  }

  Future<void> logoutMember() async {
    try {
      await _api.logoutRemote();
    } catch (e) {
      debugPrint('LOGOUT API ERROR: $e');
    } finally {
      await clearSession();
    }
  }

  Future<void> restoreStoredToken() async {
    _accessToken = await _storage.read(key: _tokenKey);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
