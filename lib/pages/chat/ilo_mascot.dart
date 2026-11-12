import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

enum IloMood {
  idle,
  greet,
  listening,
  thinking,
  searching,
  speaking,
  happy,
  celebrate,
  surprised,
  confused,
  oops,
  sleepy,
}

const Color _ink = Color(0xFF2A1B5C);
const Color _cream = Color(0xFFFFF3D1);
const Color _plateTop = Color(0xFF35236F);
const Color _plateBottom = Color(0xFF1C1144);
const Color _lid = Color(0xFF2B1C5E);
const Color _amber = Color(0xFFFFB24D);
const Color _coral = Color(0xFFFF7A59);
const Color _mint = Color(0xFF2FD2A0);
const Color _violet = Color(0xFF6C3FD1);
const Color _violetLight = Color(0xFF8B5CF6);
const Color _blue = Color(0xFF5B8CFF);
const Color _gold = Color(0xFFFFD24D);
const Color _red = Color(0xFFFF5470);
const Color _dim = Color(0xFFA79FD0);
const Color _blush = Color(0xFFFF8FA3);
const Color _mouthFill = Color(0xFFFF6F8E);
const Color _armColor = Color(0xFFFF9A5A);
const Color _handColor = Color(0xFFFFD27A);

const List<Color> _confettiColors = [
  Color(0xFFFFB24D),
  Color(0xFFFF7A59),
  Color(0xFF2FD2A0),
  Color(0xFF8B5CF6),
  Color(0xFFFFD24D),
  Color(0xFF5B8CFF),
];

// Resting pose. Every mood only lists what differs from it.
const Map<String, double> _base = {
  'eyeL': 1,
  'eyeR': 1,
  'lid': 0,
  'happy': 0,
  'bLy': 0,
  'bLr': 0,
  'bRy': 0,
  'bRr': 0,
  'mW': 22,
  'mC': 0.55,
  'mO': 0,
  'mWave': 0,
  'mX': 0,
  'cheeks': 0.38,
  'armL': 14,
  'armR': -14,
  'tilt': 0,
  'hop': 0,
  'breathe': 1,
};

typedef _Anim = void Function(double t, Map<String, double> g);

class _Spec {
  _Spec({
    this.follow = 1,
    this.bulb,
    this.props = const <String>{},
    this.t = const <String, double>{},
    this.anim,
  });

  final double follow;
  final Color? bulb;
  final Set<String> props;
  final Map<String, double> t;
  final _Anim? anim;
}

