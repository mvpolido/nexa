import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class CatalogServiceException implements Exception {
  CatalogServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CatalogService {
  Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final filtered = <String, String>{};
    query.forEach((key, value) {
      if (value != null && value.trim().isNotEmpty) {
        filtered[key] = value.trim();
      }
    });

    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: filtered.isEmpty ? null : filtered);
  }

  Future<List<String>> cursos({String? busca}) async {
    final response = await http.get(_uri('/cursos', {'busca': busca}));
    return _handleList(response, 'cursos');
  }

  Future<List<String>> instituicoes({String? busca}) async {
    final response = await http.get(_uri('/instituicoes', {'busca': busca}));
    return _handleList(response, 'instituições');
  }

  List<String> _handleList(http.Response response, String label) {
    final data = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is List) {
        return data
            .map((item) {
              if (item is Map && item['nome'] != null) {
                return item['nome'].toString();
              }
              return item.toString();
            })
            .where((item) => item.trim().isNotEmpty)
            .toList();
      }
      return <String>[];
    }

    final message = data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Erro ao carregar $label.';
    throw CatalogServiceException(message);
  }
}
