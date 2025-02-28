import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // For image manipulation
import 'package:qr/qr.dart'; // For QR code generation
import 'dart:convert'; // For base64 encoding
import 'package:intl/intl.dart'; // For date formatting
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart'; // For Gemini API calls

final FirebaseFirestore db = FirebaseFirestore.instance;
const String API_KEY = "AIzaSyC0bVWxKf34hDBUNzktCiVwGNyk0a1JAR8";
const String GEMINI_URL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

// Function to fetch userId from Firestore
Future<String?> fetchUserId(String email) async {
  try {
    QuerySnapshot users =
        await db.collection("users").where("email", isEqualTo: email).get();
    if (users.docs.isNotEmpty) {
      return users.docs.first.id;
    }
    return null;
  } catch (e) {
    print("Error fetching userId: $e");
    return null;
  }
}

// Function to call Gemini API and generate a meaningful response
Future<String> generateGeminiResponse(String input) async {
  try {
    final response = await http.post(
      Uri.parse("$GEMINI_URL?key=$API_KEY"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Generate a meaningful short response in 1-2 lines based on the input (for example oh i found two types of room deluxe and super deluxe. which should i book ?): $input"
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      print("API error: ${response.statusCode} - ${response.body}");
      return "Sorry, I couldn't generate a response at this time.";
    }
  } catch (e) {
    print("Error in Gemini API call: $e");
    return "Sorry, I couldn't generate a response at this time.";
  }
}

// Function 1: Show room types and prices
Future<String> showRoomTypesAndPrices() async {
  try {
    CollectionReference roomsRef = db.collection("rooms");
    QuerySnapshot rooms = await roomsRef.get();
    Map<String, double> roomTypes = {};

    for (var room in rooms.docs) {
      var roomData = room.data() as Map<String, dynamic>;
      String roomType = roomData["type"];
      double price = (roomData["pricePerNight"] is int)
          ? (roomData["pricePerNight"] as int).toDouble()
          : roomData["pricePerNight"];

      if (!roomTypes.containsKey(roomType)) {
        roomTypes[roomType] = price;
      }
    }

    String roomTypesString = "Room Types and Prices:\n";
    roomTypes.forEach((roomType, price) {
      roomTypesString += "$roomType: ₹$price per night\n";
    });

    // Generate Gemini response
    String input = "Room Types and Prices: ${roomTypes.toString()}";
    String geminiResponse = await generateGeminiResponse(input);
    return "$roomTypesString\n$geminiResponse\nTell me date and which dates are you looking for ?";
  } catch (e) {
    return "Error showing room types: $e";
  }
}

// Function 2: Show available rooms of a selected type for a given date range
Future<void> showAvailableRooms(
    String roomType, String checkInDate, String checkOutDate) async {
  try {
    DateTime checkIn = DateFormat("yyyy-MM-dd").parse(checkInDate);
    DateTime checkOut = DateFormat("yyyy-MM-dd").parse(checkOutDate);

    QuerySnapshot rooms = await db
        .collection("rooms")
        .where("type", isEqualTo: roomType)
        .where("status", isEqualTo: "available")
        .get();

    List<Map<String, dynamic>> availableRooms = [];

    for (var room in rooms.docs) {
      var roomData = room.data() as Map<String, dynamic>;
      String roomId = room.id; // Using document ID as roomId

      QuerySnapshot bookings = await db
          .collection("bookings")
          .where("roomId", isEqualTo: roomId)
          .get();

      bool isAvailable = true;
      for (var booking in bookings.docs) {
        var bookingData = booking.data() as Map<String, dynamic>;
        DateTime bookingCheckIn =
            (bookingData["checkInDate"] as Timestamp).toDate();
        DateTime bookingCheckOut =
            (bookingData["checkOutDate"] as Timestamp).toDate();

        if (!(checkOut.isBefore(bookingCheckIn) ||
            checkIn.isAfter(bookingCheckOut))) {
          isAvailable = false;
          break;
        }
      }

      if (isAvailable) {
        roomData['id'] = roomId; // Add the document ID to the room data
        availableRooms.add(roomData);
      }
    }

    print("Available $roomType Rooms:");
    if (availableRooms.isEmpty) {
      print("No rooms available for the selected dates.");
    } else {
      for (var room in availableRooms) {
        print(
            "Room Number: ${room['roomNumber']}, Max Guests: ${room['maxGuests']}, Price: ₹${room['pricePerNight']} per night");
      }
    }

    // Generate Gemini response
    String input =
        "Available $roomType Rooms for $checkInDate to $checkOutDate: ${availableRooms.length} rooms found";
    String geminiResponse = await generateGeminiResponse(input);
    print("Gemini Response: $geminiResponse");
  } catch (e) {
    print("Error showing available rooms: $e");
  }
}

// Function 3: Book a room and update collections

Future<String> bookRoom(
    String userId, String checkInDate, String checkOutDate) async {
  try {
    // List of room IDs to choose from
    List<String> roomIds = [
      "room_101",
      "room_102",
      "room_103",
      "room_104",
      "room_105"
    ];

    // Randomly select a room ID
    Random random = Random();
    String roomId = roomIds[random.nextInt(roomIds.length)];

    DateTime checkIn = DateFormat("yyyy-MM-dd").parse(checkInDate);
    DateTime checkOut = DateFormat("yyyy-MM-dd").parse(checkOutDate);

    // Fetch the selected room
    DocumentSnapshot room = await db.collection("rooms").doc(roomId).get();
    if (!room.exists) {
      return "Room not found.";
    }

    var roomData = room.data() as Map<String, dynamic>;
    if (roomData["status"] != "available") {
      return "Room is not available.";
    }

    // Calculate total nights and price
    int totalNights = checkOut.difference(checkIn).inDays;
    num totalPrice = totalNights *
        (roomData["pricePerNight"] is int
            ? (roomData["pricePerNight"] as int).toDouble()
            : roomData["pricePerNight"]);

    // Generate QR code data
    final qrData =
        "Booking Details: Room ${roomData['roomNumber']}, Check-In: $checkInDate, Check-Out: $checkOutDate";

    // Generate QR Code as an image
    ByteData? byteData = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
      color: Colors.black,
      emptyColor: Colors.white,
    ).toImageData(200);

    if (byteData == null) {
      return "Failed to generate QR code.";
    }

    Uint8List pngBytes = byteData.buffer.asUint8List();
    String qrBase64 = base64Encode(pngBytes);

    // Create booking document
    String bookingId = "booking_${DateTime.now().millisecondsSinceEpoch}";
    Map<String, dynamic> bookingData = {
      "bookingId": bookingId,
      "checkInDate": Timestamp.fromDate(checkIn),
      "checkOutDate": Timestamp.fromDate(checkOut),
      "createdAt": Timestamp.now(),
      "qrCode": qrBase64,
      "roomId": roomId,
      "status": "confirmed",
      "totalNights": totalNights,
      "totalPrice": totalPrice,
      "userId": userId,
    };

    await db.collection("bookings").doc(bookingId).set(bookingData);

    // Update room status
    await db.collection("rooms").doc(roomId).update({
      "status": "booked",
      "currentBookingId": bookingId,
    });

    // Return the booking confirmation message
    return "Room ${roomData['roomNumber']} booked successfully! Total Price: ₹$totalPrice! Booking ID is $bookingId\nSuccessfully added to the calendar.";
  } catch (e) {
    return "Error booking room: $e";
  }
}
