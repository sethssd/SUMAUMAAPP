// ══════════════════════════════════════════════════════════
//  app.js — Central Web Unificada (Plantas, Postagens e Administração)
//  SUMAÚMA
// ══════════════════════════════════════════════════════════

import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.4.0/firebase-app.js';
import {
  getAuth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  updateProfile,
  onAuthStateChanged,
  signOut
} from 'https://www.gstatic.com/firebasejs/11.4.0/firebase-auth.js';
import {
  getFirestore,
  collection,
  onSnapshot,
  doc,
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  getDoc,
  serverTimestamp,
  query,
  orderBy
} from 'https://www.gstatic.com/firebasejs/11.4.0/firebase-firestore.js';

const app = initializeApp(window.CONFIG.FIREBASE);
const auth = getAuth(app);
const db = getFirestore(app);

const CLOUDINARY_CLOUD = window.CONFIG?.CLOUDINARY?.cloudName || 'dkod4l8ni';
const CLOUDINARY_PRESET = window.CONFIG?.CLOUDINARY?.uploadPreset || 'sumauma_upload';

// ── BIBLIOTECA DE ÍCONES SVG (ZERO EMOJIS) ────────────────
const ICONS = {
  leaf: `<svg class="icon-svg" viewBox="0 0 24 24" aria-hidden="true"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/></svg>`,
  edit: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/></svg>`,
  trash: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>`,
  restore: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>`,
  check: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>`,
  close: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>`,
  star: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>`,
  arrowLeft: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><polyline points="15 18 9 12 15 6"/></svg>`,
  arrowRight: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><polyline points="9 18 15 12 9 6"/></svg>`,
  cube: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/></svg>`,
  audio: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M3 18v-6a9 9 0 0 1 18 0v6"/><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z"/></svg>`,
  science: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M10 2v7.31"/><path d="M14 9.3V1.99"/><path d="M8.5 2h7"/><path d="M14 9.3a6.5 6.5 0 1 1-4 0"/></svg>`,
  pin: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>`,
  link: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>`,
  plus: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  sun: `<svg class="icon-svg" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>`,
  moon: `<svg class="icon-svg" viewBox="0 0 24 24" aria-hidden="true"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>`,
  alert: `<svg class="icon-svg sm" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>`
};

// ── ESTADO GLOBAL ─────────────────────────────────────────
let currentUser = null;
let currentUserRole = 'usuario';

let allPlants = [];
let allPosts = [];
let allUsers = [];
let allRequests = [];
let allSuggestions = [];

let editingPlantId = null;
let editingPostId = null;
let editingUid = null;
let editingEmail = null;
let currentRequestId = null;

let unsubPlants = null;
let unsubPosts = null;
let unsubUsers = null;
let unsubRequests = null;
let unsubSuggestions = null;

// Estado do Formulário de Planta
const OPCOES_ASPECTOS = [
  'Chá', 'Suco', 'Banho', 'Artesanato', 'Óleo',
  'Raiz', 'Caule', 'Semente', 'Fruto', 'Flor', 'Folha', 'Casca'
];
let selectedAspectos = new Set();
let keywordsChips = [];
let beneficiosList = [];
let imagensExtras = [];
let cuidadosAvancadosList = [];
let locaisVisitacaoList = [];

// ── TEMA CLARO / ESCURO ACESSÍVEL ─────────────────────────
function initTheme() {
  const saved = localStorage.getItem('sumauma_web_theme') || 'light';
  applyTheme(saved);
}

function applyTheme(theme) {
  if (theme === 'dark') {
    document.documentElement.setAttribute('data-theme', 'dark');
  } else {
    document.documentElement.removeAttribute('data-theme');
  }
  const btn = document.getElementById('btn-theme-toggle');
  if (btn) {
    btn.innerHTML = theme === 'dark' ? ICONS.sun : ICONS.moon;
  }
}

window.toggleTheme = () => {
  const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  const next = isDark ? 'light' : 'dark';
  localStorage.setItem('sumauma_web_theme', next);
  applyTheme(next);
};

initTheme();

// ── CONFIGURAÇÃO DO EDITOR RICO QUILL ─────────────────────
const QUILL_TOOLBAR = [
  ['bold', 'italic', 'underline'],
  [{ size: ['small', false, 'large', 'huge'] }],
  [{ align: [] }],
  [{ list: 'ordered' }, { list: 'bullet' }],
  ['clean']
];

const QUILL_FIELDS = [
  'descobertasCientificas',
  'descricao',
  'taxonomia',
  'distribuicaoHabitat',
  'fenologia',
  'usosEValorEconomico',
  'farmacologia',
  'comoUsar',
  'cuidados'
];

const quillEditors = {};
let quillInitialized = false;

function initQuillEditors() {
  if (quillInitialized || !window.Quill) return;
  quillInitialized = true;
  try {
    const AlignStyle = window.Quill.import('attributors/style/align');
    const SizeStyle = window.Quill.import('attributors/style/size');
    window.Quill.register(AlignStyle, true);
    window.Quill.register(SizeStyle, true);

    const placeholders = {
      descobertasCientificas: 'Resumo científico com citações para o card "O que a ciência descobriu?"...',
      descricao: 'Morfologia, porte da árvore ou erva, folhas, flores e características gerais...',
      taxonomia: 'Reino, Família, Gênero, espécie e nomes populares na região...',
      distribuicaoHabitat: 'Biomas, tipos de solo, várzea ou terra firme, ocorrência geográfica...',
      fenologia: 'Meses de floração e frutificação...',
      usosEValorEconomico: 'Uso alimentar, artesanal, madeireiro, cosmético e importância na feira...',
      farmacologia: 'Compostos bioativos identificados, mecanismos de ação e estudos farmacológicos...',
      comoUsar: 'Modo de preparo tradicional de chás, infusões, decocções, banhos ou compressas...',
      cuidados: 'Contraindicações gerais, interações medicamentosas, gestantes e efeitos adversos...'
    };

    QUILL_FIELDS.forEach((field) => {
      const el = document.getElementById('editor-' + field);
      if (el) {
        quillEditors[field] = new window.Quill(el, {
          theme: 'snow',
          modules: { toolbar: QUILL_TOOLBAR },
          placeholder: placeholders[field] || 'Digite o conteúdo aqui...'
        });
        quillEditors[field].on('text-change', () => updateProgress());
      }
    });
  } catch (err) {
    console.error('Erro ao inicializar editores Quill:', err);
  }
}

function getQuillHtml(field) {
  const ed = quillEditors[field];
  if (!ed) return '';
  const html = ed.root.innerHTML;
  if (html === '<p><br></p>' || html === '<p></p>') return '';
  return html;
}

function setQuillHtml(field, html) {
  const ed = quillEditors[field];
  if (!ed) return;
  ed.setText('');
  if (html && String(html).trim()) {
    ed.clipboard.dangerouslyPasteHTML(String(html));
  }
}

// ── AUTENTICAÇÃO E PERMISSÕES ─────────────────────────────
onAuthStateChanged(auth, async (user) => {
  document.getElementById('loading').style.display = 'none';

  if (!user) {
    cleanupSubscriptions();
    showLogin();
    return;
  }

  try {
    const snap = await getDoc(doc(db, 'users', user.uid));
    const role = snap.exists() ? (snap.data().role || 'usuario') : 'usuario';

    if (role !== 'escritor' && role !== 'admin' && role !== 'super_admin') {
      await signOut(auth);
      showLogin('Acesso restrito a Escritores e Administradores. Solicite permissão pelo aplicativo.');
      return;
    }

    currentUser = user;
    currentUserRole = role;

    document.getElementById('header-email').textContent = user.email || '';
    const roleBadge = document.getElementById('header-role-badge');
    if (roleBadge) {
      roleBadge.textContent = rolePt(role);
      roleBadge.className = `badge role-${role}`;
    }

    // Exibe ou oculta abas exclusivas de Admin / Super Admin
    const isAdminOrSuper = role === 'admin' || role === 'super_admin';
    document.querySelectorAll('.admin-only-tab').forEach((btn) => {
      btn.style.display = isAdminOrSuper ? 'inline-flex' : 'none';
    });

    // Apenas super_admin pode alterar cargos ou criar usuários diretamente
    const btnCreateUser = document.getElementById('btn-open-create-user');
    if (btnCreateUser) {
      btnCreateUser.style.display = role === 'super_admin' ? 'inline-flex' : 'none';
    }

    showApp();
    initQuillEditors();
    renderAspectosSelector();
    subscribeData(isAdminOrSuper);

    // Verifica se veio com ?id=<plantaId> na URL (compatibilidade com links diretos)
    const params = new URLSearchParams(window.location.search);
    const directPlantId = params.get('id');
    if (directPlantId) {
      await openPlantEditor(directPlantId);
    }
  } catch (err) {
    console.error('Erro ao validar sessão:', err);
    showLogin('Erro ao verificar permissões: ' + err.message);
  }
});

