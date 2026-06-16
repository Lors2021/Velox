import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Compress and upload avatar, return download URL
  Future<String> uploadAvatar({
    required String uid,
    required File imageFile,
  }) async {
    final compressed = await _compressImage(imageFile, quality: 70);
    final ref = _storage
        .ref()
        .child(AppConstants.avatarStoragePath)
        .child('$uid.jpg');
    await ref.putFile(compressed);
    return await ref.getDownloadURL();
  }

  /// Compress and upload chat image, return download URL
  Future<String> uploadChatImage({
    required String chatId,
    required String senderId,
    required File imageFile,
  }) async {
    final compressed = await _compressImage(imageFile, quality: 60);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$senderId.jpg';
    final ref = _storage
        .ref()
        .child(AppConstants.chatImagesPath)
        .child(chatId)
        .child(fileName);
    await ref.putFile(compressed);
    return await ref.getDownloadURL();
  }

  Future<File> _compressImage(File file, {int quality = 70}) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: 800,
      minHeight: 800,
    );
    return result != null ? File(result.path) : file;
  }
}
