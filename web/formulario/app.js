// ══════════════════════════════════════════════════════════
//  app.js — Formulário de Planta
//  SUMAÚMA
// ══════════════════════════════════════════════════════════

import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.4.0/firebase-app.js';
import { getAuth, signInWithEmailAndPassword, signOut, onAuthStateChanged }
  from 'https://www.gstatic.com/firebasejs/11.4.0/firebase-auth.js';
import { getFirestore, doc, getDoc, addDoc, updateDoc, collection, serverTimestamp }
  from 'https://www.gstatic.com/firebasejs/11.4.0/firebase-firestore.js';

const firebaseConfig = window.CONFIG.FIREBASE;
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const CLOUDINARY_CLOUD = window.CONFIG.CLOUDINARY.cloudName;
const CLOUDINARY_PRESET = window.CONFIG.CLOUDINARY.uploadPreset;

const params = new URLSearchParams(window.location.search);
const plantaId = params.get('id') || null;

window._auth = auth;
window._db = db;
window._plantaId = plantaId;

// ── QUILL CONFIG ─────────────────────────────────────────
const QUILL_TOOLBAR = [
  ['bold', 'italic', 'underline'],
  [{ 'size': ['small', false, 'large', 'huge'] }],
  [{ 'align': [] }],
  [{ 'list': 'ordered' }, { 'list': 'bullet' }],
  ['clean'],
];

const QUILL_FIELDS = [
  'taxonomia', 'descricao', 'distribuicaoHabitat',
  'fenologia', 'usosEValorEconomico', 'farmacologia',
];

const quillEditors = {};
let _quillReady = false;

function initQuillEditors() {
  if (_quillReady) return;
  _quillReady = true;
  try {
    const AlignStyle = window.Quill.import('attributors/style/align');
    const SizeStyle = window.Quill.import('attributors/style/size');
    window.Quill.register(AlignStyle, true);
    window.Quill.register(SizeStyle, true);

    QUILL_FIELDS.forEach(field => {
      const container = document.querySelector('#editor-' + field);
      if (container) {
        quillEditors[field] = new window.Quill(container, {
          theme: 'snow',
          modules: { toolbar: QUILL_TOOLBAR },
          placeholder: getPlaceholder(field),
        });
        quillEditors[field].on('text-change', () => updateProgress());
      }
    });
  } catch (e) {
    console.error('Erro ao inicializar Quill:', e);
  }
}

function getPlaceholder(field) {
  const map = {
    taxonomia: 'Reino, Família, Gênero, nomes populares...',
    descricao: 'Morfologia, características gerais...',
    distribuicaoHabitat: 'Onde é encontrada, biomas, altitude...',
    fenologia: 'Épocas de floração, frutificação...',
    usosEValorEconomico: 'Uso alimentar, madeireiro, medicinal...',
    farmacologia: 'Compostos bioativos, pesquisas, propriedades medicinais...',
  };
  return map[field] || 'Digite aqui...';
}

function getQuillHtml(field) {
  const editor = quillEditors[field];
  if (!editor) return '';
  const html = editor.root.innerHTML;
  if (html === '<p><br></p>' || html === '<p></p>') return '';
  return html;
}

function setQuillHtml(field, html) {
  const editor = quillEditors[field];
  if (!editor || !html) return;
  editor.clipboard.dangerouslyPasteHTML(html);
}

// ── AUTH ──────────────────────────────────────────────────
onAuthStateChanged(auth, async (user) => {
  if (user) {
    showApp();
    initQuillEditors();
    if (plantaId) await loadPlanta(plantaId);
  } else {
    showLogin();
  }
});

document.getElementById('btn-login').addEventListener('click', async () => {
  const email = document.getElementById('login-email').value.trim();
  const pass = document.getElementById('login-password').value;
  const btn = document.getElementById('btn-login');
  const errDiv = document.getElementById('login-error');

  if (!email || !pass) {
    errDiv.textContent = 'Preencha e-mail e senha.';
    errDiv.style.display = 'block';
    return;
  }
  btn.disabled = true;
  document.getElementById('login-text').innerHTML = '<div class="spinner"></div>';
  errDiv.style.display = 'none';

  try {
    await signInWithEmailAndPassword(auth, email, pass);
  } catch (e) {
    errDiv.textContent = 'E-mail ou senha incorretos.';
    errDiv.style.display = 'block';
    btn.disabled = false;
    document.getElementById('login-text').textContent = 'Entrar';
  }
});

document.getElementById('login-password').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') document.getElementById('btn-login').click();
});

document.getElementById('btn-logout').addEventListener('click', () => signOut(auth));

