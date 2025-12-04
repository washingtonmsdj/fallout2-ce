# 🎮 Qual Engine o Fallout 2 Usa?

## 📋 RESPOSTA DIRETA

**O Fallout 2 NÃO usa uma engine comercial!**

Ele usa:
- ✅ **SDL2** - Biblioteca de baixo nível (não é uma engine)
- ✅ **Motor customizado** - Escrito em C++17 do zero
- ✅ **Sem engine pronta** - Tudo foi implementado manualmente

---

## 🔧 ARQUITETURA DO FALLOUT 2

### Stack Tecnológica:

```
Fallout 2 Community Edition:
│
├── 🎨 Renderização
│   └── SDL2 (Simple DirectMedia Layer 2)
│       ├── Gráficos (SDL_Renderer, SDL_Texture)
│       ├── Input (teclado, mouse)
│       └── Áudio (SDL_Audio)
│
├── 💻 Linguagem
│   └── C++17
│
├── 📦 Bibliotecas
│   ├── SDL2 - Gráficos, input, áudio
│   ├── zlib - Compressão de dados
│   └── fpattern - Padrões de arquivo
│
└── 🏗️ Motor do Jogo (Customizado)
    ├── Sistema de renderização próprio
    ├── Sistema de mapas próprio
    ├── Sistema de sprites próprio
    ├── Sistema de combate próprio
    ├── Sistema de scripts próprio
    └── Sistema de física próprio
```

---

## 🎯 O QUE É SDL2?

### SDL2 NÃO é uma Engine!

**SDL2** (Simple DirectMedia Layer 2) é uma **biblioteca de baixo nível** que fornece:

✅ **Acesso ao hardware:**
- Gráficos (janelas, renderização)
- Input (teclado, mouse, joystick)
- Áudio (sons, música)
- Timer (controle de FPS)

❌ **O que SDL2 NÃO faz:**
- Sistema de física
- Sistema de colisão
- Sistema de animação
- Sistema de UI
- Sistema de scripts
- Sistema de salvamento

**Tudo isso foi implementado manualmente no código do Fallout 2!**

---

## 📊 COMPARAÇÃO

### Fallout 2 vs Engines Modernas:

| Recurso | Fallout 2 | Unity | Unreal | Godot |
|---------|-----------|-------|--------|-------|
| **Gráficos** | SDL2 (manual) | Pronto | Pronto | Pronto |
| **Física** | Manual | PhysX | PhysX | Pronto |
| **Colisão** | Manual | Pronto | Pronto | Pronto |
| **UI** | Manual | Pronto | Pronto | Pronto |
| **Scripts** | Bytecode próprio | C# | C++/Blueprints | GDScript |
| **Editor** | Não tem | Visual | Visual | Visual |
| **Complexidade** | Alta | Média | Alta | Baixa |

---

## 🏗️ COMO O FALLOUT 2 FUNCIONA

### 1. Renderização (src/svga.cc)

```cpp
// Fallout 2 usa SDL2 para renderização
SDL_Window* gSdlWindow;
SDL_Renderer* gSdlRenderer;
SDL_Texture* gSdlTexture;

void renderPresent() {
    // Atualizar textura
    SDL_UpdateTexture(gSdlTexture, nullptr, pixels, pitch);
    
    // Limpar renderer
    SDL_RenderClear(gSdlRenderer);
    
    // Copiar textura
    SDL_RenderCopy(gSdlRenderer, gSdlTexture, nullptr, nullptr);
    
    // Mostrar na tela
    SDL_RenderPresent(gSdlRenderer);
}
```

### 2. Game Loop (src/main.cc)

```cpp
static void mainLoop() {
    while (!game_user_wants_to_quit) {
        // Limitar FPS
        sharedFpsLimiter.mark();
        
        // Processar input
        int keyCode = inputGetInput();
        
        // Atualizar lógica
        gameHandleKey(keyCode, false);
        scriptsHandleRequests();
        mapHandleTransition();
        
        // Renderizar
        renderPresent();
        
        // Throttle FPS
        sharedFpsLimiter.throttle();
    }
}
```

### 3. Sistemas Customizados

**Tudo foi implementado do zero:**

- ✅ **Sistema de Mapas** (`src/map.cc`) - Carrega e renderiza mapas
- ✅ **Sistema de Sprites** (`src/art.cc`) - Carrega e anima sprites
- ✅ **Sistema de Combate** (`src/combat.cc`) - Lógica de combate por turnos
- ✅ **Sistema de Scripts** (`src/interpreter.cc`) - Interpretador de bytecode
- ✅ **Sistema de Física** (`src/object.cc`) - Colisões e movimento
- ✅ **Sistema de UI** (`src/interface.cc`) - Interface do jogo

