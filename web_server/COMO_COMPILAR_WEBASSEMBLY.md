# 🚀 Como Compilar Fallout 2 para WebAssembly

## ✅ É POSSÍVEL SIM!

Você estava **100% correto** - hoje em dia É POSSÍVEL rodar jogos completos no navegador usando **WebAssembly**!

## 📋 Pré-requisitos

### 1. Instalar Emscripten

**Windows:**
```bash
# Baixar e instalar
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
emsdk install latest
emsdk activate latest
emsdk_env.bat
```

**Linux/Mac:**
```bash
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

### 2. Verificar Instalação

```bash
emcc --version
# Deve mostrar a versão do Emscripten
```

### 3. CMake (já deve estar instalado)

```bash
cmake --version
```

## 🔨 Compilação

### Opção 1: Script Automático (Recomendado)

**Windows:**
```bash
cd web_server
build_webassembly.bat
```

**Linux/Mac:**
```bash
cd web_server
chmod +x build_webassembly.sh
./build_webassembly.sh
```

### Opção 2: Manual

```bash
# 1. Ativar Emscripten
source ./emsdk/emsdk_env.sh  # Linux/Mac
# ou
emsdk_env.bat  # Windows

# 2. Criar diretório de build
mkdir build-web
cd build-web

# 3. Configurar CMake
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DFALLOUT_VENDORED=OFF

# 4. Compilar
emmake make -j4

# Isso vai gerar:
# - fallout2-ce.html
# - fallout2-ce.js
# - fallout2-ce.wasm
```

## 🎮 Testar no Navegador

### 1. Copiar Assets

```bash
# Copiar arquivos .DAT para o diretório de build
cp "Fallout 2/master.dat" build-web/
cp "Fallout 2/critter.dat" build-web/
cp "Fallout 2/patch000.dat" build-web/  # se existir
```

### 2. Iniciar Servidor HTTP

**Importante:** Não use `file://` - precisa de servidor HTTP!

```bash
cd build-web
python -m http.server 8000
# ou
npx serve
# ou
php -S localhost:8000
```

### 3. Abrir no Navegador

```
http://localhost:8000/fallout2-ce.html
```

## ⚙️ Configurações Avançadas

### Preload de Assets

Para carregar assets automaticamente, edite o `CMakeLists.txt`:

```cmake
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --preload-file \"../Fallout 2/master.dat@/master.dat\"")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --preload-file \"../Fallout 2/critter.dat@/critter.dat\"")
```

### Otimizações

```cmake
# Otimização máxima
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")

# Reduzir tamanho
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s MINIFY_HTML=1")
```

### Memória

```cmake
# Aumentar memória inicial
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s INITIAL_MEMORY=134217728")  # 128MB
```

## 🐛 Resolução de Problemas

### Erro: "Emscripten não encontrado"
```bash
# Ativar Emscripten
source ./emsdk/emsdk_env.sh  # Linux/Mac
emsdk_env.bat  # Windows
```

### Erro: "SDL2 não encontrado"
```cmake
# Adicionar flag
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s USE_SDL=2")
```

### Erro: "Arquivo não encontrado"
- Certifique-se de que os assets estão no lugar certo
- Use caminhos relativos corretos
- Verifique permissões de arquivo

### Performance Lenta
- Use `-O2` ou `-O3` para otimização
- Reduza resolução
- Desabilite recursos não essenciais

## 📊 Tamanho Esperado

- **fallout2-ce.wasm**: ~5-15 MB (comprimido: ~2-5 MB)
- **fallout2-ce.js**: ~500 KB - 1 MB
- **fallout2-ce.html**: ~10-50 KB
- **Assets (.DAT)**: ~500 MB (carregados sob demanda)

## 🎯 Próximos Passos

1. **Compilar com sucesso**
2. **Testar no navegador**
3. **Otimizar performance**
4. **Adicionar carregamento de assets**
5. **Melhorar interface web**

## 📚 Recursos

- **Emscripten Docs**: https://emscripten.org/docs/
- **WebAssembly**: https://webassembly.org/
- **SDL2 Web**: https://wiki.libsdl.org/SDL2/Installation

## ✅ Resumo

1. Instale Emscripten
2. Execute o script de build
3. Copie os assets
4. Inicie servidor HTTP
5. Abra no navegador
6. **Jogue Fallout 2 no navegador!** 🎮✨

---

**Você estava certo - É POSSÍVEL! Agora vamos fazer funcionar!** 🚀

