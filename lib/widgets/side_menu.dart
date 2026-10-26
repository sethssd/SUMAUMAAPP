import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/suggestions_screen.dart';
import '../screens/request_role_screen.dart';
import '../utils/app_constants.dart';
import '../utils/theme_controller.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String _userRole = 'usuario';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  /// Carrega o papel do usuário atual da coleção 'users' no Firestore
  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection(AppConstants.collectionUsers)
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

  Future<void> _openWebPortal() async {
    final uri = Uri.parse(AppConstants.webFormBaseUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o painel web.')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desconectado com sucesso')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao fazer logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao desconectar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = _userRole == AppConstants.roleEscritor ||
        _userRole == AppConstants.roleAdmin ||
        _userRole == AppConstants.roleSuperAdmin;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              'Sumaúma',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: const Text(
              'Enciclopédia Amazônica',
              style: TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Image.asset(
                  isDark ? 'icons/ico-branco.png' : 'icons/ico-verde.png',
                  fit: BoxFit.contain,
                );
              },
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
            ),
          ),

          // Acesso unificado à Central Editorial Web para escritores e administradores
          if (isStaff)
            ListTile(
              leading: const Icon(Icons.open_in_browser_rounded),
              title: const Text('Central Editorial (Web)'),
              subtitle: const Text('Plantas, postagens e administração'),
              onTap: () {
                Navigator.pop(context);
                _openWebPortal();
              },
            ),

          // Opção "Solicitar Acesso" — visível apenas para usuários leitores logados
          if (_userRole == AppConstants.roleUsuario &&
              FirebaseAuth.instance.currentUser != null)
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Pedidos (Ser Escritor)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequestRoleScreen(),
                  ),
                );
              },
            ),

          if (isStaff ||
              (_userRole == AppConstants.roleUsuario &&
                  FirebaseAuth.instance.currentUser != null))
            const Divider(),

          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text('Sugestões'),
            onTap: () {
              Navigator.pop(context);
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

          const Divider(),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeController,
            builder: (context, mode, _) {
              return ListTile(
                leading: Icon(themeIcon(mode)),
                title: Text(themeLabel(mode)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                onTap: cycleTheme,
              );
            },
          ),

          if (FirebaseAuth.instance.currentUser != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: _logout,
            ),
          ],
        ],
      ),
    );
  }
}
