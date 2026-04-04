// ══════════════════════════════════════════════════════════
//  app.js — Painel Super Admin
//  SUMAÚMA
// ══════════════════════════════════════════════════════════

import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js';
import { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword, updateProfile, onAuthStateChanged, signOut } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js';
import { getFirestore, collection, onSnapshot, doc, setDoc, updateDoc, deleteDoc, getDoc, serverTimestamp, query, orderBy } from 'https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js';

const app = initializeApp(window.CONFIG.FIREBASE);
const auth = getAuth(app);
const db = getFirestore(app);

let allUsers = [];
let allRequests = [];
let allPlants = [];
let editingUid = null;
let editingEmail = null;
let currentRequestId = null;

// ── AUTH ──────────────────────────────────────────────────
onAuthStateChanged(auth, async (user) => {
  document.getElementById('loading').style.display = 'none';
  if (!user) { showLogin(); return; }
  const snap = await getDoc(doc(db, 'users', user.uid));
  if (!snap.exists() || snap.data().role !== 'super_admin') {
    signOut(auth); showLogin('Acesso exclusivo Super Admin.'); return;
  }
  document.getElementById('header-email').textContent = user.email;
  showApp(); subscribeData();
});

function showLogin(err = '') {
  document.getElementById('login-screen').style.display = 'flex';
  document.getElementById('app-screen').style.display = 'none';
  if (err) { const el = document.getElementById('login-error'); el.innerText = err; el.style.display = 'block'; }
}
function showApp() {
  document.getElementById('login-screen').style.display = 'none';
  document.getElementById('app-screen').style.display = 'block';
}

// ── DATA ──────────────────────────────────────────────────
function subscribeData() {
  onSnapshot(collection(db, 'users'), (snap) => {
    allUsers = snap.docs.map(d => ({ uid: d.id, ...d.data() })).sort((a, b) => (a.email || '').localeCompare(b.email || ''));
    renderUsersTable();
  });
  onSnapshot(query(collection(db, 'role_requests'), orderBy('dataPedido', 'desc')), (snap) => {
    allRequests = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    renderRequests();
  });
  onSnapshot(collection(db, 'plantas'), (snap) => {
    allPlants = snap.docs.map(d => ({ id: d.id, ...d.data() })).sort((a, b) => (a.nome || '').localeCompare(b.nome || ''));
    renderPlantsTable();
  });
}

// ── TABS ──────────────────────────────────────────────────
window.switchTab = (id) => {
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.toggle('active', b.getAttribute('onclick').includes(id)));
  document.querySelectorAll('.tab-content').forEach(c => c.classList.toggle('active', c.id === id));
};

// ── USERS TABLE ───────────────────────────────────────────
window.renderUsersTable = () => {
  const q = document.getElementById('search-input').value.toLowerCase();
  const filtered = allUsers.filter(u => (u.email || '').toLowerCase().includes(q) || (u.nome || '').toLowerCase().includes(q));
  const tbody = document.getElementById('users-tbody');
  tbody.innerHTML = '';
  document.getElementById('empty-state-users').style.display = filtered.length ? 'none' : 'block';
  filtered.forEach(u => {
    const role = u.role || 'usuario';
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="email-cell">${u.email || '—'}</td>
      <td class="name-cell">${u.nome || '—'}</td>
      <td><span class="role-badge role-${role}">${rolePt(role)}</span></td>
      <td><button class="btn btn-outline btn-sm" onclick="openRoleModal('${u.uid}','${u.email}','${role}')">✏️ Editar</button></td>
    `;
    tbody.appendChild(tr);
  });
};

// ── PLANTS TABLE ──────────────────────────────────────────
window.renderPlantsTable = () => {
  const q = document.getElementById('search-plants').value.toLowerCase();
  const filtered = allPlants.filter(p => (p.nome || '').toLowerCase().includes(q) || (p.nomeCientifico || '').toLowerCase().includes(q));
  const tbody = document.getElementById('plants-tbody');
  tbody.innerHTML = '';
  document.getElementById('empty-state-plants').style.display = filtered.length ? 'none' : 'block';
  filtered.forEach(p => {
    const isDel = p.excluida === true;
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td class="email-cell">
        <div>${p.nome || '—'}</div>
        <div style="font-size:11px;color:var(--text-dim)">${p.nomeCientifico || ''}</div>
      </td>
      <td><span class="role-badge ${isDel ? 'role-usuario' : 'role-admin'}">${isDel ? '🗑️ Excluída' : '🌿 Ativa'}</span></td>
      <td style="display:flex;gap:6px;align-items:center;">
        <button class="btn btn-green btn-sm" onclick="openPlantForm('${p.id}')">✏️ Editar</button>
        <button class="btn btn-outline btn-sm" onclick="togglePlantStatus('${p.id}', ${!isDel})">
          ${isDel ? '♻️ Restaurar' : '🗑️ Ocultar'}
        </button>
      </td>
    `;
    tbody.appendChild(tr);
  });
};

