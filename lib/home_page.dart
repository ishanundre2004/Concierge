// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // For QR code generation
// import 'package:flutter/services.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:porcupine_flutter/porcupine_manager.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   String? _bookingId;
//   String? _qrData;
//   late PorcupineManager _porcupineManager;
//   String _wakeWordDetected = "";

//   String text = "stop service";

//   @override
//   void initState() {
//     super.initState();
//     _initializePorcupine();
//     _startForegroundTask();
//   }

//   Future<void> _initializePorcupine() async {
//     try {
//       // Load the wake word model from assets
//       final wakeWordModel =
//           await rootBundle.load('assets/Hey-Concierge_en_android_v3_0_0.ppn');

//       // Initialize Porcupine
//       _porcupineManager = await PorcupineManager.fromKeywordPaths(
//         "6iqWSRYGghb0+i6SU2V9t4ShEUjNQ5PMrT1GalMoifZAnGXXvPfY0Q==", // Replace with your access key
//         [
//           "assets/Hey-Concierge_en_android_v3_0_0.ppn"
//         ], // Path to the wake word model
//         // [0.7], // Sensitivity (0 to 1)
//         _wakeWordCallback,
//       );

//       // Start listening for the wake word
//       await _porcupineManager.start();
//     } catch (e) {
//       print("Failed to initialize Porcupine: $e");
//     }
//   }

//   void _wakeWordCallback(int keywordIndex) {
//     setState(() {
//       _wakeWordDetected = "Wake word detected!";
//     });
//   }

//   Future<void> _startForegroundTask() async {
//     // Request microphone permission
//     var status = await Permission.microphone.status;
//     if (!status.isGranted) {
//       status = await Permission.microphone.request();
//       if (!status.isGranted) {
//         throw Exception('Microphone permission denied');
//       }
//     }

//     // Start the foreground task
//     await FlutterForegroundTask.startService(
//       notificationTitle: 'Wake Word Detection',
//       notificationText: 'Listening for "Hey Concierge!"',
//       callback: _initializePorcupine,
//     );
//   }

//   @override
//   void dispose() {
//     _porcupineManager.stop();
//     _porcupineManager.delete();
//     FlutterForegroundTask.stopService();
//     super.dispose();
//   }

//   // Convert Timestamp to a serializable format (milliseconds since epoch)
//   Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
//     final result = Map<String, dynamic>.from(data);

//     result.forEach((key, value) {
//       if (value is Timestamp) {
//         // Convert Timestamp to millisecondsSinceEpoch
//         result[key] = {
//           'seconds': value.seconds,
//           'nanoseconds': value.nanoseconds,
//           '_isTimestamp': true // Add a marker to identify this as a Timestamp
//         };
//       }
//     });

