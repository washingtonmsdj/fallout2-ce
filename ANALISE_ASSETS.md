# 📊 Análise Completa dos Assets do Fallout 2

## ✅ Status: Arquivos Detectados

### 📦 Arquivos .DAT (Containers Principais)

Encontrados na pasta `Fallout 2/`:

1. **master.dat** ✅
   - Container principal com todos os assets do jogo
   - Contém: sprites, mapas, scripts, textos, etc.
   - **Localização:** `Fallout 2/master.dat`

2. **critter.dat** ✅
   - Container com sprites de personagens e criaturas
   - **Localização:** `Fallout 2/critter.dat`

3. **patch000.dat** ✅
   - Arquivo de patch/atualização
   - **Localização:** `Fallout 2/patch000.dat`

4. **f2_res.dat** ✅
   - Arquivo de recursos de alta resolução (mod)
   - **Localização:** `Fallout 2/f2_res.dat`

5. **worldmap.dat** ✅
   - Dados do mapa mundial
   - **Localização:** `Fallout 2/data/worldmap.dat`

### 🎨 Estrutura de Pastas Detectada

```
Fallout 2/
├── master.dat              ✅ Container principal
├── critter.dat             ✅ Sprites de criaturas
├── patch000.dat            ✅ Patch
├── f2_res.dat              ✅ Recursos hi-res
│
├── data/                   ✅ Pasta de dados
│   ├── art/
│   │   └── tiles/
│   │       └── grid000.FRM ✅ Sprite de tile encontrado
│   ├── maps/               ✅ (vazia - mapas estão no .DAT)
│   ├── proto/              ✅ Protótipos
│   │   ├── critters/       ✅ Protótipos de criaturas
│   │   └── items/          ✅ Protótipos de itens
│   └── worldmap.dat        ✅ Mapa mundial
│
└── sound/                  ✅ Sons e música
    └── music/              ✅ Músicas (.ACM)
        ├── 01hub.acm
        ├── 03wrldmp.acm
        ├── 07desert.acm
        └── ... (24 arquivos de música)
```

### 🎵 Arquivos de Áudio

**Formato:** `.ACM` (Interplay ACM)
**Localização:** `Fallout 2/sound/music/`

Arquivos encontrados:
- 01hub.acm, 03wrldmp.acm, 05raider.acm
- 07desert.acm, 08vats.acm, 10labone.acm
- 12junktn.acm, 13carvrn.acm, 14necro.acm
- 16follow.acm, 17arroyo.acm, 18modoc.acm
- 19reno.acm, 20car.acm, 21sf.acm
- 22vcity.acm, 23world.acm, 24redd.acm
- akiss.acm, wind1.acm, wind2.acm

**Total:** ~24 arquivos de música

### 🖼️ Arquivos de Arte/Sprites

**Formato:** `.FRM` (Fallout Resource Manager)
**Encontrado:** `grid000.FRM` em `data/art/tiles/`

**Nota:** A maioria dos sprites está dentro dos arquivos `.DAT`:
- `master.dat` - contém a maioria dos sprites
- `critter.dat` - contém sprites de personagens/criaturas

### 🗺️ Mapas

**Formato:** `.MAP` (binário customizado)
**Localização:** Dentro de `master.dat` (não na pasta `data/maps/`)

**Estrutura do formato:**
- Versão: 19 ou 20
- Header com metadados
- Variáveis globais e locais
- Tiles e objetos
- Scripts do mapa

### 📝 Arquivos de Configuração

1. **fallout2.cfg** ✅
   - Configurações principais do jogo
   - Define caminhos para master.dat, critter.dat
   - Configurações de som, vídeo, preferências

2. **ddraw.ini** ✅
   - Configurações do Sfall (mod)
   - Contém centenas de opções avançadas
   - Permite customização profunda

3. **f2_res.ini** ✅
   - Configurações do High Resolution Patch
   - Resolução, modo janela, efeitos

---

## 🔍 ONDE ESTÃO OS ASSETS?

### Assets Dentro dos .DAT

A **maioria dos assets está dentro dos arquivos .DAT**, não em pastas:

- **master.dat contém:**
  - Todos os sprites (.FRM) - items, scenery, walls, tiles, interface
  - Todos os mapas (.MAP)
  - Scripts (.INT)
  - Textos (.MSG)
  - Fontes
  - Outros recursos

- **critter.dat contém:**
  - Sprites de personagens (.FRM)
  - Sprites de criaturas (.FRM)
  - Animações de cabeças
  - Backgrounds de diálogo

### Assets em Pastas

Alguns assets estão descompactados em pastas:

- `data/art/tiles/` - alguns tiles
- `data/proto/` - protótipos de criaturas e itens
- `sound/music/` - músicas em formato .ACM
- `data/worldmap.dat` - dados do mapa mundial

---

## 📋 FORMATOS DE ARQUIVO IDENTIFICADOS

### 1. .DAT (Container)
- **Tipo:** Arquivo container/arquivo
- **Estrutura:** Tabela de hash + arquivos compactados
- **Código relevante:** `src/db.cc`, `src/xfile.cc`
- **Como extrair:** Precisa entender sistema de hash

### 2. .FRM (Sprite)
- **Tipo:** Sprite/Frame do Fallout
- **Estrutura:** Header + frames + offsets
- **Código relevante:** `src/art.cc`
- **Campos principais:**
  - framesPerSecond
  - frameCount
  - xOffsets[6], yOffsets[6]
  - dataOffsets[6]

