import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';

import '../../data/repositories/inquiry_chat_repository.dart';

const Color _ink = Color(0xFF1A1433);
const Color _inkSecondary = Color(0xFF625B7B);
const Color _violet = Color(0xFF6C3FD1);
const Color _violetDark = Color(0xFF2A1466);
const Color _mist = Color(0xFFF6F3FF);
const Color _line = Color(0xFFE6DFF9);
const Color _rose = Color(0xFFE8447F);
const Color _blue = Color(0xFF3B63E8);
const Color _green = Color(0xFF17935F);

const LinearGradient _brandGradient = LinearGradient(
  colors: [Color(0xFF7B4DE0), Color(0xFF5A34C6), Color(0xFF3B63E8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const List<Map<String, String>> _categories = [
  {'icon': '📸', 'label': 'Photographer'},
  {'icon': '🔧', 'label': 'Plumber'},
  {'icon': '🍽️', 'label': 'Catering'},
  {'icon': '⚖️', 'label': 'Lawyer'},
  {'icon': '🎨', 'label': 'Designer'},
  {'icon': '📚', 'label': 'Tutor'},
];

const List<Map<String, String>> _examples = [
  {'service': 'Photographer', 'city': 'Mumbai'},
  {'service': 'Plumber', 'city': 'Delhi'},
  {'service': 'Catering', 'city': 'Bengaluru'},
];

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

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

  bool _loading = false;
  String _input = '';

  bool get _started => _messages.isNotEmpty;

  String? get _inquiryId {
    final value = _inquiry?['id'] ?? _inquiry?['inquiryId'];
    if (value == null || value.toString().isEmpty) return null;
    return value.toString();
  }

  int get _step {
    if (_messages.any((m) => m.ready)) return 2;

    final status = _inquiry?['status']?.toString().toLowerCase();
    if (status == 'ready') return 2;
    if (status == 'confirming' || _answerChips.isNotEmpty) return 1;

    return _started ? 1 : 0;
  }

  @override
  void dispose() {
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
      // POST /api/chat/search
      // { message: query, inquiryId?: previousInquiryId }
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
      _messages.clear();
      _inquiry = null;
      _answerChips = [];
      _loading = false;
      _input = '';
      _inputController.clear();
    });

    _inputFocus.requestFocus();
  }

  void _selectCategory(String label) {
    final value = '$label in ';
    setState(() {
      _input = value;
      _inputController.text = value;
      _inputController.selection = TextSelection.collapsed(
        offset: value.length,
      );
    });
    _inputFocus.requestFocus();
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
    return Scaffold(
      backgroundColor: _mist,
      appBar: const AppHeader(),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _buildHero(),
                Expanded(
                  child: _started ? _buildConversation() : _buildWelcome(),
                ),
                _buildComposer(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(isStaff: false),
    );
  }

  Widget _buildHero() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.fromLTRB(
        22,
        _started ? 15 : 24,
        22,
        _started ? 16 : 21,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [_violetDark, Color(0xFF4A25A8), Color(0xFF3B3FC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -45,
            child: IgnorePointer(
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rose.withValues(alpha: 0.17),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_started) ...[
                const Text(
                  'What do you need?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Describe it in one line. We’ll confirm the details, '
                  'then find members who can help.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.55,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 21),
              ],
              Row(
                children: [
                  _buildProgressStep('Describe', 0),
                  _buildProgressLine(0),
                  _buildProgressStep('Confirm', 1),
                  _buildProgressLine(1),
                  _buildProgressStep('Matches', 2),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String label, int index) {
    final completed = index < _step;
    final current = index == _step;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed || current
                ? Colors.white
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: completed || current
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
            boxShadow: current
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.20),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check_rounded, size: 16, color: _violetDark)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: current ? _violetDark : Colors.white70,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: completed || current
                ? Colors.white
                : Colors.white.withValues(alpha: 0.60),
            fontSize: 12,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(int index) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 9),
        height: 2,
        decoration: BoxDecoration(
          color: index < _step
              ? Colors.white
              : Colors.white.withValues(alpha: 0.23),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 420 ? 17.0 : 23.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Browse by service',
                style: TextStyle(
                  fontSize: 16,
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 111,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 11),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategory(category);
                  },
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Or try an example',
                      style: TextStyle(
                        fontSize: 16,
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.bolt_rounded,
                    color: _violet.withValues(alpha: 0.8),
                    size: 19,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Quick start',
                    style: TextStyle(
                      color: _inkSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ..._examples.map(_buildExample),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      color: _violet,
                      size: 21,
                    ),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Tip: mention the service and city to help us '
                        'find relevant members.',
                        style: TextStyle(
                          color: _inkSecondary,
                          fontSize: 12,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategory(Map<String, String> category) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _selectCategory(category['label']!),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: _line),
                boxShadow: [
                  BoxShadow(
                    color: _violet.withValues(alpha: 0.07),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  category['icon']!,
                  style: const TextStyle(fontSize: 27),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              category['label']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(Map<String, String> example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => _send('${example['service']} in ${example['city']}'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: _mist,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: _violet,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example['service']!,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: _rose,
                            size: 15,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            example['city']!,
                            style: const TextStyle(
                              color: _inkSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: _violet,
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
      padding: const EdgeInsets.fromLTRB(17, 22, 17, 22),
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
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.05),
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
                  color: _mist,
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
                  color: _violet.withValues(alpha: 0.09),
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
          width: 88,
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
          constraints: const BoxConstraints(maxWidth: 330),
          margin: const EdgeInsets.only(bottom: 14, left: 38),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          decoration: BoxDecoration(
            gradient: _brandGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(21),
              topRight: Radius.circular(21),
              bottomLeft: Radius.circular(21),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: _violet.withValues(alpha: 0.17),
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
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ILYF Assistant',
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isError ? _rose : _ink,
                    fontSize: 13,
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
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
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
                    fontSize: 12,
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
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: _violet),
            ),
            SizedBox(width: 11),
            Text(
              'Finding the right information...',
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
              color: _mist,
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
                  gradient: _brandGradient,
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
                            fontSize: 13,
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
              height: 39,
              child: OutlinedButton(
                onPressed: () {
                  context.push('/members/$id');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _violet,
                  side: const BorderSide(color: _line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
          side: const BorderSide(color: _line),
          minimumSize: const Size(double.infinity, 47),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 13),
      decoration: BoxDecoration(
        color: _mist,
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 17, right: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _inputFocus.hasFocus ? _violet : _line,
            width: _inputFocus.hasFocus ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _violet.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 19,
              color: _inkSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                enabled: !_loading,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => setState(() => _input = value),
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Describe what you need...',
                  hintStyle: TextStyle(color: Color(0xFF9A93B3), fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                style: const TextStyle(color: _ink, fontSize: 14, height: 1.4),
              ),
            ),
            const SizedBox(width: 7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: _input.trim().isNotEmpty && !_loading
                    ? _brandGradient
                    : LinearGradient(
                        colors: [
                          _violet.withValues(alpha: 0.35),
                          _blue.withValues(alpha: 0.35),
                        ],
                      ),
                shape: BoxShape.circle,
                boxShadow: _input.trim().isNotEmpty && !_loading
                    ? [
                        BoxShadow(
                          color: _violet.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                onPressed: _input.trim().isNotEmpty && !_loading ? _send : null,
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
