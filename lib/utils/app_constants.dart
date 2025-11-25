class AppConstants {
  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionPlants = 'plantas';

  // User Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleEscritor = 'escritor';
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
