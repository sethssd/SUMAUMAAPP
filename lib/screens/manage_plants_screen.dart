import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import 'edit_plant_screen.dart'; // O formulário de adicionar/editar planta

// Tela para gerenciar plantas. A capacidade de deletar plantas é
// condicionada ao cargo do usuário: 'super_admin' pode apagar tudo,
// 'escritor' pode apagar apenas o que criou.
class ManagePlantsScreen extends StatefulWidget {
  const ManagePlantsScreen({super.key});

  @override
  State<ManagePlantsScreen> createState() => _ManagePlantsScreenState();
}

class _ManagePlantsScreenState extends State<ManagePlantsScreen> {
  // Armazena o cargo do usuário atual (carregado do documento 'users/<uid>')
  String _userRole = AppConstants.statusCarregando;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  // Carrega o cargo do usuário logado a partir do Firestore.
  Future<void> _loadUserRole() async {
    final role = await AuthService().getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  // Função para deletar uma planta.
  Future<void> _deletePlant(String id, String nome) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionPlants)
          .doc(id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nome foi deletada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao deletar $nome: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. PEGAMOS O ID DO USUÁRIO ATUAL LOGADO
    final String? currentUserId = AuthService().getCurrentUserId();

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Plantas')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditPlantScreen()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.collectionPlants)
            .snapshots(),
        builder: (context, snapshot) {
          // ... (código de loading, erro, e lista vazia continua igual) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Erro ao carregar plantas: ${snapshot.error}');
            return Center(
              child: Column(
                // ... (código de erro) ...
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma planta cadastrada.'));
          }

          final plantas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: plantas.length,
            itemBuilder: (context, index) {
              final planta = plantas[index];
              final data = planta.data() as Map<String, dynamic>;
              final String nome =
                  data[AppConstants.fieldNome] ?? 'Planta sem nome';

              // 2. PEGAMOS O ID DO CRIADOR DA PLANTA
              final String? plantCreatorId = data[AppConstants.fieldCreatorId];

              final tile = ListTile(
                title: Text(nome),
                subtitle: Text(data[AppConstants.fieldNomeCientifico] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditPlantScreen(plantaId: planta.id),
                      ),
                    );
                  },
                ),
              );

              // 3. NOVA LÓGICA DE PERMISSÃO
              bool canDelete = false;

              // O Super Admin pode deletar qualquer coisa
              if (_userRole == AppConstants.roleSuperAdmin) {
                canDelete = true;
              }
              // O Escritor só pode deletar se o ID dele for igual ao ID do criador
              else if (_userRole == AppConstants.roleEscritor &&
                  plantCreatorId != null &&
                  plantCreatorId == currentUserId) {
                canDelete = true;
              }

              // Se PUDER DELETAR, mostramos o widget Dismissible
              if (canDelete) {
                return Dismissible(
                  key: Key(planta.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    // Confirma com o usuário antes de apagar
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar'),
                        content: Text('Deseja realmente deletar "$nome"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Deletar'),
                          ),
                        ],
                      ),
                    );
                    return confirm == true;
                  },
                  onDismissed: (direction) => _deletePlant(planta.id, nome),
                  child: tile,
                );
              }

              // Usuários que NÃO PODEM DELETAR veem o tile simples
              return tile;
            },
          );
        },
      ),
    );
  }
}
