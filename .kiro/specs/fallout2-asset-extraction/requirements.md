# Requirements Document

## Introduction

Este documento especifica os requisitos para a extração completa de todos os assets do Fallout 2 original (arquivos .DAT) e sua conversão para formatos compatíveis com Godot Engine 4.x. O objetivo é migrar fielmente todos os recursos visuais, sonoros e de dados do jogo original para o projeto de recriação em Godot.

## Glossary

- **DAT2**: Formato de arquivo compactado usado pelo Fallout 2 para armazenar assets (master.dat, critter.dat, patch000.dat)
- **FRM**: Formato de imagem/animação do Fallout 2 (Frame Resource Manager)
- **PAL**: Arquivo de paleta de cores (256 cores indexadas)
- **ACM**: Formato de áudio comprimido usado pelo Fallout 2
- **MAP**: Formato de mapa do Fallout 2 contendo tiles, objetos e scripts
- **PRO**: Arquivo de protótipo definindo propriedades de itens, criaturas e tiles
- **MSG**: Arquivo de mensagens/textos localizados
- **Asset Extractor**: Sistema Python que lê arquivos DAT2 e extrai conteúdo
- **Godot Project**: Projeto de destino em `godot_project/`

## Requirements

### Requirement 1: Extração de Arquivos DAT2

**User Story:** Como desenvolvedor, quero extrair arquivos dos containers DAT2 do Fallout 2, para que eu possa acessar os assets originais do jogo.

#### Acceptance Criteria

1. WHEN o extrator recebe um arquivo DAT2 válido (master.dat, critter.dat, patch000.dat) THEN o Asset Extractor SHALL ler o índice de arquivos e listar todo o conteúdo
2. WHEN o extrator solicita um arquivo específico do DAT2 THEN o Asset Extractor SHALL extrair e descomprimir (zlib) o arquivo corretamente
3. WHEN o arquivo DAT2 não existe ou está corrompido THEN o Asset Extractor SHALL reportar erro descritivo e continuar com outros arquivos
4. WHEN múltiplos arquivos DAT2 contêm o mesmo asset THEN o Asset Extractor SHALL usar a ordem de prioridade: patch000.dat > critter.dat > master.dat

### Requirement 2: Conversão de Sprites FRM para PNG

**User Story:** Como desenvolvedor, quero converter sprites FRM do Fallout 2 para PNG, para que eu possa usá-los no Godot Engine.

#### Acceptance Criteria

1. WHEN o conversor recebe um arquivo FRM válido THEN o Asset Extractor SHALL decodificar todos os frames e direções usando a paleta de cores correta
2. WHEN um FRM contém múltiplas direções (até 6) THEN o Asset Extractor SHALL exportar cada direção como arquivo PNG separado com sufixo identificador (_ne, _e, _se, _sw, _w, _nw)
3. WHEN um FRM contém animação (múltiplos frames) THEN o Asset Extractor SHALL exportar como spritesheet ou frames individuais numerados
4. WHEN o índice de cor é 0 (transparente) THEN o Asset Extractor SHALL preservar transparência no PNG resultante (canal alpha)
5. WHEN a conversão FRM para PNG é realizada THEN o Asset Extractor SHALL produzir um PNG que, quando convertido de volta para FRM, preserve as dimensões e dados de pixel originais

### Requirement 3: Extração de Criaturas e NPCs

**User Story:** Como desenvolvedor, quero extrair todos os sprites de criaturas e NPCs organizados de forma clara, para que eu possa facilmente substituí-los com meus próprios assets no futuro.

#### Acceptance Criteria

1. WHEN o extrator processa critter.dat THEN o Asset Extractor SHALL extrair todos os sprites de criaturas organizados em pastas por categoria (humans/, animals/, mutants/, robots/)
2. WHEN uma criatura tem múltiplas animações (idle, walk, attack, death) THEN o Asset Extractor SHALL exportar cada animação em subpasta separada com nomenclatura legível (ex: deathclaw/walk/, dog/idle/)
3. WHEN sprites de criaturas são extraídos THEN o Asset Extractor SHALL manter metadados de offset (x, y) para alinhamento correto
4. WHEN sprites são organizados THEN o Asset Extractor SHALL usar nomes descritivos em vez de códigos internos (ex: "male_leather_armor" em vez de "hmlthraa")
5. WHEN um NPC é extraído THEN o Asset Extractor SHALL gerar um arquivo JSON de manifesto por NPC contendo: nome legível, categoria, animações disponíveis, e caminho para substituição

### Requirement 4: Extração de Tiles de Mapa

**User Story:** Como desenvolvedor, quero extrair todos os tiles de terreno e objetos, para que eu possa reconstruir os mapas do jogo.

#### Acceptance Criteria

1. WHEN o extrator processa tiles do master.dat THEN o Asset Extractor SHALL extrair todos os tiles de chão (floor) e teto (roof) como PNGs individuais
2. WHEN tiles são extraídos THEN o Asset Extractor SHALL organizar em pastas por categoria (desert, city, cave, vault, etc.)
3. WHEN um tile tem dimensões isométricas THEN o Asset Extractor SHALL preservar as dimensões originais (80x36 pixels para tiles de chão)

