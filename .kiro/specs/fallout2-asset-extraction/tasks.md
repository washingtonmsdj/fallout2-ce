# Implementation Plan: Fallout 2 Asset Extraction System

- [x] 1. Setup do Projeto e Estrutura Base
  - [x] 1.1 Criar estrutura de diretórios para os módulos de extração
    - Criar `tools/extractors/` com `__init__.py`
    - Criar `tools/tests/` para testes
    - Criar `tools/tests/conftest.py` com fixtures base
    - _Requirements: 10.1_
  - [x] 1.2 Configurar ambiente de testes com Hypothesis
    - Instalar dependências: `pip install hypothesis pillow`
    - Configurar `pytest.ini` com settings do Hypothesis
    - _Requirements: Testing Strategy_

- [x] 2. Implementar DAT2Reader
  - [x] 2.1 Criar módulo dat2_reader.py com parsing de header e índice
    - Implementar leitura do header DAT2 (4 bytes tamanho diretório)
    - Implementar parsing das entradas do diretório (nome, offset, tamanho, compressed)
    - Implementar método `list_files()` retornando lista de caminhos
    - _Requirements: 1.1_
  - [x] 2.2 Escrever property test para listagem de arquivos DAT2
    - **Property 1: DAT2 File Listing Completeness**
    - **Validates: Requirements 1.1**
  - [x] 2.3 Implementar extração e descompressão de arquivos
    - Implementar método `extract_file(path)` com descompressão zlib
    - Implementar tratamento de arquivos não comprimidos
    - _Requirements: 1.2_
  - [x] 2.4 Escrever property test para round-trip de extração
    - **Property 2: DAT2 Extraction Round-Trip**
    - **Validates: Requirements 1.2**
  - [x] 2.5 Implementar sistema de prioridade multi-DAT
    - Implementar classe `DAT2Manager` que gerencia múltiplos DAT2
    - Implementar ordem de prioridade: patch000.dat > critter.dat > master.dat
    - _Requirements: 1.4_
  - [x] 2.6 Escrever property test para resolução de prioridade
    - **Property 3: DAT2 Priority Resolution**
    - **Validates: Requirements 1.4**

- [x] 3. Checkpoint - Verificar testes DAT2
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implementar PaletteLoader e FRMDecoder
  - [x] 4.1 Criar módulo palette_loader.py
    - Implementar leitura de arquivos .pal (768 bytes = 256 cores RGB)
    - Implementar método `get_color(index)` retornando tupla RGB
    - Carregar paleta padrão do Fallout 2 (color.pal)
    - _Requirements: 2.1_
  - [x] 4.2 Criar módulo frm_decoder.py com parsing de header FRM
    - Implementar leitura do header FRM (versão, fps, num_frames, offsets)
    - Implementar parsing de frame data (width, height, offset_x, offset_y, pixels)
    - Suportar até 6 direções por FRM
    - _Requirements: 2.1, 2.2_
  - [x] 4.3 Implementar conversão FRM para PNG
    - Implementar método `to_png()` usando Pillow
    - Aplicar paleta de cores aos pixels indexados
    - Preservar transparência (índice 0 = alpha 0)
    - _Requirements: 2.1, 2.4_
  - [x] 4.4 Escrever property test para preservação de transparência


    - **Property 7: Transparency Preservation**
    - **Validates: Requirements 2.4**
  - [x] 4.5 Implementar exportação multi-direção
    - Gerar arquivos separados com sufixos (_ne, _e, _se, _sw, _w, _nw)
    - Implementar método `export_all_directions()`
    - _Requirements: 2.2_
  - [x] 4.6 Escrever property test para completude de direções


    - **Property 5: FRM Direction Export Completeness**
    - **Validates: Requirements 2.2**
  - [x] 4.7 Implementar exportação de animações (spritesheet/frames)
    - Implementar método `to_spritesheet()` para múltiplos frames
    - Implementar método `to_individual_frames()` alternativo
    - _Requirements: 2.3_
  - [x] 4.8 Escrever property test para exportação de frames

    - **Property 6: FRM Animation Frame Export**
    - **Validates: Requirements 2.3**

  - [x] 4.9 Escrever property test para round-trip FRM-PNG
    - **Property 4: FRM to PNG Round-Trip**
    - **Validates: Requirements 2.1, 2.5**

