import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:concierge/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image/image.dart' as img;

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  File? _profileImage;
  File? _aadhaarImage;
  bool _isLoading = false;
  String _countryCode = '+91';

  @override
  void initState() {
    super.initState();
    // Pre-fill email if user is already authenticated
    final User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      _emailController.text = currentUser.email!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isProfile) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(pickedFile.path);
          } else {
            _aadhaarImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String> _convertAndCompressImageToBase64(File imageFile) async {
    // Read the image file
    final bytes = await imageFile.readAsBytes();

    // Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return "";

    // Compress the image (resize and reduce quality)
    img.Image compressedImage =
        img.copyResize(image, width: 800); // Resize to 800px width
    List<int> compressedBytes =
        img.encodeJpg(compressedImage, quality: 70); // Reduce quality to 70%

    // Convert to Base64
    return base64Encode(compressedBytes);
  }

  Future<void> _saveUserProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile picture')),
      );
      return;
    }

    if (_aadhaarImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your Aadhaar card')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert images to Base64
      final String profileImageBase64 =
          await _convertAndCompressImageToBase64(_profileImage!);
      final String aadhaarImageBase64 =
          await _convertAndCompressImageToBase64(_aadhaarImage!);

      // Get the current user ID
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Create user profile document
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': '$_countryCode${_phoneController.text.trim()}',
        'profilePicture': profileImageBase64,
        'aadhaarCard': aadhaarImageBase64,
        'role': "guest",
        'bookings': [],
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);

      // Navigate to the next screen or show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile created successfully!')),
      );

      // Navigate to home page or dashboard
      // Navigator.of(context).pushReplacementNamed('/home');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating profile: $e')),
      );
    }
  }

  void _showImageSourceDialog(bool isProfile) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a picture'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera, isProfile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, isProfile);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Setup Profile',
                      style: TextStyle(
                        color: Color(0xFF2A3990),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFF2A3990)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // Profile Image Picker
                          GestureDetector(
                            onTap: () => _showImageSourceDialog(true),
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(0xFF2A3990)
                                          .withOpacity(0.2),
                                      width: 4,
                                    ),
                                    image: _profileImage != null
                                        ? DecorationImage(
                                            image: FileImage(_profileImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _profileImage == null
                                      ? const Center(
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Color(0xFF90A4AE),
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2A3990),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Form Fields with Card Design
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2A3990),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Name Field
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    prefixIcon: const Icon(Icons.person_outline,
                                        color: Color(0xFF5C6BC0)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFEEF2F7),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon: const Icon(Icons.email_outlined,
                                        color: Color(0xFF5C6BC0)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFEEF2F7),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Phone Field
                                IntlPhoneField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFEEF2F7),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 16),
                                  ),
                                  initialCountryCode: 'IN',
                                  onChanged: (phone) {
                                    _countryCode = phone.countryCode;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Aadhaar Card Upload Section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Identity Verification',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2A3990),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Aadhaar Card Upload
                                GestureDetector(
                                  onTap: () => _showImageSourceDialog(false),
                                  child: Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2F7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF5C6BC0)
                                            .withOpacity(0.3),
                                        width: 1,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: _aadhaarImage != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                              _aadhaarImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.upload_file,
                                                size: 50,
                                                color: Color(0xFF5C6BC0),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Upload Aadhaar Card',
                                                style: TextStyle(
                                                  color: Color(0xFF5C6BC0),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Tap to browse files',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveUserProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A3990),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : const Text(
                                      'Save Profile',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Future Use fields notice
            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: Container(
            //     padding:
            //         const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            //     color: Colors.white.withOpacity(0.9),
            //     child: const Text(
            //       'Additional features like bookings and wallet will be available after profile setup.',
            //       textAlign: TextAlign.center,
            //       style: TextStyle(
            //         color: Color(0xFF5C6BC0),
            //         fontSize: 12,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
