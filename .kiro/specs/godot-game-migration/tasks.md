# Implementation Plan: Migração Completa Fallout 2 para Godot

> **Prioridade de Implementação:**
> 1. Engine Core (renderização, câmera, input)
> 2. Sistemas de Gameplay (pathfinding, combate, inventário)
> 3. Carregamento de Dados (mapas, protótipos)
> 4. NPCs e Criaturas
> 5. Interface e Persistência

---

## FASE 1: ENGINE CORE E RENDERIZAÇÃO

- [x] 1. Implementar Sistema de Renderização Isométrica





  - [x] 1.1 Expandir IsometricRenderer com conversões precisas


    - Implementar `tile_to_screen()` com fórmula hexagonal correta
    - Implementar `screen_to_tile()` como inversa
    - Adicionar suporte a offset de sprites
    - _Requirements: 1.1, 1.5_
  - [x] 1.2 Escrever property test para round-trip de coordenadas


    - **Property 1: Isometric Coordinate Conversion Round-Trip**
    - **Validates: Requirements 1.1, 1.5**
  - [x] 1.3 Implementar ordenação de sprites por profundidade


    - Criar função `get_sort_order()` baseada em y + elevation * offset
    - Implementar `sort_sprites()` para reordenar nodes
    - Integrar com CanvasItem.z_index
    - _Requirements: 1.2_
  - [x] 1.4 Escrever property test para ordenação de sprites


    - **Property 2: Sprite Depth Ordering Consistency**
    - **Validates: Requirements 1.2**
  - [x] 1.5 Implementar sistema de camadas por elevação


    - Criar TileMapLayer para cada elevação
    - Implementar visibilidade por elevação atual
    - _Requirements: 1.4_
  - [x] 1.6 Escrever property test para separação de camadas


    - **Property 3: Elevation Layer Separation**
    - **Validates: Requirements 1.4**

- [x] 2. Implementar Sistema de Câmera Isométrica



  - [x] 2.1 Criar IsometricCamera com seguimento suave

    - Implementar seguimento do player com lerp
    - Adicionar configuração de suavização
    - _Requirements: 2.1_
  - [x] 2.2 Implementar limites de câmera

    - Calcular bounds do mapa atual
    - Clampar posição da câmera aos bounds
    - _Requirements: 2.2_
  - [x] 2.3 Escrever property test para clamping de câmera


    - **Property 4: Camera Bounds Clamping**
    - **Validates: Requirements 2.2**
  - [x] 2.4 Implementar zoom da câmera

    - Adicionar zoom in/out com scroll do mouse
    - Definir limites de zoom (0.5x a 2x)
    - _Requirements: 2.3_

- [x] 3. Implementar Sistema de Input e Cursor



  - [x] 3.1 Criar InputManager para processar clicks


    - Detectar click esquerdo para movimento/interação
    - Detectar click direito para alternar modo
    - Converter posição de tela para tile
    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 3.2 Implementar sistema de cursor contextual


    - Criar sprites de cursor para cada modo
    - Mudar cursor ao passar sobre objetos interagíveis
    - Mostrar tooltip com nome do objeto
    - _Requirements: 3.4_
  - [x] 3.3 Implementar atalhos de teclado


    - Mapear teclas: I=inventário, C=personagem, P=pipboy, ESC=pause
    - Integrar com GameManager para abrir menus
    - _Requirements: 3.5_

- [x] 4. Checkpoint - Verificar Engine Core
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 2: SISTEMAS DE GAMEPLAY CORE

- [x] 5. Implementar Sistema de Pathfinding



  - [x] 5.1 Criar Pathfinder com algoritmo A*


    - Implementar A* para grade hexagonal
    - Criar heurística de distância hexagonal
    - Suportar múltiplas elevações
    - _Requirements: 4.1_
  - [x] 5.2 Implementar detecção de obstáculos

    - Integrar com MapSystem para tiles bloqueados
    - Considerar NPCs como obstáculos temporários
    - Retornar caminho vazio se impossível
    - _Requirements: 4.2_

  - [x] 5.3 Escrever property test para validade de caminhos

    - **Property 5: Pathfinding Validity**
    - **Validates: Requirements 4.1, 4.2**
  - [x] 5.4 Integrar pathfinding com movimento do player


    - Player segue caminho calculado
    - Consumir AP em combate (1 por hex)
    - _Requirements: 4.3_
  - [x] 5.5 Escrever property test para consumo de AP


    - **Property 6: Movement AP Consumption**
    - **Validates: Requirements 4.3**
  - [x] 5.6 Implementar corrida (Shift)

    - Aumentar velocidade em 50% quando Shift pressionado
    - _Requirements: 4.4_
  - [x] 5.7 Escrever property test para velocidade de corrida

    - **Property 7: Run Speed Multiplier**
    - **Validates: Requirements 4.4**

