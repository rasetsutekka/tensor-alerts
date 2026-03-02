import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/collection_alert.dart';

class BackendService {
  BackendService({required this.baseUrl});
  final String baseUrl;

  Future<void> registerDevice({required String deviceId, required String fcmToken, String? tensorApiKey}) async {
    await _postWithRetry(
      '/register-device',
      {'deviceId': deviceId, 'fcmToken': fcmToken, 'tensorApiKey': tensorApiKey},
    );
  }

  Future<void> upsertCollection({required String deviceId, required CollectionAlert collection}) async {
    await _postWithRetry(
      '/upsert-collection',
      {'deviceId': deviceId, 'collection': collection.toMap()},
    );
  }

  Future<void> _postWithRetry(String path, Map<String, dynamic> payload) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final res = await http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: {'content-type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 8));
        if (res.statusCode >= 200 && res.statusCode < 300) return;
        lastError = 'HTTP ${res.statusCode}: ${res.body}';
      } catch (e) {
        lastError = e;
      }
      await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
    }
    throw Exception('Backend request failed ($path): $lastError');
  }
}
