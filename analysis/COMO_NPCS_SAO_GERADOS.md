# 🎭 Como os NPCs São Gerados - Sistema FID

## Visão Geral

Os NPCs no Fallout 2 são gerados usando um sistema inteligente chamado **FID (Frame ID)**, que codifica todas as informações necessárias para renderizar um sprite em um único número de 32 bits.

---

## 🔢 O Que é FID?

**FID (Frame ID)** é um número de 32 bits que contém:

```
Bits 0-11:   frmId        (ID do arquivo base - 0 a 4095)
Bits 12-15:  weaponCode   (Tipo de arma - 0 a 15)
Bits 16-23:  animType     (Tipo de animação - 0 a 255)
Bits 24-27:  objectType   (Tipo de objeto - 0 a 15)
Bits 28-30:  rotation     (Direção/rotação - 0 a 5)
Bit 31:      (reservado)
```

### Exemplo Visual

```
31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
│  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │  │
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
   rotation    objectType        animType          weaponCode        frmId
```

---

## 🏗️ Função buildFid()

Do código-fonte (`src/art.h`):

```cpp
int buildFid(int objectType, int frmId, int animType, int weaponCode, int rotation)
{
    return (objectType << 24) |      // Bits 24-27
           (rotation << 28) |         // Bits 28-30
           (animType << 16) |         // Bits 16-23
           (weaponCode << 12) |       // Bits 12-15
           (frmId & 0xFFF);          // Bits 0-11
}
```

### Macros para Extrair Valores

```cpp
#define FID_TYPE(fid)        ((fid) & 0xF000000) >> 24
#define FID_ANIM_TYPE(fid)    ((fid) & 0xFF0000) >> 16
#define FID_WEAPON(fid)       ((fid) & 0xF000) >> 12
#define FID_FRM_ID(fid)       ((fid) & 0xFFF)
#define FID_ROTATION(fid)     ((fid) & 0x70000000) >> 28
```

---

## 🎯 Exemplo Prático: NPC Tribal com Faca

### Cenário
- **NPC:** Homem tribal (hmwarr)
- **Ação:** Andando
- **Arma:** Faca
- **Direção:** Leste

### Cálculo do FID

```cpp
objectType = OBJ_TYPE_CRITTER = 1
frmId = 1  // "hmwarr" é o índice 1 na lista critters.lst
animType = ANIM_WALK = 1
weaponCode = WEAPON_ANIMATION_KNIFE = 1
rotation = ROTATION_E = 1

FID = buildFid(1, 1, 1, 1, 1)
    = (1 << 24) | (1 << 28) | (1 << 16) | (1 << 12) | 1
    = 0x11010101
```

### Conversão para Nome de Arquivo

O jogo converte o FID em nome de arquivo usando `artBuildFilePath()`:

```cpp
// Do código src/art.cc
// Para critters (objectType = 1):
// Caminho: art/critters/[nome_base][weapon][anim].frm

// Exemplo:
// frmId = 1 → "hmwarr" (da lista critters.lst)
// weaponCode = 1 → 'd' (faca)
// animType = 1 → 'a' (andar)
// Resultado: "art/critters/hmwarrda.frm"
```

---

## 📋 Tipos de Objetos (objectType)

```cpp
OBJ_TYPE_ITEM = 0
OBJ_TYPE_CRITTER = 1      // NPCs e criaturas
OBJ_TYPE_SCENERY = 2
OBJ_TYPE_WALL = 3
OBJ_TYPE_TILE = 4
OBJ_TYPE_MISC = 5
OBJ_TYPE_INTERFACE = 6
OBJ_TYPE_INVENTORY = 7
OBJ_TYPE_HEAD = 8         // Cabeças para diálogos
OBJ_TYPE_BACKGROUND = 9
OBJ_TYPE_SKILLDEX = 10
```

---

## 🎬 Tipos de Animação (animType)

### Animações Básicas

