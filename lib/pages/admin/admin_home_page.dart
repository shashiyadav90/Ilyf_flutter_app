import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const Color _background = Color(0xFFF6F7FB);
  static const Color _nav = Color(0xFF1C1930);
  static const Color _purple = Color(0xFF7252EF);
  static const Color _ink = Color(0xFF242238);
  static const Color _muted = Color(0xFF858397);
  static const Color _line = Color(0xFFECEBF2);
  static const Color _green = Color(0xFF15996A);

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _collectionsKey = GlobalKey();
  final GlobalKey _qualityKey = GlobalKey();
  final GlobalKey _membersKey = GlobalKey();
  final GlobalKey _enquiriesKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  bool get _isRoot => authService.member?.isRoot ?? false;

  String get _adminLabel => _isRoot ? 'Root Admin' : 'Chapter Admin';

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.04,
    );
  }

  void _navigate(String route) {
    context.go(route);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: _background,
          drawer: isMobile ? _buildDrawer() : null,
          body: Row(
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isMobile),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 14 : 30,
                          20,
                          isMobile ? 14 : 30,
                          30,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1500),
                            child: _buildDashboard(isMobile),
                          ),
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

  // ------------------------------------------------------------
  // SIDEBAR
  // ------------------------------------------------------------

  Widget _buildSidebar() {
    return Container(
      width: 238,
      color: _nav,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA995FF), Color(0xFF6745EE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'i',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ILYF Connect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _navLabel('WORKSPACE'),
          _navItem(
            Icons.dashboard_outlined,
            'Database overview',
            onTap: () => _scrollTo(_overviewKey),
            selected: true,
          ),
          if (_isRoot)
            _navItem(
              Icons.account_tree_outlined,
              'Chapters',
              onTap: () => _navigate('/admin/chapters'),
            ),
          _navItem(
            Icons.people_outline,
            'Members',
            onTap: () => _navigate('/members'),
          ),
          _navItem(
            Icons.business_outlined,
            'Businesses',
            onTap: () => _scrollTo(_collectionsKey),
          ),
          _navItem(
            Icons.mail_outline,
            'Enquiries',
            onTap: () => _navigate('/enquiries'),
          ),
          _navItem(
            Icons.article_outlined,
            'Content activity',
            onTap: () => _scrollTo(_contentKey),
          ),
          const SizedBox(height: 15),
          _navLabel('MONITORING'),
          _navItem(
            Icons.storage_outlined,
            'Collections',
            onTap: () => _scrollTo(_collectionsKey),
          ),
          _navItem(
            Icons.verified_outlined,
            'Data quality',
            onTap: () => _scrollTo(_qualityKey),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              'Database monitoring workspace',
              style: TextStyle(
                color: Colors.white.withOpacity(.55),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _nav,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'ILYF Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 25),
            _navLabel('WORKSPACE'),
            _drawerItem(
              Icons.dashboard_outlined,
              'Database overview',
              () => _scrollFromDrawer(_overviewKey),
            ),
            if (_isRoot)
              _drawerItem(
                Icons.account_tree_outlined,
                'Chapters',
                () => _navigate('/admin/chapters'),
              ),
            _drawerItem(
              Icons.people_outline,
              'Members',
              () => _navigate('/members'),
            ),
            _drawerItem(
              Icons.business_outlined,
              'Businesses',
              () => _scrollFromDrawer(_collectionsKey),
            ),
            _drawerItem(
              Icons.mail_outline,
              'Enquiries',
              () => _navigate('/enquiries'),
            ),
            _drawerItem(
              Icons.article_outlined,
              'Content activity',
              () => _scrollFromDrawer(_contentKey),
            ),
            const SizedBox(height: 15),
            _navLabel('MONITORING'),
            _drawerItem(
              Icons.storage_outlined,
              'Collections',
              () => _scrollFromDrawer(_collectionsKey),
            ),
            _drawerItem(
              Icons.verified_outlined,
              'Data quality',
              () => _scrollFromDrawer(_qualityKey),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollFromDrawer(GlobalKey key) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollTo(key);
    });
  }

  Widget _navLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 9),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF85819A),
          fontSize: 10,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF342E50) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white70, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      onTap: onTap,
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 30,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workspace / Monitoring',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  'Database overview',
                  style: TextStyle(
                    color: _ink,
                    fontSize: isMobile ? 19 : 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'Last 30 days  ⌄',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh, color: _muted),
            tooltip: 'Refresh dashboard',
          ),
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFE9E3FF),
            child: Text(
              _isRoot ? 'R' : 'A',
              style: const TextStyle(
                color: _purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DASHBOARD
  // ------------------------------------------------------------

  Widget _buildDashboard(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: _overviewKey,
          child: Row(
            children: [
              const Icon(Icons.circle, color: _green, size: 9),
              const SizedBox(width: 8),
              const Text(
                'Database connection status ',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const Text(
                'Healthy',
                style: TextStyle(
                  color: _green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _adminLabel,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        _responsiveGrid(
          isMobile: isMobile,
          children: [
            _kpiCard('Total members', '12,846', '+8.4%', Icons.people_outline),
            _kpiCard(
              'Business profiles',
              '2,391',
              '+5.2%',
              Icons.business_outlined,
            ),
            _kpiCard(
              'Enquiries created',
              '1,284',
              '+12.7%',
              Icons.mail_outline,
            ),
            _kpiCard(
              'Content records',
              '3,762',
              '+6.1%',
              Icons.article_outlined,
            ),
          ],
        ),
        const SizedBox(height: 17),

        _responsiveGrid(
          isMobile: isMobile,
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('Database growth'),
                  _subtitle('New records added over time'),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 205,
                    width: double.infinity,
                    child: CustomPaint(painter: _GrowthChartPainter()),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: _purple, size: 8),
                      SizedBox(width: 5),
                      Text(
                        'Current period',
                        style: TextStyle(color: _muted, fontSize: 10),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.circle, color: Color(0xFFC9C6D8), size: 8),
                      SizedBox(width: 5),
                      Text(
                        'Previous period',
                        style: TextStyle(color: _muted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('Database health'),
                  _subtitle('Operational indicators'),
                  _healthBar(
                    'Database availability',
                    '99.98%',
                    0.9998,
                    color: _green,
                  ),
                  _healthBar('Storage utilisation', '64%', .64),
                  _healthBar('Connection pool usage', '42%', .42),
                  _healthBar('Replication lag', '0.4 sec', .12, color: _green),
                  _healthBar(
                    'Failed database jobs',
                    '2',
                    .18,
                    color: const Color(0xFFE2A43C),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),

        _responsiveGrid(
          isMobile: isMobile,
          children: [
            Container(
              key: _collectionsKey,
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('Collections summary'),
                    _subtitle('Record counts by database collection'),
                    _collection(
                      'Users / Members',
                      'Member profiles and account records',
                      '12,846',
                      Icons.people_outline,
                    ),
                    _collection(
                      'Businesses',
                      'Business directory profiles',
                      '2,391',
                      Icons.business_outlined,
                    ),
                    _collection(
                      'Enquiries',
                      'Sent and received enquiries',
                      '1,284',
                      Icons.mail_outline,
                    ),
                    _collection(
                      'Offers',
                      'Published and draft offers',
                      '486',
                      Icons.local_offer_outlined,
                    ),
                    _collection(
                      'Stories, news & events',
                      'Community content records',
                      '3,276',
                      Icons.article_outlined,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              key: _qualityKey,
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('Data quality'),
                    _subtitle('Completeness checks across core records'),
                    _healthBar(
                      'Member profiles with verified phone',
                      '96.8%',
                      .968,
                      color: _green,
                    ),
                    _healthBar(
                      'Business profiles with category',
                      '91.2%',
                      .912,
                    ),
                    _healthBar('Profiles with chapter assigned', '87.5%', .875),
                    _healthBar(
                      'Duplicate records flagged',
                      '34',
                      .09,
                      color: const Color(0xFFE2A43C),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),

        _responsiveGrid(
          isMobile: isMobile,
          children: [
            Container(
              key: _membersKey,
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('Recent member records'),
                    _subtitle('Latest member activity saved in the database'),
                    _memberTable(isMobile),
                  ],
                ),
              ),
            ),
            Container(
              key: _enquiriesKey,
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('Enquiry pipeline'),
                    _subtitle('Enquiry records by current status'),
                    _healthBar('Open enquiries', '428', .68),
                    _healthBar('Responded', '612', .86, color: _green),
                    _healthBar('Closed', '244', .38),
                    _healthBar(
                      'Awaiting response over 7 days',
                      '19',
                      .08,
                      color: const Color(0xFFE2A43C),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),

        _responsiveGrid(
          isMobile: isMobile,
          children: [
            Container(
              key: _contentKey,
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('Content activity'),
                    _subtitle('Content records and publishing status'),
                    _contentTable(isMobile),
                  ],
                ),
              ),
            ),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('Recent database activity'),
                  _subtitle('Latest recorded data changes'),
                  _activity(
                    Icons.add,
                    'New member record',
                    'added to members',
                    '2 minutes ago · Members',
                  ),
                  _activity(
                    Icons.refresh,
                    'Business profile',
                    'updated',
                    '18 minutes ago · Businesses',
                  ),
                  _activity(
                    Icons.mail_outline,
                    'Enquiry status',
                    'changed to responded',
                    '34 minutes ago · Enquiries',
                  ),
                  _activity(
                    Icons.article_outlined,
                    'New story',
                    'published',
                    '1 hour ago · Stories',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'ILYF Connect · Database monitoring UI · Sample values shown until connected to live database metrics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // REUSABLE DASHBOARD WIDGETS
  // ------------------------------------------------------------

  Widget _responsiveGrid({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: child,
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth < 1050;
        if (twoColumns) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i += 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: children[i]),
                      const SizedBox(width: 16),
                      if (i + 1 < children.length)
                        Expanded(child: children[i + 1])
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _subtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 16),
      child: Text(text, style: const TextStyle(color: _muted, fontSize: 11)),
    );
  }

  Widget _kpiCard(String label, String value, String trend, IconData icon) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _purple, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '↑ $trend',
            style: const TextStyle(
              color: _green,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            'vs previous 30 days',
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _healthBar(
    String label,
    String value,
    double progress, {
    Color color = _purple,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 7,
              backgroundColor: const Color(0xFFF0EFF5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _collection(
    String title,
    String description,
    String count,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EEFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _purple, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberTable(bool isMobile) {
    final members = [
      ['Arjun Kumar', 'Bangalore', '09 Nov 2026', 'Active'],
      ['Priya Sharma', 'Mysore', '08 Nov 2026', 'Active'],
      ['Rahul N', 'Bangalore', '08 Nov 2026', 'Pending'],
      ['Meghana Rao', 'Hubli', '07 Nov 2026', 'Active'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 38,
        dataRowMinHeight: 43,
        dataRowMaxHeight: 48,
        horizontalMargin: 4,
        columnSpacing: isMobile ? 20 : 28,
        headingTextStyle: const TextStyle(
          color: _muted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: _ink, fontSize: 11),
        columns: const [
          DataColumn(label: Text('MEMBER')),
          DataColumn(label: Text('CHAPTER')),
          DataColumn(label: Text('JOINED')),
          DataColumn(label: Text('STATUS')),
        ],
        rows: members.map((member) {
          final active = member[3] == 'Active';
          return DataRow(
            cells: [
              DataCell(Text(member[0])),
              DataCell(Text(member[1])),
              DataCell(Text(member[2])),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFEAF8F1)
                        : const Color(0xFFFFF5E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member[3],
                    style: TextStyle(
                      color: active ? _green : const Color(0xFFB47B1D),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _contentTable(bool isMobile) {
    final records = [
      ['Offers', '486', '392', '94', '+42'],
      ['Stories', '1,840', '1,712', '128', '+156'],
      ['Events', '214', '178', '36', '+18'],
      ['News', '1,222', '1,104', '118', '+73'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 38,
        dataRowMinHeight: 43,
        dataRowMaxHeight: 48,
        horizontalMargin: 4,
        columnSpacing: isMobile ? 18 : 25,
        headingTextStyle: const TextStyle(
          color: _muted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: _ink, fontSize: 11),
        columns: const [
          DataColumn(label: Text('TYPE')),
          DataColumn(label: Text('TOTAL')),
          DataColumn(label: Text('PUBLISHED')),
          DataColumn(label: Text('DRAFT')),
          DataColumn(label: Text('30-DAY ADDITIONS')),
        ],
        rows: records
            .map(
              (row) => DataRow(
                cells: row.map((value) => DataCell(Text(value))).toList(),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _activity(IconData icon, String title, String action, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _purple, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: _muted, fontSize: 11),
                    children: [
                      TextSpan(
                        text: title,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' $action'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: _muted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// GROWTH CHART
// ------------------------------------------------------------

class _GrowthChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFEFEDF5)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = i * size.height / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final current = [
      .75,
      .70,
      .73,
      .59,
      .63,
      .49,
      .53,
      .39,
      .44,
      .30,
      .34,
      .21,
      .25,
      .09,
    ];

    final previous = [
      .84,
      .81,
      .78,
      .80,
      .73,
      .76,
      .68,
      .72,
      .64,
      .66,
      .58,
      .61,
      .52,
      .49,
    ];

    Offset point(int index, double value) {
      return Offset(
        index * size.width / (current.length - 1),
        value * size.height,
      );
    }

    final currentPath = Path();
    final previousPath = Path();

    for (int i = 0; i < current.length; i++) {
      final p = point(i, current[i]);
      final old = point(i, previous[i]);

      if (i == 0) {
        currentPath.moveTo(p.dx, p.dy);
        previousPath.moveTo(old.dx, old.dy);
      } else {
        currentPath.lineTo(p.dx, p.dy);
        previousPath.lineTo(old.dx, old.dy);
      }
    }

    final areaPath = Path.from(currentPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x338064FF), Color(0x008064FF)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(areaPath, areaPaint);

    canvas.drawPath(
      previousPath,
      Paint()
        ..color = const Color(0xFFC9C6D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawPath(
      currentPath,
      Paint()
        ..color = const Color(0xFF7657F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
