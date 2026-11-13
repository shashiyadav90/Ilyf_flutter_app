import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

import '../../core/config/api_config.dart';
import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../main.dart';
import '../members/membership_required_page.dart';

const _purple = Color(0xFF6C2BE8);
const _purpleDark = Color(0xFF4F1BD0);
const _ink = Color(0xFF17143D);
const _muted = Color(0xFF77758E);
const _background = Color(0xFFFCFBFF);
const _border = Color(0xFFE9E2F8);

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _offers = [];
  String _query = '';
  String _filter = 'All Listings';

  final Set<String> _liked = {};
  final Set<String> _saved = {};
  final Map<String, List<Map<String, String>>> _comments = {};

  bool get _hasFullAccess {
    return authService.member?.hasMembersDirectoryAccess ?? false;
  }

  final List<String> _filters = [
    'All Listings',
    'Services',
    'Food & Events',
    'Home & Living',
    'Wellness',
    'Business',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    if (!mounted) return;

    if (!authService.isLoggedIn) {
      setState(() {
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/login?next=/offers');
      });

      return;
    }

    if (!_hasFullAccess) {
      setState(() {
        _loading = false;
        _error = null;
        _offers = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiConfig.dio.get('/offers');

      debugPrint('========== OFFERS API ==========');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('RESPONSE TYPE: ${response.data.runtimeType}');
      debugPrint('RESPONSE DATA: ${response.data}');

      dynamic data = response.data;

      // Handle JSON returned as a string.
      if (data is String) {
        data = jsonDecode(data);
      }

      dynamic rows;

      if (data is List) {
        rows = data;
      } else if (data is Map) {
        if (data['offers'] is List) {
          rows = data['offers'];
        } else if (data['results'] is List) {
          rows = data['results'];
        } else if (data['items'] is List) {
          rows = data['items'];
        } else if (data['data'] is List) {
          rows = data['data'];
        } else if (data['data'] is Map && data['data']['offers'] is List) {
          rows = data['data']['offers'];
        } else {
          rows = [];
        }
      } else {
        rows = [];
      }

      final List<Map<String, dynamic>> fetchedOffers = [];

      if (rows is List) {
        for (final item in rows) {
          if (item is Map) {
            fetchedOffers.add(Map<String, dynamic>.from(item));
          }
        }
      }

      debugPrint('TOTAL OFFERS RECEIVED: ${fetchedOffers.length}');

      for (final offer in fetchedOffers) {
        debugPrint('OFFER TITLE: ${offer['title']}');
        debugPrint('OFFER BANNER: ${offer['bannerUrl']}');
      }

      if (!mounted) return;

      setState(() {
        _offers = fetchedOffers;
        _loading = false;
        _error = null;
      });
    } on DioException catch (e) {
      debugPrint('OFFERS API ERROR: ${e.message}');
      debugPrint('STATUS: ${e.response?.statusCode}');
      debugPrint('ERROR RESPONSE: ${e.response?.data}');

      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        context.go('/login?next=/offers');
        return;
      }

      setState(() {
        _loading = false;
        _error = e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                  'Could not load offers.')
            : 'Could not load offers. Please try again.';
      });
    } catch (e) {
      debugPrint('OFFERS PARSING ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _text(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String && value.trim().isEmpty) return fallback;
    return value.toString();
  }

  String _first(List<dynamic> values, [String fallback = '']) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  String _image(dynamic value) {
    if (value is String) return value;
    if (value is Map) {
      return _first([value['url'], value['src'], value['secure_url']]);
    }
    return '';
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

    final path = raw.startsWith('members/') ? '/api/media/$raw' : raw;

    return origin.resolve(path).toString();
  }

  String _id(Map<String, dynamic> offer, int index) =>
      _first([offer['id'], offer['_id'], offer['offerId']], 'offer-$index');

  Map<String, dynamic> _author(Map<String, dynamic> offer) {
    final author =
        offer['author'] ??
        offer['member'] ??
        offer['user'] ??
        offer['owner'] ??
        offer['createdBy'];

    return author is Map
        ? Map<String, dynamic>.from(author)
        : <String, dynamic>{};
  }

  String _title(Map<String, dynamic> offer) => _first([
    offer['title'],
    offer['offerTitle'],
    offer['name'],
    offer['headline'],
  ], 'A special offer for the ILYF community');

  String _description(Map<String, dynamic> offer) => _first([
    offer['description'],
    offer['details'],
    offer['message'],
    offer['terms'],
  ], 'Connect with this ILYF member to learn more about the offer.');

  String _category(Map<String, dynamic> offer) => _first([
    offer['category'],
    offer['type'],
    offer['serviceType'],
  ], 'Community offer');

  String _authorName(Map<String, dynamic> offer) {
    final author = _author(offer);
    return _first([
      author['name'],
      author['fullName'],
      author['businessName'],
      offer['memberName'],
      offer['authorName'],
    ], 'ILYF Member');
  }

  String _authorRole(Map<String, dynamic> offer) {
    final author = _author(offer);
    return _first([
      author['businessType'],
      author['role'],
      author['profession'],
      offer['providerType'],
    ], 'Community member');
  }

  String _cover(Map<String, dynamic> offer) {
    dynamic media = offer['media'];

    if (media is List && media.isNotEmpty) {
      media = media.first;
    }

    return _first([
      _image(offer['bannerUrl']),
      _image(offer['coverImage']),
      _image(offer['imageUrl']),
      _image(offer['image']),
      _image(offer['banner']),
      _image(offer['photo']),
      _image(media),
    ]);
  }

  String _avatar(Map<String, dynamic> offer) {
    final author = _author(offer);
    return _first([
      _image(author['avatar']),
      _image(author['photo']),
      _image(author['photoUrl']),
      _image(author['profileImage']),
      _image(author['profilePhoto']),
      _image(offer['authorAvatar']),
    ]);
  }

  String _categoryBucket(String category) {
    final value = category.toLowerCase();

    if (RegExp(r'food|cater|event|restaurant|bakery|dining').hasMatch(value)) {
      return 'Food & Events';
    }
    if (RegExp(
      r'home|interior|plumb|repair|property|furniture|decor',
    ).hasMatch(value)) {
      return 'Home & Living';
    }
    if (RegExp(
      r'wellness|fitness|yoga|health|beauty|salon|spa',
    ).hasMatch(value)) {
      return 'Wellness';
    }
    if (RegExp(
      r'business|consult|finance|marketing|legal|technology|software',
    ).hasMatch(value)) {
      return 'Business';
    }
    return 'Services';
  }

  List<Map<String, dynamic>> get _filteredOffers {
    final query = _query.trim().toLowerCase();

    return _offers.where((offer) {
      final category = _category(offer);
      final author = _authorName(offer);
      final role = _authorRole(offer);
      final location = _first([
        offer['location'],
        offer['city'],
        _author(offer)['city'],
      ]);

      final matchesFilter =
          _filter == 'All Listings' || _categoryBucket(category) == _filter;

      final searchable =
          '${_title(offer)} ${_description(offer)} $category $author $role $location'
              .toLowerCase();

      return matchesFilter && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF25174F),
      ),
    );
  }

  Future<void> _shareOffer(Map<String, dynamic> offer) async {
    final link = _first([
      offer['url'],
      offer['website'],
      offer['link'],
      offer['offerUrl'],
    ]);

    final text =
        '${_title(offer)}\n${_description(offer)}'
        '${link.isNotEmpty ? '\n$link' : ''}';

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showMessage('Offer details copied to clipboard.');
  }

  void _showComments(Map<String, dynamic> offer, String id) {
    final author = _author(offer);
    final rawComments = offer['comments'];
    final comments = rawComments is List
        ? rawComments.whereType<Map>().map((c) {
            return <String, String>{
              'name': _first([
                c['name'],
                (c['user'] is Map) ? c['user']['name'] : null,
              ], 'ILYF Member'),
              'text': _first([c['text'], c['message'], c['content']]),
            };
          }).toList()
        : <Map<String, String>>[];

    final existing = _comments[id] ?? comments;
    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COMMUNITY CONVERSATION',
                                style: TextStyle(
                                  color: _purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Comments',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _title(offer),
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ),
                  ),
                  const Divider(height: 25),
                  Expanded(
                    child: existing.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Start the conversation. Ask a question or share your thoughts.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _muted),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: existing.length,
                            itemBuilder: (context, index) {
                              final comment = existing[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFF0E8FF),
                                  child: Text(
                                    _initials(comment['name'] ?? 'ILYF'),
                                    style: const TextStyle(
                                      color: _purple,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  comment['name'] ?? 'ILYF Member',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(comment['text'] ?? ''),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLength: 500,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Write a comment…',
                              filled: true,
                              fillColor: _background,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(color: _border),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;

                            final comment = {'name': 'You', 'text': text};

                            setState(() {
                              _comments[id] = [...existing, comment];
                            });
                            setSheetState(() {
                              existing.add(comment);
                            });
                            controller.clear();
                            FocusScope.of(context).unfocus();
                          },
                          icon: const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Comments are currently stored locally in this screen.',
                      style: TextStyle(color: _muted, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    return parts.take(2).map((s) => s[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: const AppHeader(),
      body: RefreshIndicator(
        color: _purple,
        onRefresh: _fetchOffers,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
          children: [
            _buildHero(),

            if (!_hasFullAccess) ...[
              const SizedBox(height: 20),
              const MembershipRequiredPage(embedded: true),
            ] else ...[
              const SizedBox(height: 27),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore Listings',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.6,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Something good might be just around the corner.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2FF),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      '${_offers.length} ${_offers.length == 1 ? 'offer' : 'offers'}',
                      style: const TextStyle(
                        color: _purple,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSearch(),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final active = filter == _filter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: active,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = filter),
                      labelStyle: TextStyle(
                        color: active ? Colors.white : _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: _purple,
                      side: BorderSide(color: active ? _purple : _border),
                      shape: const StadiumBorder(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              if (_loading) _buildLoading(),
              if (_error != null) _buildError(),
              if (!_loading && _error == null && _filteredOffers.isEmpty)
                _buildEmpty(),
              if (!_loading && _error == null && _filteredOffers.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    final crossAxisCount = width >= 1100
                        ? 3
                        : width >= 650
                        ? 2
                        : 1;

                    // MOBILE: Cards take only the height they need.
                    if (crossAxisCount == 1) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(
                          _filteredOffers.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _buildOfferCard(
                              _filteredOffers[index],
                              index,
                            ),
                          ),
                        ),
                      );
                    }

                    // WEB / TABLET: Equal-sized cards.
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _filteredOffers.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        mainAxisExtent: crossAxisCount == 3 ? 390 : 410,
                      ),
                      itemBuilder: (context, index) {
                        return _buildOfferCard(_filteredOffers[index], index);
                      },
                    );
                  },
                ),

              const SizedBox(height: 5),
              _buildCommunityNote(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(isStaff: false),
    );
  }

  Widget _buildHero() {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DEFE)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0EAFF), Color(0xFFFAF8FF), Color(0xFFEFF4FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: .07),
            blurRadius: 25,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -45,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _purple.withValues(alpha: .12)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 22, 19, 68),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _purple, size: 16),
                    SizedBox(width: 7),
                    Text(
                      'I L Y F   C O M M U N I T Y',
                      style: TextStyle(
                        color: _purple,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'Good Listings.\nGreat connections.',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 29,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Discover member-only deals, support local businesses, '
                  'and share something valuable with your community.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.55),
                ),
                const SizedBox(height: 13),
                const Row(
                  children: [
                    Icon(Icons.circle, color: Color(0xFF31B89A), size: 8),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Shared by people in your ILYF network',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 13,
            bottom: 13,
            child: FilledButton.icon(
              onPressed: () => context.go('/profile'),
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text(
                'Post a Listing',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 24,
            child: Container(
              width: 66,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8956F4), Color(0xFF5C20D6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withValues(alpha: .2),
                    blurRadius: 15,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sell_rounded, color: Colors.white, size: 27),
                  SizedBox(height: 5),
                  Text(
                    'GOOD DEALS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'Search offers, services or members',
        hintStyle: const TextStyle(color: Color(0xFFA09BB2), fontSize: 12),
        prefixIcon: const Icon(Icons.search_rounded, color: _muted),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () => setState(() => _query = ''),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFB79BFA)),
        ),
      ),
    );
  }

  void _showOfferDetails(String title, String description) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sell_rounded, color: _purple),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Offer details',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(color: _border),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: FilledButton.styleFrom(backgroundColor: _purple),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
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

  Widget _buildOfferCard(Map<String, dynamic> offer, int index) {
    final id = _id(offer, index);
    final author = _author(offer);
    final avatar = _avatar(offer);
    final cover = _cover(offer);
    final category = _category(offer);
    final title = _title(offer);
    final description = _description(offer);
    final location = _first([offer['location'], offer['city'], author['city']]);
    final label = _first([
      offer['offerLabel'],
      offer['discountLabel'],
      offer['discount'],
      offer['badge'],
    ], 'MEMBER EXCLUSIVE');
    final price = _first([
      offer['price'],
      offer['offerPrice'],
      offer['specialPrice'],
      offer['value'],
    ]);
    final originalPrice = _first([
      offer['originalPrice'],
      offer['mrp'],
      offer['regularPrice'],
    ]);
    final validUntil = _first([
      offer['validUntil'],
      offer['expiryDate'],
      offer['expiresAt'],
    ]);
    final verified =
        author['verified'] == true ||
        author['isVerified'] == true ||
        offer['verified'] == true;

    final rawLikes =
        offer['likesCount'] ??
        offer['likeCount'] ??
        (offer['likes'] is List ? (offer['likes'] as List).length : 0);
    final likes =
        (rawLikes is num ? rawLikes.toInt() : int.tryParse('$rawLikes') ?? 0) +
        (_liked.contains(id) ? 1 : 0);

    final rawComments =
        offer['commentsCount'] ??
        offer['commentCount'] ??
        (offer['comments'] is List ? (offer['comments'] as List).length : 0);
    final commentCount =
        (rawComments is num
            ? rawComments.toInt()
            : int.tryParse('$rawComments') ?? 0) +
        (_comments[id]?.length ?? 0);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFECE7F5)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: .045),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFFF0E8FF),
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(_mediaUrl(avatar))
                      : null,
                  child: avatar.isEmpty
                      ? Text(
                          _initials(_authorName(offer)),
                          style: const TextStyle(
                            color: _purple,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _authorName(offer),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              color: _purple,
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _authorRole(offer),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F3FF),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _border),
                  ),
                  child: const Text(
                    'ILYF',
                    style: TextStyle(
                      color: _purple,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cover.isNotEmpty)
                  Image.network(
                    _mediaUrl(cover), // IMPORTANT: use _mediaUrl here
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(
                        child: CircularProgressIndicator(color: _purple),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('IMAGE RENDER ERROR: $error');
                      debugPrint('IMAGE URL: ${_mediaUrl(cover)}');

                      return _buildCoverArt(category);
                    },
                  )
                else
                  _buildCoverArt(category),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x16000000),
                        Colors.transparent,
                        Color(0x33000000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: _purpleDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white.withValues(alpha: .95),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: _saved.contains(id)
                          ? 'Unsave offer'
                          : 'Save offer',
                      onPressed: () => setState(() {
                        _saved.contains(id)
                            ? _saved.remove(id)
                            : _saved.add(id);
                      }),
                      icon: Icon(
                        _saved.contains(id)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _saved.contains(id) ? _purple : _ink,
                      ),
                    ),
                  ),
                ),
                if (label.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8D4BF0), Color(0xFF5D25D5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withValues(alpha: .2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        label.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),

                if (description.length > 100)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        _showOfferDetails(title, description);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View more →',
                        style: TextStyle(
                          color: _purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (price.isNotEmpty ||
                    originalPrice.isNotEmpty ||
                    validUntil.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  const Divider(color: Color(0xFFF0EDF6), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        if (price.isNotEmpty)
                          Expanded(
                            child: Text(
                              price,
                              style: const TextStyle(
                                color: _purpleDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        if (originalPrice.isNotEmpty)
                          Text(
                            originalPrice,
                            style: const TextStyle(
                              color: Color(0xFFA5A0B5),
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (validUntil.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: _muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            validUntil,
                            style: const TextStyle(color: _muted, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: 13),
                const Divider(color: Color(0xFFF0EDF6), height: 1),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _socialAction(
                      icon: _liked.contains(id)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: '$likes',
                      color: _liked.contains(id)
                          ? const Color(0xFFEE4D87)
                          : _muted,
                      onTap: () => setState(() {
                        _liked.contains(id)
                            ? _liked.remove(id)
                            : _liked.add(id);
                      }),
                    ),
                    const SizedBox(width: 18),
                    _socialAction(
                      icon: Icons.mode_comment_outlined,
                      label: '$commentCount',
                      onTap: () => _showComments(offer, id),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      tooltip: 'Copy offer details',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _shareOffer(offer),
                      icon: const Icon(
                        Icons.send_outlined,
                        color: _muted,
                        size: 19,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showComments(offer, id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _purple,
                        backgroundColor: const Color(0xFFF8F4FF),
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        minimumSize: const Size(0, 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Ask about Listing ↗',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverArt(String category) {
    final bucket = _categoryBucket(category);
    final colors = switch (bucket) {
      'Food & Events' => const [Color(0xFFFFF0E7), Color(0xFFFFE0EB)],
      'Home & Living' => const [Color(0xFFE4F9F7), Color(0xFFE7EAFF)],
      'Wellness' => const [Color(0xFFE8FAEF), Color(0xFFE9F2FF)],
      'Business' => const [Color(0xFFE9EAFF), Color(0xFFF3E7FF)],
      _ => const [Color(0xFFF1EAFF), Color(0xFFE7F0FF)],
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -45,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -85,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(color: _purple.withValues(alpha: .18)),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA181FF), Color(0xFF6630DF)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withValues(alpha: .2),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          const Positioned(
            bottom: 17,
            left: 18,
            child: Text(
              'GOOD THINGS, SHARED.',
              style: TextStyle(
                color: Color(0xFF8A70C0),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _muted,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: const Center(child: CircularProgressIndicator(color: _purple)),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F9),
        border: Border.all(color: const Color(0xFFF4D2DB)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error ?? 'Could not load offers.',
            style: const TextStyle(
              color: Color(0xFF7E3448),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _fetchOffers,
            style: FilledButton.styleFrom(backgroundColor: _purple),
            child: const Text('Refresh', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final filtered = _query.isNotEmpty || _filter != 'All Listings';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDED3F6)),
        borderRadius: BorderRadius.circular(21),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAF7FF)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFFF),
              border: Border.all(color: const Color(0xFFE6D9FF)),
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(Icons.sell_outlined, color: _purple, size: 29),
          ),
          const SizedBox(height: 16),
          Text(
            filtered
                ? 'No listings match that search'
                : 'Your community board is ready',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Try another keyword or choose a different category.'
                : 'Be the first to share a special deal, service or member-only perk.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 17),
          OutlinedButton(
            onPressed: () {
              if (filtered) {
                setState(() {
                  _query = '';
                  _filter = 'All Listings';
                });
              } else {
                context.go('/profile');
              }
            },
            child: Text(
              filtered ? 'Clear filters' : 'Add an listing from your profile',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityNote() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFECE5FC)),
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F3FF), Colors.white],
        ),
      ),
      child: const Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFEEE4FF),
              borderRadius: BorderRadius.all(Radius.circular(13)),
            ),
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.auto_awesome_rounded, color: _purple, size: 20),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good things grow when we share.',
                  style: TextStyle(
                    color: Color(0xFF29234E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Support an ILYF member, pass along a great deal, or ask a question before you book.',
                  style: TextStyle(color: _muted, fontSize: 10, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
