// // import 'dart:async';
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:porcupine_flutter/porcupine_error.dart';
// // import 'package:porcupine_flutter/porcupine_manager.dart';
// // // import 'package:porcupine_flutter/porcupine_manager_error.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// // class WakeWordService {
// //   static final WakeWordService _instance = WakeWordService._internal();
// //   factory WakeWordService() => _instance;
// //   WakeWordService._internal();

// //   PorcupineManager? _porcupineManager;
// //   bool _isRunning = false;
// //   final String _accessKey =
// //       "YOUR_PICOVOICE_ACCESS_KEY"; // Replace with your access key

// //   // Callback function to be called when wake word is detected
// //   Function? onWakeWordDetected;

// //   // Initialize the wake word service
// //   Future<void> initialize() async {
// //     // Check if microphone permission is granted
// //     var status = await Permission.microphone.status;
// //     if (!status.isGranted) {
// //       status = await Permission.microphone.request();
// //       if (!status.isGranted) {
// //         throw PorcupineManagerError('Microphone permission denied');
// //       }
// //     }

// //     try {
// //       // Create a Porcupine manager instance
// //       _porcupineManager = await PorcupineManager.fromKeywordPaths(
// //         accessKey: _accessKey,
// //         // You need to put your trained model file in assets folder and add it to pubspec.yaml
// //         keywordPaths: ["assets/wake_words/hey_concierge.ppn"],
// //         sensitivities: [0.7],
// //         onDetection: (keywordIndex) {
// //           // Call the callback function when wake word is detected
// //           if (onWakeWordDetected != null) {
// //             onWakeWordDetected!();
// //           }
// //         },
// //       );
// //     } on PorcupineManagerError catch (err) {
// //       throw PorcupineManagerError(
// //           'Failed to initialize Porcupine: ${err.message}');
// //     }
// //   }

// //   // Start wake word detection
// //   Future<void> start() async {
// //     if (_porcupineManager == null) {
// //       await initialize();
// //     }

// //     if (!_isRunning) {
// //       try {
// //         if (Platform.isAndroid) {
// //           // Start foreground service on Android
// //           await _startForegroundService();
// //         }
// //         await _porcupineManager?.start();
// //         _isRunning = true;
// //       } on PorcupineManagerError catch (err) {
// //         throw PorcupineManagerError(
// //             'Failed to start Porcupine: ${err.message}');
// //       }
// //     }
// //   }

// //   // Stop wake word detection
// //   Future<void> stop() async {
// //     if (_isRunning) {
// //       try {
// //         await _porcupineManager?.stop();
// //         if (Platform.isAndroid) {
// //           // Stop foreground service on Android
// //           await ForegroundService.stopForegroundService();
// //         }
// //         _isRunning = false;
// //       } on PorcupineManagerError catch (err) {
// //         throw PorcupineManagerError('Failed to stop Porcupine: ${err.message}');
// //       }
// //     }
// //   }

// //   // Release resources
// //   Future<void> dispose() async {
// //     try {
// //       await stop();
// //       await _porcupineManager?.delete();
// //       _porcupineManager = null;
// //     } on PorcupineManagerError catch (err) {
// //       throw PorcupineManagerError(
// //           'Failed to dispose Porcupine: ${err.message}');
// //     }
// //   }

// //   // Start a foreground service on Android
// //   Future<void> _startForegroundService() async {
// //     await ForegroundService.setServiceInfo(
// //       title: 'Concierge Assistant',
// //       content: 'Listening for "Hey Concierge!"',
// //       iconName: 'ic_notification',
// //     );
// //     await ForegroundService.startForegroundService(_foregroundServiceFunction);
// //     await ForegroundService.setupIsolateCommunication((data) {
// //       // Handle message from foreground service if needed
// //     });
// //   }

// //   // Foreground service function
// //   static void _foregroundServiceFunction() {
// //     // This function runs in the foreground service
// //     // We don't need to do anything here as Porcupine is running
// //     // in the main isolate and managing the audio stream
// //     ForegroundService.notification.setText('Listening for "Hey Concierge!"');
// //   }
// // }

// // import 'dart:async';
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:porcupine_flutter/porcupine_error.dart';
// // import 'package:porcupine_flutter/porcupine_manager.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// // class WakeWordService {
// //   static final WakeWordService _instance = WakeWordService._internal();
// //   factory WakeWordService() => _instance;
// //   WakeWordService._internal();

// //   PorcupineManager? _porcupineManager;
// //   bool _isRunning = false;
// //   final String _accessKey =
// //       "YOUR_PICOVOICE_ACCESS_KEY"; // Replace with your access key

// //   // Callback function to be called when wake word is detected
// //   Function? onWakeWordDetected;

// //   // Initialize the wake word service
// //   Future<void> initialize() async {
// //     // Check if microphone permission is granted
// //     var status = await Permission.microphone.status;
// //     if (!status.isGranted) {
// //       status = await Permission.microphone.request();
// //       if (!status.isGranted) {
// //         throw Exception('Microphone permission denied');
// //       }
// //     }

// //     try {
// //       // Create a Porcupine manager instance
// //       _porcupineManager = await PorcupineManager.fromKeywordPaths(
// //         accessKey: _accessKey,
// //         // You need to put your trained model file in assets folder and add it to pubspec.yaml
// //         keywordPaths: ["assets/wake_words/hey_concierge.ppn"],
// //         sensitivities: [0.7],
// //         onDetection: (keywordIndex) {
// //           // Call the callback function when wake word is detected
// //           if (onWakeWordDetected != null) {
// //             onWakeWordDetected!();
// //           }
// //         },
// //       );
// //     } on PorcupineManagerError catch (err) {
// //       throw Exception('Failed to initialize Porcupine: ${err.message}');
// //     }
// //   }

