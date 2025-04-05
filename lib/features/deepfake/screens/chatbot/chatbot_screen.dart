import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


// Running the app without dotenv
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system,
      home: const ChatbotScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Directly use the API key
  final String _apiKey = 'AIzaSyCn4_DYFPzofbS0C7lXqtGep5dEnbPqK0g';

  // Keep track of conversation to maintain context
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      text: "Hello! How can I assist you today?",
      isUser: false,
    ));
  }

  void _handleSubmitted(String text) {
    _textController.clear();

    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    // Add message to conversation history
    _conversationHistory.add({"role": "user", "content": text});

    // Scroll to bottom after message is sent
    _scrollToBottom();

    // Get response from API
    _getResponseFromApi();
  }

  Future<void> _getResponseFromApi() async {
    try {
      // Using Google's Generative AI API (Gemini)
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': _conversationHistory.map((msg) => {
            'role': msg['role'] == 'user' ? 'user' : 'model',
            'parts': [{'text': msg['content']}]
          }).toList(),
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String botResponse = "";

        try {
          // Extract the response text from the API result
          botResponse = data['candidates'][0]['content']['parts'][0]['text'] ?? "No response content";
        } catch (e) {
          botResponse = "Received response but couldn't parse it: $e";
        }

        // Add bot response to the conversation history
        _conversationHistory.add({"role": "model", "content": botResponse});

        setState(() {
          _messages.add(ChatMessage(
            text: botResponse,
            isUser: false,
          ));
          _isTyping = false;
        });
      } else {
        setState(() {
          String errorMessage;
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['error']?['message'] ?? "Error ${response.statusCode}";
          } catch (e) {
            errorMessage = "Error ${response.statusCode}: ${response.body}";
          }

          _messages.add(ChatMessage(
            text: "API Error: $errorMessage",
            isUser: false,
          ));
          _isTyping = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Connection error: $e",
          isUser: false,
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _conversationHistory.clear();
                _messages.add(ChatMessage(
                  text: "Hello! How can I assist you today?",
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start a conversation',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message, isDarkMode);
              },
            ),
          ),
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Assistant is typing...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1.0),
          _buildMessageComposer(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, bool isDarkMode) {
    final time = "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Theme.of(context).primaryColor.withOpacity(0.8)
                        : isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20.0).copyWith(
                      bottomRight: message.isUser ? const Radius.circular(0) : null,
                      bottomLeft: !message.isUser ? const Radius.circular(0) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8.0),
            CircleAvatar(
              backgroundColor: Colors.teal,
              child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageComposer(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _textController.clear(),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _isTyping ? null : _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded),
              color: Colors.white,
              onPressed: _isTyping
                  ? null
                  : () => _handleSubmitted(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}