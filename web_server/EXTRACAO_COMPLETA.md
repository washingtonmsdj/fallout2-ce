# 📦 Extração Completa dos Arquivos .DAT

## 🎯 O que este script faz?

Extrai **TODOS os arquivos** dos arquivos .DAT do Fallout 2, incluindo:

- ✅ **.FRM** - Sprites e animações
- ✅ **.MAP** - Mapas do jogo
- ✅ **.MSG** - Textos e diálogos
- ✅ **.INT** - Scripts (bytecode)
- ✅ **.PRO** - Protótipos de criaturas e itens
- ✅ **.ACM** - Músicas e sons
- ✅ **.DAT** - Outros containers
- ✅ **E muito mais!**

## 🚀 Como Usar

### Windows:
```bash
# Opção 1: Duplo clique
extract_all.bat

# Opção 2: Linha de comando
cd web_server
python extract_all_dat.py
```

### Linux/Mac:
```bash
cd web_server
python3 extract_all_dat.py
```

## ⚠️ Atenção

- **Tempo:** Pode levar 10-30 minutos dependendo do seu computador
- **Espaço:** Vai ocupar vários GB de espaço em disco
- **Arquivos:** Milhares de arquivos serão extraídos

## 📁 Onde os arquivos são salvos?

```
web_server/assets/extracted/
├── critter/     # Arquivos do critter.dat
├── master/      # Arquivos do master.dat
├── patch000/    # Arquivos do patch000.dat
└── f2_res/      # Arquivos do f2_res.dat
```

## 📊 O que você vai ver

O script mostra:
- Progresso em tempo real
- Estatísticas por tipo de arquivo
- Quantidade de arquivos extraídos
- Resumo final completo

## 🎮 Visualizar no Navegador

Após a extração:

1. Inicie o servidor:
   ```bash
   python web_server/server.py
   ```

2. Abra no navegador:
   ```
   http://localhost:8000/asset_viewer.html
   ```

3. Explore:
   - Galeria de sprites
   - Lista de arquivos
   - Estatísticas
   - Navegador de arquivos

## ❓ Sobre Rodar o Jogo no Navegador

**Resposta curta:** Não é possível rodar o jogo completo no navegador.

**Por quê?**
- O Fallout 2 é um jogo nativo (C++) que precisa ser compilado
- O motor do jogo não pode rodar em JavaScript
- Scripts .INT são bytecode específico do Fallout

**O que É possível:**
- ✅ Visualizar todos os assets
- ✅ Ver sprites, mapas, textos
- ✅ Explorar a estrutura dos arquivos
- ✅ Analisar formatos

**O que NÃO é possível:**
- ❌ Executar o motor do jogo
- ❌ Rodar scripts .INT
- ❌ Jogar o jogo completo

**Alternativa:**
Use o código-fonte C++ para compilar e executar o jogo nativamente.

## 🔧 Próximos Passos

1. **Extrair tudo:**
   ```bash
   python web_server/extract_all_dat.py
   ```

2. **Visualizar no navegador:**
   ```bash
   python web_server/server.py
   # Abra: http://localhost:8000/asset_viewer.html
   ```

3. **Converter sprites para PNG:**
   ```bash
   python web_server/frm_to_png.py
   ```

4. **Explorar outros formatos:**
   - Mapas (.MAP)
   - Scripts (.INT)
   - Textos (.MSG)
   - Protótipos (.PRO)

