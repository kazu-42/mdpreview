# MDPreview

Um aplicativo de preview Markdown leve e rapido para macOS. Criado para desenvolvedores que precisam visualizar rapidamente `plan.md`, `README.md` e outros arquivos Markdown pelo terminal.

[English](../../README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [简体中文](README.zh-CN.md)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml/badge.svg)](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml)

<p align="center">
  <img src="Assets/AppIcon.png" alt="MDPreview Icon" width="128">
</p>

## Funcionalidades

- **Inicializacao rapida** - Aplicativo nativo macOS, abre instantaneamente
- **Suporte completo a GFM** - Tabelas, listas de tarefas, tachado, autolinks
- **Destaque de sintaxe** - Mais de 40 linguagens de programacao via [highlight.js](https://highlightjs.org/)
- **Recarregamento automatico** - Atualiza automaticamente quando o arquivo muda no disco
- **Abas** - Abra varios arquivos como abas, alterne com Cmd+Shift+] / [
- **Barra lateral de arquivos** - Abra um diretorio para navegar e visualizar arquivos Markdown
- **Modo Escuro/Claro** - Segue a aparencia do sistema macOS
- **Compativel com CLI** - `mdpreview arquivo.md` abre instantaneamente, retorna ao terminal
- **Zero dependencias** - Sem pacotes Swift externos
- **Leve** - Binario de ~200KB + ~160KB de JS/CSS incluidos

## Instalacao

### Homebrew

```bash
brew install --cask kazu-42/tap/mdpreview
```

### Download

Baixe o `.dmg` ou `.zip` mais recente da pagina de [Releases](https://github.com/kazu-42/mdpreview/releases).

Apos instalar, abra o aplicativo e va em **MDPreview > Install Command Line Tool...** para configurar o comando `mdpreview`.

### Compilar do Codigo Fonte

```bash
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# Compilar e criar o pacote .app
make all

# Instalar em /Applications
make install

# Instalar CLI (requer sudo)
sudo make cli
```

## Uso

### Pelo Terminal

```bash
# Abrir um arquivo Markdown
mdpreview README.md

# Abrir varios arquivos como abas
mdpreview arquivo1.md arquivo2.md

# Abrir um diretorio com barra lateral de arquivos
mdpreview .
mdpreview ~/projetos/meu-app/

# Iniciar o aplicativo sem argumentos
mdpreview
```

### Pelo Finder

- **Arraste e solte** um arquivo `.md` na janela do MDPreview ou no icone do Dock
- **Clique com botao direito** em um arquivo `.md` > Abrir Com > MDPreview
- Use **Cmd+O** para abrir um arquivo ou diretorio pelo menu

### Atalhos de Teclado

| Atalho | Acao |
|--------|------|
| `Cmd+O` | Abrir arquivo / diretorio |
| `Cmd+W` | Fechar aba / janela |
| `Cmd+Shift+]` | Proxima aba |
| `Cmd+Shift+[` | Aba anterior |
| `Ctrl+Tab` | Proxima aba |
| `Cmd+Q` | Sair |

## Capturas de Tela

### Modo Claro
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-light" alt="Modo Claro" width="600">
</p>

### Modo Escuro
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-dark" alt="Modo Escuro" width="600">
</p>

## Como Funciona

O MDPreview usa uma interface SwiftUI minimalista com um `WKWebView` para renderizacao. O pipeline de renderizacao e:

```
Arquivo Markdown no disco
  -> Swift le o conteudo do arquivo
    -> Passa para WKWebView
      -> marked.js converte para HTML (GFM)
        -> highlight.js coloriza blocos de codigo
          -> CSS estiliza para modo escuro/claro
```

As alteracoes de arquivo sao detectadas usando o monitoramento de sistema de arquivos `DispatchSource` do GCD, com debounce para lidar com salvamentos rapidos.

## Arquitetura

```
Sources/
├── MDPreviewCore/            # Biblioteca principal
│   ├── MDPreviewApp.swift    # Cena SwiftUI App + comandos
│   ├── AppDelegate.swift     # Integracao Finder/CLI
│   ├── Workspace.swift       # Gerenciamento de abas + estado
│   ├── MainView.swift        # Layout: sidebar + abas + preview
│   ├── FileTree.swift        # Modelo de arvore de diretorios + view
│   ├── MarkdownWebView.swift # Wrapper WKWebView
│   ├── FileWatcher.swift     # Monitor de arquivo DispatchSource
│   ├── CLIInstaller.swift    # Instalador da ferramenta de linha de comando
│   └── Resources/
│       ├── template.html     # Shell de renderizacao HTML
│       ├── marked.min.js     # Parser Markdown (GFM)
│       ├── highlight.min.js  # Destaque de sintaxe
│       └── *.css             # Temas estilo GitHub
└── MDPreview/
    └── main.swift            # Ponto de entrada
```

## Requisitos

- macOS 13.0 (Ventura) ou posterior
- Mac com Apple Silicon ou Intel

### Requisitos de Build

- Xcode 15.0+ ou toolchain Swift 5.9+
- Nenhuma dependencia adicional necessaria

## Contribuindo

Contribuicoes sao bem-vindas! Veja [CONTRIBUTING.md](CONTRIBUTING.md) para diretrizes.

Por favor, note que este projeto segue um [Codigo de Conduta](CODE_OF_CONDUCT.md).

## Seguranca

Para reportar uma vulnerabilidade de seguranca, consulte nossa [Politica de Seguranca](SECURITY.md).

## Agradecimentos

- [marked.js](https://github.com/markedjs/marked) - Parser Markdown
- [highlight.js](https://github.com/highlightjs/highlight.js) - Destaque de sintaxe
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - Inspiracao de UI/UX

## Licenca

[Licenca MIT](LICENSE) - veja [LICENSE](LICENSE) para detalhes.