| Código | Animação | Letra | Descrição |
|--------|----------|-------|-----------|
| 0 | ANIM_STAND | a | Parado |
| 1 | ANIM_WALK | a | Andando |
| 2 | ANIM_RUN | b | Correndo |
| 3 | ANIM_TAKE_OUT | c | Pegando arma |
| 4 | ANIM_ATTACK | d | Atacando |
| 5 | ANIM_THROW_PUNCH | e | Socando |

### Código de Conversão

```cpp
// Do código src/art.cc - _art_get_code()
// Converte animType + weaponCode em letras para nome do arquivo

Para animações básicas (ANIM_WALK, etc):
  animLetter = 'a' + animType
  weaponLetter = 'd' + (weaponCode - 1)  // 'd' = faca, 'e' = clava, etc.
```

---

## 🔫 Códigos de Arma (weaponCode)

```cpp
WEAPON_ANIMATION_NONE = 0
WEAPON_ANIMATION_KNIFE = 1      // 'd'
WEAPON_ANIMATION_CLUB = 2       // 'e'
WEAPON_ANIMATION_HAMMER = 3     // 'f'
WEAPON_ANIMATION_SPEAR = 4      // 'g'
WEAPON_ANIMATION_PISTOL = 5     // 'h'
WEAPON_ANIMATION_SMG = 6        // 'i'
WEAPON_ANIMATION_SHOTGUN = 7    // 'j'
WEAPON_ANIMATION_LASER_RIFLE = 8 // 'k'
WEAPON_ANIMATION_MINIGUN = 9    // 'l'
WEAPON_ANIMATION_LAUNCHER = 10  // 'm'
```

---

## 🧭 Direções (rotation)

```cpp
ROTATION_NE = 0  // Norte-Leste
ROTATION_E = 1   // Leste
ROTATION_SE = 2  // Sul-Leste
ROTATION_SW = 3  // Sul-Oeste
ROTATION_W = 4   // Oeste
ROTATION_NW = 5  // Norte-Oeste
```

---

## 🔄 Fluxo Completo: Do FID ao Sprite na Tela

### 1. NPC é Criado

```cpp
// Do código src/proto.cc
Object* npc;
objectCreateWithPid(&npc, pid);  // pid = Prototype ID

// NPC recebe FID inicial do protótipo
npc->fid = proto->fid;  // Ex: 0x01010101
```

### 2. FID é Atualizado Conforme Ação

```cpp
// NPC começa a andar para o leste
int newFid = buildFid(
    FID_TYPE(npc->fid),      // Mantém tipo
    FID_FRM_ID(npc->fid),    // Mantém base
    ANIM_WALK,               // Nova animação
    FID_WEAPON(npc->fid),    // Mantém arma
    ROTATION_E               // Nova direção
);
npc->fid = newFid;
```

### 3. FID é Convertido em Nome de Arquivo

```cpp
// Do código src/art.cc - artBuildFilePath()
char* path = artBuildFilePath(npc->fid);
// Retorna: "art/critters/hmwarrda.frm"
```

### 4. Arquivo .FRM é Carregado

```cpp
// Do código src/art.cc
Art* art = artLock(npc->fid, &cacheEntry);
// Carrega do .DAT ou pasta, cacheia em memória
```

### 5. Frame Específico é Selecionado

```cpp
// Seleciona frame baseado em:
// - Direção (rotation): 0-5
// - Frame atual da animação (npc->frame)
unsigned char* pixels = artGetFrameData(
    art, 
    npc->frame,           // Frame atual
    FID_ROTATION(npc->fid) // Direção
);
```

### 6. Sprite é Renderizado

```cpp
// Do código src/draw.cc
// Renderiza pixels na tela com:
// - Offsets do frame (x, y)
// - Paleta de cores
// - Transparência
blitBufferToBufferTrans(pixels, width, height, ...);
```

---

## 📝 Lista de Sprites Base (critters.lst)

O arquivo `art/critters/critters.lst` contém a lista de sprites base:

