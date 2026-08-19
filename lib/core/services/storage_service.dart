import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Uploads listing photos to Cloudinary (unsigned upload) under
/// dobara/listings/{sellerId}/{listingId}/{index} and returns the
/// secure (https) delivery URLs.
///
/// Uses an unsigned upload preset, so no API secret is embedded in
/// the app — safe for client-side use. Works on Web, Android, and
/// iOS since it uses raw bytes (Uint8List) rather than dart:io File.
class StorageService {
  // TODO: move these to --dart-define if you don't want them
  // hardcoded in source (they aren't secret, but it's cleaner).
  static const String _cloudName = 'vdhhhwqj';
  static const String _uploadPreset = 'dobara';

  static Uri get _uploadUrl => Uri.parse(
    'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
  );

  Future<List<String>> uploadListingImages({
    required String sellerId,
    required String listingId,
    required List<Uint8List> images,
  }) async {
    final urls = <String>[];

    for (var i = 0; i < images.length; i++) {
      final request = http.MultipartRequest('POST', _uploadUrl)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'dobara/listings/$sellerId/$listingId'
        ..fields['public_id'] = '$i'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            images[i],
            filename: '$i.jpg',
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Cloudinary upload failed (${response.statusCode}): '
              '${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;
      if (secureUrl == null) {
        throw Exception('Cloudinary response missing secure_url');
      }
      urls.add(secureUrl);
    }

    return urls;
  }
}