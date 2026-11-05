import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../data/models/member.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  static const ink = Color(0xFF1A1433);
  static const muted = Color(0xFF5F5979);
  static const purple = Color(0xFF6C3FD1);
  static const purpleDark = Color(0xFF4B27A3);
  static const line = Color(0xFFE6DFF9);
  static const rose = Color(0xFFE8447F);

  bool get _signedIn => authService.isLoggedIn;

  static const directoryEndpoint = '/businesses';
  static const filtersEndpoint = '/businesses/filters';

  final _searchController = TextEditingController();

  List<Member> _members = [];
  List<String> _chapters = [...defaultChapters];

  String _selectedChapter = 'All';
  String _search = '';

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_signedIn) {
        context.go('/login?next=/members');
      } else {
        _loadMembers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // GET /api/businesses
  Future<List<Member>> _fetchMembers() async {
    final response = await ApiConfig.dio.get<dynamic>(
      directoryEndpoint,
    );

    final body = response.data;
    dynamic list = body;

    if (body is Map) {
      list = body['data'] ??
          body['businesses'] ??
          body['members'] ??
          body['listings'] ??
          body['results'] ??
          body['items'];

      if (list is Map) {
        list = list['data'] ??
            list['businesses'] ??
            list['members'] ??
            list['listings'] ??
            list['items'];
      }
    }

    if (list is! List) {
      throw const FormatException(
        'Directory response did not contain a members list.',
      );
    }

    return list
        .whereType<Map>()
        .map(
          (item) => Member.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // GET /api/businesses/filters
  Future<List<String>> _fetchChapterFilters() async {
    final response = await ApiConfig.dio.get<dynamic>(
      filtersEndpoint,
    );

    final body = response.data;
    dynamic data = body;

    if (data is Map) {
      data = data['data'] ?? data['filters'] ?? data;
    }

    if (data is Map) {
      data = data['chapters'] ??
          data['chapter'] ??
          data['chapterFilters'] ??
          data['locations'] ??
          [];
    }

    if (data is! List) {
      return [];
    }

    return data
        .map((item) {
          if (item is Map) {
            return (item['name'] ??
                    item['label'] ??
                    item['value'] ??
                    item['chapter'] ??
                    '')
                .toString()
                .trim();
          }

          return item.toString().trim();
        })
        .where((chapter) =>
            chapter.isNotEmpty && chapter != 'ILYF Trust')
        .toSet()
        .toList();
  }

  // Load directory and filters
  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch directory
      final loaded = await _fetchMembers();

      // Fetch filters separately so directory still works
      // if the filters endpoint fails.
      List<String> apiChapters = [];

      try {
        apiChapters = await _fetchChapterFilters();
      } on DioException catch (e) {
        debugPrint(
          'Business filters API error: ${e.message}',
        );
      } catch (e) {
        debugPrint('Business filters parsing error: $e');
      }

      final liveChapters = loaded
          .map((member) => member.effectiveChapter.trim())
          .where(
            (chapter) =>
                chapter.isNotEmpty && chapter != 'ILYF Trust',
          )
          .toSet();

      final allChapters = {
        ...apiChapters,
        ...liveChapters,
      }.toList()
        ..sort();

      if (!mounted) return;

      setState(() {
        _members = sortMembers(loaded);

        _chapters = [
          ...defaultChapters,
          ...allChapters.where(
            (chapter) => !defaultChapters.contains(chapter),
          ),
        ];

        // Reset selection if it is no longer available.
        if (_selectedChapter != 'All' &&
            !_chapters.contains(_selectedChapter)) {
          _selectedChapter = 'All';
        }

        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        context.go('/login?next=/members');
        return;
      }

      setState(() {
        _error = e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                e.message ??
                'Could not load members.')
            : e.message ?? 'Could not load members.';

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
          'FormatException: ',
          '',
        );
        _loading = false;
      });
    }
  }

  // Local search and chapter filtering
  List<Member> get _visibleMembers {
    final query = _search.trim().toLowerCase();

    return sortMembers(
      _members.where((member) {
        final matchesChapter = _selectedChapter == 'All' ||
            member.effectiveChapter == _selectedChapter;

        final searchable = [
          member.name,
          member.ownerName,
          member.category,
          member.effectiveChapter,
          member.membershipNo,
          member.membershipType,
          member.membership,
          member.id,
        ].join(' ').toLowerCase();

        return matchesChapter &&
            (query.isEmpty || searchable.contains(query));
      }).toList(),
    );
  }

  Future<void> _openSocial(String url, String label) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label link is not available.'),
        ),
      );
      return;
    }

    final normalized =
        url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url';

    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        !await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        )) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $label link.'),
        ),
      );
    }
  }

  void _openProfile(Member member) {
    context.push(
      '/members/${Uri.encodeComponent(member.id)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4EFFF),
        body: Center(
          child: CircularProgressIndicator(color: purple),
        ),
      );
    }

    final visible = _visibleMembers;

    return Scaffold(
      backgroundColor: const Color(0xFFF4EFFF),
      appBar: const AppHeader(),
      body: SafeArea(
        child: RefreshIndicator(
          color: purple,
          onRefresh: _loadMembers,
          child: CustomScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _hero()),

              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeader(
                  child: _chapterPills(),
                  height: 62,
                ),
              ),

              SliverToBoxAdapter(
                child: _listHeading(visible.length),
              ),

              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: purple,
                    ),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 42,
                            color: purple,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load members right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _loadMembers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (visible.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'No members match your search. '
                        'Try another name or chapter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    20,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;

                      final columns = width >= 900
                          ? 3
                          : width >= 600
                              ? 2
                              : 1;

                      return SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 218,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _MemberCard(
                            member: visible[index],
                            onTap: () =>
                                _openProfile(visible[index]),
                            onSocialTap: _openSocial,
                          ),
                          childCount: visible.length,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(isStaff: false),
    );
  }

  Widget _hero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFFBF9FF), Color(0xFFF5EFFF)],
      ),
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ILYF COMMUNITY',
          style: TextStyle(
            color: Color(0xFF702CFF),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meet our members',
                    style: TextStyle(
                      color: Color(0xFF17143D),
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Discover trusted people and businesses in your network.',
                    style: TextStyle(
                      color: Color(0xFF756B91),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => context.push('/admin/members/new'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A4B27A3),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Search people, business, city...',
              hintStyle: const TextStyle(
                color: Color(0xFF9A93B3),
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search, color: muted, size: 21),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                      icon: const Icon(Icons.close, size: 19),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chapterPills() => Container(
    color: Colors.white.withValues(alpha: .98),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _chapters.length + 1,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final chapter = index == 0 ? 'All' : _chapters[index - 1];
        final selected = _selectedChapter == chapter;
        return ChoiceChip(
          label: Text(chapter == 'All' ? 'All members' : chapter),
          selected: selected,
          onSelected: (_) => setState(() => _selectedChapter = chapter),
          showCheckmark: false,
          backgroundColor: Colors.white,
          selectedColor: purple,
          side: BorderSide(color: selected ? purple : line),
          labelStyle: TextStyle(
            color: selected ? Colors.white : purpleDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          shape: const StadiumBorder(),
        );
      },
    ),
  );

  Widget _listHeading(int count) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community directory',
                style: TextStyle(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'People you can connect with',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFECE5FF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$count ${count == 1 ? 'member' : 'members'}',
            style: const TextStyle(
              color: purpleDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
    required this.onSocialTap,
  });
  final Member member;
  final VoidCallback onTap;
  final Future<void> Function(String url, String label) onSocialTap;

  @override
  Widget build(BuildContext context) {
    final life = memberType(member).toLowerCase().contains('life');
    final photo = member.effectivePhoto;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6DFF9)),
            borderRadius: BorderRadius.circular(23),
            boxShadow: const [
              BoxShadow(
                color: Color(0x164B27A3),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 42,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1C0E4D),
                        Color(0xFF33197F),
                        Color(0xFF2A1466),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .13),
                          border: Border.all(
                            color: life
                                ? const Color(0xFFF6D37A)
                                : Colors.white38,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '★ ${memberType(member)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: life
                                ? const Color(0xFFFFF1C2)
                                : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A3FD6),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: photo.isEmpty
                              ? _InitialAvatar(name: member.displayName)
                              : Image.network(
                                  photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _InitialAvatar(name: member.displayName),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        member.displayName.isEmpty
                            ? member.name
                            : member.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 58,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Color(0xFFF7F4FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        member.category.isEmpty ? 'Member' : member.category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF344454),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFFE8447F),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              member.effectiveChapter.isEmpty
                                  ? 'Chapter not set'
                                  : member.effectiveChapter,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF5F5979),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (member.effectiveMembershipNo.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'ILYF ID: ${member.effectiveMembershipNo}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          _SocialButton(
                            label: 'LinkedIn',
                            symbol: 'in',
                            enabled: member.linkedin.isNotEmpty,
                            onTap: () =>
                                onSocialTap(member.linkedin, 'LinkedIn'),
                          ),
                          const SizedBox(width: 5),
                          _SocialButton(
                            label: 'X',
                            symbol: '𝕏',
                            enabled:
                                member.x.isNotEmpty ||
                                member.twitter.isNotEmpty,
                            onTap: () => onSocialTap(
                              member.x.isNotEmpty ? member.x : member.twitter,
                              'X',
                            ),
                          ),
                          const SizedBox(width: 5),
                          _SocialButton(
                            label: 'Instagram',
                            symbol: '◎',
                            enabled: member.instagram.isNotEmpty,
                            onTap: () =>
                                onSocialTap(member.instagram, 'Instagram'),
                          ),
                          const SizedBox(width: 5),
                          _SocialButton(
                            label: 'Facebook',
                            symbol: 'f',
                            enabled: member.facebook.isNotEmpty,
                            onTap: () =>
                                onSocialTap(member.facebook, 'Facebook'),
                          ),
                        ],
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

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      initials(name),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.symbol,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String symbol;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: enabled ? label : '$label not available',
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(9),
          child: Opacity(
            opacity: enabled ? 1 : 0.38,
            child: Container(
              height: 29,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EAF0),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                symbol,
                style: TextStyle(
                  color: const Color(0xFF172033),
                  fontSize: symbol == 'in' ? 12 : 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  const _PinnedHeader({required this.child, required this.height});
  final Widget child;
  final double height;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