window.togglePlantStatus = async (id, status) => {
  try {
    await updateDoc(doc(db, 'plantas', id), { excluida: status });
    toast(status ? 'Planta ocultada' : 'Planta restaurada', 'success');
  } catch (e) { toast('Erro: ' + e.message, 'error'); }
};

window.openPlantForm = (plantaId) => {
  const url = plantaId ? `/formulario?id=${plantaId}` : '/formulario';
  window.open(url, '_blank');
};

// ── REQUESTS ──────────────────────────────────────────────
window.renderRequests = () => {
  const container = document.getElementById('requests-list');
  container.innerHTML = '';
  document.getElementById('empty-state-requests').style.display = allRequests.length ? 'none' : 'block';
  allRequests.forEach(r => {
    const div = document.createElement('div');
    div.className = 'req-card';
    div.innerHTML = `
      <div class="req-info">
        <h3>${r.email}</h3>
        <p>Nome: ${r.nome || '—'} | UID: ${r.uid}</p>
        <div class="req-date">Solicitado em: ${r.dataPedido?.toDate().toLocaleString() || '—'}</div>
      </div>
      <button class="btn btn-green btn-sm" onclick="openRoleModal('${r.uid}','${r.email}','usuario','${r.id}')">Dar Cargo</button>
    `;
    container.appendChild(div);
  });
};

// ── ROLE MODAL ────────────────────────────────────────────
function rolePt(r) { return { usuario: 'Usuário', escritor: 'Escritor', admin: 'Admin', super_admin: 'Super Admin' }[r] || r; }

window.openRoleModal = (uid, email, currentRole, requestId = null) => {
  editingUid = uid; currentRequestId = requestId; editingEmail = email;
  document.getElementById('modal-role-email').innerText = email;
  document.getElementById('role-select').value = currentRole;
  document.getElementById('modal-title').innerText = requestId ? '✅ Atribuir Cargo Solicitado' : '🎖️ Alterar Cargo';
  document.getElementById('modal-role').classList.add('open');
};
window.closeRoleModal = () => { document.getElementById('modal-role').classList.remove('open'); editingUid = null; currentRequestId = null; };

window.saveRole = async () => {
  const role = document.getElementById('role-select').value;
  const btn = document.getElementById('btn-save-role');
  btn.disabled = true;
  try {
    const userRef = doc(db, 'users', editingUid);
    const data = {
      role, uid: editingUid, email: editingEmail,
      nome: allUsers.find(u => u.uid === editingUid)?.nome || editingEmail.split('@')[0],
    };
    await setDoc(userRef, data, { merge: true });
    if (currentRequestId) await deleteDoc(doc(db, 'role_requests', currentRequestId));
    toast(`Cargo atualizado para ${rolePt(role)}`, 'success');
    closeRoleModal();
  } catch (e) { toast('Erro: ' + e.message, 'error'); }
  finally { btn.disabled = false; }
};

// ── CREATE USER MODAL ─────────────────────────────────────
window.openCreateModal = () => document.getElementById('modal-create').classList.add('open');
window.closeCreateModal = () => document.getElementById('modal-create').classList.remove('open');

window.doCreateUser = async () => {
  const n = document.getElementById('new-name').value;
  const e = document.getElementById('new-email').value;
  const p = document.getElementById('new-pass').value;
  if (!e || !p) { toast('Campos obrigatórios!', 'error'); return; }
  const btn = document.getElementById('btn-create');
  btn.disabled = true;
  try {
    const cred = await createUserWithEmailAndPassword(auth, e, p);
    if (n) await updateProfile(cred.user, { displayName: n });
    await setDoc(doc(db, 'users', cred.user.uid), { uid: cred.user.uid, email: e, nome: n || e.split('@')[0], role: 'usuario', criadoEm: serverTimestamp() });
    toast('Conta criada com sucesso!', 'success');
    closeCreateModal();
  } catch (err) { toast('Erro: ' + err.code, 'error'); }
  finally { btn.disabled = false; }
};

// ── LOGIN / LOGOUT ────────────────────────────────────────
window.doLogin = async () => {
  const e = document.getElementById('in-email').value;
  const p = document.getElementById('in-pass').value;
  const btn = document.getElementById('btn-login');
  btn.disabled = true;
  try { await signInWithEmailAndPassword(auth, e, p); }
  catch (err) { const el = document.getElementById('login-error'); el.innerText = 'Falha no login: ' + err.code; el.style.display = 'block'; }
  finally { btn.disabled = false; }
};
window.doLogout = () => signOut(auth);

// ── TOAST ─────────────────────────────────────────────────
function toast(m, t = '') {
  const el = document.getElementById('toast');
  el.innerText = m;
  el.className = `show ${t}`;
  setTimeout(() => el.className = '', 3000);
}
