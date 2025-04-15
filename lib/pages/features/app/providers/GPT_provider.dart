import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey;

  OpenAIService(this.apiKey);

  Future<String> getChatGPTReply({
    required Map<String, List<String>> selectedOptionsGroupedBySections,
    required int numberOfWords,
    required bool isSolutionDomain,
    required bool isApplicationDomain,
    required bool isSpilledHat,
    required bool isOutsideSoftware,
    required String? problemDescription,
  }) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final headers = {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization": "Bearer $apiKey",
    };

    final String optionsText = selectedOptionsGroupedBySections.entries
        .map((entry) => "${entry.key}: ${entry.value.join(', ')}")
        .join("\n");

    String systemMessage = "I want the response always in English. ";
    if (isOutsideSoftware) {
      systemMessage += "Return exactly $numberOfWords phrases to description.";
      systemMessage += "Options have to have 1-3 words max.";
      if (problemDescription != null && problemDescription.isNotEmpty) {
        systemMessage += "\n\nProblem Description: $problemDescription";
      }
    } else {
      systemMessage += "Return exactly $numberOfWords phrases related."
          "Options have to have 1-3 words max."
          "Selected sections and options:\n$optionsText";
      if (isApplicationDomain == true && isSolutionDomain == false) {
        systemMessage +=
            "Create that option only for application domain accordingly to problem description. The application domain is, for example, banking with terms such as transaction, account, interest, etc.";
      }
      if (isApplicationDomain == false && isSolutionDomain == true) {
        systemMessage += "Create that options only for solution domain.";
      }
      if ((isApplicationDomain && isSolutionDomain) ||
          (isApplicationDomain && isSolutionDomain)) {
        systemMessage +=
            "its up to you of wich domain if application or solutions you will create option.";
      }
      systemMessage +=
          "Give me just content of option. No category , no numbering, no other words in return message.";

      if (problemDescription != null && problemDescription.isNotEmpty) {
        systemMessage += "\n\nProblem Description: $problemDescription";
      }

      if (isSpilledHat) {
        systemMessage +=
            "\n\n25% of options, have to be some random thing absolutely outside of software scope. Just option without note."; // ✅ Add Spilled Hat behavior
      }
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

  Future<String> getChatGPTNewWord({
    required String problemId,
    required String containerId,
    required String containerName,
  }) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final headers = {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization": "Bearer $apiKey",
    };

    String systemMessage = """
You are a helpful assistant. I need exactly ONE new word in English.
This new word:
- Must not be any of the following: $containerName but it have to be something similar.
- Must be 1 to 3 words max.
""";

    systemMessage += """
Return just the word/phrase itself, with no additional explanation, formatting, or punctuation.
""";

    final messages = [
      {"role": "system", "content": systemMessage},
    ];

    // The request body
    final bodyMap = {
      "model": "gpt-4o",
      "messages": messages,
      "temperature": 0.7,
      "max_tokens": 20,
    };

    final body = utf8.encode(jsonEncode(bodyMap));

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data["choices"][0]["message"]["content"] ?? "";
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
}
