import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Future<void> init() async {
    // Handle app opened from terminated state
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleUri(initialUri);
    }

    // Handle app opened while running
    _sub = _appLinks.uriLinkStream.listen((uri) async {
      await _handleUri(uri);
    });
  }

  Future<void> _handleUri(Uri uri) async {
    // Supabase magic link comes back with tokens in query/fragment; Supabase Flutter can parse it:
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
  }

  void dispose() {
    _sub?.cancel();
  }
}
