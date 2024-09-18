import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
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

// Second Widget: Working with Camera and switching between cameras
class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  late List<CameraDescription> cameras;
  bool _isCameraReady = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _selectedCameraIndex = 0;
      await _startCamera(_selectedCameraIndex);
    }
  }

  Future<void> _startCamera(int cameraIndex) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.high,
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
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

  // Method to switch between front and back cameras
  void _switchCamera() {
    if (cameras.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
      _startCamera(_selectedCameraIndex);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No second camera found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera App'),
        actions: [
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
        ],
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
