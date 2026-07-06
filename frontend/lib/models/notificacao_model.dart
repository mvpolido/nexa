class NotificacaoModel {
  final int id;
  final String tipo;
  final String titulo;
  final String mensagem;
  final bool lida;
  final int? linkId;
  final DateTime dataCriacao;

  NotificacaoModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    this.linkId,
    required this.dataCriacao,
  });

  // Factory para converter o JSON do backend (Express) em um Objeto Dart
  factory NotificacaoModel.fromJson(Map<String, dynamic> json) {
    return NotificacaoModel(
      id: json['id'],
      tipo: json['tipo'] ?? 'GERAL',
      titulo: json['titulo'] ?? 'Sem título',
      mensagem: json['mensagem'] ?? '',
      lida: json['lida'] ?? false,
      linkId: json['link_id'], // Pode ser nulo, por isso não tem fallback padrão
      dataCriacao: json['data_criacao'] != null
          ? DateTime.parse(json['data_criacao'])
          : DateTime.now(),
    );
  }
}