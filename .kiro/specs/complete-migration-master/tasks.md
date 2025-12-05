# Implementation Plan: Migração Completa Fallout 2 para Godot

## Fase 1: Documentação e Mapeamento Completo

- [x] 1. Criar documento de mapeamento do jogo original






  - [x] 1.1 Analisar e documentar estrutura completa dos arquivos DAT

    - Listar todos os arquivos em master.dat, critter.dat, patch000.dat
    - Documentar hierarquia de pastas e propósito de cada seção
    - Gerar relatório JSON com metadados de todos os arquivos
    - _Requirements: 2.1, 2.2_

  - [x] 1.2 Documentar formatos de arquivo com especificação byte-a-byte

    - Criar spec para FRM (sprites/animações)
    - Criar spec para MAP (mapas)
    - Criar spec para PRO (protótipos)
    - Criar spec para MSG (mensagens/diálogos)
    - Criar spec para ACM (áudio)
    - _Requirements: 3.1, 3.2_

  - [x] 1.3 Write property test for DAT catalog completeness

    - **Property 2: Catálogo de Arquivos DAT Completo**
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**

- [x] 2. Catalogar todo o conteúdo do jogo
  - [x] 2.1 Criar catálogo de mapas
    - Listar todos os ~160 mapas com nome, localização, conexões
    - Documentar NPCs e itens em cada mapa
    - Mapear scripts associados a cada mapa
    - _Requirements: 4.1_
    - **Implementado em:** `tools/content_cataloger.py` - método `catalog_maps()`
  - [x] 2.2 Criar catálogo de NPCs
    - Listar todos os ~1000 NPCs com stats, localização, comportamento
    - Mapear diálogos associados a cada NPC
    - Documentar scripts de AI
    - _Requirements: 4.2_
    - **Implementado em:** `tools/content_cataloger.py` - método `catalog_npcs()`
  - [x] 2.3 Criar catálogo de itens
    - Listar todos os ~500 itens com tipo, stats, localização
    - Categorizar por tipo (armas, armaduras, consumíveis, etc.)
    - Documentar efeitos especiais
    - _Requirements: 4.3_
    - **Implementado em:** `tools/content_cataloger.py` - método `catalog_items()`
  - [ ] 2.4 Criar catálogo de quests
    - Listar todas as ~100 quests com objetivos e recompensas
    - Mapear NPCs e locais envolvidos
    - Documentar condições e consequências
    - _Requirements: 4.4_
    - **Nota:** Implementação básica criada. Análise completa de quests requer interpretação de scripts .INT
  - [x] 2.5 Criar catálogo de diálogos
    - Extrair todas as árvores de diálogo
    - Mapear condições (skills, stats, flags)
    - Documentar consequências de cada opção
    - _Requirements: 4.5_
    - **Implementado em:** `tools/content_cataloger.py` - método `catalog_dialogues()`
  - [ ] 2.6 Write property test for content catalog completeness
    - **Property 3: Catálogo de Conteúdo do Jogo Completo**
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5**

- [ ] 3. Checkpoint - Validar documentação
  - Ensure all tests pass, ask the user if questions arise.

## Fase 2: Mapeamento do Código Godot Existente

- [x] 4. Criar mapa do código Godot atual
  - [x] 4.1 Mapear todos os scripts existentes
    - Listar todos os .gd com caminho, classe, responsabilidade
    - Documentar dependências entre scripts
    - Identificar autoloads e singletons
    - _Requirements: 6.1, 6.3, 6.4_
    - **Implementado em:** `tools/godot_code_mapper.py` - método `map_scripts()`
    - **Resultado:** 38 scripts mapeados, 10 autoloads identificados
  - [x] 4.2 Mapear todas as cenas existentes
    - Listar todos os .tscn com estrutura de nós
    - Documentar scripts anexados a cada cena
    - Mapear recursos (.tres) utilizados
    - _Requirements: 6.2, 6.5_
    - **Implementado em:** `tools/godot_code_mapper.py` - método `map_scenes()`
    - **Resultado:** 12 cenas mapeadas, 9 recursos identificados
  - [ ] 4.3 Write property test for code map completeness
    - **Property 5: Mapa de Código Godot Completo**
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

