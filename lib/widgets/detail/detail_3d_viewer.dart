import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Tela dedicada ao viewer de modelo 3D com AR.
/// Extraída do detail_screen.dart para separar a responsabilidade de renderização AR.
class Detail3dViewer extends StatelessWidget {
  final String url;
  final String nome;

  const Detail3dViewer({super.key, required this.url, required this.nome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nome)),
      body: ModelViewer(
        src: url,
        ar: true,
        alt: nome,
        cameraControls: true,
        autoRotate: true,
      ),
    );
  }
}
