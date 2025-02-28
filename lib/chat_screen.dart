// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:concierge/chat%20services/room_booking.dart';
// import 'package:concierge/chat%20services/room_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<ChatMessage> _messages = [];
//   bool _isTyping = false;
//   bool _isBooked = false;
//   late RoomBooking _roomBooking;

//   final List<String> bookingKeywords = [
//     "book",
//     "booking",
//     "reserve",
//     "reservation",
//     "room",
//     "stay",
//     "accommodation",
//     "check-in",
//     "check out",
//     "availability",
//     "available rooms",
//     "rent",
//     "book a room",
//     "book room",
//     "reserve room",
//     "book stay",
//     "reserve stay",
//   ];

//   final String apiKey =
//       "AIzaSyC0bVWxKf34hDBUNzktCiVwGNyk0a1JAR8"; // Replace with your actual API key
//   final String geminiUrl =
//       "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

//   @override
//   void initState() {
//     super.initState();
//     _roomBooking =
//         RoomBooking(_addMessage, _addRoomCards); // Initialize RoomBooking
//     _addInitialMessages();
//   }

//   void _addInitialMessages() async {
//     String userName = await _fetchUserName(); // Fetch user's name
//     String welcomeMessage =
//         "Welcome, $userName, to The Taj Mahal Palace, Mumbai! I'm your virtual concierge. How can I assist you today?";
//     _addMessage(welcomeMessage, false);
//   }

//   Future<String> _fetchUserName() async {
//     String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
//     if (userId.isEmpty) return "guest"; // Default if user is not logged in

//     DocumentSnapshot userDoc =
//         await FirebaseFirestore.instance.collection('users').doc(userId).get();
//     return userDoc.exists
//         ? userDoc.get('name')
//         : "Guest"; // Fetch name or default
//   }

//   void _addMessage(String text, bool isUser) {
//     setState(() {
//       _messages.add(ChatMessage(text: text, isUser: isUser));
//     });

//     // Scroll to bottom after message is added
//     Future.delayed(const Duration(milliseconds: 100), () {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     });
//   }

//   void _addRoomCards(Widget roomCards) {
//     print("Adding room cards to chat"); // Debug log
//     setState(() {
//       _messages.add(ChatMessage(
//         text: "",
//         isUser: false,
//         customWidget: roomCards,
//       ));
//     });

//     // Scroll to bottom after room cards are added
//     Future.delayed(const Duration(milliseconds: 100), () {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     });
//   }

//   void _confirmBooking() {
//     setState(() {
//       _isBooked = true;
//     });
//     _addMessage(
//         "Your booking has been confirmed! How can I assist you further?",
//         false);
//   }

// //   Future<void> _handleSubmit(String text) async {
// //     if (text.trim().isEmpty) return; // Ignore empty messages

// //     _controller.clear();
// //     _addMessage(text, true);

// //     setState(() {
// //       _isTyping = true;
// //     });

// //     try {
// //       // Check if the user's input is related to room booking
// //       bool isBookingRelated = bookingKeywords
// //           .any((keyword) => text.toLowerCase().contains(keyword));

// //       if (isBookingRelated) {
// //         await _roomBooking.handleRoomBooking(text);
// //         return;
// //       }

// //       // System prompt for before booking
// //       final String preBookingPrompt = """
// // You are a virtual concierge for The Taj Mahal Palace, Mumbai. Your role is to assist potential guests with information about the hotel and its services. However, since the guest has not yet confirmed their booking, you can only provide information and cannot assist with bookings or additional services.

// // You are fluent in multiple Indian languages, including Hindi, English, and Hinglish (Hindi written in English). Respond in the same language or style as the guest's query.

// // Examples of tasks you can assist with:
// // - Providing information about room types, rates, and availability.
// // - Sharing details about hotel amenities (e.g., pool, gym, spa, restaurants).
// // - Offering information about check-in/check-out times, late check-out, or early check-in.
// // - Providing details about nearby attractions, restaurants, or shopping areas.
// // - Sharing the hotel's policies (e.g., cancellation, pet policies).

// // Please respond only to queries related to the hotel and its services. If the guest asks about booking or additional services, politely inform them that these can be accessed after confirming their booking.
// // """;

