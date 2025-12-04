#!/usr/bin/env python3
"""
Gera arquivo SpriteFrames (.tres) para o player do Godot
usando os spritesheets extraídos do Fallout 2
"""

from pathlib import Path
from PIL import Image
import json

# Configuração
PLAYER_VARIANT = "player_male_jumpsuit"
BASE_PATH = Path("godot_project/assets/characters/player") / PLAYER_VARIANT
OUTPUT_PATH = Path("godot_project/assets/characters/player/player_spriteframes.tres")

# Animações e direções
ANIMATIONS = ["idle", "walk", "run", "attack_unarmed", "attack_melee", "death_1"]
DIRECTIONS = ["ne", "e", "se", "sw", "w", "nw"]

def get_spritesheet_info(path: Path) -> tuple:
    """Retorna (largura, altura, num_frames) de um spritesheet"""
    if not path.exists():
        return (0, 0, 0)
    
    img = Image.open(path)
    width, height = img.size
    
    # Assumir que frames são quadrados ou baseados na altura
    frame_width = height  # Frames do Fallout são aproximadamente quadrados
    num_frames = max(1, width // frame_width) if frame_width > 0 else 1
    
    return (width, height, num_frames)


def generate_spriteframes():
    """Gera o arquivo .tres com SpriteFrames"""
    
    # Coletar informações de todas as animações
    animations_info = []
    ext_resources = []
    resource_id = 1
    
    for anim_name in ANIMATIONS:
        for dir_idx, dir_name in enumerate(DIRECTIONS):
            sheet_path = BASE_PATH / "animations" / anim_name / f"{anim_name}_{dir_name}.png"
            
            if not sheet_path.exists():
                print(f"AVISO: {sheet_path} não encontrado")
                continue
            
            width, height, num_frames = get_spritesheet_info(sheet_path)
            if num_frames == 0:
                continue
            
            frame_width = width // num_frames if num_frames > 0 else width
            
            # Caminho relativo para o Godot
            godot_path = f"res://assets/characters/player/{PLAYER_VARIANT}/animations/{anim_name}/{anim_name}_{dir_name}.png"
            
            ext_resources.append({
                'id': resource_id,
                'path': godot_path,
                'type': 'Texture2D'
            })
            
            animations_info.append({
                'name': f"{anim_name}_{dir_name}",
                'texture_id': resource_id,
                'num_frames': num_frames,
                'frame_width': frame_width,
                'frame_height': height,
                'fps': 10.0,
                'loop': anim_name in ['idle', 'walk', 'run']
            })
            
            resource_id += 1
            print(f"  {anim_name}_{dir_name}: {num_frames} frames ({frame_width}x{height})")
    
    # Gerar arquivo .tres
    with open(OUTPUT_PATH, 'w') as f:
        f.write('[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n' % (len(ext_resources) + 1))
        
        # External resources
        for res in ext_resources:
            f.write(f'[ext_resource type="{res["type"]}" path="{res["path"]}" id="{res["id"]}"]\n')
        
        f.write('\n[resource]\n')
        f.write('animations = [')
        
        for i, anim in enumerate(animations_info):
            if i > 0:
                f.write(', ')
            
            f.write('{\n')
            f.write(f'"loop": {"true" if anim["loop"] else "false"},\n')
            f.write(f'"name": &"{anim["name"]}",\n')
            f.write(f'"speed": {anim["fps"]},\n')
            f.write('"frames": [')
            
            # Gerar frames usando AtlasTexture
            for frame_idx in range(anim['num_frames']):
                if frame_idx > 0:
                    f.write(', ')
                
                x = frame_idx * anim['frame_width']
                
                f.write('{\n')
                f.write(f'"duration": 1.0,\n')
                f.write(f'"texture": SubResource("atlas_{anim["texture_id"]}_{frame_idx}")\n')
                f.write('}')
            
            f.write(']\n')
            f.write('}')
        
        f.write(']\n')
        
        # Gerar sub-resources para AtlasTextures
        f.write('\n')
        for anim in animations_info:
            for frame_idx in range(anim['num_frames']):
                x = frame_idx * anim['frame_width']
                f.write(f'\n[sub_resource type="AtlasTexture" id="atlas_{anim["texture_id"]}_{frame_idx}"]\n')
                f.write(f'atlas = ExtResource("{anim["texture_id"]}")\n')
                f.write(f'region = Rect2({x}, 0, {anim["frame_width"]}, {anim["frame_height"]})\n')
    
    print(f"\nSpriteFrames salvo em: {OUTPUT_PATH}")
    print(f"Total: {len(animations_info)} animações")


if __name__ == '__main__':
    print("Gerando SpriteFrames para o player...")
    print(f"Usando variante: {PLAYER_VARIANT}")
    print(f"Base path: {BASE_PATH}")
    print()
    generate_spriteframes()