function cleanupSubscriptions() {
  if (unsubPlants) { unsubPlants(); unsubPlants = null; }
  if (unsubPosts) { unsubPosts(); unsubPosts = null; }
  if (unsubUsers) { unsubUsers(); unsubUsers = null; }
  if (unsubRequests) { unsubRequests(); unsubRequests = null; }
  if (unsubSuggestions) { unsubSuggestions(); unsubSuggestions = null; }
}

function showLogin(errMsg = '') {
  document.getElementById('login-screen').style.display = 'flex';
  document.getElementById('app-screen').style.display = 'none';
  const errEl = document.getElementById('login-error');
  if (errMsg) {
    errEl.textContent = errMsg;
    errEl.style.display = 'block';
  } else {
    errEl.style.display = 'none';
  }
}

function showApp() {
  document.getElementById('login-screen').style.display = 'none';
  document.getElementById('app-screen').style.display = 'block';
}

window.doLogin = async () => {
  const email = document.getElementById('in-email').value.trim();
  const pass = document.getElementById('in-pass').value;
  const btn = document.getElementById('btn-login');
  const btnText = document.getElementById('login-btn-text');
  const errEl = document.getElementById('login-error');

  if (!email || !pass) {
    errEl.textContent = 'Preencha seu e-mail e senha para continuar.';
    errEl.style.display = 'block';
    return;
  }

  btn.disabled = true;
  btnText.textContent = 'Autenticando...';
  errEl.style.display = 'none';

  try {
    await signInWithEmailAndPassword(auth, email, pass);
  } catch (err) {
    errEl.textContent = 'Credenciais inválidas ou conta não encontrada.';
    errEl.style.display = 'block';
  } finally {
    btn.disabled = false;
    btnText.textContent = 'Entrar no Painel';
  }
};

document.getElementById('in-pass')?.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') window.doLogin();
});

window.doLogout = () => signOut(auth);

function rolePt(r) {
  return {
    usuario: 'Usuário',
    escritor: 'Escritor',
    admin: 'Administrador',
    super_admin: 'Super Admin'
  }[r] || r;
}

// ── ASSINATURA EM TEMPO REAL DO FIRESTORE ─────────────────
function subscribeData(isAdminOrSuper) {
  cleanupSubscriptions();

  // 1. Plantas
  unsubPlants = onSnapshot(collection(db, 'plantas'), (snap) => {
    allPlants = snap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .sort((a, b) => (a.nome || '').localeCompare(b.nome || ''));
    const activeCount = allPlants.filter((p) => p.excluida !== true).length;
    document.getElementById('count-plants').textContent = activeCount;
    renderPlantsTable();
    populatePostPlantSelect();
  });

  // 2. Postagens / Destaques
  unsubPosts = onSnapshot(collection(db, 'destaques'), (snap) => {
    allPosts = snap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .sort((a, b) => {
        const ordA = Number(a.ordem ?? 0);
        const ordB = Number(b.ordem ?? 0);
        if (ordA !== ordB) return ordA - ordB;
        const tsA = (a.dataPublicacao || a.dataCriacao)?.toMillis?.() || 0;
        const tsB = (b.dataPublicacao || b.dataCriacao)?.toMillis?.() || 0;
        return tsB - tsA;
      });
    document.getElementById('count-posts').textContent = allPosts.length;
    renderPostsTable();
  });

  if (isAdminOrSuper) {
    // 3. Solicitações de Cargo
    unsubRequests = onSnapshot(
      query(collection(db, 'role_requests'), orderBy('dataPedido', 'desc')),
      (snap) => {
        allRequests = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        document.getElementById('count-requests').textContent = allRequests.length;
        renderRequests();
      }
    );

    // 4. Usuários
    unsubUsers = onSnapshot(collection(db, 'users'), (snap) => {
      allUsers = snap.docs
        .map((d) => ({ uid: d.id, ...d.data() }))
        .sort((a, b) => (a.email || '').localeCompare(b.email || ''));
      document.getElementById('count-users').textContent = allUsers.length;
      renderUsersTable();
    });

    // 5. Sugestões
    unsubSuggestions = onSnapshot(
      query(collection(db, 'sugestoes'), orderBy('timestamp', 'desc')),
      (snap) => {
        allSuggestions = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        const unread = allSuggestions.filter((s) => !s.lido).length;
        document.getElementById('count-suggestions').textContent = unread;
        renderSuggestions();
      },
      () => {
        // Caso não existam documentos ou índice ainda
        document.getElementById('count-suggestions').textContent = '0';
      }
    );
  }
}

// ── NAVEGAÇÃO ENTRE ABAS E SEÇÕES ─────────────────────────
window.switchTab = (tabId) => {
  document.querySelectorAll('.tab-btn').forEach((btn) => {
    const isActive = btn.getAttribute('data-tab') === tabId;
    btn.classList.toggle('active', isActive);
    btn.setAttribute('aria-selected', isActive ? 'true' : 'false');
  });
  document.querySelectorAll('.tab-content').forEach((sec) => {
    sec.classList.toggle('active', sec.id === tabId);
  });
};

window.toggleSection = (headerBtn) => {
  const body = headerBtn.nextElementSibling;
  const chevron = headerBtn.querySelector('.section-chevron');
  const isOpen = body.classList.toggle('open');
  if (chevron) chevron.classList.toggle('open', isOpen);
  headerBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
};

// ══════════════════════════════════════════════════════════
//  MÓDULO 1: CATÁLOGO E EDITOR UNIFICADO DE PLANTAS
// ══════════════════════════════════════════════════════════

