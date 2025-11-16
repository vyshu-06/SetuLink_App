import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';

class DocumentUploadScreen extends StatefulWidget {
  final ValueChanged<Map<String, String>> onUploadComplete;

  const DocumentUploadScreen({required this.onUploadComplete, Key? key}) : super(key: key);

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final Map<String, String> _uploadedUrls = {};
  bool _uploading = false;

  Future<void> _pickAndUpload(String docType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() => _uploading = true);
    final file = File(pickedFile.path);

    final ref = FirebaseStorage.instance
        .ref()
        .child('kyc_docs')
        .child('$docType-${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();

    setState(() {
      _uploadedUrls[docType] = url;
      _uploading = false;
    });

    // Automatically proceed when both documents are uploaded
    if (_uploadedUrls.length == 2) {
      widget.onUploadComplete(_uploadedUrls);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('upload_identity_docs_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _uploading ? null : () => _pickAndUpload('aadhar'),
              child: Text(_uploadedUrls.containsKey('aadhar')
                  ? context.tr('aadhar_uploaded')
                  : context.tr('upload_aadhar')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploading ? null : () => _pickAndUpload('passport'),
              child: Text(_uploadedUrls.containsKey('passport')
                  ? context.tr('passport_uploaded')
                  : context.tr('upload_passport')),
            ),
            const SizedBox(height: 32),
            if (_uploading) const Center(child: CircularProgressIndicator()),
            if (_uploadedUrls.length == 2) 
              Center(child: Text(context.tr('all_docs_uploaded'))),
          ],
        ),
      ),
    );
  }
}
