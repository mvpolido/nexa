import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notificacao_model.dart';
import '../services/notificacao_service.dart';

class SininhoNotificacao extends StatefulWidget {
  const SininhoNotificacao({super.key});

  @override
  State<SininhoNotificacao> createState() => _SininhoNotificacaoState();
}

class _SininhoNotificacaoState extends State<SininhoNotificacao> {
  final NotificacaoService _notificacaoService = NotificacaoService();
  List<NotificacaoModel> _notificacoes = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _carregarNotificacoes(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarNotificacoes() async {
    final dados = await _notificacaoService.getNotificacoes();
    if (!mounted) return;
    setState(() {
      _notificacoes = dados;
      _isLoading = false;
    });
  }

  // Função que marca como lida no backend e atualiza a tela
  Future<void> _marcarComoLida(NotificacaoModel notificacao) async {
    if (!notificacao.lida) {
      await _notificacaoService.marcarComoLida(notificacao.id);
      await _carregarNotificacoes();
    }
  }

  // Abre a lista de notificações em um Modal na parte inferior (ou centro) da tela
  void _abrirModalNotificacoes() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Notificações',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _notificacoes.isEmpty
                        ? const Center(child: Text('Nenhuma notificação.'))
                        : ListView.builder(
                            itemCount: _notificacoes.length,
                            itemBuilder: (context, index) {
                              final notif = _notificacoes[index];
                              return ListTile(
                                leading: Icon(
                                  _getIconePorTipo(notif.tipo),
                                  color: notif.lida ? Colors.grey : Colors.blue,
                                ),
                                title: Text(
                                  notif.titulo,
                                  style: TextStyle(
                                    fontWeight: notif.lida ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(notif.mensagem),
                                trailing: notif.lida
                                    ? null
                                    : const Icon(Icons.circle, color: Colors.red, size: 12),
                                onTap: () async {
                                  // 1. Marca como lida no banco para sumir a bolinha vermelha
                                  await _marcarComoLida(notif);
                                  
                                  // 2. Fecha o modal de notificações
                                  if (!context.mounted) return;
                                  Navigator.pop(context);

                                  // 3. Redireciona o usuário (Caminho Seguro)
                                  switch (notif.tipo) {
                                    case 'STATUS_CANDIDATURA':
                                    case 'NOVA_CANDIDATURA':
                                    case 'NOVA_MENSAGEM':
                                      // Redireciona para o painel principal, que vai recarregar
                                      // os dados e mostrar o status atualizado ou o chat novo.
                                      Navigator.pushReplacementNamed(context, '/home'); 
                                      break;
                                      
                                    default:
                                      // Fecha o modal e não faz mais nada
                                      break;
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconePorTipo(String tipo) {
    switch (tipo) {
      case 'STATUS_CANDIDATURA':
        return Icons.work;
      case 'NOVA_MENSAGEM':
        return Icons.message;
      case 'NOVA_CANDIDATURA':
        return Icons.person_add;
      case 'NOVA_VAGA':
        return Icons.business_center;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Conta quantas notificações não foram lidas
    final naoLidas = _notificacoes.where((n) => !n.lida).length;

    return IconButton(
      icon: Badge(
        isLabelVisible: naoLidas > 0, // Só mostra a bolinha vermelha se tiver notificação nova
        label: Text(naoLidas.toString()),
        child: const Icon(Icons.notifications),
      ),
      onPressed: _abrirModalNotificacoes,
    );
  }
}
