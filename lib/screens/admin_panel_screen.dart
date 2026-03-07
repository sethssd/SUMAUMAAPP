import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'manage_admins_screen.dart';
import 'manage_plants_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String _userRole = AppConstants.statusCarregando;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await AuthService().getUserRole();
    if (mounted) {
      setState(() => _userRole = role);
    }
  }

  Future<void> _openWebForm({String? plantaId}) async {
    const baseUrl = 'https://badernaapk.web.app/formulario';
    final urlStr = plantaId != null ? '$baseUrl?id=$plantaId' : baseUrl;
    final uri = Uri.parse(urlStr);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o navegador.')),
        );
      }
    }
  }

  Future<void> _deletePlant(String id, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mover para Lixeira'),
        content: Text('Deseja realmente remover "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Manter'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection(AppConstants.collectionPlants)
          .doc(id)
          .update({'excluida': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$nome" enviada para a lixeira.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuperAdmin = _userRole == AppConstants.roleSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel de Controle"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
            onPressed: () {
              AuthService().signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWebForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Planta'),
        backgroundColor: SumaColors.greenBright,
        foregroundColor: Colors.white,
      ),
      body: _userRole == AppConstants.statusCarregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── HEADER ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? SumaColors.darkDivider
                          : const Color(0xFFE0EDE4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SumaColors.greenBright.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: SumaColors.greenBright,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Super Administrador',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'Cargo: $_userRole',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── AÇÕES RÁPIDAS ──
                Row(
                  children: [
                    if (_userRole == AppConstants.roleEscritor || isSuperAdmin)
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.eco_rounded,
                          label: 'Gerenciar\nPlantas',
                          color: SumaColors.greenBright,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const ManagePlantsScreen(),
                            ),
                          ),
                        ),
                      ),
                    if (isSuperAdmin) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          icon: Icons.people_rounded,
                          label: 'Gerenciar\nAdmins',
                          color: Colors.redAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const ManageAdminsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── LISTA DE PLANTAS (super admin) ──
                if (isSuperAdmin) ...[
                  const SizedBox(height: 24),
                  Text(
                    'TODAS AS PLANTAS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildAllPlantsList(isDark),
                ],
              ],
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPlantsList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.collectionPlants)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        final plantas = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['excluida'] != true;
        }).toList();

        if (plantas.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Nenhuma planta cadastrada.'),
            ),
          );
        }

        return Column(
          children: plantas.map((planta) {
            final data = planta.data() as Map<String, dynamic>;
            final String nome = data[AppConstants.fieldNome] ?? 'Sem nome';
            final String cientifico =
                data[AppConstants.fieldNomeCientifico] ?? '';
            final String? imagemUrl = data['imagemUrl'];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? SumaColors.darkDivider
                      : const Color(0xFFE0EDE4),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: imagemUrl != null && imagemUrl.isNotEmpty
                        ? Image.network(
                            imagemUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: SumaColors.greenBright.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.eco_rounded,
                                color: SumaColors.greenBright,
                                size: 22,
                              ),
                            ),
                          )
                        : Container(
                            color: SumaColors.greenBright.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(
                              Icons.eco_rounded,
                              color: SumaColors.greenBright,
                              size: 22,
                            ),
                          ),
                  ),
                ),
                title: Text(
                  nome,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                subtitle: cientifico.isNotEmpty
                    ? Text(
                        cientifico,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: SumaColors.greenBright,
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: SumaColors.greenBright,
                        size: 20,
                      ),
                      tooltip: 'Editar planta',
                      onPressed: () => _openWebForm(plantaId: planta.id),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      tooltip: 'Remover planta',
                      onPressed: () => _deletePlant(planta.id, nome),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
