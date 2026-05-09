import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadPostImage(XFile imageFile, String userId) async {
    final fileName = '${_uuid.v4()}.jpg';
    final path = '$userId/$fileName';
    
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from('posts').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
    } else {
      await _supabase.storage.from('posts').upload(
        path,
        File(imageFile.path),
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
    }
    
    return _supabase.storage.from('posts').getPublicUrl(path);
  }

  Future<String> uploadProfileImage(XFile imageFile, String userId) async {
    final path = '$userId/avatar.jpg';
    
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from('profiles').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
    } else {
      await _supabase.storage.from('profiles').upload(
        path,
        File(imageFile.path),
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
    }
    
    return _supabase.storage.from('profiles').getPublicUrl(path);
  }

  Future<void> deleteImage(String imageUrl) async {
    // Basic deletion logic could be implemented here by parsing the path from URL
  }
}
