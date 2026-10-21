import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para um documento da coleção `destaques`.
/// Campos esperados no Firestore:
///   titulo (String), resumo (String), imagemUrl (String),
///   link (String), dataPublicacao (Timestamp), ordem (int).
class DestaqueModel {
  final String id;
  final String titulo;
  final String resumo;
  final String imagemUrl;
  final String link;
  final DateTime? dataPublicacao;
  final int ordem;

  const DestaqueModel({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.imagemUrl,
    required this.link,
    this.dataPublicacao,
    required this.ordem,
  });

  factory DestaqueModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final pubTs = (data['dataPublicacao'] ?? data['dataCriacao']) as Timestamp?;
    return DestaqueModel(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      resumo: data['resumo'] ?? '',
      imagemUrl: data['imagemUrl'] ?? '',
      link: data['link'] ?? '',
      dataPublicacao: pubTs?.toDate(),
      ordem: (data['ordem'] as num?)?.toInt() ?? 0,
    );
  }
}