// ── CARREGAR PLANTA PARA EDIÇÃO ───────────────────────────
async function loadPlanta(id) {
  const snap = await getDoc(doc(db, 'plantas', id));
  if (!snap.exists()) { showToast('Planta não encontrada.', true); return; }
  const d = snap.data();

  setField('nome', d.nome);
  setField('nomeCientifico', d.nomeCientifico);
  setField('descricaoCurta', d.descricaoCurta);

  setQuillHtml('taxonomia', d.taxonomiaNomesPopulares);
  setQuillHtml('descricao', d.descricao || d.descricaoCompleta);
  setQuillHtml('distribuicaoHabitat', d.distribuicaoHabitat);
  setQuillHtml('fenologia', d.fenologia);
  setQuillHtml('usosEValorEconomico', d.usosEValorEconomico);
  setQuillHtml('farmacologia', d.farmacologia);

  const toStr = (v) => Array.isArray(v) ? v.join(', ') : (v || '');
  setField('referenciasFarmacologicas', toStr(d.referenciasFarmacologicas));
  setField('referenciaGeral', toStr(d.referenciaGeral));
  setField('cuidados', toStr(d.cuidados));
  setField('descobertasCientificas', d.descobertasCientificas);
  setField('comoUsar', d.comoUsar);

  window._imagensExtras = Array.isArray(d.imagensExtras) ? [...d.imagensExtras] : [];
  if (typeof window.renderExtraImgs === 'function') window.renderExtraImgs();

  const kws = Array.isArray(d.keywords) ? d.keywords : (d.keywords ? [d.keywords] : []);
  kws.forEach(k => addChipValue(k));

  if (d.imagemUrl) {
    document.getElementById('field-imagemUrl').value = d.imagemUrl;
    const prev = document.getElementById('img-preview');
    prev.src = d.imagemUrl;
    prev.style.display = 'block';
    document.getElementById('img-upload-zone').classList.add('has-file');
    document.getElementById('img-success').style.display = 'flex';
  }

  if (d.modelo3dUrl) {
    document.getElementById('field-modelo3dUrl').value = d.modelo3dUrl;
    document.getElementById('model-name').textContent = 'Modelo 3D carregado';
    document.getElementById('model-sub').textContent = d.modelo3dUrl.split('/').pop();
    document.getElementById('model-upload-widget').classList.add('has-file');
    document.getElementById('model-icon').textContent = '✅';
    document.getElementById('model-success').style.display = 'flex';
  }

  if (d.audioUrl) {
    document.getElementById('field-audioUrl').value = d.audioUrl;
    document.getElementById('audio-name').textContent = 'Áudio carregado';
    document.getElementById('audio-sub').textContent = 'Pronto para tocar no app';
    document.getElementById('audio-upload-widget').classList.add('has-file');
    document.getElementById('audio-icon').textContent = '✅';
    document.getElementById('audio-success').style.display = 'flex';
  }

  updateProgress();
}

function setField(id, val) {
  const el = document.getElementById('field-' + id);
  if (el) el.value = val || '';
}

// ── SALVAR PLANTA ─────────────────────────────────────────
window.savePlanta = async function () {
  const nome = document.getElementById('field-nome').value.trim();
  if (!nome) {
    document.getElementById('field-nome').classList.add('invalid');
    document.getElementById('err-nome').style.display = 'block';
    document.getElementById('field-nome').scrollIntoView({ behavior: 'smooth', block: 'center' });
    return;
  }
  document.getElementById('field-nome').classList.remove('invalid');
  document.getElementById('err-nome').style.display = 'none';

  const btn = document.getElementById('btn-save');
  btn.disabled = true;
  document.getElementById('save-text').innerHTML = '<div class="spinner"></div> Salvando...';

  let keywords = window._chips.map(c => c.toLowerCase());
  const nomeLower = nome.toLowerCase();
  if (!keywords.includes(nomeLower)) keywords.push(nomeLower);

  const toList = (id) =>
    document.getElementById('field-' + id).value
      .split(',').map(s => s.trim()).filter(Boolean);

  const data = {
    nome,
    nomeCientifico: getVal('nomeCientifico'),
    descricaoCurta: getVal('descricaoCurta'),
    imagemUrl: getVal('imagemUrl'),
    modelo3dUrl: getVal('modelo3dUrl'),
    audioUrl: getVal('audioUrl'),
    taxonomiaNomesPopulares: getQuillHtml('taxonomia'),
    descricao: getQuillHtml('descricao'),
    distribuicaoHabitat: getQuillHtml('distribuicaoHabitat'),
    fenologia: getQuillHtml('fenologia'),
    usosEValorEconomico: getQuillHtml('usosEValorEconomico'),
    farmacologia: getQuillHtml('farmacologia'),
    referenciasFarmacologicas: toList('referenciasFarmacologicas'),
    referenciaGeral: toList('referenciaGeral'),
    imagensExtras: window._imagensExtras || [],
    cuidados: toList('cuidados'),
    descobertasCientificas: getVal('descobertasCientificas'),
    comoUsar: getVal('comoUsar'),
    keywords,
    updatedAt: serverTimestamp(),
  };

  try {
    if (window._plantaId) {
      await updateDoc(doc(db, 'plantas', window._plantaId), data);
      showToast('✅ Planta atualizada com sucesso!');
    } else {
      data.creatorId = auth.currentUser?.uid;
      data.createdAt = serverTimestamp();
      await addDoc(collection(db, 'plantas'), data);
      showToast('✅ Planta adicionada com sucesso!');
      clearForm();
    }
  } catch (e) {
    showToast('❌ Erro ao salvar: ' + e.message, true);
  }

  btn.disabled = false;
  document.getElementById('save-text').textContent = 'Salvar Planta';
};

