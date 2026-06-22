import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AdminServiceException implements Exception {
  AdminServiceException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class AdminService {
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.trim().isEmpty) {
      throw AdminServiceException(
        'Sessão expirada. Faça login novamente.',
        401,
      );
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

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

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> _handle(http.Response response) async {
    final data = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    debugPrint(
      'AdminService falhou: ${response.request?.method} ${response.request?.url} -> ${response.statusCode}',
    );

    final fallback = switch (response.statusCode) {
      401 => 'Sessão expirada. Faça login novamente.',
      403 => 'Você não tem permissão para realizar esta ação.',
      404 => 'Registro não encontrado.',
      409 => 'Não foi possível concluir por conflito de dados.',
      500 => 'Erro interno no servidor.',
      _ => 'Erro ao processar solicitação.',
    };

    final message = data is Map && data['message'] != null
        ? data['message'].toString()
        : fallback;

    throw AdminServiceException(message, response.statusCode);
  }

  Future<dynamic> _get(
    String path, [
    Map<String, String?> query = const {},
  ]) async {
    final response = await http.get(
      _uri(path, query),
      headers: await _headers(),
    );
    return _handle(response);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<dynamic> _delete(String path) async {
    final response = await http.delete(_uri(path), headers: await _headers());
    return _handle(response);
  }

  Future<http.Response> _getRaw(
    String path, [
    Map<String, String?> query = const {},
  ]) async {
    final response = await http.get(
      _uri(path, query),
      headers: await _headers(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    await _handle(response);
    return response;
  }

  Future<Map<String, dynamic>> dashboardStats() async {
    final data = await _get('/admin/dashboard/stats');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<dynamic>> usuarios({String? busca, String? perfil}) async {
    final data = await _get('/admin/usuarios', {
      'busca': busca,
      'perfil': perfil,
    });
    if (data is Map && data['usuarios'] is List) return data['usuarios'];
    return data is List ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> usuarioDetalhe(int id) async {
    final data = await _get('/admin/usuarios/$id');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<dynamic>> empresas({
    String? busca,
    bool? verificada,
    String? statusVerificacao,
  }) async {
    final data = await _get('/admin/empresas', {
      'busca': busca,
      'verificada': verificada?.toString(),
      'status_verificacao': statusVerificacao,
    });
    if (data is Map && data['empresas'] is List) return data['empresas'];
    return data is List ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> empresaDetalhe(int id) async {
    final data = await _get('/admin/empresas/$id');
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Future<List<dynamic>> vagas({String? busca, bool? ativo}) async {
    final data = await _get('/admin/vagas', {
      'busca': busca,
      'ativo': ativo?.toString(),
    });
    return data is List ? data : <dynamic>[];
  }

  Future<List<dynamic>> habilidades({String? busca, String? area}) async {
    final data = await _get('/admin/habilidades', {
      'busca': busca,
      'area': area,
    });
    return data is List ? data : <dynamic>[];
  }

  Future<void> verificarEmpresa(int id, bool verificada) async {
    await _patch('/admin/empresas/$id/verificar', {'verificada': verificada});
  }

  Future<List<int>> documentoVerificacaoEmpresa(int id) async {
    final response = await _getRaw('/admin/empresas/$id/documento-verificacao');
    return response.bodyBytes;
  }

  Future<void> decidirVerificacaoEmpresa(
    int id,
    String decisao, {
    String? motivo,
  }) async {
    await _patch('/admin/empresas/$id/verificacao', {
      'decisao': decisao,
      if (motivo != null) 'motivo': motivo,
    });
  }

  Future<void> criarHabilidade(String nome, String area) async {
    await _post('/admin/habilidades', {'nome': nome, 'area': area});
  }

  Future<void> atualizarHabilidade(int id, String nome, String area) async {
    await _patch('/admin/habilidades/$id', {'nome': nome, 'area': area});
  }

  Future<void> excluirHabilidade(int id) async {
    await _delete('/admin/habilidades/$id');
  }

  Future<void> excluirVaga(int id) async {
    await _delete('/admin/vagas/$id');
  }

  Future<void> excluirUsuario(int id) async {
    await _delete('/admin/usuarios/$id');
  }
}
