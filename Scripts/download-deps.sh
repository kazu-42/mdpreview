#!/bin/bash
set -euo pipefail

RESOURCES="Sources/MDPreview/Resources"
mkdir -p "$RESOURCES"

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

echo "Dependencies downloaded to $RESOURCES"
