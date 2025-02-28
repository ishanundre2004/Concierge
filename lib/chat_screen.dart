import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:concierge/chat%20services/room_booking.dart';
import 'package:concierge/chat%20services/room_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isBooked = false;
  late RoomBooking _roomBooking;

  final List<String> bookingKeywords = [
    "book",
    "booking",
    "reserve",
    "reservation",
    "room",
    "stay",
    "accommodation",
    "check-in",
    "check out",
    "availability",
    "available rooms",
    "rent",
    "book a room",
    "book room",
    "reserve room",
    "book stay",
    "reserve stay",
  ];

  final String apiKey =
      "AIzaSyC0bVWxKf34hDBUNzktCiVwGNyk0a1JAR8"; // Replace with your actual API key
  final String geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  @override
  void initState() {
    super.initState();
    _roomBooking =
        RoomBooking(_addMessage, _addRoomCards); // Initialize RoomBooking
    _addInitialMessages();
  }

  void _addInitialMessages() async {
    String userName = await _fetchUserName(); // Fetch user's name
    String welcomeMessage =
        "Welcome, $userName, to The Taj Mahal Palace, Mumbai! I'm your virtual concierge. How can I assist you today?";
    _addMessage(welcomeMessage, false);
  }

  Future<String> _fetchUserName() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (userId.isEmpty) return "guest"; // Default if user is not logged in

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists
        ? userDoc.get('name')
        : "Guest"; // Fetch name or default
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });

    // Scroll to bottom after message is added
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _addRoomCards(Widget roomCards) {
    print("Adding room cards to chat"); // Debug log
    setState(() {
      _messages.add(ChatMessage(
        text: "",
        isUser: false,
        customWidget: roomCards,
      ));
    });

    // Scroll to bottom after room cards are added
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _confirmBooking() {
    setState(() {
      _isBooked = true;
    });
    _addMessage(
        "Your booking has been confirmed! How can I assist you further?",
        false);
  }

//   Future<void> _handleSubmit(String text) async {
//     if (text.trim().isEmpty) return; // Ignore empty messages

//     _controller.clear();
//     _addMessage(text, true);

//     setState(() {
//       _isTyping = true;
//     });

//     try {
//       // Check if the user's input is related to room booking
//       bool isBookingRelated = bookingKeywords
//           .any((keyword) => text.toLowerCase().contains(keyword));

//       if (isBookingRelated) {
//         await _roomBooking.handleRoomBooking(text);
//         return;
//       }

//       // System prompt for before booking
//       final String preBookingPrompt = """
// You are a virtual concierge for The Taj Mahal Palace, Mumbai. Your role is to assist potential guests with information about the hotel and its services. However, since the guest has not yet confirmed their booking, you can only provide information and cannot assist with bookings or additional services.

// You are fluent in multiple Indian languages, including Hindi, English, and Hinglish (Hindi written in English). Respond in the same language or style as the guest's query.

// Examples of tasks you can assist with:
// - Providing information about room types, rates, and availability.
// - Sharing details about hotel amenities (e.g., pool, gym, spa, restaurants).
// - Offering information about check-in/check-out times, late check-out, or early check-in.
// - Providing details about nearby attractions, restaurants, or shopping areas.
// - Sharing the hotel's policies (e.g., cancellation, pet policies).

// Please respond only to queries related to the hotel and its services. If the guest asks about booking or additional services, politely inform them that these can be accessed after confirming their booking.
// """;

//       // System prompt for after booking
//       final String postBookingPrompt = """
// You are a virtual concierge for The Taj Mahal Palace, Mumbai. The guest has confirmed their booking, and you can now assist them with all hotel-related services.

// You are fluent in multiple Indian languages, including Hindi, English, and Hinglish (Hindi written in English). Respond in the same language or style as the guest's query.

// Examples of tasks you can assist with:
// - Providing the hotel's restaurant menu or room service options.
// - Assisting with transportation arrangements (e.g., taxis, shuttles).
// - Offering recommendations for nearby attractions, restaurants, or shopping areas.
// - Helping with additional requests like extra towels, room upgrades, or late check-out.
// - Providing directions or maps for local areas.
// """;

//       // Combine the appropriate prompt with the user's input
//       final String fullPrompt = _isBooked
//           ? "$postBookingPrompt\n\nGuest: $text"
//           : "$preBookingPrompt\n\nGuest: $text";

//       // Handle booking confirmation
//       if (!_isBooked && text.toLowerCase().contains("confirm booking")) {
//         _confirmBooking();
//         return;
//       }

//       // Send request to Gemini API
//       final response = await http.post(
//         Uri.parse("$geminiUrl?key=$apiKey"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "contents": [
//             {
//               "parts": [
//                 {"text": fullPrompt}
//               ]
//             }
//           ]
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final botResponse = data["candidates"]?[0]["content"]["parts"]?[0]
//                 ["text"] ??
//             "Sorry, I couldn't generate a response.";
//         _addMessage(botResponse, false);
//       } else {
//         _addMessage("Error: ${response.statusCode} - ${response.body}", false);
//       }
//     } catch (e) {
//       _addMessage(
//           "Sorry, I encountered an error. Please try again.\nError: $e", false);
//     } finally {
//       setState(() {
//         _isTyping = false;
//       });
//     }
//   }
  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty) return; // Ignore empty messages

    _controller.clear();
    _addMessage(text, true);

    setState(() {
      _isTyping = true;
    });

    try {
      // Initialize RoomService
      final roomService = RoomService(_addMessage, _addRoomCards);

      // Check if the user's input is related to room booking
      bool isBookingRelated = bookingKeywords
          .any((keyword) => text.toLowerCase().contains(keyword));

      if (isBookingRelated) {
        await _roomBooking.handleRoomBooking(text);
        return;
      }

      // Check if the user's input is related to room services
      if (roomService.isServiceRelated(text)) {
        await roomService.handleServiceRequest(text);
        return;
      }

      // System prompt for before booking
      final String preBookingPrompt = """
You are a virtual concierge for The Taj Mahal Palace, Mumbai. Your role is to assist potential guests with information about the hotel and its services. However, since the guest has not yet confirmed their booking, you can only provide information and cannot assist with bookings or additional services.

You are fluent in multiple Indian languages, including Hindi, English, and Hinglish (Hindi written in English). Respond in the same language or style as the guest's query.

Examples of tasks you can assist with:
- Providing information about room types, rates, and availability.
- Sharing details about hotel amenities (e.g., pool, gym, spa, restaurants).
- Offering information about check-in/check-out times, late check-out, or early check-in.
- Providing details about nearby attractions, restaurants, or shopping areas.
- Sharing the hotel's policies (e.g., cancellation, pet policies).

Please respond only to queries related to the hotel and its services. If the guest asks about booking or additional services, politely inform them that these can be accessed after confirming their booking.
""";

      // System prompt for after booking
      final String postBookingPrompt = """
You are a virtual concierge for The Taj Mahal Palace, Mumbai. The guest has confirmed their booking, and you can now assist them with all hotel-related services.

You are fluent in multiple Indian languages, including Hindi, English, and Hinglish (Hindi written in English). Respond in the same language or style as the guest's query.

Examples of tasks you can assist with:
- Providing the hotel's restaurant menu or room service options.
- Assisting with transportation arrangements (e.g., taxis, shuttles).
- Offering recommendations for nearby attractions, restaurants, or shopping areas.
- Helping with additional requests like extra towels, room upgrades, or late check-out.
- Providing directions or maps for local areas.
""";

      // Combine the appropriate prompt with the user's input
      final String fullPrompt = _isBooked
          ? "$postBookingPrompt\n\nGuest: $text"
          : "$preBookingPrompt\n\nGuest: $text";

      // Handle booking confirmation
      if (!_isBooked && text.toLowerCase().contains("confirm booking")) {
        _confirmBooking();
        return;
      }

      // Send request to Gemini API
      final response = await http.post(
        Uri.parse("$geminiUrl?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": fullPrompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botResponse = data["candidates"]?[0]["content"]["parts"]?[0]
                ["text"] ??
            "Sorry, I couldn't generate a response.";
        _addMessage(botResponse, false);
      } else {
        _addMessage("Error: ${response.statusCode} - ${response.body}", false);
      }
    } catch (e) {
      _addMessage(
          "Sorry, I encountered an error. Please try again.\nError: $e", false);
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/hotel_logo.png',
              height: 30,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.hotel, size: 30, color: Color(0xFF1D4E5F)),
            ),
            const SizedBox(width: 8),
            const Text(
              'Hotel Central',
              style: TextStyle(
                color: Color(0xFF1D4E5F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Color(0xFF1D4E5F)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF1D4E5F)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                padding: const EdgeInsets.only(top: 15, bottom: 10),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  if (message.customWidget != null) {
                    return message.customWidget!;
                  }
                  return _messages[index]
                      .animate()
                      .fade(duration: const Duration(milliseconds: 300))
                      .slideY(begin: 0.2, end: 0);
                },
              ),
            ),
          ),
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              alignment: Alignment.centerLeft,
              child: const Text(
                "Assistant is typing...",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Container(
            padding:
                const EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.grey[100],
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Write a reply...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: _handleSubmit,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () {},
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4E5F),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        _handleSubmit(_controller.text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Bottom status bar
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final Widget? customWidget;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.customWidget,
  });

  @override
  Widget build(BuildContext context) {
    // If a custom widget is provided, render it
    if (customWidget != null) {
      return customWidget!;
    }

    // Otherwise, render the text message
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4E5F),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(
                  Icons.hotel,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1D4E5F) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/100'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
