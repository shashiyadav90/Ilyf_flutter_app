import '../../core/config/api_config.dart';

class InquiryChatRepository {
  final dio = ApiConfig.dio;

  Future<Map<String, dynamic>> searchBusinesses({
    required String message,
    String? inquiryId,
  }) async {
    final response = await dio.post(
      '/chat/search',
      data: {
        'message': message,
        if (inquiryId != null && inquiryId.isNotEmpty) 'inquiryId': inquiryId,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }
}
