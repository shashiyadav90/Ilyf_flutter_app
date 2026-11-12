import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';

class MembershipRequiredPage extends StatelessWidget {
  const MembershipRequiredPage({super.key, this.embedded = false});

  final bool embedded;

  static const Color _purple = Color(0xFF6C3FD1);
  static const Color _purpleDark = Color(0xFF4B27A3);
  static const Color _ink = Color(0xFF1A1433);
  static const Color _muted = Color(0xFF5F5979);
  static const Color _background = Color(0xFFF4EFFF);
  static const Color _line = Color(0xFFE6DFF9);

  void _openMembership(BuildContext context) {
    context.push('/membership');
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _welcomeSection(),
                const SizedBox(height: 22),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWeb = constraints.maxWidth >= 800;

                    // Desktop / Web layout
                    if (isWeb) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT SIDE: Membership upgrade box
                          Expanded(flex: 4, child: _upgradeCard(context)),

                          const SizedBox(width: 28),

                          // RIGHT SIDE: Business listings and benefits
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeading(),
                                const SizedBox(height: 14),

                                _benefitCard(
                                  icon: Icons.storefront_outlined,
                                  title: 'One Business Listings',
                                  description:
                                      'Add your business and manage your products and offerings.',
                                  available: true,
                                ),
                                _benefitCard(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  title: 'Enquiries',
                                  description:
                                      'Connect with people and manage your business enquiries.',
                                  available: true,
                                ),
                                _benefitCard(
                                  icon: Icons.person_outline_rounded,
                                  title: 'Your Profiles',
                                  description:
                                      'See your profile information and manage your settings.',
                                  available: true,
                                ),
                                _benefitCard(
                                  icon: Icons.storefront_outlined,
                                  title: 'All Business Listings',
                                  description:
                                      'List and manage your business, products and offerings.',
                                  available: false,
                                ),
                                _benefitCard(
                                  icon: Icons.newspaper_outlined,
                                  title: 'News & Events',
                                  description:
                                      'Stay updated with the latest ILYF announcements and events.',
                                  available: false,
                                ),
                                _benefitCard(
                                  icon: Icons.groups_outlined,
                                  title: 'Community Directory',
                                  description:
                                      'Discover businesses and connect with Annual and Patron members.',
                                  available: false,
                                ),
                                _benefitCard(
                                  icon: Icons.person_outline_rounded,
                                  title: 'Member Profiles',
                                  description:
                                      'Explore member profiles and access their business information.',
                                  available: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    // MOBILE / SMALL SCREEN layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _upgradeCard(context),
                        const SizedBox(height: 26),
                        _sectionHeading(),
                        const SizedBox(height: 14),

                        _benefitCard(
                          icon: Icons.storefront_outlined,
                          title: 'One Business Listings',
                          description:
                              'Add your business and manage your products and offerings.',
                          available: true,
                        ),
                        _benefitCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Enquiries',
                          description:
                              'Connect with people and manage your business enquiries.',
                          available: true,
                        ),
                        _benefitCard(
                          icon: Icons.person_outline_rounded,
                          title: 'Your Profile',
                          description:
                              'See your profile information and manage your settings.',
                          available: true,
                        ),
                        _benefitCard(
                          icon: Icons.storefront_outlined,
                          title: 'All Business Listings',
                          description:
                              'List and manage your business, products and offerings.',
                          available: false,
                        ),
                        _benefitCard(
                          icon: Icons.newspaper_outlined,
                          title: 'News & Events',
                          description:
                              'Stay updated with the latest ILYF announcements and events.',
                          available: false,
                        ),
                        _benefitCard(
                          icon: Icons.groups_outlined,
                          title: 'Community Directory',
                          description:
                              'Discover businesses and connect with Annual and Patron members.',
                          available: false,
                        ),
                        _benefitCard(
                          icon: Icons.person_outline_rounded,
                          title: 'Member Profiles',
                          description:
                              'Explore member profiles and access their business information.',
                          available: false,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),
                _bottomMessage(),
              ],
            ),
          ),
        ),
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(68),
        child: AppHeader(),
      ),
      body: content,
      bottomNavigationBar: const BottomNav(isStaff: false),
    );
  }

  Widget _welcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE9DFFF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined, color: _purple, size: 16),
              SizedBox(width: 7),
              Text(
                'GENERAL MEMBERSHIP',
                style: TextStyle(
                  color: _purpleDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'Grow with the\nILYF community.',
          style: TextStyle(
            color: _ink,
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Build connections, discover opportunities and '
          'grow your business with your professional community.',
          style: TextStyle(color: _muted, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _upgradeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF211052), Color(0xFF4B27A3), Color(0xFF7046D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD985),
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Unlock the complete\nILYF experience',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'Upgrade to Annual or Patron membership to '
            'access the community directory, explore member '
            'profiles and connect with the entire ILYF network.',
            style: TextStyle(
              color: Color(0xFFE5DBFF),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openMembership(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD985),
                foregroundColor: const Color(0xFF291A46),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Explore Membership',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 9),
                  Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your membership benefits',
          style: TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Here is what you can access with your membership.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _benefitCard({
    required IconData icon,
    required String title,
    required String description,
    required bool available,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: available
                  ? const Color(0xFFF0EAFE)
                  : const Color(0xFFF1EFF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: available ? _purple : _muted, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            available ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: available ? const Color(0xFF239B68) : _purple,
            size: 21,
          ),
        ],
      ),
    );
  }

  Widget _bottomMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFECE4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: _purple, size: 22),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Your General membership still gives you access '
              'to business listings, enquiries, news and events. '
              'Upgrade whenever you are ready to unlock more.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
