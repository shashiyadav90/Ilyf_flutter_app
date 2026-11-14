
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const Color background = Color(0xFFF6F3FF);
  static const Color purple = Color(0xFF6C3FD1);
  static const Color purpleDark = Color(0xFF4B27A3);
  static const Color ink = Color(0xFF1A1433);
  static const Color muted = Color(0xFF77718C);
  static const Color line = Color(0xFFE8E1FA);

  bool _loading = true;
  String? _generalError;

  List<Map<String, dynamic>> _businesses = [];
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _news = [];

  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ------------------------------------------------------------
  // API RESPONSE HELPERS
  // ------------------------------------------------------------

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<Map<String, dynamic>> _extractRows(
    dynamic response,
    String collectionKey,
  ) {
    dynamic data = response;

    // Handle nested API response structures.
    for (int i = 0; i < 4; i++) {
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (data is! Map) return [];

      final map = _toMap(data);

      if (map[collectionKey] is List) {
        return _extractRows(map[collectionKey], collectionKey);
      }

      if (map['items'] is List) {
        return _extractRows(map['items'], collectionKey);
      }

      if (map['results'] is List) {
        return _extractRows(map['results'], collectionKey);
      }

      if (map['data'] != null) {
        data = map['data'];
        continue;
      }

      return [];
    }

    return [];
  }

  String _value(
    Map<String, dynamic> item,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = item[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  String _formatDate(String value) {
    if (value.isEmpty) return '';

    final date = DateTime.tryParse(value);

    if (date == null) return value;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ------------------------------------------------------------
  // API INTEGRATION
  // ------------------------------------------------------------

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _generalError = null;
      _errors.clear();
    });

    await Future.wait([
      _loadBusinesses(),
      _loadOffers(),
      _loadEvents(),
      _loadNews(),
    ]);

    if (!mounted) return;

    setState(() {
      _loading = false;

      if (_errors.length == 4) {
        _generalError = 'Unable to load dashboard data.';
      }
    });
  }

  Future<void> _loadBusinesses() async {
    try {
      final response =
          await ApiConfig.dio.get<dynamic>('/businesses');

      _businesses = _extractRows(response.data, 'businesses');
    } on DioException catch (e) {
      _errors['Businesses'] =
          _apiError(e, 'Could not load businesses.');
    } catch (e) {
      _errors['Businesses'] = e.toString();
    }
  }

  Future<void> _loadOffers() async {
    try {
      final response =
          await ApiConfig.dio.get<dynamic>('/offers');

      _offers = _extractRows(response.data, 'offers');
    } on DioException catch (e) {
      _errors['Offers'] = _apiError(e, 'Could not load offers.');
    } catch (e) {
      _errors['Offers'] = e.toString();
    }
  }

  Future<void> _loadEvents() async {
    try {
      final response =
          await ApiConfig.dio.get<dynamic>('/events');

      _events = _extractRows(response.data, 'events');
    } on DioException catch (e) {
      _errors['Events'] = _apiError(e, 'Could not load events.');
    } catch (e) {
      _errors['Events'] = e.toString();
    }
  }

  Future<void> _loadNews() async {
    try {
      final response =
          await ApiConfig.dio.get<dynamic>('/news');

      _news = _extractRows(response.data, 'news');
    } on DioException catch (e) {
      _errors['News'] = _apiError(e, 'Could not load news.');
    } catch (e) {
      _errors['News'] = e.toString();
    }
  }

  String _apiError(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return e.message ?? fallback;
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const AppHeader(),
      bottomNavigationBar: const BottomNav(isStaff: true),
      body: RefreshIndicator(
        color: purple,
        onRefresh: _loadDashboard,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 250),
                  Center(
                    child: CircularProgressIndicator(color: purple),
                  ),
                ],
              )
            : _buildDashboard(),
      ),
    );
  }

  Widget _buildDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 30,
            24,
            isMobile ? 16 : 30,
            35,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(isMobile),

                  const SizedBox(height: 24),

                  if (_generalError != null)
                    _errorBanner(_generalError!),

                  _buildStats(isMobile),

                  const SizedBox(height: 25),

                  _sectionHeading(
                    'Database collections',
                    'Live records returned by the available Data',
                  ),

                  const SizedBox(height: 14),

                  _buildCollections(isMobile),

                  const SizedBox(height: 25),

                  _sectionHeading(
                    'Latest content',
                    'Records currently available from the APIs',
                  ),

                  const SizedBox(height: 14),

                  _buildContentSections(isMobile),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'ILYF Connect · Live API dashboard',
                      style: TextStyle(
                        color: muted.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _header(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF21104F),
            Color(0xFF4B27A3),
            Color(0xFF7652D8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dashboard_customize_outlined,
                color: Colors.white,
                size: 25,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ILYF CONNECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh dashboard',
                onPressed: _loading ? null : _loadDashboard,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            'Database Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 24 : 31,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Monitor businesses, offers, events and news '
            'using live application data.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF65E6A9),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isMobile) {
    final stats = [
      _StatData(
        'Businesses',
        _businesses.length,
        Icons.business_outlined,
        const Color(0xFF6C3FD1),
        'Businesses',
      ),
      _StatData(
        'Offers',
        _offers.length,
        Icons.local_offer_outlined,
        const Color(0xFFE59A36),
        'Offers',
      ),
      _StatData(
        'Events',
        _events.length,
        Icons.event_outlined,
        const Color(0xFF269A77),
        'Events',
      ),
      _StatData(
        'News',
        _news.length,
        Icons.article_outlined,
        const Color(0xFF3985C9),
        'News',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 550 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 115,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];

            return _statCard(stat);
          },
        );
      },
    );
  }

  Widget _statCard(_StatData stat) {
    final failed = _errors.containsKey(stat.endpoint);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.label,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  failed ? '--' : stat.count.toString(),
                  style: const TextStyle(
                    color: ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                Text(
                  failed ? 'API unavailable' : 'Records received',
                  style: TextStyle(
                    color: failed ? Colors.red : muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // COLLECTIONS
  // ------------------------------------------------------------

  Widget _buildCollections(bool isMobile) {
    final collections = [
      _CollectionData(
        'Businesses',
        'Business directory profiles',
        _businesses.length,
        Icons.business_outlined,
        'Businesses',
      ),
      _CollectionData(
        'Offers',
        'Published offer records',
        _offers.length,
        Icons.local_offer_outlined,
        'Offers',
      ),
      _CollectionData(
        'Events',
        'Community event records',
        _events.length,
        Icons.event_outlined,
        'Events',
      ),
      _CollectionData(
        'News',
        'News and announcement records',
        _news.length,
        Icons.article_outlined,
        'News',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600 ? 1 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: collections.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 100,
          ),
          itemBuilder: (context, index) {
            return _collectionCard(collections[index]);
          },
        );
      },
    );
  }

  Widget _collectionCard(_CollectionData data) {
    final error = _errors[data.endpoint];

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(data.icon, color: purple, size: 24),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error ?? data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: error == null ? muted : Colors.red,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            error == null ? data.count.toString() : '--',
            style: const TextStyle(
              color: purpleDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LATEST CONTENT
  // ------------------------------------------------------------

  Widget _buildContentSections(bool isMobile) {
    return Column(
      children: [
        _contentCard(
          title: 'Latest businesses',
          icon: Icons.business_outlined,
          items: _businesses,
          endpoint: 'Businesses',
          getTitle: (item) => _value(
            item,
            ['name', 'businessName', 'fullName', 'title'],
            fallback: 'Business',
          ),
          getSubtitle: (item) => _value(
            item,
            ['category', 'city', 'location', 'chapterName'],
          ),
        ),

        _contentCard(
          title: 'Latest offers',
          icon: Icons.local_offer_outlined,
          items: _offers,
          endpoint: 'Offers',
          getTitle: (item) => _value(
            item,
            ['title', 'name'],
            fallback: 'Offer',
          ),
          getSubtitle: (item) => _value(
            item,
            ['description', 'businessName', 'status'],
          ),
        ),

        _contentCard(
          title: 'Latest events',
          icon: Icons.event_outlined,
          items: _events,
          endpoint: 'Events',
          getTitle: (item) => _value(
            item,
            ['title', 'name'],
            fallback: 'Event',
          ),
          getSubtitle: (item) {
            final date = _value(
              item,
              ['eventDate', 'startDate', 'createdAt'],
            );
            return _formatDate(date);
          },
        ),

        _contentCard(
          title: 'Latest news',
          icon: Icons.article_outlined,
          items: _news,
          endpoint: 'News',
          getTitle: (item) => _value(
            item,
            ['title', 'name'],
            fallback: 'News',
          ),
          getSubtitle: (item) {
            final date = _value(
              item,
              ['startDate', 'createdAt', 'publishedAt'],
            );
            return _formatDate(date);
          },
        ),
      ],
    );
  }

  Widget _contentCard({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String endpoint,
    required String Function(Map<String, dynamic>) getTitle,
    required String Function(Map<String, dynamic>) getSubtitle,
  }) {
    final error = _errors[endpoint];

    final latestItems = items.take(5).toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: purple, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${items.length} records',
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          if (error != null)
            _emptyContent(
              'Could not load $endpoint',
              error,
              isError: true,
            )
          else if (latestItems.isEmpty)
            _emptyContent(
              'No $endpoint available',
              'The API returned no records.',
            )
          else
            ...latestItems.map((item) {
              final itemTitle = getTitle(item);
              final subtitle = getSubtitle(item);

              return _contentRow(
                title: itemTitle,
                subtitle: subtitle,
                icon: icon,
              );
            }),
        ],
      ),
    );
  }

  Widget _contentRow({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: line),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: purple,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyContent(
    String title,
    String description, {
    bool isError = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              isError
                  ? Icons.cloud_off_outlined
                  : Icons.inbox_outlined,
              size: 30,
              color: isError ? Colors.red : muted,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // COMMON WIDGETS
  // ------------------------------------------------------------

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadDashboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: line),
      boxShadow: [
        BoxShadow(
          color: purpleDark.withValues(alpha: 0.035),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// DATA MODELS
// ------------------------------------------------------------

class _StatData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final String endpoint;

  const _StatData(
    this.label,
    this.count,
    this.icon,
    this.color,
    this.endpoint,
  );
}

class _CollectionData {
  final String title;
  final String description;
  final int count;
  final IconData icon;
  final String endpoint;

  const _CollectionData(
    this.title,
    this.description,
    this.count,
    this.icon,
    this.endpoint,
  );
}
