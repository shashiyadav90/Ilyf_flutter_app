import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _activePurple = Color(0xFF6C3FD1);
const Color _inactiveColor = Color(0xFF8C879B);
const Color _borderColor = Color(0xFFECE8F3);

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, this.isStaff = false});

  final bool isStaff;

  static const List<_NavItem> _memberItems = [
    _NavItem('Overview', '/overview', Icons.dashboard_outlined),
    _NavItem('Members', '/members', Icons.groups_outlined),
    _NavItem('Enquiry', '/', Icons.chat_bubble_outline_rounded),
    _NavItem('Listings', '/offers', Icons.local_offer_outlined),
    _NavItem('News', '/news', Icons.article_outlined),
  ];

  static const List<_NavItem> _staffItems = [
    _NavItem('Admin', '/admin', Icons.admin_panel_settings_outlined),
    _NavItem('Members', '/members', Icons.groups_outlined),
    _NavItem('Enquiry', '/', Icons.chat_bubble_outline_rounded),
    _NavItem('Listings', '/offers', Icons.local_offer_outlined),
    _NavItem('Overview', '/overview', Icons.dashboard_outlined),
    _NavItem('News', '/news', Icons.article_outlined),
  ];

  bool _isActive(String currentPath, _NavItem item) {
    if (item.path == '/') {
      return currentPath == '/';
    }

    return currentPath == item.path || currentPath.startsWith('${item.path}/');
  }

  @override
  Widget build(BuildContext context) {
    final items = isStaff ? _staffItems : _memberItems;
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 65,
          child: Row(
            children: items.map((item) {
              final active = _isActive(currentPath, item);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!active) {
                      context.go(item.path);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? _activePurple.withValues(alpha: 0.06)
                          : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 23,
                          color: active ? _activePurple : _inactiveColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? _activePurple : _inactiveColor,
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: active ? 16 : 0,
                          height: 2,
                          decoration: BoxDecoration(
                            color: _activePurple,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}
