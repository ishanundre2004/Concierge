import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SpaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch Spa Service Details
  Future<Map<String, dynamic>> getSpaServiceDetails() async {
    try {
      DocumentSnapshot spaServiceSnapshot = await _firestore
          .collection('extraServices')
          .doc('extra_service_001') // Assuming 'extra_service_001' is the Spa service ID
          .get();

      if (spaServiceSnapshot.exists) {
        return spaServiceSnapshot.data() as Map<String, dynamic>;
      } else {
        throw Exception('Spa service not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch spa service details: $e');
    }
  }

  // Fetch Available Time Slots
  Future<List<Map<String, dynamic>>> getAvailableTimeSlots() async {
    try {
      DocumentSnapshot spaServiceSnapshot = await _firestore
          .collection('extraServices')
          .doc('extra_service_001') // Assuming 'extra_service_001' is the Spa service ID
          .get();

      if (spaServiceSnapshot.exists) {
        Map<String, dynamic> spaServiceData =
            spaServiceSnapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> timeSlots =
            List<Map<String, dynamic>>.from(spaServiceData['timeSlots'] ?? []);

        // Filter available slots
        List<Map<String, dynamic>> availableSlots =
            timeSlots.where((slot) => slot['status'] == 'available').toList();

        return availableSlots;
      } else {
        throw Exception('Spa service not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch available time slots: $e');
    }
  }

  // Book Spa Service
  Future<void> bookSpaService(String timeSlot, String userId) async {
    try {
      // Update the time slot status to "booked"
      DocumentReference spaServiceRef =
          _firestore.collection('extraServices').doc('extra_service_001');

      DocumentSnapshot spaServiceSnapshot = await spaServiceRef.get();
      if (spaServiceSnapshot.exists) {
        Map<String, dynamic> spaServiceData =
            spaServiceSnapshot.data() as Map<String, dynamic>;
        List<Map<String, dynamic>> timeSlots =
            List<Map<String, dynamic>>.from(spaServiceData['timeSlots'] ?? []);

        // Find the selected time slot and update its status
        for (var slot in timeSlots) {
          if (slot['time'] == timeSlot) {
            slot['status'] = 'booked';
            break;
          }
        }

        // Update the time slots in Firestore
        await spaServiceRef.update({'timeSlots': timeSlots});

        // Create a new extraServiceBooking
        String serviceBookingId =
            'esbooking_${DateTime.now().millisecondsSinceEpoch}';
        DateTime createdAt = DateTime.now();
        int quantity = 2;
        int totalPrice = 3000;
        String status = 'new';

        await _firestore
            .collection('extraServiceBookings')
            .doc(serviceBookingId)
            .set({
          'serviceBookingId': serviceBookingId,
          'userId': userId,
          'serviceId': 'extra_service_001',
          'quantity': quantity,
          'totalPrice': totalPrice,
          'status': status,
          'createdAt': createdAt,
        });

        print('Spa service booked successfully!');
      } else {
        throw Exception('Spa service not found');
      }
    } catch (e) {
      throw Exception('Failed to book spa service: $e');
    }
  }
}

class SpaBookingScreen extends StatefulWidget {
  @override
  _SpaBookingScreenState createState() => _SpaBookingScreenState();
}

class _SpaBookingScreenState extends State<SpaBookingScreen> {
  final SpaService _spaService = SpaService();
  List<Map<String, dynamic>> _availableTimeSlots = [];
  final String _userId = 'guest_001'; // Assuming the user ID is known

  @override
  void initState() {
    super.initState();
    _fetchAvailableTimeSlots();
  }

  Future<void> _fetchAvailableTimeSlots() async {
    try {
      List<Map<String, dynamic>> timeSlots =
          await _spaService.getAvailableTimeSlots();
      setState(() {
        _availableTimeSlots = timeSlots;
      });
    } catch (e) {
      print('Error fetching time slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch time slots: $e')),
      );
    }
  }

  Future<void> _bookSpaService(String timeSlot) async {
    try {
      await _spaService.bookSpaService(timeSlot, _userId);
      print('Spa service booked successfully!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Spa service booked successfully!')),
      );

      // Refresh the available time slots after booking
      await _fetchAvailableTimeSlots();
    } catch (e) {
      print('Error booking spa service: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book spa service: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Spa Service'),
      ),
      body: ListView.builder(
        itemCount: _availableTimeSlots.length,
        itemBuilder: (context, index) {
          final timeSlot = _availableTimeSlots[index]['time'];
          return ListTile(
            title: Text(timeSlot),
            trailing: ElevatedButton(
              onPressed: () => _bookSpaService(timeSlot),
              child: Text('Book'),
            ),
          );
        },
      ),
    );
  }
}