import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../env.dart';
import '../utils/app_constants.dart';

class CuidadoForm {
  String nivel = 'avisoGeral';
  final TextEditingController descricaoCtrl = TextEditingController();
  final TextEditingController doseCtrl = TextEditingController();
}

class ReviewForm {
  final TextEditingController autorCtrl = TextEditingController();
  final TextEditingController textoCtrl = TextEditingController();
  final TextEditingController notaCtrl = TextEditingController();
}

class LocalForm {
  final TextEditingController nomeCtrl = TextEditingController();
  final TextEditingController enderecoCtrl = TextEditingController();
  final TextEditingController avaliacaoCtrl = TextEditingController();
  final List<ReviewForm> reviews = [];
}

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
  final _audioUrlController = TextEditingController();
  final _taxonomiaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _distribuicaoHabitatController = TextEditingController();
  final _fenologiaController = TextEditingController();
  final _usosValorEconomicoController = TextEditingController();
  final _farmacologiaController = TextEditingController();
  final _referenciasFarmacologicasController = TextEditingController();
  final _referenciaGeralController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _audioDescricaoUrlController = TextEditingController();
  
  final List<CuidadoForm> _cuidadosForm = [];
  final List<LocalForm> _locaisForm = [];
  final Set<String> _selectedAspectos = {};
  bool _isPopular = false;

  static const List<String> _kOpcoesAspectos = [
    'Chá',
    'Suco',
    'Banho',
    'Óleo',
    'Fruto',
    'Semente',
    'Folha',
    'Casca',
    'Raiz',
  ];

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;

  // 2. NOVAS VARIÁVEIS DE ESTADO
  bool _isUploadingImage = false;
  bool _isUploadingModel = false;
  bool _isUploadingAudio = false;
  bool _canUpload = true;

  final cloudinary = CloudinaryPublic(
    Env.cloudinaryCloudName,
    Env.cloudinaryUploadPreset,
    cache: false,
  );
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    if (widget.plantaId != null) {
      _isEditing = true;
      _loadPlantaData();
    }
  }

  Future<void> _checkPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorAndPop('Você precisa estar logado.');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection(AppConstants.collectionUsers).doc(user.uid).get();
      if (!doc.exists) {
        _showErrorAndPop('Usuário não encontrado.');
        return;
      }
      final role = doc.data()?['role'] ?? AppConstants.roleUsuario;
      if (role != AppConstants.roleEscritor && role != AppConstants.roleAdmin && role != AppConstants.roleSuperAdmin) {
        _showErrorAndPop('Acesso negado. Apenas escritores ou administradores podem acessar esta página.');
      }
    } catch (e) {
      _showErrorAndPop('Erro ao verificar permissões: \$e');
    }
  }

  void _showErrorAndPop(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeCientificoController.dispose();
    _descricaoCurtaController.dispose();
    _imagemUrlController.dispose();
    _modelo3dUrlController.dispose();
    _audioUrlController.dispose();
    _taxonomiaController.dispose();
    _descricaoController.dispose();
    _distribuicaoHabitatController.dispose();
    _fenologiaController.dispose();
    _usosValorEconomicoController.dispose();
    _farmacologiaController.dispose();
    _referenciasFarmacologicasController.dispose();
    _referenciaGeralController.dispose();
    _keywordsController.dispose();
    _categoriaController.dispose();
    _audioDescricaoUrlController.dispose();
    for (var c in _cuidadosForm) {
      c.descricaoCtrl.dispose();
      c.doseCtrl.dispose();
    }
    for (var l in _locaisForm) {
      l.nomeCtrl.dispose();
      l.enderecoCtrl.dispose();
      l.avaliacaoCtrl.dispose();
      for (var r in l.reviews) {
        r.autorCtrl.dispose();
        r.textoCtrl.dispose();
        r.notaCtrl.dispose();
      }
    }
    super.dispose();
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
        _audioUrlController.text = data['audioUrl'] ?? '';
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
        _categoriaController.text = data['categoria'] ?? '';
        _audioDescricaoUrlController.text = data['audioDescricaoUrl'] ?? '';
        _isPopular = data['isPopular'] == true;

        _selectedAspectos.clear();
        if (data['aspectosUso'] is List) {
          for (final item in data['aspectosUso']) {
            final str = item.toString().trim();
            if (str.isNotEmpty) _selectedAspectos.add(str);
          }
        }

        if (data['cuidadosAvancados'] != null && (data['cuidadosAvancados'] as List).isNotEmpty) {
          for (var c in data['cuidadosAvancados']) {
            final form = CuidadoForm();
            form.nivel = c['nivel'] ?? 'avisoGeral';
            form.descricaoCtrl.text = c['descricao'] ?? '';
            form.doseCtrl.text = c['doseRecomendada'] ?? '';
            _cuidadosForm.add(form);
          }
        }

        if (data['locais'] != null && (data['locais'] as List).isNotEmpty) {
          for (var l in data['locais']) {
            final form = LocalForm();
            form.nomeCtrl.text = l['nomeLocal'] ?? '';
            form.enderecoCtrl.text = l['endereco'] ?? '';
            form.avaliacaoCtrl.text = (l['avaliacaoMedia'] ?? '').toString();
            if (l['reviews'] != null) {
              for (var r in l['reviews']) {
                final revForm = ReviewForm();
                revForm.autorCtrl.text = r['autor'] ?? '';
                revForm.textoCtrl.text = r['texto'] ?? '';
                revForm.notaCtrl.text = (r['nota'] ?? '').toString();
                form.reviews.add(revForm);
              }
            }
            _locaisForm.add(form);
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados da planta: $e");
    }
    setState(() => _isLoading = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
    );
  }

  bool _validateFileSize(int length) {
    if (length > 10 * 1024 * 1024) {
      _showError("Arquivo muito grande. Máximo 10MB.");
      return false;
    }
    return true;
  }

  bool _checkRateLimit() {
    if (!_canUpload) {
      _showError("Aguarde alguns segundos entre uploads.");
      return false;
    }
    _canUpload = false;
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _canUpload = true);
    });
    return true;
  }

  // 4. FUNÇÃO: UPLOAD DE IMAGEM 2D
  Future<void> _pickAndUploadImage() async {
    if (!_checkRateLimit()) return;
    
    setState(() => _isUploadingImage = true);
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!_validateFileSize(bytes.length)) return;

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: image.name,
          folder: 'sumauma_test',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      if (mounted) {
        setState(() => _imagemUrlController.text = response.secureUrl);
      }
    } catch (e) {
      debugPrint("Erro no upload da imagem: \$e");
      _showError("Erro no upload: \$e");
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // 5. UPLOAD DE MODELO 3D (.GLB)
  Future<void> _pickAndUploadModel() async {
    if (!_checkRateLimit()) return;
    
    setState(() => _isUploadingModel = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // .glb
        withData: true, 
      );

      if (result == null || (result.files.single.bytes == null && result.files.single.path == null)) return;

      final fileBytes = result.files.single.bytes ?? await File(result.files.single.path!).readAsBytes();
      if (!_validateFileSize(fileBytes.length)) return;

      final fileName = result.files.single.name;
      
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          fileBytes,
          identifier: fileName,
          folder: 'sumauma_test',
          resourceType: CloudinaryResourceType.Raw,
        ),
      );

      if (mounted) {
        setState(() => _modelo3dUrlController.text = response.secureUrl);
      }
    } catch (e) {
      debugPrint("Erro no upload do modelo: \$e");
      _showError("Erro no upload do modelo: \$e");
    } finally {
      if (mounted) setState(() => _isUploadingModel = false);
    }
  }

  // 5.5 UPLOAD DE ÁUDIO (.MP3)
  Future<void> _pickAndUploadAudio() async {
    if (!_checkRateLimit()) return;
    
    setState(() => _isUploadingAudio = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: true,
      );

      if (result == null || (result.files.single.bytes == null && result.files.single.path == null)) return;

      final fileBytes = result.files.single.bytes ?? await File(result.files.single.path!).readAsBytes();
      if (!_validateFileSize(fileBytes.length)) return;

      final fileName = result.files.single.name;
      
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          fileBytes,
          identifier: fileName,
          folder: 'sumauma_test',
          resourceType: CloudinaryResourceType.Video,
        ),
      );

      if (mounted) {
        setState(() => _audioUrlController.text = response.secureUrl);
      }
    } catch (e) {
      debugPrint("Erro no upload do áudio: \$e");
      _showError("Erro no upload do áudio: \$e");
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }

  Future<void> _pickAndUploadAudioDesc() async {
    if (!_checkRateLimit()) return;
    
    setState(() => _isUploadingAudio = true); 
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
      
      if (result == null || (result.files.single.bytes == null && result.files.single.path == null)) return;

      final fileBytes = result.files.single.bytes ?? await File(result.files.single.path!).readAsBytes();
      if (!_validateFileSize(fileBytes.length)) return;

      final fileName = result.files.single.name;
      
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          fileBytes,
          identifier: fileName,
          folder: 'sumauma_test',
          resourceType: CloudinaryResourceType.Video,
        ),
      );

      if (mounted) {
        setState(() => _audioDescricaoUrlController.text = response.secureUrl);
      }
    } catch (e) {
      debugPrint("Erro no upload da audiodescrição: \$e");
      _showError("Erro no upload da audiodescrição: \$e");
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
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
      'audioUrl': _audioUrlController.text,
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
      'categoria': _categoriaController.text,
      'audioDescricaoUrl': _audioDescricaoUrlController.text,
      'aspectosUso': _selectedAspectos.toList(),
      'isPopular': _isPopular,
      'updatedAt': FieldValue.serverTimestamp(),
      'cuidadosAvancados': _cuidadosForm.map((c) => {
        'nivel': c.nivel,
        'descricao': c.descricaoCtrl.text.trim(),
        'doseRecomendada': c.doseCtrl.text.trim(),
      }).toList(),
      'locais': _locaisForm.map((l) => {
        'nomeLocal': l.nomeCtrl.text.trim(),
        'endereco': l.enderecoCtrl.text.trim(),
        'avaliacaoMedia': double.tryParse(l.avaliacaoCtrl.text.trim()) ?? 0.0,
        'reviews': l.reviews.map((r) => {
          'autor': r.autorCtrl.text.trim(),
          'texto': r.textoCtrl.text.trim(),
          'nota': double.tryParse(r.notaCtrl.text.trim()) ?? 0.0,
        }).toList(),
      }).toList(),
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('plantas')
            .doc(widget.plantaId!)
            .update(plantaData);
      } else {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          setState(() => _isLoading = false);
          _showError('Você precisa estar logado para criar uma planta.');
          return;
        }
        plantaData['creatorId'] = userId;
        plantaData['dataCriacao'] = FieldValue.serverTimestamp();
        plantaData['excluida'] = false;
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
                      controller: _categoriaController,
                      decoration: const InputDecoration(
                        labelText: 'Categoria (ex: Medicinais)',
                      ),
                    ),
                    TextFormField(
                      controller: _descricaoCurtaController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição Curta (para lista)',
                      ),
                    ),

                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Destacar em "Popular" na Home',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Exibe esta planta no card superior de plantas populares',
                      ),
                      value: _isPopular,
                      onChanged: (val) => setState(() => _isPopular = val),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Principais Aspectos Manuais (Formas de Uso / Partes)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'As pílulas de Áudio, Modelo 3D, Artigos Científicos, Científico, Resumo e Visitação são adicionadas automaticamente quando seus respectivos campos estão preenchidos.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _kOpcoesAspectos.map((aspecto) {
                              final selected = _selectedAspectos.contains(aspecto);
                              return FilterChip(
                                label: Text(aspecto),
                                selected: selected,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedAspectos.add(aspecto);
                                    } else {
                                      _selectedAspectos.remove(aspecto);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

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

                    // CAMPO DE UPLOAD DE ÁUDIO
                    TextFormField(
                      controller: _audioUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL do Áudio do Podcast (.mp3)',
                        // Ícone de Upload
                        suffixIcon: _isUploadingAudio
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.audio_file),
                                onPressed: _pickAndUploadAudio,
                              ),
                      ),
                      readOnly: _isUploadingAudio,
                    ),

                    // CAMPO DE ÁUDIO DESCRIÇÃO
                    TextFormField(
                      controller: _audioDescricaoUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL da Áudiodescrição (.mp3)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.audio_file),
                          onPressed: _pickAndUploadAudioDesc,
                        ),
                      ),
                    ),

                    const Divider(height: 30),
                    _buildCuidadosAvancadosList(),
                    const Divider(height: 30),
                    _buildLocaisList(),
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

  Widget _buildCuidadosAvancadosList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Cuidados Avançados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
              onPressed: () => setState(() => _cuidadosForm.add(CuidadoForm())),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._cuidadosForm.asMap().entries.map((entry) {
          final index = entry.key;
          final form = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cuidado #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _cuidadosForm[index].descricaoCtrl.dispose();
                          _cuidadosForm[index].doseCtrl.dispose();
                          setState(() => _cuidadosForm.removeAt(index));
                        },
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: form.nivel,
                    decoration: const InputDecoration(labelText: 'Nível de Segurança'),
                    items: const [
                      DropdownMenuItem(value: 'avisoGeral', child: Text('Aviso Geral (Azul)')),
                      DropdownMenuItem(value: 'cuidadoSeguro', child: Text('Cuidado Seguro (Verde)')),
                      DropdownMenuItem(value: 'atencao', child: Text('Atenção (Laranja)')),
                      DropdownMenuItem(value: 'cuidadoPerigo', child: Text('Perigo (Vermelho)')),
                    ],
                    onChanged: (v) => setState(() => form.nivel = v ?? 'avisoGeral'),
                  ),
                  TextFormField(
                    controller: form.descricaoCtrl,
                    decoration: const InputDecoration(labelText: 'Descrição do Cuidado'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe a descrição ou remova este item' : null,
                  ),
                  TextFormField(
                    controller: form.doseCtrl,
                    decoration: const InputDecoration(labelText: 'A Dose Certa (Opcional)'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLocaisList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Locais (Onde Encontrar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Local'),
              onPressed: () => setState(() => _locaisForm.add(LocalForm())),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._locaisForm.asMap().entries.map((entry) {
          final index = entry.key;
          final form = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Local #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _locaisForm[index].nomeCtrl.dispose();
                          _locaisForm[index].enderecoCtrl.dispose();
                          _locaisForm[index].avaliacaoCtrl.dispose();
                          for (var r in _locaisForm[index].reviews) {
                            r.autorCtrl.dispose();
                            r.textoCtrl.dispose();
                            r.notaCtrl.dispose();
                          }
                          setState(() => _locaisForm.removeAt(index));
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: form.nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome do Local'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe o nome do local ou remova-o' : null,
                  ),
                  TextFormField(
                    controller: form.enderecoCtrl,
                    decoration: const InputDecoration(labelText: 'Endereço'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Informe o endereço' : null,
                  ),
                  TextFormField(
                    controller: form.avaliacaoCtrl,
                    decoration: const InputDecoration(labelText: 'Avaliação Média (ex: 4.5)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Avaliações (Reviews):', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...form.reviews.asMap().entries.map((revEntry) {
                    final revIndex = revEntry.key;
                    final revForm = revEntry.value;
                    return Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8, left: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Review #${revIndex + 1}', style: const TextStyle(fontSize: 12)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  form.reviews[revIndex].autorCtrl.dispose();
                                  form.reviews[revIndex].textoCtrl.dispose();
                                  form.reviews[revIndex].notaCtrl.dispose();
                                  setState(() => form.reviews.removeAt(revIndex));
                                },
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: revForm.autorCtrl,
                            decoration: const InputDecoration(labelText: 'Autor'),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                          ),
                          TextFormField(
                            controller: revForm.textoCtrl,
                            decoration: const InputDecoration(labelText: 'Texto'),
                            maxLines: 2,
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Obrigatório' : null,
                          ),
                          TextFormField(
                            controller: revForm.notaCtrl,
                            decoration: const InputDecoration(labelText: 'Nota (0 a 5)'),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add_comment, size: 16),
                    label: const Text('Adicionar Avaliação'),
                    onPressed: () => setState(() => form.reviews.add(ReviewForm())),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
