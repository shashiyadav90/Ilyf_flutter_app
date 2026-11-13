import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';

import '../../components/app_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _ink = Color(0xFF171031);
  static const _ink2 = Color(0xFF5D5778);
  static const _ink3 = Color(0xFF8D86A8);
  static const _violet = Color(0xFF6C3FD1);
  static const _violetDark = Color(0xFF4B27A3);
  static const _mist = Color(0xFFF6F3FF);
  static const _line = Color(0xFFE8E1FA);
  static const _gold = Color(0xFFE9C46A);
  static const _green = Color(0xFF17935F);

  static const _otpLength = 5;
  static const _resendSeconds = 30;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String _countryCode = '+91';
  String _countryIso = 'IN';
  String _step = 'phone';
  String _error = '';
  String _notice = '';
  bool _busy = false;
  bool _otpFocused = false;
  int _cooldown = 0;
  Timer? _timer;

  String get _digits => _phoneController.text.replaceAll(RegExp(r'\D'), '');
  String get _fullPhone => '$_countryCode$_digits';

  String get _nextRoute {
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    if (next == null || next.isEmpty) return '/members';
    return next.startsWith('/') ? next : '/members';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
      } else if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  bool _validatePhone() {
    if (_countryIso == 'IN') {
      if (_digits.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(_digits)) {
        setState(() => _error = 'Enter a valid 10-digit mobile number.');
        return false;
      }
    } else if (_digits.length < 7 || _digits.length > 15) {
      setState(() => _error = 'Enter a valid mobile number.');
      return false;
    }
    return true;
  }

  Future<void> _sendOtp({bool resend = false}) async {
    FocusScope.of(context).unfocus();
    if (!_validatePhone()) return;

    setState(() {
      _busy = true;
      _error = '';
      _notice = '';
    });

    try {
      await authService.requestOtp(_fullPhone);
      if (!mounted) return;
      setState(() {
        _step = 'otp';
        _otpController.clear();
        _notice = resend ? 'We sent you a new OTP.' : '';
      });
      _startCooldown();
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _error = _apiMessage(e, 'No membership from this number.'),
        );
      }
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not send OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    final otp = _otpController.text.replaceAll(RegExp(r'\D'), '');

    if (otp.length != _otpLength) {
      setState(() => _error = 'Enter the 5-digit OTP.');
      return;
    }

    setState(() {
      _busy = true;
      _error = '';
      _notice = '';
    });

    try {
      // IMPORTANT: Update the central authentication session.
      final member = await authService.loginWithOtp(_fullPhone, otp);

      if (!mounted) return;

      if (member == null) {
        setState(() {
          _error = 'Login failed. Please try again.';
        });
        return;
      }

      // Navigate to the originally requested page.
      context.go(_nextRoute);
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = _apiMessage(e, 'OTP verification failed.');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _apiMessage(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is Map) {
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    if (e.response?.statusCode == 404) return 'No membership from this number.';
    if (e.response?.statusCode == 401)
      return 'OTP is incorrect or has expired.';
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Unable to connect. Check your internet connection.';
    }
    return fallback;
  }

  void _changeNumber() {
    _timer?.cancel();
    setState(() {
      _step = 'phone';
      _otpController.clear();
      _error = '';
      _notice = '';
      _cooldown = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lead = _nextRoute.startsWith('/profile')
        ? 'Sign in to see your profile.'
        : 'Please sign in to continue to ILYF Connect.';

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFFC),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(68),
        child: AppHeader(),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWeb = constraints.maxWidth >= 900;

            // WEB: Login information on the left, form on the right.
            if (isWeb) {
              return LayoutBuilder(
                builder: (context, webConstraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: webConstraints.maxHeight - 64,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1250),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 5,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: _hero(lead),
                                ),
                              ),
                              const SizedBox(width: 55),
                              Expanded(
                                flex: 5,
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 460,
                                    ),
                                    child: _formCard(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            // MOBILE/TABLET: Keep the existing layout.
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _hero(lead),
                      Transform.translate(
                        offset: const Offset(0, -34),
                        child: _formCard(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _hero(String lead) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 62),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF170A3D), Color(0xFF2C1573), Color(0xFF231063)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x55421466),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x22E9C46A),
              border: Border.all(color: const Color(0x88E9C46A)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login, color: _gold, size: 15),
                SizedBox(width: 7),
                Text(
                  'Welcome to ILYF',
                  style: TextStyle(
                    color: Color(0xFFFFF1C2),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 48,
                height: 1,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: 'Sign '),
                TextSpan(
                  text: 'in',
                  style: TextStyle(fontStyle: FontStyle.italic, color: _gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            lead,
            style: const TextStyle(
              color: Color(0xC2FFFFFF),
              fontSize: 15,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _stepBar(true),
              const SizedBox(width: 6),
              _stepBar(_step == 'otp'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBar(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: active ? 52 : 36,
    height: 4,
    decoration: BoxDecoration(
      color: active ? _gold : Colors.white24,
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _formCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x334B27A3),
          blurRadius: 36,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _step == 'phone' ? _phoneForm() : _otpForm(),
    ),
  );

  Widget _phoneForm() => Column(
    key: const ValueKey('phone'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Mobile number',
        style: TextStyle(
          color: _ink2,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          _countryPicker(),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: _countryIso == 'IN' ? 10 : 15,
              onChanged: (_) {
                if (_error.isNotEmpty) setState(() => _error = '');
              },
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Mobile number',
                filled: true,
                fillColor: _mist,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                hintStyle: const TextStyle(
                  color: _ink3,
                  fontWeight: FontWeight.w500,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _line, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _violet, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
      _messages(),
      const SizedBox(height: 16),
      _primaryButton(
        label: _busy ? 'Checking…' : 'Get OTP',
        onPressed: _busy ? null : () => _sendOtp(),
      ),
      const SizedBox(height: 14),
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, color: _green, size: 14),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'We’ll send a one-time code to this number.',
              style: TextStyle(color: _ink3, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      GestureDetector(
        onTap: () {
          context.push('/membership?next=${Uri.encodeComponent(_nextRoute)}');
        },
        child: const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'New to ILYF? ',
                style: TextStyle(color: _ink2, fontSize: 13),
              ),
              TextSpan(
                text: 'Become a member',
                style: TextStyle(
                  color: _violet,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: _violet,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );

  Widget _countryPicker() => InkWell(
    onTap: _busy ? null : _showCountryPicker,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _mist,
        border: Border.all(color: _line, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _countryIso == 'IN' ? '🇮🇳' : '🌐',
            style: const TextStyle(fontSize: 19),
          ),
          const SizedBox(width: 6),
          Text(
            _countryCode,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
          const Icon(Icons.keyboard_arrow_down, color: _ink3, size: 18),
        ],
      ),
    ),
  );

  Future<void> _showCountryPicker() async {
    final countries = [
      {'iso': 'IN', 'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
      {'iso': 'US', 'code': '+1', 'name': 'United States', 'flag': '🇺🇸'},
      {'iso': 'GB', 'code': '+44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
      {'iso': 'SG', 'code': '+65', 'name': 'Singapore', 'flag': '🇸🇬'},
      {
        'iso': 'AE',
        'code': '+971',
        'name': 'United Arab Emirates',
        'flag': '🇦🇪',
      },
    ];
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Select country code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            ...countries.map(
              (item) => ListTile(
                leading: Text(
                  item['flag']!,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(item['name']!),
                trailing: Text(item['code']!),
                onTap: () => Navigator.pop(context, item),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _countryIso = selected['iso']!;
      _countryCode = selected['code']!;
      _phoneController.clear();
      _error = '';
    });
  }

  Widget _otpForm() {
    final value = _otpController.text.replaceAll(RegExp(r'\D'), '');
    final boxes = List.generate(_otpLength, (index) {
      final filled = index < value.length;
      final active =
          _otpFocused && index == value.length.clamp(0, _otpLength - 1);
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          decoration: BoxDecoration(
            color: filled ? Colors.white : _mist,
            border: Border.all(
              color: active
                  ? _violet
                  : filled
                  ? const Color(0xFFCFC2F3)
                  : _line,
              width: active ? 1.8 : 1.4,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x226C3FD1),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            filled ? value[index] : '',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ),
      );
    });

    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _mist,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.phone_iphone,
                  color: _violetDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: _ink2,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Enter the OTP for\n'),
                      TextSpan(
                        text: _fullPhone,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15.5,
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
        const SizedBox(height: 18),
        const Text(
          'OTP',
          style: TextStyle(
            color: _ink2,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < boxes.length; i++) ...[
                  boxes[i],
                  if (i != boxes.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            Positioned.fill(
              child: Focus(
                onFocusChange: (focused) =>
                    setState(() => _otpFocused = focused),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: _otpLength,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {
                    _error = '';
                    _notice = '';
                  }),
                ),
              ),
            ),
          ],
        ),
        _messages(),
        const SizedBox(height: 16),
        _primaryButton(
          label: _busy ? 'Verifying…' : 'Verify OTP',
          onPressed: _busy ? null : _verifyOtp,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _busy ? null : _changeNumber,
              icon: const Icon(Icons.edit_outlined, size: 15),
              label: const Text('Change number'),
              style: TextButton.styleFrom(foregroundColor: _violet),
            ),
            if (_cooldown > 0)
              Text(
                'Resend OTP in ${_cooldown}s',
                style: const TextStyle(
                  color: _ink3,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              TextButton.icon(
                onPressed: _busy ? null : () => _sendOtp(resend: true),
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Resend OTP'),
                style: TextButton.styleFrom(foregroundColor: _violet),
              ),
          ],
        ),
      ],
    );
  }

  Widget _messages() {
    if (_error.isEmpty && _notice.isEmpty) return const SizedBox.shrink();
    final hasError = _error.isNotEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFF1F5) : const Color(0xFFEFFAF4),
        border: Border.all(
          color: hasError ? const Color(0xFFFFC9D9) : const Color(0xFFC3ECD5),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.check_circle_outline,
            size: 17,
            color: hasError ? const Color(0xFFA3173F) : const Color(0xFF0F6B44),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasError ? _error : _notice,
              style: TextStyle(
                color: hasError
                    ? const Color(0xFFA3173F)
                    : const Color(0xFF0F6B44),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: double.infinity,
    height: 56,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B4DE0), Color(0xFF5A34C6), Color(0xFF3B63E8)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x554B27A3),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_busy) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    ),
  );

  Widget _joinCard() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF170A3D), Color(0xFF2C1573)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55421466),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New to ILYF?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Georgia',
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Join the member directory.',
                style: TextStyle(color: Color(0xBFFFFFFF), fontSize: 13),
              ),
            ],
          ),
        ),
        Flexible(
          child: TextButton(
            onPressed: () {
              context.push(
                '/membership?next=${Uri.encodeComponent(_nextRoute)}',
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF2A1A00),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Become a member  →',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ),
  );
}
