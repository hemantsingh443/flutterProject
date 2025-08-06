import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  late final String _apiUrl;

  GeminiService() {
    if (_apiKey == null) {
      throw Exception(
          'API Key not found. Make sure you have a .env file with GEMINI_API_KEY');
    }
    _apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';
  }

  Future<String> getExplanation({
    required String mainText,
    required String term,
    bool isEli5 = false,
  }) async {
    final promptInstruction = isEli5
        ? "Explain the term '$term' like I'm 5 years old, in 2-3 simple sentences, based on the context of the following text."
        : "In the context of the following text, concisely explain the term '$term' in 3-4 sentences. If the term appears to be a garbled mathematical formula, do your best to interpret it. If the term is not in the text, say so.";

    final prompt = "$promptInstruction \n\nText: '''$mainText'''";

    return _generateContent(prompt);
  }

  Future<String> getSummary({required String mainText}) async {
    final prompt =
        "Provide a concise summary of the following text in a few bullet points. Identify the main arguments and conclusions. \n\nText: '''$mainText'''";
    return _generateContent(prompt);
  }

  Future<String> _generateContent(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'model': 'gemini-1.5-flash',
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          "safetySettings": [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_NONE"
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_NONE"
            },
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_NONE"
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['candidates'] != null &&
            decodedResponse['candidates'].isNotEmpty &&
            decodedResponse['candidates'][0]['content'] != null &&
            decodedResponse['candidates'][0]['content']['parts'] != null &&
            decodedResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          return decodedResponse['candidates'][0]['content']['parts'][0]
              ['text'];
        } else {
          if (decodedResponse['promptFeedback']?['blockReason'] != null) {
            return "Request blocked due to safety settings: ${decodedResponse['promptFeedback']['blockReason']}";
          }
          return "Received a response, but could not find the explanation text.";
        }
      } else {
        throw Exception(
            'Failed to get explanation. Status code: ${response.statusCode}\nBody: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the service: $e');
    }
  }
}
