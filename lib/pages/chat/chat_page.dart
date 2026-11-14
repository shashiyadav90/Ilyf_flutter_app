import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../data/repositories/inquiry_chat_repository.dart';
import '../chat/ilo_mascot.dart';
import '../../main.dart';

const Color _ink = Color(0xFF211C45);
const Color _inkSecondary = Color(0xFF6A6685);
const Color _violet = Color(0xFF7248E0);
const Color _tile = Color(0xFFF1EBFF);
const Color _line = Color(0xFFE7E1FA);
const Color _rose = Color(0xFFE8447F);
const Color _blue = Color(0xFF3B63E8);
const Color _green = Color(0xFF17935F);

const LinearGradient _buttonGradient = LinearGradient(
  colors: [Color(0xFF8C5BF0), Color(0xFF5B3FD8), Color(0xFF4B40CF)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const LinearGradient _bubbleGradient = LinearGradient(
  colors: [Color(0xFF8C5BF0), Color(0xFF5B3FD8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient _pageGradient = LinearGradient(
  colors: [Color(0xFFEDE6FF), Color(0xFFF7F4FF), Color(0xFFFFFFFF)],
  stops: [0, 0.55, 1],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class _Starter {
  const _Starter({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const List<_Starter> _starters = [
  _Starter(
    icon: Icons.build_rounded,
    title: 'Find a reliable plumber nearby',
    subtitle: 'Home repairs & maintenance',
  ),
  _Starter(
    icon: Icons.calculate_outlined,
    title: 'I need help with my taxes',
    subtitle: 'Accountants & financial advice',
  ),
  _Starter(
    icon: Icons.weekend_outlined,
    title: 'Help me redesign my living room',
    subtitle: 'Interior designers & home styling',
  ),
];

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final InquiryChatRepository _repository = InquiryChatRepository();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  Map<String, dynamic>? _inquiry;
  List<dynamic> _answerChips = [];

  bool _begun = false;
  bool _loading = false;
  String _input = '';

  bool get _started => _messages.isNotEmpty;

  String? get _inquiryId {
    final value = _inquiry?['id'] ?? _inquiry?['inquiryId'];
    if (value == null || value.toString().isEmpty) return null;
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _inputFocus.removeListener(_onFocusChange);
    _inputController.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send([String? value]) async {
    final query = (value ?? _inputController.text).trim();

    if (query.isEmpty || _loading) return;

    final previousInquiryId = _inquiryId;

    setState(() {
      _input = '';
      _inputController.clear();
      _answerChips = [];
      _messages.add(_ChatMessage(role: 'user', text: query));
      _loading = true;
    });

    _scrollToBottom();

    try {
      final result = await _repository.searchBusinesses(
        message: query,
        inquiryId: previousInquiryId,
      );

      if (!mounted) return;

      final inquiryData = result['inquiry'];
      final inquiry = inquiryData is Map
          ? Map<String, dynamic>.from(inquiryData)
          : null;

      final status = inquiry?['status']?.toString().toLowerCase();
      final clarification = inquiry?['clarification'];
      final isClarifying =
          clarification != null &&
          clarification != false &&
          clarification.toString().trim().isNotEmpty;

      final isConfirming = status == 'confirming';
      final isReady = status == 'ready';

      final suggestionsData = result['suggestions'];
      final suggestions =
          (isConfirming || isClarifying) && suggestionsData is List
          ? suggestionsData
          : <dynamic>[];

      final matchesData = result['matches'];
      final matches = isReady && matchesData is List
          ? matchesData
          : <dynamic>[];

      setState(() {
        _inquiry = inquiry;
        _answerChips = suggestions;

        _messages.add(
          _ChatMessage(
            role: 'assistant',
            text:
                result['reply']?.toString() ??
                'I received a response from the enquiry service.',
            matches: List<dynamic>.from(matches),
            ready: isReady,
          ),
        );

        _loading = false;
      });

      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            text: error.toString().replaceFirst('Exception: ', ''),
            isError: true,
          ),
        );
      });

      _scrollToBottom();
    }
  }

  void _resetChat() {
    setState(() {
      _begun = true;
      _messages.clear();
      _inquiry = null;
      _answerChips = [];
      _loading = false;
      _input = '';
      _inputController.clear();
    });

    _inputFocus.unfocus();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$feature is coming soon.'),
        ),
      );
  }

  void _openMenu(BuildContext scaffoldContext) {
    final scaffold = Scaffold.maybeOf(scaffoldContext);
    if (scaffold != null && scaffold.hasDrawer) {
      scaffold.openDrawer();
      return;
    }
    if (scaffoldContext.canPop()) scaffoldContext.pop();
  }

  String _displayValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _inquiryService() {
    return _displayValue(
      _inquiry?['service'] ??
          _inquiry?['serviceType'] ??
          _inquiry?['category'] ??
          _inquiry?['query'],
      fallback: 'Your requested service',
    );
  }

  String _inquiryCity() {
    return _displayValue(
      _inquiry?['city'] ?? _inquiry?['location'] ?? _inquiry?['place'],
      fallback: 'Not specified',
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLanding = !_begun && !_started;

    return Scaffold(
      backgroundColor: const Color(0xFFEDE6FF),
      resizeToAvoidBottomInset: true,
      appBar: const AppHeader(),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNav(isStaff: authService.isStaff)
          : null,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: _pageGradient),
        child: SafeArea(
          bottom: !widget.showBottomNav,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: showLanding
                          ? KeyedSubtree(
                              key: const ValueKey('landing'),
                              child: _buildLanding(),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('chat'),
                              child: _buildChatShell(),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLanding() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        // WEB LAYOUT
        if (isWeb) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(520, constraints.maxHeight - 42),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT SIDE: BRAND AND LET'S BEGIN
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 45),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBrand(),
                          const SizedBox(height: 45),
                          _buildConciergeCard(),
                          const SizedBox(height: 20),
                          _footerNote(
                            icon: Icons.people_outline_rounded,
                            text: 'Real people. Meaningful connections.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT SIDE: WELCOME AND ANIMATED AI
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const IloMascot(size: 190, mood: IloMood.greet),
                        const SizedBox(height: 28),
                        const Text(
                          'Hi, welcome to ILYF',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ink,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.9,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Find trusted professionals in your community. '
                            'A little conversation. The right connection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _inkSecondary,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // MOBILE / TABLET LAYOUT: KEEP VERTICAL DESIGN
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 34),
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _buildBrand(),
                  const Spacer(flex: 2),
                  IloMascot(
                    size: MediaQuery.sizeOf(context).width < 600 ? 140 : 180,
                    mood: IloMood.greet,
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Hi, welcome to ILYF',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 33,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Find trusted professionals in your community. '
                      'A little conversation. The right connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _inkSecondary,
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  _buildConciergeCard(),
                  const SizedBox(height: 18),
                  _footerNote(
                    icon: Icons.people_outline_rounded,
                    text: 'Real people. Meaningful connections.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: _buttonGradient,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 17,
          ),
        ),
        const SizedBox(width: 9),
        RichText(
          text: const TextSpan(
            style: TextStyle(color: _ink, fontSize: 16),
            children: [
              TextSpan(
                text: 'ILYF',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text: ' Connect',
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConciergeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.09),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: _violet),
              SizedBox(width: 7),
              Text(
                'YOUR AI CONCIERGE',
                style: TextStyle(
                  color: _violet,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Good connections start here.',
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell me what you need. I’ll help you find the right people.',
            style: TextStyle(color: _inkSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 18),
          _GradientButton(
            label: 'Let’s begin',
            onTap: () => setState(() => _begun = true),
          ),
        ],
      ),
    );
  }

  Widget _footerNote({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: _inkSecondary),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: _inkSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildChatShell() {
    return Column(
      children: [
        Expanded(child: _started ? _buildConversation() : _buildStart()),
        _buildComposer(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (scaffoldContext) => _squareButton(
                  icon: Icons.menu_rounded,
                  tooltip: 'Menu',
                  onTap: () => _openMenu(scaffoldContext),
                ),
              ),
            ),
          ),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ILYF Connect',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your community, connected',
                  style: TextStyle(color: _inkSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loading ? null : _resetChat,
                icon: const Icon(Icons.edit_note_rounded, size: 19),
                label: const Text('New chat'),
                style: TextButton.styleFrom(
                  foregroundColor: _violet,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _squareButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: Icon(icon, size: 21, color: _ink),
          ),
        ),
      ),
    );
  }

  Widget _buildStart() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;

        // WEB LAYOUT
        if (isWeb) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 24, 40, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(450, constraints.maxHeight - 44),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT SIDE: HEADING AND SUGGESTION CARDS
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Who can I help you connect with?',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Share what you need. I’ll ask a few follow-up questions, '
                            'then find relevant people in your community to help.',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: _inkSecondary,
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'A PLACE TO START',
                                  style: TextStyle(
                                    color: _inkSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 15,
                                color: _violet,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._starters.map(_buildStarter),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT SIDE: ANIMATED AI
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: IloMascot(size: 190, mood: IloMood.idle),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // MOBILE / TABLET LAYOUT: KEEP EXISTING DESIGN
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
            4,
            MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
            16,
          ),
          child: Column(
            children: [
              const IloMascot(size: 100, mood: IloMood.idle),
              const SizedBox(height: 10),
              Text(
                'Who can I help you connect with?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: MediaQuery.sizeOf(context).width < 600 ? 25 : 32,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Share what you need. I’ll ask a few follow-up questions, '
                  'then find relevant people in your community to help.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _inkSecondary,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'A PLACE TO START',
                      style: TextStyle(
                        color: _inkSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Icon(Icons.auto_awesome_rounded, size: 15, color: _violet),
                ],
              ),
              const SizedBox(height: 12),
              ..._starters.map(_buildStarter),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarter(_Starter starter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: _loading ? null : () => _send(starter.title),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _line),
              boxShadow: [
                BoxShadow(
                  color: _violet.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _tile,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(starter.icon, color: _violet, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        starter.title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        starter.subtitle,
                        style: const TextStyle(
                          color: _inkSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.north_east_rounded,
                  size: 17,
                  color: _inkSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversation() {
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 600 ? 14 : 28,
        14,
        MediaQuery.sizeOf(context).width < 600 ? 14 : 28,
        18,
      ),
      children: [
        if (_inquiry != null) _buildInquirySummary(),
        ..._messages.map(_buildMessage),
        if (_answerChips.isNotEmpty) _buildAnswerChips(),
        if (_loading) _buildTypingIndicator(),
        if (!_loading && _messages.any((m) => m.ready))
          _buildNewEnquiryButton(),
      ],
    );
  }

  Widget _buildInquirySummary() {
    final status = _displayValue(_inquiry?['status'], fallback: 'in progress');

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _tile,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: _violet,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Your enquiry',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _violet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: _violet,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _summaryRow(
            Icons.work_outline_rounded,
            'Looking for',
            _inquiryService(),
          ),
          const SizedBox(height: 10),
          _summaryRow(Icons.location_on_outlined, 'Location', _inquiryCity()),
          if (_inquiry?['when'] != null) ...[
            const SizedBox(height: 10),
            _summaryRow(
              Icons.calendar_today_outlined,
              'When',
              _displayValue(_inquiry?['when']),
            ),
          ],
          if (_inquiry?['budget'] != null) ...[
            const SizedBox(height: 10),
            _summaryRow(
              Icons.account_balance_wallet_outlined,
              'Budget',
              _displayValue(_inquiry?['budget']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: _inkSecondary),
        const SizedBox(width: 9),
        SizedBox(
          width: MediaQuery.sizeOf(context).width < 400 ? 76 : 88,
          child: Text(
            label,
            style: const TextStyle(color: _inkSecondary, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(_ChatMessage message) {
    if (message.role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: math.min(MediaQuery.sizeOf(context).width * 0.78, 620),
          ),
          margin: EdgeInsets.only(
            bottom: 14,
            left: MediaQuery.sizeOf(context).width < 600 ? 20 : 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          decoration: BoxDecoration(
            gradient: _bubbleGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(21),
              topRight: Radius.circular(21),
              bottomLeft: Radius.circular(21),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: _violet.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IloAvatar(size: 32),
              const SizedBox(width: 8),
              const Text(
                'ILYF Connect',
                style: TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: message.isError ? _rose.withValues(alpha: 0.35) : _line,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: _violet.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isError ? _rose : _ink,
                    fontSize: 13.5,
                    height: 1.65,
                  ),
                ),
                if (message.ready) ...[
                  const SizedBox(height: 15),
                  _buildMemberResults(message),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose an answer',
            style: TextStyle(
              color: _inkSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _answerChips.map((value) {
              final label = value is Map
                  ? _displayValue(
                      value['label'] ?? value['text'] ?? value['value'],
                      fallback: value.toString(),
                    )
                  : value.toString();

              return ActionChip(
                onPressed: _loading ? null : () => _send(label),
                backgroundColor: Colors.white,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                label: Text(
                  label,
                  style: const TextStyle(
                    color: _violet,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IloMascot(size: 48, mood: IloMood.searching),
            SizedBox(width: 10),
            Text(
              'Finding the right people...',
              style: TextStyle(
                color: _inkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberResults(_ChatMessage message) {
    final members = message.matches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Matching members',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${members.length} found',
                style: const TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _tile,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.search_off_rounded, color: _violet, size: 21),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'No matching members were returned. Try a broader '
                    'service or a nearby city.',
                    style: TextStyle(
                      color: _inkSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...members.map((member) {
          if (member is! Map) return const SizedBox.shrink();

          final person = Map<String, dynamic>.from(member);
          return _buildMemberCard(person);
        }),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> person) {
    final name = _displayValue(
      person['name'] ?? person['businessName'] ?? person['title'],
      fallback: 'ILYF Member',
    );

    final role = _displayValue(
      person['role'] ??
          person['category'] ??
          person['service'] ??
          person['description'],
      fallback: 'Member',
    );

    final city = _displayValue(
      person['city'] ?? person['location'],
      fallback: 'Location not specified',
    );

    final id = _displayValue(person['id'] ?? person['_id'] ?? person['userId']);

    final verified = person['verified'] == true || person['isVerified'] == true;

    final ratingValue = person['rating'];
    final rating = ratingValue is num
        ? ratingValue.toStringAsFixed(1)
        : ratingValue?.toString();

    final reviewsValue = person['reviews'] ?? person['reviewCount'];

    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  gradient: _bubbleGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? 'M' : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (verified)
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: _blue,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _inkSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (rating != null) ...[
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF2A516),
                            size: 15,
                          ),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        if (reviewsValue != null)
                          Text(
                            '($reviewsValue reviews)',
                            style: const TextStyle(
                              color: _inkSecondary,
                              fontSize: 10,
                            ),
                          ),
                        const Icon(
                          Icons.location_on_outlined,
                          color: _rose,
                          size: 14,
                        ),
                        Text(
                          city,
                          style: const TextStyle(
                            color: _inkSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (id.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () {
                  context.push('/members/$id');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _violet,
                  side: const BorderSide(color: _line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'View member profile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewEnquiryButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 12),
      child: OutlinedButton.icon(
        onPressed: _resetChat,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Start a new enquiry'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _violet,
          backgroundColor: Colors.white,
          side: const BorderSide(color: _line),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final focused = _inputFocus.hasFocus;
    final canSend = _input.trim().isNotEmpty && !_loading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 600 ? 12 : 28,
        6,
        MediaQuery.sizeOf(context).width < 600 ? 12 : 28,
        10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: focused ? _violet : _line,
                width: focused ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _violet.withValues(alpha: 0.09),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _inputController,
                  focusNode: _inputFocus,
                  enabled: !_loading,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => setState(() => _input = value),
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Tell ILYF what you’re looking for…',
                    hintStyle: TextStyle(
                      color: Color(0xFF9A93B3),
                      fontSize: 14,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
                Row(
                  children: [
                    _composerIcon(
                      Icons.add_rounded,
                      'Attach',
                      () => _comingSoon('Attachments'),
                    ),
                    _composerIcon(
                      Icons.mic_none_rounded,
                      'Voice',
                      () => _comingSoon('Voice input'),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: canSend ? _buttonGradient : null,
                        color: canSend ? null : _violet.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canSend
                            ? [
                                BoxShadow(
                                  color: _violet.withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: IconButton(
                        onPressed: canSend ? _send : null,
                        tooltip: 'Send enquiry',
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'AI-guided discovery. Always a human connection.',
            style: TextStyle(color: _inkSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _composerIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 22, color: _inkSecondary),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: _buttonGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _violet.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.text,
    this.matches = const [],
    this.ready = false,
    this.isError = false,
  });

  final String role;
  final String text;
  final List<dynamic> matches;
  final bool ready;
  final bool isError;
}
