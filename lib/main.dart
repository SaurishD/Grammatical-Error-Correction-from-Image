import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import './keys.dart';

void main() => runApp(new MaterialApp(
      title: "A title",
      home: LandingScreen(),
    ));

class LandingScreen extends StatefulWidget {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  File imageFile;
  var step = 0;
  String extracted = "";
  final picker = ImagePicker();

  Future _openCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    this.setState(() {
      imageFile = File(pickedFile.path);
      step = 1;
    });
  }

  Future readText() async {
    extracted = "";
    FirebaseVisionImage img = FirebaseVisionImage.fromFile(imageFile);
    TextRecognizer recText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recText.processImage(img);
    this.setState(() {
      for (TextBlock block in readText.blocks) {
        for (TextLine line in block.lines) {
          for (TextElement elem in line.elements) {
            //print(elem.text);
            extracted += " " + elem.text;
          }
        }
      }

      //print(extracted);
      step = 2;
      correctText();
    });
  }

  Widget getWidget() {
    if (step == 0) return Text("No Image");
    if (step == 1) return Image.file(imageFile);
    return Text(extracted);
  }

  Future<String> correctText() async {
    var key = gramKey;
    var response = await http.post(
        Uri.encodeFull("http://api.prowritingaid.com/api/async/text"),
        headers: {
          "LicenseCode": key,
        },
        body: {
          "text": extracted,
          "reports": "grammar"
        });
    print(response.body);
    Map<String, dynamic> map = json.decode(response.body);
    List<dynamic> data = map["Result"]["Tags"];
    var count = 0;
    var errorCount = 0;
    this.setState(() {
      data.forEach((error) {
        errorCount += 1;
        var pos = error["endPos"] + 1 + count;
        String sugg = error["suggestions"][0];
        extracted = extracted.substring(0, pos) +
            "(" +
            sugg +
            ")" +
            extracted.substring(pos);
        count = count + sugg.length + 2;
        print(pos);
        print(sugg);
        print(count);
      });
      extracted += "\n\n Total errors found :" + errorCount.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Center(child: Text("Main Screen")),
      ),
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                child: getWidget(),
                //child: step == 0 ? Text("No Image") : Image.file(imageFile)
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  RaisedButton(
                    onPressed: () => _openCamera(),
                    child: Text("Select Image"),
                  ),
                  RaisedButton(
                    onPressed: () => readText(),
                    child: Text("Extract Text"),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*Dio dio = new Dio();
    dio.options.headers["Ocp-Apim-Subscription-Key"] = key;
    dio.options.headers["Content-Type"] = "application/octet-stream";
    FormData formdata = new FormData();
    formdata.;
    var response = dio.post(endpoint,)*/

/*Map<String, String> headers = {
      "Ocp-Apim-Subscription-Key": key,
      "Content-Type": "multipart/form-data"
    };

    var request = new http.MultipartRequest("POST", Uri.parse(endpoint));
    var multipartFileSign = new http.MultipartFile(
        'data', http.ByteStream(imageFile.openRead()), length,
        filename: basename(imageFile.path));
    request.files.add(multipartFileSign);
    request.headers.addAll(headers);
    var response = await request.send();
    String result = await response.stream.bytesToString();
    print(result);*/

/*var key = azureKey;
    var endpoint =
        "https://centralindia.api.cognitive.microsoft.com//vision/v3.0/read/analyze";
    var stream = await imageFile.readAsBytes();
    String body = stream.toString();
    var length = await imageFile.length();
    print(body);

    var response = await http.post(endpoint,
        headers: {
          "Ocp-Apim-Subscription-Key": key,
          "Content-Type": "application/octet-stream"
        },
        body: {'data': body},
        encoding: Encoding.getByName("utf-8"));

    print(response.body);*/
