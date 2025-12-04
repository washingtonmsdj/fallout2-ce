# 🚀 Ambiente de Desenvolvimento

## 📦 Instalação

### 1. Instalar Dependências Node.js
```bash
npm install
```

### 2. (Opcional) Instalar Watchdog para Hot Reload
```bash
pip install watchdog
```

## 🎮 Comandos Disponíveis

### Desenvolvimento
```bash
npm run dev
```
Inicia o servidor de desenvolvimento na porta 8000 com hot reload.

### Servidor Normal
```bash
npm start
```
Inicia o servidor Python normal.

### Extrair Assets
```bash
npm run extract
```
Extrai e organiza todos os arquivos dos .DAT.

## 🌐 URLs Disponíveis

Após iniciar o servidor (`npm run dev`):

- **🎮 Jogo Web:** http://localhost:8000/fallout_game_web.html
- **🎨 Editor Web:** http://localhost:8000/fallout_web_editor.html
- **📊 Dashboard:** http://localhost:8000/dashboard.html
- **🖼️ Galeria de Sprites:** http://localhost:8000/sprite_gallery.html
- **🗺️ Visualizador de Mapas:** http://localhost:8000/map_viewer.html
- **📁 Navegador de Assets:** http://localhost:8000/asset_viewer.html
- **🏠 Página Inicial:** http://localhost:8000/

## 🔥 Hot Reload

O servidor de desenvolvimento monitora mudanças em:
- Arquivos `.html`
- Arquivos `.js`
- Arquivos `.css`

Quando você salvar um arquivo, o navegador pode recarregar automaticamente (depende do navegador).

## 📁 Estrutura

```
fallout2-ce/
├── package.json          # Configuração Node.js
├── web_server/           # Servidor e páginas web
│   ├── server.py        # Servidor principal
│   ├── dev_server.py    # Servidor de desenvolvimento
│   ├── *.html           # Páginas web
│   └── assets/          # Assets organizados
└── Fallout 2/           # Arquivos do jogo original
```

## 💡 Dicas

1. **Desenvolvimento Frontend:**
   - Edite arquivos `.html`, `.js`, `.css` em `web_server/`
   - Salve e veja as mudanças no navegador

2. **Desenvolvimento Backend:**
   - Edite `server.py` ou `dev_server.py`
   - Reinicie o servidor para aplicar mudanças

3. **Assets:**
   - Todos os assets estão em `web_server/assets/organized/`
   - Organizados por categoria (sprites, maps, scripts, etc.)

## 🛑 Parar o Servidor

Pressione `Ctrl+C` no terminal onde o servidor está rodando.

## ✅ Pronto!

Agora você pode desenvolver com:
- ✅ Hot reload
- ✅ Servidor local
- ✅ Todas as ferramentas web
- ✅ Assets organizados

**Bom desenvolvimento!** 🎮✨