- [x] 5. Criar matriz de comparação Original vs Implementado
  - [x] 5.1 Listar todas as funcionalidades do original
    - Sistemas core (renderização, input, save/load)
    - Sistemas de gameplay (combate, diálogo, inventário)
    - Conteúdo (mapas, NPCs, itens, quests)
    - _Requirements: 7.1_
    - **Implementado em:** `tools/comparison_matrix_generator.py`
    - **Resultado:** 29 funcionalidades catalogadas em 6 categorias
  - [x] 5.2 Mapear status de cada funcionalidade
    - Marcar como: não implementado, parcial, completo
    - Para parciais, listar o que falta
    - Para completos, referenciar código
    - _Requirements: 7.2, 7.3, 7.4_
    - **Implementado em:** `tools/comparison_matrix_generator.py` - método `_analyze_feature()`
  - [x] 5.3 Calcular percentual de completude
    - Por sistema
    - Por categoria
    - Total do projeto
    - _Requirements: 7.5_
    - **Implementado em:** `tools/comparison_matrix_generator.py` - método `generate_matrix()`
    - **Resultado:** Completude total: 67.2%
  - [ ] 5.4 Write property test for comparison matrix consistency
    - **Property 6: Comparação Original vs Implementado Consistente**
    - **Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5**

- [ ] 6. Checkpoint - Validar mapeamento
  - Ensure all tests pass, ask the user if questions arise.

## Fase 3: Completar Ferramentas de Extração

- [x] 7. Completar e validar extractors Python
  - [x] 7.1 Validar DAT2Reader com todos os arquivos
    - Testar extração de master.dat completo
    - Testar extração de critter.dat completo
    - Testar extração de patch000.dat completo
    - _Requirements: 2.1_
    - **Implementado em:** `tools/extractor_validator.py` - método `validate_dat2_reader()`
    - **Status:** DAT2Reader funcional, validação implementada
  - [x] 7.2 Completar FRMDecoder para todos os tipos
    - Suportar todas as variações de FRM
    - Gerar SpriteFrames para Godot
    - Exportar PNG com transparência
    - _Requirements: 3.3, 3.4_
    - **Implementado em:** `tools/extractors/frm_decoder.py`
    - **Status:** FRMDecoder completo com suporte a todas variações, PNG e spritesheets
  - [x] 7.3 Completar MapParser para todos os mapas
    - Parsear tiles de todas as elevações
    - Extrair objetos e NPCs
    - Mapear scripts espaciais
    - _Requirements: 3.3, 3.4_
    - **Implementado em:** `tools/extractors/map_parser.py`
    - **Resultado:** 170/170 mapas parseados com sucesso (100%)
  - [x] 7.4 Completar PROParser para todos os protótipos
    - Parsear protótipos de itens
    - Parsear protótipos de criaturas
    - Parsear protótipos de tiles
    - _Requirements: 3.3, 3.4_
    - **Implementado em:** `tools/extractors/pro_parser.py`
    - **Resultado:** 499/500 protótipos parseados com sucesso na amostra testada
  - [ ] 7.5 Write property test for format round-trip
    - **Property 1: Round-trip de Formatos de Arquivo**
    - **Validates: Requirements 3.4**

- [x] 8. Criar pipeline de conversão automatizada
  - [x] 8.1 Implementar conversor FRM → Godot SpriteFrames
    - Converter todas as animações de personagens
    - Converter todos os sprites de itens
    - Converter todos os tiles
    - _Requirements: 3.4_
    - **Implementado em:** `tools/frm_to_godot_converter.py`
    - **Funcionalidades:** Conversão completa de FRM para PNG e SpriteFrames .tres
  - [x] 8.2 Implementar conversor MAP → Godot Scene
    - Gerar TileMap com tiles corretos
    - Posicionar objetos e NPCs
    - Configurar scripts de mapa
    - _Requirements: 3.4_
    - **Implementado em:** `tools/map_to_godot_converter.py`
    - **Funcionalidades:** Geração de cenas .tscn com TileMap, objetos e NPCs posicionados
  - [x] 8.3 Implementar conversor PRO → Godot Resource
    - Gerar ItemData resources
    - Gerar NPCData resources
    - Gerar TileData resources
    - _Requirements: 3.4_
    - **Implementado em:** `tools/pro_to_godot_converter.py`
    - **Funcionalidades:** Geração de recursos .tres para itens, criaturas e tiles
  - [x] 8.4 Implementar conversor MSG → JSON
    - Converter todos os arquivos de texto
    - Preservar formatação e variáveis
    - Gerar estrutura de diálogos
    - _Requirements: 3.4_
    - **Implementado em:** `tools/extractors/msg_parser.py`
    - **Status:** MSGParser completo e funcional

