import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Precisamos disso para usar o Timer
import '../screens/admin_login_screen.dart'; // A tela de login secreta
import '../screens/manage_plants_screen.dart'; // Tela de gerenciar plantas
import '../screens/manage_admins_screen.dart'; // Tela de gerenciar administradores
import '../screens/suggestions_screen.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  Timer? _adminTimer; // Variável para controlar o timer
  String _userRole =
      'usuario'; // Armazena o papel do usuário (user, escritor, admin, super_admin)

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Carrega o papel do usuário quando o menu abre
  }

  /// Carrega o papel do usuário atual da coleção 'users' no Firestore
  /// Se o usuário não estiver autenticado, mantém 'usuario' como padrão
  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Busca o documento do usuário na coleção 'users'
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc.get('role') as String?;
          if (mounted) {
            setState(() {
              _userRole = role ?? 'usuario';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar papel do usuário: $e');
    }
  }

  /// Realiza o logout do usuário autenticado
  /// Limpa a sessão do Firebase Auth e volta à tela anterior
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pop(context); // Fecha o menu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desconectado com sucesso')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao desconectar: $e')));
      }
    }
  }

  void _onTimerComplete() {
    _adminTimer = null; // Limpa o timer

    // 1. Fecha o menu
    Navigator.pop(context);

    // 2. Abre a tela de login (apenas se a tela ainda existir)
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  // O que acontece quando o usuário CANCELA o gesto (solta o dedo)
  void _cancelTimer() {
    if (_adminTimer != null && _adminTimer!.isActive) {
      _adminTimer!.cancel(); // Cancela o timer
      _adminTimer = null;
    }
  }

  @override
  void dispose() {
    _cancelTimer(); // Garante que o timer seja cancelado se o widget for destruído
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. Usamos um GestureDetector para capturar o gesto
          GestureDetector(
            // 2. Quando o usuário COMEÇA a segurar
            onLongPressStart: (_) {
              // Inicia o timer de 10 segundos
              _adminTimer = Timer(
                const Duration(seconds: 10),
                _onTimerComplete,
              );
            },
            // 3. Quando o usuário SOLTA o dedo
            onLongPressEnd: (_) {
              _cancelTimer(); // Cancela o timer
            },
            // 4. O cabeçalho que o usuário vê (é o "filho" do gesto)
            child: const UserAccountsDrawerHeader(
              accountName: Text(
                "Baderna App",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              accountEmail: Text(
                "Conhecimento Medicinal",
                style: TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  "B",
                  style: TextStyle(fontSize: 40.0, color: Colors.green),
                ),
              ),
              decoration: BoxDecoration(color: Colors.green),
            ),
          ),

          // Menu de Administração (visível apenas para admin/escritor/super_admin)

          // Opção "Gerenciar Plantas" - visível para escritor, admin, e super_admin
          if (_userRole == 'escritor' ||
              _userRole == 'admin' ||
              _userRole == 'super_admin')
            ListTile(
              leading: const Icon(Icons.agriculture),
              title: const Text('Gerenciar Plantas'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManagePlantsScreen(),
                  ),
                );
              },
            ),

          // Opção "Gerenciar Administradores" - visível apenas para super_admin
          if (_userRole == 'super_admin')
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Gerenciar Administradores'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageAdminsScreen(),
                  ),
                );
              },
            ),

          // Divisor - mostrado apenas se há opções de admin visíveis
          if (_userRole == 'escritor' ||
              _userRole == 'admin' ||
              _userRole == 'super_admin')
            const Divider(),

          // Menu Geral
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Sugestões'),
            onTap: () {
              Navigator.pop(context); // Fecha o menu
              // NAVEGA PARA A NOVA TELA
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SuggestionsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('Referências'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre Nós'),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // Opção de Logout (visível apenas para admin/escritor/super_admin)
          if (_userRole == 'escritor' ||
              _userRole == 'admin' ||
              _userRole == 'super_admin')
            const Divider(),
          if (_userRole == 'escritor' ||
              _userRole == 'admin' ||
              _userRole == 'super_admin')
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: _logout,
            ),
        ],
      ),
    );
  }
}
