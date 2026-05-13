class Vaga {
  final int id;
  final String titulo;
  final String descricao;
  final String? requisitos;
  final String modalidade;
  final String empresaNome;

  Vaga({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.requisitos,
    required this.modalidade,
    required this.empresaNome,
  });

  // Este método transforma o JSON que vem do Node.js em um objeto Vaga do Dart
  factory Vaga.fromJson(Map<String, dynamic> json) {
    return Vaga(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      requisitos: json['requisitos'],
      modalidade: json['modalidade'],
      // Note que no seu Controller enviamos a relação 'empresa'
      empresaNome: json['empresa'] != null ? json['empresa']['nome_fantasia'] : 'Empresa não identificada',
    );
  }
}