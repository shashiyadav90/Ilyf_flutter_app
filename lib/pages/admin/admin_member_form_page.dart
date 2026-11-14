import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';

class AdminMemberFormPage extends StatefulWidget {
  final String? id;
  final String? chapterId;

  const AdminMemberFormPage({super.key, this.id, this.chapterId});

  @override
  State<AdminMemberFormPage> createState() => _AdminMemberFormPageState();
}

class _AdminMemberFormPageState extends State<AdminMemberFormPage> {
  static const Color ink = Color(0xFF1A1433);
  static const Color muted = Color(0xFF5F5979);
  static const Color purple = Color(0xFF6C3FD1);
  static const Color purpleDark = Color(0xFF4B27A3);
  static const Color line = Color(0xFFE6DFF9);
  static const Color canvas = Color(0xFFF4EFFF);
  static const Color rose = Color(0xFFE8447F);

  static const String chaptersEndpoint = '/admin/chapters';
  static const String membersEndpoint = '/admin/users';

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _businessController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<Map<String, String>> _countries = [
    {'iso': 'IN', 'name': 'India', 'dial': '+91', 'max': '10'},
    {'iso': 'SG', 'name': 'Singapore', 'dial': '+65', 'max': '8'},
    {'iso': 'US', 'name': 'United States', 'dial': '+1', 'max': '10'},
    {'iso': 'GB', 'name': 'United Kingdom', 'dial': '+44', 'max': '10'},
    {'iso': 'AE', 'name': 'UAE', 'dial': '+971', 'max': '9'},
    {'iso': 'AU', 'name': 'Australia', 'dial': '+61', 'max': '9'},
    {'iso': 'CA', 'name': 'Canada', 'dial': '+1', 'max': '10'},
    {'iso': 'MY', 'name': 'Malaysia', 'dial': '+60', 'max': '10'},
    {'iso': 'LK', 'name': 'Sri Lanka', 'dial': '+94', 'max': '9'},
    {'iso': 'NP', 'name': 'Nepal', 'dial': '+977', 'max': '10'},
  ];

  List<Map<String, dynamic>> _chapters = [];

  String _role = 'member';
  String _membershipType = 'Annual';
  String _countryIso = 'IN';
  String _chapterId = '';

