import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';

class AdminChapterFormPage extends StatefulWidget {
  const AdminChapterFormPage({super.key, this.id});

  final String? id;

  @override
  State<AdminChapterFormPage> createState() => _AdminChapterFormPageState();
}

class _AdminChapterFormPageState extends State<AdminChapterFormPage> {
  static const Color ink = Color(0xFF1A1433);
  static const Color muted = Color(0xFF5F5979);
  static const Color purple = Color(0xFF6C3FD1);
  static const Color purpleDark = Color(0xFF4B27A3);
  static const Color line = Color(0xFFE6DFF9);
  static const Color canvas = Color(0xFFF4EFFF);
  static const Color rose = Color(0xFFE8447F);

  static const String chaptersEndpoint = '/admin/chapters';

  static const List<Map<String, String>> countries = [
    {'iso': 'IN', 'label': 'India'},
    {'iso': 'SG', 'label': 'Singapore'},
    {'iso': 'US', 'label': 'United States'},
    {'iso': 'GB', 'label': 'United Kingdom'},
    {'iso': 'AE', 'label': 'United Arab Emirates'},
    {'iso': 'AU', 'label': 'Australia'},
    {'iso': 'CA', 'label': 'Canada'},
    {'iso': 'MY', 'label': 'Malaysia'},
    {'iso': 'LK', 'label': 'Sri Lanka'},
    {'iso': 'NP', 'label': 'Nepal'},
  ];

  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _country = 'IN';
  bool _isActive = true;

  bool _loading = false;
  bool _busy = false;
  bool _removing = false;

  String? _error;
  String? _notice;

