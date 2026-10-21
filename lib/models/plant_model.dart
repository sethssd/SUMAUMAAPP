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
  final DateTime? updatedAt;
  final String? audioDescricaoUrl;
  final String? resumoInterface;
  final List<Map<String, dynamic>>? cuidadosAvancados;
  final List<Map<String, dynamic>>? locais;
  /// Tags manuais de formas de uso ou partes da planta (ex: 'Chá', 'Suco', 'Banho', 'Óleo', 'Fruto', 'Semente').
  final List<String> aspectosUso;
  /// Define se a planta deve aparecer em destaque no card "Popular" da Home.
  final bool isPopular;

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
    this.updatedAt,
    this.audioDescricaoUrl,
    this.resumoInterface,
    this.cuidadosAvancados,
    this.locais,
    this.aspectosUso = const [],
    this.isPopular = false,
  });

  // ── Getters automáticos para pílulas (badges) ──────────────────────────────

  bool get hasAudio =>
      audioUrl.trim().isNotEmpty || (audioDescricaoUrl?.trim().isNotEmpty ?? false);

  bool get hasModel3d => modelo3dUrl.trim().isNotEmpty;

  bool get hasArticles =>
      (referenciasCientificas != null && referenciasCientificas!.isNotEmpty) ||
      referenciasFarmacologicas.any((r) => r.trim().isNotEmpty);

  bool get hasCientifico =>
      farmacologia.trim().isNotEmpty ||
      (composicaoQuimica != null && composicaoQuimica!.isNotEmpty) ||
      (propriedadesFarmacologicas != null && propriedadesFarmacologicas!.isNotEmpty) ||
      (tiposEstudo != null && tiposEstudo!.isNotEmpty) ||
      descobertasCientificas.trim().isNotEmpty;

  bool get hasResumo =>
      descricaoCurta.trim().isNotEmpty ||
      (resumoInterface?.trim().isNotEmpty ?? false) ||
      descricaoSimples.trim().isNotEmpty ||
      descricao.trim().isNotEmpty;

  bool get hasVisitacao =>
      locais != null &&
      locais!.any((l) =>
          (l['nomeLocal']?.toString().trim().isNotEmpty ?? false) ||
          (l['endereco']?.toString().trim().isNotEmpty ?? false));

  /// Retorna um texto descritivo limpo (sem tags HTML) para uso nos cards da Home.
  String get resumoLimpo {
    final candidates = [
      descricaoCurta,
      resumoInterface ?? '',
      descobertasCientificas,
      descricaoSimples,
      descricao,
    ];
    for (final raw in candidates) {
      final cleaned = _stripHtml(raw);
      if (cleaned.isNotEmpty) return cleaned;
    }
    return '';
  }

  /// Retorna o endereço ou nome do primeiro local de visitação disponível.
  String get enderecoPrincipal {
    if (locais == null || locais!.isEmpty) return '';
    for (final local in locais!) {
      final nomeLocal = local['nomeLocal']?.toString().trim() ?? '';
      final endereco = local['endereco']?.toString().trim() ?? '';
      if (nomeLocal.isNotEmpty && endereco.isNotEmpty) {
        return '$nomeLocal; $endereco';
      }
      if (endereco.isNotEmpty) return endereco;
      if (nomeLocal.isNotEmpty) return nomeLocal;
    }
    return '';
  }

  static String _stripHtml(String htmlString) {
    if (htmlString.trim().isEmpty) return '';
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&gt;', '>')
        .replaceAll('&lt;', '<')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _parseList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  factory PlantModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final cuidadosRaw = data['cuidados'];
    final cuidadosStr = cuidadosRaw is List
        ? cuidadosRaw.join('<br>')
        : (cuidadosRaw?.toString() ?? '');

    final createdTs = data['dataCriacao'] as Timestamp?;
    final updatedTs = data['updatedAt'] as Timestamp?;

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
      dataCriacao: (createdTs ?? updatedTs)?.toDate(),
      updatedAt: updatedTs?.toDate(),
      audioDescricaoUrl: data['audioDescricaoUrl'],
      resumoInterface: data['resumoInterface'],
      cuidadosAvancados: data['cuidadosAvancados'] != null
          ? List<Map<String, dynamic>>.from(data['cuidadosAvancados'])
          : null,
      locais: data['locais'] != null
          ? List<Map<String, dynamic>>.from(data['locais'])
          : null,
      aspectosUso: _parseList(data['aspectosUso']),
      isPopular: data['isPopular'] == true,
    );
  }
}
