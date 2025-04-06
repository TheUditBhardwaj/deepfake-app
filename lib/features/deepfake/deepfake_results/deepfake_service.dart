import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class DeepfakeService {
  static const String postUrl = 'https://a30cb57160011fc330.gradio.live/gradio_api/call/process_prediction';
  static const String getBaseUrl = 'https://a30cb57160011fc330.gradio.live/gradio_api/queue/status/';

  Future<DeepfakeResult> analyzeVideo(File videoFile, {int sequenceLength = 10}) async {
    try {
      // 1. Convert file to base64
      final bytes = await videoFile.readAsBytes();
      final base64Video = base64Encode(bytes);

      // 2. Prepare JSON payload
      final payload = jsonEncode({
        "data": [
          {
            "video": "data:video/mp4;base64,$base64Video",
            "sequence_length": sequenceLength
          }
        ]
      });

      // 3. Send POST request
      final response = await http.post(
        Uri.parse(postUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: payload,
      );

      if (response.statusCode != 200) {
        return DeepfakeResult(
          prediction: 'Error',
          confidenceScore: 0.0,
          hasError: true,
          errorMessage: 'API POST Error: ${response.statusCode}',
          details: {'response_body': response.body},
        );
      }

      // 4. Extract event_id
      final postResult = jsonDecode(response.body);
      final String eventId = postResult['event_id'];

      // 5. Poll for result using GET
      await Future.delayed(Duration(seconds: 2)); // wait before polling
      final getUrl = '$getBaseUrl$eventId';

      http.Response getResponse;
      int attempts = 0;
      const maxAttempts = 10;

      while (attempts < maxAttempts) {
        getResponse = await http.get(Uri.parse(getUrl));
        final getJson = jsonDecode(getResponse.body);

        if (getJson['status'] == 'COMPLETE' && getJson['output'] != null) {
          // parse actual prediction output
          final output = getJson['output'];
          return DeepfakeResult.fromApiResponse(output);
        }

        // wait and retry
        await Future.delayed(Duration(seconds: 2));
        attempts++;
      }

      return DeepfakeResult(
        prediction: 'Timeout',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: 'Prediction timed out after $maxAttempts attempts',
      );
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

  factory DeepfakeResult.fromApiResponse(dynamic json) {
    if (json is List && json.length > 0 && json[0] is Map<String, dynamic>) {
      final result = json[0];
      return DeepfakeResult(
        prediction: result['prediction'] ?? 'Unknown',
        confidenceScore: (result['confidence_score'] as num?)?.toDouble() ?? 0.0,
        gradcamImageUrl: result['gradcam_image_url'],
        explanationImage: result['explanation_image'] != null
            ? base64Decode(result['explanation_image'])
            : null,
        details: result['details'] ?? {},
        hasError: result['error'] ?? false,
        errorMessage: result['error_message'] ?? '',
      );
    } else {
      return DeepfakeResult(
        prediction: 'Unknown',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: 'Invalid response format',
        details: {'raw': json},
      );
    }
  }
}