import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

abstract class ImageRepository {
  Future<String> uploadImage(File file);
}

class ImageRepositoryImpl implements ImageRepository {
  final http.Client client;

  ImageRepositoryImpl({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<String> uploadImage(File file) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(docDir.path, 'product_images'));
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final ext = p.extension(file.path);
      final filename = '${const Uuid().v4()}$ext';
      final savedFile = File(p.join(imagesDir.path, filename));
      
      await file.copy(savedFile.path);

      return 'local:$filename';
    } catch (e) {
      throw Exception('Failed to save image locally: $e');
    }
  }
}
