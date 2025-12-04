# 🌐 Fallout 2 Asset Viewer - Dashboard Web

Dashboard completo e robusto para visualização e análise de sprites e assets do Fallout 2.

## 🚀 Como Usar

### 1. Iniciar o Servidor

```bash
# Windows
python web_server/server.py

# Linux/Mac
python3 web_server/server.py
```

O servidor iniciará em: **http://localhost:8000**

### 2. Acessar o Dashboard

Abra no navegador:
```
http://localhost:8000/dashboard.html
```

### 3. Extrair Sprites (Opcional)

Para extrair e analisar sprites conhecidos:

```bash
python web_server/extract_sprites.py
```

## 📁 Estrutura

```
web_server/
├── server.py              # Servidor web
├── dashboard.html         # Dashboard principal
├── extract_sprites.py     # Script de extração
├── assets/                # Assets extraídos
│   └── extracted/         # Sprites extraídos
└── README.md             # Este arquivo
```

## 🎯 Funcionalidades

- ✅ Visualização de estatísticas dos assets
- ✅ Listagem de arquivos .DAT
- ✅ Informações sobre sprites
- ✅ Lista de NPCs/Critters
- ✅ Análise profunda de formatos
- ✅ Interface moderna e responsiva

## 📊 API Endpoints

- `GET /api/stats` - Estatísticas gerais
- `GET /api/files?type=dat` - Lista de arquivos
- `GET /api/sprites` - Lista de sprites
- `GET /api/critters` - Lista de NPCs

## ⚠️ Notas

- A maioria dos sprites está dentro dos arquivos .DAT
- Para visualizar sprites, você precisa extraí-los primeiro
- Use ferramentas como `dat2` ou `Fallout Mod Manager` para extrair

