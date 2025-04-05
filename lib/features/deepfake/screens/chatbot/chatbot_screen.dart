import 'package:flutter/material.dart';
import 'package:hacachino/utils/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

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
  final String? fullText; // Full version of the text when shortened
  final bool isUser;
  final DateTime timestamp;
  final bool isExpanded; // Track if the message is showing full text or shortened

  ChatMessage({
    required this.text,
    this.fullText,
    required this.isUser,
    DateTime? timestamp,
    this.isExpanded = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Create a copy of the message with different expanded state
  ChatMessage copyWith({bool? isExpanded}) {
    return ChatMessage(
      text: isExpanded == true ? (fullText ?? text) : text,
      fullText: fullText,
      isUser: isUser,
      timestamp: timestamp,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  // Check if the message has a longer version available
  bool get hasFullVersion => fullText != null && fullText != text;
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Color color1;
  final Color color2;

  const AnimatedBackground({
    super.key,
    required this.child,
    required this.color1,
    required this.color2,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color1, widget.color2],
              transform: GradientRotation(_animationController.value * 2 * math.pi),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

class FloatingBubble extends StatefulWidget {
  final Color color;
  final double size;
  final double startY;

  const FloatingBubble({
    super.key,
    required this.color,
    required this.size,
    required this.startY,
  });

  @override
  State<FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  late double startX;

  @override
  void initState() {
    super.initState();

    // Random starting position
    startX = math.Random().nextDouble();

    _controller = AnimationController(
      duration: Duration(seconds: 10 + math.Random().nextInt(20)),
      vsync: this,
    );

    // Create random float animations
    _xAnimation = Tween<double>(
      begin: startX,
      end: startX + 0.2 - math.Random().nextDouble() * 0.4,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _yAnimation = Tween<double>(
      begin: widget.startY,
      end: widget.startY - 0.5 - math.Random().nextDouble() * 0.5,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _xAnimation.value,
          top: MediaQuery.of(context).size.height * _yAnimation.value,
          child: Opacity(
            opacity: 0.15,
            child: Container(
              height: widget.size,
              width: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // Animation controllers
  late AnimationController _suggestionsController;
  bool _showSuggestions = false;

  // Directly use the API key
  final String _apiKey = 'AIzaSyCn4_DYFPzofbS0C7lXqtGep5dEnbPqK0g';

  // Keep track of conversation to maintain context
  final List<Map<String, String>> _conversationHistory = [];

  // Maximum length for a bot message before shortening
  final int _maxBotMessageLength = 150;

  // Suggested prompts related to deepfakes
  final List<String> _deepfakeSuggestions = [
    "How can I identify deepfake videos?",
    "What are the risks of deepfake technology?",
    "How to verify if an image is AI-generated?",
    "What tools can detect deepfakes?",
    "How are deepfakes affecting journalism?",
    "Recent developments in deepfake detection",
    "How to protect myself from deepfake scams",
    "What are ethical concerns with deepfakes?",
    "How are deepfakes used in social media?"
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      text: "Hello! How can I assist you today? Feel free to ask about deepfakes and digital media verification.",
      isUser: false,
    ));

    // Initialize animations
    _suggestionsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _handleSubmitted(String text) {
    _textController.clear();

    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _showSuggestions = false;
    });
    _suggestionsController.reverse();

    // Add message to conversation history
    _conversationHistory.add({"role": "user", "content": text});

    // Scroll to bottom after message is sent
    _scrollToBottom();

    // Get response from API
    _getResponseFromApi();
  }

  void _useSuggestion(String suggestion) {
    _textController.text = suggestion;
    _handleSubmitted(suggestion);
  }

  void _toggleSuggestions() {
    setState(() {
      _showSuggestions = !_showSuggestions;
    });
    if (_showSuggestions) {
      _suggestionsController.forward();
    } else {
      _suggestionsController.reverse();
    }
  }

  // Function to shorten bot message if it's too long
  String _shortenMessage(String originalMessage) {
    if (originalMessage.length <= _maxBotMessageLength) {
      return originalMessage;
    }

    // Try to find a good breaking point (end of sentence)
    final possibleBreakPoint = originalMessage.indexOf(
      RegExp(r'[.!?]\s'),
      _maxBotMessageLength ~/ 2,
    );

    if (possibleBreakPoint != -1 && possibleBreakPoint < _maxBotMessageLength) {
      return originalMessage.substring(0, possibleBreakPoint + 1) +
          "\n\n(Tap to read more...)";
    }

    // If no good breaking point, just cut at max length
    return originalMessage.substring(0, _maxBotMessageLength) +
        "...\n\n(Tap to read more...)";
  }

  // Toggle between shortened and full message
  void _toggleMessageExpansion(int index) {
    if (_messages[index].hasFullVersion) {
      setState(() {
        _messages[index] = _messages[index].copyWith(
            isExpanded: !_messages[index].isExpanded
        );
      });
      // Scroll after expanding to ensure message is visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
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

        // Add bot response to the conversation history (always keep the full response in history)
        _conversationHistory.add({"role": "model", "content": botResponse});

        // Create shortened version if needed
        final String shortendResponse = _shortenMessage(botResponse);
        final bool isShortened = shortendResponse != botResponse;

        setState(() {
          _messages.add(ChatMessage(
            text: shortendResponse,
            fullText: isShortened ? botResponse : null,
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

  List<Widget> _buildAnimatedBubbles(bool isDarkMode) {
    final List<Widget> bubbles = [];
    final baseColor = isDarkMode ? Colors.white : TColors.primary;

    for (int i = 0; i < 10; i++) {
      bubbles.add(
        FloatingBubble(
          color: baseColor.withOpacity(math.Random().nextDouble() * 0.2 + 0.1),
          size: 20.0 + math.Random().nextDouble() * 80,
          startY: 0.1 + math.Random().nextDouble() * 0.9,
        ),
      );
    }

    return bubbles;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor1 = isDarkMode ? Colors.grey[900]! : Colors.blue[50]!;
    final bgColor2 = isDarkMode ? Colors.black : Colors.white;

    return AnimatedBackground(
      color1: bgColor1,
      color2: bgColor2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('DeepFake Awareness Assistant',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 2,
          backgroundColor: isDarkMode ? Colors.grey[850]!.withOpacity(0.7) : TColors.primary.withOpacity(0.9),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _conversationHistory.clear();
                  _messages.add(ChatMessage(
                    text: "Hello! How can I assist you today? Feel free to ask about deepfakes and digital media verification.",
                    isUser: false,
                  ));
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            ..._buildAnimatedBubbles(isDarkMode),
            Column(
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
                          'Start a conversation about deepfakes',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ClipRRect(
                    child: BackdropFilter(
                      filter: isDarkMode ?
                      ImageFilter.blur(sigmaX: 5, sigmaY: 5) :
                      ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessage(message, isDarkMode, index);
                        },
                      ),
                    ),
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
                AnimatedBuilder(
                  animation: _suggestionsController,
                  builder: (context, child) {
                    return SizeTransition(
                      sizeFactor: _suggestionsController,
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[850]!.withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _deepfakeSuggestions.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ActionChip(
                                label: Text(
                                  _deepfakeSuggestions[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                backgroundColor: isDarkMode
                                    ? TColors.primary.withOpacity(0.3)
                                    : TColors.primary.withOpacity(0.1),
                                onPressed: () => _useSuggestion(_deepfakeSuggestions[index]),
                                elevation: 1,
                                shadowColor: TColors.primary.withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                _buildMessageComposer(isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, bool isDarkMode, int index) {
    final time = "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    // Function to parse and format text with markdown-like syntax
    Widget buildRichText(String text) {
      final List<TextSpan> spans = [];

      // Pattern to match *bold text*
      final RegExp boldPattern = RegExp(r'\*(.*?)\*');

      String remaining = text;
      int lastMatchEnd = 0;

      // Find all bold patterns
      for (final match in boldPattern.allMatches(text)) {
        // Add text before the match
        if (match.start > lastMatchEnd) {
          spans.add(TextSpan(
            text: remaining.substring(0, match.start - lastMatchEnd),
          ));
        }

        // Add the bold text without asterisks
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));

        // Update remaining text
        remaining = remaining.substring(match.end - lastMatchEnd);
        lastMatchEnd = match.end;
      }

      // Add any remaining text
      if (remaining.isNotEmpty) {
        spans.add(TextSpan(text: remaining));
      }

      return RichText(
        text: TextSpan(
          style: TextStyle(
            color: message.isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black),
          ),
          children: spans,
        ),
      );
    }

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
              backgroundColor: TColors.primary,
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
                GestureDetector(
                  onTap: message.isUser ? null : () => _toggleMessageExpansion(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? TColors.primary
                          : isDarkMode
                          ? Colors.grey[800]!.withOpacity(0.9)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20.0).copyWith(
                        bottomRight: message.isUser ? const Radius.circular(0) : null,
                        bottomLeft: !message.isUser ? const Radius.circular(0) : null,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    // Replace Text widget with our custom rich text widget
                    child: buildRichText(message.text),
                  ),
                ),
                // Rest of your code remains the same...
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (message.hasFullVersion) ...[
                        const SizedBox(width: 8),
                        Text(
                          message.isExpanded ? "Show less" : "Read more",
                          style: TextStyle(
                            fontSize: 10,
                            color: TColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8.0),
            CircleAvatar(
              backgroundColor: TColors.primary,
              child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageComposer(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey[900]!.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.lightbulb_outline,
              color: _showSuggestions ? TColors.primary : Colors.grey,
            ),
            onPressed: _toggleSuggestions,
            tooltip: 'Show suggestions',
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask about deepfakes or media verification...',
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: TColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
    _suggestionsController.dispose();
    super.dispose();
  }
}