# 🎨 PLANO: Menu Original do Fallout 2

## 📋 ANÁLISE DO MENU ORIGINAL:

### Assets Necessários:
1. **MAINMENU.FRM** - Background do menu (640x480)
2. **MENUUP.FRM** - Botão normal (pressionado)
3. **MENUDOWN.FRM** - Botão pressionado
4. **Mensagens de texto** - Para textos dos botões

### Estrutura Original:
- Background: 640x480 pixels
- 6 botões: Intro, New Game, Load Game, Options, Credits, Exit
- Texto de copyright e versão
- Música de fundo

## 🔧 PASSO A PASSO:

### 1. Converter Sprites do Menu
```bash
# Converter MAINMENU.FRM
python tools/convert_frm_to_godot.py "web_server/assets/organized/sprites/other" "godot_project/assets/sprites/ui" --limit 3

# Arquivos específicos:
# - MAINMENU.FRM → mainmenu.png
# - MENUUP.FRM → menuup.png  
# - MENUDOWN.FRM → menudown.png
```

### 2. Criar Cena do Menu Original
- Usar TextureRect para background
- Criar botões customizados usando as texturas
- Posicionar botões corretamente
- Adicionar textos

### 3. Integrar no Projeto
- Substituir menu atual
- Manter funcionalidades
- Melhorar com recursos do Godot

## 📝 NOTAS:

- Menu original é 640x480
- Precisamos escalar para 1024x768 (ou manter proporção)
- Botões devem usar as texturas originais
- Textos podem ser adicionados via Label

---

**Status**: Preparado - aguardando conversão dos sprites

