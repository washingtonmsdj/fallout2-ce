# Requirements Document: NPCs, Quest System e Conteúdo Jogável

## Introduction

Este documento especifica os requisitos para três funcionalidades essenciais para tornar o jogo jogável: extração completa de animações de NPCs/criaturas do Fallout 2, implementação de um sistema de quests funcional, e criação do primeiro conteúdo jogável completo. O objetivo é ter um jogo demonstrável com NPCs animados, missões e gameplay loop completo.

## Glossary

- **NPC (Non-Player Character)**: Personagem controlado pelo jogo, não pelo jogador
- **Critter**: Termo do Fallout 2 para qualquer criatura ou NPC
- **FRM**: Formato de sprite animado do Fallout 2
- **Animation Set**: Conjunto completo de animações para um personagem (idle, walk, attack, death, etc.)
- **Quest**: Missão com objetivos, progresso e recompensas
- **Quest Journal**: Interface que mostra quests ativas e completadas
- **Objective**: Passo individual dentro de uma quest
- **Trigger**: Evento que ativa ou atualiza uma quest
- **Playable Content**: Conteúdo jogável com início, meio e fim

---

## PARTE 1: EXTRAÇÃO DE ANIMAÇÕES DE NPCs/CRIATURAS

### Requirement 1: Extração de Sprites de Criaturas

**User Story:** Como desenvolvedor, quero extrair todas as animações de criaturas do Fallout 2, para que NPCs e inimigos tenham animações completas no Godot.

#### Acceptance Criteria

1. WHEN o extrator processa arquivo FRM de criatura THEN o Extractor SHALL decodificar todos os frames em todas as direções (6 ou 8 direções)
2. WHEN animação tem múltiplos frames THEN o Extractor SHALL exportar como spritesheet ou frames individuais com metadados
3. WHEN criatura tem múltiplas animações (idle, walk, attack, death) THEN o Extractor SHALL organizar em pastas separadas por tipo de animação
4. WHEN extração é concluída THEN o Extractor SHALL gerar arquivo de manifesto JSON com lista de criaturas e suas animações disponíveis
5. WHEN arquivo FRM está corrompido ou incompleto THEN o Extractor SHALL registrar erro e continuar com próximo arquivo

### Requirement 2: Conversão para Formato Godot

**User Story:** Como desenvolvedor, quero que as animações extraídas sejam convertidas para formato nativo do Godot, para que possam ser usadas diretamente no engine.

#### Acceptance Criteria

1. WHEN sprites são extraídos THEN o Converter SHALL gerar arquivos PNG com transparência correta
2. WHEN animação é processada THEN o Converter SHALL criar arquivo SpriteFrames (.tres) do Godot com timing correto
3. WHEN criatura tem 6 direções THEN o Converter SHALL mapear para sistema de 8 direções do jogo (interpolando ou duplicando)
4. WHEN conversão é concluída THEN o Converter SHALL validar que todos os arquivos são carregáveis pelo Godot
5. WHEN paleta de cores é aplicada THEN o Converter SHALL usar paleta correta do Fallout 2 para cores precisas

### Requirement 3: Catálogo de Criaturas

**User Story:** Como desenvolvedor, quero um catálogo organizado de todas as criaturas disponíveis, para que eu possa facilmente selecionar e usar NPCs no jogo.

#### Acceptance Criteria

1. WHEN catálogo é gerado THEN o Catalog System SHALL listar todas as criaturas com preview de sprite
2. WHEN criatura é catalogada THEN o Catalog System SHALL incluir metadados (nome, tipo, animações disponíveis, tamanho)
3. WHEN desenvolvedor busca criatura THEN o Catalog System SHALL permitir filtrar por tipo (humano, animal, mutante, robô)
4. WHEN criatura é selecionada THEN o Catalog System SHALL fornecer caminho para assets e dados de protótipo
5. WHEN nova criatura é extraída THEN o Catalog System SHALL atualizar automaticamente o catálogo

---

## PARTE 2: SISTEMA DE QUESTS

### Requirement 4: Estrutura de Quest

**User Story:** Como jogador, quero receber missões com objetivos claros, para que eu saiba o que fazer no jogo.

#### Acceptance Criteria

1. WHEN uma quest é criada THEN o Quest System SHALL armazenar título, descrição, objetivos e recompensas
2. WHEN quest tem múltiplos objetivos THEN o Quest System SHALL rastrear progresso de cada objetivo independentemente
3. WHEN objetivo tem quantidade THEN o Quest System SHALL rastrear progresso numérico (ex: "Matar 5 ratos: 3/5")
4. WHEN quest tem pré-requisitos THEN o Quest System SHALL verificar antes de disponibilizar a quest
5. WHEN quest é serializada THEN o Quest System SHALL salvar e carregar estado completo corretamente

### Requirement 5: Progresso e Conclusão de Quest

**User Story:** Como jogador, quero que minhas ações atualizem o progresso das quests automaticamente, para que eu veja meu avanço.

#### Acceptance Criteria

