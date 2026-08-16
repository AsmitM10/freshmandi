import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';

/// Uploads the FSSAI certificate to the private `fssai-documents` Storage
/// bucket and records a reference (never the binary) in
/// `restaurant_documents`. The storage path is scoped to the caller's own
/// user id so the storage RLS policies (see SQL migration) can enforce
/// ownership: `{user_id}/{restaurant_id}/{file_name}`.
class FssaiDocumentRepository {
  FssaiDocumentRepository(this._client);

  final SupabaseClient _client;

  static const _bucket = 'fssai-documents';

  Future<void> uploadAndRecord({
    required String restaurantId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required int fileSize,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('You need to be signed in to continue.');
    }

    final storagePath = '$userId/$restaurantId/$fileName';

    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      await _client.from('restaurant_documents').insert({
        'restaurant_id': restaurantId,
        'document_type': 'fssai_certificate',
        'file_name': fileName,
        'storage_path': storagePath,
        'file_size': fileSize,
        'mime_type': mimeType,
      });
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}
