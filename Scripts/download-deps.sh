#!/bin/bash
set -euo pipefail

RESOURCES="Sources/MDPreviewCore/Resources"
mkdir -p "$RESOURCES"
mkdir -p "$RESOURCES/fonts"

echo "Downloading marked.js..."
curl -sL "https://cdn.jsdelivr.net/npm/marked/marked.min.js" -o "$RESOURCES/marked.min.js"

echo "Downloading highlight.js..."
curl -sL "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js" \
     -o "$RESOURCES/highlight.min.js"

echo "Downloading highlight.js themes..."
curl -sL "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css" \
     -o "$RESOURCES/github.min.css"
curl -sL "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github-dark.min.css" \
     -o "$RESOURCES/github-dark.min.css"

KATEX_VERSION="0.16.21"
echo "Downloading KaTeX ${KATEX_VERSION}..."
curl -sL "https://cdn.jsdelivr.net/npm/katex@${KATEX_VERSION}/dist/katex.min.js" \
     -o "$RESOURCES/katex.min.js"
curl -sL "https://cdn.jsdelivr.net/npm/katex@${KATEX_VERSION}/dist/katex.min.css" \
     -o "$RESOURCES/katex.min.css"
curl -sL "https://cdn.jsdelivr.net/npm/katex@${KATEX_VERSION}/dist/contrib/auto-render.min.js" \
     -o "$RESOURCES/auto-render.min.js"

echo "Downloading KaTeX fonts..."
KATEX_FONTS=(
    "KaTeX_AMS-Regular"
    "KaTeX_Caligraphic-Bold"
    "KaTeX_Caligraphic-Regular"
    "KaTeX_Fraktur-Bold"
    "KaTeX_Fraktur-Regular"
    "KaTeX_Main-Bold"
    "KaTeX_Main-BoldItalic"
    "KaTeX_Main-Italic"
    "KaTeX_Main-Regular"
    "KaTeX_Math-BoldItalic"
    "KaTeX_Math-Italic"
    "KaTeX_SansSerif-Bold"
    "KaTeX_SansSerif-Italic"
    "KaTeX_SansSerif-Regular"
    "KaTeX_Script-Regular"
    "KaTeX_Size1-Regular"
    "KaTeX_Size2-Regular"
    "KaTeX_Size3-Regular"
    "KaTeX_Size4-Regular"
    "KaTeX_Typewriter-Regular"
)
for FONT in "${KATEX_FONTS[@]}"; do
    curl -sL "https://cdn.jsdelivr.net/npm/katex@${KATEX_VERSION}/dist/fonts/${FONT}.woff2" \
         -o "$RESOURCES/fonts/${FONT}.woff2"
done

MERMAID_VERSION="11.4.1"
echo "Downloading Mermaid ${MERMAID_VERSION}..."
curl -sL "https://cdn.jsdelivr.net/npm/mermaid@${MERMAID_VERSION}/dist/mermaid.min.js" \
     -o "$RESOURCES/mermaid.min.js"

echo "Dependencies downloaded to $RESOURCES"
