import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAdminsScreen extends StatefulWidget {
  /// Tela que permite visualizar, criar e alterar cargos de usuários.
  ///
  /// - Lista os usuários armazenados na coleção `users` do Firestore.
  /// - Permite criar novos usuários com o cargo `escritor` (cria Auth + documento no Firestore).
  /// - Permite promover/rebaixar usuários (exceto `super_admin`).
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  // Referência para a coleção 'users' no Firestore.
  // Cada documento deve conter pelo menos: { email: string, role: string }
  final usersCollection = FirebaseFirestore.instance.collection('users');

  // FUNÇÃO: Atualiza o cargo do usuário no Firestore
  // uid: id do documento (normalmente uid do Firebase Auth)
  // newRole: string representando o novo cargo ('user', 'escritor', 'admin', 'super_admin', etc.)
  Future<void> _updateUserRole(String uid, String newRole) async {
    try {
      // Atualiza o campo 'role' do documento
      await usersCollection.doc(uid).update({'role': newRole});

      // Feedback visual: mostra um SnackBar informando que a operação deu certo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuário atualizado para $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Em caso de erro, mostra SnackBar com a mensagem
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Permite escolher o novo cargo para um usuário existente
  // Bloqueamos alterações para 'super_admin' por segurança.
  void _showRoleDialog(String uid, String email, String currentRole) {
    if (currentRole == 'super_admin') {
      // Proteção: não permitimos alterar o super admin
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível alterar o Super Admin')),
      );
      return;
    }

    // Mostra um AlertDialog simples com opções
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Mudar cargo de:"),
          content: Text(email),
          actions: [
            TextButton(
              child: const Text("Rebaixar para 'user'"),
              onPressed: () {
                _updateUserRole(uid, 'user');
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text("Promover para 'escritor'"),
              onPressed: () {
                _updateUserRole(uid, 'escritor');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Rótulos legíveis para cada cargo
  static const _roleLabels = {
    'usuario': 'Usuário (sem acesso admin)',
    'escritor': 'Escritor (editar plantas)',
    'admin': 'Admin (gerenciar usuários)',
    'super_admin': 'Super Admin (acesso total)',
  };

  /// Abre um dialog para atribuir/alterar o cargo de um usuário já cadastrado.
  /// O super admin vê todos os e-mails registrados e escolhe o cargo desejado.
  Future<void> _showAssignRoleDialog() async {
    // 1. Busca todos os usuários do Firestore (snapshot único, não stream)
    final snapshot = await usersCollection.get();
    if (!mounted) return;

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum usuário cadastrado ainda.')),
      );
      return;
    }

    // Monta lista de usuários: { uid, email, role }
    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'email': data['email'] ?? doc.id,
        'role': data['role'] ?? 'usuario',
      };
    }).toList()..sort((a, b) => (a['email']!).compareTo(b['email']!));

    // Estado inicial do dialog
    Map<String, dynamic> selectedUser = users.first;
    String selectedRole = selectedUser['role'] as String;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Atribuir Cargo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Seleção de usuário ─────────────────
                    const Text('Usuário', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedUser['uid'] as String?,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: users.map((u) {
                        return DropdownMenuItem<String>(
                          value: u['uid'],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                u['email']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Atual: ${u['role']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (uid) {
                        final u = users.firstWhere((x) => x['uid'] == uid);
                        setDialogState(() {
                          selectedUser = u;
                          selectedRole = u['role'] as String;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Seleção de cargo ───────────────────
                    const Text('Cargo', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.badge_outlined),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _roleLabels.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedRole = v ?? 'usuario'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Salvar'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _updateUserRole(selectedUser['uid']!, selectedRole);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold com AppBar e FloatingActionButton para criar novos escritores
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Admins')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAssignRoleDialog,
        child: const Icon(Icons.add),
      ),

      // StreamBuilder observa a coleção 'users' em tempo real.
      // - Enquanto carrega: mostra CircularProgressIndicator
      // - Em caso de erro: mostra mensagem e permite retry
      // - Se não houver dados: mostra mensagem apropriada
      body: StreamBuilder<QuerySnapshot>(
        stream: usersCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Log amigável para debugging e opção de 'Tentar novamente'
            debugPrint('Erro ao carregar usuários: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar usuários:\n${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum usuário no Firestore."));
          }

          // Converte os documentos em uma lista para renderizar
          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final String email = data['email'] ?? 'Sem e-mail';
              final String role = data['role'] ?? 'user';

              // Mapeamento de ícones por cargo para dar indicação visual
              final leadingIcon = role == 'super_admin'
                  ? Icons.shield_sharp
                  : (role == 'escritor'
                        ? Icons.edit_note
                        : Icons.person_outline);

              return ListTile(
                title: Text(email),
                subtitle: Text("Cargo: $role"),
                leading: Icon(leadingIcon),
                // Ao tocar, abrimos o diálogo para alterar cargo
                onTap: () => _showRoleDialog(user.id, email, role),
              );
            },
          );
        },
      ),
    );
  }
}
