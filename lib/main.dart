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
import 'package:firebase_storage/firebase_storage.dart';
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
  Future<String> upload() async {
    StorageReference storageReference =
        FirebaseStorage.instance.ref().child('images/' + imageFile.path);
    StorageUploadTask storageUploadTask = storageReference.putFile(imageFile);
    StorageTaskSnapshot ss = await storageUploadTask.onComplete;
    print("uploaded");
    return await ss.ref.getDownloadURL() as String;
  }

  File imageFile;
  var step = 0;
  String extracted = "";
  Color theme = Colors.amber;
  final picker = ImagePicker();

  Future<String> _openCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    this.setState(() {
      imageFile = File(pickedFile.path);
      step = 1;
    });
  }

  Future<String> _openGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    this.setState(() {
      imageFile = File(pickedFile.path);
      step = 1;
    });
  }

  Widget getWidget() {
    if (step == 0)
      return Text("No Image", style: TextStyle(fontSize: 30, color: theme));

    if (step == 1) return Image.file(imageFile);
    return Text(extracted, style: TextStyle(fontSize: 17, color: Colors.white));
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
      //resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Center(
            child: Text(
          "GEC Using OCR",
          style: TextStyle(color: Colors.amber),
        )),
      ),
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            //gradient:LinearGradient(
            //color:Colors.black,
            //begin:Alignment.bottomCenter,
            //end:Alignment.topCenter// )
            image: const DecorationImage(
              image: AssetImage('images/bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).copyWith().size.height * 0.8,
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    child: SingleChildScrollView(child: getWidget()),
                  ),
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    MaterialButton(
                      onPressed: () => _openGallery(),
                      color: theme,
                      textColor: Colors.black,
                      child: Icon(
                        Icons.photo_album,
                        size: 30,
                      ),
                      padding: EdgeInsets.all(16),
                      shape: CircleBorder(),
                    ),
                    MaterialButton(
                      onPressed: () => _openCamera(),
                      color: theme,
                      textColor: Colors.black,
                      child: Icon(
                        Icons.camera,
                        size: 30,
                      ),
                      padding: EdgeInsets.all(16),
                      shape: CircleBorder(),
                    ),
                    MaterialButton(
                      onPressed: () => readText(),
                      color: theme,
                      textColor: Colors.black,
                      child: Icon(
                        Icons.code,
                        size: 30,
                      ),
                      padding: EdgeInsets.all(16),
                      shape: CircleBorder(),
                    ),
                    /*RaisedButton(
                      onPressed: () => readText(),
                      child: Text(
                        "Extract Text",
                        style: TextStyle(fontSize: 20),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(30.0)),
                      color: theme,
                      elevation: 5,
                    ),*/
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* OCR using Firebase ml kit
    FirebaseVisionImage img = FirebaseVisionImage.fromFile(imageFile);
    TextRecognizer recText = FirebaseVision.instance.cloudTextRecognizer();
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
      //correctText();
    });*/

/*Azure API call using Dio
Dio dio = new Dio();
    dio.options.headers["Ocp-Apim-Subscription-Key"] = key;
    dio.options.headers["Content-Type"] = "application/octet-stream";
    FormData formdata = new FormData();
    formdata.;
    var response = dio.post(endpoint,)*/

/*//Azure API call using local Image
Map<String, String> headers = {
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

/*//Azure API call JSON
    String url = await upload();
    var body = jsonEncode({'url': url});
    var length = await imageFile.length();
    print(body);
    var response = await http.post(
      endpoint,
      headers: {
        "Ocp-Apim-Subscription-Key": key,
        "Content-Type": "application/json"
      },
      body: body,
    );
    print(response.statusCode);
    while (response.statusCode == 202) {
      print(response.headers);
      response = await http.get(response.headers['operation-location'],
          headers: {'key': azureKey});
      print(response.statusCode);
      print(response.body);
    }*/

/* //Using commercial API
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
        String sugg = "";
        try {
          sugg = error["suggestions"][0];
        } catch (Excaption) {
          sugg = "";
        }
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
    });*/
