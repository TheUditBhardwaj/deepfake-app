import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class DeepfakeService {
  static const String baseUrl = 'https://4138ff78a4df064f38.gradio.live/api/predict';

  Future<DeepfakeResult> analyzeVideo(File videoFile, {int sequenceLength = 32}) async {
    try {
      final uri = Uri.parse(baseUrl);
      final request = http.MultipartRequest('POST', uri);

      // Add video file
      final videoStream = http.ByteStream(videoFile.openRead());
      final videoLength = await videoFile.length();
      final videoUpload = http.MultipartFile(
        'video_file',
        videoStream,
        videoLength,
        filename: 'video.mp4',
      );

      request.files.add(videoUpload);
      request.fields['sequence_length'] = sequenceLength.toString();

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return DeepfakeResult.fromApiResponse(responseData);
      } else {
        return DeepfakeResult(
          prediction: 'Error',
          confidenceScore: 0.0,
          hasError: true,
          errorMessage: 'API Error: ${response.statusCode}',
          details: {'response_body': response.body},
        );
      }
    } catch (e) {
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

  DeepfakeResult({
    required this.prediction,
    required this.confidenceScore,
    this.gradcamImageUrl,
    this.explanationImage,
    this.details = const {},
    this.hasError = false,
    this.errorMessage = '',
  });

  factory DeepfakeResult.fromApiResponse(Map<String, dynamic> json) {
    return DeepfakeResult(
      prediction: json['prediction'] ?? 'Unknown',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      gradcamImageUrl: json['gradcam_image_url'],
      explanationImage: json['explanation_image'] != null
          ? base64Decode(json['explanation_image'])
          : null,
      details: json['details'] ?? {},
      hasError: json['error'] ?? false,
      errorMessage: json['error_message'] ?? '',
    );
  }
}