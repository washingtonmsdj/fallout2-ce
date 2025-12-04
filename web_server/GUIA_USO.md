# 🚀 Guia de Uso - Dashboard Web Fallout 2

## Como Iniciar o Servidor

### Windows
```bash
# Opção 1: Duplo clique
start_server.bat

# Opção 2: Linha de comando
cd web_server
python server.py
```

### Linux/Mac
```bash
chmod +x start_server.sh
./start_server.sh

# Ou diretamente:
cd web_server
python3 server.py
```

## Acessar o Dashboard

Após iniciar o servidor, abra no navegador:

```
http://localhost:8000
```

Ou diretamente:
- **Dashboard:** http://localhost:8000/dashboard.html
- **Visualizador FRM:** http://localhost:8000/frm_viewer.html
- **Página Inicial:** http://localhost:8000/index.html

## Funcionalidades

### 1. Dashboard Principal
- Estatísticas dos arquivos .DAT
- Listagem de assets
- Informações sobre sprites
- Análise de NPCs

### 2. Visualizador de Sprites
- Visualização de sprites .FRM extraídos
- Informações detalhadas de cada frame
- Análise de direções e animações

### 3. API REST
- `/api/stats` - Estatísticas gerais
- `/api/files?type=dat` - Lista de arquivos
- `/api/sprites` - Lista de sprites
- `/api/critters` - Lista de NPCs

## Extrair Sprites

Para extrair sprites conhecidos:

```bash
python web_server/extract_sprites.py
```

Isso irá:
- Procurar arquivos .FRM em `Fallout 2/data/art/`
- Analisar estrutura de cada sprite
- Salvar análise em JSON para visualização

## Estrutura de Pastas

```
web_server/
├── server.py              # Servidor web
├── dashboard.html         # Dashboard principal
├── frm_viewer.html        # Visualizador de sprites
├── index.html             # Página inicial
├── extract_sprites.py     # Script de extração
├── assets/
│   └── extracted/        # Sprites extraídos e análises
│       ├── sprites_list.json
│       └── sprites_analysis.json
└── README.md
```

## Próximos Passos

Para ver TODOS os sprites (incluindo os que estão dentro dos .DAT):

1. **Usar ferramentas existentes:**
   - `dat2` - Extrator de .DAT
   - `Fallout Mod Manager` - Gerencia e extrai assets

2. **Ou criar seu próprio extrator:**
   - Baseado em `src/xfile.cc` e `src/dfile.cc`
   - Entender sistema de hash dos .DAT
   - Extrair arquivos .FRM
   - Converter para PNG para visualização

## Dicas

- O servidor roda na porta 8000 por padrão
- Todos os arquivos são servidos de `web_server/`
- API retorna JSON para fácil integração
- Dashboard é totalmente responsivo

