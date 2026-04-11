class AppConstants {
  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionPlants = 'plantas';

  // URLs externas
  static const String webFormBaseUrl = 'https://badernaapk.web.app/formulario';

  // IDs de sistema
  static const String audioChannelId = 'br.edu.ufopa.baderna.channel.audio';

  // User Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleEscritor = 'escritor';
  static const String roleUsuario = 'usuario';
  static const String roleSemCargo = 'sem_cargo';

  // Fields
  static const String fieldRole = 'role';
  static const String fieldCreatorId = 'creatorId';
  static const String fieldNome = 'nome';
  static const String fieldNomeCientifico = 'nomeCientifico';

  // UI Strings / Status
  static const String statusCarregando = 'carregando...';
  static const String statusErro = 'erro';
}
