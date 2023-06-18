import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MaterialApp(
    home: PepperClassificationApp(),
  ));
}

class PepperClassificationApp extends StatefulWidget {
  @override
  _PepperClassificationAppState createState() =>
      _PepperClassificationAppState();
}

class _PepperClassificationAppState extends State<PepperClassificationApp> {
  List<dynamic>? _output = [];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: 'assets/mobilenet_v1_1.0_224.tflite',
        labels: 'assets/labels.txt',
      );
    } on PlatformException {
      print('Failed to load model.');
    } catch (e) {
      print(e);
    }
  }

  Future<void> classifyImage(File image) async {
    try {
      var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 5, // Number of classification results to return
        threshold: 0.1, // Classification threshold
      );
      setState(() {
        if (output != null) {
          _output = output!.cast<Map<dynamic, dynamic>>().toList();
          print(output);
        } else {
          _output = [];
        }
      });
    } on PlatformException {
      print('Failed to classify image.');
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().getImage(source: source);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      classifyImage(image);
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pepper Classification'),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Select Image'),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          GestureDetector(
                            child: Text('Gallery'),
                            onTap: () {
                              pickImage(ImageSource.gallery);
                              Navigator.of(context).pop();
                            },
                          ),
                          SizedBox(height: 16),
                          GestureDetector(
                            child: Text('Camera'),
                            onTap: () {
                              pickImage(ImageSource.camera);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Text('Select Image'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _output?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final label = _output?[index]['label'] ?? '';
                final confidence = _output?[index]['confidence'] ?? '';
                return ListTile(
                  title: Text('$label'),
                  subtitle: Text('Confidence: $confidence'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