- [x] 5. Checkpoint - Verificar testes FRM
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implementar Extração de Criaturas
  - [x] 6.1 Criar módulo critter_extractor.py
    - Implementar varredura de critter.dat para sprites de criaturas
    - Organizar por tipo (humans, animals, mutants, robots)
    - Extrair todas as animações (idle, walk, attack, death, etc.)
    - _Requirements: 3.1, 3.2_
  - [x] 6.2 Escrever property test para completude de animações


    - **Property 8: Critter Animation Completeness**
    - **Validates: Requirements 3.2**
  - [x] 6.3 Implementar preservação de metadados de offset
    - Gerar arquivo JSON com offset_x, offset_y para cada sprite
    - Incluir informações de fps e frame count
    - _Requirements: 3.3_

  - [x] 6.4 Escrever property test para metadados de offset
    - **Property 9: Sprite Offset Metadata Preservation**
    - **Validates: Requirements 3.3**

- [x] 7. Implementar Extração de Tiles
  - [x] 7.1 Criar módulo tile_extractor.py
    - Implementar extração de tiles de chão (floor) e teto (roof)
    - Organizar por categoria (desert, city, cave, vault, etc.)
    - Preservar dimensões isométricas (80x36 para floor tiles)
    - _Requirements: 4.1, 4.2, 4.3_
  - [x] 7.2 Escrever property test para dimensões de tiles


    - **Property 10: Isometric Tile Dimensions**
    - **Validates: Requirements 4.3**

- [x] 8. Implementar Extração de Interface
  - [x] 8.1 Criar módulo ui_extractor.py
    - Extrair elementos de art/intrface/
    - Manter nomenclatura descritiva (mainmenu_bg.png, button_normal.png)
    - Incluir ícones de inventário e slots
    - _Requirements: 5.1, 5.2, 5.3_

- [x] 9. Checkpoint - Verificar extração de sprites
  - Ensure all tests pass, ask the user if questions arise.

- [x] 10. Implementar ACMDecoder (Áudio)
  - [x] 10.1 Criar módulo acm_decoder.py
    - Implementar decodificação do formato ACM
    - Converter para WAV intermediário
    - Converter WAV para OGG usando ffmpeg ou biblioteca Python
    - _Requirements: 6.1_
  - [x] 10.2 Escrever property test para conversão de áudio



    - **Property 11: Audio Format Conversion**
    - **Validates: Requirements 6.1**
  - [x] 10.3 Implementar organização de áudio
    - Organizar em pastas: music/, sfx/, voice/
    - Implementar detecção automática de tipo por caminho original
    - _Requirements: 6.2_

- [x] 11. Implementar MAPParser
  - [x] 11.1 Criar módulo map_parser.py
    - Implementar parsing do header de mapa (versão, nome, dimensões)
    - Implementar parsing de tiles por nível
    - Implementar parsing de objetos (pid, posição, orientação)
    - _Requirements: 7.1_
  - [x] 11.2 Implementar exportação JSON de mapas
    - Exportar estrutura completa em JSON legível
    - Incluir referências a scripts associados
    - _Requirements: 7.2, 7.3_
  - [x] 11.3 Escrever property test para completude de dados de mapa


    - **Property 12: MAP Data Completeness**
    - **Validates: Requirements 7.1, 7.2, 7.3**

