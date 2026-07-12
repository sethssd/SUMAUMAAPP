import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo tipado que mapeia os campos de um documento Firestore da coleção 'plantas'.
/// Utilizar este modelo em vez de `Map<String, dynamic>` elimina typos silenciosos
/// nos nomes de campos e facilita refatorações futuras.
class PlantModel {
  final String id;
  final String nome;
  final String nomeCientifico;
  final String descricao;
  final String descricaoCurta;
  final String descricaoSimples;
  final String imagemUrl;
  final List<String> imagensExtras;
  final String modelo3dUrl;
  final String audioUrl;
  final String distribuicaoHabitat;
  final String fenologia;
  final String usosEValorEconomico;
  final String taxonomiaNomesPopulares;
  final String descobertasCientificas;
  final List<String> beneficios;
  final String comoUsar;
  final String cuidados;
  final String farmacologia;
  final String creatorId;
  final bool excluida;
  final List<String> keywords;
  final Map<String, dynamic>? composicaoQuimica;
  final List<dynamic>? propriedadesFarmacologicas;
  final Map<String, dynamic>? tiposEstudo;
  final List<String> referenciaGeral;
  final List<dynamic>? referenciasCientificas;
  final List<String> referenciasFarmacologicas;
  /// Categoria da planta (ex: 'Medicinais', 'Frutíferas', 'Aromáticas').
  final String categoria;
  /// Data/hora em que a planta foi cadastrada no Firestore.
  final DateTime? dataCriacao;
  final String? audioDescricaoUrl;
  final List<Map<String, dynamic>>? cuidadosAvancados;
  final List<Map<String, dynamic>>? locais;

  const PlantModel({
    required this.id,
    required this.nome,
    required this.nomeCientifico,
    required this.descricao,
    required this.descricaoCurta,
    required this.descricaoSimples,
    required this.imagemUrl,
    required this.imagensExtras,
    required this.modelo3dUrl,
    required this.audioUrl,
    required this.distribuicaoHabitat,
    required this.fenologia,
    required this.usosEValorEconomico,
    required this.taxonomiaNomesPopulares,
    required this.descobertasCientificas,
    required this.beneficios,
    required this.comoUsar,
    required this.cuidados,
    required this.farmacologia,
    required this.creatorId,
    required this.excluida,
    required this.keywords,
    this.composicaoQuimica,
    this.propriedadesFarmacologicas,
    this.tiposEstudo,
    required this.referenciaGeral,
    this.referenciasCientificas,
    required this.referenciasFarmacologicas,
    required this.categoria,
    this.dataCriacao,
    this.audioDescricaoUrl,
    this.cuidadosAvancados,
    this.locais,
  });

  static List<String> _parseList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  factory PlantModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final cuidadosRaw = data['cuidados'];
    final cuidadosStr = cuidadosRaw is List
        ? cuidadosRaw.join('<br>')
        : (cuidadosRaw?.toString() ?? '');

    return PlantModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      nomeCientifico: data['nomeCientifico'] ?? '',
      descricao: data['descricao'] ?? '',
      descricaoCurta: data['descricaoCurta'] ?? '',
      descricaoSimples: data['descricaoSimples'] ?? '',
      imagemUrl: data['imagemUrl'] ?? '',
      imagensExtras: _parseList(data['imagensExtras'] ?? data['fotos'] ?? data['imagens']),
      modelo3dUrl: data['modelo3dUrl'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
      distribuicaoHabitat: data['distribuicaoHabitat'] ?? '',
      fenologia: data['fenologia'] ?? '',
      usosEValorEconomico: data['usosEValorEconomico'] ?? '',
      taxonomiaNomesPopulares: data['taxonomiaNomesPopulares'] ?? '',
      descobertasCientificas: data['descobertasCientificas'] ?? data['descricaoSimples'] ?? '',
      beneficios: _parseList(data['beneficios']),
      comoUsar: data['comoUsar'] ?? '',
      cuidados: cuidadosStr,
      farmacologia: data['farmacologia'] ?? '',
      creatorId: data['creatorId'] ?? '',
      excluida: data['excluida'] == true,
      keywords: _parseList(data['keywords']),
      composicaoQuimica: data['composicaoQuimica'] as Map<String, dynamic>?,
      propriedadesFarmacologicas: data['propriedadesFarmacologicas'] as List<dynamic>?,
      tiposEstudo: data['tiposEstudo'] as Map<String, dynamic>?,
      referenciaGeral: _parseList(data['referenciaGeral']),
      referenciasCientificas: data['referenciasCientificas'] as List<dynamic>?,
      referenciasFarmacologicas: _parseList(data['referenciasFarmacologicas']),
      categoria: data['categoria'] ?? '',
      dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate(),
      audioDescricaoUrl: data['audioDescricaoUrl'],
      cuidadosAvancados: data['cuidadosAvancados'] != null
          ? List<Map<String, dynamic>>.from(data['cuidadosAvancados'])
          : null,
      locais: data['locais'] != null
          ? List<Map<String, dynamic>>.from(data['locais'])
          : null,
    );
  }
}
