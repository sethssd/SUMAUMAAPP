import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io'; // Para usar o tipo File

class EditPlantScreen extends StatefulWidget {
  final String? plantaId;
  const EditPlantScreen({super.key, this.plantaId});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _nomeController = TextEditingController();
  final _nomeCientificoController = TextEditingController();
  final _descricaoCurtaController = TextEditingController();
  final _imagemUrlController = TextEditingController();
  final _modelo3dUrlController = TextEditingController();
  final _taxonomiaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _distribuicaoHabitatController = TextEditingController();
  final _fenologiaController = TextEditingController();
  final _usosValorEconomicoController = TextEditingController();
  final _farmacologiaController = TextEditingController();
  final _referenciasFarmacologicasController = TextEditingController();
  final _referenciaGeralController = TextEditingController();
  final _keywordsController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;

  // 2. NOVAS VARIÁVEIS DE ESTADO
  bool _isUploadingImage = false;
  bool _isUploadingModel = false;

  // 3. INICIALIZAR O CLOUDINARY
  final cloudinary = CloudinaryPublic(
    '***REMOVED***',
    '***REMOVED***',
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    if (widget.plantaId != null) {
      _isEditing = true;
      _loadPlantaData();
    }
  }

  String _parseListFieldToString(dynamic data) {
    if (data is List) {
      return data.map((item) => item.toString()).toList().join(', ');
    }
    if (data is String) {
      return data;
    }
    return "";
  }