window.renderPlantsTable = () => {
  const q = (document.getElementById('search-plants')?.value || '').trim().toLowerCase();
  const catFilter = document.getElementById('filter-plant-category')?.value || '';
  const statusFilter = document.getElementById('filter-plant-status')?.value || 'active';

  const filtered = allPlants.filter((p) => {
    const isDel = p.excluida === true;
    if (statusFilter === 'active' && isDel) return false;
    if (statusFilter === 'hidden' && !isDel) return false;
    if (statusFilter === 'popular' && (!p.isPopular || isDel)) return false;
    if (statusFilter === 'mine' && p.creatorId !== currentUser?.uid) return false;

    if (catFilter && (p.categoria || '') !== catFilter) return false;

    if (q) {
      const nome = (p.nome || '').toLowerCase();
      const cient = (p.nomeCientifico || '').toLowerCase();
      const kws = Array.isArray(p.keywords) ? p.keywords.join(' ').toLowerCase() : '';
      if (!nome.includes(q) && !cient.includes(q) && !kws.includes(q)) return false;
    }
    return true;
  });

  const tbody = document.getElementById('plants-tbody');
  const emptyEl = document.getElementById('empty-state-plants');
  tbody.innerHTML = '';
  emptyEl.style.display = filtered.length ? 'none' : 'block';

  filtered.forEach((p) => {
    const isDel = p.excluida === true;
    const has3d = Boolean(p.modelo3dUrl && String(p.modelo3dUrl).trim());
    const hasAudio = Boolean(
      (p.audioUrl && String(p.audioUrl).trim()) ||
      (p.audioDescricaoUrl && String(p.audioDescricaoUrl).trim())
    );
    const hasSci = Boolean(
      (p.farmacologia && String(p.farmacologia).trim()) ||
      (p.descobertasCientificas && String(p.descobertasCientificas).trim())
    );
    const hasLoc = Array.isArray(p.locais) && p.locais.length > 0;

    const canToggleStatus =
      currentUserRole === 'super_admin' ||
      currentUserRole === 'admin' ||
      (currentUserRole === 'escritor' && p.creatorId === currentUser?.uid);

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <div class="plant-row-cell">
          ${
            p.imagemUrl
              ? `<img class="plant-thumb" src="${escapeHtml(p.imagemUrl)}" alt="" loading="lazy" />`
              : `<div class="plant-thumb" aria-hidden="true">${ICONS.leaf}</div>`
          }
          <div>
            <div class="plant-title-main">
              ${escapeHtml(p.nome || 'Planta sem nome')}
              ${p.isPopular ? `<span class="badge badge-accent" style="margin-left:6px;font-size:10.5px;">Popular</span>` : ''}
            </div>
            <div class="plant-title-sub">${escapeHtml(p.nomeCientifico || 'Sem nome científico')}</div>
          </div>
        </div>
      </td>
      <td>
        ${
          p.categoria
            ? `<span class="badge badge-muted">${escapeHtml(p.categoria)}</span>`
            : `<span style="color:var(--text-muted);font-size:12.5px;">Não definida</span>`
        }
      </td>
      <td>
        <div class="resource-Indicators">
          <span class="res-pill ${has3d ? 'active' : ''}" title="Modelo 3D">${ICONS.cube} 3D</span>
          <span class="res-pill ${hasAudio ? 'active' : ''}" title="Áudio / Podcast">${ICONS.audio} Áudio</span>
          <span class="res-pill ${hasSci ? 'active' : ''}" title="Conteúdo Científico">${ICONS.science} Ciência</span>
          <span class="res-pill ${hasLoc ? 'active' : ''}" title="Locais de Visitação">${ICONS.pin} Local</span>
        </div>
      </td>
      <td>
        <span class="badge ${isDel ? 'badge-danger' : 'badge-accent'}">
          ${isDel ? 'Oculta' : 'Ativa'}
        </span>
      </td>
      <td style="text-align:right;white-space:nowrap;">
        <button type="button" class="btn btn-outline btn-sm" onclick="openPlantEditor('${p.id}')">
          ${ICONS.edit}
          <span>Editar</span>
        </button>
        ${
          canToggleStatus
            ? `<button type="button" class="btn ${isDel ? 'btn-outline' : 'btn-danger-outline'} btn-sm" style="margin-left:6px;" onclick="togglePlantStatus('${p.id}', ${!isDel})">
                ${isDel ? ICONS.restore : ICONS.trash}
                <span>${isDel ? 'Restaurar' : 'Ocultar'}</span>
              </button>`
            : ''
        }
      </td>
    `;
    tbody.appendChild(tr);
  });
};

window.togglePlantStatus = async (id, hideStatus) => {
  try {
    await updateDoc(doc(db, 'plantas', id), {
      excluida: hideStatus,
      updatedAt: serverTimestamp()
    });
    showToast(hideStatus ? 'Planta movida para itens ocultos.' : 'Planta restaurada ao catálogo ativo.', 'success');
  } catch (err) {
    showToast('Erro ao alterar status: ' + err.message, 'error');
  }
};

// ── ABRIR E FECHAR O EDITOR DE PLANTA INLINE ──────────────
window.openPlantEditor = async (plantaId = null) => {
  editingPlantId = plantaId;
  clearPlantForm();

  document.getElementById('plants-list-view').style.display = 'none';
  document.getElementById('plants-editor-view').style.display = 'block';
  document.getElementById('plant-editor-heading').textContent = plantaId ? 'Editar Planta' : 'Nova Planta';

  window.scrollTo({ top: 0, behavior: 'smooth' });

  if (plantaId) {
    await loadPlantaIntoForm(plantaId);
  }
};

window.closePlantEditor = () => {
  editingPlantId = null;
  // Limpa ?id= da barra de endereço sem recarregar a página
  if (window.location.search.includes('id=')) {
    window.history.replaceState({}, document.title, window.location.pathname);
  }
  document.getElementById('plants-editor-view').style.display = 'none';
  document.getElementById('plants-list-view').style.display = 'block';
  window.scrollTo({ top: 0, behavior: 'smooth' });
};

async function loadPlantaIntoForm(id) {
  try {
    const snap = await getDoc(doc(db, 'plantas', id));
    if (!snap.exists()) {
      showToast('Planta não encontrada no banco de dados.', 'error');
      closePlantEditor();
      return;
    }

    const d = snap.data();
    document.getElementById('plant-editor-heading').textContent = `Editando: ${d.nome || 'Planta'}`;

    setVal('nome', d.nome);
    setVal('nomeCientifico', d.nomeCientifico);
    setVal('categoria', d.categoria);
    setVal('descricaoCurta', d.descricaoCurta);
    document.getElementById('field-isPopular').checked = d.isPopular === true;

    // Aspectos de Uso
    selectedAspectos.clear();
    if (Array.isArray(d.aspectosUso)) {
      d.aspectosUso.forEach((a) => {
        const clean = String(a).trim();
        if (clean) selectedAspectos.add(clean);
      });
    }
    renderAspectosSelector();

    // Keywords e Benefícios
    keywordsChips = parseToArray(d.keywords);
    renderKeywordsChips();

    beneficiosList = parseToArray(d.beneficios);
    renderBeneficiosChips();

    // Mídia Principal e Extras
    setVal('imagemUrl', d.imagemUrl);
    syncCoverPreviewFromInput();

    imagensExtras = parseToArray(d.imagensExtras || d.fotos || d.imagens);
    renderExtraImgs();

    setVal('modelo3dUrl', d.modelo3dUrl);
    if (d.modelo3dUrl) {
      document.getElementById('model-name').textContent = 'Modelo 3D configurado';
      document.getElementById('model-sub').textContent = String(d.modelo3dUrl).split('/').pop();
    }

    setVal('audioUrl', d.audioUrl);
    if (d.audioUrl) {
      document.getElementById('audio-name').textContent = 'Podcast configurado';
      document.getElementById('audio-sub').textContent = 'Pronto para reprodução';
    }

    setVal('audioDescricaoUrl', d.audioDescricaoUrl);
    if (d.audioDescricaoUrl) {
      document.getElementById('audiodesc-name').textContent = 'Audiodescrição configurada';
      document.getElementById('audiodesc-sub').textContent = 'Pronta para reprodução';
    }

    // Textos ricos Quill
    setQuillHtml('descobertasCientificas', d.descobertasCientificas || d.descricaoSimples);
    setQuillHtml('descricao', d.descricao || d.descricaoCompleta);
    setQuillHtml('taxonomia', d.taxonomiaNomesPopulares);
    setQuillHtml('distribuicaoHabitat', d.distribuicaoHabitat);
    setQuillHtml('fenologia', d.fenologia);
    setQuillHtml('usosEValorEconomico', d.usosEValorEconomico);
    setQuillHtml('farmacologia', d.farmacologia);
    setQuillHtml('comoUsar', d.comoUsar);
    setQuillHtml('cuidados', Array.isArray(d.cuidados) ? d.cuidados.join('<br>') : d.cuidados);

    // Cuidados Avançados
    cuidadosAvancadosList = Array.isArray(d.cuidadosAvancados)
      ? d.cuidadosAvancados.map((c) => ({
          nivel: c.nivel || 'avisoGeral',
          descricao: c.descricao || '',
          doseRecomendada: c.doseRecomendada || ''
        }))
      : [];
    renderCuidadosAvancados();

    // Locais de Visitação
    locaisVisitacaoList = Array.isArray(d.locais)
      ? d.locais.map((l) => ({
          nomeLocal: l.nomeLocal || '',
          endereco: l.endereco || '',
          avaliacaoMedia: l.avaliacaoMedia ?? '',
          reviews: Array.isArray(l.reviews)
            ? l.reviews.map((r) => ({
                autor: r.autor || '',
                nota: r.nota ?? '',
                texto: r.texto || ''
              }))
            : []
        }))
      : [];
    renderLocaisVisitacao();

    // Referências
    setVal('referenciasFarmacologicas', parseToArray(d.referenciasFarmacologicas).join(', '));
    setVal('referenciaGeral', parseToArray(d.referenciaGeral).join(', '));

    updateProgress();
  } catch (err) {
    showToast('Erro ao carregar dados da planta: ' + err.message, 'error');
  }
}

function clearPlantForm() {
  [
    'nome', 'nomeCientifico', 'categoria', 'descricaoCurta',
    'imagemUrl', 'modelo3dUrl', 'audioUrl', 'audioDescricaoUrl',
    'referenciasFarmacologicas', 'referenciaGeral'
  ].forEach((id) => setVal(id, ''));

  const popCheck = document.getElementById('field-isPopular');
  if (popCheck) popCheck.checked = false;

  selectedAspectos.clear();
  renderAspectosSelector();

  keywordsChips = [];
  renderKeywordsChips();

  beneficiosList = [];
  renderBeneficiosChips();

  imagensExtras = [];
  renderExtraImgs();

  cuidadosAvancadosList = [];
  renderCuidadosAvancados();

  locaisVisitacaoList = [];
  renderLocaisVisitacao();

  QUILL_FIELDS.forEach((f) => setQuillHtml(f, ''));

  const prev = document.getElementById('img-preview');
  if (prev) {
    prev.src = '';
    prev.style.display = 'none';
  }
  document.getElementById('img-upload-zone')?.classList.remove('has-file');

  document.getElementById('model-name').textContent = 'Arquivo .GLB';
  document.getElementById('model-sub').textContent = 'Visualização 3D no app';
  document.getElementById('audio-name').textContent = 'Podcast ("Papo de Feira")';
  document.getElementById('audio-sub').textContent = 'Player da aba Geral';
  document.getElementById('audiodesc-name').textContent = 'Audiodescrição';
  document.getElementById('audiodesc-sub').textContent = 'Botão de acessibilidade';

  document.getElementById('field-nome')?.classList.remove('invalid');
  const errNome = document.getElementById('err-nome');
  if (errNome) errNome.style.display = 'none';

  updateProgress();
}

// ── ASPECTOS DE USO, KEYWORDS E BENEFÍCIOS ────────────────
function renderAspectosSelector() {
  const container = document.getElementById('aspectos-container');
  if (!container) return;
  container.innerHTML = '';
  OPCOES_ASPECTOS.forEach((aspecto) => {
    const isSel = selectedAspectos.has(aspecto);
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = `aspect-chip ${isSel ? 'selected' : ''}`;
    btn.setAttribute('aria-pressed', isSel ? 'true' : 'false');
    btn.innerHTML = `${isSel ? ICONS.check : ''}<span>${escapeHtml(aspecto)}</span>`;
    btn.onclick = () => {
      if (selectedAspectos.has(aspecto)) selectedAspectos.delete(aspecto);
      else selectedAspectos.add(aspecto);
      renderAspectosSelector();
      updateProgress();
    };
    container.appendChild(btn);
  });
}

window.addChip = () => {
  const input = document.getElementById('keyword-input');
  const raw = (input?.value || '').trim().toLowerCase();
  if (raw && !keywordsChips.includes(raw)) {
    keywordsChips.push(raw);
    renderKeywordsChips();
    updateProgress();
  }
  if (input) {
    input.value = '';
    input.focus();
  }
};

document.getElementById('keyword-input')?.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ',') {
    e.preventDefault();
    window.addChip();
  }
});

function renderKeywordsChips() {
  const container = document.getElementById('chips-container');
  if (!container) return;
  container.innerHTML = '';
  keywordsChips.forEach((chip, idx) => {
    const span = document.createElement('span');
    span.className = 'chip-tag';
    span.innerHTML = `
      <span>#${escapeHtml(chip)}</span>
      <button type="button" class="chip-remove-btn" aria-label="Remover palavra-chave ${escapeHtml(chip)}" onclick="removeChip(${idx})">
        ${ICONS.close}
      </button>
    `;
    container.appendChild(span);
  });
}

window.removeChip = (idx) => {
  keywordsChips.splice(idx, 1);
  renderKeywordsChips();
  updateProgress();
};

window.addBeneficio = () => {
  const input = document.getElementById('beneficio-input');
  const raw = (input?.value || '').trim();
  if (raw && !beneficiosList.includes(raw)) {
    beneficiosList.push(raw);
    renderBeneficiosChips();
    updateProgress();
  }
  if (input) {
    input.value = '';
    input.focus();
  }
};

document.getElementById('beneficio-input')?.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    window.addBeneficio();
  }
});

function renderBeneficiosChips() {
  const container = document.getElementById('beneficios-container');
  if (!container) return;
  container.innerHTML = '';
  beneficiosList.forEach((b, idx) => {
    const span = document.createElement('span');
    span.className = 'chip-tag';
    span.innerHTML = `
      <span>${escapeHtml(b)}</span>
      <button type="button" class="chip-remove-btn" aria-label="Remover benefício" onclick="removeBeneficio(${idx})">
        ${ICONS.close}
      </button>
    `;
    container.appendChild(span);
  });
}

window.removeBeneficio = (idx) => {
  beneficiosList.splice(idx, 1);
  renderBeneficiosChips();
  updateProgress();
};

// ── CUIDADOS AVANÇADOS DINÂMICOS ──────────────────────────
window.addCuidadoAvancado = () => {
  cuidadosAvancadosList.push({
    nivel: 'avisoGeral',
    descricao: '',
    doseRecomendada: ''
  });
  renderCuidadosAvancados();
};

window.removeCuidadoAvancado = (idx) => {
  cuidadosAvancadosList.splice(idx, 1);
  renderCuidadosAvancados();
};

window.updateCuidadoField = (idx, key, val) => {
  if (cuidadosAvancadosList[idx]) {
    cuidadosAvancadosList[idx][key] = val;
  }
};

function renderCuidadosAvancados() {
  const container = document.getElementById('cuidados-avancados-container');
  if (!container) return;
  container.innerHTML = '';

  cuidadosAvancadosList.forEach((item, idx) => {
    const card = document.createElement('div');
    card.className = 'dynamic-list-card';
    card.innerHTML = `
      <div class="dynamic-list-header">
        <span class="dynamic-list-title">Alerta de Segurança #${idx + 1}</span>
        <button type="button" class="btn btn-danger-outline btn-sm" onclick="removeCuidadoAvancado(${idx})">
          ${ICONS.trash}
          <span>Remover</span>
        </button>
      </div>
      <div class="form-grid-3">
        <div class="field-group">
          <label class="field-label">Nível de Segurança</label>
          <select onchange="updateCuidadoField(${idx}, 'nivel', this.value)">
            <option value="avisoGeral" ${item.nivel === 'avisoGeral' ? 'selected' : ''}>Aviso Geral (Azul)</option>
            <option value="cuidadoSeguro" ${item.nivel === 'cuidadoSeguro' ? 'selected' : ''}>Uso Seguro (Verde)</option>
            <option value="atencao" ${item.nivel === 'atencao' ? 'selected' : ''}>Atenção / Moderado (Laranja)</option>
            <option value="cuidadoPerigo" ${item.nivel === 'cuidadoPerigo' ? 'selected' : ''}>Alto Risco / Perigo (Vermelho)</option>
          </select>
        </div>
        <div class="field-group">
          <label class="field-label">Descrição do Alerta</label>
          <input type="text" value="${escapeHtml(item.descricao)}" placeholder="Ex: Evitar uso contínuo por gestantes..." oninput="updateCuidadoField(${idx}, 'descricao', this.value)" />
        </div>
        <div class="field-group">
          <label class="field-label">Dose Recomendada (Opcional)</label>
          <input type="text" value="${escapeHtml(item.doseRecomendada)}" placeholder="Ex: Máximo de 2 xícaras ao dia" oninput="updateCuidadoField(${idx}, 'doseRecomendada', this.value)" />
        </div>
      </div>
    `;
    container.appendChild(card);
  });
}

// ── LOCAIS DE VISITAÇÃO E AVALIAÇÕES DINÂMICOS ────────────
window.addLocalVisitacao = () => {
  locaisVisitacaoList.push({
    nomeLocal: '',
    endereco: '',
    avaliacaoMedia: '5.0',
    reviews: []
  });
  renderLocaisVisitacao();
};

window.removeLocalVisitacao = (idx) => {
  locaisVisitacaoList.splice(idx, 1);
  renderLocaisVisitacao();
};

window.updateLocalField = (idx, key, val) => {
  if (locaisVisitacaoList[idx]) {
    locaisVisitacaoList[idx][key] = val;
  }
};

window.addLocalReview = (localIdx) => {
  if (!locaisVisitacaoList[localIdx]) return;
  locaisVisitacaoList[localIdx].reviews.push({
    autor: '',
    nota: '5.0',
    texto: ''
  });
  renderLocaisVisitacao();
};

window.removeLocalReview = (localIdx, revIdx) => {
  if (!locaisVisitacaoList[localIdx]) return;
  locaisVisitacaoList[localIdx].reviews.splice(revIdx, 1);
  renderLocaisVisitacao();
};

window.updateReviewField = (localIdx, revIdx, key, val) => {
  if (locaisVisitacaoList[localIdx]?.reviews?.[revIdx]) {
    locaisVisitacaoList[localIdx].reviews[revIdx][key] = val;
  }
};

function renderLocaisVisitacao() {
  const container = document.getElementById('locais-container');
  if (!container) return;
  container.innerHTML = '';

  locaisVisitacaoList.forEach((loc, idx) => {
    const card = document.createElement('div');
    card.className = 'dynamic-list-card';

    const reviewsHtml = (loc.reviews || [])
      .map(
        (rev, rIdx) => `
        <div class="nested-review-card">
          <div class="dynamic-list-header" style="margin-bottom:8px;">
            <span style="font-size:12px;font-weight:600;color:var(--text-secondary);">Avaliação #${rIdx + 1}</span>
            <button type="button" class="btn btn-ghost btn-sm" onclick="removeLocalReview(${idx}, ${rIdx})">
              ${ICONS.close}
              <span>Remover</span>
            </button>
          </div>
          <div class="form-grid-3">
            <div class="field-group">
              <label class="field-label">Autor</label>
              <input type="text" value="${escapeHtml(rev.autor)}" placeholder="Nome do visitante" oninput="updateReviewField(${idx}, ${rIdx}, 'autor', this.value)" />
            </div>
            <div class="field-group">
              <label class="field-label">Nota (0 a 5)</label>
              <input type="number" step="0.1" min="0" max="5" value="${escapeHtml(String(rev.nota))}" oninput="updateReviewField(${idx}, ${rIdx}, 'nota', this.value)" />
            </div>
            <div class="field-group">
              <label class="field-label">Comentário</label>
              <input type="text" value="${escapeHtml(rev.texto)}" placeholder="Relato sobre o local..." oninput="updateReviewField(${idx}, ${rIdx}, 'texto', this.value)" />
            </div>
          </div>
        </div>
      `
      )
      .join('');

    card.innerHTML = `
      <div class="dynamic-list-header">
        <span class="dynamic-list-title">Local de Visitação #${idx + 1}</span>
        <button type="button" class="btn btn-danger-outline btn-sm" onclick="removeLocalVisitacao(${idx})">
          ${ICONS.trash}
          <span>Remover Local</span>
        </button>
      </div>
      <div class="form-grid-3">
        <div class="field-group">
          <label class="field-label">Nome do Local / Feira / Horto</label>
          <input type="text" value="${escapeHtml(loc.nomeLocal)}" placeholder="Ex: Feira do Mercadão 2000" oninput="updateLocalField(${idx}, 'nomeLocal', this.value)" />
        </div>
        <div class="field-group">
          <label class="field-label">Endereço / Referência</label>
          <input type="text" value="${escapeHtml(loc.endereco)}" placeholder="Av. Tapajós, Santarém - PA" oninput="updateLocalField(${idx}, 'endereco', this.value)" />
        </div>
        <div class="field-group">
          <label class="field-label">Avaliação Média (0 a 5)</label>
          <input type="number" step="0.1" min="0" max="5" value="${escapeHtml(String(loc.avaliacaoMedia))}" oninput="updateLocalField(${idx}, 'avaliacaoMedia', this.value)" />
        </div>
      </div>
      <div style="margin-top:12px;">
        <button type="button" class="btn btn-outline btn-sm" onclick="addLocalReview(${idx})">
          ${ICONS.plus}
          <span>Adicionar Avaliação de Visitante</span>
        </button>
        ${reviewsHtml}
      </div>
    `;
    container.appendChild(card);
  });
}

// ── UPLOADS PARA O CLOUDINARY ─────────────────────────────
function uploadToCloudinary(file, resourceType, onProgress) {
  return new Promise((resolve, reject) => {
    if (file.size > 15 * 1024 * 1024) {
      reject(new Error('O arquivo excede o limite de 15 MB.'));
      return;
    }
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', CLOUDINARY_PRESET);

    const xhr = new XMLHttpRequest();
    xhr.open('POST', `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/${resourceType}/upload`);
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable && onProgress) {
        onProgress(Math.round((e.loaded / e.total) * 100));
      }
    };
    xhr.onload = () => {
      try {
        const res = JSON.parse(xhr.responseText);
        if (res.secure_url) resolve(res.secure_url);
        else reject(new Error(res.error?.message || 'Falha no upload para o Cloudinary.'));
      } catch (e) {
        reject(new Error('Resposta inválida do servidor de mídia.'));
      }
    };
    xhr.onerror = () => reject(new Error('Falha de conexão durante o upload.'));
    xhr.send(formData);
  });
}

window.syncCoverPreviewFromInput = () => {
  const url = getVal('imagemUrl');
  const prev = document.getElementById('img-preview');
  const zone = document.getElementById('img-upload-zone');
  if (url) {
    prev.src = url;
    prev.style.display = 'block';
    zone?.classList.add('has-file');
  } else {
    prev.src = '';
    prev.style.display = 'none';
    zone?.classList.remove('has-file');
  }
  updateProgress();
};

window.handleImageSelect = async () => {
  const file = document.getElementById('img-input')?.files?.[0];
  if (!file) return;

  const wrap = document.getElementById('img-progress-wrap');
  const fill = document.getElementById('img-progress-fill');
  const pctEl = document.getElementById('img-pct');
  wrap.style.display = 'block';

  try {
    const url = await uploadToCloudinary(file, 'image', (pct) => {
      fill.style.width = pct + '%';
      pctEl.textContent = pct + '%';
    });
    setVal('imagemUrl', url);
    window.syncCoverPreviewFromInput();
    showToast('Foto principal enviada com sucesso.', 'success');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    wrap.style.display = 'none';
  }
};

window.handleExtrasSelect = async () => {
  const files = document.getElementById('extras-input')?.files;
  if (!files || !files.length) return;

  const wrap = document.getElementById('extras-progress-wrap');
  const fill = document.getElementById('extras-progress-fill');
  const pctEl = document.getElementById('extras-pct');
  wrap.style.display = 'block';

  try {
    for (let i = 0; i < files.length; i++) {
      const url = await uploadToCloudinary(files[i], 'image', (pct) => {
        const overall = Math.round(((i + pct / 100) / files.length) * 100);
        fill.style.width = overall + '%';
        pctEl.textContent = overall + '%';
      });
      imagensExtras.push(url);
    }
    renderExtraImgs();
    updateProgress();
    showToast('Fotos adicionadas à galeria.', 'success');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    wrap.style.display = 'none';
    document.getElementById('extras-input').value = '';
  }
};

function renderExtraImgs() {
  const g = document.getElementById('extras-gallery');
  if (!g) return;
  g.innerHTML = '';

  imagensExtras.forEach((url, i) => {
    const card = document.createElement('div');
    card.className = 'extra-thumb-card';
    card.innerHTML = `
      <img src="${escapeHtml(url)}" alt="Foto extra ${i + 1}" loading="lazy" />
      <button type="button" class="extra-thumb-remove" onclick="removeExtraImg(${i})" title="Remover foto" aria-label="Remover foto extra">
        ${ICONS.close}
      </button>
      <div class="extra-thumb-bar">
        <div style="display:flex;gap:4px;">
          ${
            i > 0
              ? `<button type="button" class="extra-thumb-btn" onclick="moveExtraImg(${i}, -1)" title="Mover para esquerda" aria-label="Mover para esquerda">${ICONS.arrowLeft}</button>`
              : '<span style="width:15px;"></span>'
          }
          ${
            i < imagensExtras.length - 1
              ? `<button type="button" class="extra-thumb-btn" onclick="moveExtraImg(${i}, 1)" title="Mover para direita" aria-label="Mover para direita">${ICONS.arrowRight}</button>`
              : '<span style="width:15px;"></span>'
          }
        </div>
        <button type="button" class="extra-thumb-btn" onclick="makeMainImg(${i})" title="Definir como capa principal" aria-label="Definir como capa principal">
          ${ICONS.star}
        </button>
      </div>
    `;
    g.appendChild(card);
  });
}

window.moveExtraImg = (idx, dir) => {
  const target = idx + dir;
  if (target >= 0 && target < imagensExtras.length) {
    [imagensExtras[idx], imagensExtras[target]] = [imagensExtras[target], imagensExtras[idx]];
    renderExtraImgs();
  }
};

window.makeMainImg = (idx) => {
  const currentMain = getVal('imagemUrl');
  const chosen = imagensExtras[idx];
  setVal('imagemUrl', chosen);
  window.syncCoverPreviewFromInput();
  if (currentMain) imagensExtras[idx] = currentMain;
  else imagensExtras.splice(idx, 1);
  renderExtraImgs();
  showToast('Imagem definida como capa principal.', 'success');
};

window.removeExtraImg = (idx) => {
  imagensExtras.splice(idx, 1);
  renderExtraImgs();
};

window.handleModelSelect = async () => {
  const file = document.getElementById('model-input')?.files?.[0];
  if (!file) return;

  const wrap = document.getElementById('model-progress-wrap');
  const fill = document.getElementById('model-progress-fill');
  const pctEl = document.getElementById('model-pct');
  wrap.style.display = 'block';

  try {
    const url = await uploadToCloudinary(file, 'raw', (pct) => {
      fill.style.width = pct + '%';
      pctEl.textContent = pct + '%';
    });
    setVal('modelo3dUrl', url);
    document.getElementById('model-name').textContent = file.name;
    document.getElementById('model-sub').textContent = 'Modelo enviado com sucesso';
    updateProgress();
    showToast('Modelo 3D enviado com sucesso.', 'success');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    wrap.style.display = 'none';
  }
};

window.handleAudioSelect = async (type) => {
  const isDesc = type === 'audiodesc';
  const inputId = isDesc ? 'audiodesc-input' : 'audio-input';
  const file = document.getElementById(inputId)?.files?.[0];
  if (!file) return;

  const prefix = isDesc ? 'audiodesc' : 'audio';
  const wrap = document.getElementById(`${prefix}-progress-wrap`);
  const fill = document.getElementById(`${prefix}-progress-fill`);
  const pctEl = document.getElementById(`${prefix}-pct`);
  wrap.style.display = 'block';

  try {
    const url = await uploadToCloudinary(file, 'video', (pct) => {
      fill.style.width = pct + '%';
      pctEl.textContent = pct + '%';
    });
    setVal(isDesc ? 'audioDescricaoUrl' : 'audioUrl', url);
    document.getElementById(`${prefix}-name`).textContent = file.name;
    document.getElementById(`${prefix}-sub`).textContent = 'Áudio enviado com sucesso';
    updateProgress();
    showToast('Arquivo de áudio enviado com sucesso.', 'success');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    wrap.style.display = 'none';
  }
};

// ── BARRA DE PROGRESSO E SALVAMENTO DA PLANTA ─────────────
const TRACKED_PLANT_INPUTS = [
  'nome', 'nomeCientifico', 'categoria', 'descricaoCurta',
  'imagemUrl', 'modelo3dUrl', 'audioUrl',
  'referenciasFarmacologicas', 'referenciaGeral'
];

window.updateProgress = () => {
  let filled = 0;
  const total = TRACKED_PLANT_INPUTS.length + QUILL_FIELDS.length + 2;

  TRACKED_PLANT_INPUTS.forEach((id) => {
    if (getVal(id)) filled++;
  });
  QUILL_FIELDS.forEach((f) => {
    if (getQuillHtml(f)) filled++;
  });
  if (keywordsChips.length > 0) filled++;
  if (selectedAspectos.size > 0) filled++;

  const pct = Math.min(100, Math.round((filled / total) * 100));
  const fillEl = document.getElementById('progress-fill');
  const pctEl = document.getElementById('progress-pct');
  if (fillEl) fillEl.style.width = pct + '%';
  if (pctEl) pctEl.textContent = pct + '%';
};

window.savePlanta = async () => {
  const nome = getVal('nome');
  if (!nome) {
    const nomeInput = document.getElementById('field-nome');
    nomeInput?.classList.add('invalid');
    document.getElementById('err-nome').style.display = 'block';
    nomeInput?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    nomeInput?.focus();
    return;
  }

  document.getElementById('field-nome')?.classList.remove('invalid');
  document.getElementById('err-nome').style.display = 'none';

  const btn = document.getElementById('btn-save-plant');
  const btnText = document.getElementById('save-plant-text');
  btn.disabled = true;
  btnText.textContent = 'Salvando...';

  const kws = [...keywordsChips];
  const nomeLower = nome.toLowerCase();
  if (!kws.includes(nomeLower)) kws.push(nomeLower);

  const splitComma = (id) =>
    getVal(id)
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);

  const validCuidados = cuidadosAvancadosList
    .filter((c) => c.descricao && c.descricao.trim())
    .map((c) => ({
      nivel: c.nivel || 'avisoGeral',
      descricao: c.descricao.trim(),
      doseRecomendada: (c.doseRecomendada || '').trim()
    }));

  const validLocais = locaisVisitacaoList
    .filter((l) => (l.nomeLocal && l.nomeLocal.trim()) || (l.endereco && l.endereco.trim()))
    .map((l) => ({
      nomeLocal: (l.nomeLocal || '').trim(),
      endereco: (l.endereco || '').trim(),
      avaliacaoMedia: parseFloat(l.avaliacaoMedia) || 0.0,
      reviews: (l.reviews || [])
        .filter((r) => (r.autor && r.autor.trim()) || (r.texto && r.texto.trim()))
        .map((r) => ({
          autor: (r.autor || '').trim(),
          nota: parseFloat(r.nota) || 5.0,
          texto: (r.texto || '').trim()
        }))
    }));

  const payload = {
    nome,
    nomeCientifico: getVal('nomeCientifico'),
    categoria: getVal('categoria'),
    descricaoCurta: getVal('descricaoCurta'),
    isPopular: document.getElementById('field-isPopular')?.checked === true,
    aspectosUso: Array.from(selectedAspectos),
    keywords: kws,
    beneficios: [...beneficiosList],
    imagemUrl: getVal('imagemUrl'),
    imagensExtras: [...imagensExtras],
    modelo3dUrl: getVal('modelo3dUrl'),
    audioUrl: getVal('audioUrl'),
    audioDescricaoUrl: getVal('audioDescricaoUrl'),
    descobertasCientificas: getQuillHtml('descobertasCientificas'),
    descricao: getQuillHtml('descricao'),
    taxonomiaNomesPopulares: getQuillHtml('taxonomia'),
    distribuicaoHabitat: getQuillHtml('distribuicaoHabitat'),
    fenologia: getQuillHtml('fenologia'),
    usosEValorEconomico: getQuillHtml('usosEValorEconomico'),
    farmacologia: getQuillHtml('farmacologia'),
    comoUsar: getQuillHtml('comoUsar'),
    cuidados: getQuillHtml('cuidados'),
    cuidadosAvancados: validCuidados,
    locais: validLocais,
    referenciasFarmacologicas: splitComma('referenciasFarmacologicas'),
    referenciaGeral: splitComma('referenciaGeral'),
    updatedAt: serverTimestamp()
  };

  try {
    if (editingPlantId) {
      await updateDoc(doc(db, 'plantas', editingPlantId), payload);
      showToast('Planta atualizada com sucesso.', 'success');
    } else {
      payload.creatorId = currentUser?.uid || '';
      payload.dataCriacao = serverTimestamp();
      payload.createdAt = serverTimestamp();
      payload.excluida = false;
      await addDoc(collection(db, 'plantas'), payload);
      showToast('Nova planta cadastrada no catálogo.', 'success');
    }
    closePlantEditor();
  } catch (err) {
    showToast('Erro ao salvar planta: ' + err.message, 'error');
  } finally {
    btn.disabled = false;
    btnText.textContent = 'Salvar Planta';
  }
};

// ══════════════════════════════════════════════════════════
//  MÓDULO 2: POSTAGENS E DESTAQUES (NOTÍCIAS)
// ══════════════════════════════════════════════════════════

function populatePostPlantSelect() {
  const sel = document.getElementById('post-plantaId');
  if (!sel) return;
  const currentVal = sel.value;
  sel.innerHTML = `<option value="">Nenhuma planta vinculada (usar apenas link externo)</option>`;
  allPlants
    .filter((p) => p.excluida !== true)
    .forEach((p) => {
      const opt = document.createElement('option');
      opt.value = p.id;
      opt.textContent = `${p.nome || 'Sem nome'}${p.nomeCientifico ? ` (${p.nomeCientifico})` : ''}`;
      sel.appendChild(opt);
    });
  sel.value = currentVal;
}

window.renderPostsTable = () => {
  const tbody = document.getElementById('posts-tbody');
  const emptyEl = document.getElementById('empty-state-posts');
  if (!tbody) return;
  tbody.innerHTML = '';
  emptyEl.style.display = allPosts.length ? 'none' : 'block';

  allPosts.forEach((post) => {
    const linkedPlant = post.plantaId ? allPlants.find((p) => p.id === post.plantaId) : null;
    const pubDate = (post.dataPublicacao || post.dataCriacao)?.toDate?.();
    const dateStr = pubDate ? pubDate.toLocaleDateString('pt-BR') : 'Recente';

    let targetBadge = `<span style="color:var(--text-muted);font-size:12.5px;">Apenas leitura</span>`;
    if (linkedPlant) {
      targetBadge = `<span class="badge badge-accent">${ICONS.leaf} Planta: ${escapeHtml(linkedPlant.nome)}</span>`;
    } else if (post.link) {
      targetBadge = `<span class="badge badge-muted">${ICONS.link} Link Externo</span>`;
    }

    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <div class="plant-row-cell">
          ${
            post.imagemUrl
              ? `<img class="plant-thumb" src="${escapeHtml(post.imagemUrl)}" alt="" loading="lazy" />`
              : `<div class="plant-thumb" aria-hidden="true">${ICONS.leaf}</div>`
          }
          <div>
            <div class="plant-title-main">${escapeHtml(post.titulo || 'Sem título')}</div>
            <div class="plant-title-sub" style="font-style:normal;max-width:420px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
              ${escapeHtml(post.resumo || '')}
            </div>
          </div>
        </div>
      </td>
      <td><span class="badge badge-muted">#${Number(post.ordem ?? 0)}</span></td>
      <td>${targetBadge}</td>
      <td style="font-size:13px;color:var(--text-secondary);">${dateStr}</td>
      <td style="text-align:right;white-space:nowrap;">
        <button type="button" class="btn btn-outline btn-sm" onclick="openPostEditor('${post.id}')">
          ${ICONS.edit}
          <span>Editar</span>
        </button>
        <button type="button" class="btn btn-danger-outline btn-sm" style="margin-left:6px;" onclick="deletePostagem('${post.id}')">
          ${ICONS.trash}
          <span>Excluir</span>
        </button>
      </td>
    `;
    tbody.appendChild(tr);
  });
};

