import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';

class AdminChaptersPage extends StatefulWidget {
  const AdminChaptersPage({super.key});

  @override
  State<AdminChaptersPage> createState() => _AdminChaptersPageState();
}

class _AdminChaptersPageState extends State<AdminChaptersPage> {
  static const Color ink = Color(0xFF1A1433);
  static const Color muted = Color(0xFF5F5979);
  static const Color purple = Color(0xFF6C3FD1);
  static const Color purpleDark = Color(0xFF4B27A3);
  static const Color line = Color(0xFFE6DFF9);
  static const Color canvas = Color(0xFFF4EFFF);
  static const Color rose = Color(0xFFE8447F);
  static const String chaptersEndpoint = '/admin/chapters';

  List<Map<String, dynamic>> _chapters = [];

  bool _loading = true;
  String? _error;

  bool get _signedIn => authService.isLoggedIn;
  bool get _isRoot => authService.member?.isRoot ?? false;
  bool get _isStaff => authService.member?.isStaff ?? false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_signedIn) {
        context.go('/login?next=/admin/chapters');
        return;
      }

      if (!_isStaff) return;

      _loadChapters();
    });
  }

  Future<void> _loadChapters() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiConfig.dio.get<dynamic>(chaptersEndpoint);

      final body = response.data;
      dynamic list = body;

      if (body is Map) {
        list =
            body['data'] ??
            body['chapters'] ??
            body['items'] ??
            body['results'];

        if (list is Map) {
          list = list['data'] ?? list['chapters'] ?? list['items'];
        }
      }

      if (list is! List) {
        throw const FormatException(
          'Chapter response did not contain a chapters list.',
        );
      }

      final loaded = list
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (!mounted) return;

      setState(() {
        _chapters = loaded;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        context.go('/login?next=/admin/chapters');
        return;
      }

      setState(() {
        _error = e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                  e.message ??
                  'Could not load chapters.')
            : e.message ?? 'Could not load chapters.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('FormatException: ', '');
        _loading = false;
      });
    }
  }

  int get _activeCount => _chapters.where((c) => c['isActive'] != false).length;

  int get _totalMembers => _chapters.fold<int>(
    0,
    (total, chapter) =>
        total + (int.tryParse('${chapter['memberCount'] ?? 0}') ?? 0),
  );

  String _location(Map<String, dynamic> chapter) {
    final city = chapter['city']?.toString() ?? '';
    final country =
        (chapter['countryName'] ?? chapter['country'])?.toString() ?? '';

    return [city, country].where((value) => value.trim().isNotEmpty).join(', ');
  }

  void _openEdit(Map<String, dynamic> chapter) {
    final id = chapter['id']?.toString() ?? '';
    if (id.isEmpty) return;

    context.push('/admin/chapters/${Uri.encodeComponent(id)}');
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const Scaffold(
        backgroundColor: canvas,
        body: Center(child: CircularProgressIndicator(color: purple)),
      );
    }

    if (!_isStaff) {
      return const Scaffold(
        backgroundColor: canvas,
        body: Center(
          child: Text(
            'You do not have permission to access this page.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: canvas,
      appBar: const AppHeader(),
      body: SafeArea(
        child: RefreshIndicator(
          color: purple,
          onRefresh: _loadChapters,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _hero()),
              SliverToBoxAdapter(child: _summary()),
              SliverToBoxAdapter(child: _listHeading()),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: purple),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(hasScrollBody: false, child: _errorView())
              else if (_chapters.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_tree_outlined,
                            size: 42,
                            color: Color(0xFF6C3FD1),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No chapters yet.',
                            style: TextStyle(
                              color: Color(0xFF5F5979),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columns = width >= 1100
                          ? 3
                          : width >= 650
                          ? 2
                          : 1;

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 190,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _chapterCard(_chapters[index]),
                          childCount: _chapters.length,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(isStaff: true),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFBF9FF), Color(0xFFF5EFFF)],
        ),
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ILYF ADMINISTRATION',
                style: TextStyle(
                  color: Color(0xFF702CFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chapters',
                          style: TextStyle(
                            color: Color(0xFF17143D),
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage and monitor chapters across the ILYF network.',
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
                  if (_isRoot)
                    FilledButton.icon(
                      onPressed: () => context.push('/admin/chapters/new'),
                      icon: const Icon(Icons.add, size: 17),
                      label: const Text('Add chapter'),
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 9,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(Icons.dashboard_outlined, size: 16),
                    label: const Text('Dashboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: purpleDark,
                      side: const BorderSide(color: line),
                      shape: const StadiumBorder(),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loadChapters,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: purpleDark,
                      side: const BorderSide(color: line),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 450;

          final cards = [
            _statCard(
              'TOTAL CHAPTERS',
              _chapters.length.toString(),
              Icons.account_tree_outlined,
              purple,
            ),
            _statCard(
              'ACTIVE CHAPTERS',
              _activeCount.toString(),
              Icons.check_circle_outline,
              const Color(0xFF24A879),
            ),
            _statCard(
              'TOTAL MEMBERS',
              _totalMembers.toString(),
              Icons.people_outline,
              rose,
            ),
          ];

          if (compact) {
            return Column(
              children: [
                for (final card in cards) ...[card, const SizedBox(height: 10)],
              ],
            );
          }

          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A4B27A3),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All chapters',
                  style: TextStyle(
                    color: ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chapter details and member information',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFECE5FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '${_chapters.length} chapters',
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

  Widget _chapterCard(Map<String, dynamic> chapter) {
    final name = chapter['name']?.toString() ?? 'Unnamed chapter';
    final code = chapter['code']?.toString() ?? '';
    final count = int.tryParse('${chapter['memberCount'] ?? 0}') ?? 0;
    final active = chapter['isActive'] != false;
    final location = _location(chapter);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _isRoot ? () => _openEdit(chapter) : null,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A4B27A3),
                blurRadius: 17,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C3FD1), Color(0xFF9C78F1)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.account_balance_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  _statusPill(active),
                  if (_isRoot) ...[
                    const SizedBox(width: 5),
                    IconButton(
                      tooltip: 'Edit $name',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _openEdit(chapter),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: purple,
                        size: 19,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (code.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  code,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              if (location.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: rose,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: purple),
                  const SizedBox(width: 6),
                  Text(
                    '$count ${count == 1 ? 'member' : 'members'}',
                    style: const TextStyle(
                      color: purpleDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(bool active) {
    final color = active ? const Color(0xFF159B70) : const Color(0xFFD47A35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_tree_outlined, size: 42, color: purple),
            const SizedBox(height: 12),
            const Text(
              'Unable to load chapters right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadChapters,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
