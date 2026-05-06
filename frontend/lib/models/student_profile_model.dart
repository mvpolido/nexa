class StudentProfile {
  final int id;
  final String nomeExibicao;
  final String email;
  final String? cpf;
  final String? curso;
  final String? instituicao;
  final String? urlCurriculo;
  final String? endereco;
  final String? logradouro;
  final String? cep;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? fotoPerfil;
  final double? latitude;
  final double? longitude;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  StudentProfile({
    required this.id,
    required this.nomeExibicao,
    required this.email,
    this.cpf,
    this.curso,
    this.instituicao,
    this.urlCurriculo,
    this.endereco,
    this.logradouro,
    this.cep,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.fotoPerfil,
    this.latitude,
    this.longitude,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      nomeExibicao: json['nome_exibicao'] as String,
      email: json['email'] as String,
      cpf: json['aluno']?['cpf'] as String?,
      curso: json['aluno']?['curso'] as String?,
      instituicao: json['aluno']?['instituicao'] as String?,
      urlCurriculo: json['aluno']?['url_curriculo'] as String?,
      endereco: json['aluno']?['endereco'] as String?,
      logradouro: json['aluno']?['logradouro'] as String?,
      cep: json['aluno']?['cep'] as String?,
      numero: json['aluno']?['numero'] as String?,
      bairro: json['aluno']?['bairro'] as String?,
      cidade: json['aluno']?['cidade'] as String?,
      estado: json['aluno']?['estado'] as String?,
      fotoPerfil: json['aluno']?['foto_perfil'] as String?,
      latitude: json['aluno']?['latitude'] != null
          ? double.parse(json['aluno']['latitude'].toString())
          : null,
      longitude: json['aluno']?['longitude'] != null
          ? double.parse(json['aluno']['longitude'].toString())
          : null,
      criadoEm: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'].toString())
          : DateTime.now(),
      atualizadoEm: json['atualizado_em'] != null
          ? DateTime.parse(json['atualizado_em'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_exibicao': nomeExibicao,
      'email': email,
      'aluno': {
        'cpf': cpf,
        'curso': curso,
        'instituicao': instituicao,
        'url_curriculo': urlCurriculo,
        'endereco': endereco,
        'logradouro': logradouro,
        'cep': cep,
        'numero': numero,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'foto_perfil': fotoPerfil,
        'latitude': latitude,
        'longitude': longitude,
      },
    };
  }
}
