// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========== دالة مساعدة للحصول على النصوص المترجمة ==========
  String _getLocalizedString(String key) {
    // هذه دالة مساعدة، سيتم استبدالها بالنص الفعلي من التطبيق
    // عند استخدامها في الشاشات، سنمرر context
    return key;
  }

  Future<String> uploadFile(File file, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('${_getLocalizedString('uploadFileFailed')}: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(List<XFile> images, String folderPath) async {
    List<String> urls = [];
    try {
      for (var image in images) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        String url = await uploadFile(
          File(image.path),
          '$folderPath/$fileName',
        );
        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('${_getLocalizedString('uploadMultipleFailed')}: $e');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('${_getLocalizedString('deleteFileFailed')}: $e');
    }
  }
}