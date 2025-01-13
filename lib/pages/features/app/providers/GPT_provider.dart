import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey;

  OpenAIService(this.apiKey);

  // Here we accept the entire conversation's messages, not just the "latest user message."
  Future<String> getChatGPTReply(List<Map<String, String>> conversation) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final headers = {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization": "Bearer $apiKey",
    };

    // Build the messages array from your local "conversation" list
    // Example: each map might have { "role": "user", "content": "Hello" } or { "role": "assistant", "content": "Hi there!" }
    final messages = [
      {
        "role": "system",
        "content":
            "Chcem odpoveď vždy v Slovenskom jazyku. Vrat mi 5 slovných spojení, ktoré sa týkajú softwarového vývoja na opísaný problém používateľom."
      },
      // Add the conversation messages from your list
      ...conversation,
    ];

    final bodyMap = {
      "model": "gpt-4o",
      "messages": messages,
      "temperature": 0.7,
    };

    // Encode the body as UTF-8
    final body = utf8.encode(jsonEncode(bodyMap));

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Decode in UTF-8
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
}
