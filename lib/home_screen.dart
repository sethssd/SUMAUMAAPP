import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';
import 'side_menu.dart';
import 'plant_search_delegate.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Baderna"),
        actions: [
          // Ícone de Pesquisa (Foto 1)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 2. CHAMADA A FUNÇÃO DE BUSCA
              showSearch(
                context: context,
                delegate: PlantSearchDelegate(),
              );
            },
          ),
        ],
      ),
      drawer: const SideMenu(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('plantas').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar as plantas."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhuma planta encontrada."));
          }

          final plantas = snapshot.data!.docs;

          return ListView.builder(
            itemCount: plantas.length,
            itemBuilder: (context, index) {
              final planta = plantas[index];
              final data = planta.data() as Map<String, dynamic>;

              final String modelo3dUrl = data['modelo3dUrl'] ?? '';
              final bool hasModel3D = modelo3dUrl.isNotEmpty;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Stack(
                      children: [
                        Image.network(
                          data['imagemUrl'] ?? 'https_via_placeholder.com/100',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                        ),
                        if (hasModel3D)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.threesixty,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  title: Text(data['nome'] ?? 'Nome não encontrado'),
                  subtitle: Text(data['descricaoCurta'] ?? 'Sem descrição'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(plantaId: planta.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}