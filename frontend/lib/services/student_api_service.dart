import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/student_profile_model.dart';

class StudentApiService {
  static const String baseUrl = 'http://localhost:3000'; // Alterar para IP da máquina em produção

  static Future<StudentProfile> getStudentProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/alunos/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return StudentProfile.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Token expirado ou inválido');
      } else {
        throw Exception('Erro ao buscar perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  static Future<StudentProfile> updateStudentProfile(
    String token,
    StudentProfile profile,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/alunos/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nome_exibicao': profile.nomeExibicao,
          'email': profile.email,
          'curso': profile.curso,
          'url_curriculo': profile.urlCurriculo,
          'cpf': profile.cpf,
          'endereco': profile.endereco,
          'logradouro': profile.logradouro,
          'cep': profile.cep,
          'numero': profile.numero,
          'bairro': profile.bairro,
          'cidade': profile.cidade,
          'estado': profile.estado,
          'latitude': profile.latitude,
          'longitude': profile.longitude,
          'foto_perfil': profile.fotoPerfil,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return StudentProfile.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Token expirado ou inválido');
      } else {
        throw Exception('Erro ao atualizar perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }
}
