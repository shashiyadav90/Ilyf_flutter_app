import 'package:dio/dio.dart';

import 'auth_service.dart';

void configureAuthInterceptor({required Dio dio, required AuthService auth}) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final requiresAuth = options.extra['requiresAuth'] != false;

        final token = auth.accessToken;

        if (requiresAuth && token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },

      onError: (error, handler) async {
        final request = error.requestOptions;
        final isUnauthorized = error.response?.statusCode == 401;

        final requiresAuth = request.extra['requiresAuth'] != false;

        final alreadyRetried = request.extra['authRetried'] == true;

        final skipRefresh = request.extra['skipAuthRefresh'] == true;

        final isAuthRoute = request.path.startsWith('/auth/');

        if (!isUnauthorized ||
            !requiresAuth ||
            alreadyRetried ||
            skipRefresh ||
            isAuthRoute) {
          handler.next(error);
          return;
        }

        try {
          final session = await auth.refreshSession();

          final newToken = auth.accessToken;

          if (session == null || newToken == null || newToken.isEmpty) {
            await auth.clearSession();
            handler.next(error);
            return;
          }

          request.headers['Authorization'] = 'Bearer $newToken';
          request.extra['authRetried'] = true;

          final response = await dio.fetch(request);

          handler.resolve(response);
        } catch (_) {
          await auth.clearSession();
          handler.next(error);
        }
      },
    ),
  );
}