function getVal(id) {
  return document.getElementById('field-' + id)?.value?.trim() || '';
}

function clearForm() {
  document.querySelectorAll('input[type="text"]').forEach(el => el.value = '');
  QUILL_FIELDS.forEach(field => { if (quillEditors[field]) quillEditors[field].setText(''); });
  window._chips = [];
  renderChips();
  window._imagensExtras = [];
  if (typeof window.renderExtraImgs === 'function') window.renderExtraImgs();
  document.getElementById('img-preview').style.display = 'none';
  document.getElementById('img-success').style.display = 'none';
  document.getElementById('img-upload-zone').classList.remove('has-file');
  document.getElementById('model-name').textContent = 'Selecionar arquivo .glb';
  document.getElementById('model-sub').textContent = 'Clique para escolher';
  document.getElementById('model-icon').textContent = '🧊';
  document.getElementById('model-upload-widget').classList.remove('has-file');
  document.getElementById('model-success').style.display = 'none';
  updateProgress();
}

// ── UPLOADS CLOUDINARY ────────────────────────────────────
window.handleImageSelect = async function () {
  const file = document.getElementById('img-input').files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = e => {
    const prev = document.getElementById('img-preview');
    prev.src = e.target.result;
    prev.style.display = 'block';
  };
  reader.readAsDataURL(file);

  const progressWrap = document.getElementById('img-progress-wrap');
  const progressFill = document.getElementById('img-progress-fill');
  const progressPct = document.getElementById('img-pct');
  const successEl = document.getElementById('img-success');
  progressWrap.style.display = 'block';
  successEl.style.display = 'none';

  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', CLOUDINARY_PRESET);

  const xhr = new XMLHttpRequest();
  xhr.open('POST', `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/image/upload`);
  xhr.upload.onprogress = (e) => {
    const pct = Math.round((e.loaded / e.total) * 100);
    progressFill.style.width = pct + '%';
    progressPct.textContent = pct + '%';
  };
  xhr.onload = () => {
    progressWrap.style.display = 'none';
    const res = JSON.parse(xhr.responseText);
    if (res.secure_url) {
      document.getElementById('field-imagemUrl').value = res.secure_url;
      document.getElementById('img-upload-zone').classList.add('has-file');
      successEl.style.display = 'flex';
      showToast('📷 Imagem enviada!');
    } else {
      showToast('Erro no upload da imagem.', true);
    }
  };
  xhr.onerror = () => { progressWrap.style.display = 'none'; showToast('Erro de rede no upload.', true); };
  xhr.send(formData);
};

window._imagensExtras = [];
window.renderExtraImgs = function () {
  const g = document.getElementById('extras-gallery');
  if (!g) return;
  g.innerHTML = '';
  window._imagensExtras.forEach((url, i) => {
    const div = document.createElement('div');
    div.style.cssText = 'position:relative;width:84px;height:84px;border-radius:8px;overflow:hidden;border:2px solid var(--gray-200)';
    div.innerHTML = `
      <img src="${url}" style="width:100%;height:100%;object-fit:cover;" />
      <div onclick="removeExtraImg(${i})" style="position:absolute;top:2px;right:2px;background:var(--red);color:white;border-radius:50%;width:20px;height:20px;text-align:center;line-height:18px;font-size:14px;cursor:pointer;font-weight:bold;" title="Remover">×</div>
      <div style="position:absolute;bottom:0;left:0;right:0;background:rgba(0,0,0,0.7);display:flex;justify-content:space-between;padding:4px;align-items:center;">
        <div style="display:flex;gap:6px;">
          ${i > 0 ? `<div onclick="moveExtraImg(${i},-1)" style="cursor:pointer;color:white;font-size:14px;">◀</div>` : '<div style="width:14px;"></div>'}
          ${i < window._imagensExtras.length - 1 ? `<div onclick="moveExtraImg(${i},1)" style="cursor:pointer;color:white;font-size:14px;">▶</div>` : '<div style="width:14px;"></div>'}
        </div>
        <div onclick="makeMainImg(${i})" style="cursor:pointer;font-size:14px;" title="Tornar principal">⭐</div>
      </div>
    `;
    g.appendChild(div);
  });
};

