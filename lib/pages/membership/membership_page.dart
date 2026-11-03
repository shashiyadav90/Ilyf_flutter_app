
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';
import '../../core/config/api_config.dart';

class MembershipPage extends StatefulWidget {
  const MembershipPage({super.key});

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  // IMPORTANT:
  // Replace this with the actual endpoint provided by your backend team.
  static const String membershipSubmitEndpoint =
      '/membership/enquiries';

  static const Color purple = Color(0xFF7A4FD0);
  static const Color purpleDark = Color(0xFF4B27A3);
  static const Color pink = Color(0xFFE5397A);
  static const Color canvas = Color(0xFFF8F7FB);
  static const Color ink = Color(0xFF25212D);
  static const Color muted = Color(0xFF777181);
  static const Color line = Color(0xFFE8E3EF);

  final _formKey = GlobalKey<FormState>();

  String _type = 'annual';
  bool _isSubmitting = false;
  String? _successMessage;
  String? _errorMessage;

  final Map<String, TextEditingController> _controllers = {};

  String? _businessName;

  final List<_MembershipField> _annualFields = [
    _MembershipField('fullName', 'Full name'),
    _MembershipField('email', 'Email address', isEmail: true),
    _MembershipField('company', 'Company'),
    _MembershipField('position', 'Position'),
    _MembershipField('industry', 'Industry'),
    _MembershipField('businessCategory', 'Business category'),
  ];

  final List<_MembershipField> _patronFields = [
    _MembershipField('contactName', 'Contact name'),
    _MembershipField('email', 'Email address', isEmail: true),
    _MembershipField('company', 'Company'),
    _MembershipField('serviceType', 'Service type'),
    _MembershipField('industry', 'Industry specialization'),
    _MembershipField('experience', 'Years of experience'),
  ];

  List<_MembershipField> get _fields =>
      _type == 'annual' ? _annualFields : _patronFields;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uri = GoRouterState.of(context).uri;
    _businessName = uri.queryParameters['name'];
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String name) {
    return _controllers.putIfAbsent(
      name,
      () => TextEditingController(),
    );
  }

  void _changeType(String type) {
    if (_type == type) return;

    setState(() {
      _type = type;
      _successMessage = null;
      _errorMessage = null;

      // Clear values when switching membership types.
      for (final controller in _controllers.values) {
        controller.clear();
      }
    });
  }

  Future<void> _submitMembership() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final details = <String, dynamic>{};

    for (final field in _fields) {
      details[field.name] = _controllerFor(field.name).text.trim();
    }

    final payload = <String, dynamic>{
      'membershipType': _type,
      ...details,
    };

    try {
      final response = await ApiConfig.dio.post(
        membershipSubmitEndpoint,
        data: payload,
      );

      if (!mounted) return;

      setState(() {
        _successMessage =
            response.data is Map &&
                    response.data['message'] != null
                ? response.data['message'].toString()
                : 'Your membership details have been submitted successfully.';
      });
    } on DioException catch (e) {
      if (!mounted) return;

      final responseData = e.response?.data;
      String message = 'Unable to submit your membership details. Please try again.';

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (e.response == null) {
        message = 'Unable to connect to the server. Please check your internet connection.';
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = _businessName != null &&
            _businessName!.trim().isNotEmpty
        ? 'Become a member to view more about ${_businessName!.trim()}'
        : 'Choose your ILYF membership';

    return Scaffold(
      backgroundColor: canvas,
      appBar: const AppHeader(),
      bottomNavigationBar: const BottomNav(isStaff: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _backButton(),

                  const SizedBox(height: 22),

                  _buildHero(heading),

                  const SizedBox(height: 22),

                  _buildMembershipSelector(),

                  const SizedBox(height: 16),

                  _buildMembershipDescription(),

                  const SizedBox(height: 20),

                  _buildFormCard(),

                  const SizedBox(height: 20),

                  _buildBenefits(),

                  const SizedBox(height: 20),

                  _buildBottomNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/login?next=/members');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_rounded, size: 19, color: purple),
            SizedBox(width: 8),
            Text(
              'Back',
              style: TextStyle(
                color: purple,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(String heading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [purpleDark, purple, Color(0xFF9873E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 15,
                  color: Color(0xFFFFD76A),
                ),
                SizedBox(width: 7),
                Text(
                  'ILYF MEMBERSHIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            heading,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'Connect with professionals, grow your network and become part of the ILYF community.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.83),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _membershipTypeButton(
              'annual',
              'Annual',
              Icons.calendar_month_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _membershipTypeButton(
              'patron',
              'Patron',
              Icons.workspace_premium_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _membershipTypeButton(
    String value,
    String label,
    IconData icon,
  ) {
    final selected = _type == value;

    return InkWell(
      onTap: () => _changeType(value),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [purple, purpleDark],
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : muted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipDescription() {
    final annual = _type == 'annual';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3D9FC),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              annual
                  ? Icons.people_alt_outlined
                  : Icons.volunteer_activism_outlined,
              color: purple,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annual ? 'Annual membership' : 'Patron membership',
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  annual
                      ? 'For professionals and business owners who want directory access, events and member networking for one year.'
                      : 'For partners and sponsors who support ILYF and offer services to the community.',
                  style: const TextStyle(
                    color: muted,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Membership details',
              style: TextStyle(
                color: ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please provide the following information.',
              style: TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),

            ..._fields.map((field) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 17),
                child: _buildInput(field),
              );
            }),

            if (_errorMessage != null) ...[
              _statusMessage(
                _errorMessage!,
                const Color(0xFFFFEEF0),
                const Color(0xFFD93654),
                Icons.error_outline_rounded,
              ),
              const SizedBox(height: 16),
            ],

            if (_successMessage != null) ...[
              _statusMessage(
                _successMessage!,
                const Color(0xFFE9F8F0),
                const Color(0xFF219568),
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMembership,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: purple.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue as ${_type == 'annual' ? 'Annual' : 'Patron'} member',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(_MembershipField field) {
    final controller = _controllerFor(field.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          keyboardType: field.isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
          textCapitalization: field.isEmail
              ? TextCapitalization.none
              : TextCapitalization.words,
          validator: (value) {
            final text = value?.trim() ?? '';

            if (text.isEmpty) {
              return 'Please enter ${field.label.toLowerCase()}';
            }

            if (field.isEmail &&
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(text)) {
              return 'Please enter a valid email address';
            }

            return null;
          },
          decoration: InputDecoration(
            hintText: 'Enter ${field.label.toLowerCase()}',
            hintStyle: const TextStyle(
              color: Color(0xFFAAA5B4),
              fontSize: 13,
            ),
            filled: true,
            fillColor: const Color(0xFFFAF9FC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
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
              borderSide: const BorderSide(
                color: purple,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE5395A),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE5395A),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusMessage(
    String message,
    Color background,
    Color foreground,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      'Connect with verified professionals',
      'Discover business opportunities',
      'Access the ILYF member community',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Be part of the community',
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          ...benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF29986B),
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 13,
                      ),
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

  Widget _buildBottomNote() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          'Your information will be used for membership registration and communication.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: muted,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _MembershipField {
  final String name;
  final String label;
  final bool isEmail;

  const _MembershipField(
    this.name,
    this.label, {
    this.isEmail = false,
  });
}
