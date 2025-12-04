# Implementation Plan: NPCs, Quest System e Conteúdo Jogável

> **Contexto**: Este plano assume que todos os sistemas core já estão implementados e funcionais.
> Foco: Expandir extração de animações, criar Quest System, e montar primeiro conteúdo jogável.

---

## FASE 1: EXTRAÇÃO COMPLETA DE ANIMAÇÕES

- [x] 1. Expandir CritterExtractor para todas as animações





  - [x] 1.1 Implementar extração de todos os tipos de animação


    - Adicionar suporte para: idle (aa), walk (ab), run (at), attack (an, ao, ap), death (ba-bm), hit (ao)
    - Extrair todas as 6 direções por animação
    - Organizar em pastas: `critters/{critter_id}/{animation_type}/`
    - _Requirements: 1.1, 1.3_

  - [x] 1.2 Escrever property test para completude de extração


    - **Property 1: FRM Frame Extraction Completeness**
    - **Validates: Requirements 1.1, 1.2**

  - [x] 1.3 Implementar geração de spritesheets


    - Combinar frames em spritesheet único por animação/direção
    - Gerar metadados JSON com timing e dimensões
    - _Requirements: 1.2_


  - [x] 1.4 Implementar conversão para SpriteFrames do Godot

    - Gerar arquivos .tres compatíveis com Godot 4.x
    - Configurar FPS baseado em timing original
    - Mapear 6 direções para 8 direções (duplicar NE→N, SE→S)
    - _Requirements: 2.2, 2.3_


  - [x] 1.5 Escrever property test para mapeamento de direções

    - **Property 3: Direction Mapping Consistency**
    - **Validates: Requirements 2.3**

  - [x] 1.6 Implementar validação de transparência


    - Garantir que índice 0 da paleta = alpha 0
    - Validar PNGs gerados
    - _Requirements: 2.1_

  - [x] 1.7 Escrever property test para transparência


    - **Property 2: PNG Transparency Correctness**
    - **Validates: Requirements 2.1**

- [ ] 2. Criar Catálogo de Criaturas
  - [ ] 2.1 Implementar geração de manifesto JSON
    - Listar todas as criaturas extraídas
    - Incluir metadados: nome, tipo, animações disponíveis, tamanho
    - Validar que todos os caminhos existem
    - _Requirements: 1.4, 3.1, 3.2_

  - [ ] 2.2 Escrever property test para completude do manifesto
    - **Property 4: Manifest Completeness**
    - **Validates: Requirements 1.4, 3.1, 3.4**

  - [ ] 2.3 Implementar filtro por tipo de criatura
    - Categorizar: human, animal, mutant, robot, creature
    - Permitir busca por tipo
    - _Requirements: 3.3_

  - [ ] 2.4 Escrever property test para filtro
    - **Property 5: Catalog Filter Correctness**
    - **Validates: Requirements 3.3**

- [ ] 3. Checkpoint - Verificar Extração
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 2: SISTEMA DE QUESTS

- [ ] 4. Criar estrutura base do Quest System
  - [ ] 4.1 Criar QuestData Resource
    - Definir campos: quest_id, title, description, objectives, rewards, prerequisites
    - Implementar enum State: INACTIVE, ACTIVE, READY_TO_COMPLETE, COMPLETED, FAILED
    - _Requirements: 4.1_

  - [ ] 4.2 Criar QuestObjective Resource
    - Definir campos: objective_id, description, type, target_id, required_count
    - Implementar tracking de progresso: current_count, is_complete
    - _Requirements: 4.2, 4.3_

  - [ ] 4.3 Criar QuestRewards Resource
    - Definir campos: experience, caps, items, reputation, unlocks
    - _Requirements: 5.3_

  - [ ] 4.4 Criar QuestSystem Autoload
    - Implementar dicionários: active_quests, completed_quests, failed_quests
    - Implementar signals: quest_added, quest_updated, quest_completed, quest_failed
    - Registrar como autoload no project.godot
    - _Requirements: 4.1, 6.1_