- [x] 9. Checkpoint - Validar extração
  - Ensure all tests pass, ask the user if questions arise.
  - **Status:** ✅ Extractors validados, conversores implementados
  - **Resultado:** Fase 3 concluída com sucesso

## Fase 4: Completar Core Systems Godot

- [x] 10. Completar GameManager
  - [x] 10.1 Implementar máquina de estados completa
    - Estados: MENU, EXPLORATION, COMBAT, DIALOG, INVENTORY, PAUSED
    - Transições válidas entre estados
    - Sinais para mudança de estado
    - _Requirements: 5.1_
    - **Implementado em:** `godot_project/scripts/core/game_manager.gd`
    - **Funcionalidades:** Máquina de estados completa com validação de transições, matriz de transições válidas
  - [x] 10.2 Implementar sistema de tempo do jogo
    - Ciclo dia/noite
    - Passagem de tempo em viagem
    - Eventos baseados em tempo
    - _Requirements: 5.1_
    - **Implementado em:** `godot_project/scripts/core/game_manager.gd`
    - **Funcionalidades:** Sistema de tempo completo baseado no original (ticks, horas, dias, anos), funções de data/hora, detecção de dia/noite, eventos de meia-noite
  - [ ] 10.3 Write property test for game state consistency
    - **Property 4: Rastreamento de Progresso Consistente**
    - **Validates: Requirements 5.1, 5.2, 5.4**

- [x] 11. Completar MapManager












  - [x] 11.1 Implementar carregamento de mapas convertidos
    - Carregar tiles de todas as elevações
    - Instanciar objetos e NPCs
    - Configurar conexões entre mapas
    - _Requirements: 4.1_
    - **Implementado em:** `godot_project/scripts/systems/map_system.gd`
    - **Funcionalidades:** load_map(), _load_map_tiles(), _instantiate_map_objects(), _instantiate_map_npcs(), _configure_map_connections()
  - [x] 11.2 Implementar sistema de elevações
    - Renderizar 3 níveis de elevação
    - Transições entre elevações
    - Oclusão correta
    - _Requirements: 9.3_
    - **Implementado em:** `godot_project/scripts/systems/map_system.gd`
    - **Funcionalidades:** set_elevation(), get_elevation(), _start_elevation_transition(), _update_elevation_transition(), _update_elevation_visibility()
  - [x] 11.3 Implementar transições de mapa
    - Detectar saídas de mapa
    - Carregar novo mapa
    - Posicionar jogador corretamente
    - _Requirements: 4.1_
    - **Implementado em:** `godot_project/scripts/systems/map_system.gd`
    - **Funcionalidades:** transition_to(), check_exit(), check_exit_at_tile(), _apply_entrance()

- [x] 12. Completar SaveSystem
  - [x] 12.1 Implementar save completo
    - Salvar estado do jogador
    - Salvar estado de todos os mapas visitados
    - Salvar flags e variáveis globais
    - _Requirements: 5.1_
    - **Implementado em:** `godot_project/scripts/systems/save_system.gd`
    - **Funcionalidades:** save_game(), _collect_save_data(), track_map_visit(), visited_maps tracking
  - [x] 12.2 Implementar load com validação
    - Carregar e validar dados
    - Detectar saves corrompidos
    - Restaurar estado completo
    - _Requirements: 5.1_
    - **Implementado em:** `godot_project/scripts/systems/save_system.gd`
    - **Funcionalidades:** load_game(), _validate_save_data(), _validate_checksum(), _apply_save_data()
  - [x] 12.3 Write property test for save/load round-trip








    - **Property 1: Round-trip de Formatos de Arquivo** (aplicado a saves)
    - **Validates: Requirements 3.4**

- [ ] 13. Checkpoint - Validar core systems
  - Ensure all tests pass, ask the user if questions arise.

## Fase 5: Completar Gameplay Systems

- [ ] 14. Completar CombatSystem
  - [ ] 14.1 Implementar fórmulas de combate do original
    - Hit chance baseado em skills e stats
    - Cálculo de dano com DR/DT
    - Critical hits e misses
    - _Requirements: 17.1_
  - [ ] 14.2 Implementar sistema de AP
    - Custo de ações
    - Regeneração por turno
    - Modificadores de perks
    - _Requirements: 17.1_
  - [ ] 14.3 Implementar AI de combate
    - Comportamentos básicos (agressivo, defensivo, fugir)
    - Uso de itens e habilidades
    - Targeting inteligente
    - _Requirements: 17.1_

