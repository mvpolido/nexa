class StudentProfile {
  final int id;
  final String nomeExibicao;
  final String email;
  final String? cpf;
  final String? curso;
  final String? urlCurriculo;
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
    this.urlCurriculo,
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
      urlCurriculo: json['aluno']?['url_curriculo'] as String?,
      latitude: json['aluno']?['latitude'] != null
          ? double.parse(json['aluno']['latitude'].toString())
          : null,
      longitude: json['aluno']?['longitude'] != null
          ? double.parse(json['aluno']['longitude'].toString())
          : null,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: DateTime.parse(json['atualizado_em'] as String),
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
        'url_curriculo': urlCurriculo,
        'latitude': latitude,
        'longitude': longitude,
      },
    };
  }
}
