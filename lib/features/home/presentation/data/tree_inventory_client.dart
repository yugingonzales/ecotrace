import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../models/map_tree.dart';

class TreeInventoryClient {
  static Future<List<MapTree>> fetch() async {
    final response = await http
        .get(Uri.parse('${ApiConfig.plants}?pageSize=5000'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const TreeInventoryException('Unable to load the tree inventory.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => MapTree.fromApi(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class TreeInventoryException implements Exception {
  const TreeInventoryException(this.message);
  final String message;
  @override
  String toString() => message;
}
