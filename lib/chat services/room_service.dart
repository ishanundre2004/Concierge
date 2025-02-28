import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:concierge/chat%20services/spa_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class RoomService {
  final Function(String, bool) _addMessage;
  final Function(Widget) _addRoomCards;

  RoomService(this._addMessage, this._addRoomCards);

  // List of service-related keywords
  final List<String> serviceKeywords = [
    "service",
    "amenities",
    "restaurant",
    "spa",
    "gym",
    "pool",
    "transport",
    "shuttle",
    "menu",
    "recommendation",
    "attraction",
    "shopping",
    "towels",
    "upgrade",
    "late check-out",
    "directions",
    "map",
  ];

  // Check if the user's input is related to room services
  bool isServiceRelated(String text) {
    return serviceKeywords
        .any((keyword) => text.toLowerCase().contains(keyword));
  }

  // Check if the current user has any bookings
  Future<bool> hasPreviousBookings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      _addMessage("You need to be logged in to use this feature.", false);
      return false;
    }

    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .get();

    return bookingsSnapshot.docs.isNotEmpty;
  }

  // Fetch room services from Firestore
  Future<List<Map<String, dynamic>>> fetchRoomServices() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('roomServices').get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Fetch extra services from Firestore
  Future<List<Map<String, dynamic>>> fetchExtraServices() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('extraServices').get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Fetch custom requests from Firestore
  Future<List<Map<String, dynamic>>> fetchCustomRequests() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('customRequests').get();

      // Map each document snapshot to its data with null handling
      return snapshot.docs.map((doc) {
        final data =
            doc.data() as Map<String, dynamic>? ?? {}; // Handle null data
        return {
          'createdAt': data['createdAt'] ?? 'No date', // Handle null fields
          'description': data['description'] ?? 'No description',
          'requestId': data['requestId'] ?? 'No request ID',
          'status': data['status'] ?? 'No status',
          'userId': data['userId'] ?? 'No user ID',
        };
      }).toList();
    } catch (e) {
      // Handle any errors (e.g., network issues, Firestore permissions)
      print('Error fetching custom requests: $e');
      return []; // Return an empty list in case of error
    }
  }

  // Handle service-related queries
  Future<void> handleServiceRequest(String text) async {
    final hasBookings = await hasPreviousBookings();

    if (hasBookings) {
      // User has bookings, fetch and display the list of available services
      final roomServices = await fetchRoomServices();
      final extraServices = await fetchExtraServices();
      final customRequests = await fetchCustomRequests();

      // Display services in circular tabs with categories
      _addRoomCards(ServiceTabs(
        roomServices: roomServices,
        extraServices: extraServices,
        customRequests: customRequests,
        onCustomRequestSubmitted: _saveCustomRequest,
      ));
    } else {
      // User has no bookings, suggest booking a room
      _addMessage(
          "It seems you don't have any active bookings. Would you like to book a room now?",
          false);
    }
  }

  // Save custom request to Firestore
  Future<void> _saveCustomRequest(String request) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final uuid = Uuid();
    String requestId = uuid.v4();
    if (userId == null) {
      _addMessage("You need to be logged in to send a request.", false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('customRequests').add({
        'userId': userId,
        'description': request,
        'requestId': requestId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _addMessage(
          "Your custom request has been submitted successfully!", false);
    } catch (e) {
      _addMessage("Failed to submit your request. Please try again.", false);
      print("Error saving custom request: $e");
    }
  }
}

class ServiceTabs extends StatefulWidget {
  final List<Map<String, dynamic>> roomServices;
  final List<Map<String, dynamic>> extraServices;
  final List<Map<String, dynamic>> customRequests;
  final Function(String) onCustomRequestSubmitted;

  const ServiceTabs({
    Key? key,
    required this.roomServices,
    required this.extraServices,
    required this.customRequests,
    required this.onCustomRequestSubmitted,
  }) : super(key: key);

  @override
  _ServiceTabsState createState() => _ServiceTabsState();
}

class _ServiceTabsState extends State<ServiceTabs> {
  int _selectedIndex = 0;
  String _selectedCategory = 'roomServices'; // Default selected category
  final TextEditingController _customRequestController =
      TextEditingController();
  final SpaService _spaService = SpaService();
  List<Map<String, dynamic>> _availableSlots = [];
  String? _userId; // Store the current user ID

  @override
  void initState() {
    super.initState();
    _fetchUserId();
  }

  // Fetch the current user ID
  void _fetchUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  // Combine all services into a single list for easy indexing
  List<Map<String, dynamic>> get _allServices {
    return [
      ...widget.roomServices,
      ...widget.extraServices,
      ...widget.customRequests,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Selection Buttons with Horizontal Scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 8), // Add initial spacing
              _buildCategoryButton('Room Services', 'roomServices'),
              const SizedBox(width: 8),
              _buildCategoryButton('Extra Services', 'extraServices'),
              const SizedBox(width: 8),
              _buildCategoryButton('Custom Request', 'customRequests'),
              const SizedBox(width: 8), // Add trailing spacing
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Circular Tabs for the selected category with Horizontal Scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getServicesForCategory(_selectedCategory)
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final service = entry.value;

              return InkWell(
                onTap: () async {
                  setState(() {
                    _selectedIndex = _getGlobalIndex(_selectedCategory, index);
                  });

                  // Fetch available slots if the selected service is Spa
                  if (service['name'] == 'Spa') {
                    _availableSlots = await _spaService.getAvailableTimeSlots();
                    setState(() {});
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedIndex ==
                            _getGlobalIndex(_selectedCategory, index)
                        ? Colors.blueAccent
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service['name'] ?? 'No name', // Handle null name
                    style: TextStyle(
                      color: _selectedIndex ==
                              _getGlobalIndex(_selectedCategory, index)
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Service Details or Custom Request Input
        if (_selectedCategory == 'customRequests')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _customRequestController,
                  decoration: InputDecoration(
                    hintText: 'Write your custom request here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _sendCustomRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Send Request',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        else if (_allServices.isNotEmpty)
          Container(
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
                const SizedBox(height: 8),
                Text(
                  _allServices[_selectedIndex]['description'] ??
                      'No description', // Handle null description
                  style: const TextStyle(fontSize: 14),
                ),

                // Display available slots if the selected service is Spa
                if (_allServices[_selectedIndex]['name'] == 'Spa' &&
                    _availableSlots.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Available Time Slots:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._availableSlots.map((slot) {
                        return ListTile(
                          title: Text(slot['time']),
                          trailing: slot['status'] == 'available'
                              ? ElevatedButton(
                                  onPressed: () async {
                                    if (_userId == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'You need to be logged in to book a slot.')),
                                      );
                                      return;
                                    }

                                    try {
                                      // Call the booking function
                                      await _spaService.bookSpaService(
                                          slot['time'], _userId!);
                                      // Show success message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Spa service booked successfully!')),
                                      );
                                      // Refresh the available slots
                                      setState(() async {
                                        _availableSlots = await _spaService
                                            .getAvailableTimeSlots();
                                      });
                                    } catch (e) {
                                      // Show error message
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to book spa service: $e')),
                                      );
                                    }
                                  },
                                  child: const Text('Book'),
                                )
                              : const Icon(Icons.cancel, color: Colors.red),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper method to build category buttons
  Widget _buildCategoryButton(String label, String category) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedCategory = category;
          _selectedIndex = _getGlobalIndex(
              category, 0); // Reset to first item in the category
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedCategory == category
            ? Colors.blueAccent
            : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _selectedCategory == category ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  // Helper method to get services for the selected category
  List<Map<String, dynamic>> _getServicesForCategory(String category) {
    switch (category) {
      case 'roomServices':
        return widget.roomServices;
      case 'extraServices':
        return widget.extraServices;
      case 'customRequests':
        return widget.customRequests;
      default:
        return [];
    }
  }

  // Helper method to get the global index of a service
  int _getGlobalIndex(String category, int localIndex) {
    switch (category) {
      case 'roomServices':
        return localIndex;
      case 'extraServices':
        return widget.roomServices.length + localIndex;
      case 'customRequests':
        return widget.roomServices.length +
            widget.extraServices.length +
            localIndex;
      default:
        return 0;
    }
  }

  // Send custom request to Firestore
  Future<void> _sendCustomRequest() async {
    final request = _customRequestController.text.trim();
    if (request.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a request.')),
      );
      return;
    }

    // Call the callback to save the custom request
    widget.onCustomRequestSubmitted(request);

    // Clear the text field after sending
    _customRequestController.clear();
  }
}
