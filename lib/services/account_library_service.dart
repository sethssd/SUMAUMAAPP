import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/plant_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

/// Modelo de uma Coleção de plantas do usuário.
class PlantCollectionModel {
  final String id;
  final String nome;
  final List<String> plantIds;
  final DateTime createdAt;
  final bool isDefault;

  const PlantCollectionModel({
    required this.id,
    required this.nome,
    required this.plantIds,
    required this.createdAt,
    this.isDefault = false,
  });

  int get count => plantIds.length;

  factory PlantCollectionModel.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    final rawIds = data['plantIds'];
    final ids = rawIds is List
        ? rawIds.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    DateTime created = DateTime.now();
    final ts = data['createdAt'];
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is int) {
      created = DateTime.fromMillisecondsSinceEpoch(ts);
    }
    final nome = (data['nome']?.toString().trim().isNotEmpty ?? false)
        ? data['nome'].toString().trim()
        : 'Coleção';
    return PlantCollectionModel(
      id: doc.id,
      nome: nome,
      plantIds: ids,
      createdAt: created,
      isDefault: doc.id == 'favoritos' || data['isDefault'] == true || nome.toLowerCase() == 'favoritos',
    );
  }
}

/// Serviço centralizado para Minha Biblioteca (Coleções e Offline),
/// Perfil do Usuário e Idioma na área Minha Conta.
class AccountLibraryService {
  static final AccountLibraryService _instance = AccountLibraryService._internal();
  factory AccountLibraryService() => _instance;
  AccountLibraryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Notificador reativo de plantas salvas Offline (id -> PlantModel).
  final ValueNotifier<Map<String, PlantModel>> offlinePlantsNotifier =
      ValueNotifier<Map<String, PlantModel>>({});

  /// Notificador reativo de IDs de plantas salvas em qualquer coleção do usuário.
  final ValueNotifier<Set<String>> savedPlantIdsNotifier =
      ValueNotifier<Set<String>>({});

  /// Notificador reativo do idioma selecionado no app.
  final ValueNotifier<String> selectedLanguageNotifier =
      ValueNotifier<String>('Português (BR)');

  String? _loadedUid;
  bool _initialized = false;

  static const List<String> availableLanguages = [
    'Português (BR)',
    'Inglês',
    'Yanomami',
    'WaiWai',
    'Apurinã',
  ];

