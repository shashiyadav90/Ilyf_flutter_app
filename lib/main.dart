import 'package:flutter/material.dart';

import 'core/config/api_config.dart';
import 'core/routing/app_router.dart';

import 'pages/auth/auth_api.dart';
import 'pages/auth/auth_service.dart';
import 'pages/auth/auth_interceptor.dart';

late final AuthService authService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  authService = AuthService(api: AuthApiDio());

  configureAuthInterceptor(dio: ApiConfig.dio, auth: authService);

  await authService.bootstrapAuth();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ILYF Connect',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
