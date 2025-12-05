# Como Funcionam os Assets do Fallout 2 no Projeto Godot

**Data**: Dezembro 4, 2024

---

## 📋 Resumo

Os assets do Fallout 2 **SÃO COPIADOS** para o projeto Godot através de scripts Python de extração e conversão. O jogo **NÃO** lê diretamente da pasta do Fallout 2 original.

---

## 🔄 Processo de Extração e Conversão

### 1. Arquivos Originais (Fallout 2)

Os assets originais estão em arquivos compactados DAT2:

```
Fallout 2/
├── master.dat      (~500MB) - Assets principais
├── critter.dat     (~150MB) - Criaturas adicionais
└── patch000.dat    - Patches e correções
```

### 2. Scripts de Extração (tools/)

Os scripts Python extraem e convertem os assets:

```
tools/
├── extract_fallout2_assets.py    - Extrator principal
├── extract_character_animations.py - Extrai animações de personagens
├── extract_menu_sprites.py        - Extrai sprites de UI
├── extract_tiles.py               - Extrai tiles de terreno
├── extract_critters.py            - Extrai criaturas
├── frm_to_godot_converter.py     - Converte FRM → PNG/SpriteFrames
├── map_to_godot_converter.py     - Converte MAP → Godot Scene
├── pro_to_godot_converter.py     - Converte PRO → Godot Resource
└── extract_all.py                 - Script mestre para extrair tudo
```

### 3. Assets Convertidos (godot_project/assets/)

Os assets são salvos no projeto Godot:

```
godot_project/assets/
├── sprites/
│   ├── ui/              - Interface do usuário
│   ├── characters/      - Personagens
│   ├── creatures/       - Criaturas
│   ├── items/           - Itens
│   └── tiles/           - Tiles de terreno
├── data/
│   ├── maps/            - Dados de mapas (.tres, .json)
│   ├── items/           - Dados de itens (.tres)
│   └── npcs/            - Dados de NPCs (.tres)
├── audio/
│   ├── music/           - Música
│   └── sfx/             - Efeitos sonoros
└── animations/          - Animações (SpriteFrames)
```

---

## 🔧 Como Usar os Scripts de Extração

### Extrair Todos os Assets

```bash
python tools/extract_all.py --fallout2-path "Fallout 2" --output-path "godot_project"
```

### Extrair Apenas Sprites

```bash
python tools/extract_fallout2_assets.py
```

### Extrair Animações de Personagens

```bash
python tools/extract_character_animations.py --fallout2 "Fallout 2" --output "godot_project/assets/characters"
```

### Extrair Sprites de Menu

```bash
python tools/extract_menu_sprites.py
```

### Converter FRM para Godot

```bash
python tools/frm_to_godot_converter.py "Fallout 2" "godot_project/assets" "godot_project"
```

### Converter Mapas para Godot

```bash
python tools/map_to_godot_converter.py "Fallout 2" "godot_project/assets/data/maps" "godot_project"
```

---

## 📊 Fluxo de Dados

```
┌─────────────────────────────────────────────────────────────┐
│                    FALLOUT 2 ORIGINAL                       │
├─────────────────────────────────────────────────────────────┤
│  master.dat                                                 │
│  ├── art/critters/*.frm    (sprites de criaturas)          │
│  ├── art/items/*.frm       (sprites de itens)              │
│  ├── art/tiles/*.frm       (tiles de terreno)              │
│  ├── art/intrface/*.frm    (interface)                     │
│  ├── maps/*.map            (mapas)                         │
│  ├── proto/items/*.pro     (protótipos de itens)           │
│  └── text/english/*.msg    (textos/diálogos)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SCRIPTS PYTHON (tools/)                  │
├─────────────────────────────────────────────────────────────┤
│  1. DAT2Extractor          - Extrai arquivos do DAT        │
│  2. FRMDecoder             - Decodifica sprites FRM         │
│  3. MapParser              - Parseia arquivos MAP           │
│  4. PROParser              - Parseia protótipos PRO         │
│  5. MSGParser              - Parseia textos MSG             │
│                                                             │
│  Conversores:                                               │
│  - FRM → PNG + SpriteFrames (.tres)                        │
│  - MAP → PackedScene (.tscn)                               │
│  - PRO → Resource (.tres)                                  │
│  - MSG → JSON (.json)                                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    GODOT PROJECT                            │
├─────────────────────────────────────────────────────────────┤
│  godot_project/assets/                                      │
│  ├── sprites/              (PNG convertidos)                │
│  ├── animations/           (SpriteFrames .tres)             │
│  ├── data/                 (Resources .tres, JSON)          │
│  ├── scenes/               (PackedScenes .tscn)             │
│  └── audio/                (OGG/WAV convertidos)            │
│                                                             │
│  O Godot carrega APENAS destes arquivos convertidos!       │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Vantagens desta Abordagem

### 1. **Independência**
- O projeto Godot não depende da instalação do Fallout 2
- Pode ser distribuído sem os arquivos originais
- Funciona em qualquer plataforma

### 2. **Performance**
- Assets já estão em formatos nativos do Godot
- Não precisa descomprimir DAT em runtime
- Carregamento mais rápido

### 3. **Modificabilidade**
- Assets podem ser editados diretamente
- Fácil substituir por assets próprios
- Permite criar jogo original

### 4. **Compatibilidade**
- Formatos modernos (PNG, OGG, JSON)
- Compatível com ferramentas de edição
- Integração com editor do Godot

---

## 🔍 Verificação de Assets

### Verificar se Assets Foram Extraídos

```bash
# Verificar sprites
ls godot_project/assets/sprites/

