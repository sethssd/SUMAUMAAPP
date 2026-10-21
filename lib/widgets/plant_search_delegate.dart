import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/detail_screen.dart';

class PlantSearchDelegate extends SearchDelegate {
  // Mantemos o cache em memória das plantas para poder filtrar localmente rápido sem onerar o Firestore.
  static Future<List<QueryDocumentSnapshot>>? _cachedPlantsFuture;
  static DateTime? _lastCacheTime;

  PlantSearchDelegate() {
    if (_lastCacheTime != null && DateTime.now().difference(_lastCacheTime!) > const Duration(minutes: 5)) {
      _cachedPlantsFuture = null;
    }

    if (_cachedPlantsFuture == null) {
      _lastCacheTime = DateTime.now();
      _cachedPlantsFuture = FirebaseFirestore.instance
          .collection('plantas')
          .get()
          .then((snap) => snap.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null) return false;
                return data['excluida'] != true;
              }).toList());
    }
  }

  @override
  String? get searchFieldLabel => "Buscar por planta...";

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.primary,
        iconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  String _removeDiacritics(String str) {
    var withDia = 'áàãâäéèêëíìîïóòõôöúùûüçñ';
    var withoutDia = 'aaaaaeeeeiiiiooooouuuucn';
    String result = str.toLowerCase();
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }

  // Verifica se a query está contida no nome, nome_cientifico ou keywords aplicando tolerância a acentos
  bool _matchQuery(Map<String, dynamic> data, String queryStr) {
    final searchParam = _removeDiacritics(queryStr);
    if (searchParam.isEmpty) return true;

    final String nome = _removeDiacritics(data['nome'] ?? '');
    if (nome.contains(searchParam)) return true;

    final String cientifico = _removeDiacritics(data['nomeCientifico'] ?? '');
    if (cientifico.contains(searchParam)) return true;

    final keywords = List<String>.from(data['keywords'] ?? []);
    for (var kw in keywords) {
      if (_removeDiacritics(kw).contains(searchParam)) return true;
    }

    return false;
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

  Widget _buildList(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _cachedPlantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar dados."));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Banco de dados vazio."));
        }

        // Filtra em RAM localmente com base no cache (MUITO rápido, tolera substrings e acentos)
        final results = snapshot.data!.where((doc) {
          return _matchQuery(doc.data() as Map<String, dynamic>, query);
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text("Nenhuma correspondência para '$query'."),
          );
        }

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
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text("Digite algo para buscar."));
    }
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Digite o nome da planta (ex: Açaí) ou palavra chave e pressione 'Buscar'.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Graças ao cache, buildSuggestions processa instantaneamente a busca parcial a cada tecla
    return _buildList(context);
  }
}
