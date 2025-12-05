# Teste do Menu e Fluxo do Jogo

## Como Testar

### 1. Abrir o Projeto
```
Abra o Godot e carregue o projeto godot_project
```

### 2. Executar o Jogo
```
Pressione F5 ou clique em "Play" (▶)
```

### 3. Verificar Menu Principal
- [ ] Menu aparece com fundo do Fallout 2
- [ ] Botões visíveis: INTRO, NEW GAME, LOAD GAME, OPTIONS, CREDITS, EXIT
- [ ] Botões mudam de cor ao passar o mouse
- [ ] Botões respondem ao click

### 4. Testar New Game
1. Clique em "NEW GAME"
2. Deve aparecer tela de criação de personagem
3. Digite um nome (ou deixe vazio)
4. Clique em "START GAME"
5. Jogo deve carregar com mapa isométrico

### 5. Verificar Mapa
- [ ] Tiles aparecem em perspectiva isométrica (diamante)
- [ ] Player aparece no centro do mapa
- [ ] Player tem sprite do Vault Dweller
- [ ] HUD aparece na parte inferior
- [ ] Câmera segue o player

### 6. Testar Movimento
- [ ] Click no mapa move o player
- [ ] Player se move suavemente
- [ ] Animação de caminhada funciona
- [ ] Câmera acompanha o movimento

## Problemas Conhecidos e Soluções

### Problema: Botões não respondem
**Solução**: Verifique se o script está anexado à cena do menu

### Problema: Tela de criação não aparece
**Solução**: Verifique se o arquivo `character_creation.tscn` existe em `scenes/ui/`

### Problema: Mapa ainda aparece quebrado
**Solução**: 
1. Verifique se `IsometricRenderer` está registrado como autoload
2. Verifique se `game_scene.gd` tem o método `_convert_tiles_to_isometric()`

### Problema: Player não aparece
**Solução**: Verifique se a cena `player.tscn` existe e está correta

## Arquivos Modificados

1. `scripts/ui/main_menu_fallout2.gd` - Corrigido fluxo do menu
2. `scripts/core/game_manager.gd` - Adicionado suporte para criação de personagem
3. `scripts/core/game_scene.gd` - Adicionada conversão isométrica
4. `scenes/ui/character_creation.tscn` - Nova cena criada
5. `scripts/ui/character_creation.gd` - Novo script criado

## Debug

Se algo não funcionar, verifique o console do Godot para mensagens de erro.

Mensagens esperadas:
```
MainMenu: Carregado com sprites originais
MainMenu: Botoes configurados
MainMenu: NEW GAME pressionado - Carregando criação de personagem...
CharacterCreation: Tela carregada
CharacterCreation: Iniciando jogo com nome: [NOME]
GameScene: Inicializando...
GameScene: Convertendo tiles para isométrico...
GameScene: Player configurado em [POSIÇÃO]
GameScene: Pronto!
```
