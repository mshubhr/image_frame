import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:image_frame/screens/splash.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? imageFile;
  bool useHeartFrame = false;
  bool useCircleFrame = false;
  bool useSquareFrame = false;
  bool useRectangleFrame = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          statusBarColor: Color.fromARGB(255, 8, 138, 95),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
        centerTitle: true,
        elevation: 2.0,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: const Text(
          'Add Image / Icon',
          style: TextStyle(
              color: Color(0x8A000000),
              fontFamily: 'Tajawal',
              fontSize: 20.0,
              fontWeight: FontWeight.w500),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              height: 100,
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x61000000)),
                  borderRadius: BorderRadius.circular(10.0)),
              child: Column(
                children: [
                  const SizedBox(height: 22.0),
                  const Text(
                    'Upload Image',
                    style: TextStyle(
                      color: Color(0x61000000),
                      fontFamily: 'Tajawal',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Map<Permission, PermissionStatus> statuses = await [
                        Permission.storage,
                        Permission.camera,
                      ].request();
                      if (statuses[Permission.storage]!.isGranted &&
                          statuses[Permission.camera]!.isGranted) {
                        // ignore: use_build_context_synchronously
                        showImagePicker(context);
                      } else {
                        if (kDebugMode) {
                          print('no permission granted');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 8, 138, 95)),
                    child: const Text(
                      'Choose from Device',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            imageFile == null
                ? const SizedBox(height: 400, width: 400)
                : _buildImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageFile == null) {
      return const SizedBox(height: 400, width: 400);
    }
    Widget imageWidget = Image.file(
      imageFile!,
      fit: BoxFit.fill,
      width: 300,
      height: 300,
    );
    if (useHeartFrame) {
      imageWidget = ClipPath(
        clipper: HeartClipper(),
        child: imageWidget,
      );
    } else if (useSquareFrame) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(50.0),
        child: imageWidget,
      );
    } else if (useCircleFrame) {
      imageWidget = CircleAvatar(
        radius: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
              300), // Use half of the size for a circular shape
          child: imageWidget,
        ),
      );
    } else if (useRectangleFrame) {
      imageWidget = SizedBox(
        width: 300, // Replace with the original width of your image
        height: 200, // Set the desired custom height for the rectangle
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
              10.0), // You can adjust the borderRadius as needed
          child: imageWidget,
        ),
      );
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(0.0),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  void showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (builder) {
        return Card(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: 200,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Text(
                  'Complete action using',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: InkWell(
                        child: const Column(
                          children: [
                            Icon(
                              Icons.image,
                              size: 50.0,
                            ),
                            SizedBox(height: 12.0),
                            Text(
                              "Gallery",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ],
                        ),
                        onTap: () {
                          _imgFromGallery();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        child: const SizedBox(
                          child: Column(
                            children: [
                              Icon(Icons.camera_alt, size: 50.0),
                              SizedBox(height: 12.0),
                              Text(
                                "Camera",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          _imgFromCamera();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _imgFromGallery() async {
    final picker = ImagePicker();
    await picker
        .pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    )
        .then((value) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
  }

  _imgFromCamera() async {
    final picker = ImagePicker();
    await picker
        .pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    )
        .then((value) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
  }

  _cropImage(File imgFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imgFile.path,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio16x9
            ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: "Image Cropper",
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(title: "ImageCropper"),
      ],
    );

    if (croppedFile != null) {
      imageCache.clear();
      setState(() {
        imageFile = File(croppedFile.path);
        useHeartFrame = false; // Reset to default square frame
        _showFrameChoiceDialog();
      });
    }
  }

  void _showFrameChoiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            width: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Uploaded Image',
                    style: TextStyle(
                        color: Colors.black45,
                        fontFamily: 'Tajawal',
                        fontSize: 19),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    height: 200,
                    width: 150,
                    child: _buildImage(),
                  ),
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: Colors.black45),
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          useHeartFrame = true;
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Colors.black45),
                          ),
                          padding: const EdgeInsets.all(5.0),
                          child: Image.asset('assets/user_image_frame_1.png',
                              width: 10, height: 10, fit: BoxFit.fill),
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          useSquareFrame = true;
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Colors.black45),
                          ),
                          padding: const EdgeInsets.all(5.0),
                          child: Image.asset('assets/user_image_frame_2.png',
                              width: 10, height: 10, fit: BoxFit.fill),
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          useCircleFrame = true;
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Colors.black45),
                          ),
                          padding: const EdgeInsets.all(5.0),
                          child: Image.asset('assets/user_image_frame_3.png',
                              width: 10, height: 10, fit: BoxFit.fill),
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          useRectangleFrame = true;
                        },
                        child: Container(
                          width: 50,
                          height: 35,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Colors.black45),
                          ),
                          padding: const EdgeInsets.all(5.0),
                          child: Image.asset('assets/user_image_frame_4.png',
                              width: 10, height: 10, fit: BoxFit.fill),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    height: 50,
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        if (useHeartFrame == true) {
                          setState(() {
                            useHeartFrame = true;
                          });
                          Navigator.pop(context);
                        } else if (useCircleFrame == true) {
                          setState(() {
                            useCircleFrame = true;
                          });
                          Navigator.pop(context);
                        } else if (useSquareFrame == true) {
                          setState(() {
                            useSquareFrame = true;
                          });
                          Navigator.pop(context);
                        } else if (useRectangleFrame == true) {
                          setState(() {
                            useRectangleFrame = true;
                          });
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            useHeartFrame = false;
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 8, 138, 95),
                      ),
                      child: const Text('Use this image',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double width = size.width;
    double height = size.height;

    Path path = Path();
    path.moveTo(0.5 * width, height * 0.35);
    path.cubicTo(0.2 * width, height * 0.1, -0.25 * width, height * 0.6,
        0.5 * width, height);
    path.moveTo(0.5 * width, height * 0.35);
    path.cubicTo(0.8 * width, height * 0.1, 1.25 * width, height * 0.6,
        0.5 * width, height);

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
