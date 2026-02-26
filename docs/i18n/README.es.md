# MDPreview

Una aplicacion ligera y rapida para previsualizar Markdown en macOS. Creada para desarrolladores que necesitan previsualizar rapidamente archivos `plan.md`, `README.md` y otros archivos Markdown desde la terminal.

[English](../../README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [简体中文](README.zh-CN.md)

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![CI](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml/badge.svg)](https://github.com/kazu-42/mdpreview/actions/workflows/ci.yml)

<p align="center">
  <img src="Assets/AppIcon.png" alt="Icono de MDPreview" width="128">
</p>

## Caracteristicas

- **Inicio rapido** - Aplicacion nativa de macOS, se abre instantaneamente
- **Soporte completo de GFM** - Tablas, listas de tareas, tachado, enlaces automaticos
- **Resaltado de sintaxis** - Mas de 40 lenguajes de programacion via [highlight.js](https://highlightjs.org/)
- **Recarga en vivo** - Se actualiza automaticamente cuando el archivo cambia en disco
- **Pestanas** - Abre multiples archivos como pestanas, cambia con Cmd+Shift+] / [
- **Barra lateral de arbol de archivos** - Abre un directorio para explorar y previsualizar archivos Markdown
- **Modo oscuro/claro** - Sigue la apariencia del sistema macOS
- **Compatible con CLI** - `mdpreview archivo.md` se inicia instantaneamente, regresa a la terminal
- **Cero dependencias** - Sin paquetes Swift externos
- **Ligero** - Binario de ~200KB + ~160KB de JS/CSS incluido

## Instalacion

### Homebrew

```bash
brew install --cask kazu-42/tap/mdpreview
```

### Descarga

Descarga el ultimo `.dmg` o `.zip` desde la pagina de [Releases](https://github.com/kazu-42/mdpreview/releases).

Despues de instalar, abre la aplicacion y ve a **MDPreview > Install Command Line Tool...** para configurar el comando `mdpreview`.

### Compilar desde el codigo fuente

```bash
git clone https://github.com/kazu-42/mdpreview.git
cd mdpreview

# Compilar y crear el bundle .app
make all

# Instalar en /Applications
make install

# Instalar CLI (requiere sudo)
sudo make cli
```

## Uso

### Desde la terminal

```bash
# Abrir un archivo Markdown
mdpreview README.md

# Abrir multiples archivos como pestanas
mdpreview archivo1.md archivo2.md

# Abrir un directorio con la barra lateral de arbol de archivos
mdpreview .
mdpreview ~/projects/mi-app/

# Iniciar la aplicacion sin argumentos
mdpreview
```

### Desde Finder

- **Arrastra y suelta** un archivo `.md` sobre la ventana de MDPreview o el icono del Dock
- **Clic derecho** en un archivo `.md` > Abrir con > MDPreview
- Usa **Cmd+O** para abrir un archivo o directorio desde el menu

### Atajos de teclado

| Atajo | Accion |
|-------|--------|
| `Cmd+O` | Abrir archivo / directorio |
| `Cmd+W` | Cerrar pestana / ventana |
| `Cmd+Shift+]` | Siguiente pestana |
| `Cmd+Shift+[` | Pestana anterior |
| `Ctrl+Tab` | Siguiente pestana |
| `Cmd+Q` | Salir |

## Capturas de pantalla

### Modo claro
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-light" alt="Modo claro" width="600">
</p>

### Modo oscuro
<p align="center">
  <img src="https://github.com/user-attachments/assets/placeholder-dark" alt="Modo oscuro" width="600">
</p>

## Como funciona

MDPreview usa una interfaz minima de SwiftUI con un `WKWebView` para el renderizado. El flujo de renderizado es:

```
Archivo Markdown en disco
  → Swift lee el contenido del archivo
    → Lo pasa a WKWebView
      → marked.js convierte a HTML (GFM)
        → highlight.js colorea los bloques de codigo
          → Estilos CSS para modo oscuro/claro
```

Los cambios en los archivos se detectan usando el monitoreo del sistema de archivos `DispatchSource` de GCD, con debounce para manejar guardados rapidos.

## Arquitectura

```
Sources/
├── MDPreviewCore/            # Libreria principal
│   ├── MDPreviewApp.swift    # Escena SwiftUI App + comandos
│   ├── AppDelegate.swift     # Integracion con Finder/CLI
│   ├── Workspace.swift       # Gestion de pestanas + estado
│   ├── MainView.swift        # Diseno: barra lateral + pestanas + vista previa
│   ├── FileTree.swift        # Modelo de arbol de directorios + vista
│   ├── MarkdownWebView.swift # Wrapper de WKWebView
│   ├── FileWatcher.swift     # Monitor de archivos DispatchSource
│   ├── CLIInstaller.swift    # Instalador de herramienta de linea de comandos
│   └── Resources/
│       ├── template.html     # Shell de renderizado HTML
│       ├── marked.min.js     # Parser Markdown (GFM)
│       ├── highlight.min.js  # Resaltado de sintaxis
│       └── *.css             # Temas estilo GitHub
└── MDPreview/
    └── main.swift            # Punto de entrada
```

## Requisitos

- macOS 13.0 (Ventura) o posterior
- Mac con Apple Silicon o Intel

### Requisitos de compilacion

- Xcode 15.0+ o toolchain Swift 5.9+
- No se requieren dependencias adicionales

## Contribuir

!Las contribuciones son bienvenidas! Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para las directrices.

Ten en cuenta que este proyecto sigue un [Codigo de conducta](CODE_OF_CONDUCT.md).

## Seguridad

Para reportar una vulnerabilidad de seguridad, consulta nuestra [Politica de seguridad](SECURITY.md).

## Agradecimientos

- [marked.js](https://github.com/markedjs/marked) - Parser Markdown
- [highlight.js](https://github.com/highlightjs/highlight.js) - Resaltado de sintaxis
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) - Inspiracion de UI/UX

## Licencia

[Licencia MIT](LICENSE) - consulta [LICENSE](LICENSE) para mas detalles.
