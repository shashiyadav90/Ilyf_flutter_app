import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';

// API: GET /api/businesses/{id}
class MemberCardPage extends StatefulWidget {
  const MemberCardPage({super.key, required this.id});

  final String id;

  @override
  State<MemberCardPage> createState() => _MemberCardPageState();
}

class _MemberCardPageState extends State<MemberCardPage> {
  Map<String, dynamic>? _listing;
  bool _loading = true;
  String? _error;

  static const Color _ink = Color(0xFF17143D);
  static const Color _ink2 = Color(0xFF625A7B);
  static const Color _ink3 = Color(0xFF9188AA);
  static const Color _violet = Color(0xFF7044D6);
  static const Color _violetDark = Color(0xFF4B27A3);
  static const Color _mist = Color(0xFFF6F2FF);
  static const Color _line = Color(0xFFE9E1FA);

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  @override
  void didUpdateWidget(covariant MemberCardPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id) {
      _loadMember();
    }
  }

  // GET /api/businesses/{id}
  Future<void> _loadMember() async {
    setState(() {
      _loading = true;
      _error = null;
      _listing = null;
    });

    try {
      final response = await ApiConfig.dio.get<dynamic>(
        '/businesses/${Uri.encodeComponent(widget.id)}',
      );

      final payload = response.data;

      Map<String, dynamic>? business;

      if (payload is Map) {
        dynamic data = payload['data'] ?? payload['business'] ?? payload;

        if (data is Map) {
          if (data['business'] is Map) {
            data = data['business'];
          }

          business = Map<String, dynamic>.from(data);
        }
      }

      if (!mounted) return;

      setState(() {
        _listing = business;

        if (business == null || business.isEmpty) {
          _error = 'This member is not in the directory.';
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.response?.statusCode == 404) {
          _error = 'This member is not in the directory.';
        } else if (e.response?.statusCode == 401) {
          _error = 'Please log in to view this member.';
        } else {
          _error = _readableError(e);
        }
      });

      if (e.response?.statusCode == 401 && mounted) {
        context.go('/login?next=/members/${widget.id}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _readableError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _readableError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'The server is taking too long to respond. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Could not connect to the server. Check your internet connection.';
      }

      return error.response?.data is Map
          ? (error.response?.data['message']?.toString() ??
                'Could not load this member. Please try again.')
          : 'Could not load this member. Please try again.';
    }

    return 'Could not load this member. Please try again.';
  }

  String _value(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  List<String> _services() {
    final raw = _listing?['services'];

    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return const [];
  }

  String _memberType() {
    final item = _listing ?? {};

    final raw = _value(
      item['memberType'] ??
          item['membershipType'] ??
          item['type'] ??
          item['memberCategory'],
    );

    if (raw.isNotEmpty) return raw;

    final lifetime =
        item['lifetimePatron'] == true ||
        item['isLifetimePatron'] == true ||
        _value(item['membershipNo']).toLowerCase().contains('patron');

    if (lifetime) return 'Lifetime Patron';

    final category = _value(item['category']).toLowerCase();

    if (category.contains('patron')) return 'Patron';

    return 'ILYF Member';
  }

  String _typeLabel() => _memberType();

  String _typeClass() =>
      _typeLabel().toLowerCase().replaceAll(RegExp(r'\s+'), '-');

  String _initials() {
    final name = _value(_listing?['ownerName'], 'Member');

    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'M';

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  String? _photoUrl() {
    final item = _listing ?? {};

    final candidates = [
      item['photoUrl'],
      item['imageUrl'],
      item['profileImage'],
      item['logo'],
      item['photo'],
      item['avatar'],
    ];

    for (final candidate in candidates) {
      final value = _value(candidate);

      if (value.startsWith('https://') || value.startsWith('http://')) {
        return value;
      }
    }

    return null;
  }

  Future<void> _openExternal(String value) async {
    final uri = Uri.tryParse(value);

    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that link.')),
      );
    }
  }

  Future<void> _callMember() async {
    final phone = _value(_listing?['phone']);

    if (phone.isNotEmpty) {
      await _openExternal('tel:$phone');
    }
  }

  Future<void> _emailMember() async {
    final email = _value(_listing?['email']);

    if (email.isNotEmpty) {
      await _openExternal('mailto:$email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listing;
    final type = _typeLabel();
    final imageUrl = _photoUrl();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(68),
        child: AppHeader(),
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : listing == null
            ? _buildError()
            : _buildDetails(listing, type, imageUrl),
      ),
      bottomNavigationBar: BottomNav(isStaff: authService.isStaff),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _heroSkeleton(),
        const SizedBox(height: 18),
        _skeletonCard(),
        const SizedBox(height: 14),
        _skeletonCard(),
      ],
    );
  }

  Widget _heroSkeleton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 54),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFFCFAFF), Color(0xFFF5EFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backLink(),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEE7FB),
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: 90),
                    SizedBox(height: 10),
                    _SkeletonLine(width: 160, height: 20),
                    SizedBox(height: 10),
                    _SkeletonLine(width: 120),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonCard() => Container(
    height: 145,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF1ECFB),
      borderRadius: BorderRadius.circular(23),
    ),
  );

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        _heroHeader(null, null, loading: false),
        Container(
          margin: const EdgeInsets.only(top: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _mist,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: _violet,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'We couldn’t find this member',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'This member is not in the directory.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink2, height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go('/members'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Back to members'),
                style: FilledButton.styleFrom(
                  backgroundColor: _violet,
                  foregroundColor: Colors.white,
                ),
              ),
              TextButton(
                onPressed: _loadMember,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroHeader(
    Map<String, dynamic>? listing,
    String? imageUrl, {
    required bool loading,
  }) {
    final type = listing == null ? 'ILYF Member' : _typeLabel();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 54),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEE7FB)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: const RadialGradient(
          center: Alignment.topRight,
          radius: 1.3,
          colors: [Color(0xFFD7C3FF), Color(0xFFFCFAFF), Colors.white],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x184B27A3),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _backLink(),
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: _violet, size: 15),
                  SizedBox(width: 5),
                  Text(
                    'ILYF MEMBER',
                    style: TextStyle(
                      color: Color(0xFF796A9D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (listing != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD9C7FF), Color(0xFF9E7BEA)],
                    ),
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(27),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33D9C8FF),
                        blurRadius: 0,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Color(0x26421466),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              _initials(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: type == 'Lifetime Patron' || type == 'Patron'
                              ? const Color(0xFFFFF7DF)
                              : const Color(0xFFF2EBFF),
                          border: Border.all(
                            color: type == 'Lifetime Patron' || type == 'Patron'
                                ? const Color(0xFFF0DFA9)
                                : const Color(0xFFE4D7FF),
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: type == 'Lifetime Patron' || type == 'Patron'
                                ? const Color(0xFF7A5914)
                                : _violetDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _value(listing['ownerName'], 'Member'),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 30,
                          height: 1.02,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _value(listing['name'], 'ILYF Member Business'),
                        style: const TextStyle(
                          color: Color(0xFF776C91),
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEMBER DIRECTORY',
                    style: TextStyle(
                      color: Color(0xFF8D7BB4),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  SizedBox(height: 9),
                  Text(
                    'Member details',
                    style: TextStyle(color: _ink, fontSize: 30),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'View member information and contact details.',
                    style: TextStyle(color: _ink2, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (listing != null) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_value(listing['category']).isNotEmpty)
                  _chip(Icons.business_outlined, _value(listing['category'])),
                if (_value(listing['chapter']).isNotEmpty)
                  _chip(Icons.location_on_outlined, _value(listing['chapter'])),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroSkeletonPlaceholder() => _heroHeader(null, null, loading: true);

  Widget _backLink() => InkWell(
    onTap: () => context.go('/members'),
    borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 17, color: _violetDark),
          SizedBox(width: 6),
          Text(
            'All members',
            style: TextStyle(
              color: _violetDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.86),
      border: Border.all(color: const Color(0xFFE8E0F8)),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _violet, size: 14),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF655A81),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildDetails(
    Map<String, dynamic> listing,
    String type,
    String? imageUrl,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isTablet =
            constraints.maxWidth >= 650 && constraints.maxWidth < 1100;

        const maxContentWidth = 1240.0;
        const horizontalPadding = 20.0;
        const cardGap = 18.0;

        final contentWidth = constraints.maxWidth > maxContentWidth
            ? maxContentWidth
            : constraints.maxWidth;

        final availableWidth = contentWidth - (horizontalPadding * 2);

        final cardWidth = isDesktop || isTablet
            ? (availableWidth - cardGap) / 2
            : availableWidth;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: _heroHeader(listing, imageUrl, loading: false),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -31),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x184B27A3),
                          blurRadius: 26,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            icon: Icons.call_outlined,
                            label: 'Call',
                            primary: true,
                            enabled: _value(listing['phone']).isNotEmpty,
                            onTap: _callMember,
                          ),
                        ),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.mail_outline,
                            label: 'Email',
                            enabled: _value(listing['email']).isNotEmpty,
                            onTap: _emailMember,
                          ),
                        ),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.location_on_outlined,
                            label: 'Chapter',
                            enabled: _value(listing['chapter']).isNotEmpty,
                            onTap: () {
                              final chapter = _value(listing['chapter']);
                              if (chapter.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Chapter: $chapter')),
                                );
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.tag,
                            label: 'Member ID',
                            enabled: _value(listing['membershipNo']).isNotEmpty,
                            onTap: () {
                              final memberNo = _value(listing['membershipNo']);
                              if (memberNo.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Member ID: $memberNo'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      28,
                    ),
                    child: Wrap(
                      spacing: cardGap,
                      runSpacing: cardGap,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _infoCard(
                            kicker: 'GET TO KNOW THEM',
                            title: 'About the business',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _value(
                                    listing['description'],
                                    'This member has not added a business description yet.',
                                  ),
                                  style: const TextStyle(
                                    color: _ink2,
                                    fontSize: 14,
                                    height: 1.75,
                                  ),
                                ),
                                if (_services().isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    height: 1,
                                    color: const Color(0xFFF0EBFA),
                                  ),
                                  const SizedBox(height: 17),
                                  const Text(
                                    'Services and expertise',
                                    style: TextStyle(
                                      color: Color(0xFF81759D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 11),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _services().map((service) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _mist,
                                          border: Border.all(
                                            color: const Color(0xFFE8E0FA),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          service,
                                          style: const TextStyle(
                                            color: _violetDark,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        SizedBox(
                          width: cardWidth,
                          child: _infoCard(
                            kicker: 'CONNECT DIRECTLY',
                            title: 'Contact information',
                            child: Column(
                              children: [
                                _contactRow(
                                  icon: Icons.call_outlined,
                                  label: 'Phone number',
                                  value: _value(
                                    listing['phone'],
                                    'Not provided',
                                  ),
                                  isAvailable: _value(
                                    listing['phone'],
                                  ).isNotEmpty,
                                  onTap: _callMember,
                                ),
                                _contactRow(
                                  icon: Icons.mail_outline,
                                  label: 'Email address',
                                  value: _value(
                                    listing['email'],
                                    'Not provided',
                                  ),
                                  isAvailable: _value(
                                    listing['email'],
                                  ).isNotEmpty,
                                  onTap: _emailMember,
                                ),
                                _contactRow(
                                  icon: Icons.tag,
                                  label: 'Membership number',
                                  value: _value(
                                    listing['membershipNo'],
                                    'Not provided',
                                  ),
                                  isAvailable: _value(
                                    listing['membershipNo'],
                                  ).isNotEmpty,
                                ),
                                _contactRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Chapter',
                                  value: _value(
                                    listing['chapter'],
                                    'Not provided',
                                  ),
                                  isAvailable: _value(
                                    listing['chapter'],
                                  ).isNotEmpty,
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(
                          width: availableWidth,
                          child: InkWell(
                            onTap: () => context.go('/members'),
                            borderRadius: BorderRadius.circular(999),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: _violetDark,
                                    size: 17,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'Return to all members',
                                    style: TextStyle(
                                      color: _violetDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final color = enabled ? _violetDark : _ink3.withValues(alpha: 0.55);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primary && enabled ? _violet : _mist,
              border: Border.all(
                color: primary && enabled ? Colors.transparent : _line,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: primary && enabled
                  ? const [
                      BoxShadow(
                        color: Color(0x334B27A3),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: primary && enabled ? Colors.white : color,
              size: 20,
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String kicker,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
            color: Color(0x184B27A3),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: const TextStyle(
              color: Color(0xFF8D7BB4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isAvailable,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0EBFA))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _mist,
              border: Border.all(color: const Color(0xFFEEE7FB)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _violetDark, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _ink3,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: isAvailable ? _ink : const Color(0xFFA49BB8),
                    fontSize: 13,
                    fontWeight: isAvailable ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null && isAvailable)
            IconButton(
              tooltip: 'Open',
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: 16, color: _violet),
            ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({this.width = 100, this.height = 11});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E1F8),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
