# SUMAÙMA

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![MIT License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20Linux%20%7C%20macOS-lightgrey?style=for-the-badge)

<!-- IMAGEM: banner-sumauma.png -->
<!-- <div align="center"><img src="docs/images/banner.png" alt="Sumaúma Banner" width="100%"></div> -->

Aplicativo mobile desenvolvido em **Flutter** com backend em **Firebase**, focado em catalogar e disponibilizar informações sobre plantas medicinais e espécies da flora amazônica — com suporte a visualização 3D, dados científicos e referências bibliográficas.

---

## 📑 Sumário

- [Funcionalidades](#-funcionalidades)
- [Screenshots](#-screenshots)
- [Tecnologias](#-tecnologias)
- [Como rodar o projeto](#-como-rodar-o-projeto)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Plataformas Suportadas](#-plataformas-suportadas)
- [Contribuição](#-contribuição)
- [Licença](#-licença)

---

## ✨ Funcionalidades

-  **Catálogo de Plantas** — listagem completa com imagens, nome popular e descrição curta
-  **Busca Inteligente** — pesquisa por nome em tempo real
-  **Aba Geral** — descrição simples, benefícios, modo de uso, cuidados e nível de evidência científica
-  **Aba Científica** — composição química, propriedades farmacológicas e estudos clínicos
-  **Aba Referências** — referências gerais e científicas com links e DOI/PMID
-  **Visualização 3D** — modelos GLB/GLTF interativos com rotação automática

---

## 📱 Screenshots

| Tela Inicial | Detalhe da Planta | Aba Científica | Visualização 3D |
| :---: | :---: | :---: | :---: |
| <!-- <img src="docs/images/screenshot_home.png" width="200"> --> | <!-- <img src="docs/images/screenshot_detail.png" width="200"> --> | <!-- <img src="docs/images/screenshot_scientific.png" width="200"> --> | <!-- <img src="docs/images/screenshot_3d.png" width="200"> --> |
| _Placeholder_ | _Placeholder_ | _Placeholder_ | _Placeholder_ |

---

## 🛠 Tecnologias

| Camada | Tecnologia |
|---|---|
| **Front-end / Mobile** | [Flutter](https://flutter.dev) + Dart |
| **Banco de Dados** | [Cloud Firestore](https://firebase.google.com/products/firestore) |
| **Autenticação** | [Firebase Auth](https://firebase.google.com/products/auth) + Google Sign-In |
| **Armazenamento de Imagens** | [Cloudinary](https://cloudinary.com) |
| **Modelos 3D** | [model_viewer_plus](https://pub.dev/packages/model_viewer_plus) |
| **Links Externos** | [url_launcher](https://pub.dev/packages/url_launcher) |

---

## 🚀 Como rodar o projeto

Siga o passo a passo abaixo para rodar o projeto localmente:

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/seu-usuario/seu-repositorio.git
   cd seu-repositorio
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Configure as variáveis de ambiente:**
   - Crie um arquivo `.env` na raiz do projeto, usando o arquivo de exemplo como base:
     ```bash
     cp .env.example .env
     ```
   - Preencha as chaves necessárias no arquivo `.env`.

4. **Configure o Firebase:**
   - Configure o seu projeto no [Firebase Console](https://console.firebase.google.com/).
   - Tenha certeza de que o arquivo `lib/firebase_options.dart` está atualizado para o seu projeto, ou rode o [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/):
     ```bash
     flutterfire configure
     ```

5. **Rode o aplicativo:**
   - Para Web:
     ```bash
     flutter run -d chrome
     ```
   - Para Android (com emulador ou dispositivo conectado):
     ```bash
     flutter run
     ```
   - Para outras plataformas (macOS, Windows, Linux, iOS), certifique-se de que os requisitos de build estão instalados e use `flutter run -d <device>`.

---

## 📂 Estrutura do Projeto

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

_Arquivos de documentação adicionais estão localizados na pasta `docs/`._

---

## 🌍 Plataformas Suportadas

-  Android
-  iOS
-  Web
-  Windows
-  Linux
-  macOS

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
