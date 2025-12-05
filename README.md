# Fallout 2: Godot Edition

Reimplementação moderna e turbinada do Fallout 2 usando Godot Engine 4.3+

## Sobre o Projeto

Esta é uma recriação profissional do clássico RPG Fallout 2, migrando do código C++ original para uma arquitetura moderna em Godot, mantendo a essência do jogo original enquanto adiciona melhorias significativas de qualidade de vida e recursos modernos.

### Melhorias sobre o Original

- **Engine Moderna**: Godot 4.3+ com renderização avançada
- **UI Responsiva**: Interface adaptável para diferentes resoluções
- **Sistema de Combate Aprimorado**: Animações fluidas e feedback visual melhorado
- **Inventário Modernizado**: Drag & drop intuitivo
- **Sistema de Diálogos Expandido**: Suporte a vozes e animações faciais
- **Multiplataforma**: PC, Console, Mobile
- **Modding Facilitado**: Sistema de plugins e recursos do Godot

## Estrutura do Projeto

Este projeto segue padrões AAA de organização para garantir escalabilidade e manutenibilidade.

### Estrutura de Pastas

```
├── assets/              # Todos os assets do jogo
│   ├── audio/          # Sons, música, efeitos sonoros
│   ├── models/         # Modelos 3D
│   ├── textures/       # Texturas e materiais
│   ├── animations/     # Animações
│   ├── fonts/          # Fontes
│   ├── ui/             # Assets de interface
│   └── vfx/            # Efeitos visuais e partículas
│
├── scenes/             # Cenas do Godot
│   ├── characters/     # Personagens jogáveis e NPCs
│   ├── environments/   # Ambientes e níveis
│   ├── props/          # Objetos interativos
│   ├── ui/             # Interfaces de usuário
│   └── gameplay/       # Mecânicas de gameplay
│
├── scripts/            # Scripts organizados por sistema
│   ├── core/           # Sistemas fundamentais
│   ├── gameplay/       # Lógica de gameplay
│   ├── ai/             # Inteligência artificial
│   ├── ui/             # Lógica de interface
│   ├── managers/       # Gerenciadores globais
│   └── utils/          # Utilitários e helpers
│
├── addons/             # Plugins e extensões
├── resources/          # Resources do Godot (materiais, etc)
├── shaders/            # Shaders customizados
├── localization/       # Arquivos de tradução
├── config/             # Configurações do jogo
├── docs/               # Documentação do projeto
└── tools/              # Ferramentas de desenvolvimento
```

## Convenções de Nomenclatura

- **Cenas**: PascalCase (ex: `PlayerCharacter.tscn`)
- **Scripts**: snake_case (ex: `player_controller.gd`)
- **Assets**: snake_case (ex: `hero_texture_diffuse.png`)
- **Constantes**: UPPER_SNAKE_CASE (ex: `MAX_HEALTH`)

## Workflow

1. Assets são importados em `assets/`
2. Cenas são criadas em `scenes/`
3. Scripts são organizados por sistema em `scripts/`
4. Resources compartilhados ficam em `resources/`
