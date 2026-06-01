import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'permissions_service.dart';
import 'security_service.dart';

class PickedCompressedImage {
  final String fileName;
  final String originalContentType;
  final int originalBytes;
  final String compressedContentType;
  final int compressedBytes;
  final String compressedBase64;
  final int width;
  final int height;
  final Uint8List previewBytes;

  const PickedCompressedImage({required this.fileName, required this.originalContentType, required this.originalBytes, required this.compressedContentType, required this.compressedBytes, required this.compressedBase64, required this.width, required this.height, required this.previewBytes});
}

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<PickedCompressedImage?> pickAndCompress({bool camera = false}) async {
    SecurityService().suppressLockFor(const Duration(minutes: 3));
    final ok = camera ? await PermissionsService.requestCamera() : await PermissionsService.requestGallery();
    if (!ok) throw Exception(camera ? 'Camera permission is required.' : 'Gallery permission is required.');
    final file = await _picker.pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, imageQuality: 95);
    SecurityService().suppressLockFor(const Duration(seconds: 45));
    if (file == null) return null;
    final bytes = await File(file.path).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not read selected image.');
    final resized = decoded.width > 1800 ? img.copyResize(decoded, width: 1800) : decoded;
    final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: 82));
    final name = file.name.toLowerCase().endsWith('.jpg') || file.name.toLowerCase().endsWith('.jpeg') ? file.name : '${file.name}.jpg';
    return PickedCompressedImage(
      fileName: name,
      originalContentType: file.mimeType ?? 'image/jpeg',
      originalBytes: bytes.length,
      compressedContentType: 'image/jpeg',
      compressedBytes: encoded.length,
      compressedBase64: base64Encode(encoded),
      width: resized.width,
      height: resized.height,
      previewBytes: encoded,
    );
  }
}
