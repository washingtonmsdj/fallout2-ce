# 🎮 Como Usar o Editor Web Interativo

## 🎯 O QUE FOI CRIADO

Um **editor web completo** usando **PixiJS** que permite:

✅ **Visualizar** sprites do Fallout 2  
✅ **Editar** propriedades em tempo real  
✅ **Animar** sprites  
✅ **Exportar** frames  
✅ **Interagir** com os sprites (arrastar, zoom, rotacionar)  

## 🚀 COMO USAR

### Passo 1: Extrair Assets

Primeiro, extraia os sprites:

```bash
cd web_server
python extract_all_dat.py
```

### Passo 2: Converter para PNG (Opcional)

Se quiser ver os sprites convertidos:

```bash
python frm_to_png.py
```

### Passo 3: Iniciar Servidor

```bash
python server.py
```

### Passo 4: Abrir Editor

```
http://localhost:8000/fallout_web_editor.html
```

## 🎮 FUNCIONALIDADES

### Visualização
- ✅ Ver todos os sprites disponíveis
- ✅ Carregar sprites na tela
- ✅ Visualizar frames individuais
- ✅ Animar sprites automaticamente

### Edição Interativa
- ✅ **Escala** - Aumentar/diminuir tamanho
- ✅ **Rotação** - Girar sprite
- ✅ **Posição** - Arrastar com mouse
- ✅ **Zoom** - Scroll do mouse

### Controles
- 🖱️ **Arrastar** - Mover sprite
- 🔍 **Scroll** - Zoom in/out
- ⌨️ **Espaço** - Pausar animação
- ⌨️ **R** - Resetar posição

### Exportação
- 💾 Exportar frame atual como PNG
- 📋 Copiar informações do sprite

## 🛠️ TECNOLOGIAS USADAS

### PixiJS
- Biblioteca de renderização 2D
- Performance otimizada
- Suporte a WebGL
- Fácil de usar

### HTML5 Canvas
- Renderização acelerada
- Suporte a imagens
- Manipulação de pixels

### JavaScript
- Lógica do editor
- Interatividade
- Carregamento de assets

## 📋 ESTRUTURA

```
fallout_web_editor.html
├── Sidebar Esquerda
│   └── Lista de sprites
├── Área Central
│   └── Canvas PixiJS (visualização)
└── Sidebar Direita
    ├── Informações do sprite
    ├── Controles (escala, rotação, frame)
    └── Botões (animar, exportar, editar)
```

## 💡 PRÓXIMAS FUNCIONALIDADES

### Planejadas:
- ✏️ Editor de pixels
- 🎨 Editor de paleta de cores
- ➕ Adicionar/remover frames
- 💾 Salvar modificações
- 📤 Upload de sprites customizados
- 🔄 Comparar sprites lado a lado

## 🎯 VANTAGENS DO PIXIJS

### Por que PixiJS?

1. **Performance:**
   - Usa WebGL quando disponível
   - Renderização acelerada por GPU
   - Suporte a muitos sprites

2. **Facilidade:**
   - API simples e intuitiva
   - Boa documentação
   - Muitos exemplos

3. **Compatibilidade:**
   - Funciona em todos os navegadores
   - Suporte a mobile
   - Fallback para Canvas2D

4. **Recursos:**
   - Animações
   - Filtros
   - Máscaras
   - Partículas

## 🔧 PERSONALIZAÇÃO

### Adicionar Mais Funcionalidades:

```javascript
// Exemplo: Adicionar filtro
sprite.filters = [new PIXI.filters.BlurFilter()];

// Exemplo: Adicionar máscara
sprite.mask = maskSprite;

// Exemplo: Adicionar partículas
const particles = new PIXI.particles.ParticleContainer();
```

## 📚 RECURSOS

- **PixiJS Docs:** https://pixijs.com/
- **Exemplos:** https://pixijs.com/examples
- **API Reference:** https://pixijs.download/release/docs/index.html

## ✅ RESUMO

1. **Extraia** os assets
2. **Inicie** o servidor
3. **Abra** o editor web
4. **Visualize** e **edite** os sprites
5. **Exporte** suas modificações

**Agora você tem liberdade total para visualizar e editar os sprites do Fallout 2 na web!** 🎮✨

