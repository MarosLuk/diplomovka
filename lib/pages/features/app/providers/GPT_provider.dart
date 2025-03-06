import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey;

  OpenAIService(this.apiKey);

  Future<String> getChatGPTReply({
    required Map<String, List<String>> selectedOptionsGroupedBySections,
    required int numberOfWords,
    required bool isSolutionDomain,
    required bool isSpilledHat,
    String? problemDescription,
  }) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final headers = {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization": "Bearer $apiKey",
    };

    final String optionsText = selectedOptionsGroupedBySections.entries
        .map((entry) => "${entry.key}: ${entry.value.join(', ')}")
        .join("\n");

    final String domainType = isSolutionDomain ? "solution" : "application";

    String systemMessage = "I want the response always in English. "
        "Return exactly $numberOfWords phrases related to software development. "
        "Use the domain: $domainType. "
        "Options have to have 1-3 words max."
        "Selected sections and options:\n$optionsText";

    if (problemDescription != null && problemDescription.isNotEmpty) {
      systemMessage += "\n\nProblem Description: $problemDescription";
    }

    if (isSpilledHat) {
      systemMessage +=
          "\n\n25% of options, have to be some random thing absolutely outside of software scope. Just option without note."; // ✅ Add Spilled Hat behavior
    }

    final messages = [
      {"role": "system", "content": systemMessage}
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
        print("OpenAI API error: ${response.body}");
        throw Exception("Error from OpenAI: ${response.statusCode}");
      }
    } catch (e) {
      print("Error calling OpenAI: $e");
      rethrow;
    }
  }

  Future<String> _fetchGPTResponse(
      Uri url, Map<String, String> headers, String systemPrompt) async {
    final messages = [
      {"role": "system", "content": systemPrompt}
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
        return data["choices"][0]["message"]["content"].trim();
      } else {
        print("OpenAI API error: ${response.body}");
        throw Exception("Error from OpenAI: ${response.statusCode}");
      }
    } catch (e) {
      print("Error calling OpenAI: $e");
      rethrow;
    }
  }
}