window.moveExtraImg = function (idx, dir) {
  const arr = window._imagensExtras;
  const target = idx + dir;
  if (target >= 0 && target < arr.length) {
    [arr[idx], arr[target]] = [arr[target], arr[idx]];
    window.renderExtraImgs();
    updateProgress();
  }
};

window.makeMainImg = function (idx) {
  const mainField = document.getElementById('field-imagemUrl');
  const currentMain = mainField.value;
  const newMain = window._imagensExtras[idx];
  mainField.value = newMain;
  document.getElementById('img-preview').src = newMain;
  document.getElementById('img-preview').style.display = 'block';
  document.getElementById('img-upload-zone').classList.add('has-file');
  document.getElementById('img-success').style.display = 'flex';
  if (currentMain) {
    window._imagensExtras[idx] = currentMain;
  } else {
    window._imagensExtras.splice(idx, 1);
  }
  window.renderExtraImgs();
  updateProgress();
  showToast('⭐ Definida como Principal!');
};

window.removeExtraImg = function (idx) {
  window._imagensExtras.splice(idx, 1);
  window.renderExtraImgs();
  updateProgress();
};

window.handleExtrasSelect = async function () {
  const files = document.getElementById('extras-input').files;
  if (!files.length) return;

  const progressWrap = document.getElementById('extras-progress-wrap');
  const progressFill = document.getElementById('extras-progress-fill');
  const progressPct = document.getElementById('extras-pct');
  progressWrap.style.display = 'block';
  let totalFiles = files.length;
  let uploadedCount = 0;
  progressFill.style.width = '0%';
  progressPct.textContent = '0%';

  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    const formData = new FormData();
    formData.append('file', file);
    formData.append('upload_preset', CLOUDINARY_PRESET);
    try {
      const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/image/upload`, { method: 'POST', body: formData });
      const data = await res.json();
      if (data.secure_url) {
        window._imagensExtras.push(data.secure_url);
        uploadedCount++;
        const pct = Math.round((uploadedCount / totalFiles) * 100);
        progressFill.style.width = pct + '%';
        progressPct.textContent = pct + '%';
      }
    } catch (e) {
      showToast('Erro ao subir imagem extra', true);
    }
  }
  setTimeout(() => {
    progressWrap.style.display = 'none';
    progressFill.style.width = '0%';
    window.renderExtraImgs();
    updateProgress();
    document.getElementById('extras-input').value = '';
    showToast('📷 Fotos extras enviadas!');
  }, 500);
};

window.handleModelSelect = async function () {
  const file = document.getElementById('model-input').files[0];
  if (!file) return;
  document.getElementById('model-name').textContent = file.name;
  document.getElementById('model-sub').textContent = (file.size / 1024 / 1024).toFixed(1) + ' MB';

  const progressWrap = document.getElementById('model-progress-wrap');
  const progressFill = document.getElementById('model-progress-fill');
  const progressPct = document.getElementById('model-pct');
  const successEl = document.getElementById('model-success');
  progressWrap.style.display = 'block';
  successEl.style.display = 'none';

  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', CLOUDINARY_PRESET);

  const xhr = new XMLHttpRequest();
  xhr.open('POST', `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/raw/upload`);
  xhr.upload.onprogress = (e) => {
    const pct = Math.round((e.loaded / e.total) * 100);
    progressFill.style.width = pct + '%';
    progressPct.textContent = pct + '%';
  };
  xhr.onload = () => {
    progressWrap.style.display = 'none';
    const res = JSON.parse(xhr.responseText);
    if (res.secure_url) {
      document.getElementById('field-modelo3dUrl').value = res.secure_url;
      document.getElementById('model-upload-widget').classList.add('has-file');
      document.getElementById('model-icon').textContent = '✅';
      successEl.style.display = 'flex';
      showToast('🧊 Modelo 3D enviado!');
    } else {
      showToast('Erro no upload do modelo.', true);
    }
  };
  xhr.onerror = () => { progressWrap.style.display = 'none'; showToast('Erro de rede.', true); };
  xhr.send(formData);
};

window.handleAudioSelect = async function () {
  const file = document.getElementById('audio-input').files[0];
  if (!file) return;
  document.getElementById('audio-name').textContent = file.name;
  document.getElementById('audio-sub').textContent = (file.size / 1024 / 1024).toFixed(1) + ' MB';

  const progressWrap = document.getElementById('audio-progress-wrap');
  const progressFill = document.getElementById('audio-progress-fill');
  const progressPct = document.getElementById('audio-pct');
  const successEl = document.getElementById('audio-success');
  progressWrap.style.display = 'block';
  successEl.style.display = 'none';

  const formData = new FormData();
  formData.append('file', file);
  formData.append('upload_preset', CLOUDINARY_PRESET);

  const xhr = new XMLHttpRequest();
  xhr.open('POST', `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD}/video/upload`);
  xhr.upload.onprogress = (e) => {
    const pct = Math.round((e.loaded / e.total) * 100);
    progressFill.style.width = pct + '%';
    progressPct.textContent = pct + '%';
  };
  xhr.onload = () => {
    progressWrap.style.display = 'none';
    const res = JSON.parse(xhr.responseText);
    if (res.secure_url) {
      document.getElementById('field-audioUrl').value = res.secure_url;
      document.getElementById('audio-upload-widget').classList.add('has-file');
      document.getElementById('audio-icon').textContent = '✅';
      successEl.style.display = 'flex';
      showToast('🎧 Áudio enviado!');
    } else {
      showToast('Erro no upload do áudio.', true);
    }
  };
  xhr.onerror = () => { progressWrap.style.display = 'none'; showToast('Erro de rede.', true); };
  xhr.send(formData);
};

// ── HELPERS ───────────────────────────────────────────────
function showApp() {
  document.getElementById('login-screen').style.display = 'none';
  document.getElementById('app-screen').style.display = 'block';
  document.getElementById('mode-badge').textContent = plantaId ? 'Editar Planta' : 'Nova Planta';
}

function showLogin() {
  document.getElementById('login-screen').style.display = 'flex';
  document.getElementById('app-screen').style.display = 'none';
  document.getElementById('btn-login').disabled = false;
  document.getElementById('login-text').textContent = 'Entrar';
}

let toastTimer;
window.showToast = function (msg, isError = false) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = isError ? 'error show' : 'show';
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.className = '', 3500);
};

window.toggleSection = function (header) {
  const body = header.nextElementSibling;
  const toggle = header.querySelector('.section-toggle');
  const open = body.classList.toggle('open');
  toggle.classList.toggle('open', open);
};

// ── CHIPS / KEYWORDS ──────────────────────────────────────
window._chips = [];

window.addChipValue = function (val) {
  const v = val.trim().toLowerCase();
  if (!v || window._chips.includes(v)) return;
  window._chips.push(v);
  renderChips();
};

window.addChip = function () {
  const input = document.getElementById('keyword-input');
  addChipValue(input.value);
  input.value = '';
  input.focus();
  updateProgress();
};

document.getElementById('keyword-input').addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ',') { e.preventDefault(); addChip(); }
});

function renderChips() {
  const container = document.getElementById('chips-container');
  container.innerHTML = '';
  window._chips.forEach((chip, i) => {
    const el = document.createElement('div');
    el.className = 'chip';
    el.innerHTML = `#${chip} <span class="chip-remove" onclick="removeChip(${i})">×</span>`;
    container.appendChild(el);
  });
}

window.removeChip = function (i) {
  window._chips.splice(i, 1);
  renderChips();
  updateProgress();
};

// ── BARRA DE PROGRESSO ────────────────────────────────────
const TRACKED_INPUT_FIELDS = [
  'field-nome', 'field-nomeCientifico', 'field-descricaoCurta',
  'field-referenciasFarmacologicas', 'field-referenciaGeral',
  'field-imagemUrl', 'field-modelo3dUrl', 'field-audioUrl',
];

window.updateProgress = function () {
  let filled = 0;
  const totalFields = TRACKED_INPUT_FIELDS.length + QUILL_FIELDS.length + 1;
  TRACKED_INPUT_FIELDS.forEach(id => { if (document.getElementById(id)?.value?.trim()) filled++; });
  QUILL_FIELDS.forEach(field => { if (getQuillHtml(field)) filled++; });
  if (window._chips.length > 0) filled++;
  const pct = Math.round((filled / totalFields) * 100);
  document.getElementById('progress-fill').style.width = pct + '%';
  document.getElementById('progress-pct').textContent = pct + '%';
};
