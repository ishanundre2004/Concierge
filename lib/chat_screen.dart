import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:concierge/booking.dart';
import 'package:concierge/notification_service.dart';
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
  String userId = "";

  // Sample hotel info for bot responses
  final Map<String, String> _hotelInfo = {
    'checkout': '12:00 PM',
    'breakfast': '7:00 AM to 10:30 AM in the Main Restaurant',
    'wifi': 'Network: Hotel_Guest, Password: welcome2025',
    'pool':
        'Open from 7:00 AM to 9:00 PM. Located on the 3rd floor, accessible via the central elevator or staircase.',
    'spa':
        'Open from 9:00 AM to 8:00 PM. Located on the 2nd floor, next to the fitness center. Please book appointments in advance at the front desk.',
    'gym':
        'Open 24/7. Located on the 2nd floor, next to the spa. Access requires your room keycard. Equipment includes treadmills, weights, and yoga mats.',
    'yoga':
        'Group yoga sessions are held daily at 7:00 AM and 5:00 PM in the rooftop garden. Mats and props are provided. Private sessions can be arranged at the spa.',
    'restaurant':
        'The Main Restaurant is open for breakfast (7:00 AM - 10:30 AM), lunch (12:00 PM - 3:00 PM), and dinner (6:00 PM - 10:00 PM). Located on the ground floor, near the lobby.',
    'room service':
        'Available 24/7. Dial "0" from your room phone to place an order. The menu is available in your room directory.',
    'parking':
        'Valet parking is available at the main entrance. Self-parking is located in the underground garage, accessible via the elevator near the lobby.',
    'business center':
        'Open from 8:00 AM to 8:00 PM. Located on the 1st floor, next to the conference rooms. Services include printing, faxing, and private workstations.',
    'concierge':
        'Our concierge desk is open 24/7 in the lobby. They can assist with tour bookings, transportation, and local recommendations.',
    'laundry':
        'Laundry and dry-cleaning services are available. Drop-off is at the housekeeping office on the 1st floor. Same-day service is available for items received before 10:00 AM.',
    'rooftop bar':
        'Open from 5:00 PM to 11:00 PM. Located on the 10th floor, offering panoramic views of the city. Happy hour is from 5:00 PM to 7:00 PM.',
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

  Future<String?> fetchUserId(String email) async {
    QuerySnapshot users =
        await db.collection("users").where("email", isEqualTo: email).get();
    if (users.docs.isNotEmpty) {
      userId = users.docs.first.id;
    }
    return null;
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

  void _handleBotResponse(String userMessage) async {
    String botResponse = "";
    userMessage = userMessage.toLowerCase();

    // Simple response logic
    if (userMessage.contains('hello') || userMessage.contains('hi')) {
      botResponse = "Hello! How can I assist you with your stay?";
    } else if (userMessage.contains('gym') || userMessage.contains('fitness')) {
      botResponse =
          "Our gym is open 24/7 and is located on the 2nd floor, next to the spa. It includes treadmills, weights, and yoga mats. Access requires your room keycard.";
    } else if (userMessage.contains('yoga')) {
      botResponse =
          "We offer group yoga sessions daily at 7:00 AM and 5:00 PM in the rooftop garden. Mats and props are provided. Private sessions can also be arranged at the spa.";
    } else if (userMessage.contains('restaurant')) {
      botResponse =
          "The Main Restaurant is open for breakfast (7:00 AM - 10:30 AM), lunch (12:00 PM - 3:00 PM), and dinner (6:00 PM - 10:00 PM). It's located on the ground floor, near the lobby.";
    } else if (userMessage.contains('parking')) {
      botResponse =
          "Valet parking is available at the main entrance. Self-parking is located in the underground garage, accessible via the elevator near the lobby.";
    } else if (userMessage.contains('business center')) {
      botResponse =
          "Our business center is open from 8:00 AM to 8:00 PM on the 1st floor, next to the conference rooms. Services include printing, faxing, and private workstations.";
    } else if (userMessage.contains('concierge')) {
      botResponse =
          "Our concierge desk is open 24/7 in the lobby. They can assist with tour bookings, transportation, and local recommendations.";
    } else if (userMessage.contains('laundry')) {
      botResponse =
          "Laundry and dry-cleaning services are available. Drop-off is at the housekeeping office on the 1st floor. Same-day service is available for items received before 10:00 AM.";
    } else if (userMessage.contains('rooftop bar')) {
      botResponse =
          "The rooftop bar is open from 5:00 PM to 11:00 PM on the 10th floor, offering panoramic views of the city. Happy hour is from 5:00 PM to 7:00 PM.";
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
    } else if (userMessage.contains('show me available rooms')) {
      botResponse = await showRoomTypesAndPrices();
    } else if (userMessage.contains('book for')) {
      botResponse = await bookRoom(userId, "2025-03-07", "2025-03-09");
      botResponse = "Would you like me to schedule a cab for pickup ?";
      final notificationService = NotificationService();
      await notificationService.showNotification(
          id: 1, // Unique ID for the notification
          title: "Booking Successful!",
          body:
              "Your room has been booked successfully. Booking ID: booking_1740659697567");
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

              // Lottie animation for "Bot is typing"
              if (_isTyping)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Lottie.asset(
                    'assets/typing.json', // Path to your Lottie animation
                    width: 100,
                    height: 50,
                    fit: BoxFit.contain,
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