  /// Inicializa o cache local e garante a coleção padrão "Favoritos".
  Future<void> ensureInitialized() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      offlinePlantsNotifier.value = {};
      savedPlantIdsNotifier.value = {};
      _loadedUid = null;
      _initialized = false;
      return;
    }
    if (_initialized && _loadedUid == uid) return;
    _loadedUid = uid;
    _initialized = true;

    await _loadOfflineFromDisk(uid);
    await _ensureDefaultFavoritesCollection(uid);
    await refreshSavedPlantIds();
  }

  // ── OFFLINE STORAGE ────────────────────────────────────────────────────────

  Future<File?> _getOfflineFile(String uid) async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/sumauma_offline_$uid.json');
    } catch (e) {
      debugPrint('Aviso ao acessar diretório local offline: $e');
      return null;
    }
  }

  Future<void> _loadOfflineFromDisk(String uid) async {
    final map = <String, PlantModel>{};
    try {
      final file = await _getOfflineFile(uid);
      if (file != null && await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final plant = PlantModel.fromMap(Map<String, dynamic>.from(item));
              if (plant.id.isNotEmpty) {
                map[plant.id] = plant;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso ao ler plantas offline do disco: $e');
    }

    // Se o disco local estiver vazio, tenta sincronizar os IDs salvos no Firestore do usuário
    if (map.isEmpty) {
      try {
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(uid)
            .get();
        final data = userDoc.data();
        if (data != null) {
          if (data['idioma'] is String && (data['idioma'] as String).isNotEmpty) {
            selectedLanguageNotifier.value = data['idioma'] as String;
          }
          final offlineIds = data['offlinePlantIds'];
          if (offlineIds is List && offlineIds.isNotEmpty) {
            for (final rawId in offlineIds.take(30)) {
              final pid = rawId.toString().trim();
              if (pid.isEmpty) continue;
              final snap = await _firestore.collection(AppConstants.collectionPlants).doc(pid).get();
              if (snap.exists) {
                map[pid] = PlantModel.fromSnapshot(snap);
              }
            }
            if (map.isNotEmpty) {
              await _saveOfflineToDisk(uid, map);
            }
          }
        }
      } catch (_) {}
    }

    offlinePlantsNotifier.value = map;
  }

  Future<void> _saveOfflineToDisk(String uid, Map<String, PlantModel> map) async {
    try {
      final file = await _getOfflineFile(uid);
      if (file != null) {
        final list = map.values.map((p) => p.toJsonMap()).toList();
        await file.writeAsString(jsonEncode(list));
      }
    } catch (e) {
      debugPrint('Aviso ao gravar plantas offline no disco: $e');
    }

    try {
      await _firestore.collection(AppConstants.collectionUsers).doc(uid).set({
        'offlinePlantIds': map.keys.toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  bool isPlantOffline(String plantId) {
    return offlinePlantsNotifier.value.containsKey(plantId);
  }

  PlantModel? getOfflinePlant(String plantId) {
    return offlinePlantsNotifier.value[plantId];
  }

  Future<bool> toggleOfflinePlant(PlantModel plant, {BuildContext? context}) async {
    await ensureInitialized();
    final uid = _auth.currentUser?.uid ?? 'guest';
    final current = Map<String, PlantModel>.from(offlinePlantsNotifier.value);
    final bool nowSaved;

    if (current.containsKey(plant.id)) {
      current.remove(plant.id);
      nowSaved = false;
    } else {
      current[plant.id] = plant;
      nowSaved = true;
      // Pré-carrega a imagem de capa no cache de imagem do Flutter quando possível
      if (context != null && plant.imagemUrl.isNotEmpty && context.mounted) {
        try {
          precacheImage(NetworkImage(plant.imagemUrl), context);
        } catch (_) {}
      }
    }

    offlinePlantsNotifier.value = current;
    await _saveOfflineToDisk(uid, current);
    return nowSaved;
  }

  Future<void> removeOfflinePlant(String plantId) async {
    await ensureInitialized();
    final uid = _auth.currentUser?.uid ?? 'guest';
    final current = Map<String, PlantModel>.from(offlinePlantsNotifier.value);
    current.remove(plantId);
    offlinePlantsNotifier.value = current;
    await _saveOfflineToDisk(uid, current);
  }

  // ── COLEÇÕES (FIRESTORE) ───────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>>? _collectionsRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection(AppConstants.collectionUsers)
        .doc(uid)
        .collection('colecoes');
  }

  Future<void> _ensureDefaultFavoritesCollection(String uid) async {
    try {
      final ref = _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .collection('colecoes')
          .doc('favoritos');
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'nome': 'Favoritos',
          'plantIds': <String>[],
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Aviso ao garantir coleção Favoritos: $e');
    }
  }

  Stream<List<PlantCollectionModel>> watchCollections() {
    final ref = _collectionsRef();
    if (ref == null) return Stream.value(const []);
    return ref.snapshots().map((snap) {
      final list = snap.docs.map(PlantCollectionModel.fromDoc).toList();
      // Atualiza o notificador de plantas salvas
      final allSaved = <String>{};
      for (final c in list) {
        allSaved.addAll(c.plantIds);
      }
      savedPlantIdsNotifier.value = allSaved;
      return list;
    });
  }

  Future<List<PlantCollectionModel>> getCollectionsOnce() async {
    await ensureInitialized();
    final ref = _collectionsRef();
    if (ref == null) return [];
    final snap = await ref.get();
    final list = snap.docs.map(PlantCollectionModel.fromDoc).toList();
    final allSaved = <String>{};
    for (final c in list) {
      allSaved.addAll(c.plantIds);
    }
    savedPlantIdsNotifier.value = allSaved;
    return list;
  }

  Future<void> refreshSavedPlantIds() async {
    try {
      await getCollectionsOnce();
    } catch (_) {}
  }

  Future<PlantCollectionModel?> createCollection(String nome) async {
    final ref = _collectionsRef();
    if (ref == null || nome.trim().isEmpty) return null;
    final clean = nome.trim();
    final docRef = await ref.add({
      'nome': clean,
      'plantIds': <String>[],
      'isDefault': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final snap = await docRef.get();
    return PlantCollectionModel.fromDoc(snap);
  }

  Future<void> renameCollection(String collectionId, String novoNome) async {
    final ref = _collectionsRef();
    if (ref == null || novoNome.trim().isEmpty) return;
    await ref.doc(collectionId).update({'nome': novoNome.trim()});
  }

  Future<void> deleteCollection(String collectionId) async {
    final ref = _collectionsRef();
    if (ref == null) return;
    await ref.doc(collectionId).delete();
    await refreshSavedPlantIds();
  }

  Future<bool> togglePlantInCollection(String collectionId, String plantId) async {
    final ref = _collectionsRef();
    if (ref == null) return false;
    final docRef = ref.doc(collectionId);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'nome': collectionId == 'favoritos' ? 'Favoritos' : 'Coleção',
        'plantIds': [plantId],
        'isDefault': collectionId == 'favoritos',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await refreshSavedPlantIds();
      return true;
    }

    final model = PlantCollectionModel.fromDoc(snap);
    final exists = model.plantIds.contains(plantId);
    if (exists) {
      await docRef.update({
        'plantIds': FieldValue.arrayRemove([plantId]),
      });
    } else {
      await docRef.update({
        'plantIds': FieldValue.arrayUnion([plantId]),
      });
    }
    await refreshSavedPlantIds();
    return !exists;
  }

  // ── IDIOMA E PERFIL ────────────────────────────────────────────────────────

  Future<void> setLanguage(String language) async {
    selectedLanguageNotifier.value = language;
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection(AppConstants.collectionUsers).doc(uid).set({
          'idioma': language,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<void> updateUserProfile({
    required String nome,
    required String instituicao,
    String? fotoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final cleanNome = nome.trim();
    final cleanInst = instituicao.trim();

    if (cleanNome.isNotEmpty) {
      try {
        await user.updateDisplayName(cleanNome);
      } catch (_) {}
    }
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      try {
        await user.updatePhotoURL(fotoUrl);
      } catch (_) {}
    }

    final payload = <String, dynamic>{
      'nome': cleanNome,
      'instituicao': cleanInst,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fotoUrl != null) {
      payload['foto'] = fotoUrl;
    }

    await _firestore
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .set(payload, SetOptions(merge: true));
  }

  // ── MODAL DE SALVAR EM COLEÇÃO (USADO NA FICHA E NOS CARDS) ────────────────

  Future<void> showSavePlantModal(BuildContext context, PlantModel plant) async {
    await ensureInitialized();
    if (!context.mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? SumaColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _SaveToCollectionSheet(plant: plant);
      },
    );
  }
}

class _SaveToCollectionSheet extends StatefulWidget {
  final PlantModel plant;
  const _SaveToCollectionSheet({required this.plant});

  @override
  State<_SaveToCollectionSheet> createState() => _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState extends State<_SaveToCollectionSheet> {
  final _service = AccountLibraryService();
  final _newColController = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _newColController.dispose();
    super.dispose();
  }

  Future<void> _createNewCollection() async {
    final name = _newColController.text.trim();
    if (name.isEmpty) return;
    setState(() => _creating = true);
    try {
      final col = await _service.createCollection(name);
      if (col != null) {
        await _service.togglePlantInCollection(col.id, widget.plant.id);
      }
      _newColController.clear();
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryGreen = SumaColors.greenAccentDark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salvar na Biblioteca',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.plant.nome,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Opção rápida: Salvar Offline
          ValueListenableBuilder<Map<String, PlantModel>>(
            valueListenable: _service.offlinePlantsNotifier,
            builder: (context, offlineMap, _) {
              final isOffline = offlineMap.containsKey(widget.plant.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? SumaColors.darkSurface
                      : const Color(0xFFF3FAF3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isOffline
                        ? primaryGreen
                        : (isDark ? SumaColors.darkDivider : const Color(0xFFD5E6D6)),
                  ),
                ),
                child: ListTile(
                  leading: Image.asset(
                    'assets/icons/conta/download.png',
                    width: 26,
                    height: 26,
                    color: isDark ? SumaColors.greenSage : SumaColors.greenAccentDark,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  title: Text(
                    isOffline ? 'Disponível Offline' : 'Baixar para ler Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    isOffline
                        ? 'Ficha salva no dispositivo para acesso sem internet'
                        : 'Salva os textos e dados da planta no aparelho',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  trailing: Icon(
                    isOffline
                        ? Icons.check_circle_rounded
                        : Icons.download_for_offline_outlined,
                    color: primaryGreen,
                    size: 26,
                  ),
                  onTap: () => _service.toggleOfflinePlant(
                    widget.plant,
                    context: context,
                  ),
                ),
              );
            },
          ),

          Text(
            'MINHAS COLEÇÕES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: StreamBuilder<List<PlantCollectionModel>>(
              stream: _service.watchCollections(),
              builder: (context, snapshot) {
                final cols = snapshot.data ?? [];
                if (cols.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: cols.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final col = cols[index];
                    final contains = col.plantIds.contains(widget.plant.id);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? SumaGradients.darkCard
                              : SumaGradients.searchBar,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'icons/ico-branco.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      title: Text(
                        col.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${col.count} ${col.count == 1 ? 'item' : 'itens'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      trailing: Icon(
                        contains
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: contains
                            ? primaryGreen
                            : (isDark ? Colors.white54 : Colors.grey),
                        size: 26,
                      ),
                      onTap: () => _service.togglePlantInCollection(
                        col.id,
                        widget.plant.id,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newColController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _createNewCollection(),
                  decoration: InputDecoration(
                    hintText: 'Nova coleção (ex: Nutrição, Antibióticos)...',
                    hintStyle: const TextStyle(fontSize: 13.5),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _creating ? null : _createNewCollection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: _creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