### Requirement 5: Extração de Interface do Usuário

**User Story:** Como desenvolvedor, quero extrair todos os elementos de UI, para que eu possa recriar a interface original do Fallout 2.

#### Acceptance Criteria

1. WHEN o extrator processa art/intrface/ THEN o Asset Extractor SHALL extrair todos os elementos de menu, botões, painéis e ícones
2. WHEN elementos de UI são extraídos THEN o Asset Extractor SHALL manter nomenclatura descritiva (mainmenu_bg.png, button_normal.png, button_pressed.png)
3. WHEN sprites de inventário são extraídos THEN o Asset Extractor SHALL incluir ícones de itens, slots e backgrounds

### Requirement 6: Extração de Áudio

**User Story:** Como desenvolvedor, quero extrair todos os arquivos de áudio, para que eu possa incluir sons e músicas originais.

#### Acceptance Criteria

1. WHEN o extrator encontra arquivos ACM THEN o Asset Extractor SHALL converter para formato OGG ou WAV compatível com Godot
2. WHEN arquivos de áudio são extraídos THEN o Asset Extractor SHALL organizar em pastas (music, sfx, voice)
3. WHEN a conversão de áudio falha THEN o Asset Extractor SHALL registrar o erro e continuar com outros arquivos

### Requirement 7: Extração de Dados de Mapas

**User Story:** Como desenvolvedor, quero extrair dados dos mapas originais, para que eu possa reconstruir as áreas do jogo.

#### Acceptance Criteria

1. WHEN o extrator processa arquivos MAP THEN o Asset Extractor SHALL extrair layout de tiles, posições de objetos e triggers
2. WHEN dados de mapa são extraídos THEN o Asset Extractor SHALL exportar em formato JSON legível para importação no Godot
3. WHEN um mapa referencia scripts THEN o Asset Extractor SHALL incluir referências aos scripts associados

### Requirement 8: Extração de Textos e Diálogos

**User Story:** Como desenvolvedor, quero extrair todos os textos do jogo, para que eu possa implementar diálogos e mensagens.

#### Acceptance Criteria

1. WHEN o extrator processa arquivos MSG THEN o Asset Extractor SHALL extrair todas as strings de texto preservando IDs
2. WHEN textos são extraídos THEN o Asset Extractor SHALL exportar em formato JSON com estrutura {id: texto}
3. WHEN múltiplos idiomas existem THEN o Asset Extractor SHALL organizar por locale (en, pt, etc.)

### Requirement 9: Geração de Metadados e Catálogo

**User Story:** Como desenvolvedor, quero um catálogo completo dos assets extraídos, para que eu possa gerenciar e referenciar recursos facilmente.

#### Acceptance Criteria

1. WHEN a extração é concluída THEN o Asset Extractor SHALL gerar arquivo de manifesto JSON listando todos os assets extraídos
2. WHEN o manifesto é gerado THEN o Asset Extractor SHALL incluir caminho original, caminho de destino, tipo e dimensões para cada asset
3. WHEN erros ocorrem durante extração THEN o Asset Extractor SHALL registrar em arquivo de log separado com detalhes do erro

### Requirement 10: Organização de Saída para Godot

**User Story:** Como desenvolvedor, quero que os assets sejam organizados na estrutura do projeto Godot, para que eu possa usá-los diretamente.

#### Acceptance Criteria

1. WHEN assets são extraídos THEN o Asset Extractor SHALL salvar na estrutura `godot_project/assets/` com subpastas organizadas
2. WHEN sprites são salvos THEN o Asset Extractor SHALL usar estrutura: `sprites/{categoria}/{subcategoria}/{arquivo}.png`
3. WHEN áudio é salvo THEN o Asset Extractor SHALL usar estrutura: `audio/{tipo}/{arquivo}.ogg`
4. WHEN dados são salvos THEN o Asset Extractor SHALL usar estrutura: `data/{tipo}/{arquivo}.json`

### Requirement 11: Facilitar Substituição de Assets

**User Story:** Como desenvolvedor criando meu próprio jogo baseado na engine, quero que os assets sejam organizados de forma que eu possa facilmente substituí-los com meus próprios recursos.

#### Acceptance Criteria

1. WHEN assets são extraídos THEN o Asset Extractor SHALL gerar um arquivo `ASSET_REPLACEMENT_GUIDE.md` documentando a estrutura e como substituir cada tipo de asset
2. WHEN sprites de NPCs são organizados THEN o Asset Extractor SHALL criar uma pasta por NPC/criatura com nome legível contendo todas as suas animações
3. WHEN um NPC é extraído THEN o Asset Extractor SHALL gerar um arquivo `_template.json` na pasta do NPC especificando: dimensões esperadas, número de frames por animação, direções necessárias
4. WHEN tiles são extraídos THEN o Asset Extractor SHALL organizar por ambiente (desert, city, cave, vault, interior) com nomes descritivos
5. WHEN a extração é concluída THEN o Asset Extractor SHALL gerar um relatório `ASSETS_SUMMARY.md` listando todos os NPCs, tiles e itens extraídos com seus nomes legíveis