### 3. .MAP (Mapa)
- **Tipo:** Mapa do jogo
- **Estrutura:** Header + tiles + objetos + scripts
- **Código relevante:** `src/map.cc`
- **Versões:** 19 ou 20

### 4. .ACM (Áudio)
- **Tipo:** Música/áudio comprimido
- **Formato:** Interplay ACM
- **Localização:** `sound/music/`

### 5. .INT (Script)
- **Tipo:** Bytecode de script
- **Formato:** Bytecode do interpretador Fallout
- **Código relevante:** `src/interpreter.cc`

### 6. .MSG (Mensagem)
- **Tipo:** Textos do jogo
- **Formato:** ID + texto
- **Código relevante:** `src/message.cc`

### 7. .PRO (Protótipo)
- **Tipo:** Definição de objetos/criaturas
- **Localização:** `data/proto/critters/`, `data/proto/items/`
- **Código relevante:** `src/proto.cc`

---

## 🛠️ PRÓXIMOS PASSOS PARA ANÁLISE

### 1. Extrair Arquivos dos .DAT

**Ferramentas úteis:**
- `dat2` - extrator de .DAT
- `Fallout Mod Manager` - gerencia e extrai assets
- Ou criar sua própria baseada em `src/xfile.cc`

**O que extrair primeiro:**
1. Lista de arquivos dentro de `master.dat`
2. Sprites (.FRM) para análise
3. Mapas (.MAP) para entender estrutura
4. Scripts (.INT) para entender bytecode

### 2. Analisar Formatos Específicos

**Prioridade:**
1. **.FRM** - Mais importante para sprites
   - Estude `src/art.cc` linha por linha
   - Crie visualizador de sprites

2. **.MAP** - Importante para mapas
   - Estude `src/map.cc` função `mapLoad()`
   - Entenda estrutura do header

3. **.DAT** - Base para tudo
   - Estude `src/xfile.cc` e `src/db.cc`
   - Entenda sistema de hash

### 3. Documentar Estruturas

Crie documentação em `analysis/docs/`:
- `dat_format.txt` - Estrutura de .DAT
- `frm_format.txt` - Estrutura de .FRM
- `map_format.txt` - Estrutura de .MAP
- `script_format.txt` - Estrutura de scripts

---

## 📊 ESTATÍSTICAS

### Arquivos Encontrados:
- ✅ 5 arquivos .DAT principais (502 MB total)
- ✅ 1 arquivo .FRM visível (milhares mais dentro dos .DAT)
- ✅ ~24 arquivos de música .ACM
- ✅ 3 arquivos de configuração (.cfg, .ini)

### Tamanhos dos Arquivos .DAT:
| Arquivo | Tamanho | Conteúdo Principal |
|---------|---------|-------------------|
| master.dat | 333 MB | Todos os assets (sprites, mapas, scripts) |
| critter.dat | 166 MB | Sprites de personagens/criaturas |
| patch000.dat | 2.3 MB | Patches e atualizações |
| f2_res.dat | 651 KB | Recursos de alta resolução |
| unins000.dat | 329 KB | Desinstalador |

### Tamanho Real dos Arquivos:
- `master.dat` - **333 MB** (317 MB) - Container principal gigante!
- `critter.dat` - **166 MB** (159 MB) - Sprites de criaturas
- `patch000.dat` - **2.3 MB** - Patch/atualização
- `f2_res.dat` - **651 KB** - Recursos hi-res
- `unins000.dat` - **329 KB** - Arquivo do desinstalador

**Total:** ~502 MB de assets comprimidos

---

## 🎯 RECOMENDAÇÕES

### Para Análise Imediata:

1. **Comece com .FRM:**
   ```cpp
   // Estude src/art.cc
   // Função artLock() mostra como carrega
   ```

2. **Depois .MAP:**
   ```cpp
   // Estude src/map.cc
   // Função mapLoad() mostra estrutura completa
   ```

3. **Por último .DAT:**
   ```cpp
   // Estude src/xfile.cc e src/db.cc
   // Mais complexo, mas essencial
   ```

### Para Seu Jogo Comercial:

1. **Documente tudo** que encontrar
2. **Crie ferramentas** de extração/análise
3. **Entenda** os formatos profundamente
4. **Crie formatos próprios** baseados no conhecimento
5. **NÃO copie** assets do Fallout 2

---

## ⚠️ LEMBRETE LEGAL

Você está analisando estes arquivos para:
- ✅ **Estudar** formatos e estruturas
- ✅ **Entender** como funcionam
- ✅ **Criar** seu próprio formato similar

**NÃO use:**
- ❌ Assets do Fallout 2 no seu jogo
- ❌ Código diretamente copiado
- ❌ Sprites, mapas ou conteúdo do Fallout 2

---

## 📚 CÓDIGOS-CHAVE PARA ESTUDAR

### Carregamento de Assets:
- `src/db.cc` - Sistema de .DAT
- `src/xfile.cc` - Acesso a arquivos
- `src/datafile.cc` - Carregamento de imagens

### Formatos Específicos:
- `src/art.cc` - Formato .FRM
- `src/map.cc` - Formato .MAP
- `src/interpreter.cc` - Scripts .INT
- `src/message.cc` - Textos .MSG

### Renderização:
- `src/svga.cc` - Renderização SDL2
- `src/draw.cc` - Funções de desenho

---

**Status:** ✅ Arquivos detectados e prontos para análise!
**Próximo passo:** Começar a extrair e analisar formatos específicos.