//     return result;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               _wakeWordDetected,
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:concierge/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:lottie/lottie.dart'; // For animations

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String? _bookingId;
  String? _qrData;
  late PorcupineManager _porcupineManager;
  String _wakeWordDetected = "";
  bool _showAnimation = false;
  late AnimationController _animationController;

  // Sample data for bookings and updates (replace with your Firestore data)
  final List<Map<String, dynamic>> _bookings = [
    {
      'hotelName': 'Grand Hyatt',
      'checkIn': 'Feb 28, 2025',
      'checkOut': 'Mar 3, 2025',
      'roomType': 'Deluxe Suite',
      'status': 'Confirmed',
      'bookingId': 'BK123456'
    },
    {
      'hotelName': 'Marriott Resort',
      'checkIn': 'Mar 15, 2025',
      'checkOut': 'Mar 20, 2025',
      'roomType': 'Ocean View Room',
      'status': 'Pending',
      'bookingId': 'BK789012'
    }
  ];

  final List<Map<String, dynamic>> _updates = [
    {
      'type': 'offer',
      'title': 'Valentine Special',
      'description': 'Get 25% off on couples spa treatment during your stay',
      'validUntil': 'Mar 15, 2025',
      'image': 'https://example.com/spa.jpg'
    },
    {
      'type': 'update',
      'title': 'Pool Maintenance',
      'description':
          'The main pool will be closed from 2 PM to 4 PM on March 1st',
      'date': 'Mar 1, 2025',
      'image': 'https://example.com/pool.jpg'
    },
    {
      'type': 'offer',
      'title': 'Fine Dining Experience',
      'description': 'Complimentary welcome drink at our rooftop restaurant',
      'validUntil': 'Mar 10, 2025',
      'image': 'https://example.com/restaurant.jpg'
    }
  ];

  String text = "stop service";

  @override
  void initState() {
    super.initState();
    _initializePorcupine();
    _startForegroundTask();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _initializePorcupine() async {
    try {
      // Load the wake word model from assets
      final wakeWordModel =
          await rootBundle.load('assets/Hey-Concierge_en_android_v3_0_0.ppn');

      // Initialize Porcupine
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        "6iqWSRYGghb0+i6SU2V9t4ShEUjNQ5PMrT1GalMoifZAnGXXvPfY0Q==", // Replace with your access key
        [
          "assets/Hey-Concierge_en_android_v3_0_0.ppn"
        ], // Path to the wake word model
        _wakeWordCallback,
      );

      // Start listening for the wake word
      await _porcupineManager.start();
    } catch (e) {
      print("Failed to initialize Porcupine: $e");
    }
  }

  void _wakeWordCallback(int keywordIndex) {
    setState(() {
      _wakeWordDetected = "Wake word detected!";
      _showAnimation = true;
    });

    // Start animation
    _animationController.forward().then((_) {
      // Navigate to chat screen after animation completes
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen()),
      ).then((_) {
        // Reset animation when returning from chat screen
        _animationController.reset();
        setState(() {
          _showAnimation = false;
        });
      });
    });
  }

  Future<void> _startForegroundTask() async {
    // Request microphone permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission denied');
      }
    }

    // Start the foreground task
    await FlutterForegroundTask.startService(
      notificationTitle: 'Wake Word Detection',
      notificationText: 'Listening for "Hey Concierge!"',
      callback: _initializePorcupine,
    );
  }

  @override
  void dispose() {
    _porcupineManager.stop();
    _porcupineManager.delete();
    FlutterForegroundTask.stopService();
    _animationController.dispose();
    super.dispose();
  }

  // Convert Timestamp to a serializable format (milliseconds since epoch)
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    result.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Timestamp to millisecondsSinceEpoch
        result[key] = {
          'seconds': value.seconds,
          'nanoseconds': value.nanoseconds,
          '_isTimestamp': true // Add a marker to identify this as a Timestamp
        };
      }
    });

    return result;
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
        child: Stack(
          children: [
            // Main Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom App Bar similar to ChatScreen
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Concierge',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(0xFF334155).withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.settings, size: 18),
                                  color: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                              SizedBox(width: 12),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        'https://randomuser.me/api/portraits/men/43.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Welcome Message
                    Text(
                      'Welcome, Ishan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Here are your active bookings and updates',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Updates & Offers Section
                    Text(
                      'Updates & Offers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _updates.length,
                        itemBuilder: (context, index) {
                          final update = _updates[index];
                          final bool isOffer = update['type'] == 'offer';

                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFF334155).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Color(0xFF475569).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isOffer
                                          ? Color.fromARGB(255, 41, 65, 118)
                                          : Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isOffer ? 'OFFER' : 'UPDATE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    update['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    update['description'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Spacer(),
                                  Text(
                                    isOffer
                                        ? 'Valid until: ${update['validUntil']}'
                                        : 'Date: ${update['date']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 25),
                    
                    // Your Bookings Section
                    Text(
                      'Your Bookings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bookings ListView
                    Expanded(
                      flex: 3,
                      child: _bookings.isEmpty
                          ? Center(
                              child: Text(
                                'No active bookings',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white60,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _bookings.length,
                              itemBuilder: (context, index) {
                                final booking = _bookings[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF334155).withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Color(0xFF475569).withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                booking['hotelName'],
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: booking['status'] ==
                                                        'Confirmed'
                                                    ? Color(0xFF2563EB)
                                                    : Color.fromARGB(
                                                        255, 41, 65, 118),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                booking['status'],
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Check-in',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    booking['checkIn'],
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Check-out',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    booking['checkOut'],
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.hotel,
                                              color: Colors.white70,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              booking['roomType'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.confirmation_number,
                                              color: Colors.white70,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Booking ID: ${booking['bookingId']}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Chat Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ChatScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Color.fromARGB(255, 41, 65, 118),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline),
                              SizedBox(width: 8),
                              Text(
                                'Start Chat with Concierge',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Wake Word Animation Overlay
            if (_showAnimation)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/voice_recognition.json',
                        controller: _animationController,
                        width: 200,
                        height: 200,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Hey Concierge!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Taking you to chat...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}