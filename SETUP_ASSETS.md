# Setup Rápido: Onde Colocar os Arquivos do Fallout 2

## 📍 Localização dos Arquivos

### Windows

Coloque os arquivos na **mesma pasta** onde está o executável `fallout2-ce.exe`:

```
C:\Users\Casa\Documents\Novo github\fallout2-ce\
├── fallout2-ce.exe          # Executável (após compilar)
├── master.dat               # ← COLE AQUI
├── critter.dat              # ← COLE AQUI  
├── patch000.dat             # ← COLE AQUI (opcional)
├── data\                    # ← COLE A PASTA COMPLETA AQUI
│   ├── art\
│   ├── maps\
│   ├── scripts\
│   └── ...
└── fallout2.cfg             # Será criado automaticamente
```

### Estrutura Esperada pelo Jogo

O jogo procura os arquivos nesta ordem:

1. **Primeiro:** Na pasta do executável
2. **Depois:** Caminhos configurados em `fallout2.cfg`

---

## 🔧 Configuração Inicial

### 1. Copiar Arquivos

Do Fallout 2 instalado, copie:
- `master.dat`
- `critter.dat`  
- `patch000.dat` (se existir)
- Toda a pasta `data/`

Para a pasta do projeto `fallout2-ce/`

### 2. Verificar Nomes

**IMPORTANTE:** O jogo pode ser sensível a maiúsculas/minúsculas dependendo do sistema:

- **Windows:** Geralmente não importa
- **Linux/Mac:** Pode importar - use minúsculas:
  - `master.dat` (não `MASTER.DAT`)
  - `critter.dat` (não `CRITTER.DAT`)

### 3. Testar

Após copiar, compile e execute:
```bash
# Windows
fallout2-ce.exe

# Linux/Mac  
./fallout2-ce
```

Se aparecer erro sobre arquivos não encontrados, verifique:
- Nomes dos arquivos (maiúsculas/minúsculas)
- Localização (mesma pasta do executável)
- Arquivos não corrompidos

---

## 📂 Estrutura de Pastas para Análise

Recomendo criar esta estrutura para organizar sua análise:

```
fallout2-ce/
├── assets/                  # Assets do Fallout 2 (para o jogo rodar)
│   ├── master.dat
│   ├── critter.dat
│   └── data/
│
├── analysis/                # Sua área de trabalho
│   ├── extracted/          # Arquivos extraídos
│   │   ├── maps/          # Mapas extraídos
│   │   ├── art/           # Sprites extraídos
│   │   └── scripts/       # Scripts extraídos
│   │
│   ├── docs/              # Documentação que você criar
│   │   ├── dat_format.txt
│   │   ├── map_format.txt
│   │   └── frm_format.txt
│   │
│   └── tools/             # Ferramentas que você criar
│       ├── extract_dat.cpp
│       └── view_frm.cpp
│
└── src/                    # Código-fonte (para estudar)
```

---

## 🎯 Próximo Passo: Analisar Formatos

Depois de colocar os arquivos, você pode começar a analisar:

1. **Arquivos .DAT:**
   - Estude `src/db.cc` e `src/xfile.cc`
   - Veja como o jogo abre e lê esses arquivos

2. **Mapas .MAP:**
   - Estude `src/map.cc`
   - Função `mapLoad()` mostra como carrega

3. **Sprites .FRM:**
   - Estude `src/art.cc`
   - Função `artLock()` mostra estrutura

4. **Scripts:**
   - Estude `src/interpreter.cc`
   - Veja como interpreta bytecode

---

## ⚠️ Lembrete Legal

Você está usando os arquivos do Fallout 2 apenas para:
- ✅ Estudar os formatos
- ✅ Entender como funcionam
- ✅ Criar seu próprio formato similar

**NÃO use os assets do Fallout 2 no seu jogo comercial!**

Crie seus próprios sprites, mapas e conteúdo.

