# ⚡ INÍCIO RÁPIDO: Migração para Godot

## 🎯 Quer começar AGORA? Siga estes passos:

### 1️⃣ Preparar Ambiente (5 minutos)

#### Instalar Godot
1. Baixe Godot 4.2+: https://godotengine.org/download
2. Extraia e execute (não precisa instalar)

#### Instalar Python (para scripts de conversão)
1. Python 3.7+: https://www.python.org/downloads/
2. Instale dependências:
```bash
cd tools
pip install -r requirements.txt
```

### 2️⃣ Criar Projeto Godot (2 minutos)

Execute o script de setup:
```bash
cd tools
python setup_godot_project.py ../godot_project
```

Ou crie manualmente:
1. Abra o Godot
2. Clique em "New Project"
3. Nome: `fallout2-godot`
4. Local: escolha uma pasta
5. Clique "Create & Edit"

### 3️⃣ Converter Primeiro Sprite (5 minutos)

Para testar a conversão:
```bash
cd tools
python convert_frm_to_godot.py ../web_server/assets/organized/sprites/characters ../godot_project/assets/sprites
```

Isso vai:
- Converter alguns sprites .FRM para PNG
- Criar estrutura organizada
- Gerar metadados JSON

### 4️⃣ Importar no Godot (3 minutos)

1. No Godot, vá em **FileSystem**
2. Os PNGs aparecerão automaticamente
3. Clique direito em um PNG → **Open**
4. Na aba **Import**, configure:
   - **Filter**: ON (para pixel art)
   - **Mipmaps**: OFF
5. Clique **Reimport**

### 5️⃣ Criar Primeira Cena (10 minutos)

1. **File → New Scene**
2. Adicione um **Node2D** como root
3. Salve como `scenes/test.tscn`
4. Adicione um **Sprite2D** filho
5. No Inspector, clique em **Texture** → **Load**
6. Selecione um sprite convertido
7. Execute (F5) para ver!

### 6️⃣ Adicionar Script Básico (10 minutos)

Crie `scripts/test_player.gd`:
```gdscript
extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(delta):
    var input_vector = Vector2.ZERO
    
    if Input.is_action_pressed("move_up"):
        input_vector.y -= 1
    if Input.is_action_pressed("move_down"):
        input_vector.y += 1
    if Input.is_action_pressed("move_left"):
        input_vector.x -= 1
    if Input.is_action_pressed("move_right"):
        input_vector.x += 1
    
    velocity = input_vector.normalized() * speed
    move_and_slide()
```

Anexe o script ao Node2D na cena de teste.

### 7️⃣ Testar! (1 minuto)

1. Execute (F5)
2. Use WASD ou setas para mover
3. Você tem um jogo básico funcionando! 🎉

---

## 📋 Checklist Rápido

- [ ] Godot instalado
- [ ] Projeto Godot criado
- [ ] Scripts Python instalados
- [ ] Primeiro sprite convertido
- [ ] Sprite importado no Godot
- [ ] Primeira cena criada
- [ ] Movimento básico funcionando

---

## 🎯 Próximos Passos

Agora que você tem o básico:

1. **Converter mais sprites** - Use o script para converter todos
2. **Criar sistema de mapas** - Ver `MIGRACAO_GODOT.md` Fase 3
3. **Implementar combate** - Sistema de turnos
4. **Adicionar UI** - Menus e HUD

---

## ❓ Problemas Comuns

### Script não executa
- Verifique se Python está instalado: `python --version`
- Instale Pillow: `pip install Pillow`

### Sprites não aparecem no Godot
- Verifique se os arquivos estão na pasta `assets/`
- Force reimport: Clique direito → **Reimport**

### Movimento não funciona
- Verifique se as ações estão configuradas no Input Map
- Verifique se o script está anexado ao node correto

---

## 🚀 Dica Final

**Não tente converter tudo de uma vez!**
- Comece com 1-2 sprites
- Teste no Godot
- Ajuste scripts se necessário
- Depois converta mais

**Um passo de cada vez = Sucesso garantido!** ✨

---

## 📚 Documentação Completa

Para mais detalhes, veja:
- `MIGRACAO_GODOT.md` - Guia completo
- `godot_project_setup.md` - Configuração detalhada
- `tools/README.md` - Documentação dos scripts

