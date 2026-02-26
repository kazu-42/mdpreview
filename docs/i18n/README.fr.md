# MDPreview

Une application legere et rapide de previsualisation Markdown pour macOS. Concue pour les developpeurs qui ont besoin de previsualiser rapidement `plan.md`, `README.md` et autres fichiers Markdown depuis le terminal.

[English](../../README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [简体中文](README.zh-CN.md)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml/badge.svg)](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml)

<p align="center">
  <img src="Assets/AppIcon.png" alt="MDPreview Icon" width="128">
</p>

## Fonctionnalites

- **Demarrage rapide** - Application macOS native, s'ouvre instantanement
- **Support complet GFM** - Tableaux, listes de taches, texte barre, liens automatiques
- **Coloration syntaxique** - Plus de 40 langages de programmation via [highlight.js](https://highlightjs.org/)
- **Rechargement en direct** - Actualisation automatique lors des modifications du fichier sur le disque
- **Onglets** - Ouvrez plusieurs fichiers en onglets, basculez avec Cmd+Shift+] / [
- **Barre laterale arborescence** - Ouvrez un repertoire pour parcourir et previsualiser les fichiers Markdown
- **Mode sombre/clair** - Suit l'apparence systeme de macOS
- **Compatible CLI** - `mdpreview fichier.md` se lance instantanement, revient au terminal
- **Zero dependance** - Aucun package Swift externe
- **Leger** - Binaire ~200Ko + ~160Ko JS/CSS integres

## Installation

### Homebrew

```bash
brew install --cask kazu-42/tap/mdpreview
```

### Telechargement

Telechargez le dernier `.dmg` ou `.zip` depuis la page [Releases](https://github.com/kazu-42/mdpreview/releases).

Apres installation, ouvrez l'application et allez dans **MDPreview > Install Command Line Tool...** pour configurer la commande `mdpreview`.

### Compiler depuis les sources

```bash
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# Compiler et creer le bundle .app
make all

# Installer dans /Applications
make install

# Installer le CLI (necessite sudo)
sudo make cli
```

## Utilisation

### Depuis le terminal

```bash
# Ouvrir un fichier Markdown
mdpreview README.md

# Ouvrir plusieurs fichiers en onglets
mdpreview fichier1.md fichier2.md

# Ouvrir un repertoire avec la barre laterale
mdpreview .
mdpreview ~/projects/mon-app/

# Lancer l'application sans arguments
mdpreview
```

### Depuis Finder

- **Glisser-deposer** un fichier `.md` sur la fenetre MDPreview ou l'icone du Dock
- **Clic droit** sur un fichier `.md` > Ouvrir avec > MDPreview
- Utilisez **Cmd+O** pour ouvrir un fichier ou repertoire depuis le menu

### Raccourcis clavier

| Raccourci | Action |
|-----------|--------|
| `Cmd+O` | Ouvrir fichier / repertoire |
| `Cmd+W` | Fermer onglet / fenetre |
| `Cmd+Shift+]` | Onglet suivant |
| `Cmd+Shift+[` | Onglet precedent |
| `Ctrl+Tab` | Onglet suivant |
| `Cmd+Q` | Quitter |

## Captures d'ecran

### Mode clair
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-light" alt="Mode clair" width="600">
</p>

### Mode sombre
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-dark" alt="Mode sombre" width="600">
</p>

## Fonctionnement

MDPreview utilise une interface SwiftUI minimale avec un `WKWebView` pour le rendu. Le pipeline de rendu est :

```
Fichier Markdown sur disque
  -> Swift lit le contenu du fichier
    -> Transmet a WKWebView
      -> marked.js convertit en HTML (GFM)
        -> highlight.js colore les blocs de code
          -> Styles CSS pour mode sombre/clair
```

Les modifications de fichiers sont detectees grace a la surveillance du systeme de fichiers via `DispatchSource` de GCD, avec un debouncing pour gerer les sauvegardes rapides.

## Architecture

```
Sources/
├── MDPreviewCore/            # Bibliotheque principale
│   ├── MDPreviewApp.swift    # Scene App SwiftUI + commandes
│   ├── AppDelegate.swift     # Integration Finder/CLI
│   ├── Workspace.swift       # Gestion onglets + etat
│   ├── MainView.swift        # Disposition : barre laterale + onglets + previsualisation
│   ├── FileTree.swift        # Modele arborescence + vue
│   ├── MarkdownWebView.swift # Wrapper WKWebView
│   ├── FileWatcher.swift     # Moniteur de fichiers DispatchSource
│   ├── CLIInstaller.swift    # Installateur outil ligne de commande
│   └── Resources/
│       ├── template.html     # Shell de rendu HTML
│       ├── marked.min.js     # Analyseur Markdown (GFM)
│       ├── highlight.min.js  # Coloration syntaxique
│       └── *.css             # Themes style GitHub
└── MDPreview/
    └── main.swift            # Point d'entree
```

## Configuration requise

- macOS 13.0 (Ventura) ou superieur
- Mac Apple Silicon ou Intel

### Configuration pour la compilation

- Xcode 15.0+ ou toolchain Swift 5.9+
- Aucune dependance supplementaire requise

## Contribuer

Les contributions sont les bienvenues ! Consultez [CONTRIBUTING.md](CONTRIBUTING.md) pour les directives.

Veuillez noter que ce projet suit un [Code de conduite](CODE_OF_CONDUCT.md).

## Securite

Pour signaler une vulnerabilite de securite, veuillez consulter notre [Politique de securite](SECURITY.md).

## Remerciements

- [marked.js](https://github.com/markedjs/marked) - Analyseur Markdown
- [highlight.js](https://github.com/highlightjs/highlight.js) - Coloration syntaxique
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - Inspiration UI/UX

## Licence

[Licence MIT](LICENSE) - voir [LICENSE](LICENSE) pour plus de details.