// //       // System prompt for after booking
// //       final String postBookingPrompt = """
// // You are a virtual concierge for The Taj Mahal Palace, Mumbai. The guest has confirmed their booking, and you can now assist them with all hotel-related services.

// // You are fluent in multiple Indian languages, including Hindi, English, and Hinglish (Hindi written in English). Respond in the same language or style as the guest's query.

// // Examples of tasks you can assist with:
// // - Providing the hotel's restaurant menu or room service options.
// // - Assisting with transportation arrangements (e.g., taxis, shuttles).
// // - Offering recommendations for nearby attractions, restaurants, or shopping areas.
// // - Helping with additional requests like extra towels, room upgrades, or late check-out.
// // - Providing directions or maps for local areas.
// // """;

// //       // Combine the appropriate prompt with the user's input
// //       final String fullPrompt = _isBooked
// //           ? "$postBookingPrompt\n\nGuest: $text"
// //           : "$preBookingPrompt\n\nGuest: $text";

// //       // Handle booking confirmation
// //       if (!_isBooked && text.toLowerCase().contains("confirm booking")) {
// //         _confirmBooking();
// //         return;
// //       }

// //       // Send request to Gemini API
// //       final response = await http.post(
// //         Uri.parse("$geminiUrl?key=$apiKey"),
// //         headers: {"Content-Type": "application/json"},
// //         body: jsonEncode({
// //           "contents": [
// //             {
// //               "parts": [
// //                 {"text": fullPrompt}
// //               ]
// //             }
// //           ]
// //         }),
// //       );

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);
// //         final botResponse = data["candidates"]?[0]["content"]["parts"]?[0]
// //                 ["text"] ??
// //             "Sorry, I couldn't generate a response.";
// //         _addMessage(botResponse, false);
// //       } else {
// //         _addMessage("Error: ${response.statusCode} - ${response.body}", false);
// //       }
// //     } catch (e) {
// //       _addMessage(
// //           "Sorry, I encountered an error. Please try again.\nError: $e", false);
// //     } finally {
// //       setState(() {
// //         _isTyping = false;
// //       });
// //     }
// //   }
//   Future<void> _handleSubmit(String text) async {
//     if (text.trim().isEmpty) return; // Ignore empty messages

//     _controller.clear();
//     _addMessage(text, true);

//     setState(() {
//       _isTyping = true;
//     });

//     try {
//       // Initialize RoomService
//       final roomService = RoomService(_addMessage, _addRoomCards);

//       // Check if the user's input is related to room booking
//       bool isBookingRelated = bookingKeywords
//           .any((keyword) => text.toLowerCase().contains(keyword));

//       if (isBookingRelated) {
//         await _roomBooking.handleRoomBooking(text);
//         return;
//       }

//       // Check if the user's input is related to room services
//       if (roomService.isServiceRelated(text)) {
//         await roomService.handleServiceRequest(text);
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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: Row(
//           children: [
//             Image.asset(
//               'assets/hotel_logo.png',
//               height: 30,
//               errorBuilder: (context, error, stackTrace) =>
//                   const Icon(Icons.hotel, size: 30, color: Color(0xFF1D4E5F)),
//             ),
//             const SizedBox(width: 8),
//             const Text(
//               'Hotel Central',
//               style: TextStyle(
//                 color: Color(0xFF1D4E5F),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.fullscreen, color: Color(0xFF1D4E5F)),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_horiz, color: Color(0xFF1D4E5F)),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//               ),
//               child: ListView.builder(
//                 controller: _scrollController,
//                 itemCount: _messages.length,
//                 padding: const EdgeInsets.only(top: 15, bottom: 10),
//                 itemBuilder: (context, index) {
//                   final message = _messages[index];
//                   if (message.customWidget != null) {
//                     return message.customWidget!;
//                   }
//                   return _messages[index]
//                       .animate()
//                       .fade(duration: const Duration(milliseconds: 300))
//                       .slideY(begin: 0.2, end: 0);
//                 },
//               ),
//             ),
//           ),
//           if (_isTyping)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//               alignment: Alignment.centerLeft,
//               child: const Text(
//                 "Assistant is typing...",
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ),
//           Container(
//             padding:
//                 const EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 10),
//             color: Colors.white,
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(30),
//                       color: Colors.grey[100],
//                     ),
//                     child: TextField(
//                       controller: _controller,
//                       decoration: const InputDecoration(
//                         hintText: "Write a reply...",
//                         hintStyle: TextStyle(color: Colors.grey),
//                         border: InputBorder.none,
//                         contentPadding:
//                             EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                       ),
//                       onSubmitted: _handleSubmit,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 IconButton(
//                   icon: const Icon(Icons.attach_file, color: Colors.grey),
//                   onPressed: () {},
//                 ),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF1D4E5F),
//                     shape: BoxShape.circle,
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.send_rounded, color: Colors.white),
//                     onPressed: () {
//                       if (_controller.text.isNotEmpty) {
//                         _handleSubmit(_controller.text);
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Bottom status bar
//         ],
//       ),
//     );
//   }
// }

