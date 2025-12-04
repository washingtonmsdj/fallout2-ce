# 🛠️ Ferramentas de Conversão para Godot

Esta pasta contém scripts para converter assets do Fallout 2 para formatos compatíveis com o Godot.

## 📋 Scripts Disponíveis

### 1. `convert_frm_to_godot.py`
Converte sprites .FRM para PNG e cria recursos do Godot.

**Uso:**
```bash
python convert_frm_to_godot.py <diretório_com_frm> <diretório_saída>
```

**Exemplo:**
```bash
python convert_frm_to_godot.py "../web_server/assets/organized/sprites" "../godot_project/assets"
```

**O que faz:**
- Converte cada arquivo .FRM em múltiplos PNGs (um por frame/direção)
- Cria spritesheets combinando frames
- Gera arquivos JSON com metadados para o Godot
- Organiza sprites em estrutura compatível com Godot

### 2. `convert_map_to_godot.py`
Converte mapas .MAP para JSON e templates de cenas do Godot.

**Uso:**
```bash
python convert_map_to_godot.py <diretório_com_map> <diretório_saída>
```

**Exemplo:**
```bash
python convert_map_to_godot.py "../Fallout 2/data/maps" "../godot_project/assets/maps"
```

**O que faz:**
- Extrai dados dos arquivos .MAP
- Cria arquivos JSON com informações do mapa
- Gera templates de cenas .tscn do Godot
- Prepara estrutura para importação no Godot

## 🔧 Requisitos

### Python 3.7+
### Bibliotecas Python:
```bash
pip install Pillow
```

Ou instale todas de uma vez:
```bash
pip install -r requirements.txt
```

## 📝 Notas Importantes

### Sobre Conversão de .FRM:
- A paleta de cores precisa ser lida corretamente dos arquivos de dados do Fallout 2
- Alguns sprites podem ter transparência que precisa ser tratada
- Animações precisam ser configuradas manualmente no Godot após a conversão

### Sobre Conversão de .MAP:
- O formato .MAP é complexo e pode requerer ajustes no script
- Tiles e objetos podem precisar de processamento adicional
- Scripts de mapa precisam ser convertidos separadamente

## 🚀 Próximos Passos

1. **Testar conversão** de um sprite simples
2. **Testar conversão** de um mapa simples
3. **Importar no Godot** e verificar resultado
4. **Ajustar scripts** conforme necessário

## ⚠️ Avisos

- Estes scripts são **versões iniciais** e podem precisar de ajustes
- Alguns formatos do Fallout 2 são complexos e podem requerer análise mais profunda
- Sempre **faça backup** dos assets originais antes de converter

