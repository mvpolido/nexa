import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String baseUrl = 'http://localhost:3000'; // Alterar para IP da máquina em produção

  // 1. Função para pedir o código por e-mail
  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['message'] ?? 'Erro ao solicitar recuperação de senha.');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  // 2. Função para enviar o código e a nova senha
  static Future<void> resetPassword(String email, String token, String novaSenha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'novaSenha': novaSenha,
        }),
      );

      if (response.statusCode != 200) {
        final jsonResponse = jsonDecode(response.body);
        throw Exception(jsonResponse['message'] ?? 'Erro ao redefinir a senha.');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }
}