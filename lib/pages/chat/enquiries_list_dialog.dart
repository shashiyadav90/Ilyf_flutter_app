import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';

const Color _enquiryInk = Color(0xFF211C45);
const Color _enquiryMuted = Color(0xFF6A6685);
const Color _enquiryPurple = Color(0xFF7248E0);
const Color _enquiryLine = Color(0xFFE7E1FA);
const Color _enquiryTile = Color(0xFFF1EBFF);

class EnquiriesListDialog extends StatefulWidget {
  const EnquiriesListDialog({super.key});

  @override
  State<EnquiriesListDialog> createState() => _EnquiriesListDialogState();
}

class _EnquiriesListDialogState extends State<EnquiriesListDialog> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _enquiries = [];

  int _total = 0;
  int _limit = 10;
  int _offset = 0;

  bool _loading = true;
  String? _error;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchEnquiries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEnquiries({bool loadMore = false}) async {
    if (_loading && loadMore) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final nextOffset = loadMore ? _offset + _limit : 0;

      final response = await ApiConfig.dio.get(
        '/enquiries',
        queryParameters: {'limit': _limit, 'offset': nextOffset},
      );

      final body = response.data;

      if (body is! Map) {
        throw Exception('Unexpected enquiries response.');
      }

      final rawData = body['data'];

      final rows = rawData is List
          ? rawData
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _total = (body['total'] as num?)?.toInt() ?? 0;
        _limit = (body['limit'] as num?)?.toInt() ?? 10;
        _offset = (body['offset'] as num?)?.toInt() ?? 0;

        if (loadMore) {
          _enquiries.addAll(rows);
        } else {
          _enquiries = rows;
        }

        _loading = false;
      });
    } catch (e) {
      debugPrint('ENQUIRIES API ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load enquiries. Please try again.';
      });
    }
  }

  String _value(dynamic value, [String fallback = 'Not available']) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final date = DateTime.tryParse(value.toString());

    if (date == null) return 'Date unavailable';

    final local = date.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFF17935F);
      case 'NEW':
        return const Color(0xFFB7791F);
      case 'ASSIGNED':
        return const Color(0xFF3B63E8);
      default:
        return _enquiryPurple;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return const Color(0xFFEAF8F1);
      case 'NEW':
        return const Color(0xFFFFF5E6);
      case 'ASSIGNED':
        return const Color(0xFFEAF1FF);
      default:
        return _enquiryTile;
    }
  }

  List<Map<String, dynamic>> get _filteredEnquiries {
    final query = _searchController.text.trim().toLowerCase();

    return _enquiries.where((item) {
      final status = _value(item['status'], '').toUpperCase();

      final matchesStatus =
          _selectedStatus == 'ALL' || status == _selectedStatus;

      final searchable = [
        item['title'],
        item['category'],
        item['city'],
        item['creatorName'],
        item['receiverName'],
        item['id'],
      ].map((value) => value?.toString() ?? '').join(' ').toLowerCase();

      return matchesStatus && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _enquiryCard(Map<String, dynamic> item) {
    final status = _value(item['status'], 'UNKNOWN');
    final kind = _value(item['kind'], 'Enquiry');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _enquiryLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          childrenPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          iconColor: _enquiryPurple,
          collapsedIconColor: _enquiryMuted,

          title: Text(
            _value(item['title'], 'Untitled enquiry'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _enquiryInk,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    _statusBadge(status),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _enquiryTile,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kind.toUpperCase(),
                        style: const TextStyle(
                          color: _enquiryPurple,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _value(item['category']),
                  style: const TextStyle(
                    color: _enquiryInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_value(item['city'])}  ·  ${_formatDate(item['createdAt'])}',
                  style: const TextStyle(color: _enquiryMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9FF),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _enquiryLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ENQUIRY DETAILS',
                    style: TextStyle(
                      color: _enquiryPurple,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _detailRow('Enquiry ID', _value(item['id'])),

                  _detailRow('Category', _value(item['category'])),

                  _detailRow('City', _value(item['city'])),

                  _detailRow('Creator', _value(item['creatorName'])),

                  if (item['receiverName'] != null)
                    _detailRow('Assigned to', _value(item['receiverName'])),

                  _detailRow('Description', _value(item['description'])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: _enquiryMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          SizedBox(
            width: double.infinity,
            child: SelectableText(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: _enquiryInk,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _enquiries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _enquiryPurple),
      );
    }

    if (_error != null && _enquiries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 35,
                color: _enquiryMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _enquiryMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _fetchEnquiries,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filteredEnquiries;

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'No enquiries found.',
            style: TextStyle(color: _enquiryMuted),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        ...filtered.map(_enquiryCard),
        if (_enquiries.length < _total)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: OutlinedButton(
              onPressed: _loading
                  ? null
                  : () => _fetchEnquiries(loadMore: true),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more enquiries'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFCFBFF),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _enquiryLine),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 17, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _enquiryTile,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: _enquiryPurple,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Enquiries',
                            style: TextStyle(
                              color: _enquiryInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$_total enquiries',
                            style: const TextStyle(
                              color: _enquiryMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loading ? null : _fetchEnquiries,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: _enquiryPurple,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _enquiryLine),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search title, category or city...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _enquiryMuted,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _enquiryLine),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _enquiryLine),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final status in [
                            'ALL',
                            'OPEN',
                            'NEW',
                            'ASSIGNED',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: ChoiceChip(
                                label: Text(status == 'ALL' ? 'All' : status),
                                selected: _selectedStatus == status,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                },
                                selectedColor: _enquiryTile,
                                labelStyle: TextStyle(
                                  color: _selectedStatus == status
                                      ? _enquiryPurple
                                      : _enquiryMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                side: const BorderSide(color: _enquiryLine),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _enquiryLine),
              Expanded(child: _buildBody()),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _enquiryLine)),
                ),
                child: Text(
                  'Showing ${_enquiries.length} of $_total enquiries',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _enquiryMuted, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
