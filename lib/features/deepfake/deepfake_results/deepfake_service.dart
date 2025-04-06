import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'deepfake_results.dart';

class DeepfakeService {
  static const String baseUrl = 'https://deepsight-f7b7g8grc3czg7gq.centralindia-01.azurewebsites.net';

  Future<DeepfakeResult> analyzeVideo(File videoFile, int sequenceLength) async {
    try {
      var uri = Uri.parse('$baseUrl/predict/');
      var request = http.MultipartRequest('POST', uri);

      // Add video file to request
      var videoStream = http.ByteStream(videoFile.openRead());
      var videoLength = await videoFile.length();
      var videoUpload = http.MultipartFile(
        'video',
        videoStream,
        videoLength,
        filename: 'video.mp4',
      );

      // Add additional parameters
      request.fields['sequence_length'] = sequenceLength.toString();
      request.files.add(videoUpload);

      // Set timeout for request
      var responseStream = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw TimeoutException('Request timed out after 5 minutes');
        },
      );

      // Process response
      var responseData = await responseStream.stream.bytesToString();

      if (responseStream.statusCode == 200) {
        Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = json.decode(responseData);
        } catch (e) {
          throw FormatException('Invalid response format: $e');
        }

        // Parse the response using the factory constructor
        return DeepfakeResult.fromApiResponse(jsonResponse);
      } else {
        // Handle non-200 responses
        Map<String, dynamic> errorJson;
        try {
          errorJson = json.decode(responseData);
          String errorMessage = errorJson['error_message'] ?? 'Unknown server error';
          throw HttpException('Server error (${responseStream.statusCode}): $errorMessage');
        } catch (e) {
          if (e is HttpException) rethrow;
          throw HttpException('Server error (${responseStream.statusCode}): $responseData');
        }
      }
    } on SocketException catch (e) {
      return DeepfakeResult(
        prediction: 'Connection Error',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: 'Network connection issue: ${e.message}',
      );
    } on TimeoutException catch (_) {
      return DeepfakeResult(
        prediction: 'Timeout Error',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: 'Analysis is taking too long. Please try again with a shorter video.',
      );
    } on FormatException catch (e) {
      return DeepfakeResult(
        prediction: 'Format Error',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: 'Response format error: ${e.message}',
      );
    } on HttpException catch (e) {
      return DeepfakeResult(
        prediction: 'Server Error',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: e.message,
      );
    } catch (e) {
      return DeepfakeResult(
        prediction: 'Error',
        confidenceScore: 0.0,
        hasError: true,
        errorMessage: 'Unexpected error: ${e.toString()}',
      );
    }
  }
}

// Make sure to import this at the top of your file
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}