```
hmwarr    ← Homem tribal (índice 0)
hfprim    ← Mulher tribal (índice 1)
hmjmps    ← Homem jumpsuit (índice 2)
hfjmps    ← Mulher jumpsuit (índice 3)
...
```

Cada linha tem 13 caracteres (nome + terminador).

### Como o Jogo Lê

```cpp
// Do código src/art.cc - artReadList()
// Lê critters.lst e cria array de nomes
char* critterNames = malloc(13 * count);

// Para obter nome do sprite:
char name[13];
artCopyFileName(OBJ_TYPE_CRITTER, frmId, name);
// name = "hmwarr"
```

---

## 🎨 Exemplos de FIDs Reais

### Exemplo 1: NPC Parado sem Arma

```cpp
FID = buildFid(
    OBJ_TYPE_CRITTER,    // 1
    1,                   // hmwarr
    ANIM_STAND,          // 0
    WEAPON_ANIMATION_NONE, // 0
    ROTATION_NE          // 0
);
// = 0x01000001
// Arquivo: art/critters/hmwarraa.frm
```

### Exemplo 2: NPC Correndo com Pistola para Oeste

```cpp
FID = buildFid(
    OBJ_TYPE_CRITTER,    // 1
    1,                   // hmwarr
    ANIM_RUN,            // 2
    WEAPON_ANIMATION_PISTOL, // 5
    ROTATION_W           // 4
);
// = 0x14020001
// Arquivo: art/critters/hmwarhb.frm
```

### Exemplo 3: NPC Atacando com Faca para Sul-Leste

```cpp
FID = buildFid(
    OBJ_TYPE_CRITTER,    // 1
    1,                   // hmwarr
    ANIM_ATTACK,         // 4
    WEAPON_ANIMATION_KNIFE, // 1
    ROTATION_SE          // 2
);
// = 0x12040001
// Arquivo: art/critters/hmwaradd.frm
```

---

## 🔍 Sistema de Aliases

Alguns NPCs usam "aliases" - quando um sprite não existe, usa outro:

```cpp
// Do código src/art.cc
int _art_alias_num(int fid) {
    int frmId = FID_FRM_ID(fid);
    if (frmId < gArtListDescriptions[OBJ_TYPE_CRITTER].fileNamesLength) {
        return _anon_alias[frmId];  // Retorna ID do alias
    }
    return -1;
}
```

Exemplo: NPC anônimo usa sprite do jogador.

---

## 💡 Como Aplicar no Seu Jogo

### Vantagens do Sistema FID

1. **Compacto:** Tudo em um número
2. **Flexível:** Fácil mudar animação/direção
3. **Cacheável:** FID pode ser usado como chave de cache
4. **Extensível:** Pode adicionar mais bits se necessário

### Implementação Sugerida

```cpp
// Seu próprio sistema
struct SpriteID {
    uint16_t baseId;      // ID do sprite base
    uint8_t animation;    // Tipo de animação
    uint8_t weapon;       // Tipo de arma
    uint8_t direction;    // Direção
    uint8_t frame;        // Frame atual
};

// Ou usar FID similar:
uint32_t myFID = (baseId & 0xFFFF) | 
                 (animation << 16) | 
                 (weapon << 24) | 
                 (direction << 28);
```

---

## 📚 Códigos Relevantes

### Arquivos Principais

- **src/art.h** - Definição de `buildFid()`
- **src/art.cc** - `artBuildFilePath()`, `artLock()`
- **src/object.h** - Estrutura `Object` com campo `fid`
- **src/animation.cc** - Animações e mudanças de FID

### Funções-Chave

```cpp
// Construir FID
int buildFid(int objectType, int frmId, int animType, int weaponCode, int rotation);

// Converter FID em caminho
char* artBuildFilePath(int fid);

// Carregar sprite
Art* artLock(int fid, CacheEntry** handle);

// Obter frame
unsigned char* artGetFrameData(int fid, int frame, int direction);
```

---

**Última atualização:** Baseado na análise do código-fonte do Fallout 2 Community Edition

