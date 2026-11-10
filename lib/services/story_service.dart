import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/api_config.dart';

class StoryService {
  final Dio _dio = ApiConfig.dio;

  // GET: Fetch all stories
  Future<dynamic> getStories() async {
    final response = await _dio.get('/overview/stories');
    return response.data;
  }

  // POST: Create image, video or text story
  Future<dynamic> createStory({
    required String mediaType,
    XFile? file,
    String? text,
  }) async {
    final Map<String, dynamic> formFields = {'mediaType': mediaType};

    if (text != null && text.trim().isNotEmpty) {
      formFields['text'] = text.trim();
    }

    if (file != null) {
      final bytes = await file.readAsBytes();

      formFields['file'] = MultipartFile.fromBytes(bytes, filename: file.name);
    }

    final formData = FormData.fromMap(formFields);

    final response = await _dio.post(
      '/overview/stories',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data;
  }

  // POST: Mark story as viewed
  Future<dynamic> viewStory(String storyId) async {
    final response = await _dio.post('/overview/stories/$storyId/view');

    return response.data;
  }

  // DELETE: Delete a story
  Future<dynamic> deleteStory(String storyId) async {
    final response = await _dio.delete('/overview/stories/$storyId');

    return response.data;
  }

  // GET: Get story viewers
  Future<dynamic> getStoryViews(String storyId) async {
    final response = await _dio.get('/overview/stories/$storyId/views');

    return response.data;
  }
}
