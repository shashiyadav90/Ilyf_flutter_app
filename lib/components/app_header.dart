import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

const Color ilyfPurple = Color(0xFF6C3FD1);
const Color ilyfInk = Color(0xFF1A1433);
const Color ilyfBorder = Color(0xFFECE8F3);

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'ILYF Connect',
    this.subtitle = 'Your professional community',
    this.showBackButton = false,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: ilyfBorder, width: 1)),
          ),
          child: Row(
            children: [
              if (showBackButton) ...[
                IconButton(
                  onPressed:
                      onBack ??
                      () {
                        Navigator.of(context).maybePop();
                      },
                  icon: const Icon(Icons.arrow_back_rounded, color: ilyfInk),
                  tooltip: 'Go back',
                ),
                const SizedBox(width: 4),
              ],

              // ILYF logo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'lib/images/ilyf_logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 12),

              // Header title and subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ilyfInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF817B91),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile button on top-right
              if (trailing != null)
                trailing!
              else
                InkWell(
                  onTap: () {
                    context.go('/profile');
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE4D9FF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color: ilyfPurple,
                          size: 19,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: ilyfPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
