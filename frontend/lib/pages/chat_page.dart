import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class ChatPage extends StatefulWidget {
  final int candidaturaId;
  final String vagaTitulo;
  final String token;
  final int meuUsuarioId;

  const ChatPage({
    super.key,
    required this.candidaturaId,
    required this.vagaTitulo,
    required this.token,
    required this.meuUsuarioId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late IO.Socket _socket;
  final List<Map<String, dynamic>> _mensagens = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _carregandoHistorico = true;

  @override
  void initState() {
    super.initState();
    _carregarHistoricoDoBanco();
    _inicializarConexaoSocket();
  }

  Future<void> _carregarHistoricoDoBanco() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/candidaturas/${widget.candidaturaId}/mensagens'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(response.body);
        setState(() {
          for (var item in dados) {
            _mensagens.add({
              'remetente_id': item['remetente_id'],
              'conteudo': item['conteudo'],
              'enviado_em': item['enviado_em'],
            });
          }
          _carregandoHistorico = false;
        });
        _irParaOFinal();
      }
    } catch (e) {
      setState(() => _carregandoHistorico = false);
    }
  }

  void _inicializarConexaoSocket() {
    _socket = IO.io('http://localhost:3000', IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .build());

    _socket.onConnect((_) {
      _socket.emit('join_chat', {'candidaturaId': widget.candidaturaId});
    });

    _socket.on('receive_message', (data) {
      if (mounted && data['candidatura_id'] == widget.candidaturaId) {
        setState(() {
          _mensagens.add({
            'remetente_id': data['remetente_id'],
            'conteudo': data['conteudo'],
            'enviado_em': data['enviado_em'] ?? DateTime.now().toIso8601String(),
          });
        });
        _irParaOFinal();
      }
    });
  }

  void _enviarMensagem() {
    final texto = _messageController.text.trim();
    if (texto.isEmpty) return;

    _socket.emit('send_message', {
      'candidaturaId': widget.candidaturaId,
      'remetente_id': widget.meuUsuarioId,
      'conteudo': texto,
    });

    _messageController.clear();
  }

  void _irParaOFinal() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), 
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat da Vaga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.vagaTitulo, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: _carregandoHistorico
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _mensagens.length,
                    itemBuilder: (context, index) {
                      final msg = _mensagens[index];
                      final bool souEu = msg['remetente_id'] == widget.meuUsuarioId;

                      return Align(
                        alignment: souEu ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: souEu ? const Color(0xFF7C3AED) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: souEu ? const Radius.circular(16) : const Radius.circular(0),
                              bottomRight: souEu ? const Radius.circular(0) : const Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: Text(
                            msg['conteudo'] ?? '',
                            style: TextStyle(
                              color: souEu ? Colors.white : const Color(0xFF374151),
                              fontSize: 15,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Digite uma mensagem...",
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                        ),
                      ),
                      onSubmitted: (_) => _enviarMensagem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _enviarMensagem,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}