// //   // Start wake word detection
// //   Future<void> start() async {
// //     if (_porcupineManager == null) {
// //       await initialize();
// //     }

// //     if (!_isRunning) {
// //       try {
// //         if (Platform.isAndroid) {
// //           // Start foreground service on Android
// //           await _startForegroundService();
// //         }
// //         await _porcupineManager?.start();
// //         _isRunning = true;
// //       } on PorcupineManagerError catch (err) {
// //         throw Exception('Failed to start Porcupine: ${err.message}');
// //       }
// //     }
// //   }

// //   // Stop wake word detection
// //   Future<void> stop() async {
// //     if (_isRunning) {
// //       try {
// //         await _porcupineManager?.stop();
// //         if (Platform.isAndroid) {
// //           // Stop foreground service on Android
// //           await FlutterForegroundTask.stopService();
// //         }
// //         _isRunning = false;
// //       } on PorcupineManagerError catch (err) {
// //         throw Exception('Failed to stop Porcupine: ${err.message}');
// //       }
// //     }
// //   }

// //   // Release resources
// //   Future<void> dispose() async {
// //     try {
// //       await stop();
// //       await _porcupineManager?.delete();
// //       _porcupineManager = null;
// //     } on PorcupineManagerError catch (err) {
// //       throw Exception('Failed to dispose Porcupine: ${err.message}');
// //     }
// //   }

// //   // Start a foreground service on Android
// //   Future<void> _startForegroundService() async {
// //     // Define the foreground task configuration
// //     final taskCallback = FlutterForegroundTask.setTaskHandler(
// //       WakeWordTaskHandler(onWakeWordDetected: onWakeWordDetected),
// //     );

// //     // Configure the foreground task
// //     final initData = {
// //       'countInit': 1,
// //     };

// //     FlutterForegroundTask.init(
// //       androidNotificationOptions: AndroidNotificationOptions(
// //         channelId: 'concierge_channel',
// //         channelName: 'Concierge Assistant',
// //         channelDescription: 'Listening for wake word',
// //         channelImportance: NotificationChannelImportance.LOW,
// //         priority: NotificationPriority.LOW,
// //         iconData: const NotificationIconData(
// //           resType: ResourceType.mipmap,
// //           resPrefix: ResourcePrefix.ic,
// //           name: 'launcher',
// //         ),
// //         buttons: [
// //           const NotificationButton(id: 'stop', text: 'Stop'),
// //         ],
// //       ),
// //       iosNotificationOptions: const IOSNotificationOptions(
// //         showNotification: true,
// //         playSound: false,
// //       ),
// //       foregroundTaskOptions: const ForegroundTaskOptions(
// //         interval: 1000,
// //         isOnceEvent: false,
// //         autoRunOnBoot: false,
// //         allowWakeLock: true,
// //         allowWifiLock: false,
// //       ),
// //     );

// //     await FlutterForegroundTask.startService(
// //       notificationTitle: 'Concierge Assistant',
// //       notificationText: 'Listening for "Hey Concierge!"',
// //       callback: taskCallback,
// //       initData: initData,
// //     );
// //   }
// // }

// // // TaskHandler for the foreground service
// // class WakeWordTaskHandler extends TaskHandler {
// //   final Function? onWakeWordDetected;

// //   WakeWordTaskHandler({this.onWakeWordDetected});

// //   @override
// //   Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
// //     // Nothing to do here, the wake word detection is handled by Porcupine in the main isolate
// //   }

// //   @override
// //   Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
// //     // This will be called periodically
// //     // You can add any periodic tasks here if needed
// //   }

// //   @override
// //   Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
// //     // Clean up resources if needed
// //   }

// //   @override
// //   void onButtonPressed(String id) {
// //     // Handle button press in notification
// //     if (id == 'stop') {
// //       FlutterForegroundTask.stopService();
// //     }
// //   }
  
// //   @override
// //   void onRepeatEvent(DateTime timestamp) {
// //     // TODO: implement onRepeatEvent
// //   }
// // }


// import 'package:porcupine/porcupine.dart';
// import 'package:porcupine_flutter/porcupine.dart';

// class PorcupineManager {
//   late Porcupine _porcupine;
//   final Function(int) onWakeWordDetected;

//   PorcupineManager({required this.onWakeWordDetected});

//   Future<void> initialize(List<String> keywordPaths, List<double> sensitivities) async {
//     try {
//       _porcupine = await Porcupine.fromKeywordPaths(
//         "YOUR_PICOVOICE_ACCESS_KEY",  // Replace with your access key
//         keywordPaths,
//         // sensitivities,
//       );

//       _porcupine.addListener(() {
//         onWakeWordDetected(0);  // Trigger callback
//       });
//     } catch (e) {
//       throw Exception("Failed to initialize Porcupine: $e");
//     }
//   }

//   Future<void> start() async {
//     try {
//       await _porcupine.start();
//     } catch (e) {
//       throw Exception("Failed to start Porcupine: $e");
//     }
//   }

//   Future<void> stop() async {
//     try {
//       await _porcupine.stop();
//     } catch (e) {
//       throw Exception("Failed to stop Porcupine: $e");
//     }
//   }

//   Future<void> delete() async {
//     try {
//       await _porcupine.delete();
//     } catch (e) {
//       throw Exception("Failed to delete Porcupine: $e");
//     }
//   }
// }