  Future<void> _loadPlantaData() async {
    setState(() => _isLoading = true);
    try {
      final plantaData = await FirebaseFirestore.instance
          .collection('plantas')
          .doc(widget.plantaId!)
          .get();

      if (plantaData.exists) {
        final data = plantaData.data() as Map<String, dynamic>;

        _nomeController.text = data['nome'] ?? '';
        _nomeCientificoController.text = data['nomeCientifico'] ?? '';
        _descricaoCurtaController.text = data['descricaoCurta'] ?? '';
        _imagemUrlController.text = data['imagemUrl'] ?? '';
        _modelo3dUrlController.text = data['modelo3dUrl'] ?? '';
        _taxonomiaController.text = data['taxonomiaNomesPopulares'] ?? '';
        _descricaoController.text =
            data['descricao'] ?? data['descricaoCompleta'] ?? '';
        _distribuicaoHabitatController.text = data['distribuicaoHabitat'] ?? '';
        _fenologiaController.text = data['fenologia'] ?? '';
        _usosValorEconomicoController.text = data['usosEValorEconomico'] ?? '';
        _farmacologiaController.text = data['farmacologia'] ?? '';
        _referenciasFarmacologicasController.text = _parseListFieldToString(
          data['referenciasFarmacologicas'],
        );
        _referenciaGeralController.text = _parseListFieldToString(
          data['referenciaGeral'],
        );
        _keywordsController.text = _parseListFieldToString(data['keywords']);
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados da planta: $e");
    }
    setState(() => _isLoading = false);
  }

  // 4. FUNÇÃO: UPLOAD DE IMAGEM 2D
  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Preenche o campo de texto com a nova URL
      setState(() {
        _imagemUrlController.text = response.secureUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      debugPrint("Erro no upload da imagem: $e");
    }
  }

  // 5. UPLOAD DE MODELO 3D (.GLB)
  Future<void> _pickAndUploadModel() async {
    setState(() => _isUploadingModel = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Ou limite para .glb se souber a extensão
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isUploadingModel = false);
        return;
      }

      File file = File(result.files.single.path!);

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Raw, // .glb é um arquivo "Raw"
        ),
      );

      setState(() {
        _modelo3dUrlController.text = response.secureUrl;
        _isUploadingModel = false;
      });
    } catch (e) {
      setState(() => _isUploadingModel = false);
      debugPrint("Erro no upload do modelo: $e");
    }
  }

  // 6.  _savePlanta
  Future<void> _savePlanta() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    List<String> keywords = _keywordsController.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    if (_nomeController.text.isNotEmpty &&
        !keywords.contains(_nomeController.text.toLowerCase())) {
      keywords.add(_nomeController.text.toLowerCase());
    }

    final Map<String, dynamic> plantaData = {
      'nome': _nomeController.text,
      'nomeCientifico': _nomeCientificoController.text,
      'descricaoCurta': _descricaoCurtaController.text,
      'imagemUrl': _imagemUrlController.text,
      'modelo3dUrl': _modelo3dUrlController.text,
      'taxonomiaNomesPopulares': _taxonomiaController.text,
      'descricao': _descricaoController.text,
      'distribuicaoHabitat': _distribuicaoHabitatController.text,
      'fenologia': _fenologiaController.text,
      'usosEValorEconomico': _usosValorEconomicoController.text,
      'farmacologia': _farmacologiaController.text,
      'referenciasFarmacologicas': _referenciasFarmacologicasController.text
          .split(',')
          .map((e) => e.trim())
          .toList(),
      'referenciaGeral': _referenciaGeralController.text
          .split(',')
          .map((e) => e.trim())
          .toList(),
      'keywords': keywords,
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('plantas')
            .doc(widget.plantaId!)
            .update(plantaData);
      } else {
        plantaData['creatorId'] = FirebaseAuth.instance.currentUser?.uid;
        await FirebaseFirestore.instance.collection('plantas').add(plantaData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planta salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 7. ATUALIZAÇÃO GRANDE: build()
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Planta' : 'Adicionar Planta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePlanta,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    TextFormField(
                      controller: _keywordsController,
                      decoration: const InputDecoration(
                        labelText: 'Palavras-chave (açaí, boldo, etc.)',
                        helperText: 'Separar por vírgula',
                      ),
                      maxLines: 2,
                    ),
                    TextFormField(
                      controller: _nomeCientificoController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Científico',
                      ),
                    ),
                    TextFormField(
                      controller: _descricaoCurtaController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição Curta (para lista)',
                      ),
                    ),

                    // CAMPO DE UPLOAD DE IMAGEM 2D
                    TextFormField(
                      controller: _imagemUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL da Imagem 2D',
                        // Ícone de Upload
                        suffixIcon: _isUploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.upload_file),
                                onPressed: _pickAndUploadImage,
                              ),
                      ),
                      readOnly:
                          _isUploadingImage, // Trava o campo durante o upload
                    ),

                    // CAMPO DE UPLOAD DE MODELO 3D
                    TextFormField(
                      controller: _modelo3dUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL do Modelo 3D (.glb)',
                        // Ícone de Upload
                        suffixIcon: _isUploadingModel
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.upload_file),
                                onPressed: _pickAndUploadModel,
                              ),
                      ),
                      readOnly: _isUploadingModel,
                    ),
                    const Divider(height: 30),

                    // ... (resto dos campos de texto)
                    TextFormField(
                      controller: _taxonomiaController,
                      decoration: const InputDecoration(
                        labelText: 'Taxonomia e nomes populares',
                      ),
                      maxLines: 3,
                    ),
                    // ... (etc.)
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      maxLines: 5,
                    ),
                    TextFormField(
                      controller: _distribuicaoHabitatController,
                      decoration: const InputDecoration(
                        labelText: 'Distribuição e habitat',
                      ),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _fenologiaController,
                      decoration: const InputDecoration(labelText: 'Fenologia'),
                      maxLines: 2,
                    ),
                    TextFormField(
                      controller: _usosValorEconomicoController,
                      decoration: const InputDecoration(
                        labelText: 'Usos e valor econômico',
                      ),
                      maxLines: 3,
                    ),
                    TextFormField(
                      controller: _farmacologiaController,
                      decoration: const InputDecoration(
                        labelText: 'Farmacologia',
                      ),
                      maxLines: 5,
                    ),
                    TextFormField(
                      controller: _referenciasFarmacologicasController,
                      decoration: const InputDecoration(
                        labelText:
                            'Referências farmacológicas (separadas por vírgula)',
                      ),
                      maxLines: 5,
                    ),
                    TextFormField(
                      controller: _referenciaGeralController,
                      decoration: const InputDecoration(
                        labelText: 'Referência geral (separadas por vírgula)',
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
