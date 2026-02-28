import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/collection_alert.dart';

class BackendService {
  BackendService({required this.baseUrl});
  final String baseUrl;

  Future<void> registerDevice({required String deviceId, required String fcmToken, String? tensorApiKey}) async {
    await http.post(
      Uri.parse('$baseUrl/register-device'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId, 'fcmToken': fcmToken, 'tensorApiKey': tensorApiKey}),
    );
  }

  Future<void> upsertCollection({required String deviceId, required CollectionAlert collection}) async {
    await http.post(
      Uri.parse('$baseUrl/upsert-collection'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId, 'collection': collection.toMap()}),
    );
  }
}