final Map<IloMood, _Spec> _specs = {
  IloMood.idle: _Spec(bulb: _mint),
  IloMood.greet: _Spec(
    follow: 0.8,
    bulb: _mint,
    props: {'spark'},
    t: {
      'mC': 1,
      'mO': 0.3,
      'cheeks': 0.8,
      'bLy': -3,
      'bRy': -3,
      'armR': -130,
      'eyeL': 1.05,
      'eyeR': 1.05,
    },
    anim: (t, g) {
      g['armR'] = -128 + math.sin(t * 8) * 18;
      g['tilt'] = math.sin(t * 3) * 2;
    },
  ),
  IloMood.listening: _Spec(
    bulb: _mint,
    props: {'wavesL', 'wavesR'},
    t: {
      'eyeL': 1.14,
      'eyeR': 1.14,
      'bLy': -7,
      'bRy': -7,
      'mC': 0.15,
      'mW': 11,
      'mO': 0.16,
      'tilt': -5,
      'cheeks': 0.45,
    },
  ),
  IloMood.thinking: _Spec(
    follow: 0,
    bulb: _violetLight,
    props: {'think'},
    t: {
      'lookX': 0.7,
      'lookY': -0.85,
      'bLy': -10,
      'bLr': -8,
      'bRy': 2,
      'bRr': 8,
      'mC': 0,
      'mW': 9,
      'mX': 12,
      'tilt': 5,
      'armR': 62,
      'eyeL': 0.95,
      'eyeR': 0.95,
      'cheeks': 0.2,
    },
    anim: (t, g) {
      g['tilt'] = 5 + math.sin(t * 1.8) * 2;
    },
  ),
  IloMood.searching: _Spec(
    follow: 0,
    bulb: _blue,
    props: {'mag'},
    t: {'lookY': -0.05, 'bLy': -5, 'bRy': -5, 'mC': 0.1, 'mW': 12, 'mO': 0.14},
    anim: (t, g) {
      g['lookX'] = math.sin(t * 2.4) * 0.95;
      g['tilt'] = math.sin(t * 2.4) * 3;
    },
  ),
  IloMood.speaking: _Spec(
    follow: 0.7,
    bulb: _mint,
    props: {'wavesR'},
    t: {'mC': 0.55, 'mW': 20, 'bLy': -3, 'bRy': -3, 'cheeks': 0.5},
    anim: (t, g) {
      g['mO'] =
          0.1 + (0.5 + 0.5 * math.sin(t * 14 + math.sin(t * 3) * 2)) * 0.55;
      g['tilt'] = math.sin(t * 3.2) * 2.5;
      g['bRy'] = -3 + math.sin(t * 6) * 2;
    },
  ),
  IloMood.happy: _Spec(
    follow: 0.3,
    bulb: _gold,
    props: {'spark'},
    t: {
      'happy': 1,
      'mC': 1.1,
      'mO': 0.55,
      'mW': 30,
      'cheeks': 1,
      'armL': 150,
      'armR': -150,
      'hop': 0.55,
    },
  ),
  IloMood.celebrate: _Spec(
    follow: 0.2,
    props: {'spark'},
    t: {
      'happy': 1,
      'mC': 1.2,
      'mO': 0.7,
      'mW': 32,
      'cheeks': 1,
      'armL': 155,
      'armR': -155,
      'hop': 1,
    },
  ),
  IloMood.surprised: _Spec(
    follow: 0.6,
    bulb: _amber,
    props: {'bang'},
    t: {
      'eyeL': 1.32,
      'eyeR': 1.32,
      'bLy': -13,
      'bRy': -13,
      'mC': 0,
      'mW': 9,
      'mO': 0.95,
      'armL': 42,
      'armR': -42,
      'cheeks': 0.15,
    },
  ),
  IloMood.confused: _Spec(
    follow: 0.4,
    bulb: _coral,
    props: {'qmark'},
    t: {
      'eyeL': 1.18,
      'eyeR': 0.92,
      'bLy': -9,
      'bLr': -8,
      'bRy': 3,
      'bRr': -10,
      'mC': -0.1,
      'mW': 15,
      'mWave': 1,
      'tilt': 7,
      'armL': 152,
      'cheeks': 0.15,
    },
    anim: (t, g) {
      g['tilt'] = 7 + math.sin(t * 2) * 2;
    },
  ),
  IloMood.oops: _Spec(
    follow: 0.2,
    bulb: _red,
    props: {'sweat'},
    t: {
      'bLr': -17,
      'bRr': 17,
      'bLy': 2,
      'bRy': 2,
      'mC': -0.95,
      'mW': 17,
      'cheeks': 0.05,
      'armL': 4,
      'armR': -4,
      'tilt': -3,
      'breathe': 0.4,
      'eyeL': 0.95,
      'eyeR': 0.95,
    },
  ),
  IloMood.sleepy: _Spec(
    follow: 0.1,
    bulb: _dim,
    props: {'zzz'},
    t: {
      'lid': 0.62,
      'mC': 0,
      'mW': 10,
      'cheeks': 0.3,
      'armL': 6,
      'armR': -6,
      'tilt': 6,
      'breathe': 1.6,
    },
    anim: (t, g) {
      g['lid'] = 0.55 + 0.25 * math.sin(t * 0.9);
      final y = math.max(0.0, math.sin(t * 0.55));
      final y3 = y * y * y;
      g['mO'] = y3 * 0.85;
      g['mW'] = 10 + y3 * 6;
      g['mC'] = -0.1 * y;
    },
  ),
};

const List<String> _propNames = [
  'spark',
  'wavesL',
  'wavesR',
  'think',
  'mag',
  'qmark',
  'bang',
  'sweat',
  'zzz',
];

// ---------------------------------------------------------------------------
// Engine: smooths the pose toward the current mood and runs the physics.
// ---------------------------------------------------------------------------
class _Part {
  double x = 0, y = 0, vx = 0, vy = 0, rot = 0, vr = 0, life = 0, max = 1;
  Color color = Colors.white;
}

class _IloEngine extends ChangeNotifier {
  _IloEngine() {
    for (var i = 0; i < 30; i++) {
      parts.add(_Part());
    }
    for (final n in _propNames) {
      propV[n] = 0;
    }
  }

