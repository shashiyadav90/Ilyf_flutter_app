class Member {
  const Member({
    required this.id,
    required this.name,
    this.ownerName = '',
    this.membershipNo = '',
    this.chapter = '',
    this.city = '',
    this.category = '',
    this.membershipType = '',
    this.membership = '',
    this.photo = '',
    this.photoUrl = '',
    this.linkedin = '',
    this.x = '',
    this.twitter = '',
    this.instagram = '',
    this.facebook = '',
    this.phone = '',
    this.memberId = '',
    this.chapterId = '',
  });

  final String id, name, ownerName, membershipNo, chapter, city, category;
  final String membershipType,
      membership,
      photo,
      photoUrl,
      linkedin,
      x,
      twitter;
  final String instagram, facebook, phone, memberId, chapterId;

  factory Member.fromJson(Map<String, dynamic> json) {
    String value(dynamic v) => v == null ? '' : v.toString();
    final socials = json['socials'] is Map ? json['socials'] as Map : const {};
    return Member(
      id: value(json['id'] ?? json['_id']),
      name: value(json['name']),
      ownerName: value(json['ownerName']),
      membershipNo: value(json['membershipNo'] ?? json['ilyfId']),
      chapter: value(json['chapter']),
      city: value(json['city']),
      category: value(json['category']),
      membershipType: value(json['membershipType']),
      membership: value(json['membership']),
      photo: value(json['photo']),
      photoUrl: value(json['photoUrl']),
      linkedin: value(json['linkedin'] ?? socials['linkedin']),
      x: value(json['x'] ?? socials['x']),
      twitter: value(json['twitter'] ?? socials['twitter']),
      instagram: value(json['instagram'] ?? socials['instagram']),
      facebook: value(json['facebook'] ?? socials['facebook']),
      phone: value(json['phone']),
      memberId: value(json['memberId']),
      chapterId: value(json['chapterId']),
    );
  }

  String get displayName => ownerName.trim().isNotEmpty ? ownerName : name;
  String get effectiveChapter => chapter.trim().isNotEmpty ? chapter : city;
  String get effectivePhoto => photo.isNotEmpty ? photo : photoUrl;
  String get effectiveMembershipNo => membershipNo;
}

const List<String> defaultChapters = [
  'Bengaluru',
  'Mysuru',
  'Hubballi',
  'Shivamogga',
  'Belagavi',
  'Mumbai',
  'Dubai',
];

String memberType(Member member) {
  if (member.membershipType == 'Patron' || member.membershipType == 'Annual') {
    return member.membershipType;
  }
  final type = '${member.membership} ${member.membershipType}'.toLowerCase();
  if (type.contains('life')) return 'Life Member';
  if (type.contains('annual')) return 'Annual Member';
  if (type.contains('patron')) return 'Patron';
  return 'Chapter member';
}

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .where(
        (p) => !RegExp(
          r'^(dr|mr|mrs|ms|prof)\.?$',
          caseSensitive: false,
        ).hasMatch(p),
      )
      .toList();
  if (parts.isEmpty) return 'I';
  if (parts.length == 1) {
    final p = parts.first;
    return p.substring(0, p.length > 1 ? 2 : 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

List<Member> sortMembers(List<Member> members) {
  final result = [...members];
  result.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return result;
}

String nationalDigits([String phone = '']) =>
    phone.replaceAll(RegExp(r'\D'), '');
String phoneDigits([String phone = '']) {
  final digits = nationalDigits(phone);
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

bool isAnilPhone(String phone) => phoneDigits(phone) == '9900147723';

String? validateNationalNumber(String value, {int min = 8, int max = 12}) {
  final digits = nationalDigits(value);
  if (digits.isEmpty) return 'Enter a mobile number.';
  if (digits.length < min) {
    return min == max
        ? 'Enter a $min-digit mobile number.'
        : 'Enter at least $min digits.';
  }
  if (digits.length > max)
    return 'Mobile number should be $max digits or fewer.';
  return null;
}

String formatIntlPhone(String dialCode, String national) =>
    '+${dialCode.replaceAll('+', '')} ${nationalDigits(national)}';

bool phonesMatch(String stored, String entered) {
  final a = nationalDigits(stored), b = nationalDigits(entered);
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  final length = [10, a.length, b.length].reduce((x, y) => x < y ? x : y);
  return length >= 8 &&
      a.substring(a.length - length) == b.substring(b.length - length);
}

Member? findListingByPhone(List<Member> members, String entered) {
  for (final member in members) {
    if (phonesMatch(member.phone, entered)) return member;
  }
  return null;
}
