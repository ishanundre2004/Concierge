import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img; // For image manipulation
import 'package:qr/qr.dart'; // For QR code generation
import 'dart:convert'; // For base64 encoding
import 'package:intl/intl.dart'; // For date formatting
import 'package:http/http.dart' as http; // For Gemini API calls

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
                    "Generate a meaningful response in 2-3 lines and recommend/ask a relatable question based on this input: $input"
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
Future<void> showRoomTypesAndPrices() async {
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

    print("Room Types and Prices:");
    roomTypes.forEach((roomType, price) {
      print("$roomType: ₹$price per night");
    });

    // Generate Gemini response
    String input = "Room Types and Prices: ${roomTypes.toString()}";
    String geminiResponse = await generateGeminiResponse(input);
    print("Gemini Response: $geminiResponse");
  } catch (e) {
    print("Error showing room types: $e");
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
        DateTime bookingCheckIn = (bookingData["checkInDate"] as Timestamp).toDate();
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
    String input = "Available $roomType Rooms for $checkInDate to $checkOutDate: ${availableRooms.length} rooms found";
    String geminiResponse = await generateGeminiResponse(input);
    print("Gemini Response: $geminiResponse");
  } catch (e) {
    print("Error showing available rooms: $e");
  }
}

// Function 3: Book a room and update collections
Future<void> bookRoom(String roomId, String userId, String checkInDate,
    String checkOutDate) async {
  try {
    DateTime checkIn = DateFormat("yyyy-MM-dd").parse(checkInDate);
    DateTime checkOut = DateFormat("yyyy-MM-dd").parse(checkOutDate);

    DocumentSnapshot room = await db.collection("rooms").doc(roomId).get();
    if (!room.exists) {
      print("Room not found.");
      return;
    }

    var roomData = room.data() as Map<String, dynamic>;
    if (roomData["status"] != "available") {
      print("Room is not available.");
      return;
    }

    int totalNights = checkOut.difference(checkIn).inDays;
    num totalPrice = totalNights * (roomData["pricePerNight"] is int 
        ? (roomData["pricePerNight"] as int).toDouble() 
        : roomData["pricePerNight"]);

    // Generate QR code data
    final qrData =
        "Booking Details: Room ${roomData['roomNumber']}, Check-In: $checkInDate, Check-Out: $checkOutDate";
    
    // Create QR code
    final qrCode = QrCode.fromData(
      data: qrData,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    
    // Get QR module count (size)
    final moduleCount = qrCode.moduleCount;
    
    // Create a new image with the required width and height
    final qrImage = img.Image(width: moduleCount + 8, height: moduleCount + 8);
    
    // Fill with white background (all pixels)
    for (int y = 0; y < qrImage.height; y++) {
      for (int x = 0; x < qrImage.width; x++) {
        qrImage.setPixel(x, y, img.ColorRgb8(255, 255, 255));
      }
    }
    
    // Draw QR code pixels
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (qrCode.isDark(y, x)) {
          // Draw a black pixel with a 4-pixel margin
          qrImage.setPixel(x + 4, y + 4, img.ColorRgb8(0, 0, 0));
        }
      }
    }

    // Convert the image to PNG and then to base64
    final pngBytes = img.encodePng(qrImage);
    final qrBase64 = base64Encode(pngBytes);

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

    print(
        "Room ${roomData['roomNumber']} booked successfully! Total Price: ₹$totalPrice");

    // Generate Gemini response
    String input =
        "Room ${roomData['roomNumber']} booked successfully! Total Price: ₹$totalPrice";
    String geminiResponse = await generateGeminiResponse(input);
    print("Gemini Response: $geminiResponse");
  } catch (e) {
    print("Error booking room: $e");
  }
}