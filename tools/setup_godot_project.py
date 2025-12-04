#!/usr/bin/env python3
"""
Script para criar estrutura base do projeto Godot
Cria todas as pastas e arquivos iniciais necessários
"""

import os
import json
from pathlib import Path
import argparse

def create_project_structure(base_path):
    """Cria estrutura completa de pastas do projeto Godot"""
    base = Path(base_path)
    
    # Criar estrutura de diretórios
    directories = [
        "scenes/maps",
        "scenes/ui",
        "scenes/characters",
        "scripts/core",
        "scripts/systems",
        "scripts/actors",
        "assets/sprites/characters",
        "assets/sprites/items",
        "assets/sprites/tiles",
        "assets/audio/music",
        "assets/audio/sfx",
        "assets/data",
    ]
    
    print("📁 Criando estrutura de pastas...")
    for directory in directories:
        dir_path = base / directory
        dir_path.mkdir(parents=True, exist_ok=True)
        print(f"  ✅ {directory}")
    
    return base

def create_project_file(base_path):
    """Cria arquivo project.godot básico"""
    project_content = """; Engine configuration file.
; It's best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section] ; section goes between []
;   param=value ; assign values to parameters

config_version=5

[application]

config/name="Fallout 2 Godot"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.2", "Forward Plus")
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1024
window/size/viewport_height=768
window/size/mode=2
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[input]

move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
inventory={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":73,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}

[rendering]

textures/canvas_textures/default_texture_filter=0
"""
    
    project_file = base_path / "project.godot"
    with open(project_file, 'w', encoding='utf-8') as f:
        f.write(project_content)
    
    print(f"✅ Arquivo project.godot criado")

def create_readme(base_path):
    """Cria README para o projeto Godot"""
    readme_content = """# Fallout 2 - Projeto Godot

Projeto de migração do Fallout 2 CE para o Godot Engine.

## 📁 Estrutura

- `scenes/` - Cenas do jogo (mapas, UI, personagens)
- `scripts/` - Scripts GDScript
- `assets/` - Assets do jogo (sprites, áudio, dados)

## 🚀 Como Começar

1. Abra este projeto no Godot 4.2 ou superior
2. Execute a cena principal (`scenes/main.tscn`)
3. Comece a desenvolver!

## 📚 Documentação

Veja `MIGRACAO_GODOT.md` para o guia completo de migração.
"""
    
    readme_file = base_path / "README.md"
    with readme_file.open('w', encoding='utf-8') as f:
        f.write(readme_content)
    
    print(f"✅ README.md criado")

def main():
    parser = argparse.ArgumentParser(description='Cria estrutura base do projeto Godot')
    parser.add_argument('project_path', help='Caminho onde criar o projeto Godot')
    
    args = parser.parse_args()
    
    project_path = Path(args.project_path)
    
    print("🎮 Criando projeto Godot...")
    print(f"📁 Local: {project_path.absolute()}")
    print()
    
    # Criar estrutura
    base = create_project_structure(project_path)
    
    # Criar arquivos base
    create_project_file(base)
    create_readme(base)
    
    print()
    print("✅ Projeto Godot criado com sucesso!")
    print()
    print("📝 Próximos passos:")
    print("  1. Abra o Godot")
    print("  2. Import Project → Selecione a pasta do projeto")
    print("  3. Comece a desenvolver!")
    print()
    print(f"   Projeto em: {project_path.absolute()}")

if __name__ == "__main__":
    main()

