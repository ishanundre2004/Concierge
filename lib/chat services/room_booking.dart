import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:qr_flutter/qr_flutter.dart'; // For QR code generation
import 'package:image/image.dart'
    as img; // Use 'img' as a prefix // For QR code generation

class RoomBooking {
  final Function(String, bool) _addMessage;
  final Function(Widget)
      _addRoomCards; // Callback to add room cards to the chat
  String userId = "";
  RoomBooking(this._addMessage, this._addRoomCards);
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  String getCurrentUserId() {
    final User? user = _auth.currentUser;
    return user != null ? user.uid : "guest_001";
  }

  Future<void> handleRoomBooking(String text) async {
    final lowerText = text.toLowerCase();
    bool isBookingRelated =
        bookingKeywords.any((keyword) => lowerText.contains(keyword));

    if (isBookingRelated) {
      final availableRooms = await _fetchAvailableRooms();

      if (availableRooms.isEmpty) {
        _addMessage(
            "No rooms are available at the moment. Please try again later.",
            false);
        return;
      }

      // Display room cards in the chat
      _addRoomCards(_buildRoomCards(availableRooms));
    }
  }

  Widget _buildRoomCards(List<Map<String, dynamic>> availableRooms) {
    return Builder(
      builder: (context) {
        return SizedBox(
          height: 200, // Adjust height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: availableRooms.length,
            itemBuilder: (context, index) {
              final room = availableRooms[index];
              return GestureDetector(
                onTap: () => _handleRoomSelection(context, room),
                child: _buildRoomCard(room),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    return Container(
      width: 160, // Adjust width as needed
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              room['imageUrl'] ?? 'https://via.placeholder.com/160x100',
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Room Details
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['type'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${room['pricePerNight']} / night",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Max Guests: ${room['maxGuests']}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Available: ${room['available']}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableRooms() async {
    final roomsSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .where('status', isEqualTo: 'available')
        .get();

    // Group rooms by type
    final Map<String, List<Map<String, dynamic>>> roomsByType = {};

    for (final room in roomsSnapshot.docs) {
      final data = room.data();
      final type = data['type'];

      if (!roomsByType.containsKey(type)) {
        roomsByType[type] = [];
      }

      roomsByType[type]!.add({
        'pricePerNight': data['pricePerNight'],
        'maxGuests': data['maxGuests'],
        'roomId': room.id,
        'imageUrl': data['imageUrl'], // Add image URL from Firestore
      });
    }

    // Prepare the response
    final List<Map<String, dynamic>> availableRooms = [];

    roomsByType.forEach((type, rooms) {
      availableRooms.add({
        'type': type,
        'pricePerNight': rooms.first['pricePerNight'],
        'maxGuests': rooms.first['maxGuests'],
        'available': rooms.length,
        'imageUrl': rooms.first['imageUrl'], // Use the first room's image URL
        'bookingUrl': "https://example.com/book/${rooms.first['roomId']}",
      });
    });

    return availableRooms;
  }

  void _handleRoomSelection(BuildContext context, Map<String, dynamic> room) {
    // Show a dialog to input check-in and check-out dates
    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime? checkInDate;
        DateTime? checkOutDate;

        return AlertDialog(
          title: const Text("Select Dates"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selectedDate != null) {
                    checkInDate = selectedDate;
                  }
                },
                child: Text(
                  checkInDate == null
                      ? "Select Check-In Date"
                      : "Check-In: ${DateFormat('yyyy-MM-dd').format(checkInDate!)}",
                ),
              ),
              TextButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: checkInDate ?? DateTime.now(),
                    firstDate: checkInDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (selectedDate != null) {
                    checkOutDate = selectedDate;
                  }
                },
                child: Text(
                  checkOutDate == null
                      ? "Select Check-Out Date"
                      : "Check-Out: ${DateFormat('yyyy-MM-dd').format(checkOutDate!)}",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (checkInDate != null && checkOutDate != null) {
                  Navigator.of(context).pop();
                  await _createBooking(room, checkInDate!, checkOutDate!);
                } else {
                  _addMessage(
                      "Please select both check-in and check-out dates.",
                      false);
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createBooking(
    Map<String, dynamic> room,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    try {
      if (room == null || checkInDate == null || checkOutDate == null) {
        _addMessage("Invalid booking data. Please try again.", false);
        return;
      }

      final totalNights = checkOutDate.difference(checkInDate).inDays;
      final totalPrice = room['pricePerNight'] * totalNights;

      // Fetch all available rooms of the selected type
      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('type', isEqualTo: room['type'])
          .where('status', isEqualTo: 'available')
          .get();

      if (roomsSnapshot.docs.isEmpty) {
        _addMessage("No rooms of this type are available for booking.", false);
        return;
      }

      // Randomly select a room from the available rooms
      final randomIndex = Random().nextInt(roomsSnapshot.docs.length);
      final selectedRoom = roomsSnapshot.docs[randomIndex];
      final roomId = selectedRoom.id;

      if (roomId == null) {
        _addMessage("Failed to select a room. Please try again.", false);
        return;
      }

      final bookingId = "booking_${DateTime.now().millisecondsSinceEpoch}";
      // final String userId = userId;
      // Replace with actual user ID
      final userId = getCurrentUserId();

      // Booking data
      final bookingData = {
        "bookingId": bookingId,
        "userId": userId,
        "roomId": roomId,
        "checkInDate": checkInDate, // DateTime object
        "checkOutDate": checkOutDate, // DateTime object
        "totalNights": totalNights,
        "totalPrice": totalPrice,
        "status": "confirmed",
        "createdAt": FieldValue.serverTimestamp(), // Firestore Timestamp
      };

      // Generate QR code data
      final qrData = jsonEncode({
        "bookingId": bookingId,
        "userId": userId,
        "roomId": roomId,
        "checkInDate":
            checkInDate.toIso8601String(), // Convert DateTime to String
        "checkOutDate":
            checkOutDate.toIso8601String(), // Convert DateTime to String
        "totalNights": totalNights,
        "totalPrice": totalPrice,
      });

      // Generate QR code in base64 format
      final qrBase64 = await generateQrCodeBase64(qrData);

      // Add QR code to booking data
      bookingData["qrCode"] = qrBase64;

      // Save booking data to Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .set(bookingData);

      // Update the selected room's status to "booked"
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .update({'status': 'booked', 'currentBookingId' : bookingId });

      // Display booking details and QR code
      _addMessage("Booking confirmed! Here are your details:", false);
      _addRoomCards(_buildBookingDetailsCard(bookingData));
    } catch (e) {
      _addMessage("Failed to create booking. Please try again.", false);
      print("Error during booking creation: $e"); // Debug log
    }
  }

  Widget _buildBookingDetailsCard(Map<String, dynamic> bookingData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Booking ID: ${bookingData['bookingId']}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check-In: ${DateFormat('yyyy-MM-dd').format(bookingData['checkInDate'])}", // Remove toDate()
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "Check-Out: ${DateFormat('yyyy-MM-dd').format(bookingData['checkOutDate'])}", // Remove toDate()
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "Total Nights: ${bookingData['totalNights']}",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "Total Price: ₹${bookingData['totalPrice']}",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          // Display the QR code if available
          if (bookingData['qrCode'] != null)
            Image.memory(
              base64Decode(bookingData['qrCode']),
              height: 100,
              width: 100,
            ),
        ],
      ),
    );
  }

  Future<String> generateQrCodeBase64(String data) async {
    try {
      if (data.isEmpty) {
        throw Exception("QR data cannot be empty");
      }

      print("Generating QR code for data: $data"); // Debug log

      // Create a QR code painter
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        // color: const Color(0xFF000000),
        gapless: true,
        // emptyColor: Colors.white,
      );

      // Render the QR code to an image
      final imageSize = 300.0;
      final picData = await painter.toImageData(imageSize);

      if (picData == null) {
        throw Exception("Failed to generate QR image data");
      }

      // Convert the image to a format that can be compressed
      final imageBytes = picData.buffer.asUint8List();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("Failed to decode QR image");
      }

      // Resize the image to reduce its dimensions (optional)
      final resizedImage =
          img.copyResize(image, width: 150); // Adjust width as needed

      // Compress the image (reduce quality)
      final compressedImageBytes =
          img.encodeJpg(resizedImage, quality: 50); // Adjust quality (0-100)

      // Convert the compressed image to base64
      final qrBase64 = base64Encode(compressedImageBytes);

      print("QR code generated and compressed successfully"); // Debug log
      return qrBase64;
    } catch (e) {
      print("Error generating QR code: $e"); // Debug log
      rethrow;
    }
  }
}







// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';

// class RoomBooking {
//   final Function(String, bool) _addMessage;
//   final Function(Widget)
//       _addRoomCards; // Callback to add room cards to the chat
//   String? _selectedRoomType;

//   RoomBooking(this._addMessage, this._addRoomCards);

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

//   Future<void> handleRoomBooking(String text) async {
//     final lowerText = text.toLowerCase();
//     bool isBookingRelated =
//         bookingKeywords.any((keyword) => lowerText.contains(keyword));

//     if (isBookingRelated) {
//       if (_selectedRoomType == null) {
//         // Show available room types
//         final availableRooms = await _fetchAvailableRooms();

//         if (availableRooms.isEmpty) {
//           _addMessage(
//               "No rooms are available at the moment. Please try again later.",
//               false);
//           return;
//         }

//         // Display room cards in the chat
//         _addRoomCards(_buildRoomCards(availableRooms));
//       } else {
//         // Parse dates using Gemini API
//         final dates = await _parseDatesWithGemini(text);
//         if (dates == null) {
//           _addMessage(
//               "Please provide valid dates (e.g., '26 Feb 2025 to 1 Mar 2025').",
//               false);
//           return;
//         }

//         // Check room availability
//         final availableRooms = await _checkRoomAvailability(
//             _selectedRoomType!, dates['checkIn']!, dates['checkOut']!);

//         if (availableRooms.isEmpty) {
//           _addMessage(
//               "No ${_selectedRoomType} rooms are available for the selected dates.",
//               false);
//         } else {
//           final response = StringBuffer(
//               "There are ${availableRooms.length} ${_selectedRoomType} rooms available from ${DateFormat('d MMMM y').format(dates['checkIn']!)} to ${DateFormat('d MMMM y').format(dates['checkOut']!)}.\n");
//           response.writeln("Here are the details:");

//           for (final room in availableRooms) {
//             response.writeln(
//                 "- Room ${room['roomNumber']}: ₹${room['pricePerNight']} per night, Max Guests: ${room['maxGuests']}");
//           }

//           _addMessage(response.toString(), false);
//         }

//         _selectedRoomType = null; // Reset selected room type
//       }
//     } else if (text.toLowerCase() == 'deluxe' ||
//         text.toLowerCase() == 'super deluxe') {
//       _selectedRoomType = text;
//       _addMessage(
//           "You selected ${text}. When are you planning to stay? Please provide dates (e.g., '26 Feb 2025 to 1 Mar 2025').",
//           false);
//     }
//   }

//   Widget _buildRoomCards(List<Map<String, dynamic>> availableRooms) {
//     return SizedBox(
//       height: 200, // Adjust height as needed
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: availableRooms.length,
//         itemBuilder: (context, index) {
//           final room = availableRooms[index];
//           return _buildRoomCard(room);
//         },
//       ),
//     );
//   }

//   Widget _buildRoomCard(Map<String, dynamic> room) {
//     return GestureDetector(
//       onTap: () async {
//         // Set the selected room type
//         _selectedRoomType = room['type'];
//         _addMessage(
//             "You selected ${room['type']}. When are you planning to stay? Please provide dates (e.g., '26 Feb 2025 to 1 Mar 2025').",
//             false);
//       },
//       child: Container(
//         width: 160, // Adjust width as needed
//         margin: const EdgeInsets.symmetric(horizontal: 8),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 6,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Room Image
//             ClipRRect(
//               borderRadius:
//                   const BorderRadius.vertical(top: Radius.circular(16)),
//               child: Image.network(
//                 room['imageUrl'] ?? 'https://via.placeholder.com/160x100',
//                 height: 100,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             // Room Details
//             Padding(
//               padding: const EdgeInsets.all(8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     room['type'],
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     "₹${room['pricePerNight']} / night",
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     "Max Guests: ${room['maxGuests']}",
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     "Available: ${room['available']}",
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

  
// }