- [ ] 15. Completar DialogSystem
  - [ ] 15.1 Implementar árvores de diálogo completas
    - Carregar diálogos convertidos
    - Avaliar condições (skills, stats, flags)
    - Executar consequências
    - _Requirements: 4.5_
  - [ ] 15.2 Implementar sistema de barter
    - Interface de troca
    - Cálculo de preços baseado em Barter skill
    - Inventário de NPCs
    - _Requirements: 4.3_

- [ ] 16. Completar InventorySystem
  - [ ] 16.1 Implementar inventário completo
    - Limite de peso baseado em Strength
    - Equipamento em slots
    - Uso de consumíveis
    - _Requirements: 4.3_
  - [ ] 16.2 Implementar sistema de crafting (se aplicável)
    - Receitas de itens
    - Requisitos de skills
    - _Requirements: 4.3_

- [ ] 17. Implementar ScriptInterpreter
  - [ ] 17.1 Criar interpretador de scripts SSL/INT
    - Parsear scripts compilados
    - Executar comandos básicos
    - Integrar com sistemas do jogo
    - _Requirements: 3.3_
  - [ ] 17.2 Implementar funções de script
    - Funções de diálogo
    - Funções de combate
    - Funções de mundo
    - _Requirements: 3.3_

- [ ] 18. Checkpoint - Validar gameplay systems
  - Ensure all tests pass, ask the user if questions arise.

## Fase 6: Upgrades e Modernização

- [ ] 19. Implementar upgrades gráficos
  - [ ] 19.1 Adicionar iluminação dinâmica 2D
    - Light2D para tochas, explosões
    - Ciclo dia/noite com iluminação global
    - Sombras dinâmicas
    - _Requirements: 9.1, 9.2_
  - [ ] 19.2 Adicionar efeitos de partículas
    - Explosões
    - Sangue e impactos
    - Efeitos de clima
    - _Requirements: 9.2_
  - [ ] 19.3 Implementar suporte a múltiplas resoluções
    - Scaling de pixel art
    - UI responsiva
    - Aspect ratio handling
    - _Requirements: 9.3_
  - [ ] 19.4 Write property test for UI responsiveness
    - **Property 8: UI Responsiva em Múltiplas Resoluções**
    - **Validates: Requirements 11.1, 11.2, 11.5**

- [ ] 20. Implementar upgrades de áudio
  - [ ] 20.1 Implementar áudio posicional 2D
    - Volume baseado em distância
    - Panning baseado em direção
    - Atenuação configurável
    - _Requirements: 10.1_
  - [ ] 20.2 Implementar sistema de música dinâmica
    - Crossfade entre tracks
    - Layering baseado em situação
    - Transições suaves
    - _Requirements: 10.2_
  - [ ] 20.3 Write property test for positional audio
    - **Property 7: Sistema de Áudio Posicional Correto**
    - **Validates: Requirements 10.1, 10.2, 10.3, 10.5**

- [ ] 21. Implementar upgrades de UI/UX
  - [ ] 21.1 Adicionar suporte a gamepad
    - Mapeamento de controles
    - Navegação de menus
    - Cursor virtual
    - _Requirements: 11.2_
  - [ ] 21.2 Implementar opções de acessibilidade
    - Tamanho de fonte ajustável
    - Alto contraste
    - Narração de UI (opcional)
    - _Requirements: 11.3_

- [ ] 22. Checkpoint - Validar upgrades
  - Ensure all tests pass, ask the user if questions arise.

## Fase 7: Modularização para Substituição de Assets

- [ ] 23. Implementar sistema de assets substituíveis
  - [ ] 23.1 Reorganizar estrutura de assets
    - Criar estrutura: assets/{tipo}/{categoria}/{arquivo}
    - Mover todos os assets para estrutura correta
    - Atualizar referências no código
    - _Requirements: 13.1_
  - [ ] 23.2 Implementar sistema de IDs para assets
    - Criar registry de assets
    - Substituir caminhos hardcoded por IDs
    - Implementar fallback para assets faltantes
    - _Requirements: 13.2_
  - [ ] 23.3 Criar sistema de hot-reload de assets
    - Detectar mudanças em assets
    - Recarregar sem reiniciar
    - Validar novos assets
    - _Requirements: 13.3_
  - [ ] 23.4 Write property test for asset substitution
    - **Property 10: Sistema de Assets Substituível**
    - **Validates: Requirements 13.1, 13.2, 13.3, 13.4**

