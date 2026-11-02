import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../env.dart';
import '../models/plant_model.dart';
import '../services/account_library_service.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import '../utils/theme_controller.dart';
import '../widgets/account/botanical_header.dart';
import 'collection_plants_screen.dart';
import 'collections_screen.dart';
import 'references_screen.dart';
import 'request_role_screen.dart';
import 'suggestions_screen.dart';

/// Tela principal de Minha Conta — fiel a "Menu Conta.pdf" e seus modais
/// ("Notificações Conta.pdf", "Idioma Conta.pdf", "Sobre Nós Conta.pdf", "Sair Conta.pdf").
/// Não inclui "Nova Publicação", "Rascunhos" nem redirecionamentos para o painel Web.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _service = AccountLibraryService();

  String _userName = 'Usuário Sumaúma';
  String _userRole = AppConstants.roleUsuario;
  String _userInstitution = 'UFOPA - Santarém, PA';
  String _userPhotoUrl = '';

  int _myPublicationsCount = 0;
  int _underAnalysisCount = 0;
  List<Map<String, String>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _service.ensureInitialized();
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String nome = user.displayName ?? user.email?.split('@').first ?? 'Usuário Sumaúma';
    String role = AppConstants.roleUsuario;
    String inst = 'UFOPA - Santarém, PA';
    String foto = user.photoURL ?? '';

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final docNome = data['nome']?.toString().trim() ?? '';
        if (docNome.isNotEmpty) nome = docNome;
        final docRole = data['role']?.toString().trim() ?? '';
        if (docRole.isNotEmpty) role = docRole;
        final docInst = data['instituicao']?.toString().trim() ?? '';
        if (docInst.isNotEmpty) inst = docInst;
        final docFoto = data['foto']?.toString().trim() ?? '';
        if (docFoto.isNotEmpty) foto = docFoto;
        final docLang = data['idioma']?.toString().trim() ?? '';
        if (docLang.isNotEmpty) {
          _service.selectedLanguageNotifier.value = docLang;
        }
      }
    } catch (e) {
      debugPrint('Aviso ao carregar perfil: $e');
    }

    int myPubs = 0;
    int inAnalysis = 0;
    final notifs = <Map<String, String>>[];

    try {
      final plantasSnap = await FirebaseFirestore.instance
          .collection(AppConstants.collectionPlants)
          .get();
      for (final doc in plantasSnap.docs) {
        final p = PlantModel.fromSnapshot(doc);
        if (p.excluida) continue;
        if (p.creatorId == user.uid) {
          if (p.isUnderAnalysis) {
            inAnalysis++;
          } else {
            myPubs++;
          }
        } else if (p.isUnderAnalysis) {
          inAnalysis++;
        }
      }
    } catch (_) {}

    try {
      final reqSnap = await FirebaseFirestore.instance
          .collection('role_requests')
          .doc(user.uid)
          .get();
      if (reqSnap.exists) {
        inAnalysis++;
        notifs.add({
          'titulo': 'Sua solicitação para perfil de Pesquisador está em processo de revisão.',
          'autor': 'Equipe SumaúmaBioData',
          'data': _formatTimestamp(reqSnap.data()?['dataPedido']),
        });
      }
    } catch (_) {}

    // Notificações padrão / histórico editorial (fiel a Notificações Conta.pdf)
    if (inAnalysis > 0) {
      notifs.add({
        'titulo': 'Sua publicação está em processo de revisão.',
        'autor': 'Equipe SumaúmaBioData',
        'data': '18/08/2026.',
      });
    }
    if (myPubs > 0 || notifs.isEmpty) {
      if (notifs.isEmpty) {
        notifs.add({
          'titulo': 'Sua publicação está em processo de revisão.',
          'autor': 'Equipe SumaúmaBioData',
          'data': '18/08/2026.',
        });
      }
      notifs.add({
        'titulo': 'Sua publicação foi aprovada e já está disponível na plataforma.',
        'autor': 'Equipe SumaúmaBioData',
        'data': '20/08/2026.',
      });
    }

    if (!mounted) return;
    setState(() {
      _userName = nome;
      _userRole = role;
      _userInstitution = inst;
      _userPhotoUrl = foto;
      _myPublicationsCount = myPubs;
      _underAnalysisCount = inAnalysis;
      _notifications = notifs;
    });
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd/$mm/${d.year}.';
    }
    return 'Recente';
  }

  String _formattedRoleLabel(String role) {
    switch (role) {
      case AppConstants.roleSuperAdmin:
      case AppConstants.roleAdmin:
        return 'Pesquisador • Admin';
      case AppConstants.roleEscritor:
        return 'Pesquisador';
      default:
        return 'Pesquisador / Leitor';
    }
  }

  bool get _isResearcherOrAdmin =>
      _userRole == AppConstants.roleEscritor ||
      _userRole == AppConstants.roleAdmin ||
      _userRole == AppConstants.roleSuperAdmin;

  // ── MODAIS DE CONFIGURAÇÃO E CONTA ─────────────────────────────────────────

  /// Modal de Edição de Perfil (Nome, Instituição/Localização e Foto).
  Future<void> _showEditProfileDialog() async {
    final nameCtrl = TextEditingController(text: _userName);
    final instCtrl = TextEditingController(text: _userInstitution);
    String currentPhoto = _userPhotoUrl;
    bool uploadingPhoto = false;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickAndUploadPhoto() async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  imageQuality: 85,
                );
                if (picked == null) return;
                setModalState(() => uploadingPhoto = true);

                final cloudinary = CloudinaryPublic(
                  Env.cloudinaryCloudName,
                  Env.cloudinaryUploadPreset,
                  cache: false,
                );
                final res = await cloudinary.uploadFile(
                  CloudinaryFile.fromFile(
                    picked.path,
                    resourceType: CloudinaryResourceType.Image,
                  ),
                );
                setModalState(() {
                  currentPhoto = res.secureUrl;
                  uploadingPhoto = false;
                });
              } catch (e) {
                setModalState(() => uploadingPhoto = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Não foi possível enviar a foto: $e')),
                  );
                }
              }
            }

            return Dialog(
              backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Editar Perfil',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: uploadingPhoto ? null : pickAndUploadPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: kAccountGreen,
                              backgroundImage: currentPhoto.isNotEmpty
                                  ? NetworkImage(currentPhoto)
                                  : null,
                              child: uploadingPhoto
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : (currentPhoto.isEmpty
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 48,
                                          color: Colors.white,
                                        )
                                      : null),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: kAccountGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome de exibição',
                        hintText: 'Ex: Dr. Jonh Poul',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Instituição / Localização',
                        hintText: 'Ex: UFOPA - Santarém, PA',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccountGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: (saving || uploadingPhoto)
                            ? null
                            : () async {
                                setModalState(() => saving = true);
                                await _service.updateUserProfile(
                                  nome: nameCtrl.text,
                                  instituicao: instCtrl.text,
                                  fotoUrl: currentPhoto,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadAccountData();
                              },
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Salvar Alterações',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Modal "Notificações" — fiel a "Notificações Conta.pdf".
  void _showNotificationsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 420, maxHeight: 540),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notificações',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF141414),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mais recentes',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF7A7A7A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 28,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E0E0),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E0E0),
                  ),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['titulo'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['autor'] ?? 'Equipe SumaúmaBioData',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white70 : const Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['data'] ?? '',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white60 : const Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modal "Idioma" — fiel a "Idioma Conta.pdf".
  void _showLanguageDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 420, maxHeight: 520),
          child: ValueListenableBuilder<String>(
            valueListenable: _service.selectedLanguageNotifier,
            builder: (context, selectedLang, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Idioma',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF141414),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Disponíveis',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white54 : const Color(0xFF7A7A7A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 28,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E0E0),
                  ),
                  ...AccountLibraryService.availableLanguages.map((lang) {
                    final isCurrent = lang == selectedLang;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            await _service.setLanguage(lang);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 15,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lang,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrent
                                        ? kAccountGreen
                                        : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                                  ),
                                ),
                                if (isCurrent)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: kAccountGreen,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E0E0),
                        ),
                      ],
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Modal "Tema" — seleção limpa de tema no mesmo padrão visual de Idioma.
  void _showThemeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeController,
          builder: (context, currentMode, _) {
            final options = [
              (ThemeMode.light, 'Claro'),
              (ThemeMode.dark, 'Escuro'),
              (ThemeMode.system, 'Padrão do Sistema'),
            ];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tema',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF141414),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Aparência do aplicativo',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : const Color(0xFF7A7A7A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 28,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E0E0),
                ),
                ...options.map((opt) {
                  final selected = opt.$1 == currentMode;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          themeController.value = opt.$1;
                          Navigator.pop(ctx);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 15,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                opt.$2,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? kAccountGreen
                                      : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_rounded,
                                  color: kAccountGreen,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E0E0),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Modal "Sobre nós" — fiel a "Sobre Nós Conta.pdf".
  void _showAboutUsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 590),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sobre nós',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF141414),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Equipe Sumaúma BioData',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white54 : const Color(0xFF7A7A7A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 28,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E0E0),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: Text(
                    'O Sumaúma Biodata nasceu com o propósito de aproximar a ciência dos saberes tradicionais sobre as plantas da Amazônia.\n\n'
                    'Desenvolvido por estudantes e pesquisadores da UFOPA, o projeto busca reunir, organizar e tornar acessíveis informações sobre plantas medicinais, valorizando tanto o conhecimento construído pelas comunidades quanto as pesquisas científicas realizadas na região.\n\n'
                    'Começamos pelo Pará e pela Amazônia, onde essas plantas fazem parte da nossa cultura, biodiversidade e cotidiano. Nosso objetivo é ampliar gradualmente esse conhecimento, alcançando toda a Amazônia e, futuramente, outras regiões do Brasil.\n\n'
                    'Além de consultar informações, qualquer pessoa poderá contribuir com o Biodata enviando informações, fotografias, pesquisas ou outros conhecimentos sobre as plantas. Todo conteúdo enviado passa por análise da nossa equipe antes de ser publicado, buscando garantir a qualidade e a confiabilidade das informações disponíveis na plataforma.\n\n'
                    'O nome Sumaúma representa essa proposta: uma árvore símbolo da Amazônia, conhecida por sua grandeza e por conectar diferentes elementos da floresta. Assim como a sumaúma, queremos criar conexões — entre pessoas, comunidades, conhecimento tradicional e ciência.\n\n'
                    'Sumaúma Biodata — conectando a Amazônia, seus saberes e a ciência.',
                    style: TextStyle(
                      fontSize: 13.8,
                      height: 1.42,
                      color: isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF222222),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modal "Aviso Legal".
  void _showLegalNoticeDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aviso Legal',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF141414),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Termos de Uso e Responsabilidade',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white54 : const Color(0xFF7A7A7A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 28,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E0E0),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: Text(
                    'As informações disponibilizadas no Sumaúma BioData possuem caráter exclusivamente educativo, científico, cultural e informativo sobre a flora amazônica e os saberes tradicionais associados.\n\n'
                    'O conteúdo apresentado não substitui, em nenhuma hipótese, o diagnóstico, a orientação ou o acompanhamento de médicos, farmacêuticos ou outros profissionais de saúde qualificados.\n\n'
                    'Algumas espécies botânicas possuem compostos bioativos potentes, contraindicações para gestantes, lactantes, crianças, idosos ou interações com medicamentos. Nunca realize automedicação e observe sempre os alertas de segurança descritos em cada ficha botânica.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF222222),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modal de confirmação de saída — fiel a "Sair Conta.pdf".
  Future<void> _showLogoutConfirmationDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Círculo rosa/vermelho com ponto de exclamação (fiel a Sair Conta.pdf)
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEA9A9A),
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      fontSize: 40,
                      height: 1.0,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFEA9A9A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tem certeza que deseja sair?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark
                              ? SumaColors.darkSurface
                              : const Color(0xFFF0F0F0),
                          side: BorderSide(
                            color: isDark
                                ? SumaColors.darkDivider
                                : const Color(0xFFD0D0D0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDE3535),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Fazer Logout',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? SumaColors.darkBg : kAccountPageBg,
      body: Column(
        children: [
          // Cabeçalho verde com folhas botânicas, seta de voltar, sino e perfil (fiel a Menu Conta.pdf)
          _buildAccountHeader(isDark),

          // Corpo rolável com as 4 seções e botão Sair da Conta
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                // ── 1. MINHA BIBLIOTECA ──────────────────────────────────────
                _buildSectionHeader('MINHA BIBLIOTECA', isDark),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<PlantCollectionModel>>(
                        stream: _service.watchCollections(),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.length ?? 1;
                          return _LibraryTopCard(
                            iconAsset: 'assets/icons/conta/pasta-de-arquivo.png',
                            title: 'Coleções',
                            subtitle: '$count ${count == 1 ? 'coleção' : 'coleções'}',
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CollectionsScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ValueListenableBuilder<Map<String, PlantModel>>(
                        valueListenable: _service.offlinePlantsNotifier,
                        builder: (context, offlineMap, _) {
                          final count = offlineMap.length;
                          return _LibraryTopCard(
                            iconAsset: 'assets/icons/conta/download.png',
                            title: 'Offline',
                            subtitle: '$count ${count == 1 ? 'baixado' : 'baixados'}',
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CollectionPlantsScreen(
                                  title: 'Offline',
                                  mode: CollectionPlantsMode.offline,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ── 2. ÁREA DO PESQUISADOR (Sem Nova Publicação e sem Rascunhos) ──
                _buildSectionHeader('ÁREA DO PESQUISADOR', isDark),
                const SizedBox(height: 10),
                _buildMenuGroupCard(
                  isDark: isDark,
                  items: [
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/pasta-de-documentos.png',
                      label: _isResearcherOrAdmin || _myPublicationsCount > 0
                          ? 'Minhas Publicações'
                          : 'Minhas Publicações (Solicitar Acesso)',
                      onTap: () async {
                        if (_isResearcherOrAdmin || _myPublicationsCount > 0) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CollectionPlantsScreen(
                                title: 'Minhas Publicações',
                                mode: CollectionPlantsMode.myPublications,
                              ),
                            ),
                          );
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RequestRoleScreen(),
                            ),
                          );
                        }
                        _loadAccountData();
                      },
                    ),
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/relogio.png',
                      label: 'Em Análise',
                      trailingBadgeText: _underAnalysisCount > 0
                          ? '$_underAnalysisCount'
                          : null,
                      trailingBadgeColor: const Color(0xFFF39C38),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CollectionPlantsScreen(
                              title: 'Em Análise',
                              mode: CollectionPlantsMode.underAnalysis,
                            ),
                          ),
                        );
                        _loadAccountData();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ── 3. COMUNIDADE ────────────────────────────────────────────
                _buildSectionHeader('COMUNIDADE', isDark),
                const SizedBox(height: 10),
                _buildMenuGroupCard(
                  isDark: isDark,
                  items: [
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/ideia-criativa.png',
                      label: 'Sugestões',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuggestionsScreen(),
                        ),
                      ),
                    ),
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/auditoria.png',
                      label: 'Referências',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReferencesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ── 4. CONFIGURAÇÕES ─────────────────────────────────────────
                _buildSectionHeader('CONFIGURAÇÕES', isDark),
                const SizedBox(height: 10),
                _buildMenuGroupCard(
                  isDark: isDark,
                  items: [
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/notificacoes.png',
                      label: 'Notificações',
                      onTap: _showNotificationsDialog,
                    ),
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/modo-noturno.png',
                      label: 'Tema',
                      onTap: _showThemeDialog,
                    ),
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/mudar-o-idioma-do-teclado.png',
                      label: 'Idioma',
                      onTap: _showLanguageDialog,
                    ),
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/informacoes.png',
                      label: 'Sobre Nós',
                      onTap: _showAboutUsDialog,
                    ),
                    _AccountMenuItem(
                      iconAsset: 'assets/icons/conta/escala-de-lei.png',
                      label: 'Aviso Legal',
                      onTap: _showLegalNoticeDialog,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ── 5. BOTÃO SAIR DA CONTA + VERSÃO ──────────────────────────
                InkWell(
                  onTap: _showLogoutConfirmationDialog,
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? SumaColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E6E1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/conta/sair.png',
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Sair da Conta',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD93232),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Versão 1.0.0',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountHeader(bool isDark) {
    return BotanicalHeaderContainer(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 22),
      child: Column(
        children: [
          // Topo: Seta de voltar + Ícone de Sino
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                tooltip: 'Voltar',
              ),
              IconButton(
                onPressed: _showNotificationsDialog,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                tooltip: 'Notificações',
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Linha do Perfil: Avatar Circular + Nome, Cargo e Instituição
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: _showEditProfileDialog,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  // Avatar idêntico ao PDF "Menu Conta.pdf" (ou foto do usuário)
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 7),
                    ),
                    child: ClipOval(
                      child: _userPhotoUrl.isNotEmpty
                          ? Image.network(
                              _userPhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultAvatarGraphic(),
                            )
                          : _defaultAvatarGraphic(),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.edit_outlined,
                              color: Colors.white70,
                              size: 17,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formattedRoleLabel(_userRole),
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.white.withValues(alpha: 0.92),
                            fontSize: 17.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _userInstitution,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : Colors.white.withValues(alpha: 0.85),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatarGraphic() {
    return Container(
      color: kAccountGreen,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 13,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -14,
            child: Container(
              width: 58,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: isDark ? Colors.white : const Color(0xFF141414),
        ),
      ),
    );
  }

  Widget _buildMenuGroupCard({
    required bool isDark,
    required List<_AccountMenuItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? SumaColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E6E1),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? SumaColors.darkDivider : const Color(0xFFE4EAE5),
              ),
            items[i],
          ],
        ],
      ),
    );
  }
}

/// Card superior de "Minha Biblioteca" (Coleções / Offline).
class _LibraryTopCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _LibraryTopCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? SumaColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? SumaColors.darkDivider : const Color(0xFFE0E6E1),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 34,
              height: 34,
              color: isDark ? SumaColors.greenSage : SumaColors.greenAccentDark,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de linha dentro dos blocos de seção da Conta.
class _AccountMenuItem extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String? trailingBadgeText;
  final Color? trailingBadgeColor;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.iconAsset,
    required this.label,
    this.trailingBadgeText,
    this.trailingBadgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 24,
              height: 24,
              color: isDark ? SumaColors.greenSage : SumaColors.greenAccentDark,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (trailingBadgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trailingBadgeColor ?? const Color(0xFFF39C38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailingBadgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: isDark ? Colors.white54 : const Color(0xFF6E6E6E),
              ),
          ],
        ),
      ),
    );
  }
}
