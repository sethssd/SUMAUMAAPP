# SUMAÙMA


Aplicativo mobile desenvolvido em **Flutter** com backend em **Firebase**, focado em catalogar e disponibilizar informações sobre plantas medicinais e espécies da flora amazônica — com suporte a visualização 3D, dados científicos e referências bibliográficas.

---

##  Funcionalidades

-  **Catálogo de Plantas** — listagem completa com imagens, nome popular e descrição curta
-  **Busca Inteligente** — pesquisa por nome em tempo real
-  **Aba Geral** — descrição simples, benefícios, modo de uso, cuidados e nível de evidência científica
-  **Aba Científica** — composição química, propriedades farmacológicas e estudos clínicos
-  **Aba Referências** — referências gerais e científicas com links e DOI/PMID
-  **Visualização 3D** — modelos GLB/GLTF interativos com rotação automática


---

##  Tecnologias

| Camada | Tecnologia |
|---|---|
| **Front-end / Mobile** | [Flutter](https://flutter.dev) + Dart |
| **Banco de Dados** | [Cloud Firestore](https://firebase.google.com/products/firestore) |
| **Autenticação** | [Firebase Auth](https://firebase.google.com/products/auth) + Google Sign-In |
| **Armazenamento de Imagens** | [Cloudinary](https://cloudinary.com) |
| **Modelos 3D** | [model_viewer_plus](https://pub.dev/packages/model_viewer_plus) |
| **Links Externos** | [url_launcher](https://pub.dev/packages/url_launcher) |

---

##  Estrutura do Projeto

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


##  Plataformas Suportadas

-  Android
-  iOS
-  Web
-  Windows
-  Linux
-  macOS

---

##  Contribuição

Contribuições são bem-vindas! Para sugerir uma nova planta ou funcionalidade:

1. Abra uma **Issue** descrevendo a sugestão
2. Faça um **Fork** do repositório
3. Crie uma branch: `git checkout -b feature/minha-feature`
4. Commit suas mudanças: `git commit -m 'feat: adiciona nova funcionalidade'`
5. Push: `git push origin feature/minha-feature`
6. Abra um **Pull Request**

---

##  Licença

Este projeto está sob licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

<div align="center">
  Feito com 💚 para preservar o conhecimento sobre a flora amazônica
</div>
