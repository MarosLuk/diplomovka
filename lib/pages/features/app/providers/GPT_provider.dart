import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey;

  OpenAIService(this.apiKey);

  Future<String> getChatGPTReply({
    required Map<String, List<String>> selectedOptionsGroupedBySections,
    required int numberOfWords,
    required bool isSolutionDomain,
  }) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final headers = {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization": "Bearer $apiKey",
    };

    // Format the selected options as a readable text for GPT
    final String optionsText = selectedOptionsGroupedBySections.entries
        .map((entry) => "${entry.key}: ${entry.value.join(', ')}")
        .join("\n");

    final String domainType =
        isSolutionDomain ? "riešenia (solution)" : "aplikácie (application)";

    final messages = [
      {
        "role": "system",
        "content": "I want the response always in English. "
            "The options should be without numbering or any labels at the beginning. "
            "Return exactly $numberOfWords phrases related to software development "
            "for the problem described by the user. "
            "Use the domain: $domainType. "
            "Selected sections and options:\n$optionsText"
      }
    ];

    final bodyMap = {
      "model": "gpt-4o",
      "messages": messages,
      "temperature": 0.7,
    };

    final body = utf8.encode(jsonEncode(bodyMap));

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data["choices"][0]["message"]["content"];
        return reply.trim();
      } else {
        print("❌ OpenAI API error: ${response.body}");
        throw Exception("Error from OpenAI: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error calling OpenAI: $e");
      rethrow;
    }
  }
}
