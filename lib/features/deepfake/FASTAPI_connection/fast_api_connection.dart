import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class DeepfakeService {
  static const String baseUrl = 'https://deepsight-f7b7g8grc3czg7gq.centralindia-01.azurewebsites.net';

  Future<Map<String, dynamic>> analyzeVideo(File videoFile, int sequenceLength) async {
    try {
      var uri = Uri.parse('$baseUrl/predict/');
      var request = http.MultipartRequest('POST', uri);

      // Add video file
      var videoStream = http.ByteStream(videoFile.openRead());
      var videoLength = await videoFile.length();
      var videoUpload = http.MultipartFile(
        'video',
        videoStream,
        videoLength,
        filename: 'video.mp4',
      );

      // Add sequence length parameter
      request.fields['sequence_length'] = sequenceLength.toString();
      request.files.add(videoUpload);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to analyze video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error analyzing video: $e');
    }
  }
}