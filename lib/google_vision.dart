
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';



// class RealTimeSceneDetector extends StatefulWidget {
//   final CameraDescription camera;

//   const RealTimeSceneDetector({super.key, required this.camera});

//   @override
//   _RealTimeSceneDetectorState createState() => _RealTimeSceneDetectorState();
// }

// class _RealTimeSceneDetectorState extends State<RealTimeSceneDetector> {
//   late CameraController _cameraController;
//   bool _isCameraInitialized = false;
//   bool _isLoading = false;
//   Map<String, dynamic>? _responseData;
//   FlutterTts flutterTts = FlutterTts();

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _initializeTts();
//   }

//   Future<void> _initializeCamera() async {
//     _cameraController = CameraController(
//       widget.camera,
//       ResolutionPreset.medium,
//     );

//     await _cameraController.initialize();
//     if (!mounted) return;

//     setState(() {
//       _isCameraInitialized = true;
//     });
//   }

//   Future<void> _initializeTts() async {
//     await flutterTts.setLanguage("en-US");
//     await flutterTts.setPitch(1.0);
//     await flutterTts.setSpeechRate(0.5);
//   }

//   Future<void> _speak(String text) async {
//     await flutterTts.speak(text);
//   }

//   Future<void> _captureAndProcessImage() async {
//     if (!_cameraController.value.isInitialized) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Camera is not initialized.')),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _responseData = null;
//     });

//     try {
//       final image = await _cameraController.takePicture();
//       final bytes = await File(image.path).readAsBytes();

//       final uri = Uri.parse('http://192.168.46.203:5000/upload'); // Replace with your server IP
//       final request = http.MultipartRequest('POST', uri)
//         ..files.add(http.MultipartFile.fromBytes(
//           'image',
//           bytes,
//           filename: 'captured_image.jpg',
//         ));

//       final response = await request.send();

//       if (response.statusCode == 200) {
//         final responseData = await response.stream.bytesToString();
//         setState(() {
//           _responseData = json.decode(responseData);
//         });

//         if (_responseData != null && _responseData!.containsKey('description')) {
//           _speak(_responseData!['description']);
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text('Error uploading image: ${response.statusCode}')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Widget _buildResult() {
//     if (_responseData == null) {
//       return const SizedBox();
//     }

//     if (_responseData!.containsKey('error')) {
//       return Text(
//         _responseData!['error'],
//         style: const TextStyle(color: Colors.red),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (_responseData!.containsKey('landmark'))
//           Text(
//             'Landmark: ${_responseData!['landmark']}',
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//         if (_responseData!.containsKey('description'))
//           const SizedBox(height: 10),
//         Text(
//           'Description: ${_responseData!['description']}',
//           style: const TextStyle(fontSize: 16),
//         ),
//         if (_responseData!.containsKey('specific_features'))
//           const SizedBox(height: 10),
//         if (_responseData!.containsKey('specific_features'))
//           const Text(
//             'Specific Features:',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         if (_responseData!.containsKey('specific_features'))
//           ..._responseData!['specific_features'].map<Widget>((feature) {
//             return ListTile(
//               title: Text(feature['name']),
//               subtitle: Text(feature['description']),
//             );
//           }).toList(),
//         if (_responseData!.containsKey('image_url') &&
//             _responseData!['image_url'].isNotEmpty)
//           const SizedBox(height: 10),
//         if (_responseData!.containsKey('image_url') &&
//             _responseData!['image_url'].isNotEmpty)
//           Image.network(_responseData!['image_url']),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _cameraController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Real-Time Scene Detector'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             if (_isCameraInitialized)
//               Expanded(
//                 child: CameraPreview(_cameraController),
//               ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _captureAndProcessImage,
//               child: _isLoading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text('Capture and Detect'),
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: SingleChildScrollView(
//                 child: _buildResult(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




class GoogleVision extends StatefulWidget {
  const GoogleVision({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GoogleVisionState createState() => _GoogleVisionState();
}

class _GoogleVisionState extends State<GoogleVision> {
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