- [x] 12. Implementar MSGParser
  - [x] 12.1 Criar módulo msg_parser.py
    - Implementar parsing de arquivos MSG (formato {id}{}{texto})
    - Preservar IDs originais das mensagens
    - Suportar caracteres especiais e encoding
    - _Requirements: 8.1_
  - [x] 12.2 Implementar exportação JSON de mensagens
    - Exportar como {id: texto} em JSON
    - Organizar por locale quando aplicável
    - _Requirements: 8.2, 8.3_
  - [x] 12.3 Escrever property test para round-trip de MSG



    - **Property 13: MSG Parsing Round-Trip**
    - **Validates: Requirements 8.1, 8.2**

- [x] 13. Checkpoint - Verificar parsers de dados
  - Ensure all tests pass, ask the user if questions arise.

- [x] 14. Implementar AssetOrganizer e Manifesto
  - [x] 14.1 Criar módulo asset_organizer.py
    - Implementar organização automática na estrutura Godot
    - Criar subpastas: sprites/{categoria}/, audio/{tipo}/, data/{tipo}/
    - _Requirements: 10.1, 10.2, 10.3, 10.4_
  - [x] 14.2 Escrever property test para conformidade de estrutura


    - **Property 15: Output Structure Conformance**
    - **Validates: Requirements 10.1, 10.2, 10.3, 10.4**
  - [x] 14.3 Implementar geração de manifesto
    - Gerar manifest.json com todos os assets extraídos
    - Incluir: original_path, output_path, asset_type, dimensions
    - _Requirements: 9.1, 9.2_

  - [ ] 14.4 Escrever property test para completude do manifesto
    - **Property 14: Manifest Entry Completeness**
    - **Validates: Requirements 9.2**
  - [x] 14.5 Implementar logging de erros
    - Criar arquivo de log separado para erros
    - Incluir timestamp, arquivo, tipo de erro, mensagem
    - _Requirements: 9.3_

- [x] 15. Implementar ExtractionPipeline
  - [x] 15.1 Criar módulo extraction_pipeline.py
    - Orquestrar todos os extratores em sequência
    - Implementar métodos: extract_all(), extract_sprites(), extract_audio(), etc.
    - Gerar relatório final com estatísticas
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [x] 15.2 Criar script CLI principal
    - Criar `tools/extract_all.py` como ponto de entrada
    - Aceitar argumentos: --fallout2-path, --output-path, --types
    - Mostrar progresso durante extração
    - _Requirements: All_

- [x] 16. Checkpoint Final - Verificar todos os testes
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 17. Executar Extração Completa
  - [ ] 17.1 Executar extração de todos os assets do Fallout 2
    - Rodar pipeline completo com arquivos reais
    - Verificar manifesto gerado
    - Validar estrutura de saída em godot_project/assets/
    - _Requirements: All_

- [x] 18. Organizar Assets para Substituição (Jogo AAA)
  - [x] 18.1 Executar script de reorganização de assets
    - Rodar `python tools/organize_assets_for_replacement.py`
    - Reorganizar critters com nomes legíveis (deathclaw, super_mutant, etc.)
    - Criar estrutura de pastas por categoria (humans, animals, mutants, robots)
    - _Requirements: 3.4, 3.5, 11.1, 11.2, 11.3_
  - [x] 18.2 Gerar manifestos individuais por personagem
    - Criar _manifest.json em cada pasta de NPC/criatura
    - Incluir lista de animações, direções, tamanho recomendado
    - _Requirements: 11.3_
  - [x] 18.3 Gerar documentação de substituição
    - Criar ASSET_REPLACEMENT_GUIDE.md com instruções detalhadas
    - Criar ASSETS_SUMMARY.md com lista de todos os assets
    - _Requirements: 11.1, 11.5_

- [ ] 19. Checkpoint Final - Validar Estrutura para Jogo AAA
  - Verificar que todos os assets estão organizados com nomes legíveis
  - Confirmar que guias de substituição foram gerados
  - Testar que o jogo ainda funciona com a nova estrutura