  IloMood mood = IloMood.idle;
  _Spec spec = _specs[IloMood.idle]!;
  Map<String, double> target = {..._base};
  final Map<String, double> cur = {..._base, 'lookX': 0, 'lookY': 0};
  final Map<String, double> propV = {};
  final List<_Part> parts = [];
  Color bulb = _mint;

  Offset? pointer; // normalised -1..1 relative to the mascot, or null
  double t = 0;
  double motion = 1; // 0.25 when the user asked for reduced motion
  double pk = 0; // poke spring position
  double pv = 0; // poke spring velocity
  double open = 1; // blink amount applied to the eyes
  double _last = -1;
  double _blinkAt = 2;
  double _blinkStart = -9;
  final math.Random _rand = math.Random();

  void setMood(IloMood m) {
    mood = m;
    spec = _specs[m]!;
    target = {..._base, ...spec.t};
    if (m == IloMood.surprised) pv += 9;
    if (m == IloMood.celebrate) _burst();
  }

  void poke() => pv += 7;

  void _burst() {
    for (final p in parts) {
      p.x = 200 + (_rand.nextDouble() - 0.5) * 60;
      p.y = 190;
      p.vx = (_rand.nextDouble() - 0.5) * 520;
      p.vy = -200 - _rand.nextDouble() * 260;
      p.rot = _rand.nextDouble() * 360;
      p.vr = (_rand.nextDouble() - 0.5) * 1040;
      p.life = 1.2 + _rand.nextDouble() * 0.8;
      p.max = p.life;
      p.color = _confettiColors[_rand.nextInt(_confettiColors.length)];
    }
  }

  void tick(double now) {
    final dt = _last < 0 ? 0.016 : (now - _last).clamp(0.0, 0.05).toDouble();
    _last = now;
    t = now;

    final g = {...target};
    spec.anim?.call(t, g);
    final px = pointer?.dx ?? math.sin(t * 0.55) * 0.3;
    final py =
        pointer?.dy ??
        (mood == IloMood.listening ? 0.5 : math.sin(t * 0.4) * 0.12);
    g['lookX'] = g['lookX'] ?? px * spec.follow;
    g['lookY'] = g['lookY'] ?? py * spec.follow;

    final k = 1 - math.exp(-dt * 13);
    g.forEach((key, v) {
      final c = cur[key] ?? v;
      cur[key] = c + (v - c) * k;
    });

    // blink
    if (t > _blinkAt && cur['lid']! < 0.2 && cur['happy']! < 0.5) {
      _blinkStart = t;
      _blinkAt = t + 2.4 + _rand.nextDouble() * 2.8;
    }
    final blink = math.sin(
      math.pi * ((t - _blinkStart) / 0.16).clamp(0.0, 1.0),
    );
    open = 1 - blink * 0.92;

    // poke spring
    pv += (-170 * pk - 11 * pv) * dt;
    pk += pv * dt;

    // antenna light
    final tb =
        spec.bulb ?? _confettiColors[(t * 5).floor() % _confettiColors.length];
    bulb = Color.lerp(bulb, tb, k) ?? tb;

    // props fade in and out
    for (final n in _propNames) {
      final want = spec.props.contains(n) ? 1.0 : 0.0;
      final v = propV[n] ?? 0;
      propV[n] = v + (want - v) * k;
    }

    // confetti
    for (final p in parts) {
      if (p.life <= 0) continue;
      p.life -= dt;
      p.vy += 900 * dt;
      p.vx *= 1 - 0.8 * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.vr * dt;
    }

    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------
class IloMascot extends StatefulWidget {
  const IloMascot({
    super.key,
    required this.size,
    this.mood = IloMood.idle,
    this.pointer,
    this.onTap,
    this.semanticLabel = 'Ilo, your AI assistant',
  });

  /// Width and height of the whole drawing, rings included.
  final double size;
  final IloMood mood;

  /// Global pointer position the eyes should follow (null = look around idly).
  final ValueListenable<Offset?>? pointer;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  State<IloMascot> createState() => _IloMascotState();
}

class _IloMascotState extends State<IloMascot>
    with SingleTickerProviderStateMixin {
  final _IloEngine _engine = _IloEngine();
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _engine.setMood(widget.mood);
    _ticker = createTicker((elapsed) {
      _syncPointer();
      _engine.tick(elapsed.inMicroseconds / 1e6);
    })..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _engine.motion = MediaQuery.of(context).disableAnimations ? 0.25 : 1;
  }

  @override
  void didUpdateWidget(IloMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) _engine.setMood(widget.mood);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _syncPointer() {
    final p = widget.pointer?.value;
    final ro = context.findRenderObject();
    if (p == null || ro is! RenderBox || !ro.attached || !ro.hasSize) {
      _engine.pointer = null;
      return;
    }
    final c = ro.localToGlobal(ro.size.center(Offset.zero));
    _engine.pointer = Offset(
      ((p.dx - c.dx) / 380).clamp(-1.0, 1.0).toDouble(),
      ((p.dy - c.dy) / 380).clamp(-1.0, 1.0).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _engine.poke();
          widget.onTap?.call();
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: ExcludeSemantics(
            child: CustomPaint(painter: _IloPainter(_engine)),
          ),
        ),
      ),
    );
  }
}

