# 📐 Formato .FRM - Sprites do Fallout 2

## Visão Geral

O formato `.FRM` (Fallout Resource Manager) é usado para armazenar sprites e animações no Fallout 2. Cada arquivo .FRM contém múltiplos frames organizados por direção (6 direções isométricas).

---

## 📊 Estrutura do Arquivo

### Header Principal (Art)

```cpp
struct Art {
    int field_0;              // 4 bytes - Campo reservado
    short framesPerSecond;    // 2 bytes - FPS da animação
    short actionFrame;        // 2 bytes - Frame de ação (quando ataca, etc)
    short frameCount;         // 2 bytes - Número total de frames
    short xOffsets[6];        // 12 bytes - Offset X para cada direção (0-5)
    short yOffsets[6];        // 12 bytes - Offset Y para cada direção (0-5)
    int dataOffsets[6];       // 24 bytes - Offset dos dados para cada direção
    int padding[6];           // 24 bytes - Padding
    int dataSize;             // 4 bytes - Tamanho total dos dados
};
```

**Tamanho total do header:** 80 bytes

### Direções (Rotations)

O Fallout 2 usa 6 direções isométricas:

```
    0 = NE (Norte-Leste)
    1 = E  (Leste)
    2 = SE (Sul-Leste)
    3 = SW (Sul-Oeste)
    4 = W  (Oeste)
    5 = NW (Norte-Oeste)
```

### Estrutura de Cada Frame (ArtFrame)

Cada frame individual tem esta estrutura:

```cpp
struct ArtFrame {
    short width;    // 2 bytes - Largura do frame em pixels
    short height;   // 2 bytes - Altura do frame em pixels
    int size;       // 4 bytes - Tamanho dos dados de pixels
    short x;        // 2 bytes - Offset X (hotspot)
    short y;        // 2 bytes - Offset Y (hotspot)
    // Depois vem: width × height bytes de dados de pixels
};
```

**Tamanho do header do frame:** 12 bytes

---

## 🎨 Dados de Pixels

Após cada `ArtFrame` header, vêm os dados da imagem:

- **Formato:** 8-bit indexed (paleta)
- **Tamanho:** `width × height` bytes
- **Cada byte:** Índice na paleta (0-255)
- **Transparência:** Geralmente índice 0 é transparente

### Exemplo de Leitura

```cpp
// Pseudocódigo para ler um frame
ArtFrame* frame = (ArtFrame*)data;
unsigned char* pixels = (unsigned char*)(frame + 1);

for (int y = 0; y < frame->height; y++) {
    for (int x = 0; x < frame->width; x++) {
        int paletteIndex = pixels[y * frame->width + x];
        // Use paletteIndex para obter cor da paleta
    }
}
```

---

## 📁 Organização dos Dados

### Estrutura no Arquivo

```
[Art Header - 80 bytes]
├── Direção 0 (NE)
│   ├── Frame 0 [ArtFrame + pixels]
│   ├── Frame 1 [ArtFrame + pixels]
│   └── ...
├── Direção 1 (E)
│   ├── Frame 0 [ArtFrame + pixels]
│   └── ...
├── Direção 2 (SE)
├── Direção 3 (SW)
├── Direção 4 (W)
└── Direção 5 (NW)
```

### Como Acessar um Frame Específico

```cpp
// Do código src/art.cc
unsigned char* artGetFrameData(Art* art, int frame, int direction) {
    // 1. Verificar se direção é válida (0-5)
    if (direction < 0 || direction >= 6) return nullptr;
    
    // 2. Obter offset dos dados para esta direção
    int offset = art->dataOffsets[direction];
    if (offset == 0) return nullptr;
    
    // 3. Calcular posição do frame
    // (precisa iterar pelos frames anteriores)
    unsigned char* data = ((unsigned char*)art) + offset;
    
    // 4. Pular frames anteriores
    for (int i = 0; i < frame; i++) {
        ArtFrame* f = (ArtFrame*)data;
        data += sizeof(ArtFrame) + f->size;
    }
    
    // 5. Retornar dados do frame
    ArtFrame* frameHeader = (ArtFrame*)data;
    return (unsigned char*)(frameHeader + 1);
}
```

