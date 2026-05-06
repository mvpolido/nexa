import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressData {
  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String estado;

  AddressData({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory AddressData.fromJson(Map<String, dynamic> json) {
    return AddressData(
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      bairro: json['bairro'] ?? '',
      cidade: json['localidade'] ?? '', // A API do ViaCEP usa 'localidade'
      estado: json['uf'] ?? '',
    );
  }
}

class AddressService {
  // Busca o CEP na API do ViaCEP (com fallback)
  static Future<AddressData> fetchCep(String cep) async {
    try {
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
      print('🌐 Chamando ViaCEP com CEP: $cleanCep');
      
      // Tenta primeira com https://
      try {
        final response = await http.get(
          Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'),
          headers: {'User-Agent': 'Mozilla/5.0'},
        ).timeout(const Duration(seconds: 10));
        
        print('📡 Resposta ViaCEP (https): ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ JSON decodificado: $data');
          
          if (data['erro'] == true) {
            throw Exception('CEP não encontrado na base de dados do ViaCEP');
          }
          
          final result = AddressData.fromJson(data);
          print('📍 Endereço extraído: logradouro=${result.logradouro}, bairro=${result.bairro}, cidade=${result.cidade}');
          return result;
        }
      } catch (e) {
        print('⚠️ Erro com https, tentando http: $e');
        // Se https falhar, tenta com http
        final response = await http.get(
          Uri.parse('http://viacep.com.br/ws/$cleanCep/json/'),
          headers: {'User-Agent': 'Mozilla/5.0'},
        ).timeout(const Duration(seconds: 10));
        
        print('📡 Resposta ViaCEP (http): ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ JSON decodificado (http): $data');
          
          if (data['erro'] == true) {
            throw Exception('CEP não encontrado');
          }
          
          final result = AddressData.fromJson(data);
          print('📍 Endereço extraído (http): logradouro=${result.logradouro}, bairro=${result.bairro}, cidade=${result.cidade}');
          return result;
        }
      }
      
      throw Exception('Não foi possível buscar o CEP em ambas as tentativas');
    } catch (e) {
      print('❌ Erro ao buscar CEP: $e');
      rethrow;
    }
  }

  // Busca a Latitude e Longitude para o Mapa
  static Future<LatLng> geocodeAddress({
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required String cep,
  }) async {
    try {
      // Tenta primeiro com a rua completa
      final query = '$logradouro, $numero, $bairro, $cidade, $estado, Brazil';
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      
      print('🌐 Geocoding com endereço completo: $query');
      var response = await http.get(url, headers: {'User-Agent': 'NexaApp/1.0'}).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          print('✅ Geocoding bem-sucedido (endereço): $lat, $lon');
          return LatLng(lat, lon);
        }
      }

      // Se falhar, tenta apenas com cidade e estado
      print('⚠️ Não encontrou com endereço completo, tentando com cidade e estado...');
      final cityQuery = '$cidade, $estado, Brazil';
      final cityUrl = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cityQuery)}&format=json&limit=1');
      
      response = await http.get(cityUrl, headers: {'User-Agent': 'NexaApp/1.0'}).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          print('✅ Geocoding bem-sucedido (cidade/estado): $lat, $lon');
          return LatLng(lat, lon);
        }
      }
      
      // Última tentativa: apenas a cidade
      print('⚠️ Tentando apenas com a cidade...');
      final simpleCityUrl = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cidade)}&format=json&limit=1');
      response = await http.get(simpleCityUrl, headers: {'User-Agent': 'NexaApp/1.0'}).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          print('✅ Geocoding bem-sucedido (cidade): $lat, $lon');
          return LatLng(lat, lon);
        }
      }
      
      throw Exception('Não foi possível encontrar as coordenadas para $cidade, $estado');
    } catch (e) {
      print('❌ Erro ao fazer geocoding: $e');
      rethrow;
    }
  }
}