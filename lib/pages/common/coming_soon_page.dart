
import 'package:flutter/material.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;

  const ComingSoonPage({
    super.key,
    required this.title,
  });

  static const Color purple = Color(0xFF6C3FD1);
  static const Color background = Color(0xFFF6F3FF);
  static const Color muted = Color(0xFF77708D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // Common ILYF header
      appBar: const AppHeader(),

      // Common ILYF footer
      bottomNavigationBar: const BottomNav(isStaff: false),

      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE4FF),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 48,
                      color: purple,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF241447),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'We are working on something amazing. '
                    'This page will be available soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: muted,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFE8E1FA),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.construction_rounded,
                          size: 17,
                          color: purple,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: purple,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
