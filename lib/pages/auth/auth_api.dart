import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import 'auth_service.dart';

class AuthApiDio implements AuthApi {
  Dio get _dio => ApiConfig.dio;

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Invalid response received from server.');
  }

  String _errorMessage(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message'];

      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Could not reach the server. Check your connection.';
    }

    return fallback;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String fallback = 'Could not load data.',
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.get(
        path,
        options: Options(extra: {'requiresAuth': authenticated}),
      );

      return _toMap(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, fallback));
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    dynamic body,
    String fallback = 'Something went wrong.',
    bool authenticated = true,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        options: Options(extra: {'requiresAuth': authenticated}),
      );

      return _toMap(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, fallback));
    }
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  // POST /auth/otp/send
  @override
  Future<Map<String, dynamic>> sendOtp(String phone) {
    return _post(
      '/auth/otp/send',
      body: {'phone': phone},
      authenticated: false,
      fallback: 'Could not send OTP. Please try again.',
    );
  }

  // POST /auth/otp/verify
  @override
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) {
    return _post(
      '/auth/otp/verify',
      body: {'phone': phone, 'otp': otp},
      authenticated: false,
      fallback: 'OTP verification failed.',
    );
  }

  // POST /auth/token/refresh
  @override
  Future<Map<String, dynamic>> refreshAccess() async {
    try {
      final response = await _dio.post(
        '/auth/token/refresh',
        options: Options(
          extra: {'requiresAuth': false, 'skipAuthRefresh': true},
        ),
      );

      if (response.data is Map) {
        return _toMap(response.data);
      }

      return {};
    } on DioException {
      return {};
    }
  }

  // GET /me
  @override
  Future<Map<String, dynamic>> fetchMe() {
    return _get('/me', fallback: 'Could not load member session.');
  }

  // POST /auth/logout
  @override
  Future<void> logoutRemote() async {
    try {
      await _dio.post(
        '/auth/logout',
        options: Options(
          extra: {'requiresAuth': false, 'skipAuthRefresh': true},
        ),
      );
    } catch (_) {
      // Local logout should still complete.
    }
  }

  // ==========================================
  // MEMBERS
  // ==========================================

  // GET /businesses
  Future<Map<String, dynamic>> fetchDirectory() {
    return _get('/businesses', fallback: 'Could not load members.');
  }

  // ==========================================
  // PROFILE
  // ==========================================

  // GET /me/profile
  Future<Map<String, dynamic>> fetchProfile() {
    return _get('/me/profile', fallback: 'Could not load your profile.');
  }

  // PATCH /me/profile
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> body) async {
    try {
      final response = await _dio.patch('/me/profile', data: body);

      return _toMap(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Could not save your profile.'));
    }
  }

  // ==========================================
  // OFFERS
  // ==========================================

  // GET /offers
  Future<Map<String, dynamic>> fetchOffers() {
    return _get('/offers', fallback: 'Could not load offers.');
  }

  // GET /me/offers
  Future<Map<String, dynamic>> fetchMyOffers() {
    return _get('/me/offers', fallback: 'Could not load your offers.');
  }

  // ==========================================
  // ENQUIRY
  // ==========================================

  // POST /chat/search
  Future<Map<String, dynamic>> searchBusinesses(
    String message, {
    String? inquiryId,
  }) {
    return _post(
      '/chat/search',
      body: {
        'message': message,
        if (inquiryId != null && inquiryId.isNotEmpty) 'inquiryId': inquiryId,
      },
      authenticated: false,
      fallback: 'Could not continue the enquiry.',
    );
  }

  // ==========================================
  // NEWS
  // ==========================================

  // GET /news
  Future<Map<String, dynamic>> fetchNews() {
    return _get('/news', fallback: 'Could not load news.');
  }

  // GET /me/news
  Future<Map<String, dynamic>> fetchMyNews() {
    return _get('/me/news', fallback: 'Could not load your news.');
  }

  // ==========================================
  // PHONE CHANGE
  // ==========================================

  // POST /me/phone/otp
  Future<Map<String, dynamic>> requestPhoneChangeOtp(String phone) {
    return _post(
      '/me/phone/otp',
      body: {'phone': phone},
      fallback: 'Could not send phone verification OTP.',
    );
  }

  // POST /me/phone/confirm
  Future<Map<String, dynamic>> confirmPhoneChange(String phone, String otp) {
    return _post(
      '/me/phone/confirm',
      body: {'phone': phone, 'otp': otp},
      fallback: 'Phone verification failed.',
    );
  }

  // ==========================================
  // PROFILE MEDIA
  // ==========================================

  // DELETE /me/media
  Future<Map<String, dynamic>> removeProfileMedia(
    String kind, {
    String? index,
  }) async {
    try {
      final response = await _dio.delete(
        '/me/media',
        queryParameters: {
          'kind': kind,
          if (index != null && index.isNotEmpty) 'index': index,
        },
      );

      return _toMap(response.data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Could not remove that file.'));
    }
  }
}
