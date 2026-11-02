class MemberSession {
  final String id;
  final String phone;
  final String? role;
  final String kind;
  final String? status;
  final String? chapterId;
  final Map<String, dynamic>? listing;
  final DateTime loggedInAt;

  const MemberSession({
    required this.id,
    required this.phone,
    this.role,
    this.kind = 'member',
    this.status,
    this.chapterId,
    this.listing,
    required this.loggedInAt,
  });

  factory MemberSession.fromJson(Map<String, dynamic> json) {
    return MemberSession(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString(),
      kind: json['kind']?.toString() ?? 'member',
      status: json['status']?.toString(),
      chapterId: json['chapterId']?.toString(),
      listing: json['listing'] is Map
          ? Map<String, dynamic>.from(json['listing'])
          : null,
      loggedInAt: DateTime.now(),
    );
  }

  bool get isRoot => kind == 'root' || role == 'SUPER_ADMIN';

  bool get isStaff => isRoot || kind == 'admin' || role == 'CHAPTER_ADMIN';
}
