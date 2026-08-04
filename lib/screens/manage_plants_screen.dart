import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import 'edit_plant_screen.dart';

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
          .update({'excluida': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nome foi movida para a lixeira.'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'RESTAURAR',
              textColor: Colors.white,
              onPressed: () => FirebaseFirestore.instance
                  .collection(AppConstants.collectionPlants)
                  .doc(id)
                  .update({'excluida': false}),
            ),
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

  // Abre o formulário web de planta no navegador do dispositivo. (LEGADO)
  // Mantido caso seja necessário reverter ou usar como fallback.
  // ignore: unused_element
  Future<void> _abrirFormularioWebLegado(
    BuildContext context, {
    required String? plantaId,
  }) async {
    final urlStr = plantaId != null
        ? '${AppConstants.webFormBaseUrl}?id=$plantaId'
        : AppConstants.webFormBaseUrl;
    final uri = Uri.parse(urlStr);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o navegador.')),
        );
      }
    }
  }

  void _navigateToEditScreen(BuildContext context, {String? plantaId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPlantScreen(plantaId: plantaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. PEGAMOS O ID DO USUÁRIO ATUAL LOGADO
    final String? currentUserId = AuthService().getCurrentUserId();

    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Plantas')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar nova planta',
        child: const Icon(Icons.add),
        onPressed: () => _navigateToEditScreen(context, plantaId: null),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Erro ao carregar plantas.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final plantas = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final bool isNotDeleted = data['excluida'] != true;

            // Se for escritor, vê apenas o que criou
            if (_userRole == AppConstants.roleEscritor) {
              return isNotDeleted &&
                  data[AppConstants.fieldCreatorId] == currentUserId;
            }

            // Se for admin ou super_admin, vê tudo que não está excluído
            return isNotDeleted;
          }).toList();

          if (plantas.isEmpty) {
            return const Center(child: Text('Nenhuma planta cadastrada.'));
          }

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
                  tooltip: 'Editar Planta',
                  onPressed: () => _navigateToEditScreen(context, plantaId: planta.id),
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
                        title: const Text('Mover para Lixeira'),
                        content: Text(
                          'Deseja realmente remover "$nome"? Poderá restaurar no painel web.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Manter'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Remover'),
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
