# 🎮 Como Usar o Projeto Godot

## ✅ Projeto Criado!

A estrutura base do projeto foi criada com sucesso.

## 📁 Estrutura Criada

```
godot_project/
├── project.godot          # Configuração do projeto
├── scenes/
│   └── main.tscn         # Cena principal
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd    # Gerenciador principal
│   │   └── map_manager.gd     # Gerenciador de mapas
│   └── actors/
│       └── player.gd          # Script do jogador
└── assets/
    └── sprites/               # Sprites convertidos (será preenchido)
```

## 🚀 Próximos Passos

### 1. Abrir o Projeto no Godot

1. Abra o **Godot 4.2+**
2. Clique em **"Import"**
3. Navegue até a pasta `godot_project`
4. Selecione a pasta e clique em **"Select Folder"**
5. Clique em **"Import & Edit"**

### 2. Verificar Configuração

1. O projeto deve abrir automaticamente
2. Verifique se a cena principal está configurada:
   - Vá em **Project → Project Settings → Application**
   - Verifique se **Run → Main Scene** está como `res://scenes/main.tscn`

### 3. Testar Execução Básica

1. Pressione **F5** para executar
2. Você deve ver uma janela preta (isso é normal - ainda não temos gráficos)
3. Pressione **ESC** para sair

### 4. Converter e Importar Sprites

Para converter sprites do Fallout 2:

```bash
cd tools
python convert_frm_to_godot.py "../web_server/assets/organized/sprites/items" "../godot_project/assets/sprites/items"
```

Depois no Godot:
1. Os PNGs aparecerão automaticamente no FileSystem
2. Clique direito em um PNG → **Open**
3. Configure as importações para pixel art:
   - **Filter**: ON
   - **Mipmaps**: OFF
4. Clique **Reimport**

### 5. Criar Primeira Cena de Teste

1. **File → New Scene**
2. Adicione um **Node2D** como root, nomeie como "TestScene"
3. Adicione um **CharacterBody2D** filho, nomeie como "Player"
4. Adicione um **Sprite2D** ou **AnimatedSprite2D** como filho do Player
5. Anexe o script `scripts/actors/player.gd` ao Player
6. Configure uma textura no sprite
7. Salve como `scenes/test_player.tscn`

### 6. Configurar Input

As ações de input já estão configuradas no `project.godot`:
- **W/↑**: move_up
- **S/↓**: move_down  
- **A/←**: move_left
- **D/→**: move_right
- **E**: interact
- **I**: inventory
- **ESC**: pause

## 📝 Scripts Disponíveis

### `game_manager.gd`
- Gerencia estado do jogo
- Carrega mapas
- Controla pausa/menu

### `player.gd`
- Movimento do jogador
- Sistema de action points
- Estatísticas SPECIAL
- Sistema de HP

### `map_manager.gd`
- Carrega mapas de arquivos JSON
- Cria tiles e objetos

## 🔧 Ajustes Necessários

### Para o Player Funcionar:

1. Na cena do player, adicione um **AnimatedSprite2D** como filho
2. No script `player.gd`, as animações "idle" e "walk" precisam ser criadas
3. Adicione um **CollisionShape2D** para colisões

Exemplo de setup:
```
Player (CharacterBody2D)
├── AnimatedSprite2D
└── CollisionShape2D
```

## ⚠️ Problemas Comuns

### "Node not found" ao executar
- Verifique se `main.tscn` está configurado como cena principal
- Certifique-se de que o GameManager está na cena principal

### Sprites não aparecem
- Verifique se os arquivos foram convertidos corretamente
- Force reimport no Godot (clique direito → Reimport)
- Verifique configurações de importação

### Movimento não funciona
- Verifique Input Map no Project Settings
- Certifique-se de que o script está anexado ao player
- Verifique se o GameManager está no estado PLAYING

## 📚 Próximas Funcionalidades

- [ ] Sistema de combate por turnos
- [ ] Sistema de inventário
- [ ] Sistema de diálogos
- [ ] Sistema de quests
- [ ] IA de NPCs
- [ ] Renderização isométrica completa

## 💡 Dicas

- Use **F6** para executar a cena atual (não o projeto inteiro)
- Use **F8** para abrir o debugger
- Organize assets em subpastas
- Use nomes descritivos para cenas e scripts

---

**Boa sorte com o desenvolvimento!** 🚀

