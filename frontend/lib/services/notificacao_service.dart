import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Import necessário para o Token
import '../models/notificacao_model.dart';
import '../config/api_config.dart'; 

class NotificacaoService {
  Future<List<NotificacaoModel>> getNotificacoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notificacoes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificacaoModel.fromJson(json)).toList();
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Erro ao buscar notificações.', error: e);
      return []; 
    }
  }

  Future<bool> marcarComoLida(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notificacoes/$id/lida'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Erro ao marcar notificação como lida.', error: e);
      return false;
    }
  }
}