1. WHEN jogador completa ação relevante THEN o Quest System SHALL atualizar objetivo correspondente
2. WHEN todos os objetivos são completados THEN o Quest System SHALL marcar quest como pronta para entregar
3. WHEN jogador entrega quest THEN o Quest System SHALL conceder recompensas (XP, itens, dinheiro, reputação)
4. WHEN quest falha (condição de falha atingida) THEN o Quest System SHALL marcar como falhada e notificar jogador
5. WHEN quest tem múltiplos finais THEN o Quest System SHALL rastrear qual caminho foi escolhido

### Requirement 6: Quest Journal (Diário de Quests)

**User Story:** Como jogador, quero consultar minhas quests ativas e completadas, para que eu possa acompanhar meu progresso.

#### Acceptance Criteria

1. WHEN jogador abre journal THEN o Quest Journal SHALL exibir lista de quests organizadas por status (ativa, completada, falhada)
2. WHEN jogador seleciona quest THEN o Quest Journal SHALL mostrar descrição completa, objetivos e progresso
3. WHEN quest é atualizada THEN o Quest Journal SHALL destacar visualmente a mudança
4. WHEN quest tem localização THEN o Quest Journal SHALL mostrar indicação de onde ir
5. WHEN jogador fecha journal THEN o Quest Journal SHALL manter última quest selecionada para referência rápida

### Requirement 7: Integração com NPCs e Diálogos

**User Story:** Como jogador, quero receber e entregar quests através de diálogos com NPCs, para que a experiência seja imersiva.

#### Acceptance Criteria

1. WHEN NPC oferece quest THEN o Dialog System SHALL apresentar opção de aceitar ou recusar
2. WHEN jogador aceita quest THEN o Quest System SHALL adicionar quest ao journal e notificar
3. WHEN jogador retorna com quest completa THEN o Dialog System SHALL oferecer opção de entregar
4. WHEN quest afeta diálogo THEN o Dialog System SHALL mostrar opções diferentes baseado no estado da quest
5. WHEN NPC é quest giver THEN o NPC System SHALL mostrar indicador visual (ícone de quest disponível/em progresso)

---

## PARTE 3: CONTEÚDO JOGÁVEL

### Requirement 8: Área Inicial Jogável

**User Story:** Como jogador, quero uma área inicial completa para explorar, para que eu possa experimentar o jogo.

#### Acceptance Criteria

1. WHEN jogo inicia THEN o Game System SHALL carregar área inicial com mapa, NPCs e objetos
2. WHEN área é carregada THEN o Map System SHALL posicionar player em ponto de spawn definido
3. WHEN jogador explora THEN o Area System SHALL ter múltiplas áreas conectadas para navegação
4. WHEN área tem NPCs THEN o NPC System SHALL spawnar NPCs com comportamentos e diálogos funcionais
5. WHEN área tem inimigos THEN o Combat System SHALL permitir combate funcional com IA básica

### Requirement 9: Quest Inicial Completa

**User Story:** Como jogador, quero uma quest inicial do começo ao fim, para que eu experimente o loop de gameplay completo.

#### Acceptance Criteria

1. WHEN jogador inicia jogo THEN o Quest System SHALL ter quest inicial disponível automaticamente ou via NPC
2. WHEN quest inicial é aceita THEN o Quest System SHALL guiar jogador através de objetivos progressivos
3. WHEN quest envolve combate THEN o Combat System SHALL ter encontro balanceado para nível inicial
4. WHEN quest envolve diálogo THEN o Dialog System SHALL ter conversas com escolhas significativas
5. WHEN quest é completada THEN o Quest System SHALL recompensar jogador e desbloquear próximo conteúdo

### Requirement 10: NPCs Funcionais na Área

**User Story:** Como jogador, quero interagir com NPCs que pareçam vivos, para que o mundo seja imersivo.

#### Acceptance Criteria

1. WHEN NPC está na área THEN o NPC System SHALL exibir animações apropriadas (idle, walk)
2. WHEN jogador interage com NPC THEN o Dialog System SHALL iniciar conversa com opções
3. WHEN NPC é mercador THEN o Trade System SHALL permitir compra e venda de itens
4. WHEN NPC é hostil THEN o Combat System SHALL iniciar combate quando jogador se aproxima
5. WHEN NPC morre THEN o NPC System SHALL deixar corpo com loot acessível

### Requirement 11: Gameplay Loop Completo

**User Story:** Como jogador, quero experimentar o ciclo completo de explorar, lutar, conversar e progredir, para que o jogo seja satisfatório.

#### Acceptance Criteria

1. WHEN jogador explora THEN o Game System SHALL permitir descobrir novos locais e itens
2. WHEN jogador luta THEN o Combat System SHALL conceder XP e loot
3. WHEN jogador ganha XP suficiente THEN o Level System SHALL permitir subir de nível e melhorar stats
4. WHEN jogador completa quests THEN o Quest System SHALL desbloquear novas oportunidades
5. WHEN jogador salva e carrega THEN o Save System SHALL preservar todo progresso corretamente

