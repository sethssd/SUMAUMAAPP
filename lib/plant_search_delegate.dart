import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'detail_screen.dart';

class PlantSearchDelegate extends SearchDelegate {
  
  @override
  String? get searchFieldLabel => "Buscar por nome ou palavra-chave...";

  @override
  ThemeData appBarTheme(BuildContext context) {
   
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.green, // Cor do seu AppBar
        iconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
   
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; 
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); 
      },
    );
  }

  // MUDANÇA PRINCIPAL AQUI
  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text("Digite algo para buscar."));
    }

    // Prepara a query para buscar em minúsculas
    final String searchQuery = query.toLowerCase().trim();

    return FutureBuilder<QuerySnapshot>(
      
      // Usamos 'array-contains' no campo 'keywords'
      future: FirebaseFirestore.instance
          .collection('plantas')
          .where('keywords', arrayContains: searchQuery)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao buscar. Tente novamente."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Nenhuma planta encontrada para '$query'."));
        }

        final results = snapshot.data!.docs;

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final planta = results[index];
            final data = planta.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(data['nome'] ?? 'Sem nome'),
              subtitle: Text(data['descricaoCurta'] ?? ''),
              onTap: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(plantaId: planta.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
   
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "Digite o nome da planta (ex: Açaí) e pressione 'Buscar'.",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}