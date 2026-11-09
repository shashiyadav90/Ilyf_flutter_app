import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';
import 'dart:async';
import '../../data/models/story_model.dart';
import '../../services/story_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  static const Color purple = Color(0xFF6C3FD1);
  static const Color purpleDark = Color(0xFF4B27A3);
  static const Color background = Color(0xFFF7F5FC);
  static const Color ink = Color(0xFF1A1433);
  static const Color muted = Color(0xFF898398);
  static const Color border = Color(0xFFECE8F3);

  final StoryService _storyService = StoryService();
  final ImagePicker _imagePicker = ImagePicker();

  List<StoryModel> _myStories = [];
  List<StoryMemberGroup> _storyMembers = [];

  bool _storiesLoading = false;

  Map<String, dynamic> _overview = {};
  bool _loading = true;
  String? _error;

  Map<String, dynamic> get _profile =>
      (_overview['profile'] as Map?)?.cast<String, dynamic>() ?? {};

  Map<String, dynamic> get _stats =>
      (_overview['stats'] as Map?)?.cast<String, dynamic>() ?? {};

  List<Map<String, dynamic>> get _weeklyEnquiries =>
      ((_overview['weeklyEnquiries'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();

  List<Map<String, dynamic>> get _recentEnquiries =>
      ((_overview['recentEnquiries'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();

  List<Map<String, dynamic>> get _latestOffers =>
      ((_overview['latestOffers'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();

  String _text(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _readStoriesFromOverview(Map<String, dynamic> data) {
    final stories = data['stories'];

    if (stories is! Map) {
      _myStories = [];
      _storyMembers = [];
      return;
    }

    final myStoriesData = stories['myStories'] is List
        ? stories['myStories'] as List
        : [];

    final membersData = stories['members'] is List
        ? stories['members'] as List
        : [];

    _myStories = myStoriesData
        .whereType<Map>()
        .map((item) => StoryModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    _storyMembers = membersData
        .whereType<Map>()
        .map(
          (item) => StoryMemberGroup.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> _fetchStories() async {
    if (mounted) {
      setState(() => _storiesLoading = true);
    }

    try {
      final data = await _storyService.getStories();

      final myStoriesData = data['myStories'] is List
          ? data['myStories'] as List
          : [];

      final membersData = data['members'] is List
          ? data['members'] as List
          : [];

      if (!mounted) return;

      setState(() {
        _myStories = myStoriesData
            .whereType<Map>()
            .map((item) => StoryModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        _storyMembers = membersData
            .whereType<Map>()
            .map(
              (item) =>
                  StoryMemberGroup.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

        _storiesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _storiesLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load stories: $e')));
    }
  }

  void _showCreateStoryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create a story',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.image_outlined, color: purple),
                  title: const Text('Upload image'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickStoryMedia('IMAGE');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam_outlined, color: purple),
                  title: const Text('Upload video'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickStoryMedia('VIDEO');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_fields, color: purple),
                  title: const Text('Create text story'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _createTextStory();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickStoryMedia(String mediaType) async {
    try {
      final XFile? file = mediaType == 'IMAGE'
          ? await _imagePicker.pickImage(source: ImageSource.gallery)
          : await _imagePicker.pickVideo(source: ImageSource.gallery);

      if (file == null) return;

      await _uploadStory(mediaType: mediaType, file: file);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to select media: $e')));
    }
  }

  Future<void> _uploadStory({
    required String mediaType,
    XFile? file,
    String? text,
  }) async {
    try {
      await _storyService.createStory(
        mediaType: mediaType,
        file: file,
        text: text,
      );

      await _fetchStories();
    } catch (e) {
      debugPrint('Story upload error: $e');
      rethrow;
    }
  }

  Future<void> _openMemberStories(StoryMemberGroup group) async {
    if (group.stories.isEmpty) return;

    await showDialog(
      context: context,
      builder: (_) => _StoryListDialog(
        memberName: _text(group.member['fullName'], 'Member'),
        stories: group.stories,
        onViewStory: (storyId) async {
          await _storyService.viewStory(storyId);
        },
      ),
    );

    if (mounted) {
      await _fetchStories();
    }
  }

  Future<void> _createTextStory() async {
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create text story'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Write something for your community...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (text == null || text.isEmpty) return;

    await _uploadStory(mediaType: 'TEXT', text: text);
  }

  Future<void> _openMyStories() async {
    if (_myStories.isEmpty) {
      _showCreateStoryOptions();
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => _StoryListDialog(
        memberName: 'Your story',
        stories: _myStories,
        onShowStoryViews: _showStoryViews,
        onLoadViewCount: _loadStoryViewCount,
      ),
    );
  }

  Future<void> _deleteStory(String storyId) async {
    try {
      await _storyService.deleteStory(storyId);
      await _fetchStories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story deleted successfully')),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      final data = e.response?.data;
      final message = data is Map
          ? _text(data['message'], 'Unable to delete story')
          : 'Unable to delete story';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showStoryViews(String storyId) async {
    try {
      final data = await _storyService.getStoryViews(storyId);

      if (!mounted) return;

      final viewers = data['viewers'] is List ? data['viewers'] as List : [];

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Viewed by ${data['totalViews'] ?? viewers.length}',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (viewers.isEmpty)
                    const Text('No views yet.')
                  else
                    ...viewers.map((item) {
                      if (item is! Map) return const SizedBox.shrink();

                      final viewer = Map<String, dynamic>.from(item);
                      final photo = _text(viewer['photoUrl']);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(_text(viewer['fullName'], 'ILYF Member')),
                        subtitle: Text(_text(viewer['city'])),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load viewers: $e')));
    }
  }

  Future<int> _loadStoryViewCount(String storyId) async {
    try {
      final data = await _storyService.getStoryViews(storyId);

      if (data is Map) {
        final count = data['totalViews'];

        if (count is num) return count.toInt();

        if (count != null) {
          return int.tryParse(count.toString()) ?? 0;
        }

        final viewers = data['viewers'];
        if (viewers is List) return viewers.length;
      }

      return 0;
    } catch (e) {
      debugPrint('Unable to load story view count: $e');
      return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchOverview();
  }

  Future<void> _fetchOverview() async {
    // 1. Check whether the user is logged in.
    if (!authService.isLoggedIn) {
      if (mounted) {
        setState(() {
          _loading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/login?next=/overview');
        });
      }
      return;
    }

    // 2. Show loading indicator.
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // 3. Fetch Overview API.
      final response = await ApiConfig.dio.get<dynamic>('/overview');

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid overview response from server.');
      }

      // 4. Update Overview data.
      if (!mounted) return;

      setState(() {
        _overview = data.cast<String, dynamic>();

        _readStoriesFromOverview(_overview);

        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      // 5. If session expired, redirect to login.
      if (e.response?.statusCode == 401) {
        context.go('/login?next=/overview');
        return;
      }

      // 6. Handle other API errors.
      setState(() {
        _loading = false;
        _error = e.response?.data is Map
            ? _text(
                (e.response!.data as Map)['message'],
                'Unable to load overview.',
              )
            : 'Unable to load overview. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;

      // 7. Handle unexpected errors.
      setState(() {
        _loading = false;
        _error = 'Unable to load overview. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const AppHeader(),
      bottomNavigationBar: const BottomNav(isStaff: false),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: purple))
            : _error != null
            ? _errorView()
            : RefreshIndicator(
                color: purple,
                onRefresh: _fetchOverview,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 28),
                  children: [
                    _greetingSection(),
                    _storiesSection(),
                    _statisticsSection(),
                    _activitySection(),
                    _enquiriesSection(),
                    _offersSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: muted),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: ink, fontSize: 14),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _fetchOverview,
              style: ElevatedButton.styleFrom(backgroundColor: purple),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // GREETING SECTION
  Widget _greetingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 23, 18, 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF26105C), Color(0xFF5C35B5), Color(0xFF8060D5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: purple.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GOOD DAY 👋',
                    style: TextStyle(
                      color: Color(0xFFDCD0FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Hi, ${_text(_profile['fullName'], 'Member')}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    [
                              _text((_profile['chapter'] as Map?)?['name']),
                              _text(_profile['city']),
                            ]
                            .where((value) => value.isNotEmpty)
                            .toSet()
                            .join(' • ')
                            .isNotEmpty
                        ? [
                                _text((_profile['chapter'] as Map?)?['name']),
                                _text(_profile['city']),
                              ]
                              .where((value) => value.isNotEmpty)
                              .toSet()
                              .join(' • ')
                        : 'Stay connected. Keep growing.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFFFFD780),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_text(_profile['membershipType'], 'Member')} Member',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: ClipOval(
                child: _text(_profile['photoUrl']).isNotEmpty
                    ? Image.network(
                        _text(_profile['photoUrl']),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 43,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 43,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STORIES SECTION
  Widget _storiesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Stories', 'Share an update with your community'),
          const SizedBox(height: 14),
          if (_storiesLoading)
            const SizedBox(
              height: 92,
              child: Center(child: CircularProgressIndicator(color: purple)),
            )
          else
            SizedBox(
              height: 112,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _storyAvatar(
                    name: 'Your story',
                    imageUrl: _text(_profile['photoUrl']),
                    hasStory: _myStories.isNotEmpty,
                    isViewed: false,
                    isAdd: _myStories.isEmpty,
                    onTap: _myStories.isEmpty
                        ? _showCreateStoryOptions
                        : _openMyStories,
                  ),
                  const SizedBox(width: 14),
                  ..._storyMembers.map((group) {
                    final member = group.member;
                    final allViewed =
                        group.stories.isNotEmpty &&
                        group.stories.every((story) => story.isViewed);
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _storyAvatar(
                        name: _text(member['fullName'], 'Member'),
                        imageUrl: _text(member['photoUrl']),
                        hasStory: group.stories.isNotEmpty,
                        isViewed: allViewed,
                        onTap: () => _openMemberStories(group),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _storyAvatar({
    required String name,
    required String imageUrl,
    required bool hasStory,
    required bool isViewed,
    required VoidCallback onTap,
    bool isAdd = false,
  }) {
    return SizedBox(
      width: 70,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasStory
                      ? (isViewed ? const Color(0xFFBDB8C8) : purple)
                      : border,
                  width: 2.2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFECE4FF),
                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person, color: purpleDark)
                        : null,
                  ),
                  if (isAdd)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                          color: purple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ink,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STATISTICS SECTION
  Widget _statisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading('Your activity', 'A quick look at your community'),
          const SizedBox(height: 13),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.30,
            children: [
              _statCard(
                'Total Enquiries',
                '${_number(_stats['totalEnquiries'])}',
                Icons.mark_email_unread_outlined,
                const Color(0xFFECE4FF),
                purple,
                'All enquiries',
              ),
              _statCard(
                'Pending Enquiries',
                '${_number(_stats['pendingEnquiries'])}',
                Icons.pending_actions_rounded,
                const Color(0xFFFFECDD),
                const Color(0xFFE18A42),
                'Awaiting response',
              ),
              _statCard(
                'Completed',
                '${_number(_stats['completedEnquiries'])}',
                Icons.task_alt_rounded,
                const Color(0xFFDFF3E8),
                const Color(0xFF29986B),
                'Resolved enquiries',
              ),
              _statCard(
                'Active Offers',
                '${_number(_stats['activeOffers'])}',
                Icons.local_offer_outlined,
                const Color(0xFFE3EBFF),
                const Color(0xFF4B75D1),
                'Currently active',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color iconBackground,
    Color iconColor,
    String caption,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF29986B),
                size: 17,
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: ink,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: iconColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ACTIVITY GRAPH
  Widget _activitySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 25, 18, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enquiry activity',
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your weekly activity',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'This week',
                    style: TextStyle(
                      color: purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 155,
              width: double.infinity,
              child: CustomPaint(
                painter: _ActivityChartPainter(
                  values: _weeklyEnquiries
                      .map((e) => _number(e['count']).toDouble())
                      .toList(),
                  labels: _weeklyEnquiries.map((e) => _text(e['day'])).toList(),
                  purple: purple,
                  gridColor: border,
                  textColor: muted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.circle, size: 8, color: purple),
                SizedBox(width: 6),
                Text(
                  'Enquiries received',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // RECENT ENQUIRIES FROM OVERVIEW API
  Widget _enquiriesSection() {
    final items = _recentEnquiries;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 27, 18, 0),
      child: Column(
        children: [
          _sectionHeading(
            'Recent enquiries',
            'Latest enquiries from your community',
            action: 'View all',
            onAction: () => context.go('/'),
          ),
          const SizedBox(height: 13),
          if (items.isEmpty)
            _emptyCard('No recent enquiries found.')
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
              ),
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      _enquiryTile(item),
                      if (index != items.length - 1)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: border,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _enquiryTile(Map<String, dynamic> item) {
    final status = _text(item['status'], 'UNKNOWN').toUpperCase();
    final title = _text(item['title'], 'Untitled enquiry');
    final category = _text(item['category'], 'General');
    final createdAt = _text(item['createdAt']);

    Color statusColor;
    Color statusBackground;
    if (status == 'NEW') {
      statusColor = const Color(0xFF4C73D1);
      statusBackground = const Color(0xFFEAF0FF);
    } else if (status == 'PENDING' || status == 'IN_PROGRESS') {
      statusColor = const Color(0xFFD48A37);
      statusBackground = const Color(0xFFFFF2DF);
    } else if (status == 'COMPLETED' || status == 'RESOLVED') {
      statusColor = const Color(0xFF29986B);
      statusBackground = const Color(0xFFE2F5EB);
    } else {
      statusColor = muted;
      statusBackground = const Color(0xFFF0EEF4);
    }

    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'E';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE9DFFF),
            backgroundImage: _text(item['imageUrl']).isNotEmpty
                ? NetworkImage(_text(item['imageUrl']))
                : null,
            child: _text(item['imageUrl']).isEmpty
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(createdAt),
                    style: const TextStyle(
                      color: Color(0xFFA29DAF),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 12),
      ),
    );
  }

  // LATEST OFFERS FROM OVERVIEW API
  Widget _offersSection() {
    final items = _latestOffers;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 27, 18, 0),
      child: Column(
        children: [
          _sectionHeading(
            'Latest offers',
            'Exclusive opportunities for members',
            action: 'View all',
            onAction: () => context.go('/offers'),
          ),
          const SizedBox(height: 13),
          if (items.isEmpty)
            _emptyCard('No offers available right now.')
          else
            ...items.map(_offerCard),
        ],
      ),
    );
  }

  Widget _offerCard(Map<String, dynamic> offer) {
    final imageUrl = _text(offer['imageUrl']);
    final expiryDate = _text(offer['expiryDate']);
    final category = _text(offer['category'], 'Offer');
    final redirectUrl = _text(offer['redirectUrl'], '/offers');

    return InkWell(
      borderRadius: BorderRadius.circular(21),
      //onTap: () => context.go(redirectUrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _offerPlaceholder(),
                    )
                  : _offerPlaceholder(),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(offer['title'], 'Untitled offer'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    style: const TextStyle(
                      color: purple,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _text(offer['description']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  if (expiryDate.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 13,
                          color: purple,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Valid until ${_formatDate(expiryDate)}',
                            style: const TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      color: const Color(0xFFECE4FF),
      child: const Icon(
        Icons.local_offer_outlined,
        color: purpleDark,
        size: 30,
      ),
    );
  }

  // COMMON SECTION HEADING
  Widget _sectionHeading(
    String title,
    String subtitle, {
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action,
              style: const TextStyle(
                color: purple,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _StoryListDialog extends StatefulWidget {
  final String memberName;
  final List<StoryModel> stories;
  final Future<void> Function(String storyId)? onViewStory;
  final Future<void> Function(String storyId)? onShowStoryViews;
  final Future<int> Function(String storyId)? onLoadViewCount;

  const _StoryListDialog({
    required this.memberName,
    required this.stories,
    this.onViewStory,
    this.onShowStoryViews,
    this.onLoadViewCount,
  });

  @override
  State<_StoryListDialog> createState() => _StoryListDialogState();
}

class _StoryListDialogState extends State<_StoryListDialog> {
  int index = 0;

  VideoPlayerController? _videoController;

  final Set<String> _recordedStoryIds = {};

  int _storyViewCount = 0;

  StoryModel get current => widget.stories[index];

  Future<void> _loadCurrentViewCount() async {
    final callback = widget.onLoadViewCount;

    if (callback == null) return;

    final storyId = current.id;

    try {
      final count = await callback(storyId);

      if (!mounted || current.id != storyId) return;

      setState(() {
        _storyViewCount = count;
      });
    } catch (e) {
      debugPrint('Unable to load story views: $e');
    }
  }

@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    _recordCurrentStoryView();
    _loadCurrentViewCount();
  });

  _loadVideo();
}

  Future<void> _recordCurrentStoryView() async {
    final callback = widget.onViewStory;
    if (callback == null) return;

    final storyId = current.id;
    if (!_recordedStoryIds.add(storyId)) return;

    try {
      await callback(storyId);
    } catch (_) {
      // Story viewing should continue even if view tracking fails.
    }
  }

  Future<void> _loadVideo() async {
    final oldController = _videoController;
    _videoController = null;
    await oldController?.dispose();

    if (!mounted ||
        current.mediaType != 'VIDEO' ||
        current.mediaUrl == null ||
        current.mediaUrl!.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(current.mediaUrl!),
    );
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      // An unavailable-media message is shown in the viewer.
    }

    if (mounted) setState(() {});
  }

Future<void> _next() async {
  if (index >= widget.stories.length - 1) {
    Navigator.pop(context);
    return;
  }

  setState(() {
    index++;
    _storyViewCount = 0;
  });

  _loadCurrentViewCount();
  await _recordCurrentStoryView();
  await _loadVideo();
}

Future<void> _previous() async {
  if (index == 0) return;

  setState(() {
    index--;
    _storyViewCount = 0;
  });

  _loadCurrentViewCount();
  await _recordCurrentStoryView();
  await _loadVideo();
}

@override
void dispose() {
  _videoController?.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return const SizedBox.shrink();

    final story = current;
    final videoReady = _videoController?.value.isInitialized == true;
    final videoFailed = _videoController?.value.hasError == true;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 420,
        height: 650,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (story.mediaType == 'TEXT')
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF26105C), Color(0xFF8060D5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    story.text ?? story.caption ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else if (story.mediaType == 'IMAGE' &&
                story.mediaUrl != null &&
                story.mediaUrl!.isNotEmpty)
              Image.network(
                story.mediaUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              )
            else if (story.mediaType == 'VIDEO')
              Center(
                child: videoReady
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : videoFailed
                    ? const Text(
                        'Unable to play this video.',
                        style: TextStyle(color: Colors.white),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
              )
            else
              const Center(
                child: Text(
                  'Story media is unavailable.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey(current.id),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(seconds: 15),
                    onEnd: () {
                      if (mounted) {
                        _next();
                      }
                    },
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: Colors.white30,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.memberName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Story caption
            // Story caption
            if (story.caption != null && story.caption!.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 65,
                child: Text(
                  story.caption!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
              ),

            // Story views
            if (widget.onShowStoryViews != null)
              Positioned(
                left: 16,
                bottom: 16,
                child: InkWell(
                  onTap: () {
                    widget.onShowStoryViews?.call(current.id);
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_storyViewCount views',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Previous / next story navigation
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _previous,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _next,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Activity chart painter
class _ActivityChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color purple;
  final Color gridColor;
  final Color textColor;

  _ActivityChartPainter({
    required this.values,
    required this.labels,
    required this.purple,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const left = 25.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 25.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final maxValue = values.fold<double>(0, (m, v) => v > m ? v : m) <= 0
        ? 1.0
        : values.fold<double>(0, (m, v) => v > m ? v : m);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i <= 4; i++) {
      final y = top + chartHeight * i / 4;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${(maxValue - (maxValue * i / 4)).round()}',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(0, y - 5));
    }

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * i / (values.length - 1);
      final y = top + chartHeight * (1 - values[i] / maxValue);

      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, top + chartHeight)
      ..lineTo(points.first.dx, top + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          purple.withValues(alpha: 0.22),
          purple.withValues(alpha: 0.01),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = purple
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = purple;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, dotPaint);
      canvas.drawCircle(points[i], 2, Paint()..color = Colors.white);

      final labelPainter = TextPainter(
        text: TextSpan(text: labels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(points[i].dx - labelPainter.width / 2, size.height - 17),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.purple != purple;
  }
}
