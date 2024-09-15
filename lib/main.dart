import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:gallery_saver/gallery_saver.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  runApp(MaterialApp(
    home: PermissionPage(),
  ));
}


// First Widget: Asking for permissions (Camera, Storage)
class PermissionPage extends StatefulWidget {
  @override
  _PermissionPageState createState() => _PermissionPageState();
}


class _PermissionPageState extends State<PermissionPage> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }


  // Method to request both camera and storage permissions
  Future<void> _requestPermissions() async {
    // Request camera permission
    PermissionStatus cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      await Permission.camera.request();
    }


    // Request storage permissions
    PermissionStatus storageStatus = await Permission.storage.status;
    if (storageStatus.isDenied) {
      await Permission.storage.request();
    }


    // Check if both permissions are granted
    if (await Permission.camera.isGranted && await Permission.storage.isGranted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CameraPage()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Permission Request')),
      body: Center(
        child: ElevatedButton(
          onPressed: _requestPermissions,
          child: Text('Request Permissions'),
        ),
      ),
    );
  }
}


// Second Widget: Working with Camera
class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}


class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool _isCameraReady = false;


  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }


  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {
        _isCameraReady = true;
      });
    }
  }


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }


  // Method to capture image and save it to gallery
  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Error: Camera not initialized');
      return;
    }


    // Capture image
    final XFile image = await _controller!.takePicture();


    // Save the image to gallery in the 'seenShot' folder
    final String imagePath = image.path;
    await GallerySaver.saveImage(imagePath, albumName: 'seenShot').then((bool? success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to gallery!'))
      );
    }).catchError((e) {
      print('Error saving image: $e');
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera App'),
      ),
      body: _isCameraReady
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: CameraPreview(_controller!),
          ),
          ElevatedButton(
            onPressed: _captureImage,
            child: Text('Capture Image'),
          ),
        ],
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
