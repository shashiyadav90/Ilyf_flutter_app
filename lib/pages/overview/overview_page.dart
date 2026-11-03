import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../components/app_header.dart';
import '../../components/bottom_nav.dart';

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

  // DUMMY USER DATA
  final String userName = 'Shashank';
  final String membership = 'Lifetime Member';

  // DUMMY STORIES
  final List<Map<String, dynamic>> stories = [
    {
      'name': 'My Story',
      'initial': 'S',
      'color': Color(0xFF6C3FD1),
      'isOwn': true,
    },
    {'name': 'ILYF News', 'initial': 'I', 'color': Color(0xFFEF9B55)},
    {'name': 'Events', 'initial': 'E', 'color': Color(0xFF3E9E9A)},
    {'name': 'Members', 'initial': 'M', 'color': Color(0xFF5586D8)},
    {'name': 'Community', 'initial': 'C', 'color': Color(0xFFD16B9A)},
  ];

  // DUMMY STATISTICS
  final Map<String, dynamic> statistics = {
    'totalEnquiries': 48,
    'pendingEnquiries': 12,
    'completedEnquiries': 36,
    'totalOffers': 15,
  };

  // DUMMY WEEKLY GRAPH DATA
  final List<double> weeklyActivity = [12, 18, 10, 25, 19, 32, 27];

  final List<String> weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // DUMMY ENQUIRIES
  final List<Map<String, dynamic>> enquiries = [
    {
      'name': 'Rahul Sharma',
      'subject': 'Business Partnership',
      'date': 'Today, 10:30 AM',
      'status': 'New',
      'initial': 'R',
      'color': Color(0xFFE9DFFF),
    },
    {
      'name': 'Priya Kumar',
      'subject': 'Membership Enquiry',
      'date': 'Today, 09:15 AM',
      'status': 'In Progress',
      'initial': 'P',
      'color': Color(0xFFFFE9D9),
    },
    {
      'name': 'Arjun Reddy',
      'subject': 'Event Collaboration',
      'date': 'Yesterday',
      'status': 'Completed',
      'initial': 'A',
      'color': Color(0xFFDDF3E8),
    },
    {
      'name': 'Sneha Rao',
      'subject': 'Business Networking',
      'date': 'Yesterday',
      'status': 'New',
      'initial': 'S',
      'color': Color(0xFFFFE2EE),
    },
  ];

  // DUMMY OFFERS
  final List<Map<String, dynamic>> offers = [
    {
      'title': 'Exclusive Business Networking',
      'description': 'Connect with leading business professionals.',
      'category': 'Networking',
      'validity': 'Valid until 30 Nov 2026',
      'tag': 'FEATURED',
      'color': Color(0xFFECE4FF),
      'icon': Icons.groups_rounded,
    },
    {
      'title': 'Premium Member Benefits',
      'description': 'Special benefits for ILYF members.',
      'category': 'Member Benefits',
      'validity': 'Valid until 15 Dec 2026',
      'tag': 'NEW',
      'color': Color(0xFFFFEBDD),
      'icon': Icons.workspace_premium_rounded,
    },
    {
      'title': 'Business Growth Workshop',
      'description': 'Learn, connect and grow your business.',
      'category': 'Events',
      'validity': 'Valid until 20 Dec 2026',
      'tag': 'LIMITED',
      'color': Color(0xFFDFF3EC),
      'icon': Icons.rocket_launch_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const AppHeader(),
      bottomNavigationBar: const BottomNav(isStaff: false),

      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: purple,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 700));
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              _storiesSection(),
              _greetingSection(),
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

  // STORIES SECTION
  Widget _storiesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Community updates',
                style: TextStyle(
                  color: ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/news'),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: purple,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (context, index) {
                final story = stories[index];
                final color = story['color'] as Color;

                return GestureDetector(
                  onTap: () {
                    if (index == 1 || index == 2) {
                      context.go('/news');
                    }
                  },
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: purple, width: 2),
                          ),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: story['isOwn'] == true
                                  ? const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 27,
                                    )
                                  : Text(
                                      story['initial'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          story['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
                    'Hi, $userName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Stay connected. Keep growing.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
                          membership,
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
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 43,
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
                '${statistics['totalEnquiries']}',
                Icons.mark_email_unread_outlined,
                const Color(0xFFECE4FF),
                purple,
                '+12%',
              ),
              _statCard(
                'Pending Enquiries',
                '${statistics['pendingEnquiries']}',
                Icons.pending_actions_rounded,
                const Color(0xFFFFECDD),
                const Color(0xFFE18A42),
                'Needs attention',
              ),
              _statCard(
                'Completed',
                '${statistics['completedEnquiries']}',
                Icons.task_alt_rounded,
                const Color(0xFFDFF3E8),
                const Color(0xFF29986B),
                '+8 this month',
              ),
              _statCard(
                'Active Offers',
                '${statistics['totalOffers']}',
                Icons.local_offer_outlined,
                const Color(0xFFE3EBFF),
                const Color(0xFF4B75D1),
                'Available now',
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
                  values: weeklyActivity,
                  labels: weekdays,
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

  // ENQUIRIES SECTION
  Widget _enquiriesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 27, 18, 0),
      child: Column(
        children: [
          _sectionHeading(
            'Recent enquiries',
            'Latest messages from your community',
            action: 'View all',
            onAction: () => context.go('/'),
          ),
          const SizedBox(height: 13),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
            ),
            child: Column(
              children: enquiries.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Column(
                  children: [
                    _enquiryTile(item),
                    if (index != enquiries.length - 1)
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
    final status = item['status'] as String;

    Color statusColor;
    Color statusBackground;

    switch (status) {
      case 'New':
        statusColor = const Color(0xFF4C73D1);
        statusBackground = const Color(0xFFEAF0FF);
        break;
      case 'In Progress':
        statusColor = const Color(0xFFD48A37);
        statusBackground = const Color(0xFFFFF2DF);
        break;
      default:
        statusColor = const Color(0xFF29986B);
        statusBackground = const Color(0xFFE2F5EB);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: item['color'],
            child: Text(
              item['initial'],
              style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subject'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 5),
                Text(
                  item['date'],
                  style: const TextStyle(
                    color: Color(0xFFA29DAF),
                    fontSize: 10,
                  ),
                ),
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

  // OFFERS SECTION
  Widget _offersSection() {
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
          ...offers.map(_offerCard),
        ],
      ),
    );
  }

  Widget _offerCard(Map<String, dynamic> offer) {
    final color = offer['color'] as Color;
    final icon = offer['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
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
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: purpleDark, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer['title'],
                        style: const TextStyle(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        offer['tag'],
                        style: const TextStyle(
                          color: purpleDark,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  offer['description'],
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 9),
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
                        offer['validity'],
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/offers'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Explore',
                        style: TextStyle(
                          color: purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

// CUSTOM GRAPH PAINTER - NO EXTRA PACKAGE REQUIRED
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
    const maxValue = 40.0;

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
        text: TextSpan(text: '${40 - i * 10}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(0, y - 5));
    }

    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = left + chartWidth * i / (values.length - 1);
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
