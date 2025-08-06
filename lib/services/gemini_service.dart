import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// A dedicated class for handling Gemini API calls.
// This makes our code cleaner and easier to test.
class GeminiService {
  // Load the API key from the .env file.
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  late final String _apiUrl;

  GeminiService() {
    if (_apiKey == null) {
      throw Exception(
        'API Key not found. Make sure you have a .env file with GEMINI_API_KEY',
      );
    }
    _apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';
  }

  Future<String> getExplanation({
    required String mainText,
    required String term,
  }) async {
    final prompt =
        "In the context of the following text, concisely explain the term '$term' in 3-4 sentences. If the term is not in the text, say so. \n\nText: '''$mainText'''";

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': 'gemini-1.5-flash',
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        // Added more checks for a robust response parsing
        if (decodedResponse['candidates'] != null &&
            decodedResponse['candidates'].isNotEmpty &&
            decodedResponse['candidates'][0]['content'] != null &&
            decodedResponse['candidates'][0]['content']['parts'] != null &&
            decodedResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          return decodedResponse['candidates'][0]['content']['parts'][0]['text'];
        } else {
          // Handle cases where the API returns a 200 but no valid content
          return "Received a response, but could not find the explanation text.";
        }
      } else {
        // Throw an exception with a user-friendly message
        throw Exception(
          'Failed to get explanation. Status code: ${response.statusCode}\nBody: ${response.body}',
        );
      }
    } catch (e) {
      // Re-throw the exception to be handled by the UI layer
      throw Exception('Failed to connect to the service: $e');
    }
  }
}
