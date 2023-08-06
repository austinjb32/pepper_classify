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
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: 'assets/model.tflite',
        labels: 'assets/label_1.txt',
      );
    } on PlatformException {
      print('Failed to load model.');
    } catch (e) {
      print(e);
    }
  }

  Future<void> classifyImage(File image) async {
    var output;
    try {
      output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 3,
        threshold: 0.5,
      );
    } on PlatformException {
      print('Failed to classify image.');
    }

    if (!mounted) return;

    setState(() {
      if (output != null) {
        _output = output!.cast<Map<dynamic, dynamic>>().toList();
        print(output);
      } else {
        _output = [];
      }
    });
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().getImage(source: source);
    if (pickedFile != null) {
      File image = File(pickedFile.path);
      classifyImage(image);
      setState(() {
        _pickedImage = image;
      });
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
        backgroundColor: Colors.green,
        title: Text('Pepper Classification'),
      ),
      body: Column(
        children: <Widget>[
          if (_pickedImage != null)
            Container(
              height: 300,
              width: double.infinity,
              child: Image.file(
                _pickedImage!,
                fit: BoxFit.cover,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _output?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final label = _output?[index]['label'] ?? '';
                final confidence = _output?[index]['confidence'] * 100 ?? '';
                print(_output);
                return Center(
                  child: ListTile(
                    textColor: Colors.black87,
                    title: Text('$label'),
                    subtitle: Text('Confidence: $confidence%'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightGreen,
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
                      SizedBox(height: 24),
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
        child: Icon(Icons.image),
      ),
    );
  }
}
