import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  final String token;
  const ChatListPage({super.key, required this.token});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<dynamic> chats = [];
  List<dynamic> chatsFiltrados = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarChats();
    searchController.addListener(_filtrarChats);
  }

  void _filtrarChats() {
    final query = searchController.text.toLowerCase();
    setState(() {
      chatsFiltrados = chats.where((chat) {
        final nome = (chat['nome_contato'] ?? '').toString().toLowerCase();
        final vaga = (chat['vaga_titulo'] ?? '').toString().toLowerCase();
        return nome.contains(query) || vaga.contains(query);
      }).toList();
    });
  }

  Future<void> carregarChats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chats'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          chats = data;
          chatsFiltrados = data;
          isLoading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  String _formatarData(String? dataIso) {
    if (dataIso == null) return '';
    final data = DateTime.parse(dataIso).toLocal();
    final hoje = DateTime.now();
    final diferenca = hoje.difference(data).inDays;

    if (diferenca == 0 && hoje.day == data.day) {
      return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
    } else if (diferenca == 1 || (diferenca == 0 && hoje.day != data.day)) {
      return 'Ontem';
    } else {
      final diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
      if (diferenca < 7) {
        return diasSemana[data.weekday - 1];
      }
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Conversas',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Inter'),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 🛠️ BARRA DE PESQUISA ESTILO PROTÓTIPO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar conversas...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          
          // 🛠️ LISTAGEM DE CHATS
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                : chatsFiltrados.isEmpty
                    ? const Center(child: Text('Nenhuma conversa ativa no momento.', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: chatsFiltrados.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 70),
                        itemBuilder: (context, index) {
                          final chat = chatsFiltrados[index];
                          final hasUnread = chat['nao_lidas'] != null && chat['nao_lidas'] > 0;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
                                  child: Text(
                                    (chat['nome_contato'] ?? 'C')[0].toUpperCase(),
                                    style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981), // Verde "Online"
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    chat['nome_contato'] ?? 'Contato',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatarData(chat['data_ultima_mensagem']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasUnread ? const Color(0xFF7C3AED) : Colors.grey.shade500,
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      chat['ultima_mensagem'] ?? 'Inicie a conversa!',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (hasUnread)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF7C3AED),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        chat['nao_lidas'].toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ChatPage(
                                candidaturaId: chat['candidatura_id'],
                                vagaTitulo: chat['vaga_titulo'],
                                token: widget.token,
                                meuUsuarioId: chat['usuario_id'],
                              ),
                            )).then((_) => carregarChats()), // Recarrega a lista ao voltar do chat
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}