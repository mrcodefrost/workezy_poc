import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  List<int>? _selectedFile;
  Uint8List? _bytesData;

  startWebFilePicker() async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.multiple = true;
    uploadInput.draggable = true;
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      final file = files![0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) {
        setState(() {
          _bytesData =
              const Base64Decoder().convert(reader.result.toString().split(",").last);
          _selectedFile = _bytesData;
        });
      });
      reader.readAsDataUrl(file);
    });
  }

  Future uploadImage() async {
    var url = Uri.parse("API URL HERE...");
    var request = http.MultipartRequest("POST", url);
    request.files.add(http.MultipartFile.fromBytes('file', _selectedFile!,
        contentType: MediaType('application', 'json'), filename: "Any_name"));

    request.send().then((response) {
      if (response.statusCode == 200) {
        print("File uploaded successfully");
      } else {
        print('file upload failed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
            child: Column(
          children: [
            const Text('Let\'s upload Image'),
            const SizedBox(height: 20),
            MaterialButton(
              color: Colors.pink,
              elevation: 8,
              highlightElevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textColor: Colors.white,
              child: const Text("Select Photo"),
              onPressed: () {
                startWebFilePicker();
              },
            ),
            const Divider(
              color: Colors.teal,
            ),
            _bytesData != null
                ? Image.memory(_bytesData!, width: 200, height: 200)
                : Container(),
            MaterialButton(
              color: Colors.purple,
              elevation: 8,
              highlightElevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textColor: Colors.white,
              child: const Text("Send file to server"),
              onPressed: () {
                uploadImage();
              },
            ),
          ],
        )),
      ),
    );
  }
}

// Methods for Geniex

// need to update upload files
Future<void> uploadFiles() async {
  final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*'; // Specify file types
  uploadInput.multiple = true; // Allow multiple file selection
  uploadInput.click();

  uploadInput.onChange.listen((e) async {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) return;

    List<Uint8List> imageDataList = [];

    // Prepare the multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('YOUR_UPLOAD_URL'), // Replace with your upload URL
    );

    // Add each selected file to the request
    for (var file in files) {
      await addFileToRequest(request, file, 'propertyImages');
    }

    // Send the request
    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print('Files uploaded successfully');
      } else {
        print('File upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('File upload failed: $e');
    }
  });
}

// to add file
Future<void> addFileToRequest(
    http.MultipartRequest request, html.File file, String fieldName) async {
  try {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;

    final data = reader.result as Uint8List;
    final mimeType = lookupMimeType(file.name) ?? 'application/octet-stream';

    var multipartFile = http.MultipartFile.fromBytes(
      fieldName,
      data,
      filename: file.name,
      contentType: MediaType.parse(mimeType),
    );
    request.files.add(multipartFile);
  } catch (e) {
    print('Error adding file to request: $e');
  }
}
