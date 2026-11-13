import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';
import '../../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const purple = Color(0xFF6C3FD1);
  static const purpleDark = Color(0xFF4B27A3);
  static const ink = Color(0xFF171031);
  static const muted = Color(0xFF5D5778);
  static const line = Color(0xFFE8E1FA);
  static const bg = Color(0xFFF6F3FF);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _services = TextEditingController();
  final _website = TextEditingController();
  final _instagram = TextEditingController();
  final _facebook = TextEditingController();
  final _linkedin = TextEditingController();
  final _otp = TextEditingController();
  final Map<String, Uint8List> _localMediaPreviews = {};

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _offers = [];

  // Editable offer state.
  final _offerTitle = TextEditingController();
  final _offerDescription = TextEditingController();
  DateTime? _offerStartDate;
  DateTime? _offerEndDate;
  String? _editingOfferId;
  PlatformFile? _offerBanner;
  String? _offerBannerPreview;
  bool _offerEditorOpen = false;
  bool _offerBusy = false;

  // Profile media state.
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _videos = [];
  bool _mediaBusy = false;
  String? _uploadingKind;
  static const int _maxImages = 5;
  static const int _maxDocuments = 3;
  static const int _maxVideos = 1;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String _phoneStep = 'idle';
  String? _error;
  String? _notice;
  bool get _signedIn => authService.isLoggedIn;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (!_signedIn) {
        context.go('/login?next=/profile');
      } else {
        _loadProfile();
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _category,
      _description,
      _services,
      _website,
      _instagram,
      _facebook,
      _linkedin,
      _otp,
      _offerTitle,
      _offerDescription,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _s(dynamic v) => v == null ? '' : v.toString();

  Map<String, dynamic> _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  List<Map<String, dynamic>> _list(dynamic v) {
    if (v is! List) return [];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _social(List<dynamic> links, String platform) {
    for (final raw in links) {
      final item = _map(raw);
      if (_s(item['platform']).toLowerCase().contains(platform)) {
        return _s(item['url']);
      }
    }
    return '';
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiConfig.dio.get<dynamic>('/me/profile');
      _applyProfile(_map(response.data));

      if (_offers.isEmpty) {
        try {
          final r = await ApiConfig.dio.get<dynamic>('/me/offers');
          final body = r.data;
          final rawOffers = body is Map
              ? (body['offers'] ??
                    (body['data'] is Map
                        ? body['data']['offers']
                        : body['data']) ??
                    [])
              : body;
          setState(() => _offers = _list(rawOffers));
        } on DioException {}
      }
    } on DioException catch (e) {
      if (!mounted) return;

      if (e.response?.statusCode == 401) {
        context.go('/login?next=/profile');
        return;
      }

      setState(() {
        _error = e.message ?? 'Could not load your profile.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load profile: $e';
        _loading = false;
      });
    }
  }

  void _applyProfile(Map<String, dynamic> data) {
    if (data['data'] is Map && data['business'] == null)
      data = _map(data['data']);
    final business = _map(data['business']);
    final links = business['socialLinks'] is List
        ? business['socialLinks'] as List
        : <dynamic>[];
    _profile = data;
    _name.text = _s(data['fullName']);
    _email.text = _s(data['email']);
    _phone.text = _s(data['phone']);
    _category.text = _s(business['category']);
    _description.text = _s(business['description']);
    _services.text = business['services'] is List
        ? (business['services'] as List).map(_s).join('\n')
        : '';
    _website.text = _s(business['website']).isNotEmpty
        ? _s(business['website'])
        : _social(links, 'website');
    _instagram.text = _social(links, 'instagram');
    _facebook.text = _social(links, 'facebook');
    _linkedin.text = _social(links, 'linkedin');
    _offers = _list(data['offers']);
    _images = _normaliseMedia(business['images']);
    _documents = _normaliseMedia(business['documents']);
    _videos = _normaliseMedia(business['videos']);
    _phoneStep = 'idle';
    _otp.clear();
    if (mounted) {
      setState(() {
        _loading = false;
        _error = null;
      });
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _error = error ? message : null;
      _notice = error ? null : message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : purpleDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      final links = <Map<String, String>>[
        if (_instagram.text.trim().isNotEmpty)
          {'platform': 'Instagram', 'url': _instagram.text.trim()},
        if (_facebook.text.trim().isNotEmpty)
          {'platform': 'Facebook', 'url': _facebook.text.trim()},
        if (_linkedin.text.trim().isNotEmpty)
          {'platform': 'LinkedIn', 'url': _linkedin.text.trim()},
        if (_website.text.trim().isNotEmpty)
          {'platform': 'Website', 'url': _website.text.trim()},
      ];
      final oldPhone = _s(_profile?['phone']);

      final response = await ApiConfig.dio.patch<dynamic>(
        '/me/profile',
        data: {
          'fullName': _name.text.trim(),
          'email': _email.text.trim(),
          'category': _category.text.trim(),
          'description': _description.text.trim(),
          'website': _website.text.trim(),
          'services': _services.text
              .split(RegExp(r'[\n,]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
          'socialLinks': links,
        },
      );
      final saved = _map(response.data);
      if (saved.isNotEmpty) _applyProfile(saved);

      final newPhone = _phone.text.trim();
      if (newPhone.isNotEmpty && oldPhone.isNotEmpty && newPhone != oldPhone) {
        await ApiConfig.dio.post<dynamic>(
          '/me/phone/otp',
          data: {'phone': newPhone},
        );
        if (!mounted) return;
        setState(() {
          _phoneStep = 'otp';
          _saving = false;
        });
        _toast('OTP sent to the new number. Enter it to confirm the change.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
      _toast('Profile saved successfully.');
      await _loadProfile();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final body = e.response?.data;
      final message = body is Map && body['message'] != null
          ? _s(body['message'])
          : (e.message ?? 'Could not save your profile.');
      _toast(message, error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Could not save profile: $e', error: true);
    }
  }

  Future<void> _verifyPhone() async {
    if (_otp.text.trim().isEmpty) {
      _toast('Enter the OTP sent to your new number.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final r = await ApiConfig.dio.post<dynamic>(
        '/me/phone/confirm',
        data: {'phone': _phone.text.trim(), 'otp': _otp.text.trim()},
      );
      final data = _map(r.data);
      if (data.isNotEmpty) _applyProfile(data);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
        _phoneStep = 'idle';
      });
      _toast('Phone number updated.');
      await _loadProfile();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message ?? 'OTP verification failed.', error: true);
    }
  }

  List<Map<String, dynamic>> _normaliseMedia(dynamic value) {
    if (value is! List) return [];
    return value
        .map((item) {
          if (item is Map) return Map<String, dynamic>.from(item);
          if (item is String)
            return <String, dynamic>{
              'url': item,
              'title': item.split('/').last,
            };
          return <String, dynamic>{};
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _mediaItemUrl(Map<String, dynamic> item) {
    return _s(item['url']).isNotEmpty
        ? _s(item['url'])
        : _s(item['fileUrl']).isNotEmpty
        ? _s(item['fileUrl'])
        : _s(item['path']);
  }

  String _mediaItemTitle(Map<String, dynamic> item) {
    return _s(item['title']).isNotEmpty
        ? _s(item['title'])
        : _s(item['originalName']).isNotEmpty
        ? _s(item['originalName'])
        : _mediaItemUrl(item).split('/').last;
  }

  Future<PlatformFile?> _pickFile({required List<String> extensions}) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    return file;
  }

  Future<void> _uploadMedia(String kind, {int? replaceIndex}) async {
    final isImage = kind == 'image';
    final isDocument = kind == 'document';
    final limit = isImage
        ? _maxImages
        : isDocument
        ? _maxDocuments
        : _maxVideos;
    final current = isImage
        ? _images
        : isDocument
        ? _documents
        : _videos;

    if (replaceIndex == null && current.length >= limit) {
      _toast(
        'You can add up to $limit ${kind == 'image'
            ? 'images'
            : kind == 'document'
            ? 'documents'
            : 'video'}.',
        error: true,
      );
      return;
    }

    final extensions = isImage
        ? ['jpg', 'jpeg', 'png', 'webp']
        : isDocument
        ? ['pdf', 'doc', 'docx', 'xls', 'xlsx']
        : ['mp4', 'mov', 'webm'];

    final file = await _pickFile(extensions: extensions);
    if (file == null) return;

    if (isImage || kind == 'video') {
      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        _localMediaPreviews[kind] = bytes;
      });
    }

    setState(() {
      _mediaBusy = true;
      _uploadingKind = kind;
    });

    try {
      final fileBytes = await file.readAsBytes();

      final form = FormData.fromMap({
        'kind': kind,
        'file': MultipartFile.fromBytes(fileBytes, filename: file.name),
        'title': file.name,
        if (replaceIndex != null) 'replaceIndex': replaceIndex,
      });

      final response = await ApiConfig.dio.post<dynamic>(
        '/me/media',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final body = _map(response.data);
      if (body.isNotEmpty) {
        final data = body['data'] is Map ? _map(body['data']) : body;
        if (data.containsKey('business') || data.containsKey('offers')) {
          _applyProfile(data);
        } else {
          await _loadProfile();
        }
      } else {
        await _loadProfile();
      }
      if (!mounted) return;
      setState(() {
        _mediaBusy = false;
        _uploadingKind = null;
      });
      _toast(
        '${kind[0].toUpperCase()}${kind.substring(1)} uploaded successfully.',
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _mediaBusy = false;
        _uploadingKind = null;
      });
      final body = e.response?.data;
      final message = body is Map && body['message'] != null
          ? _s(body['message'])
          : 'Could not upload this file.';
      _toast(message, error: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mediaBusy = false;
        _uploadingKind = null;
      });
      _toast('Could not upload this file.', error: true);
    }
  }

  Future<void> _removeMedia(String kind, int index) async {
    final label = kind == 'image'
        ? 'image'
        : kind == 'document'
        ? 'file'
        : 'video';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remove ${kind == 'image'
              ? 'image'
              : kind == 'document'
              ? 'document'
              : 'video'}?',
        ),
        content: Text('Do you want to remove this $label from your profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _mediaBusy = true;
      _uploadingKind = kind;
    });
    try {
      await ApiConfig.dio.delete<dynamic>(
        '/me/media',
        queryParameters: {'kind': kind, 'index': index},
      );
      await _loadProfile();
      if (!mounted) return;
      setState(() {
        _mediaBusy = false;
        _uploadingKind = null;
      });
      _toast('Removed successfully.');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _mediaBusy = false;
        _uploadingKind = null;
      });
      _toast(e.message ?? 'Could not remove this file.', error: true);
    }
  }

  void _resetOfferEditor() {
    _offerTitle.clear();
    _offerDescription.clear();
    _offerStartDate = null;
    _offerEndDate = null;
    _editingOfferId = null;
    _offerBanner = null;
    _offerBannerPreview = null;
    _offerEditorOpen = false;
  }

  void _startOfferCreate() {
    setState(() {
      _resetOfferEditor();
      _offerEditorOpen = true;
    });
  }

  void _startOfferEdit(Map<String, dynamic> offer) {
    setState(() {
      _offerTitle.text = _s(offer['title']);
      _offerDescription.text = _s(offer['description']);
      _offerStartDate = DateTime.tryParse(_s(offer['startDate']));
      _offerEndDate = DateTime.tryParse(_s(offer['endDate']));
      _editingOfferId = _s(offer['id']).isNotEmpty
          ? _s(offer['id'])
          : _s(offer['_id']);
      _offerBanner = null;
      _offerBannerPreview = _s(offer['bannerUrl']).isNotEmpty
          ? _mediaUrl(_s(offer['bannerUrl']))
          : null;
      _offerEditorOpen = true;
    });
  }

  Future<void> _pickOfferBanner() async {
    final file = await _pickFile(extensions: ['jpg', 'jpeg', 'png', 'webp']);
    if (file == null) return;
    setState(() {
      _offerBanner = file;
      _offerBannerPreview = null;
    });
  }

  Future<void> _chooseOfferDate({required bool start}) async {
    final initial = (start ? _offerStartDate : _offerEndDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _offerStartDate = picked;
      } else {
        _offerEndDate = picked;
      }
    });
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Select date';
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    return '$d/$m/${value.year}';
  }

  Future<void> _saveOffer() async {
    final title = _offerTitle.text.trim();
    if (title.isEmpty) {
      _toast('Offer title is required.', error: true);
      return;
    }
    if (_offerStartDate != null &&
        _offerEndDate != null &&
        _offerEndDate!.isBefore(_offerStartDate!)) {
      _toast('End date cannot be before start date.', error: true);
      return;
    }
    if (_editingOfferId == null && _offers.isNotEmpty) {
      _toast(
        'You can add only one offer. Edit or remove the existing offer.',
        error: true,
      );
      return;
    }

    setState(() => _offerBusy = true);
    try {
      final form = FormData.fromMap({
        'title': title,
        'description': _offerDescription.text.trim(),
        'startDate': _offerStartDate == null
            ? ''
            : _offerStartDate!.toIso8601String().split('T').first,
        'endDate': _offerEndDate == null
            ? ''
            : _offerEndDate!.toIso8601String().split('T').first,
        if (_offerBanner != null)
          'banner': MultipartFile.fromBytes(
            await _offerBanner!.readAsBytes(),
            filename: _offerBanner!.name,
          ),
      });

      final id = _editingOfferId;
      if (id == null) {
        await ApiConfig.dio.post<dynamic>(
          '/me/offers',
          data: form,
          options: Options(contentType: 'multipart/form-data'),
        );
      } else {
        await ApiConfig.dio.patch<dynamic>(
          '/me/offers/$id',
          data: form,
          options: Options(contentType: 'multipart/form-data'),
        );
      }

      await _loadProfile();
      if (!mounted) return;
      setState(() {
        _offerBusy = false;
        _resetOfferEditor();
      });
      _toast(
        id == null
            ? 'Offer created successfully.'
            : 'Offer updated successfully.',
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _offerBusy = false);
      final body = e.response?.data;
      final message = body is Map && body['message'] != null
          ? _s(body['message'])
          : 'Could not save offer.';
      _toast(message, error: true);
    }
  }

  Future<void> _deleteOffer(Map<String, dynamic> offer) async {
    final id = _s(offer['id']).isNotEmpty ? _s(offer['id']) : _s(offer['_id']);
    if (id.isEmpty) {
      _toast('Offer ID is missing. Cannot delete this offer.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete offer?'),
        content: const Text('This offer will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _offerBusy = true);
    try {
      await ApiConfig.dio.delete<dynamic>('/me/offers/$id');
      await _loadProfile();
      if (!mounted) return;
      setState(() => _offerBusy = false);
      _toast('Offer deleted successfully.');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _offerBusy = false);
      _toast(e.message ?? 'Could not delete offer.', error: true);
    }
  }

  Widget _offerDateButton(String label, DateTime? date, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: _offerBusy ? null : onTap,
      icon: const Icon(Icons.calendar_month_outlined, size: 18),
      label: Text('$label: ${_dateLabel(date)}'),
      style: OutlinedButton.styleFrom(
        foregroundColor: purpleDark,
        side: const BorderSide(color: line),
      ),
    );
  }

  Widget _offerEditor() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editingOfferId == null ? 'Create offer' : 'Edit offer',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _field('Offer title *', _offerTitle, required: true),
        _field('Description', _offerDescription, maxLines: 3),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _offerDateButton(
              'Start',
              _offerStartDate,
              () => _chooseOfferDate(start: true),
            ),
            _offerDateButton(
              'End',
              _offerEndDate,
              () => _chooseOfferDate(start: false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_offerBannerPreview != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _offerBannerPreview!,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        if (_offerBanner != null)
          Text(
            'Selected banner: ${_offerBanner!.name}',
            style: const TextStyle(color: muted),
          ),
        OutlinedButton.icon(
          onPressed: _offerBusy ? null : _pickOfferBanner,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            _offerBanner == null ? 'Choose offer banner' : 'Change banner',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _offerBusy
                    ? null
                    : () => setState(_resetOfferEditor),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _offerBusy ? null : _saveOffer,
                style: FilledButton.styleFrom(backgroundColor: purple),
                child: _offerBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save offer'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _mediaSection({
    required String kind,
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required int limit,
    required List<String> extensionsLabel,
  }) {
    final canAdd = items.length < limit;
    final isImage = kind == 'image';
    final isVideo = kind == 'video';
    final isVisualMedia = isImage || isVideo;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: purpleDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title (${items.length}/$limit)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ink,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _mediaBusy || !canAdd
                    ? null
                    : () => _uploadMedia(kind),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: Column(
                children: [
                  Icon(
                    isImage
                        ? Icons.add_photo_alternate_outlined
                        : isVideo
                        ? Icons.video_library_outlined
                        : Icons.description_outlined,
                    size: 30,
                    color: muted,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'No ${title.toLowerCase()} added yet',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            )
          else if (isVisualMedia)
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final boxWidth = (constraints.maxWidth - spacing * 2) / 3;

                return SizedBox(
                  height: 142,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: spacing),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final url = _mediaItemUrl(item);
                      final name = _mediaItemTitle(item);

                      return SizedBox(
                        width: boxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: isImage
                                        ? (_localMediaPreviews[kind] != null
                                              ? Image.memory(
                                                  _localMediaPreviews[kind]!,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                )
                                              : Image.network(
                                                  _mediaUrl(url),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        color: bg,
                                                        child: const Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                          color: muted,
                                                        ),
                                                      ),
                                                ))
                                        : Container(
                                            color: const Color(0xFF32166D),
                                            child: const Center(
                                              child: Icon(
                                                Icons.play_circle_fill,
                                                color: Colors.white,
                                                size: 42,
                                              ),
                                            ),
                                          ),
                                  ),

                                  // Preview actions
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _mediaActionButton(
                                          icon: Icons.swap_horiz,
                                          color: purpleDark,
                                          onTap: _mediaBusy
                                              ? null
                                              : () => _uploadMedia(
                                                  kind,
                                                  replaceIndex: index,
                                                ),
                                        ),
                                        const SizedBox(width: 4),
                                        _mediaActionButton(
                                          icon: Icons.delete_outline,
                                          color: Colors.red,
                                          onTap: _mediaBusy
                                              ? null
                                              : () => _removeMedia(kind, index),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (isVideo && url.isNotEmpty)
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: IconButton(
                                        visualDensity: VisualDensity.compact,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black
                                              .withValues(alpha: 0.55),
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _openLink(_mediaUrl(url)),
                                        icon: const Icon(
                                          Icons.open_in_new,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              name.isEmpty ? '$title ${index + 1}' : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final name = _mediaItemTitle(item);
              final url = _mediaItemUrl(item);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: line),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: purple,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name.isEmpty ? 'Document ${index + 1}' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _mediaBusy
                          ? null
                          : () => _uploadMedia(kind, replaceIndex: index),
                      icon: const Icon(Icons.swap_horiz, color: purpleDark),
                    ),
                    IconButton(
                      onPressed: _mediaBusy
                          ? null
                          : () => _removeMedia(kind, index),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                    if (url.isNotEmpty)
                      IconButton(
                        onPressed: () => _openLink(_mediaUrl(url)),
                        icon: const Icon(Icons.open_in_new, color: purpleDark),
                      ),
                  ],
                ),
              );
            }),

          if (_uploadingKind == kind && _mediaBusy)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(color: purple),
            ),

          const SizedBox(height: 5),
          Text(
            'Accepted: ${extensionsLabel.join(', ')}',
            style: const TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _mediaActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 29,
          height: 29,
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }

  Future<void> _openLink(String value) async {
    var raw = value.trim();
    if (raw.isEmpty) return;
    if (!raw.startsWith('http://') &&
        !raw.startsWith('https://') &&
        !raw.startsWith('mailto:') &&
        !raw.startsWith('tel:')) {
      raw = 'https://$raw';
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast('Could not open this link.', error: true);
    }
  }

  Future<void> _share() async {
    final text = [
      _name.text,
      if (_businessName.isNotEmpty) _businessName,
      if (_membershipNo.isNotEmpty) 'ILYF ID: $_membershipNo',
      if (_email.text.isNotEmpty) _email.text,
      if (_phone.text.isNotEmpty) _phone.text,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    _toast('Profile details copied.');
  }

  Future<void> _logout() async {
    try {
      await ApiConfig.dio.post<dynamic>('/auth/logout');
    } catch (_) {}
    if (mounted) context.go('/');
  }

  String get _nameValue => _s(_profile?['fullName']).isNotEmpty
      ? _s(_profile?['fullName'])
      : 'Your profile';
  String get _businessName => _s(_map(_profile?['business'])['name']);
  String get _membershipNo => _s(_profile?['membershipNo']);
  String get _membershipType => _s(_profile?['membershipType']);
  String get _chapter => _s(_map(_profile?['chapter'])['name']);
  String get _photo => _s(_profile?['photoUrl']);
  String get _initials {
    final words = _nameValue
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty);
    return words.take(2).map((e) => e[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: purple)),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: const AppHeader(),
      bottomNavigationBar: const BottomNav(isStaff: false),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: purple))
            : _profile == null
            ? _errorView()
            : RefreshIndicator(
                color: purple,
                onRefresh: _loadProfile,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 1000;
                    final isTablet = constraints.maxWidth >= 650;

                    final contentWidth = isDesktop ? 1250.0 : double.infinity;

                    final horizontalPadding = isDesktop ? 32.0 : 16.0;

                    final cardWidth = isDesktop
                        ? (contentWidth - (horizontalPadding * 2) - 16) / 2
                        : isTablet
                        ? (constraints.maxWidth - 48) / 2
                        : constraints.maxWidth - 32;

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 30),
                      children: [
                        _hero(),

                        Transform.translate(
                          offset: const Offset(0, -28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: contentWidth,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                ),
                                child: _actionPanel(),
                              ),
                            ),
                          ),
                        ),

                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: contentWidth),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                0,
                                horizontalPadding,
                                0,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    if (_notice != null)
                                      _noticeBox(_notice!, false),

                                    if (_error != null)
                                      _noticeBox(
                                        'Something went wrong. Please try again later.',
                                        true,
                                      ),

                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: [
                                        SizedBox(
                                          width: cardWidth,
                                          child: _aboutCard(),
                                        ),
                                        SizedBox(
                                          width: cardWidth,
                                          child: _contactCard(),
                                        ),
                                        SizedBox(
                                          width: cardWidth,
                                          child: _socialCard(),
                                        ),
                                        SizedBox(
                                          width: cardWidth,
                                          child: _servicesCard(),
                                        ),
                                        SizedBox(
                                          width: cardWidth,
                                          child: _memberIdCard(),
                                        ),
                                        SizedBox(
                                          width: cardWidth,
                                          child: _offersCard(),
                                        ),
                                      ],
                                    ),

                                    _mediaCard(),
                                    _saveActions(),
                                    _logoutButton(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_circle_outlined, size: 54, color: purple),
          Text(
            _error ?? 'Could not load your profile',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  Widget _hero() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1314),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 48),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF170A3D), Color(0xFF2C1573), Color(0xFF231063)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFFE9C46A),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'PROFILE SUMMARY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (_membershipType.isNotEmpty)
                  _pill('$_membershipType member', gold: true),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photo.isEmpty
                      ? Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : Image.network(
                          _mediaUrl(_photo),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameValue,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_businessName.isNotEmpty)
                        Text(
                          _businessName,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      if (_category.text.isNotEmpty)
                        Text(
                          _category.text,
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_membershipNo.isNotEmpty) _pill('ILYF ID: $_membershipNo'),
                if (_chapter.isNotEmpty) _pill(_chapter),
                if (_membershipType.isNotEmpty) _pill('★ $_membershipType'),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _actionPanel() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x164B27A3),
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _action(
            Icons.edit_outlined,
            'Edit profile',
            () => setState(() => _editing = true),
            primary: true,
          ),
        ),
        Expanded(
          child: _action(
            Icons.mail_outline,
            'Email',
            () => _openLink('mailto:${_email.text}'),
          ),
        ),
        Expanded(
          child: _action(
            Icons.call_outlined,
            'Call',
            () => _openLink('tel:${_phone.text}'),
          ),
        ),
        Expanded(child: _action(Icons.share_outlined, 'Share', _share)),
      ],
    ),
  );

  Widget _action(
    IconData icon,
    String label,
    VoidCallback tap, {
    bool primary = false,
  }) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary ? purple : bg,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primary ? purple : line),
            ),
            child: Icon(icon, color: primary ? Colors.white : purpleDark),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _card(String title, IconData icon, Widget child, {Widget? trailing}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x104B27A3),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: purple),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _editButton() => IconButton(
    tooltip: 'Edit profile',
    onPressed: () => setState(() => _editing = true),
    icon: const Icon(Icons.edit_outlined, color: purple),
  );

  Widget _aboutCard() => _card(
    'About your business',
    Icons.auto_awesome_outlined,
    _editing
        ? Column(
            children: [
              _field('Full name', _name, required: true),
              _field('Business category', _category),
              _field('Description', _description, maxLines: 4),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _description.text.isEmpty
                    ? 'Add a business description.'
                    : _description.text,
                style: const TextStyle(color: muted, height: 1.6),
              ),
              if (_category.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                _lightPill(_category.text),
              ],
            ],
          ),
    trailing: _editButton(),
  );

  Widget _contactCard() => _card(
    'Contact details',
    Icons.contact_mail_outlined,
    Column(
      children: [
        _contactRow(
          Icons.email_outlined,
          'Email',
          _email.text,
          () => _openLink('mailto:${_email.text}'),
        ),
        _contactRow(
          Icons.phone_outlined,
          'Phone',
          _phone.text,
          () => _openLink('tel:${_phone.text}'),
        ),
        if (_editing) ...[
          _field(
            'Email address',
            _email,
            keyboardType: TextInputType.emailAddress,
          ),
          _field('Phone number', _phone, keyboardType: TextInputType.phone),
          if (_phoneStep == 'otp') ...[
            _field('OTP', _otp, keyboardType: TextInputType.number),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _saving ? null : _verifyPhone,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Verify new phone'),
              ),
            ),
          ],
        ],
      ],
    ),
    trailing: _editButton(),
  );

  Widget _contactRow(
    IconData icon,
    String label,
    String value,
    VoidCallback tap,
  ) => InkWell(
    onTap: value.isEmpty ? null : tap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: purpleDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'Add your $label' : value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Icon(value.isEmpty ? Icons.add : Icons.chevron_right, color: muted),
        ],
      ),
    ),
  );

  Widget _socialCard() => _card(
    'Social profiles',
    Icons.link_outlined,
    _editing
        ? Column(
            children: [
              _field('Website URL', _website, keyboardType: TextInputType.url),
              _field(
                'LinkedIn URL',
                _linkedin,
                keyboardType: TextInputType.url,
              ),
              _field(
                'Instagram URL',
                _instagram,
                keyboardType: TextInputType.url,
              ),
              _field(
                'Facebook URL',
                _facebook,
                keyboardType: TextInputType.url,
              ),
            ],
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_website.text.isNotEmpty)
                _socialChip('Website', Icons.language, _website.text),
              if (_linkedin.text.isNotEmpty)
                _socialChip('LinkedIn', Icons.work_outline, _linkedin.text),
              if (_instagram.text.isNotEmpty)
                _socialChip(
                  'Instagram',
                  Icons.camera_alt_outlined,
                  _instagram.text,
                ),
              if (_facebook.text.isNotEmpty)
                _socialChip('Facebook', Icons.facebook, _facebook.text),
              if (_website.text.isEmpty &&
                  _linkedin.text.isEmpty &&
                  _instagram.text.isEmpty &&
                  _facebook.text.isEmpty)
                const Text(
                  'Add your social profile links.',
                  style: TextStyle(color: muted),
                ),
            ],
          ),
    trailing: _editButton(),
  );

  Widget _socialChip(String label, IconData icon, String url) => ActionChip(
    avatar: Icon(icon, size: 17, color: purpleDark),
    label: Text(label),
    onPressed: () => _openLink(url),
    backgroundColor: bg,
    side: const BorderSide(color: line),
  );

  Widget _servicesCard() {
    final items = _services.text
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return _card(
      'Services & expertise',
      Icons.workspace_premium_outlined,
      _editing
          ? _field('One service per line', _services, maxLines: 5)
          : items.isEmpty
          ? const Text('Add your services.', style: TextStyle(color: muted))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map(_lightPill).toList(),
            ),
      trailing: _editButton(),
    );
  }

  Widget _lightPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: line),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: purpleDark,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _memberIdCard() => _card(
    'Your member ID',
    Icons.qr_code_2_outlined,
    Row(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: line),
          ),
          child: const Icon(Icons.qr_code_2, size: 65, color: purpleDark),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ILYF member identification',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _membershipNo.isEmpty
                    ? 'Member ID not available'
                    : _membershipNo,
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 5),
              const Text(
                'QR icon is a placeholder; a QR package is needed for a scannable code.',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _offersCard() => _card(
    'Your listings',
    Icons.local_offer_outlined,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_offers.isEmpty && !_offerEditorOpen)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'You have not created an listing yet.',
              style: TextStyle(color: muted),
            ),
          ),
        if (_offers.isNotEmpty && !_offerEditorOpen)
          ..._offers.map((offer) {
            final banner = _s(offer['bannerUrl']);
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banner.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _mediaUrl(banner),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  if (banner.isNotEmpty) const SizedBox(height: 10),
                  Text(
                    _s(offer['title']).isEmpty ? 'Offer' : _s(offer['title']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (_s(offer['description']).isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      _s(offer['description']),
                      style: const TextStyle(color: muted, height: 1.4),
                    ),
                  ],
                  if (_s(offer['startDate']).isNotEmpty ||
                      _s(offer['endDate']).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_s(offer['startDate'])} – ${_s(offer['endDate'])}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _offerBusy
                            ? null
                            : () => _startOfferEdit(offer),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _offerBusy
                            ? null
                            : () => _deleteOffer(offer),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 17,
                        ),
                        label: const Text(
                          'Remove',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        if (_offerEditorOpen) _offerEditor(),
        if (!_offerEditorOpen && _offers.isEmpty)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _offerBusy ? null : _startOfferCreate,
              style: FilledButton.styleFrom(backgroundColor: purple),
              icon: const Icon(Icons.add),
              label: const Text('Create Listing'),
            ),
          ),
      ],
    ),
    trailing: Text(
      '${_offers.length}/1',
      style: const TextStyle(color: muted, fontWeight: FontWeight.w800),
    ),
  );

  Widget _mediaCard() => _card(
    'Profile media',
    Icons.perm_media_outlined,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage the photos, documents and introduction video displayed on your member profile.',
          style: TextStyle(color: muted, height: 1.45),
        ),
        const SizedBox(height: 14),
        _mediaSection(
          kind: 'image',
          title: 'Images',
          icon: Icons.image_outlined,
          items: _images,
          limit: _maxImages,
          extensionsLabel: ['JPG', 'PNG', 'WEBP'],
        ),
        _mediaSection(
          kind: 'document',
          title: 'Documents',
          icon: Icons.description_outlined,
          items: _documents,
          limit: _maxDocuments,
          extensionsLabel: ['PDF', 'DOC', 'DOCX', 'XLS', 'XLSX'],
        ),
        _mediaSection(
          kind: 'video',
          title: 'Introduction video',
          icon: Icons.videocam_outlined,
          items: _videos,
          limit: _maxVideos,
          extensionsLabel: ['MP4', 'MOV', 'WEBM'],
        ),
        if (_mediaBusy)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Updating profile media…',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
      ],
    ),
  );

  Widget _saveActions() {
    if (!_editing) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_profile != null) _applyProfile(_profile!);
                      setState(() {
                        _editing = false;
                        _phoneStep = 'idle';
                      });
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: line),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutButton() => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          'Log out',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFFFC9D9)),
        ),
      ),
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: purple),
        ),
      ),
    ),
  );

  Widget _pill(String text, {bool gold = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: gold
          ? const Color(0x26E9C46A)
          : Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(
        color: gold ? const Color(0x99E9C46A) : Colors.white24,
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: gold ? const Color(0xFFFFF1C2) : Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _noticeBox(String text, bool error) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFFEEF2) : const Color(0xFFEAF8F0),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: error ? Colors.red.shade800 : Colors.green.shade800,
      ),
    ),
  );

  String _mediaUrl(String value) {
    final raw = value.trim();
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('/'))
      return raw;
    if (raw.startsWith('members/')) return '/api/media/$raw';
    return raw;
  }
}
