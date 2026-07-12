import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDestaquesScreen extends StatefulWidget {
  const ManageDestaquesScreen({super.key});

  @override
  State<ManageDestaquesScreen> createState() => _ManageDestaquesScreenState();
}

class _ManageDestaquesScreenState extends State<ManageDestaquesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addDestaque() {
    String titulo = '';
    String resumo = '';
    String imagemUrl = '';
    String link = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Destaque'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Título'),
                  onChanged: (v) => titulo = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Resumo (opcional)'),
                  onChanged: (v) => resumo = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'URL da Imagem'),
                  onChanged: (v) => imagemUrl = v,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Link/Referência (opcional)'),
                  onChanged: (v) => link = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titulo.isNotEmpty && imagemUrl.isNotEmpty) {
                  await _firestore.collection('destaques').add({
                    'titulo': titulo,
                    'resumo': resumo,
                    'imagemUrl': imagemUrl,
                    'link': link,
                    'dataCriacao': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Título e Imagem são obrigatórios!')),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Destaques'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('destaques')
            .orderBy('dataCriacao', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum destaque cadastrado.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: data['imagemUrl'] != null && data['imagemUrl'].toString().isNotEmpty
                      ? Image.network(
                          data['imagemUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.star),
                  title: Text(data['titulo'] ?? 'Sem Título'),
                  subtitle: Text(data['resumo'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final conf = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Remover destaque?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remover')),
                          ],
                        ),
                      );
                      if (conf == true) {
                        await _firestore.collection('destaques').doc(doc.id).delete();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDestaque,
        child: const Icon(Icons.add),
      ),
    );
  }
}