window.openPostEditor = (postId = null) => {
  editingPostId = postId;
  populatePostPlantSelect();

  document.getElementById('post-titulo').value = '';
  document.getElementById('post-resumo').value = '';
  document.getElementById('post-ordem').value = '0';
  document.getElementById('post-imagemUrl').value = '';
  document.getElementById('post-plantaId').value = '';
  document.getElementById('post-link').value = '';
  window.syncPostCoverPreview();

  if (postId) {
    const found = allPosts.find((x) => x.id === postId);
    if (found) {
      document.getElementById('post-editor-heading').textContent = 'Editar Postagem';
      document.getElementById('post-titulo').value = found.titulo || '';
      document.getElementById('post-resumo').value = found.resumo || '';
      document.getElementById('post-ordem').value = String(found.ordem ?? 0);
      document.getElementById('post-imagemUrl').value = found.imagemUrl || '';
      document.getElementById('post-plantaId').value = found.plantaId || '';
      document.getElementById('post-link').value = found.link || '';
      window.syncPostCoverPreview();
    }
  } else {
    document.getElementById('post-editor-heading').textContent = 'Nova Postagem';
  }

  document.getElementById('posts-list-view').style.display = 'none';
  document.getElementById('posts-editor-view').style.display = 'block';
};

window.closePostEditor = () => {
  editingPostId = null;
  document.getElementById('posts-editor-view').style.display = 'none';
  document.getElementById('posts-list-view').style.display = 'block';
};

