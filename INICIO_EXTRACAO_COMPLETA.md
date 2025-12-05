# 🚀 INÍCIO RÁPIDO - Extração Completa do Fallout 2

## ⚡ Execução Rápida

Para extrair **TODO o conteúdo** do Fallout 2:

```bash
cd tools
python extrair_tudo.py
```

Ou com caminhos customizados:

```bash
python extrair_tudo.py --fallout2-path "Fallout 2" --output-path "godot_project/assets"
```

## 📋 O Que Será Extraído

O sistema extrairá e processará:

- ✅ **Sprites** (.FRM → PNG)
- ✅ **Mapas** (.MAP → JSON)
- ✅ **Protótipos** (.PRO → JSON)
- ✅ **Textos/Diálogos** (.MSG → JSON)
- ✅ **Áudio** (.ACM → WAV)
- ✅ **Paletas** (.PAL)
- ✅ **Scripts** (.INT, .SSL)
- ✅ **Outros arquivos** (genéricos)

## 📁 Onde Ficam os Arquivos

### Arquivos Extraídos
```
godot_project/assets/
├── sprites/          # Sprites convertidos
├── maps/             # Mapas convertidos
├── prototypes/       # Protótipos convertidos
├── texts/            # Textos convertidos
├── audio/            # Áudio convertido
└── ...
```

### Arquivos Marcados como Processados
```
Fallout 2/processed/
├── art/              # Marcadores de arquivos processados
├── maps/
└── ...
```

## 🔄 Sistema de Tracking

- ✅ Arquivos processados são **marcados** (não movidos, pois estão dentro de DATs)
- ✅ Progresso é **salvo automaticamente** a cada 10 arquivos
- ✅ Você pode **interromper** (Ctrl+C) e **retomar** depois
- ✅ Arquivos já processados são **pulados automaticamente**

## ⏱️ Tempo Estimado

A extração completa pode levar:
- **1-3 horas** dependendo do hardware
- Progresso é salvo automaticamente
- Pode ser interrompida e retomada

## 📊 Acompanhar Progresso

Durante a extração, você verá:

```
[1/5000] 🔄 Processando: art/critters/player/plmale.frm
  ✅ Sucesso!

[2/5000] 🔄 Processando: maps/artemple.map
  ✅ Sucesso!

📊 Progresso: 10/5000 (0.2%) | ✅ 10 | ❌ 0 | ⏭️  0
```

## 📝 Relatórios Gerados

Após a extração:

1. **extraction_progress.json** - Progresso detalhado
2. **extraction_report.json** - Relatório final com estatísticas

## 🆘 Problemas?

### Erro: "Nenhum arquivo DAT encontrado"
- Certifique-se de que `master.dat` e `critter.dat` estão na pasta "Fallout 2"

### Extração muito lenta
- Normal! Pode levar horas. O progresso é salvo automaticamente.

### Quer reprocessar um arquivo
- Delete o arquivo `.processed` correspondente na pasta `processed/`

## 📚 Documentação Completa

Para mais detalhes, veja:
- `tools/README_EXTRACAO_COMPLETA.md` - Documentação completa
- `tools/extract_complete_with_tracking.py` - Código fonte

---

**Boa extração!** 🎮✨


