# 🌿 BADERNA

> **B**ase de **A**poio para **D**ados **E**tnobotânicos de **R**ecursos **N**aturais da **A**mazônia

Aplicativo mobile desenvolvido em **Flutter** com backend em **Firebase**, focado em catalogar e disponibilizar informações sobre plantas medicinais e espécies da flora amazônica — com suporte a visualização 3D, dados científicos e referências bibliográficas.

---

## ✨ Funcionalidades

- 📋 **Catálogo de Plantas** — listagem completa com imagens, nome popular e descrição curta
- 🔍 **Busca Inteligente** — pesquisa por nome em tempo real
- 🌿 **Aba Geral** — descrição simples, benefícios, modo de uso, cuidados e nível de evidência científica
- 🔬 **Aba Científica** — composição química, propriedades farmacológicas e estudos clínicos
- 📚 **Aba Referências** — referências gerais e científicas com links e DOI/PMID
- 🧊 **Visualização 3D** — modelos GLB/GLTF interativos com rotação automática
- 🔐 **Autenticação** — login com Google
- 🛠️ **Painel Admin** — gerenciamento de plantas (adicionar, editar, excluir)
- 💡 **Sugestões** — tela para envio de sugestões de novas plantas

---

## 🛠️ Tecnologias

| Camada | Tecnologia |
|---|---|
| **Front-end / Mobile** | [Flutter](https://flutter.dev) + Dart |
| **Banco de Dados** | [Cloud Firestore](https://firebase.google.com/products/firestore) |
| **Autenticação** | [Firebase Auth](https://firebase.google.com/products/auth) + Google Sign-In |
| **Armazenamento de Imagens** | [Cloudinary](https://cloudinary.com) |
| **Modelos 3D** | [model_viewer_plus](https://pub.dev/packages/model_viewer_plus) |
| **Links Externos** | [url_launcher](https://pub.dev/packages/url_launcher) |

---

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                   # Ponto de entrada, inicialização Firebase
├── firebase_options.dart       # Configurações Firebase por plataforma
├── screens/
│   ├── home_screen.dart        # Tela principal (lista de plantas)
│   ├── detail_screen.dart      # Detalhes da planta (abas Geral/Científico/Referências)
│   ├── login_screen.dart       # Login com Google
│   ├── admin_login_screen.dart # Login administrativo
│   ├── admin_panel_screen.dart # Painel de administração
│   ├── manage_plants_screen.dart  # Gerenciamento de plantas
│   ├── edit_plant_screen.dart  # Edição de planta
│   ├── manage_admins_screen.dart  # Gerenciamento de admins
│   └── suggestions_screen.dart # Tela de sugestões
└── widgets/
    ├── side_menu.dart          # Menu lateral (drawer)
    └── plant_search_delegate.dart # Delegado de busca
```

---

## 🚀 Como Rodar

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado
- Conta no Firebase com projeto configurado
- Arquivo `google-services.json` (Android) e `GoogleService-Info.plist` (iOS) adicionados

### Instalação

```bash
# Clone o repositório
git clone https://github.com/sethssd/BADERNA.git
cd BADERNA

# Instale as dependências
flutter pub get
```

### Executar

```bash
# Modo debug
flutter run

# Modo release no emulador
flutter run --release

# Gerar APK
flutter build apk

# Gerar APK por splits de ABI (menor tamanho)
flutter build apk --split-per-abi
```

---

## 🔥 Configuração do Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
2. Ative o **Cloud Firestore**, **Firebase Authentication** e o provedor **Google**
3. Baixe o `google-services.json` e coloque em `android/app/`
4. Configure as regras do Firestore conforme necessidade do projeto
5. Renomeie `firebase_options.dart.example` para `firebase_options.dart` e preencha com suas credenciais

---

## 🗂️ Estrutura do Firestore

Coleção `plantas` — cada documento representa uma planta com os seguintes campos principais:

| Campo | Tipo | Descrição |
|---|---|---|
| `nome` | String | Nome popular da planta |
| `descricaoCurta` | String | Resumo exibido na lista |
| `descricaoSimples` | String | Descrição para o público geral |
| `imagemUrl` | String | URL da imagem principal (Cloudinary) |
| `modelo3dUrl` | String | URL do modelo 3D (.glb/.gltf) |
| `beneficios` | Array | Lista de benefícios |
| `comoUsar` | String | Modo de preparo/uso |
| `cuidados` | Array | Avisos e contraindicações |
| `nivelEvidencia` | Number | Nível 1–5 de evidência científica |
| `composicaoQuimica` | Map | Compostos químicos identificados |
| `propriedadesFarmacologicas` | Array | Propriedades farmacológicas detalhadas |
| `referenciasCientificas` | Array | Referências estruturadas (título, autores, ano, DOI/PMID) |

---

## 📱 Plataformas Suportadas

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ Linux
- ✅ macOS

---

## 🤝 Contribuição

Contribuições são bem-vindas! Para sugerir uma nova planta ou funcionalidade:

1. Abra uma **Issue** descrevendo a sugestão
2. Faça um **Fork** do repositório
3. Crie uma branch: `git checkout -b feature/minha-feature`
4. Commit suas mudanças: `git commit -m 'feat: adiciona nova funcionalidade'`
5. Push: `git push origin feature/minha-feature`
6. Abra um **Pull Request**

---

## 📄 Licença

Este projeto está sob licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

<div align="center">
  Feito com 💚 para preservar o conhecimento sobre a flora amazônica
</div>