/// A small, still version of Ilo's face for chat bubbles.
class IloAvatar extends StatelessWidget {
  const IloAvatar({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _AvatarPainter()),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.shortestSide / 100);
    const c = Offset(50, 52);
    canvas.drawCircle(
      c,
      44,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(36, 34),
          70,
          const [Color(0xFFFFF3C9), Color(0xFFFFC25E), Color(0xFFFF7A59)],
          const [0, 0.4, 1],
        ),
    );
    final plate = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 36, 60, 38),
      const Radius.circular(19),
    );
    canvas.drawRRect(plate, Paint()..color = _plateTop);
    final eye = Paint()..color = _cream;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(37, 52), width: 9, height: 12),
      eye,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(63, 52), width: 9, height: 12),
      eye,
    );
    canvas.drawPath(
      Path()
        ..moveTo(42, 63)
        ..quadraticBezierTo(50, 70, 58, 63),
      Paint()
        ..color = _cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(52, 5), 4, Paint()..color = _mint);
    canvas.drawLine(
      const Offset(50, 9),
      const Offset(52, 8),
      Paint()
        ..color = _ink
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Painter (everything is drawn in a 400 x 400 space)
// ---------------------------------------------------------------------------
final Map<String, TextPainter> _textCache = {};

class _IloPainter extends CustomPainter {
  _IloPainter(this.e) : super(repaint: e);

  final _IloEngine e;

  static final Path _star = Path()
    ..moveTo(0, -10)
    ..quadraticBezierTo(2, -2, 10, 0)
    ..quadraticBezierTo(2, 2, 0, 10)
    ..quadraticBezierTo(-2, 2, -10, 0)
    ..quadraticBezierTo(-2, -2, 0, -10)
    ..close();

  @override
  bool shouldRepaint(covariant _IloPainter oldDelegate) => oldDelegate.e != e;

  double _c(String key) => e.cur[key] ?? 0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.shortestSide / 400);

    final t = e.t;
    final m = e.motion;
    _aura(canvas, t, m);

    final hopS = math.sin(t * 6.2).abs();
    final hopY = -hopS * 20 * _c('hop') * m;
    final floatY = math.sin(t * 1.6) * 4 * _c('breathe') * m;
    final sx =
        1 +
        e.pk * 0.1 -
        hopS * 0.03 * _c('hop') +
        math.sin(t * 2) * 0.008 * _c('breathe') * m;
    final sy =
        1 -
        e.pk * 0.1 +
        hopS * 0.045 * _c('hop') +
        math.sin(t * 2) * 0.01 * _c('breathe') * m;
    final lift = (1 + (hopY + floatY) / 90).clamp(0.7, 1.2).toDouble();

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(200, 346),
        width: 168 * lift,
        height: 22,
      ),
      Paint()..color = _ink.withValues(alpha: 0.2 * lift),
    );

    canvas.save();
    canvas.translate(0, hopY + floatY);
    canvas.translate(200, 332);
    canvas.rotate(_c('tilt') * math.pi / 180);
    canvas.scale(sx, sy);
    canvas.translate(-200, -332);

    _antenna(canvas, t);
    _body(canvas);
    _face(canvas, t);
    _arm(canvas, const Offset(96, 228), _c('armL'));
    _arm(canvas, const Offset(304, 228), _c('armR'));
    _props(canvas, t);
    canvas.restore();

    _confetti(canvas);
    canvas.restore();
  }

  void _aura(Canvas canvas, double t, double m) {
    const c = Offset(200, 200);
    canvas.drawCircle(
      c,
      192,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          192,
          [
            _violetLight.withValues(alpha: 0),
            _violetLight.withValues(alpha: 0.16),
          ],
          const [0.72, 1],
        ),
    );
    canvas.drawCircle(
      c,
      192,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _violetLight.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      c,
      158,
      Paint()..color = _violetLight.withValues(alpha: 0.05),
    );
    canvas.drawCircle(
      c,
      158,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _violetLight.withValues(alpha: 0.2),
    );

    void dot(double angle, double radius, double r) {
      final p = c + Offset(math.sin(angle) * radius, -math.cos(angle) * radius);
      canvas.drawCircle(p, r, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _violetLight.withValues(alpha: 0.5),
      );
    }

    dot(t * 2 * math.pi / 16 * m, 192, 5);
    dot(-t * 2 * math.pi / 11 * m, 158, 4);
  }

  void _antenna(Canvas canvas, double t) {
    canvas.save();
    canvas.translate(200, 106);
    canvas.rotate((math.sin(t * 2.2) * 5 + e.pk * -10) * math.pi / 180);
    canvas.translate(-200, -106);
    canvas.drawPath(
      Path()
        ..moveTo(200, 106)
        ..cubicTo(200, 86, 209, 78, 211, 66),
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final r = 10 + math.sin(t * (e.mood == IloMood.sleepy ? 1 : 5)) * 1.6;
    canvas.drawCircle(
      const Offset(211, 56),
      r + 3,
      Paint()
        ..color = e.bulb.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(const Offset(211, 56), r, Paint()..color = e.bulb);
    canvas.restore();
  }

  void _body(Canvas canvas) {
    const center = Offset(200, 214);
    canvas.drawCircle(
      center,
      118,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(164.2, 157.4),
          224,
          const [Color(0xFFFFF3C9), Color(0xFFFFC25E), Color(0xFFFF7A59)],
          const [0, 0.4, 1],
        ),
    );
    canvas.save();
    canvas.translate(154, 146);
    canvas.rotate(-28 * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 96, height: 52),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
    canvas.restore();
    canvas.drawCircle(
      center,
      117,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _face(Canvas canvas, double t) {
    final lx = _c('lookX');
    final ly = _c('lookY');
    canvas.save();
    canvas.translate(lx * 5, ly * 3.5);

    const plateRect = Rect.fromLTWH(116, 150, 168, 114);
    final plate = RRect.fromRectAndRadius(plateRect, const Radius.circular(54));
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 150),
          const Offset(0, 264),
          const [_plateTop, _plateBottom],
        ),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    final cheek = Paint()
      ..color = _blush.withValues(
        alpha: (_c('cheeks') * 0.75).clamp(0.0, 1.0).toDouble(),
      );
    canvas.drawCircle(const Offset(139, 231), 11, cheek);
    canvas.drawCircle(const Offset(261, 231), 11, cheek);

    _eye(canvas, 166, _c('eyeL'), lx, ly);
    _eye(canvas, 234, _c('eyeR'), lx, ly);
    _brow(canvas, 166, 168 + _c('bLy'), _c('bLr'));
    _brow(canvas, 234, 168 + _c('bRy'), _c('bRr'));
    _mouth(canvas);
    canvas.restore();
  }

  void _eye(Canvas canvas, double cx, double size, double lx, double ly) {
    final happy = _c('happy');
    final lid = _c('lid');
    final rx = 15 * size;
    final ry = math.max(0.5, 19 * size * e.open);
    final opacity = 1 - happy;

    canvas.save();
    canvas.translate(cx, 198);

    if (opacity > 0.02) {
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: rx * 2,
        height: ry * 2,
      );
      final layered = opacity < 0.98;
      if (layered) {
        canvas.saveLayer(
          Rect.fromCenter(center: Offset.zero, width: 90, height: 100),
          Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
        );
      }
      canvas.drawOval(
        rect.inflate(2),
        Paint()
          ..color = _cream.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      canvas.drawOval(rect, Paint()..color = _cream);
      canvas.drawCircle(
        Offset(lx * 6, ly * 5),
        7.5 * size,
        Paint()..color = _amber,
      );
      canvas.drawCircle(
        Offset(-5 + lx * 2, -7 + ly * 2),
        4,
        Paint()..color = Colors.white,
      );
      if (lid > 0.01) {
        canvas.drawRect(
          Rect.fromLTWH(-rx - 3, -ry - 2, 2 * rx + 6, lid * 2 * ry + 2),
          Paint()..color = _lid,
        );
      }
      canvas.restore();
      if (layered) canvas.restore();
    }

    if (happy > 0.02) {
      canvas.drawPath(
        Path()
          ..moveTo(-15, 6)
          ..quadraticBezierTo(0, -16, 15, 6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = _cream.withValues(alpha: happy.clamp(0.0, 1.0).toDouble()),
      );
    }
    canvas.restore();
  }

  void _brow(Canvas canvas, double x, double y, double rotDeg) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotDeg * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -2.5, 26, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = _cream.withValues(alpha: 0.9),
    );
    canvas.restore();
  }

  void _mouth(Canvas canvas) {
    final w = _c('mW');
    final x = _c('mX');
    final a = _c('mC') * 18;
    final wave = _c('mWave');
    final u1 = a * 1.33 - wave * 12;
    final u2 = a * 1.33 + wave * 12;
    final d = math.max(0.0, _c('mO')) * 30;
    final path = Path()
      ..moveTo(x - w, 0)
      ..cubicTo(x - w / 3, u1, x + w / 3, u2, x + w, 0)
      ..cubicTo(x + w / 3, u2 + d, x - w / 3, u1 + d, x - w, 0)
      ..close();
    canvas.save();
    canvas.translate(200, 240);
    final fill = (_c('mO') * 9).clamp(0.0, 1.0).toDouble();
    if (fill > 0.01) {
      canvas.drawPath(
        path,
        Paint()..color = _mouthFill.withValues(alpha: fill),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = _cream,
    );
    canvas.restore();
  }

  void _arm(Canvas canvas, Offset shoulder, double angleDeg) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(angleDeg * math.pi / 180);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12, -6, 24, 56),
        const Radius.circular(12),
      ),
      Paint()..color = _armColor,
    );
    canvas.drawCircle(const Offset(0, 52), 15, Paint()..color = _handColor);
    canvas.drawCircle(
      const Offset(0, 52),
      15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.45),
    );
    canvas.restore();
  }

  // ---- props ----
  void _withAlpha(Canvas canvas, double a, VoidCallback draw) {
    if (a < 0.01) return;
    if (a > 0.99) {
      draw();
      return;
    }
    canvas.saveLayer(
      const Rect.fromLTWH(-60, -60, 520, 520),
      Paint()..color = Color.fromRGBO(255, 255, 255, a),
    );
    draw();
    canvas.restore();
  }

  void _glyph(
    Canvas canvas,
    String s,
    double size,
    Color color,
    Offset base, {
    double rot = 0,
    double scale = 1,
  }) {
    final tp = _textCache.putIfAbsent(
      '$s|$size|${color.hashCode}',
      () => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    final baseline = tp.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(rot);
    canvas.scale(scale);
    tp.paint(canvas, Offset(-tp.width / 2, -baseline));
    canvas.restore();
  }

  void _props(Canvas canvas, double t) {
    double v(String n) => e.propV[n] ?? 0;

    _withAlpha(canvas, v('spark'), () {
      const stars = [
        [86.0, 122.0, 1.1],
        [318.0, 112.0, 1.4],
        [52.0, 250.0, 0.9],
        [350.0, 244.0, 1.0],
        [130.0, 62.0, 0.8],
        [286.0, 58.0, 0.9],
      ];
      const colors = [_amber, _mint, _violetLight, _coral, _gold, _violetLight];
      for (var i = 0; i < stars.length; i++) {
        final tw = 0.4 + 0.7 * (0.5 + 0.5 * math.sin(t * 5.7 + i * 1.1));
        canvas.save();
        canvas.translate(stars[i][0], stars[i][1]);
        canvas.scale(stars[i][2] * tw);
        canvas.drawPath(_star, Paint()..color = colors[i]);
        canvas.restore();
      }
    });

    _withAlpha(canvas, v('think'), () {
      const dots = [
        [262.0, 130.0, 4.0],
        [278.0, 110.0, 6.0],
        [302.0, 80.0, 10.0],
      ];
      for (var i = 0; i < dots.length; i++) {
        final s = 0.7 + 0.4 * (0.5 + 0.5 * math.sin(t * 4.8 - i * 1.2));
        final p = Offset(dots[i][0], dots[i][1]);
        canvas.drawCircle(p, dots[i][2] * s, Paint()..color = Colors.white);
        canvas.drawCircle(
          p,
          dots[i][2] * s,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = _violetLight.withValues(alpha: 0.5),
        );
      }
    });

    void waves(List<String> paths, double side) {
      for (var i = 0; i < 2; i++) {
        final a = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * 5.2 - i * 1.4));

        final path = Path();

        if (side < 0) {
          if (i == 0) {
            path
              ..moveTo(64, 188)
              ..quadraticBezierTo(50, 214, 64, 240);
          } else {
            path
              ..moveTo(44, 168)
              ..quadraticBezierTo(20, 214, 44, 260);
          }
        } else {
          if (i == 0) {
            path
              ..moveTo(336, 188)
              ..quadraticBezierTo(350, 214, 336, 240);
          } else {
            path
              ..moveTo(356, 168)
              ..quadraticBezierTo(380, 214, 356, 260);
          }
        }

        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..color = _mint.withValues(alpha: a),
        );
      }
    }

    _withAlpha(canvas, v('wavesL'), () => waves(const [], -1));
    _withAlpha(canvas, v('wavesR'), () => waves(const [], 1));

    _withAlpha(canvas, v('mag'), () {
      canvas.save();
      canvas.translate(310, 150);
      canvas.rotate(math.sin(t * 3.9) * 15 * math.pi / 180);
      canvas.translate(-310, -150);
      canvas.drawCircle(
        const Offset(318, 142),
        20,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = _violet;
      canvas.drawCircle(const Offset(318, 142), 20, stroke..strokeWidth = 6);
      canvas.drawLine(
        const Offset(332, 157),
        const Offset(350, 176),
        stroke..strokeWidth = 8,
      );
      canvas.restore();
    });

    _withAlpha(canvas, v('qmark'), () {
      _glyph(
        canvas,
        '?',
        68,
        _violet,
        const Offset(288, 120),
        rot: math.sin(t * 4.2) * 8 * math.pi / 180,
        scale: 1 + 0.04 * math.sin(t * 4.2),
      );
    });

    _withAlpha(canvas, v('bang'), () {
      _glyph(
        canvas,
        '!',
        68,
        _coral,
        const Offset(286, 118),
        rot: math.sin(t * 12) * 8 * math.pi / 180,
        scale: 1 + 0.05 * math.sin(t * 12),
      );
    });

    _withAlpha(canvas, v('sweat'), () {
      final phase = (t % 1.6) / 1.6;
      canvas.save();
      canvas.translate(0, phase * 16);
      final drop = Path()
        ..moveTo(284, 150)
        ..relativeQuadraticBezierTo(-10, 15, 0, 22)
        ..relativeQuadraticBezierTo(10, -7, 0, -22)
        ..close();
      final fade = phase < 0.8 ? 1.0 : (1 - phase) / 0.2;
      canvas.drawPath(
        drop,
        Paint()..color = const Color(0xFF8FD8FF).withValues(alpha: fade),
      );
      canvas.drawPath(
        drop,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = _ink.withValues(alpha: fade),
      );
      canvas.restore();
    });

    _withAlpha(canvas, v('zzz'), () {
      const zs = [
        [272.0, 130.0, 24.0],
        [294.0, 102.0, 32.0],
        [318.0, 70.0, 40.0],
      ];
      for (var i = 0; i < zs.length; i++) {
        final phase = ((t + i * 0.85) % 2.6) / 2.6;
        final alpha = math.sin(math.pi * phase);
        _glyph(
          canvas,
          'z',
          zs[i][2],
          _violet.withValues(alpha: alpha.clamp(0.0, 1.0).toDouble()),
          Offset(zs[i][0] + zs[i][2] * 0.2, zs[i][1] + 8 - 30 * phase),
        );
      }
    });
  }

  void _confetti(Canvas canvas) {
    for (final p in e.parts) {
      if (p.life <= 0) continue;
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot * math.pi / 180);
      final a = (p.life / p.max * 1.6).clamp(0.0, 1.0).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 9, height: 6),
          const Radius.circular(1.5),
        ),
        Paint()..color = p.color.withValues(alpha: a),
      );
      canvas.restore();
    }
  }
}