---

## 🎮 POR QUE NÃO USOU UMA ENGINE?

### Motivos Históricos:

1. **Época (1998):**
   - Unity não existia (criado em 2005)
   - Unreal era muito pesado
   - Engines eram caras e raras

2. **Controle Total:**
   - Precisavam de controle total
   - Sistema de turnos específico
   - Formatos de arquivo próprios

3. **Performance:**
   - Jogos 2D isométricos
   - Otimizações específicas
   - Menos overhead

---

## 🔍 DIFERENÇA: SDL2 vs Engine

### SDL2 (O que Fallout 2 usa):
```
SDL2 = Ferramenta de baixo nível
├── Abre janela ✅
├── Desenha pixels ✅
├── Captura input ✅
└── Toca áudio ✅

MAS você precisa implementar:
├── Sistema de física ❌
├── Sistema de colisão ❌
├── Sistema de animação ❌
└── Sistema de UI ❌
```

### Engine (Unity, Unreal, etc.):
```
Engine = Ferramenta de alto nível
├── Abre janela ✅
├── Desenha pixels ✅
├── Captura input ✅
├── Toca áudio ✅
├── Sistema de física ✅
├── Sistema de colisão ✅
├── Sistema de animação ✅
└── Sistema de UI ✅

Tudo pronto para usar!
```

---

## 💡 EQUIVALENTE MODERNO

Se você quisesse criar algo similar hoje:

### Opção 1: SDL2 (Como Fallout 2)
```cpp
// Você escreve tudo manualmente
#include <SDL2/SDL.h>

// Implementar física, colisão, UI, etc.
```

**Vantagens:**
- ✅ Controle total
- ✅ Performance máxima
- ✅ Sem dependências pesadas

**Desvantagens:**
- ❌ Muito trabalho
- ❌ Tempo de desenvolvimento longo
- ❌ Precisa implementar tudo

### Opção 2: Engine Moderna
```csharp
// Unity - Tudo pronto
public class Player : MonoBehaviour {
    void Update() {
        // Física, colisão, etc. já funcionam!
    }
}
```

**Vantagens:**
- ✅ Rápido de desenvolver
- ✅ Muitos recursos prontos
- ✅ Editor visual

**Desvantagens:**
- ❌ Menos controle
- ❌ Pode ser pesado
- ❌ Dependências grandes

---

## 📚 CÓDIGO DO FALLOUT 2

### Estrutura de Arquivos:

```
src/
├── svga.cc          # Renderização (SDL2)
├── main.cc          # Game loop principal
├── map.cc           # Sistema de mapas
├── art.cc           # Sistema de sprites
├── combat.cc        # Sistema de combate
├── interpreter.cc   # Sistema de scripts
├── object.cc        # Sistema de objetos/física
├── interface.cc     # Sistema de UI
└── ... (265 arquivos no total)
```

**Tudo customizado, nada de engine pronta!**

---

## 🎯 RESUMO

### Fallout 2 usa:
- ✅ **SDL2** - Biblioteca de baixo nível (não é engine)
- ✅ **C++17** - Linguagem
- ✅ **Motor customizado** - Tudo implementado manualmente

### Fallout 2 NÃO usa:
- ❌ Unity
- ❌ Unreal
- ❌ Godot
- ❌ Nenhuma engine comercial

### É como:
- 🏗️ **Construir uma casa do zero** vs **Usar kit pré-fabricado**
- Fallout 2 = Casa do zero (mais trabalho, mais controle)
- Unity/Unreal = Kit pré-fabricado (mais rápido, menos controle)

---

## 🚀 PARA CRIAR SEU JOGO

### Se quiser fazer como Fallout 2:
1. Use **SDL2** ou **Raylib**
2. Implemente tudo manualmente
3. Controle total, mas muito trabalho

### Se quiser fazer mais rápido:
1. Use **Godot**, **Unity** ou **Unreal**
2. Use recursos prontos
3. Menos controle, mas muito mais rápido

---

## ✅ CONCLUSÃO

**Fallout 2 = Motor customizado + SDL2**

Não é uma engine pronta, é um **motor de jogo customizado** que usa **SDL2** apenas para acesso ao hardware (gráficos, input, áudio).

Tudo o resto (física, colisão, UI, scripts, etc.) foi **implementado do zero** pelos desenvolvedores!

**É um trabalho impressionante de engenharia!** 🎮✨

