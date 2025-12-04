# Requirements Document: Migração Completa Fallout 2 para Godot

## Introduction

Este documento especifica os requisitos para finalizar a migração completa do Fallout 2 para Godot Engine 4.x. O objetivo é criar um jogo funcional idêntico ao original, utilizando os assets já extraídos e os sistemas parcialmente implementados. A prioridade é: 1) Engine/Core funcional, 2) Sistemas de gameplay, 3) NPCs e criaturas, 4) Mapas e conteúdo.

## Glossary

- **Godot Engine**: Motor de jogo open-source versão 4.x usado para a recriação
- **SPECIAL**: Sistema de atributos do Fallout (Strength, Perception, Endurance, Charisma, Intelligence, Agility, Luck)
- **AP (Action Points)**: Pontos de ação usados em combate por turnos
- **Hex Grid**: Grade hexagonal usada para posicionamento isométrico
- **FRM**: Formato de sprite original do Fallout 2
- **Tile**: Unidade básica do mapa (80x36 pixels para chão isométrico)
- **Critter**: Qualquer criatura ou NPC no jogo
- **PRO (Prototype)**: Definição de propriedades de itens, criaturas e objetos
- **Script SSL**: Scripts originais do Fallout 2 em linguagem SSL

---

## FASE 1: ENGINE CORE E RENDERIZAÇÃO

### Requirement 1: Sistema de Renderização Isométrica

**User Story:** Como jogador, quero ver o mundo em perspectiva isométrica fiel ao original, para que a experiência visual seja autêntica.

#### Acceptance Criteria

1. WHEN o jogo renderiza o mundo THEN o Isometric Renderer SHALL posicionar tiles em grade hexagonal com dimensões 80x36 pixels
2. WHEN múltiplos objetos ocupam a mesma área THEN o Isometric Renderer SHALL ordenar sprites por profundidade (y + elevation * offset)
3. WHEN o player se move THEN o Isometric Renderer SHALL atualizar a ordem de renderização em tempo real
4. WHEN tiles de diferentes elevações existem THEN o Isometric Renderer SHALL renderizar cada elevação como camada separada
5. WHEN um sprite tem offset definido THEN o Isometric Renderer SHALL aplicar offset para alinhamento correto ao tile

### Requirement 2: Sistema de Câmera

**User Story:** Como jogador, quero que a câmera siga meu personagem suavemente, para que eu possa navegar pelo mundo confortavelmente.

#### Acceptance Criteria

1. WHEN o player se move THEN a Camera SHALL seguir o player com suavização configurável
2. WHEN o player está próximo da borda do mapa THEN a Camera SHALL limitar movimento para não mostrar área fora do mapa
3. WHEN o jogador usa scroll do mouse THEN a Camera SHALL permitir zoom in/out dentro de limites definidos
4. WHEN em modo de combate THEN a Camera SHALL centralizar no combatente atual durante seu turno
5. WHEN uma cutscene ou diálogo inicia THEN a Camera SHALL poder ser controlada por script

### Requirement 3: Sistema de Input e Cursor

**User Story:** Como jogador, quero interagir com o mundo usando mouse e teclado como no original, para que os controles sejam familiares.

#### Acceptance Criteria

1. WHEN o jogador clica com botão esquerdo no chão THEN o Input System SHALL comandar o player a mover para aquela posição
2. WHEN o jogador clica com botão esquerdo em objeto interagível THEN o Input System SHALL executar ação padrão do objeto
3. WHEN o jogador clica com botão direito THEN o Input System SHALL alternar entre modos de cursor (movimento, ataque, uso, examinar)
4. WHEN o cursor passa sobre objeto interagível THEN o Input System SHALL mudar aparência do cursor e mostrar tooltip
5. WHEN teclas de atalho são pressionadas THEN o Input System SHALL executar ação correspondente (I=inventário, C=personagem, etc.)

---

## FASE 2: SISTEMAS DE GAMEPLAY CORE

### Requirement 4: Sistema de Movimento e Pathfinding

**User Story:** Como jogador, quero que meu personagem encontre caminhos automaticamente até o destino, para que a navegação seja fluida.

#### Acceptance Criteria

1. WHEN o player recebe comando de movimento THEN o Pathfinding System SHALL calcular caminho evitando obstáculos
2. WHEN o caminho está bloqueado THEN o Pathfinding System SHALL encontrar rota alternativa ou reportar impossibilidade
3. WHEN o player se move THEN o Movement System SHALL consumir AP em combate (1 AP por hex)
4. WHEN o player corre (Shift) THEN o Movement System SHALL aumentar velocidade em 50%
5. WHEN o player colide com NPC THEN o Movement System SHALL parar movimento e permitir interação