- [x] 6. Expandir Sistema de Combate




  - [x] 6.1 Implementar ordenação por Sequence

    - Calcular Sequence = Perception * 2
    - Ordenar combatentes em ordem decrescente
    - _Requirements: 5.1_

  - [x] 6.2 Escrever property test para ordem de turno

    - **Property 8: Combat Turn Order by Sequence**
    - **Validates: Requirements 5.1**
  - [x] 6.3 Implementar fórmula de hit chance


    - Hit = Skill - (Distance * 4) - Target_AC + (Perception * 2)
    - Clampar entre 5% e 95%
    - _Requirements: 5.3_
  - [x] 6.4 Escrever property test para hit chance


    - **Property 9: Hit Chance Formula Correctness**
    - **Validates: Requirements 5.3**
  - [x] 6.5 Implementar fórmula de dano


    - Damage = Weapon_Damage + Strength_Bonus - (DR * Damage / 100)
    - Mínimo de 1 de dano
    - _Requirements: 5.4_
  - [x] 6.6 Escrever property test para dano


    - **Property 10: Damage Formula Correctness**
    - **Validates: Requirements 5.4**
  - [x] 6.7 Implementar condições de fim de combate


    - Detectar quando todos inimigos morrem
    - Transicionar para estado INACTIVE
    - _Requirements: 5.5, 5.6_
  - [x] 6.8 Escrever property test para consistência de estado


    - **Property 11: Combat State Consistency**
    - **Validates: Requirements 5.5, 5.6**

- [x] 7. Checkpoint - Verificar Pathfinding e Combate
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Expandir Sistema de Inventário
  - [x] 8.1 Implementar cálculo de peso total
    - Somar peso * quantidade de todos itens
    - Emitir signal quando peso muda
    - _Requirements: 6.1_
  - [x] 8.2 Escrever property test para cálculo de peso
    - **Property 12: Inventory Weight Calculation**
    - **Validates: Requirements 6.1**
  - [x] 8.3 Implementar sistema de equipamento
    - Criar slots: arma primária, secundária, armadura
    - Atualizar stats ao equipar/desequipar
    - _Requirements: 6.2_
  - [x] 8.4 Escrever property test para consistência de equipamento
    - **Property 13: Equipment Slot Consistency**
    - **Validates: Requirements 6.2**
  - [x] 8.5 Implementar uso de consumíveis
    - Aplicar efeito do item ao alvo
    - Reduzir quantidade ou remover item
    - _Requirements: 6.3_
  - [x] 8.6 Escrever property test para uso de consumíveis
    - **Property 14: Consumable Usage Effect**
    - **Validates: Requirements 6.3**
  - [x] 8.7 Implementar verificação de encumbrance
    - Bloquear movimento se peso > capacidade
    - Mostrar aviso ao jogador
    - _Requirements: 6.4_
  - [x] 8.8 Escrever property test para encumbrance
    - **Property 15: Encumbrance Movement Block**
    - **Validates: Requirements 6.4**

- [ ] 9. Expandir Sistema de Diálogo
  - [ ] 9.1 Implementar verificação de requisitos
    - Checar skill, stat, item, reputação
    - Habilitar/desabilitar opções baseado em requisitos
    - _Requirements: 7.2_
  - [ ] 9.2 Escrever property test para requisitos de diálogo
    - **Property 16: Dialog Option Requirement Check**
    - **Validates: Requirements 7.2**
  - [ ] 9.3 Implementar substituição de variáveis
    - Parsear placeholders {var_name}
    - Substituir por valores do game state
    - _Requirements: 7.5_
  - [ ] 9.4 Escrever property test para substituição de variáveis
    - **Property 17: Dialog Variable Substitution**
    - **Validates: Requirements 7.5**
  - [ ] 9.5 Implementar ações de diálogo
    - Dar/remover item, XP, reputação
    - Iniciar combate, abrir comércio
    - _Requirements: 7.3_

- [ ] 10. Checkpoint - Verificar Inventário e Diálogo
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 3: CARREGAMENTO DE DADOS E MAPAS