- [ ] 5. Implementar lógica de quests
  - [ ] 5.1 Implementar add_quest() e verificação de pré-requisitos
    - Verificar se pré-requisitos estão completos
    - Adicionar quest ao dicionário active_quests
    - Emitir signal quest_added
    - _Requirements: 4.4_

  - [ ] 5.2 Escrever property test para pré-requisitos
    - **Property 9: Quest Prerequisite Enforcement**
    - **Validates: Requirements 4.4**

  - [ ] 5.3 Implementar update_objective()
    - Atualizar progresso do objetivo específico
    - Verificar se objetivo foi completado
    - Verificar se todos objetivos estão completos → mudar estado para READY_TO_COMPLETE
    - _Requirements: 5.1, 5.2_

  - [ ] 5.4 Escrever property test para independência de objetivos
    - **Property 7: Objective Independence**
    - **Validates: Requirements 4.2**

  - [ ] 5.5 Escrever property test para bounds de contagem
    - **Property 8: Objective Count Bounds**
    - **Validates: Requirements 4.3**

  - [ ] 5.6 Implementar complete_quest() e fail_quest()
    - Mover quest para lista apropriada
    - Aplicar recompensas (complete) ou não (fail)
    - Emitir signals
    - _Requirements: 5.2, 5.3, 5.4_

  - [ ] 5.7 Escrever property test para máquina de estados
    - **Property 6: Quest State Machine Validity**
    - **Validates: Requirements 5.2, 5.4**

  - [ ] 5.8 Escrever property test para aplicação de recompensas
    - **Property 11: Reward Application Correctness**
    - **Validates: Requirements 5.3, 11.2**

  - [ ] 5.9 Implementar serialize() e deserialize()
    - Serializar estado completo para save/load
    - Integrar com SaveSystem existente
    - _Requirements: 4.5_

  - [ ] 5.10 Escrever property test para round-trip de serialização
    - **Property 10: Quest Serialization Round-Trip**
    - **Validates: Requirements 4.5, 11.5**

- [ ] 6. Checkpoint - Verificar Quest System Core
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Criar Quest Journal UI
  - [ ] 7.1 Criar cena QuestJournal
    - Layout com lista de quests à esquerda, detalhes à direita
    - Filtros: Ativas, Completadas, Falhadas
    - _Requirements: 6.1, 6.2_

  - [ ] 7.2 Escrever property test para organização do journal
    - **Property 12: Quest Journal Organization**
    - **Validates: Requirements 6.1**

  - [ ] 7.3 Implementar seleção e exibição de detalhes
    - Mostrar título, descrição, objetivos com progresso
    - Destacar quests atualizadas recentemente
    - _Requirements: 6.2, 6.4, 6.5_

  - [ ] 7.4 Integrar com GameManager
    - Adicionar estado QUEST_JOURNAL
    - Adicionar atalho J para abrir journal
    - _Requirements: 6.1_

- [ ] 8. Integrar Quest System com sistemas existentes
  - [ ] 8.1 Integrar com DialogSystem
    - Adicionar ação "start_quest" em opções de diálogo
    - Adicionar ação "complete_quest" para entrega
    - Modificar opções baseado em estado da quest
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ]* 8.2 Escrever property test para integração dialog-quest
    - **Property 13: Quest-Dialog Integration**
    - **Validates: Requirements 7.1, 7.3**

  - [ ] 8.3 Integrar com NPC
    - Adicionar NPCQuestIndicator como componente
    - Mostrar ícones: quest disponível (!), em progresso (?), pronta (!)
    - _Requirements: 7.5_

  - [ ]* 8.4 Escrever property test para indicadores de NPC
    - **Property 14: NPC Quest Indicator Correctness**
    - **Validates: Requirements 7.5**

  - [ ] 8.5 Integrar com SaveSystem
    - Adicionar QuestSystem.serialize() ao save_game()
    - Adicionar QuestSystem.deserialize() ao load_game()
    - _Requirements: 4.5_

- [ ] 9. Checkpoint - Verificar Quest System Completo
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 3: CONTEÚDO JOGÁVEL

- [ ] 10. Criar área inicial (Vila de Arroyo)
  - [ ] 10.1 Criar mapa JSON da vila
    - Definir tiles 50x50
    - Posicionar estruturas (cabanas, templo)
    - Definir spawn points para NPCs e player
    - _Requirements: 8.1, 8.2_

  - [ ]* 10.2 Escrever property test para spawn do player
    - **Property 18: Player Spawn Position**
    - **Validates: Requirements 8.2**

  - [ ] 10.3 Criar protótipos de NPCs
    - Ancião (quest giver)
    - Guerreiro (treinador)
    - Curandeira (mercador)
    - Guarda (hostil se provocado)
    - Aldeão (ambiente)
    - _Requirements: 8.4, 10.1_

  - [ ]* 10.4 Escrever property test para animações de NPC
    - **Property 15: NPC Animation State Consistency**
    - **Validates: Requirements 10.1, 12.1, 12.2**

  - [ ] 10.5 Criar diálogos para NPCs
    - Diálogo do Ancião com opção de quest
    - Diálogo da Curandeira com opção de comércio
    - Diálogos simples para outros NPCs
    - _Requirements: 10.2_

