import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Cria um novo usuário com cargo 'escritor'
  // Este fluxo cria primeiro a conta no FirebaseAuth e, se bem sucedido,
  // escreve um documento na coleção 'users' com o campo 'role'.
  void _showCreateWriterDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false; // controle local dentro do diálogo

    // showDialog + StatefulBuilder permite atualizar o estado do diálogo
    // (por exemplo, mostrar spinner enquanto a operação assíncrona ocorre).
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Criar Novo Escritor"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campo de e-mail com validação simples
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "E-mail"),
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                          ? 'E-mail inválido'
                          : null,
                    ),
                    // Campo de senha com validação mínima (6 caracteres)
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: "Senha"),
                      obscureText: true,
                      validator: (value) => (value == null || value.length < 6)
                          ? 'Senha muito curta (mín. 6)'
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  // Quando pressionado, valida e cria o usuário
                  onPressed: isLoading
                      ? null
                      : () {
                          if (!formKey.currentState!.validate()) return;

                          // Captura referências de Navigator e ScaffoldMessenger ANTES de qualquer await
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          setDialogState(() => isLoading = true);

                          // Executa a lógica assíncrona em um future separado para evitar usar
                          // o BuildContext após um 'await' (evita warnings do analyzer).
                          Future(() async {
                            try {
                              // 1) Cria o usuário no Firebase Authentication
                              UserCredential userCredential = await FirebaseAuth
                                  .instance
                                  .createUserWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );

                              // 2) Se a criação de Auth funcionou, salva o documento no Firestore
                              if (userCredential.user != null) {
                                await usersCollection
                                    .doc(userCredential.user!.uid)
                                    .set({
                                      'email': emailController.text.trim(),
                                      'role':
                                          'escritor', // define o cargo como 'escritor'
                                    });
                              }

                              // Fecha o diálogo e informa sucesso (Lista é atualizada automaticamente pelo StreamBuilder)
                              navigator.pop();
                            } on FirebaseAuthException catch (e) {
                              // Em caso de erro (ex.: e-mail já em uso), mostra SnackBar explicando o problema
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Erro: ${e.message}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              // Sempre reativa o botão do diálogo
                              setDialogState(() => isLoading = false);
                            }
                          }).ignore();
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Criar"),
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
      appBar: AppBar(title: const Text("Gerenciar Admins")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateWriterDialog,
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
