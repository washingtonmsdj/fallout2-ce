# 🚀 Sistema de Extração Completa com Tracking

Este sistema extrai **TODO o conteúdo** do Fallout 2 e marca arquivos processados para facilitar a migração para Godot.

## 📋 Funcionalidades

- ✅ Extrai todos os arquivos dos DATs (master.dat, critter.dat, patch000.dat)
- ✅ Processa cada arquivo conforme seu tipo:
  - `.FRM` → Sprites PNG
  - `.MAP` → Mapas JSON
  - `.PRO` → Protótipos JSON
  - `.MSG` → Textos/Diálogos JSON
  - `.ACM` → Áudio WAV
  - `.PAL` → Paletas
  - `.INT/.SSL` → Scripts
  - Outros → Arquivos genéricos
- ✅ Marca arquivos processados (cria arquivos `.processed` na pasta `processed/`)
- ✅ Mantém log de progresso (permite retomar de onde parou)
- ✅ Gera relatório completo da extração

## 🎯 Como Usar

### Extração Completa

```bash
cd tools
python extract_complete_with_tracking.py --fallout2-path "../Fallout 2" --output-path "../godot_project/assets"
```

### Com Pasta de Processados Customizada

```bash
python extract_complete_with_tracking.py \
  --fallout2-path "../Fallout 2" \
  --output-path "../godot_project/assets" \
  --processed-path "../Fallout 2/processed"
```

## 📁 Estrutura de Pastas

Após a extração, você terá:

```
Fallout 2/
├── master.dat          # Arquivo original (não modificado)
├── critter.dat         # Arquivo original (não modificado)
├── patch000.dat        # Arquivo original (não modificado)
└── processed/          # Arquivos marcados como processados
    ├── art/
    │   ├── critters/
    │   │   └── *.processed  # Marcadores de arquivos processados
    │   └── ...
    └── ...

godot_project/assets/
├── sprites/            # Sprites convertidos (PNG)
├── maps/               # Mapas convertidos (JSON)
├── prototypes/         # Protótipos convertidos (JSON)
├── texts/              # Textos convertidos (JSON)
├── audio/              # Áudio convertido (WAV)
├── palettes/           # Paletas
├── scripts/            # Scripts
├── misc/               # Arquivos genéricos
├── extraction_progress.json  # Progresso da extração
└── extraction_report.json     # Relatório final
```

## 🔄 Sistema de Tracking

### Como Funciona

Como arquivos dentro de DATs não podem ser movidos diretamente, o sistema cria **arquivos marcadores** na pasta `processed/`:

- Cada arquivo processado gera um arquivo `.processed` correspondente
- O marcador contém informações sobre quando foi processado
- Arquivos já processados são pulados automaticamente

### Exemplo de Marcador

```json
{
  "original_path": "art/critters/player/plmale.frm",
  "processed_date": "2025-01-27T10:30:00",
  "status": "processed"
}
```

### Retomar Extração

O sistema salva progresso automaticamente. Se a extração for interrompida:

1. Execute o mesmo comando novamente
2. O sistema detectará arquivos já processados
3. Continuará de onde parou

## 📊 Relatórios

### Progresso (extraction_progress.json)

Contém:
- Total de arquivos
- Arquivos processados
- Arquivos com sucesso/falha
- Lista completa de arquivos processados

### Relatório Final (extraction_report.json)

Contém:
- Estatísticas completas
- Taxa de sucesso
- Contagem por tipo de arquivo
- Lista de erros (se houver)

## ⚙️ Opções Avançadas

### Processar Apenas Arquivos Não Processados

O sistema automaticamente pula arquivos já processados. Para reprocessar:

1. Delete o arquivo `extraction_progress.json`
2. Ou delete os marcadores `.processed` específicos

### Verificar Arquivos Processados

```bash
# Contar arquivos processados
find "Fallout 2/processed" -name "*.processed" | wc -l

# Listar arquivos processados
find "Fallout 2/processed" -name "*.processed"
```

## 🐛 Troubleshooting

### Erro: "Nenhum arquivo DAT encontrado"

Certifique-se de que os arquivos `master.dat` e `critter.dat` estão na pasta do Fallout 2.

### Erro: "Falha ao processar"

Alguns arquivos podem falhar no processamento. Isso é normal. O sistema continua com os próximos arquivos e registra os erros no relatório.

### Extração Muito Lenta

A extração pode levar várias horas dependendo do número de arquivos. O sistema salva progresso automaticamente, então você pode interromper e retomar depois.

## 📝 Notas Importantes

1. **Arquivos Originais Não São Modificados**: Os arquivos `.DAT` originais permanecem intactos
2. **Marcadores São Criados**: Apenas arquivos marcadores são criados na pasta `processed/`
3. **Progresso É Salvo**: O progresso é salvo automaticamente a cada 10 arquivos
4. **Pode Ser Interrompido**: Você pode interromper (Ctrl+C) e retomar depois

## 🎯 Próximos Passos Após Extração

Após a extração completa:

1. ✅ Verificar relatório final
2. ✅ Importar assets no projeto Godot
3. ✅ Converter assets para recursos do Godot (se necessário)
4. ✅ Testar importação no jogo

---

**Boa extração!** 🚀