- [ ] 11. Implementar MapLoader
  - [ ] 11.1 Criar parser de mapas JSON
    - Ler estrutura de mapa (tiles, objetos, NPCs)
    - Validar dados antes de instanciar
    - _Requirements: 8.1_
  - [ ] 11.2 Implementar instanciação de tiles
    - Criar TileMapLayer para cada elevação
    - Posicionar tiles usando IsometricRenderer
    - _Requirements: 8.1, 8.2_
  - [ ] 11.3 Implementar spawn de objetos e NPCs
    - Instanciar objetos interagíveis
    - Spawnar NPCs com protótipos
    - _Requirements: 8.1_
  - [ ] 11.4 Escrever property test para completude de carregamento
    - **Property 18: Map Loading Completeness**
    - **Validates: Requirements 8.1, 8.2, 8.5**
  - [ ] 11.5 Implementar persistência de estado do mapa
    - Salvar modificações ao descarregar
    - Restaurar estado ao recarregar
    - _Requirements: 8.4_
  - [ ] 11.6 Escrever property test para persistência de mapa
    - **Property 19: Map State Persistence**
    - **Validates: Requirements 8.4**
  - [ ] 11.7 Implementar transições de mapa
    - Detectar áreas de saída
    - Carregar novo mapa na entrada correta
    - _Requirements: 8.3_

- [ ] 12. Implementar PrototypeSystem
  - [ ] 12.1 Criar loader de protótipos JSON
    - Carregar item_prototypes.json
    - Carregar critter_prototypes.json
    - _Requirements: 9.1, 9.2_
  - [ ] 12.2 Implementar criação de instâncias
    - Criar ItemData a partir de protótipo
    - Criar CritterData a partir de protótipo
    - _Requirements: 9.1, 9.2_
  - [ ] 12.3 Escrever property test para aplicação de protótipos
    - **Property 20: Prototype Application Correctness**
    - **Validates: Requirements 9.1, 9.2**
  - [ ] 12.4 Implementar isolamento de instâncias
    - Modificações em instância não afetam protótipo
    - _Requirements: 9.4_
  - [ ] 12.5 Escrever property test para isolamento
    - **Property 21: Prototype Instance Isolation**
    - **Validates: Requirements 9.4**

- [ ] 13. Implementar ScriptSystem básico
  - [ ] 13.1 Criar parser de scripts JSON
    - Ler estrutura de script (triggers, procedures)
    - Validar sintaxe
    - _Requirements: 10.1_
  - [ ] 13.2 Implementar variáveis globais
    - Armazenar variáveis em dicionário global
    - Permitir leitura/escrita por scripts
    - _Requirements: 10.3_
  - [ ] 13.3 Escrever property test para variáveis globais
    - **Property 22: Script Global Variable Round-Trip**
    - **Validates: Requirements 10.3**
  - [ ] 13.4 Implementar funções builtin básicas
    - display_msg, give_item, add_xp, etc.
    - _Requirements: 10.4_

- [ ] 14. Checkpoint - Verificar Carregamento de Dados
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 4: NPCs E CRIATURAS

- [ ] 15. Expandir Sistema de NPCs
  - [ ] 15.1 Integrar NPCs com PrototypeSystem
    - Carregar stats e comportamento do protótipo
    - Aplicar aparência (sprites) do protótipo
    - _Requirements: 11.1_
  - [ ] 15.2 Implementar morte de NPC
    - Criar corpo com inventário acessível
    - Manter corpo no mapa
    - _Requirements: 11.5_
  - [ ] 15.3 Escrever property test para inventário de corpo
    - **Property 23: NPC Death Inventory Access**
    - **Validates: Requirements 11.5**
  - [ ] 15.4 Implementar IA de NPC hostil
    - Detectar player em range
    - Iniciar combate automaticamente
    - _Requirements: 11.3_
  - [ ] 15.5 Implementar NPC mercador
    - Abrir interface de comércio
    - Gerenciar estoque do mercador
    - _Requirements: 11.4_

- [ ] 16. Implementar Sistema de Animações
  - [ ] 16.1 Criar AnimationController para criaturas
    - Gerenciar estados: idle, walk, attack, death
    - Carregar spritesheets por direção
    - _Requirements: 12.1, 12.2, 12.3, 12.4_
  - [ ] 16.2 Implementar transição de direção
    - Detectar mudança de direção
    - Trocar spritesheet suavemente
    - _Requirements: 12.5_
  - [ ] 16.3 Integrar animações com Player e NPCs
    - Player usa AnimationController
    - NPCs usam AnimationController
    - _Requirements: 12.1-12.5_

- [ ] 17. Checkpoint - Verificar NPCs e Animações
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 5: INTERFACE DO USUÁRIO

- [ ] 18. Expandir HUD Principal
  - [ ] 18.1 Implementar barra de HP dinâmica
    - Atualizar em tempo real
    - Mostrar valor numérico
    - _Requirements: 13.1_
  - [ ] 18.2 Implementar barra de AP
    - Mostrar AP atual/máximo
    - Destacar em combate
    - _Requirements: 13.1, 13.2_
  - [ ] 18.3 Implementar slot de arma
    - Mostrar arma equipada
    - Permitir troca rápida
    - _Requirements: 13.1_
  - [ ] 18.4 Implementar tooltips
    - Mostrar info ao passar mouse
    - _Requirements: 13.3_

