#!/usr/bin/env python3
"""
Script para converter arquivos .MAP do Fallout 2 para cenas do Godot
Extrai informações dos mapas e cria arquivos JSON que podem ser importados no Godot
"""

import os
import sys
import struct
import json
from pathlib import Path
import argparse

class MapConverter:
    """Conversor de arquivos .MAP para formato do Godot"""
    
    def __init__(self, input_dir, output_dir):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Criar estrutura de pastas
        (self.output_dir / "maps").mkdir(exist_ok=True)
        (self.output_dir / "godot_scenes").mkdir(exist_ok=True)
    
    def read_map_header(self, file_path):
        """Lê o header do arquivo .MAP"""
        with open(file_path, 'rb') as f:
            # Estrutura do header .MAP (baseado em src/map.h)
            version = struct.unpack('<I', f.read(4))[0]
            
            if version not in [19, 20]:
                raise ValueError(f"Versão de mapa não suportada: {version}")
            
            name = f.read(16).decode('ascii', errors='ignore').rstrip('\x00')
            global_vars_count = struct.unpack('<I', f.read(4))[0]
            local_vars_count = struct.unpack('<I', f.read(4))[0]
            
            # Ler variáveis globais e locais
            global_vars = []
            for _ in range(global_vars_count):
                var_id = struct.unpack('<I', f.read(4))[0]
                var_value = struct.unpack('<i', f.read(4))[0]
                global_vars.append({'id': var_id, 'value': var_value})
            
            local_vars = []
            for _ in range(local_vars_count):
                var_id = struct.unpack('<I', f.read(4))[0]
                var_value = struct.unpack('<i', f.read(4))[0]
                local_vars.append({'id': var_id, 'value': var_value})
            
            # Ler informações de tiles
            # (Simplificado - o formato real é mais complexo)
            
            return {
                'version': version,
                'name': name,
                'global_vars': global_vars,
                'local_vars': local_vars,
                'file_handle': f,
                'file_path': file_path
            }
    
    def extract_map_data(self, map_path):
        """Extrai dados principais do mapa"""
        try:
            header = self.read_map_header(map_path)
            
            # Ler tamanho do mapa (isso precisa ser ajustado conforme o formato real)
            # Por enquanto, vamos criar uma estrutura básica
            
            map_data = {
                'name': header['name'],
                'version': header['version'],
                'file_name': map_path.name,
                'global_vars': header['global_vars'],
                'local_vars': header['local_vars'],
                'tiles': [],  # Será preenchido
                'objects': [],  # Será preenchido
                'scripts': []  # Será preenchido
            }
            
            # Nota: A leitura completa dos tiles e objetos requer análise mais profunda
            # do formato .MAP. Esta é uma versão simplificada.
            
            return map_data
            
        except Exception as e:
            print(f"❌ Erro ao ler mapa {map_path.name}: {e}")
            return None
    
    def create_godot_map_json(self, map_data):
        """Cria arquivo JSON compatível com Godot"""
        godot_map = {
            'name': map_data['name'],
            'version': map_data['version'],
            'global_vars': map_data['global_vars'],
            'local_vars': map_data['local_vars'],
            'tiles': map_data['tiles'],
            'objects': map_data['objects'],
            'scripts': map_data['scripts'],
            'godot_scene_path': f"res://scenes/maps/{map_data['name'].lower()}.tscn"
        }
        
        return godot_map
    
    def generate_godot_scene_template(self, map_data):
        """Gera template de cena do Godot em formato texto"""
        # Este é um template básico - você pode expandir conforme necessário
        scene_name = map_data['name'].lower().replace(' ', '_')
        
        template = f"""[gd_scene load_steps=2 format=3 uid="uid://{hash(map_data['name'])}"]

[ext_resource type="Script" path="res://scripts/core/map_base.gd" id="1"]

[node name="{map_data['name']}" type="Node2D"]
script = ExtResource("1")
map_name = "{map_data['name']}"
map_version = {map_data['version']}

[node name="Tiles" type="Node2D" parent="."]

[node name="Objects" type="Node2D" parent="."]

[node name="NPCs" type="Node2D" parent="."]

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(0, 0)
zoom = Vector2(2, 2)
"""
        
        return template
    
    def convert_map(self, map_path):
        """Converte um arquivo .MAP para formato do Godot"""
        try:
            map_data = self.extract_map_data(map_path)
            
            if not map_data:
                return False
            
            # Criar JSON de dados
            godot_map = self.create_godot_map_json(map_data)
            json_path = self.output_dir / "maps" / f"{map_data['name'].lower()}.json"
            json_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(json_path, 'w', encoding='utf-8') as f:
                json.dump(godot_map, f, indent=2, ensure_ascii=False)
            
            # Criar template de cena do Godot
            scene_template = self.generate_godot_scene_template(map_data)
            scene_path = self.output_dir / "godot_scenes" / f"{map_data['name'].lower()}.tscn"
            scene_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(scene_path, 'w', encoding='utf-8') as f:
                f.write(scene_template)
            
            print(f"✅ Convertido: {map_path.name} -> {json_path.name} + {scene_path.name}")
            return True
            
        except Exception as e:
            print(f"❌ Erro ao converter {map_path.name}: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def convert_directory(self):
        """Converte todos os arquivos .MAP em um diretório"""
        map_files = list(self.input_dir.rglob("*.MAP")) + list(self.input_dir.rglob("*.map"))
        
        if not map_files:
            print(f"❌ Nenhum arquivo .MAP encontrado em {self.input_dir}")
            return
        
        print(f"🔍 Encontrados {len(map_files)} arquivos .MAP")
        
        converted = 0
        failed = 0
        
        for map_file in map_files:
            if self.convert_map(map_file):
                converted += 1
            else:
                failed += 1
        
        print(f"\n📊 Conversão concluída:")
        print(f"  ✅ Convertidos: {converted}")
        print(f"  ❌ Falhas: {failed}")
        print(f"  📁 Output: {self.output_dir}")


def main():
    parser = argparse.ArgumentParser(description='Converte arquivos .MAP do Fallout 2 para formato do Godot')
    parser.add_argument('input_dir', help='Diretório com arquivos .MAP')
    parser.add_argument('output_dir', help='Diretório de saída para JSONs e cenas do Godot')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input_dir):
        print(f"❌ Diretório não encontrado: {args.input_dir}")
        sys.exit(1)
    
    converter = MapConverter(args.input_dir, args.output_dir)
    converter.convert_directory()


if __name__ == "__main__":
    main()

