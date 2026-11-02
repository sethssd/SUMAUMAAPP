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
  /// Status editorial da planta ('publicado', 'em_analise', 'pendente').
  final String status;

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
    this.status = 'publicado',
  });

  // ── Getters automáticos para pílulas (badges) ──────────────────────────────

  bool get isUnderAnalysis {
    final s = status.trim().toLowerCase();
    return s == 'em_analise' ||
        s == 'em analise' ||
        s == 'em análise' ||
        s == 'pendente' ||
        s == 'analise' ||
        s == 'revisao';
  }

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

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  factory PlantModel.fromSnapshot(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return PlantModel.fromMap(data, id: doc.id);
  }

  factory PlantModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final cuidadosRaw = data['cuidados'];
    final cuidadosStr = cuidadosRaw is List
        ? cuidadosRaw.join('<br>')
        : (cuidadosRaw?.toString() ?? '');

    final createdDate = _parseDate(data['dataCriacao'] ?? data['createdAt']);
    final updatedDate = _parseDate(data['updatedAt']);

    String resolvedStatus = (data['status']?.toString().trim() ?? '');
    if (resolvedStatus.isEmpty) {
      if (data['emAnalise'] == true || data['aprovado'] == false) {
        resolvedStatus = 'em_analise';
      } else {
        resolvedStatus = 'publicado';
      }
    }

    return PlantModel(
      id: id ?? data['id']?.toString() ?? '',
      nome: data['nome']?.toString() ?? '',
      nomeCientifico: data['nomeCientifico']?.toString() ?? '',
      descricao: data['descricao']?.toString() ?? '',
      descricaoCurta: data['descricaoCurta']?.toString() ?? '',
      descricaoSimples: data['descricaoSimples']?.toString() ?? '',
      imagemUrl: data['imagemUrl']?.toString() ?? '',
      imagensExtras: _parseList(data['imagensExtras'] ?? data['fotos'] ?? data['imagens']),
      modelo3dUrl: data['modelo3dUrl']?.toString() ?? '',
      audioUrl: data['audioUrl']?.toString() ?? '',
      distribuicaoHabitat: data['distribuicaoHabitat']?.toString() ?? '',
      fenologia: data['fenologia']?.toString() ?? '',
      usosEValorEconomico: data['usosEValorEconomico']?.toString() ?? '',
      taxonomiaNomesPopulares: data['taxonomiaNomesPopulares']?.toString() ?? '',
      descobertasCientificas: (data['descobertasCientificas'] ?? data['descricaoSimples'] ?? '').toString(),
      beneficios: _parseList(data['beneficios']),
      comoUsar: data['comoUsar']?.toString() ?? '',
      cuidados: cuidadosStr,
      farmacologia: data['farmacologia']?.toString() ?? '',
      creatorId: data['creatorId']?.toString() ?? '',
      excluida: data['excluida'] == true,
      keywords: _parseList(data['keywords']),
      composicaoQuimica: data['composicaoQuimica'] is Map
          ? Map<String, dynamic>.from(data['composicaoQuimica'] as Map)
          : null,
      propriedadesFarmacologicas: data['propriedadesFarmacologicas'] is List
          ? List<dynamic>.from(data['propriedadesFarmacologicas'] as List)
          : null,
      tiposEstudo: data['tiposEstudo'] is Map
          ? Map<String, dynamic>.from(data['tiposEstudo'] as Map)
          : null,
      referenciaGeral: _parseList(data['referenciaGeral']),
      referenciasCientificas: data['referenciasCientificas'] is List
          ? List<dynamic>.from(data['referenciasCientificas'] as List)
          : null,
      referenciasFarmacologicas: _parseList(data['referenciasFarmacologicas']),
      categoria: data['categoria']?.toString() ?? '',
      dataCriacao: createdDate ?? updatedDate,
      updatedAt: updatedDate,
      audioDescricaoUrl: data['audioDescricaoUrl']?.toString(),
      resumoInterface: data['resumoInterface']?.toString(),
      cuidadosAvancados: data['cuidadosAvancados'] is List
          ? (data['cuidadosAvancados'] as List)
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList()
          : null,
      locais: data['locais'] is List
          ? (data['locais'] as List)
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList()
          : null,
      aspectosUso: _parseList(data['aspectosUso']),
      isPopular: data['isPopular'] == true,
      status: resolvedStatus,
    );
  }

  /// Converte para Map serializável em JSON para armazenamento Offline local.
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'nome': nome,
      'nomeCientifico': nomeCientifico,
      'descricao': descricao,
      'descricaoCurta': descricaoCurta,
      'descricaoSimples': descricaoSimples,
      'imagemUrl': imagemUrl,
      'imagensExtras': imagensExtras,
      'modelo3dUrl': modelo3dUrl,
      'audioUrl': audioUrl,
      'distribuicaoHabitat': distribuicaoHabitat,
      'fenologia': fenologia,
      'usosEValorEconomico': usosEValorEconomico,
      'taxonomiaNomesPopulares': taxonomiaNomesPopulares,
      'descobertasCientificas': descobertasCientificas,
      'beneficios': beneficios,
      'comoUsar': comoUsar,
      'cuidados': cuidados,
      'farmacologia': farmacologia,
      'creatorId': creatorId,
      'excluida': excluida,
      'keywords': keywords,
      'composicaoQuimica': composicaoQuimica,
      'propriedadesFarmacologicas': propriedadesFarmacologicas,
      'tiposEstudo': tiposEstudo,
      'referenciaGeral': referenciaGeral,
      'referenciasCientificas': referenciasCientificas,
      'referenciasFarmacologicas': referenciasFarmacologicas,
      'categoria': categoria,
      'dataCriacao': dataCriacao?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'audioDescricaoUrl': audioDescricaoUrl,
      'resumoInterface': resumoInterface,
      'cuidadosAvancados': cuidadosAvancados,
      'locais': locais,
      'aspectosUso': aspectosUso,
      'isPopular': isPopular,
      'status': status,
    };
  }
}