window.syncPostCoverPreview = () => {
  const url = document.getElementById('post-imagemUrl')?.value?.trim() || '';
  const prev = document.getElementById('post-img-preview');
  const zone = document.getElementById('post-img-zone');
  if (url) {
    prev.src = url;
    prev.style.display = 'block';
    zone?.classList.add('has-file');
  } else {
    prev.src = '';
    prev.style.display = 'none';
    zone?.classList.remove('has-file');
  }
};

window.handlePostImageSelect = async () => {
  const file = document.getElementById('post-img-input')?.files?.[0];
  if (!file) return;

  const wrap = document.getElementById('post-img-progress-wrap');
  const fill = document.getElementById('post-img-progress-fill');
  const pctEl = document.getElementById('post-img-pct');
  wrap.style.display = 'block';

  try {
    const url = await uploadToCloudinary(file, 'image', (pct) => {
      fill.style.width = pct + '%';
      pctEl.textContent = pct + '%';
    });
    document.getElementById('post-imagemUrl').value = url;
    window.syncPostCoverPreview();
    showToast('Imagem de capa enviada.', 'success');
  } catch (err) {
    showToast(err.message, 'error');
  } finally {
    wrap.style.display = 'none';
  }
};

window.savePostagem = async () => {
  const titulo = document.getElementById('post-titulo').value.trim();
  const resumo = document.getElementById('post-resumo').value.trim();
  const ordem = parseInt(document.getElementById('post-ordem').value, 10) || 0;
  const imagemUrl = document.getElementById('post-imagemUrl').value.trim();
  const plantaId = document.getElementById('post-plantaId').value.trim();
  const link = document.getElementById('post-link').value.trim();

  if (!titulo || !imagemUrl) {
    showToast('Título e Imagem de Capa são obrigatórios para publicar.', 'error');
    return;
  }

  const btn = document.getElementById('btn-save-post');
  btn.disabled = true;

  const payload = {
    titulo,
    resumo,
    ordem,
    imagemUrl,
    plantaId,
    link,
    updatedAt: serverTimestamp()
  };

  try {
    if (editingPostId) {
      await updateDoc(doc(db, 'destaques', editingPostId), payload);
      showToast('Postagem atualizada com sucesso.', 'success');
    } else {
      payload.dataPublicacao = serverTimestamp();
      payload.dataCriacao = serverTimestamp();
      payload.creatorId = currentUser?.uid || '';
      await addDoc(collection(db, 'destaques'), payload);
      showToast('Postagem publicada com sucesso.', 'success');
    }
    closePostEditor();
  } catch (err) {
    showToast('Erro ao salvar postagem: ' + err.message, 'error');
  } finally {
    btn.disabled = false;
  }
};

