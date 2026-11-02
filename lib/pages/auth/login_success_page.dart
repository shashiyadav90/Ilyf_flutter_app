import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/api_config.dart';

class LoginSuccessPage extends StatefulWidget {
  const LoginSuccessPage({super.key});

  @override
  State<LoginSuccessPage> createState() => _LoginSuccessPageState();
}

class _LoginSuccessPageState extends State<LoginSuccessPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectUser();
    });
  }

  Future<void> _redirectUser() async {
    try {
      final response = await ApiConfig.dio.get('/me/profile');

      if (!mounted) return;

      final data = response.data;
      final profile = data is Map ? data['data'] ?? data : null;

      final isMember =
          profile is Map &&
          (profile['member'] != null || profile['isMember'] == true);

      if (isMember) {
        context.go('/chapters');
      } else {
        context.go('/view-more?name=chapters');
      }
    } catch (e) {
      if (!mounted) return;
      context.go('/view-more?name=chapters');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF8064D8))),
    );
  }
}
