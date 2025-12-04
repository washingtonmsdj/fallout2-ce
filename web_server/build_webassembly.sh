#!/bin/bash
# Script para compilar Fallout 2 para WebAssembly
# 
# PRÉ-REQUISITOS:
#   1. Emscripten instalado e ativado
#   2. CMake instalado
#   3. Assets do Fallout 2 na pasta "Fallout 2/"

set -e

echo "=========================================="
echo "🔧 Compilando Fallout 2 para WebAssembly"
echo "=========================================="

# Verificar se Emscripten está instalado
if ! command -v emcc &> /dev/null; then
    echo "❌ Emscripten não encontrado!"
    echo "   Instale em: https://emscripten.org/docs/getting_started/downloads.html"
    exit 1
fi

echo "✅ Emscripten encontrado: $(emcc --version | head -n 1)"

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-web"
FALLOUT_DIR="$PROJECT_ROOT/Fallout 2"

# Verificar se os assets existem
if [ ! -d "$FALLOUT_DIR" ]; then
    echo "⚠️  Pasta 'Fallout 2' não encontrada!"
    echo "   Certifique-se de que os assets do jogo estão em: $FALLOUT_DIR"
    read -p "   Continuar mesmo assim? (s/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Criar diretório de build
echo ""
echo "📁 Criando diretório de build..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configurar CMake
echo ""
echo "⚙️  Configurando CMake..."
emcmake cmake "$PROJECT_ROOT" \
    -DCMAKE_BUILD_TYPE=Release \
    -DFALLOUT_VENDORED=OFF

# Compilar
echo ""
echo "🔨 Compilando (isso pode levar vários minutos)..."
emmake make -j$(nproc 2>/dev/null || echo 4)

# Verificar se compilou
if [ -f "fallout2-ce.html" ]; then
    echo ""
    echo "=========================================="
    echo "✅ Compilação concluída com sucesso!"
    echo "=========================================="
    echo ""
    echo "📁 Arquivos gerados em: $BUILD_DIR"
    echo "   - fallout2-ce.html (página principal)"
    echo "   - fallout2-ce.js (JavaScript)"
    echo "   - fallout2-ce.wasm (WebAssembly)"
    echo ""
    echo "🚀 Para testar:"
    echo "   1. Copie os assets para build-web/"
    echo "   2. Inicie um servidor HTTP:"
    echo "      cd $BUILD_DIR"
    echo "      python -m http.server 8000"
    echo "   3. Abra: http://localhost:8000/fallout2-ce.html"
    echo ""
else
    echo ""
    echo "❌ Erro na compilação!"
    exit 1
fi