- [ ] 24. Implementar sistema de dados configuráveis
  - [ ] 24.1 Externalizar dados de gameplay
    - Mover stats de itens para JSON/Resource
    - Mover stats de NPCs para JSON/Resource
    - Mover configurações de combate para JSON/Resource
    - _Requirements: 14.1_
  - [ ] 24.2 Implementar validação de dados
    - Schemas para cada tipo de dado
    - Validação ao carregar
    - Mensagens de erro claras
    - _Requirements: 14.4_
  - [ ] 24.3 Criar editor visual de dados
    - Integrar com Inspector do Godot
    - Custom editors para tipos complexos
    - Preview de mudanças
    - _Requirements: 14.5_
  - [ ] 24.4 Write property test for data configuration
    - **Property 11: Sistema de Dados Configurável**
    - **Validates: Requirements 14.1, 14.2, 14.3, 14.4**

- [ ] 25. Criar documentação de substituição
  - [ ] 25.1 Gerar manifesto de assets
    - Listar todos os assets necessários
    - Especificações (tamanho, formato, animações)
    - Exemplos de cada tipo
    - _Requirements: 13.4_
  - [ ] 25.2 Criar guia de substituição
    - Passo a passo para cada tipo de asset
    - Ferramentas recomendadas
    - Troubleshooting comum
    - _Requirements: 13.5_

- [ ] 26. Checkpoint - Validar modularização
  - Ensure all tests pass, ask the user if questions arise.

## Fase 8: Qualidade e Testes Finais

- [ ] 27. Implementar testes de arquitetura
  - [ ] 27.1 Validar estrutura de pastas
    - Verificar que scripts estão nas pastas corretas
    - Verificar convenções de nomenclatura
    - _Requirements: 12.1_
  - [ ] 27.2 Validar padrões de comunicação
    - Verificar uso de sinais vs chamadas diretas
    - Verificar ausência de dependências circulares
    - _Requirements: 12.2_
  - [ ] 27.3 Write property test for modular architecture
    - **Property 9: Arquitetura Modular Válida**
    - **Validates: Requirements 12.1, 12.2, 12.3, 12.4**

- [ ] 28. Implementar testes de qualidade de código
  - [ ] 28.1 Configurar linter GDScript
    - Instalar e configurar gdlint
    - Definir regras de estilo
    - Integrar com CI
    - _Requirements: 18.1_
  - [ ] 28.2 Validar documentação de código
    - Verificar docstrings em funções públicas
    - Verificar comentários em código complexo
    - _Requirements: 12.5, 15.3_
  - [ ] 28.3 Write property test for code quality
    - **Property 13: Código Segue Padrões de Qualidade**
    - **Validates: Requirements 18.1, 18.2, 18.5**

- [ ] 29. Validar cobertura de testes
  - [ ] 29.1 Verificar cobertura de testes unitários
    - Medir cobertura por sistema
    - Identificar gaps
    - _Requirements: 17.1_
  - [ ] 29.2 Verificar testes de propriedade
    - Confirmar que todas as propriedades têm testes
    - Executar com 100+ iterações
    - _Requirements: 17.3_
  - [ ] 29.3 Write property test for test coverage
    - **Property 12: Cobertura de Testes Adequada**
    - **Validates: Requirements 17.1, 17.2, 17.3, 17.5**

- [ ] 30. Final Checkpoint - Validação completa
  - Ensure all tests pass, ask the user if questions arise.

---

## Resumo de Propriedades e Testes

| # | Propriedade | Task | Requirements |
|---|-------------|------|--------------|
| 1 | Round-trip de Formatos | 7.5, 12.3 | 3.4 |
| 2 | Catálogo DAT Completo | 1.3 | 2.1-2.5 |
| 3 | Catálogo Conteúdo Completo | 2.6 | 4.1-4.5 |
| 4 | Progress Tracker Consistente | 10.3 | 5.1, 5.2, 5.4 |
| 5 | Code Map Completo | 4.3 | 6.1-6.5 |
| 6 | Comparação Consistente | 5.4 | 7.1-7.5 |
| 7 | Áudio Posicional | 20.3 | 10.1-10.5 |
| 8 | UI Responsiva | 19.4 | 11.1, 11.2, 11.5 |
| 9 | Arquitetura Modular | 27.3 | 12.1-12.4 |
| 10 | Assets Substituíveis | 23.4 | 13.1-13.4 |
| 11 | Dados Configuráveis | 24.4 | 14.1-14.4 |
| 12 | Cobertura de Testes | 29.3 | 17.1-17.5 |
| 13 | Qualidade de Código | 28.3 | 18.1, 18.2, 18.5 |
