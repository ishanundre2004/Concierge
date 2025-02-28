// import 'package:concierge/chat_screen.dart';
// import 'package:concierge/home_page.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:porcupine_flutter/porcupine_manager.dart';

// void main() async {
// WidgetsFlutterBinding.ensureInitialized();
// await Firebase.initializeApp();
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF1D4E5F),
//           primary: const Color(0xFF1D4E5F),
//         ),
//         useMaterial3: true,
//         fontFamily: 'Poppins',
//       ),
//       home: LocationDetect(),
//     );
//   }
// }

import 'dart:io';
import 'dart:convert';
import 'package:concierge/chat_screen.dart';
import 'package:concierge/notification_service.dart';
import 'package:concierge/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await notificationService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Landmark Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Wrapper(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _responseData;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _responseData = null;
    });

    try {
      // Convert image to base64
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare the request
      final uri = Uri.parse(
          'http://192.168.46.203:5000/upload'); // Replace with your IP
      final request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'uploaded_image.jpg',
        ));

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        setState(() {
          _responseData = json.decode(responseData);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error uploading image: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildResult() {
    if (_responseData == null) {
      return SizedBox();
    }

    if (_responseData!.containsKey('error')) {
      return Text(
        _responseData!['error'],
        style: TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_responseData!.containsKey('landmark'))
          Text(
            'Landmark: ${_responseData!['landmark']}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        if (_responseData!.containsKey('description')) SizedBox(height: 10),
        Text(
          'Description: ${_responseData!['description']}',
          style: TextStyle(fontSize: 16),
        ),
        if (_responseData!.containsKey('specific_features'))
          SizedBox(height: 10),
        Text(
          'Specific Features:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ..._responseData!['specific_features'].map<Widget>((feature) {
          return ListTile(
            title: Text(feature['name']),
            subtitle: Text(feature['description']),
          );
        }).toList(),
        if (_responseData!.containsKey('image_url') &&
            _responseData!['image_url'].isNotEmpty)
          SizedBox(height: 10),
        Image.network(_responseData!['image_url']),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Landmark Detector'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_image != null) Image.file(_image!, height: 200),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Select Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadImage,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Upload and Detect'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: _buildResult(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