  DateTime _memberSince = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 365));

  bool _loading = true;
  bool _busy = false;
  bool _removing = false;
  bool _confirmRemove = false;

  String? _error;

  bool get _editing => widget.id != null && widget.id!.isNotEmpty;
  bool get _signedIn => authService.isLoggedIn;
  bool get _isRoot => authService.member?.isRoot ?? false;
  bool get _isStaff => authService.member?.isStaff ?? false;

  bool get _makingRoot => _role == 'root';

  bool get _ownRecord => _editing && widget.id == authService.member?.id;

  Map<String, String> get _country => _countries.firstWhere(
    (item) => item['iso'] == _countryIso,
    orElse: () => _countries.first,
  );

  String get _chapterName {
    final chapter = _chapters.where(
      (item) => item['id']?.toString() == _chapterId,
    );

    if (chapter.isNotEmpty) {
      return chapter.first['name']?.toString() ?? '';
    }

    return _chapters.isNotEmpty
        ? _chapters.first['name']?.toString() ?? ''
        : '';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_signedIn) {
        context.go('/login?next=/admin/members/new');
        return;
      }

      if (!_isStaff) return;

      _loadForm();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  DateTime _safeDate(DateTime date) {
    final nextYear = date.year + 1;
    final lastDay = DateTime(nextYear, date.month + 1, 0).day;

    return DateTime(
      nextYear,
      date.month,
      date.day > lastDay ? lastDay : date.day,
    );
  }

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;

    return DateTime.tryParse(
      value.toString().substring(
        0,
        value.toString().length >= 10 ? 10 : value.toString().length,
      ),
    );
  }

  dynamic _unwrap(dynamic response) {
    if (response is Map) {
      return response['data'] ?? response['user'] ?? response;
    }

    return response;
  }

  Future<void> _loadForm() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiConfig.dio.get<dynamic>(chaptersEndpoint);

      dynamic data = _unwrap(response.data);

      if (data is Map) {
        data = data['chapters'] ?? data['items'] ?? data['results'];
      }

      final loadedChapters = data is List
          ? data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      final currentMember = authService.member;

      final ownChapter = loadedChapters.where(
        (item) =>
            item['id']?.toString() == currentMember?.chapterId?.toString(),
      );

      final requestedChapter = loadedChapters.where(
        (item) =>
            item['id']?.toString() == widget.chapterId &&
            item['code'] != 'TRUST',
      );

      final defaultChapter = requestedChapter.isNotEmpty
          ? requestedChapter.first['id']?.toString() ?? ''
          : ownChapter.isNotEmpty && ownChapter.first['code'] != 'TRUST'
          ? ownChapter.first['id']?.toString() ?? ''
          : loadedChapters
                    .where((item) => item['code'] != 'TRUST')
                    .firstOrNull?['id']
                    ?.toString() ??
                '';

      if (_editing) {
        final userResponse = await ApiConfig.dio.get<dynamic>(
          '$membersEndpoint/${Uri.encodeComponent(widget.id!)}',
        );

        final user = _unwrap(userResponse.data);

        if (user is! Map) {
          throw Exception('Invalid member response.');
        }

        final phone = user['phone']?.toString() ?? '';

        final digits = phone.replaceAll(RegExp(r'\D'), '');

        final membershipType = user['membershipType']?.toString() ?? 'Annual';

        final startDate = _parseDate(user['memberSince']) ?? DateTime.now();

        final endDate =
            _parseDate(user['validUntil']) ??
            (membershipType == 'Annual' ? _safeDate(startDate) : startDate);

        final chapter = user['chapter'];

        _nameController.text = user['fullName']?.toString() ?? '';
        _businessController.text = user['businessName']?.toString() ?? '';
        _emailController.text = user['email']?.toString() ?? '';

        // This conversion assumes the stored number has the
        // country dial code followed by the national number.
        _phoneController.text = digits.length >= 10
            ? digits.substring(digits.length - 10)
            : digits;

        _role = _roleFromKind(user['kind']);
        _membershipType = membershipType;

        _chapterId = chapter is Map
            ? chapter['id']?.toString() ?? defaultChapter
            : defaultChapter;

        _memberSince = startDate;
        _validUntil = endDate;
      } else {
        _chapterId = defaultChapter;
      }

      if (!mounted) return;

      setState(() {
        _chapters = loadedChapters;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.response?.data is Map
            ? e.response?.data['message']?.toString() ??
                  e.message ??
                  'Could not load the form.'
            : e.message ?? 'Could not load the form.';

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _roleFromKind(dynamic kind) {
    if (kind == 'root') return 'root';
    if (kind == 'admin') return 'admin';
    return 'member';
  }

  void _setRole(String? value) {
    if (value == null) return;

    setState(() {
      _role = value;
      _error = null;
    });
  }

  void _setMembership(String? value) {
    if (value == null) return;

    setState(() {
      _membershipType = value;

      if (value == 'Annual') {
        _validUntil = _safeDate(_memberSince);
      }

      _error = null;
    });
  }

  Future<void> _selectDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _memberSince : _validUntil,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: purple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (start) {
        _memberSince = selected;

        if (_membershipType == 'Annual') {
          _validUntil = _safeDate(selected);
        } else if (_validUntil.isBefore(selected)) {
          _validUntil = selected;
        }
      } else {
        _validUntil = selected;
      }
    });
  }

  String _phoneNumber() {
    final dial = _country['dial'] ?? '+91';
    final number = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    return '$dial$number';
  }

  String? _validatePhone() {
    final number = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    final max = int.tryParse(_country['max'] ?? '10') ?? 10;

    if (number.isEmpty) return 'Enter a mobile number.';

    if (number.length != max) {
      return 'Enter a valid ${_country['name']} mobile number.';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_makingRoot && _isRoot && _chapterId.isEmpty) {
      setState(() => _error = 'Choose a chapter.');
      return;
    }

    final phoneError = _validatePhone();

    if (phoneError != null) {
      setState(() => _error = phoneError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'fullName': _nameController.text.trim(),
      'phone': _phoneNumber(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'role': _isRoot ? _role : 'member',
      'chapterId': _makingRoot ? null : _chapterId,
      'membershipType': _makingRoot ? null : _membershipType,
      'businessName': _makingRoot ? null : _businessController.text.trim(),
      'memberSince': _makingRoot || _membershipType != 'Annual'
          ? null
          : _dateString(_memberSince),
      'validUntil': _makingRoot || _membershipType != 'Annual'
          ? null
          : _dateString(_validUntil),
    };

    try {
      if (_editing) {
        await ApiConfig.dio.patch(
          '$membersEndpoint/${Uri.encodeComponent(widget.id!)}',
          data: body,
        );
      } else {
        await ApiConfig.dio.post(membersEndpoint, data: body);
      }

      if (!mounted) return;

      _goToMembers();
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.response?.data is Map
            ? e.response?.data['message']?.toString() ??
                  e.message ??
                  'Could not save the member.'
            : e.message ?? 'Could not save the member.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _removing = true);

    try {
      await ApiConfig.dio.delete(
        '$membersEndpoint/${Uri.encodeComponent(widget.id!)}',
      );

      if (!mounted) return;

      _goToMembers();
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.response?.data is Map
            ? e.response?.data['message']?.toString() ??
                  'Could not remove the member.'
            : 'Could not remove the member.';

        _confirmRemove = false;
      });
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  void _goToMembers() {
    final chapter = _chapters.where(
      (item) => item['id']?.toString() == _chapterId,
    );

    final name = chapter.isNotEmpty
        ? chapter.first['name']?.toString() ?? ''
        : '';

    if (name.isNotEmpty) {
      context.go(
        Uri(path: '/members', queryParameters: {'chapter': name}).toString(),
      );
    } else {
      context.go('/members');
    }
  }

  void _showRemoveDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Remove member',
                style: TextStyle(color: ink, fontWeight: FontWeight.w800),
              ),
              content: Text(
                'Remove ${_nameController.text.isEmpty ? 'this member' : _nameController.text}? They will no longer be able to sign in.',
                style: const TextStyle(color: muted),
              ),
              actions: [
                TextButton(
                  onPressed: _removing
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _removing
                      ? null
                      : () async {
                          setDialogState(() {});
                          await _remove();

                          if (mounted && !_removing) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: rose),
                  child: _removing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Remove'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: ink, fontSize: 14),
          decoration: _decoration(hint),
        ),
      ],
    );
  }

  Widget _label(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: rose),
            ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFA49BB8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFFCFBFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: purple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: rose),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          decoration: _decoration('Select $label'),
          style: const TextStyle(color: ink, fontSize: 13),
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: true),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _decoration(null),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: purple,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _dateString(date),
                    style: const TextStyle(color: ink, fontSize: 13),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: muted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneField() {
    final country = _country;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Mobile number', required: true),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 155,
              child: DropdownButtonFormField<String>(
                value: _countryIso,
                isExpanded: true,
                decoration: _decoration(null),
                items: _countries.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['iso'],
                    child: Text(
                      '${item['iso']} ${item['dial']}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _countryIso = value;
                    _phoneController.clear();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: int.tryParse(country['max'] ?? '10') ?? 10,
                validator: (_) => _validatePhone(),
                style: const TextStyle(color: ink, fontSize: 14),
                decoration: _decoration(
                  'Mobile number',
                ).copyWith(counterText: ''),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _formPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x164B27A3),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: purple,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editing ? 'Edit member' : 'Add member',
                        style: const TextStyle(
                          color: ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter membership and contact information.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            const Divider(color: line),
            const SizedBox(height: 22),

            const Text(
              'MEMBER INFORMATION',
              style: TextStyle(
                color: purpleDark,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 18),

            LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 650;
                final width = desktop
                    ? (constraints.maxWidth - 20) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    if (_isRoot)
                      SizedBox(
                        width: width,
                        child: _dropdown(
                          label: 'Member type',
                          value: _role,
                          required: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'member',
                              child: Text('Member'),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Chapter Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'root',
                              child: Text('Root User'),
                            ),
                          ],
                          onChanged: _setRole,
                        ),
                      ),

                    SizedBox(
                      width: width,
                      child: _field(
                        label: 'Person managing the business',
                        controller: _nameController,
                        hint: 'Full name',
                        required: true,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter the full name.'
                            : null,
                      ),
                    ),

                    if (!_makingRoot) ...[
                      SizedBox(
                        width: width,
                        child: _field(
                          label: 'Business name',
                          controller: _businessController,
                          hint: 'Studio or company name',
                          required: true,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter the business name.'
                              : null,
                        ),
                      ),

                      SizedBox(
                        width: width,
                        child: _dropdown(
                          label: 'Membership',
                          value: _membershipType,
                          required: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'Annual',
                              child: Text('Annual'),
                            ),
                            DropdownMenuItem(
                              value: 'Patron',
                              child: Text('Patron'),
                            ),
                          ],
                          onChanged: _setMembership,
                        ),
                      ),

                      if (_membershipType == 'Annual') ...[
                        SizedBox(
                          width: width,
                          child: _dateField(
                            label: 'Start date',
                            date: _memberSince,
                            onTap: () => _selectDate(start: true),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _dateField(
                            label: 'End date',
                            date: _validUntil,
                            onTap: () => _selectDate(start: false),
                          ),
                        ),
                      ],

                      if (_isRoot)
                        SizedBox(
                          width: width,
                          child: _dropdown(
                            label: 'Chapter',
                            value: _chapterId,
                            required: true,
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Choose a chapter'),
                              ),
                              ..._chapters
                                  .where(
                                    (chapter) => chapter['code'] != 'TRUST',
                                  )
                                  .map(
                                    (chapter) => DropdownMenuItem<String>(
                                      value: chapter['id'].toString(),
                                      child: Text(
                                        chapter['name']?.toString() ?? '',
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _chapterId = value ?? '';
                              });
                            },
                          ),
                        ),
                    ],

                    SizedBox(
                      width: width,
                      child: _field(
                        label: 'Email (optional)',
                        controller: _emailController,
                        hint: 'name@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }

                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email address.';
                          }

                          return null;
                        },
                      ),
                    ),

                    SizedBox(width: width, child: _phoneField()),
                  ],
                );
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF4C7D7)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: rose,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
            const Divider(color: line),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 500;

                final saveButton = SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _editing ? 'Save Changes' : 'Add Member',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );

                final canRemove = _editing && !_ownRecord;

                final removeButton = OutlinedButton.icon(
                  onPressed: _removing ? null : _showRemoveDialog,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Member'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: rose,
                    side: const BorderSide(color: Color(0xFFF4C7D7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                  ),
                );

                if (!desktop) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      saveButton,
                      if (canRemove) ...[
                        const SizedBox(height: 12),
                        removeButton,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    if (canRemove) removeButton,
                    const Spacer(),
                    SizedBox(width: 190, child: saveButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/members'),
          icon: const Icon(Icons.arrow_back, size: 17),
          label: const Text('Back to members'),
          style: TextButton.styleFrom(
            foregroundColor: purple,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _editing
              ? 'Edit member'
              : (!_isRoot && _chapterName.isNotEmpty
                    ? 'Add $_chapterName Member'
                    : 'Add member'),
          style: const TextStyle(
            color: ink,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Manage member details, membership and access.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
      ],
    );
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 40 : 16,
                vertical: 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heading(),
                      const SizedBox(height: 25),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(70),
                            child: CircularProgressIndicator(color: purple),
                          ),
                        )
                      else
                        _formPanel(),
                      const SizedBox(height: 35),
                      const Center(
                        child: Text(
                          'ILYF Connect • Administration Portal',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNav(isStaff: true),
    );
  }
}
