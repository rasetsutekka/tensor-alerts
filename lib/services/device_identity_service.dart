import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentityService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'tensor_alerts_device_id';

  static Future<String> getOrCreateId() async {
    final existing = await _storage.read(key: _key);
    if (existing != null) return existing;
    final id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    await _storage.write(key: _key, value: id);
    return id;
  }
}
