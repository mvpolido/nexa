import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Import necessário para o Token
import '../models/notificacao_model.dart';
import '../config/api_config.dart'; 

class NotificacaoService {
  
  // 1️⃣ Função para buscar a lista de notificações
  // 1️⃣ Função para buscar a lista de notificações (MODO DEBUG)
  Future<List<NotificacaoModel>> getNotificacoes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      print("🕵️‍♂️ 1. TOKEN LIDO DO CELULAR: $token");

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notificacoes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("🕵️‍♂️ 2. STATUS DA RESPOSTA: ${response.statusCode}");
      print("🕵️‍♂️ 3. DADOS QUE VIERAM DO BANCO: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificacaoModel.fromJson(json)).toList();
      } else {
        throw Exception('Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 ERRO NO SERVIÇO DE NOTIFICAÇÃO: $e');
      return []; 
    }
  }

  // 2️⃣ Função para marcar uma notificação específica como lida
  Future<bool> marcarComoLida(int id) async {
    try {
      // 🔑 Pega o token salvo no login
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notificacoes/$id/lida'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // 👈 Precisa do crachá aqui também!
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Erro no NotificacaoService (marcarComoLida): $e');
      return false;
    }
  }
}