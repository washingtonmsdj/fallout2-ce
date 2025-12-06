# 🎮 Como Testar o City Map System

## ⚡ Passos Rápidos

### 1️⃣ Recarregar o Projeto
No Godot, pressione:
```
Ctrl + Alt + R
```
Ou vá em: `Project > Reload Current Project`

**Por quê?** Isso limpa o cache e garante que todos os scripts atualizados sejam carregados.

### 2️⃣ Executar o Jogo
Pressione:
```
F5
```
Ou vá em: `Project > Run`

### 3️⃣ Selecionar a Cena
Se pedir para selecionar uma cena, escolha:
```
scenes/test/TestCityIntegrated.tscn
```

---

## ✅ O Que Você Deve Ver

### No Console (Output)
```
🏙️ Initializing City Map System...

🛣️ Creating roads...
✅ Created 2 roads

🏘️ Creating zones...
✅ Created 2 zones

🏢 Creating buildings...
✅ Created 4 buildings

👥 Creating citizens...
✅ Created 5 citizens

⚔️ Creating factions...
✅ Created 2 factions

💰 Initializing economy...
✅ Economy initialized

✅ City Map System initialized!
📊 Grid: 100x100
🛣️ Roads: 2
🏢 Buildings: 4
👥 Citizens: 5
💰 Resources: 9 types
⚔️ Factions: 2
```

### Na Tela (UI)
No canto superior esquerdo:
```
🏙️ CITY MAP SYSTEM
─────────────────
👥 Pop: 5
🏗️ Build: 4
─────────────────
🍖 100
💧 100
💰 500
🧱 200
─────────────────
😊 50%
⏱️ 1.0x
```

### Controles
- **Scroll do Mouse**: Zoom in/out
- **Espaço**: Liga/desliga modo de construção
- **ESC**: Cancela modo de construção

---

## 🐛 Problemas Comuns

### ❌ Erro: "Could not resolve class"
**Solução**: Recarregue o projeto (`Ctrl+Alt+R`)

### ❌ Erro: "Invalid assignment"
**Solução**: 
1. Feche o Godot completamente
2. Delete a pasta `.godot/` na raiz do projeto
3. Reabra o Godot

### ❌ Console vazio
**Solução**: 
1. Verifique se está na aba "Output" (não "Debugger")
2. Certifique-se que a cena `TestCityIntegrated.tscn` está selecionada

### ❌ Tela preta
**Solução**: 
1. A câmera pode estar mal posicionada
2. Tente dar zoom out com o scroll do mouse

---

## 📊 O Que Está Funcionando

### ✅ Sistemas Ativos
1. **Grid** - Mapa 100x100 com terreno
2. **Roads** - 2 estradas principais (horizontal e vertical)
3. **Zones** - Zona residencial e comercial
4. **Buildings** - 2 casas, 1 loja, 1 fazenda
5. **Citizens** - 5 cidadãos com casas e trabalhos
6. **Economy** - Recursos sendo rastreados
7. **Factions** - 2 facções com território

### ✅ Recursos Iniciais
- 🍖 Comida: 100
- 💧 Água: 100
- 💰 Caps: 500
- 🧱 Materiais: 200

### ✅ Cidadãos
- 5 cidadãos criados
- Todos têm casa
- Todos têm trabalho
- Skills aleatórios (30-80)
- Trait "hardworking"

### ✅ Facções
- "Player Settlement" (verde) - controla território
- "Rival Faction" (vermelho)

---

## 🎯 O Que Testar

1. **Inicialização**: Todos os sistemas devem inicializar sem erros
2. **UI**: Os números devem aparecer corretamente
3. **Console**: Deve mostrar as mensagens de criação
4. **Zoom**: Scroll do mouse deve funcionar
5. **Performance**: Deve rodar suavemente (60 FPS)

---

## 📝 Reportar Problemas

Se encontrar algum erro, anote:
1. **Mensagem de erro** (copie do console)
2. **Quando aconteceu** (ao iniciar, ao clicar, etc)
3. **O que estava fazendo** (zoom, construção, etc)

---

## 🚀 Próximos Passos

Após confirmar que tudo funciona:
1. Implementar PowerSystem (rede elétrica)
2. Implementar WaterSystem (rede de água)
3. Implementar WeatherSystem (clima)
4. Implementar rendering visual (isométrico)

---

**🎉 Boa sorte com o teste!**

Se tudo funcionar, você verá uma cidade básica funcionando com todos os sistemas integrados.