- [ ] 11. Criar quest inicial
  - [ ] 11.1 Definir quest "Prova do Guerreiro" em JSON
    - 3 objetivos: falar, matar, retornar
    - Recompensas: 100 XP, 50 caps, 2 stimpaks
    - _Requirements: 9.1, 9.2_

  - [ ] 11.2 Criar inimigos (ratos)
    - Protótipo de rato: HP 10, dano 1-3
    - Protótipo de rato grande: HP 20, dano 2-5
    - Spawnar na "caverna" (área do mapa)
    - _Requirements: 8.5, 9.3_

  - [ ]* 11.3 Escrever property test para detecção hostil
    - **Property 16: Hostile NPC Detection**
    - **Validates: Requirements 10.4, 11.3**

  - [ ] 11.4 Configurar triggers de quest
    - Trigger ao falar com Ancião → objetivo 1
    - Trigger ao matar rato → objetivo 2 (incrementar)
    - Trigger ao retornar → objetivo 3 e completar
    - _Requirements: 5.1_

- [ ] 12. Implementar gameplay loop
  - [ ] 12.1 Adicionar itens ao mapa
    - Containers com stimpaks
    - Faca como arma inicial
    - Caps espalhados
    - _Requirements: 11.1_

  - [ ] 12.2 Configurar loot de inimigos
    - Ratos dropam: 1-5 caps, chance de carne
    - _Requirements: 11.2_

  - [ ]* 12.3 Escrever property test para loot de NPC morto
    - **Property 17: NPC Death Loot Preservation**
    - **Validates: Requirements 10.5, 11.5**

  - [ ] 12.4 Testar progressão de nível
    - Verificar que XP da quest permite level up
    - _Requirements: 11.3_

  - [ ]* 12.5 Escrever property test para level up
    - **Property 19: Level Up Threshold**
    - **Validates: Requirements 11.3**

- [ ] 13. Checkpoint - Verificar Conteúdo Jogável
  - Ensure all tests pass, ask the user if questions arise.

---

## FASE 4: INTEGRAÇÃO FINAL

- [ ] 14. Testar gameplay completo
  - [ ] 14.1 Testar fluxo completo da quest
    - Iniciar jogo → falar com Ancião → aceitar quest
    - Ir à caverna → matar ratos → coletar loot
    - Retornar → entregar quest → receber recompensas
    - _Requirements: 9.1-9.5, 11.1-11.4_

  - [ ] 14.2 Testar save/load durante quest
    - Salvar no meio da quest
    - Carregar e verificar progresso mantido
    - _Requirements: 11.5_

  - [ ] 14.3 Testar todos os NPCs
    - Diálogos funcionam
    - Comércio funciona
    - Indicadores de quest aparecem
    - _Requirements: 10.1-10.5_

- [ ] 15. Checkpoint Final
  - Ensure all tests pass, ask the user if questions arise.
  - Verificar que o jogo é jogável do início ao fim
  - Confirmar gameplay loop: explorar → lutar → quest → recompensa → progredir

---

## Resumo de Dependências

| Tarefa | Depende de |
|--------|------------|
| Catálogo de Criaturas | Extração de Animações |
| Quest System Core | Nenhuma (sistemas existentes) |
| Quest Journal UI | Quest System Core |
| Integração Quest-Dialog | Quest System Core, DialogSystem ✅ |
| Área Inicial | Catálogo de Criaturas, Quest System |
| Quest Inicial | Área Inicial, Quest System |
| Gameplay Loop | Todos os anteriores |

---

## Arquivos a Criar

### Python (tools/)
- `tools/extractors/animation_extractor.py` - Extração completa de animações
- `tools/extractors/spriteframes_generator.py` - Geração de .tres
- `tools/extractors/critter_catalog.py` - Geração de catálogo

### GDScript (godot_project/scripts/)
- `scripts/systems/quest_system.gd` - Sistema de quests (autoload)
- `scripts/resources/quest_data.gd` - Resource de quest
- `scripts/resources/quest_objective.gd` - Resource de objetivo
- `scripts/resources/quest_rewards.gd` - Resource de recompensas
- `scripts/ui/quest_journal.gd` - UI do journal
- `scripts/components/npc_quest_indicator.gd` - Indicador visual

### Cenas (godot_project/scenes/)
- `scenes/ui/quest_journal.tscn` - Cena do journal

### Dados (godot_project/assets/data/)
- `data/quests/tutorial_01.json` - Quest inicial
- `data/maps/arroyo_village.json` - Mapa da vila
- `data/npcs/arroyo_npcs.json` - Protótipos de NPCs
- `data/dialogs/elder_dialog.json` - Diálogo do Ancião

### Testes
- `tools/tests/test_animation_extractor.py`
- `godot_project/tests/property/test_quest_state_machine.gd`
- `godot_project/tests/verify_quest_*.py`
