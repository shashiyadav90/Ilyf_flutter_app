import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../members/membership_required_page.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';

const _ink = Color(0xFF171031);
const _muted = Color(0xFF5D5778);
const _violet = Color(0xFF6C3FD1);
const _deepPurple = Color(0xFF2A1466);
const _mist = Color(0xFFF6F3FF);
const _line = Color(0xFFE8E1FA);
const _gold = Color(0xFFE9C46A);
const Color _ink3 = Color(0xFF8B849B);

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final Dio _dio = ApiConfig.dio;
  final Set<String> _expandedNewsIds = {};
  int _tab = 0;
  bool _newsLoading = true;
  bool _eventsLoading = true;
  bool _busy = false;
  String? _newsError;
  String? _eventsError;
  List<Map<String, dynamic>> _news = [];
  List<Map<String, dynamic>> _events = [];

  bool get _signedIn => authService.isLoggedIn;
  bool get _staff => authService.isStaff;

  bool get _hasFullAccess {
    return authService.member?.hasMembersDirectoryAccess ?? false;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_signedIn) {
        context.go('/login?next=/news');
        return;
      }

      // Restrict General users from News and Events.
      if (!_hasFullAccess) {
        return;
      }

      _loadNews();
      _loadEvents();
    });
  }

  List<Map<String, dynamic>> _asRows(dynamic response) {
    dynamic data = response;
    if (data is Map) {
      data =
          data['data'] ??
          data['items'] ??
          data['news'] ??
          data['events'] ??
          data['results'] ??
          [];
      if (data is Map)
        data = data['items'] ?? data['rows'] ?? data['data'] ?? [];
    }
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _id(Map<String, dynamic> item) =>
      (item['id'] ?? item['_id'] ?? '').toString();

  String _title(Map<String, dynamic> item) =>
      (item['title'] ?? item['headline'] ?? item['name'] ?? 'News').toString();

  String _error(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      if (m is String) return m;
      if (m is List && m.isNotEmpty) return m.first.toString();
    }
    if (e.response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Could not connect to the server. Check your connection.';
    }
    return fallback;
  }

  Future<void> _loadNews() async {
    if (!_signedIn || !_hasFullAccess) return;
    setState(() {
      _newsLoading = true;
      _newsError = null;
    });
    try {
      final feedResponse = await _dio.get('/news');
      final feed = _asRows(feedResponse.data);
      var result = feed;
      if (_staff) {
        try {
          final mineResponse = await _dio.get('/news');
          final byId = <String, Map<String, dynamic>>{};
          for (final item in [...feed, ..._asRows(mineResponse.data)]) {
            final id = _id(item);
            if (id.isNotEmpty) byId[id] = item;
          }
          result = byId.values.toList()
            ..sort(
              (a, b) => (b['updatedAt'] ?? '').toString().compareTo(
                (a['updatedAt'] ?? '').toString(),
              ),
            );
        } catch (_) {}
      }
      if (mounted) setState(() => _news = result);
    } on DioException catch (e) {
      if (mounted)
        setState(() => _newsError = _error(e, 'Could not load news.'));
    } finally {
      if (mounted) setState(() => _newsLoading = false);
    }
  }

  Future<void> _loadEvents() async {
    if (!_signedIn || !_hasFullAccess) return;
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });
    try {
      final response = await _dio.get('/events');
      if (mounted) setState(() => _events = _asRows(response.data));
    } on DioException catch (e) {
      if (mounted)
        setState(() => _eventsError = _error(e, 'Could not load events.'));
    } finally {
      if (mounted) setState(() => _eventsLoading = false);
    }
  }

  Future<void> _deleteNews(Map<String, dynamic> item) async {
    final id = _id(item);
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove news'),
        content: Text('Do you want to remove “${_title(item)}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _dio.delete('/news/$id');
      await _loadNews();
      _snack('News removed.');
    } on DioException catch (e) {
      _snack(_error(e, 'Could not remove this news item.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _deepPurple,
        ),
      );
  }

  DateTime? _date(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _eventImage(Map<String, dynamic> event) {
    final image =
        event['bannerUrl'] ??
        event['imageUrl'] ??
        event['image_url'] ??
        event['coverImage'] ??
        event['posterUrl'] ??
        event['image'] ??
        event['banner'] ??
        '';

    if (image is Map) {
      final url = image['url'] ?? image['src'] ?? image['secure_url'] ?? '';

      return _mediaUrl(url.toString());
    }

    return _mediaUrl(image.toString());
  }

  DateTime? _eventStart(Map<String, dynamic> e) {
    final raw =
        e['startsAt'] ??
        e['start'] ??
        e['dateTime'] ??
        e['date'] ??
        e['startDate'];
    if (raw == null) return null;
    final s = raw.toString();
    final hasTime = RegExp(r'T\d{2}:\d{2}|\s\d{1,2}:\d{2}').hasMatch(s);
    return DateTime.tryParse(
      !hasTime && e['time'] != null ? '${s}T${e['time']}' : s,
    )?.toLocal();
  }

  DateTime? _eventEnd(Map<String, dynamic> e) =>
      _date(e['endsAt'] ?? e['end'] ?? e['endDate']);

  bool _hasTime(Map<String, dynamic> e) {
    final raw =
        (e['startsAt'] ??
                e['start'] ??
                e['dateTime'] ??
                e['date'] ??
                e['startDate'] ??
                '')
            .toString();
    return RegExp(r'T\d{2}:\d{2}|\s\d{1,2}:\d{2}').hasMatch(raw) ||
        e['time'] != null;
  }

  List<Map<String, dynamic>> get _upcoming {
    final now = DateTime.now();
    return _events.where((e) {
      final start = _eventStart(e);
      final end = _eventEnd(e) ?? (start?.add(const Duration(hours: 3)));
      return end == null || !end.isBefore(now);
    }).toList()..sort(
      (a, b) => (_eventStart(a) ?? DateTime(2100)).compareTo(
        _eventStart(b) ?? DateTime(2100),
      ),
    );
  }

  List<Map<String, dynamic>> get _past {
    final now = DateTime.now();
    return _events.where((e) {
      final start = _eventStart(e);
      final end = _eventEnd(e) ?? start?.add(const Duration(hours: 3));
      return end != null && end.isBefore(now);
    }).toList()..sort(
      (a, b) => (_eventStart(b) ?? DateTime(1970)).compareTo(
        _eventStart(a) ?? DateTime(1970),
      ),
    );
  }

  String _month(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  String _ago(dynamic value) {
    final d = _date(value);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.isNegative) return '';
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${d.day} ${_month(d.month)}';
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const Scaffold(
        backgroundColor: _mist,
        body: Center(child: CircularProgressIndicator(color: _violet)),
      );
    }

    // Show membership-required screen for General users.
    if (!_hasFullAccess) {
      return const MembershipRequiredPage();
    }

    return Scaffold(
      backgroundColor: _mist,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: AppHeader(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _hero(),
            _tabBar(),
            Expanded(child: _tab == 0 ? _newsBody() : _eventsBody()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(isStaff: _staff),
    );
  }

  Widget _hero() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_staff)
          FilledButton.icon(
            onPressed: () =>
                context.go(_tab == 1 ? '/events/new' : '/news/new'),
            icon: const Icon(Icons.add, size: 17),
            label: Text(_tab == 1 ? 'Add event' : 'Add news'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
      ],
    ),
  );

  Widget _tabBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147527C6),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _tabButton(0, 'News', Icons.article_outlined),
          _tabButton(
            1,
            'Events',
            Icons.calendar_month_outlined,
            _upcoming.length,
          ),
        ],
      ),
    ),
  );

  Widget _tabButton(int index, String label, IconData icon, [int badge = 0]) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xFF7B4DE0),
                      Color(0xFF5A34C6),
                      Color(0xFF3B63E8),
                    ],
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: selected ? Colors.white : _muted),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (index == 1 && badge > 0) ...[
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: selected ? Colors.white24 : _mist,
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      color: selected ? Colors.white : _deepPurple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _newsBody() {
    if (_newsLoading && _news.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          _NewsSkeleton(),
          SizedBox(height: 16),
          _NewsSkeleton(),
        ],
      );
    }
    if (_newsError != null && _news.isEmpty)
      return _errorState(_newsError!, _loadNews);
    if (_news.isEmpty) {
      return _emptyState(
        Icons.article_outlined,
        'No news yet',
        _staff
            ? 'Add one with Add news.'
            : 'New announcements will show up here.',
      );
    }
    return RefreshIndicator(
      color: _violet,
      onRefresh: _loadNews,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 650
              ? 2
              : 1;

          final cardWidth =
              (constraints.maxWidth - 28 - (16 * (columns - 1))) / columns;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: _news.map((item) {
                  return SizedBox(
                    width: cardWidth,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _newsCard(item),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _newsCard(Map<String, dynamic> item) {
    final title = _title(item);
    final body = (item['description'] ?? item['body'] ?? item['content'] ?? '')
        .toString();
    final member = item['member'] is Map ? item['member'] as Map : {};
    final author =
        (member['name'] ?? item['authorName'] ?? item['author_name'] ?? 'ILYF')
            .toString();
    final avatar = (member['avatar'] ?? '').toString();
    final image =
        (item['bannerUrl'] ??
                item['imageUrl'] ??
                item['image_url'] ??
                item['image'] ??
                '')
            .toString();
    final category = (item['category'] ?? 'Announcement').toString();
    final created =
        item['updatedAt'] ?? item['createdAt'] ?? item['created_at'];
    final link = (item['link'] ?? item['url'] ?? item['linkUrl'] ?? '')
        .toString();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147527C6),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
            child: Row(
              children: [
                _avatar(author, avatar),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          height: 1.3,
                        ),
                      ),
                      Text(
                        _ago(created),
                        style: const TextStyle(
                          color: Color(0xFF8D86A8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_busy && _staff) ...[
                  IconButton(
                    tooltip: 'Edit news',
                    onPressed: () => context.go('/news/${_id(item)}/edit'),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _deepPurple,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove news',
                    onPressed: () => _deleteNews(item),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (image.isNotEmpty)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _mediaUrl(image),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _poster(title, author, category),
                  ),
                ),
                Positioned(left: 12, top: 12, child: _tag(category)),
              ],
            )
          else
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _poster(title, author, category),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1.3,
                    ),
                  ),
                Builder(
                  builder: (context) {
                    final String newsId = _id(item);
                    final bool isExpanded = _expandedNewsIds.contains(newsId);

                    const descriptionStyle = TextStyle(
                      color: _muted,
                      fontSize: 14,
                      height: 1.6,
                    );

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final textPainter = TextPainter(
                          text: const TextSpan(),
                          textDirection: Directionality.of(context),
                        );

                        textPainter.text = TextSpan(
                          text: body,
                          style: descriptionStyle,
                        );

                        textPainter.maxLines = 3;
                        textPainter.ellipsis = '...';
                        textPainter.textScaler = MediaQuery.textScalerOf(
                          context,
                        );

                        textPainter.layout(maxWidth: constraints.maxWidth);

                        final bool hasMore = textPainter.didExceedMaxLines;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: Text(
                                body,
                                maxLines: isExpanded ? null : 3,
                                overflow: isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: descriptionStyle,
                              ),
                            ),

                            if (hasMore)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedNewsIds.remove(newsId);
                                      } else {
                                        _expandedNewsIds.add(newsId);
                                      }
                                    });
                                  },
                                  child: Text(
                                    isExpanded ? 'Read less' : 'Read more',
                                    style: const TextStyle(
                                      color: _deepPurple,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
                if (link.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openUrl(link),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Read more'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mediaUrl(String value) {
    final raw = value.trim();

    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('data:') ||
        raw.startsWith('blob:')) {
      return raw;
    }

    final baseUri = Uri.parse(ApiConfig.baseUrl);

    final origin = baseUri.replace(path: '/', query: null, fragment: null);

    return origin.resolve(raw).toString();
  }

  Widget _avatar(String name, String image) {
    if (image.isNotEmpty) {
      return CircleAvatar(
        radius: 21,
        backgroundImage: NetworkImage(_mediaUrl(image)),
      );
    }
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 21,
      backgroundColor: _violet,
      child: Text(
        initials.isEmpty ? 'I' : initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: _violet,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.article_outlined, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _poster(String title, String author, String category) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(23),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_deepPurple, _violet, Color(0xFF3B63E8)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tag(category),
        const Spacer(),
        Text(
          title,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 32,
            height: 1.08,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          author,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _eventsBody() {
    if (_eventsLoading && _events.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          _EventSkeleton(),
          SizedBox(height: 12),
          _EventSkeleton(),
        ],
      );
    }
    if (_eventsError != null && _events.isEmpty)
      return _errorState(_eventsError!, _loadEvents);
    if (_events.isEmpty) {
      return _emptyState(
        Icons.calendar_month_outlined,
        'No events yet',
        _staff
            ? 'Add one with Add event.'
            : 'Upcoming events will show up here.',
      );
    }
    final upcoming = _upcoming;
    final past = _past;
    return RefreshIndicator(
      color: _violet,
      onRefresh: _loadEvents,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 650
              ? 2
              : 1;

          Widget eventGrid(List<Map<String, dynamic>> events, String section) {
            if (events.isEmpty) {
              return _NoEvents(
                section == 'Upcoming'
                    ? 'No upcoming events right now.'
                    : 'No past events yet.',
              );
            }

            final cardWidth =
                (constraints.maxWidth - 28 - (16 * (columns - 1))) / columns;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: events.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;

                return SizedBox(
                  width: cardWidth,
                  child: _EventTile(
                    event: event,
                    imageUrl: _eventImage(event),
                    variant: section == 'Upcoming'
                        ? (index == 0 ? 'next' : 'row')
                        : (index == 0 ? 'last' : 'row'),
                    start: _eventStart(event),
                    end: _eventEnd(event),
                    hasTime: _hasTime(event),
                    onOpen: _openUrl,
                    onCalendar: () => _calendar(event),
                  ),
                );
              }).toList(),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 25),
            children: [
              _sectionTitle('Upcoming'),
              eventGrid(upcoming, 'Upcoming'),
              const SizedBox(height: 20),
              _sectionTitle('Past events'),
              eventGrid(past, 'Past events'),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 9, 4, 12),
    child: Text(
      title,
      style: const TextStyle(fontFamily: 'Georgia', fontSize: 26, color: _ink),
    ),
  );

  Future<void> _calendar(Map<String, dynamic> event) async {
    final start = _eventStart(event);
    if (start == null) return;
    final end =
        _eventEnd(event) ??
        start.add(
          _hasTime(event) ? const Duration(hours: 2) : const Duration(days: 1),
        );
    String stamp(DateTime d) {
      String p(int n) => n.toString().padLeft(2, '0');
      return '${d.year}${p(d.month)}${p(d.day)}T${p(d.hour)}${p(d.minute)}00';
    }

    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': _title(event),
      'dates': '${stamp(start)}/${stamp(end)}',
      'details': (event['description'] ?? event['about'] ?? '').toString(),
      'location': (event['venue'] ?? event['location'] ?? '').toString(),
    });
    await _openUrl(uri.toString());
  }

  Widget _emptyState(IconData icon, String title, String subtitle) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 60),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _mist,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(icon, color: _violet, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 25,
                color: _ink,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _errorState(String message, Future<void> Function() retry) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 50),
      Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFCBD5)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFC4194A), size: 30),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9F2446)),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: retry,
              style: FilledButton.styleFrom(backgroundColor: _violet),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _EventTile extends StatefulWidget {
  const _EventTile({
    required this.event,
    required this.imageUrl,
    required this.variant,
    required this.start,
    required this.end,
    required this.hasTime,
    required this.onOpen,
    required this.onCalendar,
  });

  final Map<String, dynamic> event;
  final String imageUrl;
  final String variant;
  final DateTime? start;
  final DateTime? end;
  final bool hasTime;
  final ValueChanged<String> onOpen;
  final VoidCallback onCalendar;

  @override
  State<_EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<_EventTile> {
  bool _expanded = false;

  String get _title =>
      (widget.event['title'] ?? widget.event['name'] ?? 'Event').toString();
  String get _about =>
      (widget.event['description'] ?? widget.event['about'] ?? '').toString();
  String get _venue =>
      (widget.event['venue'] ?? widget.event['location'] ?? '').toString();
  String get _link =>
      (widget.event['registerUrl'] ??
              widget.event['link'] ??
              widget.event['url'] ??
              '')
          .toString();
  bool get _past => widget.variant == 'last';

  String _clock(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _date(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}${d.year == DateTime.now().year ? '' : ' ${d.year}'}';
  }

  String _when(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff <= 45) return 'In $diff days';
    if (diff < -1 && diff >= -45) return '${-diff} days ago';
    return '${d.month}/${d.year}';
  }

  List<String> _agenda() {
    final value =
        widget.event['agenda'] ??
        widget.event['schedule'] ??
        widget.event['whatsNext'] ??
        widget.event['plan'];
    if (value is List) {
      return value
          .map((row) {
            if (row is Map) {
              final time = (row['time'] ?? '').toString();
              final title = (row['title'] ?? row['text'] ?? row['name'] ?? '')
                  .toString();
              return time.isEmpty ? title : '$time  $title';
            }
            return row.toString();
          })
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (value == null) return [];
    return value
        .toString()
        .split(RegExp(r'[\n;]'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.variant == 'next';
    final last = widget.variant == 'last';
    final dark = next;
    final fg = dark ? Colors.white : _ink;
    final start = widget.start;
    final recap =
        (widget.event['recap'] ??
                widget.event['summary'] ??
                widget.event['outcome'] ??
                widget.event['whatHappened'] ??
                '')
            .toString();
    final highlightsRaw = widget.event['highlights'];
    final highlights = highlightsRaw is List
        ? highlightsRaw.map((e) => e.toString()).toList()
        : (highlightsRaw ?? '')
              .toString()
              .split(RegExp(r'[\n;]'))
              .where((e) => e.trim().isNotEmpty)
              .toList();
    final attendees =
        int.tryParse((widget.event['attendees'] ?? 0).toString()) ?? 0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF24105F) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: last ? const Color(0xFFD9CDF7) : _line),
          boxShadow: [
            BoxShadow(
              color: _deepPurple.withValues(alpha: .08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 16, 15, 7),
                child: Row(
                  children: [
                    if (start != null)
                      Container(
                        width: 59,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: dark ? Colors.white12 : _mist,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: dark ? Colors.white24 : _line,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${start.day}',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 29,
                                color: dark ? _gold : _ink,
                              ),
                            ),
                            Text(
                              start.month.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: dark ? _gold : _violet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (start != null) const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (next || last)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                next ? 'NEXT EVENT' : 'LAST EVENT',
                                style: TextStyle(
                                  color: dark ? _gold : _violet,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          Text(
                            _title,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: widget.variant == 'row' ? 21 : 25,
                              height: 1.1,
                              color: fg,
                            ),
                          ),
                          if (start != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              _when(start),
                              style: TextStyle(
                                color: dark ? _gold : _violet,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.variant == 'row')
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_down
                            : Icons.chevron_right,
                        color: _ink3,
                      ),
                  ],
                ),
              ),
            ),
            if (start != null || _venue.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 5),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (start != null)
                      _chip(Icons.calendar_today_outlined, _date(start), dark),
                    if (start != null && widget.hasTime)
                      _chip(
                        Icons.access_time,
                        '${_clock(start)}${widget.end == null ? '' : ' to ${_clock(widget.end!)}'}',
                        dark,
                      ),
                    if (_venue.isNotEmpty)
                      _chip(Icons.location_on_outlined, _venue, dark),
                  ],
                ),
              ),
            if (widget.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      widget.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return Container(
                          color: _mist,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: _violet,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('EVENT IMAGE ERROR: $error');
                        debugPrint('EVENT IMAGE URL: ${widget.imageUrl}');

                        return Container(
                          color: _mist,
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: _violet,
                                size: 35,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Event image unavailable',
                                style: TextStyle(color: _muted, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            if (_expanded) ...[
              if (!_past) ...[
                if (_about.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      _about,
                      style: TextStyle(
                        color: dark ? Colors.white70 : _muted,
                        height: 1.6,
                      ),
                    ),
                  ),
                if (_agenda().isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 7),
                    child: Text(
                      'What will happen',
                      style: TextStyle(
                        color: dark ? _gold : _deepPurple,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ..._agenda().map(
                    (line) => Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 16, 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 7, color: _gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                color: dark ? Colors.white : _ink,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else ...[
                if (recap.isNotEmpty || _about.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What happened',
                          style: TextStyle(
                            color: _deepPurple,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          recap.isNotEmpty ? recap : _about,
                          style: const TextStyle(color: _muted, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                if (attendees > 0 || highlights.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 4),
                    child: Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (attendees > 0)
                          _highlight('$attendees attended', true),
                        ...highlights.map((e) => _highlight(e, false)),
                      ],
                    ),
                  ),
              ],
              if ((!_past && start != null) || _link.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
                  child: Row(
                    children: [
                      if (!_past && start != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onCalendar,
                            icon: const Icon(Icons.calendar_month, size: 17),
                            label: const Text('Add to calendar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dark
                                  ? Colors.white
                                  : _deepPurple,
                              side: BorderSide(
                                color: dark ? Colors.white38 : _line,
                              ),
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                      if (!_past && start != null && _link.isNotEmpty)
                        const SizedBox(width: 8),
                      if (_link.isNotEmpty)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => widget.onOpen(_link),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text(_past ? 'See more' : 'Register'),
                            style: FilledButton.styleFrom(
                              backgroundColor: dark ? _gold : _violet,
                              foregroundColor: dark
                                  ? const Color(0xFF2A1A00)
                                  : Colors.white,
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, bool dark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: dark ? Colors.white12 : _mist,
      border: Border.all(color: dark ? Colors.white24 : _line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: dark ? _gold : _violet),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: dark ? Colors.white : _muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _highlight(String text, bool stat) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      gradient: stat
          ? const LinearGradient(colors: [Color(0xFF7B4DE0), Color(0xFF3B63E8)])
          : null,
      color: stat ? null : _mist,
      border: Border.all(color: stat ? Colors.transparent : _line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: stat ? Colors.white : _deepPurple,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _NoEvents extends StatelessWidget {
  const _NoEvents(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFCFC2F3)),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: _muted),
    ),
  );
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _line),
    ),
    child: Column(
      children: [
        const Row(
          children: [
            CircleAvatar(radius: 21, backgroundColor: _mist),
            SizedBox(width: 12),
            SizedBox(width: 130, height: 13, child: ColoredBox(color: _mist)),
          ],
        ),
        const SizedBox(height: 14),
        AspectRatio(aspectRatio: 1, child: ColoredBox(color: _mist)),
        const SizedBox(height: 14),
        const SizedBox(
          height: 12,
          width: double.infinity,
          child: ColoredBox(color: _mist),
        ),
      ],
    ),
  );
}

class _EventSkeleton extends StatelessWidget {
  const _EventSkeleton();
  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _line),
    ),
  );
}