# Verificar dados de mapas
ls godot_project/assets/data/maps/

# Verificar animações
ls godot_project/assets/animations/
```

### Verificar Tamanho dos Assets

```bash
# Windows
dir godot_project\assets /s

# Linux/Mac
du -sh godot_project/assets/*
```

---

## 📝 Formatos de Arquivo

### Originais (Fallout 2)
| Formato | Descrição | Tamanho Típico |
|---------|-----------|----------------|
| .DAT | Container compactado | 500MB |
| .FRM | Sprite/animação | 1-50KB |
| .MAP | Dados de mapa | 10-100KB |
| .PRO | Protótipo de objeto | 1-5KB |
| .MSG | Textos/diálogos | 1-50KB |
| .ACM | Áudio comprimido | 100KB-5MB |

### Convertidos (Godot)
| Formato | Descrição | Tamanho Típico |
|---------|-----------|----------------|
| .png | Sprite convertido | 1-100KB |
| .tres | Resource do Godot | 1-50KB |
| .tscn | Scene do Godot | 5-100KB |
| .json | Dados estruturados | 1-50KB |
| .ogg | Áudio convertido | 100KB-5MB |

---

## 🚀 Próximos Passos

### Se Assets Não Foram Extraídos

1. **Verificar instalação do Fallout 2**
   ```bash
   ls "Fallout 2/master.dat"
   ```

2. **Instalar dependências Python**
   ```bash
   pip install -r tools/requirements.txt
   ```

3. **Executar extração completa**
   ```bash
   python tools/extract_all.py --fallout2-path "Fallout 2" --output-path "godot_project"
   ```

### Se Assets Já Foram Extraídos

1. **Verificar integridade**
   ```bash
   python tools/extractor_validator.py
   ```

2. **Abrir projeto no Godot**
   - Os assets estarão disponíveis no FileSystem
   - Podem ser usados diretamente em cenas

---

## ⚠️ Notas Importantes

### 1. **Direitos Autorais**
- Assets originais são propriedade da Bethesda/Interplay
- Use apenas para fins educacionais/pessoais
- Para distribuição, substitua por assets próprios

### 2. **Tamanho do Projeto**
- Assets convertidos ocupam ~1-2GB
- Considere usar .gitignore para assets grandes
- Mantenha apenas assets necessários

### 3. **Atualização de Assets**
- Re-executar scripts sobrescreve assets existentes
- Faça backup de modificações manuais
- Use controle de versão (git) para rastrear mudanças

---

## 📞 Referências

### Documentação
- `tools/README.md` - Documentação dos scripts
- `analysis/FORMATO_FRM.md` - Especificação do formato FRM
- `SETUP_ASSETS.md` - Guia de configuração de assets

### Scripts Principais
- `tools/extract_all.py` - Extração completa
- `tools/extractor_validator.py` - Validação de extração
- `tools/dat_catalog_analyzer.py` - Análise de conteúdo DAT

---

## 🎯 Conclusão

**Os assets DO Fallout 2 são COPIADOS e CONVERTIDOS para o projeto Godot.**

O jogo **NÃO** lê diretamente da pasta do Fallout 2. Todos os assets são:
1. ✅ Extraídos dos arquivos DAT
2. ✅ Convertidos para formatos do Godot
3. ✅ Salvos em `godot_project/assets/`
4. ✅ Carregados pelo Godot em runtime

Isso garante independência, performance e modificabilidade do projeto.