window.deletePostagem = async (postId) => {
  if (!window.confirm('Deseja realmente excluir esta postagem permanentemente?')) return;
  try {
    await deleteDoc(doc(db, 'destaques', postId));
    showToast('Postagem removida.', 'success');
  } catch (err) {
    showToast('Erro ao remover postagem: ' + err.message, 'error');
  }
};

// ══════════════════════════════════════════════════════════
//  MÓDULO 3: SOLICITAÇÕES, USUÁRIOS E SUGESTÕES
// ══════════════════════════════════════════════════════════

window.renderRequests = () => {
  const container = document.getElementById('requests-list');
  const emptyEl = document.getElementById('empty-state-requests');
  if (!container) return;
  container.innerHTML = '';
  emptyEl.style.display = allRequests.length ? 'none' : 'block';

  allRequests.forEach((r) => {
    const div = document.createElement('div');
    div.className = 'item-card';
    div.innerHTML = `
      <div class="item-card-info">
        <h3>${escapeHtml(r.email || 'Sem e-mail')}</h3>
        <p>Nome: ${escapeHtml(r.nome || 'Não informado')} — UID: ${escapeHtml(r.uid || r.id)}</p>
        <div class="item-card-meta">Solicitado em: ${r.dataPedido?.toDate?.()?.toLocaleString('pt-BR') || 'Data recente'}</div>
      </div>
      <div style="display:flex;gap:8px;">
        <button type="button" class="btn btn-primary btn-sm" onclick="openRoleModal('${r.uid || r.id}', '${escapeHtml(r.email || '')}', 'escritor', '${r.id}')">
          ${ICONS.check}
          <span>Aprovar / Definir Cargo</span>
        </button>
        <button type="button" class="btn btn-danger-outline btn-sm" onclick="rejectRoleRequest('${r.id}')">
          ${ICONS.close}
          <span>Recusar</span>
        </button>
      </div>
    `;
    container.appendChild(div);
  });
};

