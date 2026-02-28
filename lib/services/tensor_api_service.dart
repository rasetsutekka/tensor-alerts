import 'dart:convert';
import 'package:http/http.dart' as http;

class TensorApiService {
  Future<double> fetchFloorPrice({required String slug, required String apiKey}) async {
    final uri = Uri.parse('https://api.tensor.so/collections/$slug/floor');
    final res = await http.get(uri, headers: {'x-tensor-api-key': apiKey});
    if (res.statusCode >= 400) return 0;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['floorPriceSol'] ?? 0).toDouble();
  }
}