  bool get _editing => widget.id != null && widget.id!.isNotEmpty;
  bool get _isRoot => authService.member?.isRoot ?? false;
  bool get _signedIn => authService.isLoggedIn;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_signedIn) {
        context.go('/login?next=/admin/chapters');
        return;
      }

      if (!_isRoot) return;

      if (_editing) {
        _loadChapter();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadChapter() async {
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

      final chapters = list.whereType<Map>().toList();

      Map<String, dynamic>? chapter;

      for (final item in chapters) {
        if (item['id']?.toString() == widget.id) {
          chapter = Map<String, dynamic>.from(item);
          break;
        }
      }

      if (!mounted) return;

      if (chapter == null) {
        setState(() {
          _error = 'Chapter not found.';
          _loading = false;
        });
        return;
      }

      _codeController.text = chapter['code']?.toString() ?? '';
      _nameController.text = chapter['name']?.toString() ?? '';
      _cityController.text = chapter['city']?.toString() ?? '';
      _descriptionController.text = chapter['description']?.toString() ?? '';

      final country = chapter['country']?.toString() ?? 'IN';

      setState(() {
        _country = countries.any((item) => item['iso'] == country)
            ? country
            : 'IN';
        _isActive = chapter?['isActive'] != false;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        context.go('/login?next=/admin/chapters');
        return;
      }

      setState(() {
        _error = _messageFromDio(e, 'Could not load that chapter.');
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

  String _messageFromDio(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return e.message ?? fallback;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      if (_editing) {
        await ApiConfig.dio.patch(
          '$chaptersEndpoint/${Uri.encodeComponent(widget.id!)}',
          data: {
            'name': name,
            'city': city,
            'country': _country,
            'description': description,
            'isActive': _isActive,
          },
        );
      } else {
        await ApiConfig.dio.post(
          chaptersEndpoint,
          data: {
            'code': _codeController.text.trim().toUpperCase(),
            'name': name,
            'city': city.isEmpty ? name : city,
            'country': _country,
            'description': description,
          },
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Chapter updated successfully.'
                : 'Chapter created successfully.',
          ),
          backgroundColor: const Color(0xFF159B70),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.go('/admin/chapters');
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        context.go('/login?next=/admin/chapters');
        return;
      }

      setState(() {
        _error = _messageFromDio(e, 'Could not save that chapter.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRemove() async {
    final name = _nameController.text.trim().isEmpty
        ? 'this chapter'
        : _nameController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Remove chapter',
            style: TextStyle(color: ink, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Remove $name? If it still has members, it will only be disabled.',
            style: const TextStyle(color: muted, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: muted)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: rose,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _removeChapter();
    }
  }

  Future<void> _removeChapter() async {
    setState(() {
      _removing = true;
      _error = null;
    });

    try {
      final response = await ApiConfig.dio.delete<dynamic>(
        '$chaptersEndpoint/${Uri.encodeComponent(widget.id!)}',
      );

      final result = response.data;
      final disabled = result is Map && result['disabled'] == true;

      if (!mounted) return;

      if (disabled) {
        setState(() {
          _isActive = false;
          _notice =
              '${_nameController.text.trim().isEmpty ? 'This chapter' : _nameController.text.trim()} still has members, so it was disabled.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_notice!),
            backgroundColor: const Color(0xFF159B70),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chapter removed successfully.'),
            backgroundColor: Color(0xFF159B70),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/admin/chapters');
      }
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        context.go('/login?next=/admin/chapters');
        return;
      }

      setState(() {
        _error = _messageFromDio(e, 'Could not remove that chapter.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const Scaffold(
        backgroundColor: canvas,
        body: Center(child: CircularProgressIndicator(color: purple)),
      );
    }

    if (!_isRoot) {
      return const Scaffold(
        backgroundColor: canvas,
        body: Center(
          child: Text(
            'Only Root Admin can manage chapters.',
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading(),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(color: purple),
                      ),
                    )
                  else
                    _formPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(isStaff: true),
    );
  }

  Widget _heading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => context.go('/admin/chapters'),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 7, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 17, color: purple),
                SizedBox(width: 7),
                Text(
                  'Chapters',
                  style: TextStyle(
                    color: purpleDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _editing ? 'Edit chapter' : 'Add chapter',
          style: const TextStyle(
            color: ink,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _editing
              ? 'Update chapter information and settings.'
              : 'Create a new chapter in the ILYF network.',
          style: const TextStyle(color: muted, fontSize: 13, height: 1.5),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_tree_outlined,
                    color: purple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chapter information',
                        style: TextStyle(
                          color: ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage chapter details and configuration.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),
            const Divider(color: line),
            const SizedBox(height: 24),

            const Text(
              'GENERAL INFORMATION',
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
                final isDesktop = constraints.maxWidth >= 650;
                final fieldWidth = isDesktop
                    ? (constraints.maxWidth - 20) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: !_editing
                          ? _field(
                              label: 'Chapter Code',
                              required: true,
                              controller: _codeController,
                              hint: 'BLR',
                              maxLength: 8,
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (value) {
                                final upper = value.toUpperCase();
                                if (upper != value) {
                                  _codeController.value = TextEditingValue(
                                    text: upper,
                                    selection: TextSelection.collapsed(
                                      offset: upper.length,
                                    ),
                                  );
                                }
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Add a chapter code.';
                                }
                                return null;
                              },
                            )
                          : _readOnlyCode(),
                    ),

                    SizedBox(
                      width: fieldWidth,
                      child: _field(
                        label: 'Chapter Name',
                        required: true,
                        controller: _nameController,
                        hint: 'Bengaluru',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Add the chapter name.';
                          }
                          return null;
                        },
                      ),
                    ),

                    SizedBox(
                      width: fieldWidth,
                      child: _field(
                        label: 'City',
                        controller: _cityController,
                        hint: 'Bengaluru',
                      ),
                    ),

                    SizedBox(width: fieldWidth, child: _countryField()),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: _field(
                        label: 'Chapter Details',
                        controller: _descriptionController,
                        hint: 'Enter information about this chapter...',
                        maxLines: 5,
                      ),
                    ),
                  ],
                );
              },
            ),

            if (_editing) ...[
              const SizedBox(height: 24),
              const Divider(color: line),
              const SizedBox(height: 16),
              _activeToggle(),
            ],

            if (_notice != null) ...[const SizedBox(height: 18), _noticeBox()],

            if (_error != null) ...[const SizedBox(height: 18), _errorBox()],

            const SizedBox(height: 28),
            const Divider(color: line),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 500;

                final saveButton = SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _editing ? 'Save Changes' : 'Create Chapter',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: purple.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                  ),
                );

                final removeButton = SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _removing ? null : _confirmRemove,
                    icon: _removing
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: rose,
                            ),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text(
                      'Remove Chapter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: rose,
                      side: const BorderSide(color: Color(0xFFF4C7D7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                );

                final showRemove =
                    _editing &&
                    _codeController.text.trim().toUpperCase() != 'TRUST';

                if (!isDesktop) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      saveButton,
                      if (showRemove) ...[
                        const SizedBox(height: 12),
                        removeButton,
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    if (showRemove) removeButton,
                    const Spacer(),
                    SizedBox(width: 210, child: saveButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Code'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2FB),
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            _codeController.text,
            style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool required = false,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
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
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9A93B3), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFCFBFF),
            counterStyle: const TextStyle(color: muted, fontSize: 10),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: purple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: rose),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String value, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(text: value),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: rose),
            ),
        ],
      ),
    );
  }

  Widget _countryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Country'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _country,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFCFBFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: line),
            ),
          ),
          items: countries.map((country) {
            return DropdownMenuItem<String>(
              value: country['iso'],
              child: Text(
                country['label']!,
                style: const TextStyle(
                  color: ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _country = value);
            }
          },
        ),
      ],
    );
  }

  Widget _activeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter status',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Allow this chapter to remain active.',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            activeThumbColor: Colors.white,
            activeTrackColor: purple,
            onChanged: (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F2),
        border: Border.all(color: const Color(0xFFF5C7D1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: rose, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB52D50), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F8F1),
        border: Border.all(color: const Color(0xFFB8E8D2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF159B70),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _notice!,
              style: const TextStyle(
                color: Color(0xFF167B5C),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
