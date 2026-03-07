const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError }  = require('firebase-functions/v2/https');
const { auth }                = require('firebase-functions/v2');
const admin                   = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────────────────────
// 1. TRIGGER: toda vez que um usuário é criado no Firebase Auth,
//    cria automaticamente um documento em /users/{uid} com role 'usuario'.
//    Isso garante que qualquer conta nova apareça na tela de Gerenciar Admins.
// ─────────────────────────────────────────────────────────────────────────────
exports.onUserCreated = auth.user().onCreate(async (user) => {
  const { uid, email, displayName } = user;
  const docRef = db.collection('users').doc(uid);

  // Não sobrescreve se já existir (ex.: criado pela tela de Acesso Restrito)
  const existing = await docRef.get();
  if (existing.exists) return null;

  return docRef.set({
    uid,
    email:     email ?? '',
    nome:      displayName ?? email?.split('@')[0] ?? '',
    role:      'usuario',
    criadoEm:  admin.firestore.FieldValue.serverTimestamp(),
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. CALLABLE: migracao única para sincronizar TODOS os usuários
//    existentes no Firebase Auth para a coleção /users do Firestore.
//    Só pode ser chamada por super_admin.
// ─────────────────────────────────────────────────────────────────────────────
exports.syncAllAuthUsers = onCall({ enforceAppCheck: false }, async (request) => {
  // Verifica se quem chamou é super_admin
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError('unauthenticated', 'Não autenticado.');

  const callerDoc = await db.collection('users').doc(callerUid).get();
  if (!callerDoc.exists || callerDoc.data()?.role !== 'super_admin') {
    throw new HttpsError('permission-denied', 'Apenas super_admin pode sincronizar.');
  }

  // Lista todos os usuários do Auth (paginando de 1000 em 1000)
  let synced   = 0;
  let skipped  = 0;
  let nextPage = undefined;

  do {
    const result = await admin.auth().listUsers(1000, nextPage);
    const batch  = db.batch();

    for (const user of result.users) {
      const docRef   = db.collection('users').doc(user.uid);
      const existing = await docRef.get();

      if (!existing.exists) {
        batch.set(docRef, {
          uid:      user.uid,
          email:    user.email ?? '',
          nome:     user.displayName ?? user.email?.split('@')[0] ?? '',
          role:     'usuario',
          criadoEm: admin.firestore.FieldValue.serverTimestamp(),
        });
        synced++;
      } else {
        skipped++;
      }
    }

    await batch.commit();
    nextPage = result.pageToken;
  } while (nextPage);

  return { synced, skipped, total: synced + skipped };
});
