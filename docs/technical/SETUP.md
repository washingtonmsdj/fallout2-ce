# Guia de Configuração

## Requisitos

- Godot Engine 4.3+
- Git para controle de versão
- Editor de código (VS Code recomendado)

## Configuração Inicial

### 1. Clone o Repositório
```bash
git clone [url-do-repositorio]
cd [nome-do-projeto]
```

### 2. Abra no Godot
1. Abra o Godot Engine
2. Clique em "Import"
3. Navegue até a pasta do projeto
4. Selecione `project.godot`

### 3. Configure os Autoloads
Project Settings > Autoload:
- GameManager: `res://scripts/core/game_manager.gd`
- AudioManager: `res://scripts/managers/audio_manager.gd`
- SaveManager: `res://scripts/managers/save_manager.gd`

### 4. Configure os Input Maps
Project Settings > Input Map:
- Adicione ações de input conforme necessário

### 5. Configure os Audio Buses
Audio > Audio Buses:
- Master
  - Music
  - SFX
  - Voice
  - Ambient

## Estrutura de Branches

- `main`: Versão estável
- `develop`: Desenvolvimento ativo
- `feature/*`: Novas funcionalidades
- `bugfix/*`: Correções de bugs
- `hotfix/*`: Correções urgentes

## Workflow de Desenvolvimento

1. Crie uma branch a partir de `develop`
2. Desenvolva a funcionalidade
3. Teste localmente
4. Crie um Pull Request
5. Code review
6. Merge para `develop`

## Ferramentas Recomendadas

- **VS Code** com extensões:
  - godot-tools
  - GDScript
- **Blender** para modelagem 3D
- **Audacity** para edição de áudio
- **GIMP/Photoshop** para texturas