window.rejectRoleRequest = async (reqId) => {
  try {
    await deleteDoc(doc(db, 'role_requests', reqId));
    showToast('Solicitação arquivada.', 'success');
  } catch (err) {
    showToast('Erro ao arquivar pedido: ' + err.message, 'error');
  }
};

window.renderUsersTable = () => {
  const q = (document.getElementById('search-input')?.value || '').trim().toLowerCase();
  const filtered = allUsers.filter(
    (u) =>
      (u.email || '').toLowerCase().includes(q) ||
      (u.nome || '').toLowerCase().includes(q)
  );
  const tbody = document.getElementById('users-tbody');
  const emptyEl = document.getElementById('empty-state-users');
  if (!tbody) return;
  tbody.innerHTML = '';
  emptyEl.style.display = filtered.length ? 'none' : 'block';

  filtered.forEach((u) => {
    const role = u.role || 'usuario';
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td style="font-weight:500;">${escapeHtml(u.email || '—')}</td>
      <td style="color:var(--text-secondary);">${escapeHtml(u.nome || '—')}</td>
      <td><span class="badge role-${role}">${rolePt(role)}</span></td>
      <td style="text-align:right;">
        ${
          currentUserRole === 'super_admin'
            ? `<button type="button" class="btn btn-outline btn-sm" onclick="openRoleModal('${u.uid}', '${escapeHtml(u.email || '')}', '${role}')">
                ${ICONS.edit}
                <span>Alterar Cargo</span>
              </button>`
            : `<span style="color:var(--text-muted);font-size:12px;">Somente leitura</span>`
        }
      </td>
    `;
    tbody.appendChild(tr);
  });
};

window.openRoleModal = (uid, email, currentRole, requestId = null) => {
  editingUid = uid;
  editingEmail = email;
  currentRequestId = requestId;
  document.getElementById('modal-role-email').textContent = email;
  document.getElementById('role-select').value = currentRole;
  document.getElementById('modal-role').classList.add('open');
};

window.closeRoleModal = () => {
  document.getElementById('modal-role').classList.remove('open');
  editingUid = null;
  currentRequestId = null;
};

window.saveRole = async () => {
  const role = document.getElementById('role-select').value;
  const btn = document.getElementById('btn-save-role');
  btn.disabled = true;
  try {
    const userRef = doc(db, 'users', editingUid);
    const existingUser = allUsers.find((u) => u.uid === editingUid);
    await setDoc(
      userRef,
      {
        uid: editingUid,
        email: editingEmail,
        role,
        nome: existingUser?.nome || (editingEmail ? editingEmail.split('@')[0] : '')
      },
      { merge: true }
    );
    if (currentRequestId) {
      await deleteDoc(doc(db, 'role_requests', currentRequestId));
    }
    showToast(`Permissão atualizada para ${rolePt(role)}.`, 'success');
    closeRoleModal();
  } catch (err) {
    showToast('Erro ao salvar cargo: ' + err.message, 'error');
  } finally {
    btn.disabled = false;
  }
};

window.openCreateModal = () => document.getElementById('modal-create').classList.add('open');
window.closeCreateModal = () => document.getElementById('modal-create').classList.remove('open');

window.doCreateUser = async () => {
  const n = document.getElementById('new-name').value.trim();
  const e = document.getElementById('new-email').value.trim();
  const p = document.getElementById('new-pass').value;
  if (!e || !p) {
    showToast('Preencha e-mail e senha.', 'error');
    return;
  }
  const btn = document.getElementById('btn-create');
  btn.disabled = true;
  try {
    const cred = await createUserWithEmailAndPassword(auth, e, p);
    if (n) await updateProfile(cred.user, { displayName: n });
    await setDoc(doc(db, 'users', cred.user.uid), {
      uid: cred.user.uid,
      email: e,
      nome: n || e.split('@')[0],
      role: 'usuario',
      criadoEm: serverTimestamp()
    });
    showToast('Conta criada com sucesso.', 'success');
    closeCreateModal();
  } catch (err) {
    showToast('Erro ao criar conta: ' + err.message, 'error');
  } finally {
    btn.disabled = false;
  }
};

window.renderSuggestions = () => {
  const container = document.getElementById('suggestions-list');
  const emptyEl = document.getElementById('empty-state-suggestions');
  if (!container) return;
  container.innerHTML = '';
  emptyEl.style.display = allSuggestions.length ? 'none' : 'block';

  allSuggestions.forEach((s) => {
    const dateStr = s.timestamp?.toDate?.()?.toLocaleString('pt-BR') || 'Recente';
    const div = document.createElement('div');
    div.className = 'item-card';
    div.innerHTML = `
      <div class="item-card-info" style="max-width:720px;">
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:6px;">
          <span class="badge ${s.lido ? 'badge-muted' : 'badge-accent'}">${s.lido ? 'Lida' : 'Nova'}</span>
          <span class="item-card-meta" style="margin-top:0;">${dateStr}</span>
        </div>
        <p style="color:var(--text);font-size:14px;white-space:pre-wrap;">${escapeHtml(s.texto || '')}</p>
      </div>
      <div style="display:flex;gap:8px;">
        <button type="button" class="btn btn-outline btn-sm" onclick="toggleSuggestionRead('${s.id}', ${!s.lido})">
          ${ICONS.check}
          <span>${s.lido ? 'Marcar não lida' : 'Marcar como lida'}</span>
        </button>
        <button type="button" class="btn btn-danger-outline btn-sm" onclick="deleteSuggestion('${s.id}')">
          ${ICONS.trash}
          <span>Excluir</span>
        </button>
      </div>
    `;
    container.appendChild(div);
  });
};

window.toggleSuggestionRead = async (id, readState) => {
  try {
    await updateDoc(doc(db, 'sugestoes', id), { lido: readState });
  } catch (err) {
    showToast('Erro ao atualizar sugestão: ' + err.message, 'error');
  }
};

window.deleteSuggestion = async (id) => {
  try {
    await deleteDoc(doc(db, 'sugestoes', id));
    showToast('Sugestão removida.', 'success');
  } catch (err) {
    showToast('Erro ao remover sugestão: ' + err.message, 'error');
  }
};

// ── UTILITÁRIOS ───────────────────────────────────────────
function getVal(id) {
  return document.getElementById('field-' + id)?.value?.trim() || '';
}

function setVal(id, val) {
  const el = document.getElementById('field-' + id);
  if (el) el.value = val ?? '';
}

function parseToArray(val) {
  if (Array.isArray(val)) {
    return val.map((x) => String(x).trim()).filter(Boolean);
  }
  if (typeof val === 'string' && val.trim()) {
    return val.split(',').map((x) => x.trim()).filter(Boolean);
  }
  return [];
}

function escapeHtml(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

let toastTimeout = null;
window.showToast = (msg, type = 'success') => {
  const el = document.getElementById('toast');
  if (!el) return;
  const icon = type === 'error' ? ICONS.alert : ICONS.check;
  el.innerHTML = `${icon}<span>${escapeHtml(msg)}</span>`;
  el.className = `show ${type}`;
  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    el.className = '';
  }, 3500);
};
