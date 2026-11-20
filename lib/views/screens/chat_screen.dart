// lib/views/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../viewModel/chat_viewmodel.dart';
import '../../viewModel/chat_viewmodel.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String receptorId;
  final String receptorNombre;

  const ChatScreen({super.key, required this.receptorId, required this.receptorNombre});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final miUsuarioId = Supabase.instance.client.auth.currentUser!.id;

    final params = (usuarioA: miUsuarioId, usuarioB: widget.receptorId);
    final mensajesAsync = ref.watch(mensajesStreamProvider(params));

    return Scaffold(
      appBar: AppBar(title: Text(widget.receptorNombre)),

      // 1. El cuerpo solo contiene la lista de mensajes
      body: mensajesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (mensajes) {
          // Auto-scroll al final cuando llega un mensaje nuevo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: mensajes.length,
            itemBuilder: (context, index) {
              final msg = mensajes[index];
              final esMio = msg['emisor_id'] == miUsuarioId;

              return Align(
                alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: esMio ? Colors.blue : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    msg['contenido'],
                    style: TextStyle(color: esMio ? Colors.white : Colors.black),
                  ),
                ),
              );
            },
          );
        },
      ),

      // 2. EL TRUCO: Usamos bottomNavigationBar para el campo de texto
      // Flutter lo sube automáticamente con el teclado y respeta el SafeArea
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mensajeController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: () async {
                    final texto = _mensajeController.text.trim();
                    if (texto.isNotEmpty) {
                      _mensajeController.clear();
                      await ref.read(chatRepositoryProvider).enviarMensaje(
                        emisorId: miUsuarioId,
                        receptorId: widget.receptorId,
                        contenido: texto,
                      );
                      ref.invalidate(bandejaEntradaProvider);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}