import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import 'manage_admins_screen.dart';
import 'manage_plants_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String _userRole = AppConstants.statusCarregando; // Valor padrão

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  // Função para buscar o "cargo" do usuário usando AuthService
  Future<void> _loadUserRole() async {
    final role = await AuthService().getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel de Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
            onPressed: () {
              AuthService().signOut();
              Navigator.pop(context); // Volta para a tela anterior
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Seu cargo: $_userRole",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Botões do Painel

            // MUDOU AQUI: Agora 'escritor' pode ver este botão
            if (_userRole == AppConstants.roleEscritor ||
                _userRole == AppConstants.roleSuperAdmin)
              ElevatedButton(
                child: const Text("Gerenciar Plantas"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManagePlantsScreen(),
                    ),
                  );
                },
              ),

            const SizedBox(height: 10),

            // Botão visível APENAS para o super_admin
            if (_userRole == AppConstants.roleSuperAdmin)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text("Gerenciar Administradores"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageAdminsScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
