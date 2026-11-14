import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';

class AdminNewsFormPage extends StatefulWidget {
  final String? id;

  const AdminNewsFormPage({super.key, this.id});

  @override
  State<AdminNewsFormPage> createState() => _AdminNewsFormPageState();
}

class _AdminNewsFormPageState extends State<AdminNewsFormPage> {
  static const Color ink = Color(0xFF1A1433);
  static const Color muted = Color(0xFF5F5979);
  static const Color purple = Color(0xFF6C3FD1);
  static const Color purpleDark = Color(0xFF4B27A3);
  static const Color line = Color(0xFFE6DFF9);
  static const Color canvas = Color(0xFFF4EFFF);
  static const Color rose = Color(0xFFE8447F);

  // Verify these endpoints against your React api.js.
  static const String myNewsEndpoint = '/me/news';
  static const String newsEndpoint = '/me/news';

  // Replace with the actual MEDIA_LIMITS.image size.
  static const int maxBannerBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _kind = 'NEWS';

  DateTime? _startDate;
  DateTime? _endDate;

  XFile? _banner;
  Uint8List? _bannerBytes;
  String _previewUrl = '';

  bool _loading = false;
  bool _busy = false;

  String? _error;
  String? _success;

  bool get _editing => widget.id != null && widget.id!.isNotEmpty;
  bool get _signedIn => authService.isLoggedIn;
  bool get _isStaff => authService.member?.isStaff ?? false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_signedIn) {
        context.go('/login?next=/events');
        return;
      }

      if (!_isStaff) return;

      if (_editing) {
        _loadNews();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    final text = value.toString();

    return DateTime.tryParse(text.length >= 10 ? text.substring(0, 10) : text);
  }

  dynamic _unwrap(dynamic response) {
    if (response is Map) {
      return response['data'] ?? response['news'] ?? response;
    }

    return response;
  }

  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiConfig.dio.get<dynamic>(myNewsEndpoint);

      dynamic data = _unwrap(response.data);

      if (data is Map) {
        data = data['items'] ?? data['results'] ?? data['news'];
      }

      if (data is! List) {
        throw Exception('Invalid news response.');
      }

      final rows = data.whereType<Map>().toList();

      final matching = rows.where(
        (item) => item['id']?.toString() == widget.id,
      );

      if (matching.isEmpty) {
        throw Exception('That news item was not found.');
      }

      final item = matching.first;

      _kind = item['kind'] == 'ANNOUNCEMENT' ? 'ANNOUNCEMENT' : 'NEWS';

      _titleController.text = item['title']?.toString() ?? '';

      _descriptionController.text = item['description']?.toString() ?? '';

      _startDate = _parseDate(item['startDate']);
      _endDate = _parseDate(item['endDate']);

      _previewUrl = item['bannerUrl']?.toString() ?? '';

      if (!mounted) return;

      setState(() {});
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.response?.data is Map
            ? e.response?.data['message']?.toString() ??
                  e.message ??
                  'Could not load that news item.'
            : e.message ?? 'Could not load that news item.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickBanner() async {
    if (_busy) return;

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (file == null) return;

      final size = await file.length();

      if (size > maxBannerBytes) {
        setState(() {
          _error = 'Banner image is too large. Maximum allowed size is 5 MB.';
        });
        return;
      }

      final name = file.name.toLowerCase();

      final valid =
          name.endsWith('.jpg') ||
          name.endsWith('.jpeg') ||
          name.endsWith('.png') ||
          name.endsWith('.webp') ||
          name.endsWith('.gif');

      if (!valid) {
        setState(() {
          _error = 'Select a JPG, PNG, WebP or GIF image.';
        });
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        _banner = file;
        _bannerBytes = bytes;
        _previewUrl = '';
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not select the banner image.';
      });
    }
  }

  Future<void> _selectDate({required bool start}) async {
    final now = DateTime.now();

    final initial = start ? _startDate ?? now : _endDate ?? _startDate ?? now;

    final firstDate = !start && _startDate != null
        ? _startDate!
        : DateTime(2000);

    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
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
        _startDate = selected;

        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }

      _error = null;
    });
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) {
      return 'Add a title for this news item.';
    }

    if (_startDate != null &&
        _endDate != null &&
        _startDate!.isAfter(_endDate!)) {
      return 'The end date cannot be before the start date.';
    }

    return null;
  }

  Future<void> _saveNews() async {
    if (!_formKey.currentState!.validate()) return;

    final validationError = _validate();

    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    try {
      final formData = FormData.fromMap({
        'kind': _kind,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': _startDate == null ? '' : _dateString(_startDate!),
        'endDate': _endDate == null ? '' : _dateString(_endDate!),
        if (_banner != null && _bannerBytes != null)
          'banner': MultipartFile.fromBytes(
            _bannerBytes!,
            filename: _banner!.name,
          ),
      });

      if (_editing) {
        await ApiConfig.dio.patch(
          '$newsEndpoint/${Uri.encodeComponent(widget.id!)}',
          data: formData,
        );
      } else {
        await ApiConfig.dio.post(newsEndpoint, data: formData);
      }

      if (!mounted) return;

      _success = _editing ? 'News updated.' : 'News added.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_success!),
          backgroundColor: const Color(0xFF159B70),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.go('/events?tab=news');
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.response?.data is Map
            ? e.response?.data['message']?.toString() ??
                  e.message ??
                  'Could not save that news item.'
            : e.message ?? 'Could not save that news item.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  InputDecoration _decoration(String hint) {
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
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: rose),
            ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: const TextStyle(color: ink, fontSize: 14),
          decoration: _decoration(hint),
        ),
      ],
    );
  }

  Widget _dropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Type'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _kind,
          isExpanded: true,
          decoration: _decoration('Select type'),
          style: const TextStyle(color: ink, fontSize: 13),
          items: const [
            DropdownMenuItem(value: 'NEWS', child: Text('News')),
            DropdownMenuItem(
              value: 'ANNOUNCEMENT',
              child: Text('Announcement'),
            ),
          ],
          onChanged: _busy
              ? null
              : (value) {
                  if (value == null) return;

                  setState(() {
                    _kind = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required bool start,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(start: start),
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _decoration('Select date'),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: purple,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    date == null ? 'Select date' : _dateString(date),
                    style: TextStyle(
                      color: date == null ? muted : ink,
                      fontSize: 13,
                    ),
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

  Widget _bannerPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFECE5FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            color: purple,
            size: 30,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Add a banner',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Click to browse images',
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _bannerPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('News banner'),
        const SizedBox(height: 9),
        InkWell(
          onTap: _pickBanner,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            height: 220,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFCFBFF),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: line),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_bannerBytes != null)
                  Image.memory(_bannerBytes!, fit: BoxFit.cover)
                else if (_previewUrl.isNotEmpty)
                  Image.network(
                    _previewUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _bannerPlaceholder(),
                  )
                else
                  _bannerPlaceholder(),

                if (_bannerBytes != null || _previewUrl.isNotEmpty)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 10),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined, color: purple, size: 16),
                          SizedBox(width: 7),
                          Text(
                            'Change banner',
                            style: TextStyle(
                              color: purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Optional · Maximum 5 MB · JPG, PNG, WebP or GIF',
          style: TextStyle(color: muted, fontSize: 11),
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
                  child: const Icon(Icons.article_outlined, color: purple),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'News information',
                        style: TextStyle(
                          color: ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Publish news and announcements for your members.',
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
              'NEWS DETAILS',
              style: TextStyle(
                color: purpleDark,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 18),
            _bannerPicker(),
            const SizedBox(height: 24),

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
                    SizedBox(width: width, child: _dropdown()),

                    SizedBox(
                      width: width,
                      child: _textField(
                        label: 'Title',
                        controller: _titleController,
                        hint: 'Chapter meetup this Sunday',
                        required: true,
                        maxLength: 120,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Add a title for this news item.';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(
                      width: width,
                      child: _dateField(
                        label: 'Start date',
                        date: _startDate,
                        start: true,
                      ),
                    ),

                    SizedBox(
                      width: width,
                      child: _dateField(
                        label: 'End date',
                        date: _endDate,
                        start: false,
                      ),
                    ),

                    SizedBox(
                      width: constraints.maxWidth,
                      child: _textField(
                        label: 'Details',
                        controller: _descriptionController,
                        hint: 'Share the news or announcement...',
                        maxLines: 5,
                        maxLength: 2000,
                      ),
                    ),
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
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: rose, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: rose,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _error = null);
                      },
                      icon: const Icon(Icons.close, color: rose, size: 17),
                    ),
                  ],
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
                    onPressed: _busy ? null : _saveNews,
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
                      _editing ? 'Save News' : 'Add News',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
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

                final cancelButton = OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => context.go('/events?tab=news'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: muted,
                    side: const BorderSide(color: line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                );

                if (!desktop) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      saveButton,
                      const SizedBox(height: 12),
                      cancelButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    cancelButton,
                    const Spacer(),
                    SizedBox(width: 180, child: saveButton),
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
          onPressed: () => context.go('/events?tab=news'),
          icon: const Icon(Icons.arrow_back, size: 17),
          label: const Text('Back to events'),
          style: TextButton.styleFrom(
            foregroundColor: purple,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _editing ? 'Edit news' : 'Add News/Announcement',
          style: const TextStyle(
            color: ink,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Title is required. Banner, details and dates are optional.',
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
            'You do not have permission to manage news.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: canvas,
      appBar: const AppHeader(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
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
        ),
      ),
      bottomNavigationBar: const BottomNav(isStaff: true),
    );
  }
}
