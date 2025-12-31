import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/supabase/client.dart';

class ScanService {
  final _picker = ImagePicker();

  Future<String?> pickAndUploadReceipt({required String userId}) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return null;

    final file = File(picked.path);
    final fileName = 'receipts/$userId/${DateTime.now().toUtc().toIso8601String()}.jpg';

    final storageRes = await SupabaseClientWrapper.instance.storage.from('receipts').upload(fileName, file);
    if (storageRes.error != null) throw Exception(storageRes.error!.message);

    final publicUrlRes = SupabaseClientWrapper.instance.storage.from('receipts').getPublicUrl(fileName);
    final imageUrl = publicUrlRes.data!
        .publicURL; // For production consider signed URLs with expiry instead of public URLs

    // Insert receipt record in DB
    final insertRes = await SupabaseClientWrapper.instance.from('receipts').insert([
      {
        'user_id': userId,
        'image_url': imageUrl,
        'store': null,
        'total_value': 0,
        'cashback_value': 0,
        'status': 'processing',
      }
    ]).select();

    if (insertRes.error != null) throw Exception(insertRes.error!.message);

    final inserted = insertRes.data != null && insertRes.data is List && (insertRes.data as List).isNotEmpty
        ? (insertRes.data as List).first['id']
        : null;

    return inserted as String?;
  }
}
