import 'package:flutter/material.dart';
import 'package:diplomovka/pages/features/app/providers/GPT_provider.dart';
import 'package:diplomovka/pages/features/user_auth/API_keys/GPT_key.dart';
/*
class GPTPage extends StatefulWidget {
  const GPTPage({Key? key}) : super(key: key);

  @override
  _GPTPageState createState() => _GPTPageState();
}

class _GPTPageState extends State<GPTPage> {
  final TextEditingController _controller = TextEditingController();
  final OpenAIService _openAIService = OpenAIService(APIkey_GPT);

  // This list will hold our entire conversation.
  // Each item is a map with "role": "user"|"assistant", "content": "the text"
  final List<Map<String, String>> _messages = [];

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    // 1. Add the user's message to the conversation list
    setState(() {
      _messages.add({
        "role": "user",
        "content": prompt,
      });
      _controller.clear(); // Clear the input field
      _isLoading = true;
    });

    try {
      // 2. Call OpenAI with the entire conversation so far
      final reply = await _openAIService.getChatGPTReply(_messages);

      // 3. Add assistant's reply to the conversation list
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": reply,
        });
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        // In case of an error, we can add an assistant message with the error
        _messages.add({
          "role": "assistant",
          "content": "Error occurred while calling API: $e",
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Build a widget for each chat message
  Widget _buildMessageItem(Map<String, String> message) {
    final isUser = message["role"] == "user";
    final text = message["content"] ?? "";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[50] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatGPT Test"),
      ),
      body: Column(
        children: [
          // This expanded area shows the conversation history
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),

          if (_isLoading) const LinearProgressIndicator(),

          // Text input + send button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Text field to type the prompt
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: "Napíš niečo...",
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: const Text("Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


 */