---

## 🔍 Exemplo de Análise

### Sprite de NPC Andando

**Arquivo:** `art/critters/hmwarrda.frm`
- `hmwarr` = homem tribal (base)
- `d` = faca (weapon code)
- `a` = andar (animation)

**Estrutura esperada:**
```
Art Header:
  framesPerSecond: 10
  frameCount: 6 (6 frames de animação)
  xOffsets[6]: [-10, -8, -6, -4, -2, 0]  (exemplo)
  yOffsets[6]: [5, 3, 1, -1, -3, -5]     (exemplo)

Direção 0 (NE):
  Frame 0: 48x64 pixels, offset (24, 32)
  Frame 1: 48x64 pixels, offset (24, 32)
  ... (6 frames)

Direção 1 (E):
  ... (6 frames)

... (outras direções)
```

---

## 🛠️ Como Ler um Arquivo .FRM

### Passo a Passo

1. **Abrir arquivo:**
   ```cpp
   FILE* file = fopen("hmwarrda.frm", "rb");
   ```

2. **Ler header:**
   ```cpp
   Art art;
   fread(&art, sizeof(Art), 1, file);
   ```

3. **Para cada direção (0-5):**
   ```cpp
   for (int dir = 0; dir < 6; dir++) {
       if (art.dataOffsets[dir] == 0) continue;
       
       fseek(file, art.dataOffsets[dir], SEEK_SET);
       
       // Ler frames desta direção
       for (int frame = 0; frame < art.frameCount; frame++) {
           ArtFrame frameHeader;
           fread(&frameHeader, sizeof(ArtFrame), 1, file);
           
           // Ler pixels
           unsigned char* pixels = malloc(frameHeader.size);
           fread(pixels, 1, frameHeader.size, file);
           
           // Processar pixels...
           free(pixels);
       }
   }
   ```

---

## 📚 Referências no Código

### Arquivos Relevantes

- **src/art.h** - Definições das estruturas
- **src/art.cc** - Funções de carregamento
  - `artLoad()` - Carrega arquivo .FRM
  - `artGetFrame()` - Obtém frame específico
  - `artGetFrameData()` - Obtém dados de pixels
  - `artGetWidth()` / `artGetHeight()` - Dimensões

### Funções Principais

```cpp
// Carregar sprite
Art* art = artLock(fid, &cacheEntry);

// Obter frame
ArtFrame* frame = artGetFrame(art, frameNum, direction);

// Obter dados de pixels
unsigned char* pixels = artGetFrameData(art, frameNum, direction);

// Liberar
artUnlock(cacheEntry);
```

---

## 💡 Dicas para Criar Seu Próprio Formato

### Similaridades que Você Pode Usar

1. **Sistema de direções** - 6 direções isométricas funcionam bem
2. **Header + frames** - Estrutura simples e eficiente
3. **8-bit indexed** - Compacto, fácil de comprimir
4. **Offsets por direção** - Permite acesso rápido

### Melhorias Possíveis

1. **Compressão** - Adicionar compressão (zlib, etc)
2. **Múltiplas resoluções** - Suporte a sprites HD
3. **Metadados** - Informações adicionais (tags, etc)
4. **Formato moderno** - PNG embutido ou similar

---

## ⚠️ Notas Importantes

1. **Endianness:** O formato é little-endian
2. **Alinhamento:** Estruturas podem ter padding
3. **Paleta:** A paleta é separada (arquivo .PAL)
4. **Transparência:** Índice 0 geralmente é transparente
5. **Cache:** O jogo cacheia sprites em memória

---

**Última atualização:** Baseado na análise do código-fonte do Fallout 2 Community Edition

