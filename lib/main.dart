import 'package:flutter/material.dart';
import 'dart:io';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:developer';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.red,
        ),
        home: TfliteWidget()
    );
  }
}

class TfliteWidget extends StatefulWidget {
  @override
  _TfliteWidgetState createState() => _TfliteWidgetState();
}

class _TfliteWidgetState extends State<TfliteWidget> {

  File _image;

  double _imageWidth;
  double _imageHeight;

  bool _loading;

  List _recognitions;

  @override
  void initState() {
    super.initState();
    _loading = true;

    Tflite.close();

    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }
  
  loadModel() async {
    await Tflite.loadModel(
        model: "assets/tflite/eye_model.tflite",
        labels: "assets/tflite/eye_labels.txt"
    );
  }

  pickImage() async {
    final picker = ImagePicker();

    var temp = await picker.getImage(source: ImageSource.gallery);
    File image = File(temp.path);

    if(image == null) return;

    setState(() {
      _loading = true;
    });

    loadImage(image);
  }

  loadImage(File image) {
    FileImage(image)
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((image, synchronousCall) {
          setState(() {
            _imageWidth = image.image.width.toDouble();
            _imageHeight = image.image.height.toDouble();
          });
    }));

    setState(() {
      _image = image;
      _recognitions = [];
    });

    makeRecognition(image);
  }

  makeRecognition(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        threshold: 0.23,
        imageMean: 0.0,
        imageStd: 255.0,
    );

    setState(() {
      _loading = false;
      _recognitions = recognitions;
    });
  }

  clearImage() {
    setState(() {
      _image = null;
      _recognitions = [];
    });
  }

  List<Widget> renderBoxes(Size screen) {
    if(_recognitions == null || _imageWidth == null || _imageHeight == null) return [];

    double fx = screen.width;
    double fy = _imageHeight / _imageWidth  * screen.width;

    return _recognitions.map((r) {
      return Positioned(
        left: r["rect"]["x"]*fx,
        top: r["rect"]["y"]*fy,
        width: r["rect"]["w"]*fx,
        height: r["rect"]["h"]*fx,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.red,
              width: 3
            ))
          ),
//          child: Text("${r["detectedClass"]} ${(r["confidenceInClass"] * 100).toStringAsFixed(0)}%",
//              style: TextStyle(
//              color: Colors.white,
//              fontSize: 12
//              )
//            ),
        );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    Size size = MediaQuery.of(context).size;

    List<Widget> stackChildren = [];

    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null ? Text("Pick a image for recognition") : Image.file(_image),
    ));

    stackChildren.addAll(renderBoxes(size));

    stackChildren.add(Stack(
      children: <Widget>[
        Positioned(
          left: 10,
          bottom: 10,
          child: FloatingActionButton(onPressed: clearImage, child: Icon(Icons.delete), backgroundColor: Colors.red,),
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: FloatingActionButton(onPressed: pickImage, child: Icon(Icons.image), backgroundColor: Colors.red,),
        ),
      ],
    ));

    if (_loading) {
      stackChildren.add(Center(
        child: CircularProgressIndicator(),
      ));
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Flutter & TFlite - Eye detection"),
        ),

        body: Stack(
          children: stackChildren,
        )
    );
  }
}