// class ChatMessage extends StatelessWidget {
//   final String text;
//   final bool isUser;
//   final Widget? customWidget;

//   const ChatMessage({
//     super.key,
//     required this.text,
//     required this.isUser,
//     this.customWidget,
//   });

//   @override
//   Widget build(BuildContext context) {
//     // If a custom widget is provided, render it
//     if (customWidget != null) {
//       return customWidget!;
//     }

//     // Otherwise, render the text message
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         mainAxisAlignment:
//             isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!isUser)
//             Container(
//               margin: const EdgeInsets.only(right: 8),
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1D4E5F),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: const Center(
//                 child: Icon(
//                   Icons.hotel,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//               ),
//             ),
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.7,
//               ),
//               decoration: BoxDecoration(
//                 color: isUser ? const Color(0xFF1D4E5F) : Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 5,
//                     offset: const Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Text(
//                 text,
//                 style: TextStyle(
//                   color: isUser ? Colors.white : Colors.black87,
//                   fontSize: 20,
//                 ),
//               ),
//             ),
//           ),
//           if (isUser)
//             Container(
//               margin: const EdgeInsets.only(left: 8),
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: Colors.white,
//                   width: 2,
//                 ),
//                 image: const DecorationImage(
//                   image: NetworkImage('https://i.pravatar.cc/100'),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isRecording = false;
  bool _isTyping = false;
  late AnimationController _micAnimationController;

  // Sample hotel info for bot responses
  final Map<String, String> _hotelInfo = {
    'checkout': '12:00 PM',
    'breakfast': '7:00 AM to 10:30 AM in the Main Restaurant',
    'wifi': 'Network: Hotel_Guest, Password: welcome2025',
    'pool': 'Open from 7:00 AM to 9:00 PM',
    'spa': 'Open from 9:00 AM to 8:00 PM.',
  };

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Add welcome message
    _addBotMessage(
        "Hello Ishan! I'm your virtual concierge. How can I help you today?");
  }

  @override
  void dispose() {
    _textController.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // Add user message
    ChatMessage message = ChatMessage(
      text: text,
      isUser: true,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
    });

    message.animationController.forward();

    // Simulate bot typing response
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isTyping = false;
      });
      _handleBotResponse(text);
    });
  }

  void _handleBotResponse(String userMessage) {
    String botResponse = "";
    userMessage = userMessage.toLowerCase();

    // Simple response logic
    if (userMessage.contains('hello') || userMessage.contains('hi')) {
      botResponse = "Hello! How can I assist you with your stay?";
    } else if (userMessage.contains('checkout')) {
      botResponse =
          "Checkout time is ${_hotelInfo['checkout']}. Would you like me to arrange late checkout for you?";
    } else if (userMessage.contains('breakfast') ||
        userMessage.contains('food')) {
      botResponse =
          "Breakfast is served ${_hotelInfo['breakfast']}. Would you like to make a reservation?";
    } else if (userMessage.contains('wifi') ||
        userMessage.contains('internet')) {
      botResponse =
          "WiFi details: ${_hotelInfo['wifi']}. Let me know if you have any connection issues!";
    } else if (userMessage.contains('pool') || userMessage.contains('swim')) {
      botResponse =
          "The pool is ${_hotelInfo['pool']}. Towels are provided poolside.";
    } else if (userMessage.contains('spa') || userMessage.contains('massage')) {
      botResponse =
          "Our spa is ${_hotelInfo['spa']}. Would you like me to book a treatment for you?";
    } else if (userMessage.contains('room service') ||
        userMessage.contains('order')) {
      botResponse =
          "Room service is available 24/7. What would you like to order?";
    } else {
      botResponse =
          "I'd be happy to help with that. Would you like me to connect you to a staff member for more assistance?";
    }

    _addBotMessage(botResponse);
  }

  void _addBotMessage(String text) {
    ChatMessage message = ChatMessage(
      text: text,
      isUser: false,
      animationController: AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    setState(() {
      _messages.insert(0, message);
    });

    message.animationController.forward();
  }

  void _handleVoiceInput() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _micAnimationController.repeat(reverse: true);
      // In a real app, you would start speech recognition here
    } else {
      _micAnimationController.reset();
      // In a real app, you would stop speech recognition and process the result

      // Simulate a voice response
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleSubmitted("Tell me about breakfast options");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 49, 64, 87),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar similar to the image
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(0xFF334155).withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, size: 18),
                        color: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'AI Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(0xFF334155).withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.more_vert, size: 18),
                        color: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _messages[index],
                ),
              ),

              // "Bot is typing" indicator
              if (_isTyping)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(0xFF60A5FA),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(0xFFBFDBFE),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Typing...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Input area styled like the image
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Add button similar to the image
                    Container(
                      width: 40,
                      height: 40,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF334155).withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, size: 20),
                        color: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                    // Text field with border
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(0xFF334155).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Color(0xFF475569).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: TextField(
                                  controller: _textController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Ask anything...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.white60),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ),
                            ),
                            // Recording indicator
                            if (_isRecording)
                              Container(
                                width: 8,
                                height: 8,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                            // Mic button
                            InkWell(
                              onTap: _handleVoiceInput,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _isRecording
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isRecording ? Icons.mic : Icons.mic_none,
                                  color: _isRecording
                                      ? Colors.red
                                      : Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                    // Send button
                    Container(
                      width: 40,
                      height: 40,
                      margin: EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 41, 65, 118),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send_rounded),
                        color: Colors.white,
                        iconSize: 20,
                        onPressed: () => _handleSubmitted(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final AnimationController animationController;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if message contains voice recording (for UI display)
    bool hasVoiceRecording = false;
    double recordingDuration = 0.40; // Sample duration in minutes

    final messageUI = Container(
      margin: EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: isUser ? 50.0 : 0.0,
        right: isUser ? 0.0 : 50.0,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Timestamp for messages
          Padding(
            padding: EdgeInsets.only(bottom: 4.0, left: 8.0, right: 8.0),
            child: Text(
              isUser ? "1 min ago" : "3 min ago", // Sample timestamps
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ),
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message bubble
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Color.fromARGB(255, 41, 65, 118)
                        : Color(0xFF334155).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasVoiceRecording && isUser)
                        // Voice recording UI (similar to the image)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              // Voice waveform visualization (simplified)
                              Row(
                                children: List.generate(10, (index) {
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: 1),
                                    width: 2,
                                    height: 5 + Random().nextInt(10).toDouble(),
                                    color: Colors.white,
                                  );
                                }),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "$recordingDuration",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else
                        // Regular text message
                        Text(
                          text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // For bot messages that have a pattern similar to those in the image
          if (!isUser && text.contains("3D"))
            Container(
              margin: EdgeInsets.only(top: 12, left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "•",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "You can create the illusion of 3D by strategically layering 2D shapes and applying effects like gradients, shadows, and bevels.",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "•",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "There are also [YouTube videos] available that walk you through this process step-by-step.",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  // Timestamp and like/dislike buttons
                  Padding(
                    padding: EdgeInsets.only(left: 12, top: 8),
                    child: Row(
                      children: [
                        Text(
                          "Just now",
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.thumb_up_outlined,
                            color: Colors.white60, size: 14),
                        SizedBox(width: 16),
                        Icon(Icons.thumb_down_outlined,
                            color: Colors.white60, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
      child: messageUI,
    );
  }
}
