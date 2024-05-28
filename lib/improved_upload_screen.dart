import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ImageUploadPreview extends StatefulWidget {
  const ImageUploadPreview({super.key});

  @override
  _ImageUploadPreviewState createState() => _ImageUploadPreviewState();
}

class _ImageUploadPreviewState extends State<ImageUploadPreview> {
  final List<html.File> _selectedFiles = [];
  final List<Uint8List> _imageDataList = [];

  void _selectImages() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.multiple = true;
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      if (files.length + _selectedFiles.length > 10) {
        _showDialog('You can only select upto 10 images');
        return;
      }

      List<Uint8List> imageDataList = [];

      for (var file in files) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        await reader.onLoadEnd.first;
        final data = reader.result as Uint8List;
        imageDataList.add(data);
      }

      setState(() {
        _selectedFiles.addAll(files);
        _imageDataList.addAll(imageDataList);
      });
    });
  }

  Future<void> _submitImages() async {
    if (_selectedFiles.isEmpty) {
      _showDialog('No images selected');
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('YOUR_UPLOAD_URL'), // Replace with your upload URL
    );

    for (int i = 0; i < _selectedFiles.length; i++) {
      await addFileToRequest(request, _selectedFiles[i], 'propertyImages');
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        _showDialog('Images uploaded successfully');
      } else {
        _showDialog('Upload failed, check logs');
        debugPrint('Error status code ${response.statusCode}');
      }
    } catch (e) {
      _showDialog('Upload failed, check logs');
      debugPrint('Upload failed : ${e.toString()}');
    }
  }

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

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _selectImages,
          child: const Text('Select Images'),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _imageDataList.isNotEmpty
              ? GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _imageDataList.length,
                  itemBuilder: (context, index) {
                    return Image.memory(_imageDataList[index],
                        fit: BoxFit.cover);
                  },
                )
              : const Center(child: Text('No images selected')),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitImages,
          child: const Text('Submit Images'),
        ),
      ],
    );
  }
}
