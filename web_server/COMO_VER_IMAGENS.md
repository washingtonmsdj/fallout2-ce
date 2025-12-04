# 🖼️ Como Ver as Imagens dos Sprites

## ⚠️ Problema Atual

A maioria dos sprites está **dentro dos arquivos .DAT** (master.dat e critter.dat), não em pastas. Por isso você não está vendo as imagens dos personagens.

## ✅ Solução: Extrair dos .DAT

### Opção 1: Usar Ferramentas Existentes (Recomendado)

1. **Baixar dat2 ou Fallout Mod Manager**
   - `dat2` - Extrator de .DAT
   - `Fallout Mod Manager` - Gerencia e extrai assets

2. **Extrair arquivos .FRM**
   - Abra o `master.dat` ou `critter.dat`
   - Extraia os arquivos `.FRM` para uma pasta
   - Exemplo: `Fallout 2/data/art/critters/`

3. **Converter para PNG**
   ```bash
   cd web_server
   python frm_to_png.py
   ```

4. **Ver no Dashboard**
   - Abra: http://localhost:8000/sprite_gallery.html
   - Você verá todas as imagens!

### Opção 2: Criar Extrator Próprio

Baseado no código do projeto:
- `src/xfile.cc` - Sistema de arquivos
- `src/dfile.cc` - Leitura de .DAT
- `src/db.cc` - Sistema de hash

## 📍 Onde Estão os Sprites dos NPCs?

### Dentro dos .DAT:
- **critter.dat** (166 MB) - Sprites de NPCs/criaturas
- **master.dat** (333 MB) - Outros sprites

### Estrutura Esperada:
```
art/critters/hmwarr.frm  - Homem Tribal
art/critters/hfprim.frm  - Mulher Tribal
art/critters/hmjmps.frm  - Homem Jumpsuit
art/critters/hfjmps.frm  - Mulher Jumpsuit
... e muitos outros
```

## 🎯 Passo a Passo Completo

1. **Extrair .FRM dos .DAT**
   - Use `dat2` ou similar
   - Extraia para `Fallout 2/data/art/critters/`

2. **Converter para PNG**
   ```bash
   python web_server/frm_to_png.py
   ```

3. **Ver no Dashboard**
   - http://localhost:8000/sprite_gallery.html
   - Você verá todas as imagens dos personagens!

## 🔧 Melhorias Futuras

- [ ] Criar extrator de .DAT integrado
- [ ] Carregar paleta correta (color.pal)
- [ ] Suporte para animações
- [ ] Busca e filtros avançados

