import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

void main() {
  runApp(
    MaterialApp(
      home: MyApp(),
      title: 'Crop AI',
      debugShowCheckedModeBanner: false,
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  File _image;
  final picker = ImagePicker();
  bool submitButtonVisible = false;
  bool predictedLabelTextVisible = false;
  bool isImagePosting = false;
  String predictedLabelText;

  Widget buildWelcomeScreen() {
    return (Column(children: <Widget>[
      FractionallySizedBox(
        child: Image(
          image: AssetImage('assets/crop.png'),
        ),
        widthFactor: 0.8,
      ),
      SizedBox(height: 40),
      Text(
        "Select An Image",
        style: TextStyle(fontSize: 25),
      ),
    ]));
  }

  Future getCameraImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    print(pickedFile.path);

    setState(() {
      _image = File(pickedFile.path);
      submitButtonVisible = true;
      predictedLabelTextVisible = false;
    });
  }

  Future getGalleryImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      _image = File(pickedFile.path);
      submitButtonVisible = true;
      predictedLabelTextVisible = false;
    });
  }

  SpeedDial buildSpeedDial() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      backgroundColor: Colors.greenAccent[700],
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.perm_media, color: Colors.white),
          backgroundColor: Colors.green[600],
          onTap: getGalleryImage,
          label: 'Gallery',
          labelStyle:
              TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 15),
          labelBackgroundColor: Colors.green[600],
        ),
        SpeedDialChild(
          child: Icon(Icons.camera, color: Colors.white),
          backgroundColor: Colors.green[600],
          onTap: getCameraImage,
          label: 'Camera',
          labelStyle:
              TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 15),
          labelBackgroundColor: Colors.green[600],
        ),
      ],
    );
  }

  Widget buildImageContainer() {
    return (
      FractionallySizedBox(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.0),
          child: Image.file(_image),
        ),
        widthFactor: 0.74,
      )
    );
  }

  Widget buildAppBar() {
    return (AppBar(
      title: Text('Crop AI'),
      backgroundColor: Colors.greenAccent[700],
      centerTitle: true,
    ));
  }

  void postImageToServer(File image) async {
    setState(() {
      isImagePosting = true;
    });
    var stream = new http.ByteStream(Stream.castFrom(image.openRead()));
    var length = await image.length();
    var uri = Uri.parse('https://cropaiapp.herokuapp.com/');

    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('InputImg', stream, length,
        filename: basename(image.path));

    request.files.add(multipartFile);
    var response = await request.send();
    print(response);

    response.stream.transform(utf8.decoder).listen((value) {
      setState(() {
        isImagePosting = false;
        predictedLabelText = value;
        submitButtonVisible = false;
        predictedLabelTextVisible = true;
      });
    });
  }

  Widget buildSubmitButton() {
    return (RaisedButton(
      child: Text("SUBMIT"),
      onPressed: () => postImageToServer(_image),
      color: Colors.greenAccent[700],
      textColor: Colors.white,
    ));
  }

  Widget buildProgressIndicator() {
    return (
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("Please Wait", style: TextStyle(fontSize: 20),),
            SizedBox(height: 15),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[400]),
            ),
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      floatingActionButton: buildSpeedDial(),
      body: Center(
        child: isImagePosting == true
            ? buildProgressIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _image == null ? buildWelcomeScreen() : buildImageContainer(),
                  SizedBox(height: 20),
                  if (submitButtonVisible == true) 
                    buildSubmitButton(),
                  if (predictedLabelTextVisible == true)
                    Center(
                      child: Text(
                        predictedLabelText, 
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}