- [ ] 19. Implementar Menus
  - [ ] 19.1 Criar tela de personagem
    - Exibir stats SPECIAL
    - Exibir skills e perks
    - _Requirements: 14.1_
  - [ ] 19.2 Criar tela de inventário completa
    - Grid de itens
    - Slots de equipamento
    - Info de peso
    - _Requirements: 14.2_
  - [ ] 19.3 Criar tela de opções
    - Volume de áudio
    - Dificuldade
    - Controles
    - _Requirements: 14.3_
  - [ ] 19.4 Implementar pausa ao abrir menu
    - Pausar jogo quando menu abre
    - Não pausar em combate
    - _Requirements: 14.5_
  - [ ] 19.5 Escrever property test para estado de pausa
    - **Property 24: Menu Pause State**
    - **Validates: Requirements 14.5**

- [ ] 20. Checkpoint - Verificar Interface
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 6: PERSISTÊNCIA E SAVE/LOAD

- [ ] 21. Expandir Sistema de Save/Load
  - [ ] 21.1 Implementar serialização completa
    - Serializar player (posição, stats, inventário)
    - Serializar estado do mapa (objetos modificados)
    - Serializar variáveis globais
    - _Requirements: 15.1_
  - [ ] 21.2 Implementar deserialização
    - Restaurar player
    - Restaurar mapa
    - Restaurar variáveis
    - _Requirements: 15.2_
  - [ ] 21.3 Escrever property test para round-trip de save
    - **Property 25: Save/Load Round-Trip**
    - **Validates: Requirements 15.1, 15.2**
  - [ ] 21.4 Implementar metadados de save
    - Capturar screenshot
    - Registrar timestamp e localização
    - _Requirements: 15.3_
  - [ ] 21.5 Escrever property test para metadados
    - **Property 26: Save Metadata Completeness**
    - **Validates: Requirements 15.3**
  - [ ] 21.6 Implementar checksum e validação
    - Calcular checksum do save
    - Validar ao carregar
    - _Requirements: 15.4_
  - [ ] 21.7 Escrever property test para detecção de corrupção
    - **Property 27: Save Corruption Detection**
    - **Validates: Requirements 15.4**
  - [ ] 21.8 Implementar quicksave/quickload
    - F6 para quicksave
    - F9 para quickload
    - _Requirements: 15.5, 15.6_

- [ ] 22. Checkpoint - Verificar Save/Load
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 7: ÁUDIO

- [ ] 23. Implementar Sistema de Áudio
  - [ ] 23.1 Criar AudioManager
    - Gerenciar música ambiente
    - Gerenciar efeitos sonoros
    - _Requirements: 16.1, 16.2_
  - [ ] 23.2 Implementar transição de música
    - Crossfade entre tracks
    - Mudar música por área
    - _Requirements: 16.1_
  - [ ] 23.3 Implementar efeitos sonoros
    - Tocar sons de ações (ataque, passo, etc.)
    - Posicionamento 2D básico
    - _Requirements: 16.2_
  - [ ] 23.4 Implementar controle de volume
    - Volumes separados (master, music, sfx, voice)
    - Aplicar configurações imediatamente
    - _Requirements: 16.4_
  - [ ] 23.5 Escrever property test para aplicação de volume
    - **Property 28: Audio Volume Application**
    - **Validates: Requirements 16.4**

- [ ] 24. Checkpoint Final - Verificar todos os sistemas
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 8: INTEGRAÇÃO E CONTEÚDO

- [ ] 25. Criar Primeiro Mapa Jogável
  - [ ] 25.1 Converter mapa de Arroyo para JSON
    - Usar dados extraídos do original
    - Definir tiles, objetos, NPCs
    - _Requirements: 8.1_
  - [ ] 25.2 Criar NPCs de Arroyo
    - Definir protótipos dos NPCs
    - Criar diálogos básicos
    - _Requirements: 11.1_
  - [ ] 25.3 Testar gameplay completo
    - Movimento, combate, diálogo
    - Save/load
    - _Requirements: All_

- [ ] 26. Checkpoint Final - Jogo Funcional
  - Verificar que o jogo é jogável do início ao fim em Arroyo
  - Confirmar que todos os sistemas funcionam integrados
  - Testar save/load em diferentes pontos

---

## Resumo de Dependências

| Tarefa | Depende de |
|--------|------------|
| Pathfinding | IsometricRenderer |
| Combat (expandido) | Pathfinding |
| MapLoader | IsometricRenderer, PrototypeSystem |
| NPCs (expandido) | PrototypeSystem, Combat |
| Save/Load | Todos os sistemas |
| Primeiro Mapa | Todos os sistemas |
