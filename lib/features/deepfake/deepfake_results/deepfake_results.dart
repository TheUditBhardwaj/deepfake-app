import 'dart:typed_data'; // Ensure this import is correct
import 'dart:convert'; // For decoding base64 if necessary

class DeepfakeResult {
  final String prediction;
  final double confidenceScore;
  final String? gradcamImageUrl;
  final Uint8List? explanationImage; // Uint8List for image data
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
