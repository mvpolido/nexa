Future<List<Vaga>> fetchVagas() async {
  try {
    // Substitua pelo IP real se estiver testando no celular, 
    // ou localhost:3000 se estiver no Opera GX no Linux Mint
    final response = await dio.get('http://localhost:3000/vagas');

    if (response.statusCode == 200) {
      List lista = response.data;
      return lista.map((json) => Vaga.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao carregar vagas');
    }
  } catch (e) {
    throw Exception('Falha na conexão com o servidor');
  }
}