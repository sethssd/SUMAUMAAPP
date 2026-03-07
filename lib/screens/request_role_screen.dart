import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RequestRoleScreen extends StatefulWidget {
  const RequestRoleScreen({super.key});

  @override
  State<RequestRoleScreen> createState() => _RequestRoleScreenState();
}

class _RequestRoleScreenState extends State<RequestRoleScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Cria a solicitação na coleção 'role_requests'
      await FirebaseFirestore.instance
          .collection('role_requests')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'email': user.email ?? '',
            'nome': user.displayName ?? user.email?.split('@').first ?? '',
            'status': 'pendente',
            'dataPedido': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() {
          _statusMessage =
              "Solicitação enviada com sucesso! Aguarde a aprovação do Super Admin.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = "Erro ao enviar solicitação: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Acesso')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note_rounded, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Deseja solicitar acesso como Escritor?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Como Escritor, você poderá criar e editar informações sobre as plantas da Amazônia em nosso banco de dados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusMessage!.contains('sucesso')
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (_statusMessage == null) ...[
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Não'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitRequest,
                        child: const Text('Sim'),
                      ),
                    ),
                  ],
                ),
            ] else
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Voltar'),
              ),
          ],
        ),
      ),
    );
  }
}
