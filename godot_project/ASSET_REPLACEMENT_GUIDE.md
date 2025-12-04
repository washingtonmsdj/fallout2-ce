# Guia de Substituição de Assets

## Visão Geral

Este guia explica como substituir os assets placeholder pelos seus próprios assets originais.

## Estrutura de Pastas

```
assets/
├── characters/           # Personagens jogáveis e NPCs
│   ├── player/          # Personagem principal
│   └── npcs/            # NPCs do jogo
│       └── {npc_name}/  # Cada NPC em sua pasta
│           ├── idle/    # Animação parada
│           ├── walk/    # Animação andando
│           ├── run/     # Animação correndo
│           ├── attack/  # Animações de ataque
│           └── _manifest.json
├── creatures/           # Criaturas e inimigos
│   ├── animal/
│   ├── monster/
│   ├── mutant/
│   └── robot/
├── tiles/               # Tiles de mapa
│   ├── desert/
│   ├── city/
│   ├── cave/
│   └── interior/
├── ui/                  # Interface do usuário
│   ├── menus/
│   ├── hud/
│   ├── buttons/
│   └── icons/
└── audio/               # Áudio
    ├── music/
    ├── sfx/
    └── voice/
```

## Como Substituir Personagens

### 1. Localize a pasta do personagem
Cada personagem tem sua própria pasta em `characters/npcs/` ou `creatures/`.

### 2. Verifique o _manifest.json
O arquivo `_manifest.json` contém:
- Lista de animações necessárias
- Número de direções (geralmente 6)
- Tamanho recomendado dos sprites
- Formato de nomenclatura

### 3. Crie seus sprites
- **Tamanho recomendado**: 80x80 pixels (pode variar)
- **Formato**: PNG com transparência
- **Direções**: NE, E, SE, SW, W, NW (6 direções isométricas)
- **Nomenclatura**: `{animacao}_frame_{n}.png`

### 4. Substitua os arquivos
Simplesmente substitua os PNGs existentes pelos seus.

## Animações Necessárias

| Animação | Descrição | Frames típicos |
|----------|-----------|----------------|
| idle | Parado | 1-4 |
| walk | Andando | 6-8 |
| run | Correndo | 6-8 |
| attack_punch | Soco | 4-6 |
| attack_kick | Chute | 4-6 |
| attack_fire | Atirando | 3-5 |
| death_normal | Morte normal | 6-10 |
| hit_front | Recebendo dano | 2-3 |

## Como Substituir Tiles

1. Localize a categoria em `tiles/`
2. Mantenha as dimensões isométricas: **80x36 pixels** para tiles de chão
3. Use PNG com transparência onde necessário
4. Mantenha o mesmo nome de arquivo ou atualize as referências

## Como Substituir UI

1. Localize o elemento em `ui/`
2. Mantenha as mesmas dimensões ou ajuste o código
3. Use PNG com transparência
4. Teste no jogo após substituição

## Dicas para Jogo AAA

1. **Consistência visual**: Mantenha um estilo artístico consistente
2. **Resolução**: Considere suportar múltiplas resoluções (1x, 2x, 4x)
3. **Animações fluidas**: Use mais frames para animações mais suaves
4. **Efeitos**: Adicione partículas e efeitos visuais
5. **Som**: Substitua todos os sons por áudio original de alta qualidade

## Checklist de Substituição

- [ ] Personagem principal (player)
- [ ] NPCs principais
- [ ] Inimigos comuns
- [ ] Bosses
- [ ] Tiles de ambiente
- [ ] Interface do usuário
- [ ] Ícones de itens
- [ ] Música de fundo
- [ ] Efeitos sonoros
- [ ] Vozes/Diálogos

