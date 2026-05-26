import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // Ensure row exists
    await _client.from('profiles').upsert({'id': user.id});

    // Fetch profile
    final row = await _client
        .from('profiles')
        .select('id, full_name, avatar_url, updated_at')
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;

    final profile = Map<String, dynamic>.from(row);

    // If profile full_name is empty, try to copy it from auth user metadata
    final profileName = (profile['full_name'] ?? '').toString().trim();
    final metaName = (user.userMetadata?['full_name'] ?? '').toString().trim();

    if (profileName.isEmpty && metaName.isNotEmpty) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': metaName,
        'updated_at': DateTime.now().toIso8601String(),
      });

      profile['full_name'] = metaName;
    }

    return profile;
  }

  Future<void> updateMyProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName.trim().isEmpty ? null : fullName.trim(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Uploads an image file to Storage and returns a signed URL (private bucket).
  Future<String> uploadAvatarAndGetSignedUrl({required File file}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final ext = file.path.split('.').last.toLowerCase();
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage
        .from('avatars')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    // Signed URL valid for 1 year
    final signedUrl = await _client.storage
        .from('avatars')
        .createSignedUrl(path, 60 * 60 * 24 * 365);

    return signedUrl;
  }
}
