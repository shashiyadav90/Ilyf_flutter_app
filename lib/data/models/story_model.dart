class StoryModel {
  final String id;
  final String mediaType;
  final String? mediaUrl;
  final String? caption;
  final String? text;
  final String? createdAt;
  final String? expiresAt;
  final bool isViewed;
  final int viewCount;

  StoryModel({
    required this.id,
    required this.mediaType,
    this.mediaUrl,
    this.caption,
    this.text,
    this.createdAt,
    this.expiresAt,
    this.isViewed = false,
    this.viewCount = 0,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? 'TEXT',
      mediaUrl: json['mediaUrl']?.toString(),
      caption: json['caption']?.toString(),
      text: json['text']?.toString(),
      createdAt: json['createdAt']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
      isViewed: json['isViewed'] == true,
      viewCount: json['viewCount'] is num
          ? (json['viewCount'] as num).toInt()
          : 0,
    );
  }
}

class StoryMemberGroup {
  final Map<String, dynamic> member;
  final List<StoryModel> stories;
  final bool hasUnseen;

  StoryMemberGroup({
    required this.member,
    required this.stories,
    required this.hasUnseen,
  });

  factory StoryMemberGroup.fromJson(Map<String, dynamic> json) {
    final memberData = json['member'] is Map
        ? Map<String, dynamic>.from(json['member'])
        : <String, dynamic>{};

    final storyList = json['stories'] is List
        ? (json['stories'] as List)
        : [];

    return StoryMemberGroup(
      member: memberData,
      stories: storyList
          .whereType<Map>()
          .map((item) => StoryModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      hasUnseen: json['hasUnseen'] == true,
    );
  }
}