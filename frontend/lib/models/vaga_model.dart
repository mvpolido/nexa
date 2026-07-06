class Vaga {
  final int id;
  final String titulo;
  final String descricao;
  final String? requisitos;
  final String modalidade;
  final String empresaNome;
  final bool empresaVerificada;
  final List<String> cursosDestinados;
  final int? anoConclusaoMin;
  final int? anoConclusaoMax;

  Vaga({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.requisitos,
    required this.modalidade,
    required this.empresaNome,
    this.empresaVerificada = false,
    this.cursosDestinados = const [],
    this.anoConclusaoMin,
    this.anoConclusaoMax,
  });

  // Este método transforma o JSON que vem do Node.js em um objeto Vaga do Dart
  factory Vaga.fromJson(Map<String, dynamic> json) {
    final cursosRaw = json['cursos_destinados'] ?? json['cursosDestinados'];
    final cursos = cursosRaw is List
        ? cursosRaw.map((curso) => curso.toString()).toList()
        : <String>[];

    return Vaga(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      requisitos: json['requisitos'],
      modalidade: json['modalidade'],
      // Note que no seu Controller enviamos a relação 'empresa'
      empresaNome: json['empresa'] != null
          ? (json['empresa']['usuario']?['nome_exibicao'] ??
                json['empresa']['nome_fantasia'] ??
                'Empresa não identificada')
          : 'Empresa não identificada',
      empresaVerificada:
          json['empresa']?['verificada'] == true ||
          json['empresa']?['verificada'] == 1,
      cursosDestinados: cursos,
      anoConclusaoMin: _intFromJson(
        json['ano_conclusao_min'] ?? json['anoConclusaoMin'],
      ),
      anoConclusaoMax: _intFromJson(
        json['ano_conclusao_max'] ?? json['anoConclusaoMax'],
      ),
    );
  }

  static int? _intFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