### Requirement 5: Sistema de Combate por Turnos

**User Story:** Como jogador, quero combate tático por turnos usando Action Points, para que eu possa planejar minhas ações estrategicamente.

#### Acceptance Criteria

1. WHEN combate inicia THEN o Combat System SHALL ordenar combatentes por Sequence (2 * Perception)
2. WHEN é turno do player THEN o Combat System SHALL permitir ações até AP acabar ou jogador terminar turno
3. WHEN um ataque é realizado THEN o Combat System SHALL calcular hit chance baseado em skill, distância e AC do alvo
4. WHEN um ataque acerta THEN o Combat System SHALL calcular dano considerando arma, força e armadura
5. WHEN HP de combatente chega a zero THEN o Combat System SHALL marcar como morto e remover da ordem de turno
6. WHEN todos inimigos morrem ou fogem THEN o Combat System SHALL encerrar combate e restaurar modo normal

### Requirement 6: Sistema de Inventário

**User Story:** Como jogador, quero gerenciar itens que coleto, para que eu possa equipar armas, usar consumíveis e negociar.

#### Acceptance Criteria

1. WHEN o jogador abre inventário THEN o Inventory System SHALL exibir todos itens com peso total e capacidade
2. WHEN o jogador equipa arma THEN o Inventory System SHALL atualizar slot de arma ativa e stats de combate
3. WHEN o jogador usa consumível THEN o Inventory System SHALL aplicar efeito e remover/reduzir quantidade
4. WHEN peso excede capacidade THEN o Inventory System SHALL impedir movimento e notificar jogador
5. WHEN o jogador examina item THEN o Inventory System SHALL mostrar descrição, stats e valor

### Requirement 7: Sistema de Diálogo

**User Story:** Como jogador, quero conversar com NPCs através de árvores de diálogo, para que eu possa obter informações e fazer escolhas.

#### Acceptance Criteria

1. WHEN diálogo inicia THEN o Dialog System SHALL exibir retrato do NPC, texto e opções de resposta
2. WHEN opção tem requisito (skill, stat, item) THEN o Dialog System SHALL verificar e habilitar/desabilitar opção
3. WHEN jogador seleciona opção THEN o Dialog System SHALL executar ações associadas (dar item, XP, mudar reputação)
4. WHEN diálogo termina THEN o Dialog System SHALL retornar controle ao jogador e fechar interface
5. WHEN texto contém variáveis THEN o Dialog System SHALL substituir por valores corretos (nome do player, etc.)

---

## FASE 3: CARREGAMENTO DE DADOS E MAPAS

### Requirement 8: Sistema de Carregamento de Mapas

**User Story:** Como jogador, quero explorar os mapas do jogo original, para que eu possa vivenciar a história completa.

#### Acceptance Criteria

1. WHEN um mapa é carregado THEN o Map Loader SHALL ler dados JSON e instanciar tiles, objetos e NPCs
2. WHEN mapa tem múltiplas elevações THEN o Map Loader SHALL criar camadas separadas para cada elevação
3. WHEN player entra em área de transição THEN o Map Loader SHALL carregar novo mapa na entrada especificada
4. WHEN mapa é descarregado THEN o Map Loader SHALL salvar estado de objetos modificados
5. WHEN mapa contém scripts THEN o Map Loader SHALL registrar triggers e eventos

### Requirement 9: Sistema de Protótipos (PRO)

**User Story:** Como desenvolvedor, quero que itens e criaturas sejam definidos por protótipos, para que dados sejam carregados dinamicamente.

#### Acceptance Criteria

1. WHEN um item é criado THEN o Prototype System SHALL carregar propriedades do arquivo PRO correspondente
2. WHEN uma criatura é spawnada THEN o Prototype System SHALL aplicar stats, inventário e comportamento do PRO
3. WHEN PRO não existe THEN o Prototype System SHALL usar valores padrão e registrar warning
4. WHEN PRO é modificado em runtime THEN o Prototype System SHALL manter instância separada dos dados base
5. WHEN jogo salva THEN o Prototype System SHALL serializar apenas diferenças do PRO base

### Requirement 10: Sistema de Scripts

**User Story:** Como desenvolvedor, quero executar scripts que controlam eventos do jogo, para que comportamentos complexos funcionem.

#### Acceptance Criteria

1. WHEN script é carregado THEN o Script System SHALL parsear e validar sintaxe
2. WHEN evento trigger ocorre THEN o Script System SHALL executar procedimento associado
3. WHEN script acessa variável global THEN o Script System SHALL ler/escrever no estado do jogo
4. WHEN script chama função builtin THEN o Script System SHALL executar ação correspondente no engine
5. WHEN script tem erro THEN o Script System SHALL logar erro e continuar execução do jogo

