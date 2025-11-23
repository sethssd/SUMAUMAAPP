import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'manage_admins_screen.dart';
import 'manage_plants_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String _userRole = 'carregando...'; // Valor padrão

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  // Função para buscar o "cargo" do usuário no Firestore
  Future<void> _loadUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _userRole = 'erro');
        return;
      }
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _userRole = doc.data()!['role'] ?? 'sem_cargo';
        });
      } else {
        setState(() => _userRole = 'sem_cargo');
      }
    } catch (e) {
      setState(() => _userRole = 'erro');
    }
  }

// ... 
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
              FirebaseAuth.instance.signOut();
              Navigator.pop(context); // Volta para a tela anterior
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seu cargo: $_userRole", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Botões do Painel
            
            // MUDOU AQUI: Agora 'escritor' pode ver este botão
            if (_userRole == 'escritor' || _userRole == 'super_admin')
              ElevatedButton(
                child: const Text("Gerenciar Plantas"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManagePlantsScreen()),
                  );
                },
              ),

            const SizedBox(height: 10),

            // Botão visível APENAS para o super_admin 
            if (_userRole == 'super_admin')
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text("Gerenciar Administradores"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageAdminsScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}