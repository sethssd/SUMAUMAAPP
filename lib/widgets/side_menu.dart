import 'package:flutter/material.dart';
import '../screens/account_screen.dart';

/// Redirecionador legado caso algum widget instancie SideMenu diretamente:
/// exibe o conteúdo da nova área Minha Conta sem links para o portal web.
class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(
      width: 340,
      child: AccountScreen(),
    );
  }
}