---

## FASE 4: NPCs E CRIATURAS

### Requirement 11: Sistema de NPCs

**User Story:** Como jogador, quero interagir com NPCs que têm comportamentos únicos, para que o mundo pareça vivo.

#### Acceptance Criteria

1. WHEN NPC é carregado THEN o NPC System SHALL aplicar aparência, stats e comportamento do protótipo
2. WHEN NPC tem schedule THEN o NPC System SHALL mover NPC para locais apropriados baseado no horário
3. WHEN NPC é hostil THEN o NPC System SHALL iniciar combate quando player entra em range de detecção
4. WHEN NPC é mercador THEN o NPC System SHALL permitir interface de comércio
5. WHEN NPC morre THEN o NPC System SHALL deixar corpo com inventário acessível

### Requirement 12: Sistema de Animações de Criaturas

**User Story:** Como jogador, quero ver criaturas animadas em todas as direções, para que o visual seja fiel ao original.

#### Acceptance Criteria

1. WHEN criatura está parada THEN o Animation System SHALL reproduzir animação idle na direção atual
2. WHEN criatura se move THEN o Animation System SHALL reproduzir animação walk na direção do movimento
3. WHEN criatura ataca THEN o Animation System SHALL reproduzir animação de ataque apropriada
4. WHEN criatura morre THEN o Animation System SHALL reproduzir animação de morte e manter frame final
5. WHEN direção muda THEN o Animation System SHALL transicionar suavemente para sprites da nova direção

---

## FASE 5: INTERFACE DO USUÁRIO

### Requirement 13: HUD Principal

**User Story:** Como jogador, quero ver informações importantes na tela, para que eu possa tomar decisões informadas.

#### Acceptance Criteria

1. WHEN jogo está ativo THEN o HUD SHALL exibir barra de HP, AP, arma equipada e modo de cursor
2. WHEN em combate THEN o HUD SHALL mostrar indicador de combate e turno atual
3. WHEN jogador passa mouse sobre elemento THEN o HUD SHALL mostrar tooltip com informações
4. WHEN jogador clica em botão do HUD THEN o HUD SHALL executar ação correspondente
5. WHEN estado do player muda THEN o HUD SHALL atualizar valores em tempo real

### Requirement 14: Telas de Menu

**User Story:** Como jogador, quero acessar menus para gerenciar personagem, inventário e opções, para que eu tenha controle total.

#### Acceptance Criteria

1. WHEN jogador abre menu de personagem THEN o Menu System SHALL exibir stats SPECIAL, skills e perks
2. WHEN jogador abre inventário THEN o Menu System SHALL exibir itens, equipamento e peso
3. WHEN jogador abre opções THEN o Menu System SHALL permitir ajustar volume, dificuldade e controles
4. WHEN jogador abre mapa THEN o Menu System SHALL mostrar worldmap com locais descobertos
5. WHEN menu está aberto THEN o Menu System SHALL pausar o jogo (exceto em combate)

---

## FASE 6: PERSISTÊNCIA E SAVE/LOAD

### Requirement 15: Sistema de Save/Load

**User Story:** Como jogador, quero salvar e carregar meu progresso, para que eu possa continuar de onde parei.

#### Acceptance Criteria

1. WHEN jogador salva THEN o Save System SHALL capturar estado completo: player, inventário, mapas, quests, variáveis
2. WHEN jogador carrega THEN o Save System SHALL restaurar estado exatamente como estava
3. WHEN save é criado THEN o Save System SHALL incluir screenshot, timestamp e localização
4. WHEN save está corrompido THEN o Save System SHALL detectar via checksum e notificar jogador
5. WHEN quicksave é acionado (F6) THEN o Save System SHALL salvar imediatamente no slot de quicksave
6. WHEN quickload é acionado (F9) THEN o Save System SHALL carregar último quicksave

---

## FASE 7: ÁUDIO

### Requirement 16: Sistema de Áudio

**User Story:** Como jogador, quero ouvir música e efeitos sonoros do jogo, para que a experiência seja imersiva.

#### Acceptance Criteria

1. WHEN área muda THEN o Audio System SHALL transicionar música ambiente suavemente
2. WHEN ação ocorre THEN o Audio System SHALL tocar efeito sonoro apropriado
3. WHEN NPC fala THEN o Audio System SHALL reproduzir voice clip se disponível
4. WHEN jogador ajusta volume THEN o Audio System SHALL aplicar configuração imediatamente
5. WHEN múltiplos sons tocam THEN o Audio System SHALL mixar e priorizar corretamente

