import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class DeepfakeService {
  static const String baseUrl = 'https://deepsight-f7b7g8grc3czg7gq.centralindia-01.azurewebsites.net';

  Future<DeepfakeResult> analyzeVideo(File videoFile, int sequenceLength) async {
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

      // Send request and get response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse response data
        Map<String, dynamic> responseData = json.decode(response.body);
        return DeepfakeResult.fromApiResponse(responseData);
      } else {
        // Return error result
        return DeepfakeResult(
          prediction: 'Error',
          confidenceScore: 0.0,
          hasError: true,
          errorMessage: 'API Error: ${response.statusCode}',
          details: {'error_code': response.statusCode, 'response': response.body},
        );
      }
    } catch (e) {
      // Return error result for exceptions
      return DeepfakeResult(
        prediction: 'Error',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: 'Exception: ${e.toString()}',
      );
    }
  }
}

class DeepfakeResult {
  final String prediction;
  final double confidenceScore;
  final String? gradcamImageUrl;
  final Uint8List? explanationImage;
  final Map<String, dynamic> details;
  final bool hasError;
  final String errorMessage;

  // Constructor
  DeepfakeResult({
    required this.prediction,
    required this.confidenceScore,
    this.gradcamImageUrl,
    this.explanationImage,
    this.details = const {},
    this.hasError = false,
    this.errorMessage = '',
  });

  // Factory constructor to create DeepfakeResult from API response
  factory DeepfakeResult.fromApiResponse(Map<String, dynamic> json) {
    return DeepfakeResult(
      prediction: json['prediction'] ?? 'Unknown',
      confidenceScore: json['confidence_score']?.toDouble() ?? 0.0,
      gradcamImageUrl: json['gradcam_image_url'],
      explanationImage: json['explanation_image'] != null
          ? Uint8List.fromList(base64Decode(json['explanation_image']))
          : null,
      details: json['details'] ?? {},
      hasError: json['error'] ?? false,
      errorMessage: json['error_message'] ?? '',
    );
  }
}