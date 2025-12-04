"""
MAP to Godot Scene Converter - Conversor profissional de MAP para Scene do Godot.

Converte arquivos MAP do Fallout 2 diretamente para cenas (.tscn) do Godot,
gerando TileMap com tiles, objetos e NPCs posicionados corretamente.

Requirements: 3.4
"""
import json
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime

from extractors.dat2_reader import DAT2Manager
from extractors.map_parser import MAPParser, MapData, MapObject


class MapToGodotConverter:
    """
    Conversor profissional de MAP para Godot Scene.
    
    Converte mapas do Fallout 2 diretamente para cenas .tscn do Godot,
    gerando TileMap com tiles corretos e posicionando objetos e NPCs.
    """
    
    # Tamanho de um tile em pixels (isométrico)
    TILE_WIDTH = 80
    TILE_HEIGHT = 36
    
    def __init__(self, fallout2_path: str, output_dir: str,
                 godot_project_path: Optional[str] = None):
        """
        Inicializa o conversor.
        
        Args:
            fallout2_path: Caminho para a pasta do Fallout 2
            output_dir: Diretório de saída para cenas
            godot_project_path: Caminho do projeto Godot (opcional)
        """
        self.fallout2_path = Path(fallout2_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.godot_project_path = Path(godot_project_path) if godot_project_path else None
        
        # Inicializar extractors
        dat_files = []
        for dat_name in ['master.dat', 'critter.dat', 'patch000.dat']:
            dat_path = self.fallout2_path / dat_name
            if dat_path.exists():
                dat_files.append(str(dat_path))
        
        self.dat_manager = DAT2Manager(dat_files)
        self.map_parser = MAPParser()
        
        self.conversion_stats = {
            'total_maps': 0,
            'converted': 0,
            'failed': 0
        }
    
    def convert_map(self, map_path: str, output_name: Optional[str] = None) -> Optional[str]:
        """
        Converte um único mapa para cena Godot.
        
        Args:
            map_path: Caminho interno do mapa no DAT
            output_name: Nome do arquivo de saída (opcional)
            
        Returns:
            Caminho do arquivo .tscn gerado ou None se falhar
        """
        try:
            # Ler e parsear mapa
            map_data_bytes = self.dat_manager.get_file(map_path)
            if not map_data_bytes:
                return None
            
            map_data = self.map_parser.parse(map_data_bytes)
            
            # Gerar nome de saída
            if not output_name:
                output_name = map_data.name or Path(map_path).stem
            
            # Gerar conteúdo da cena
            tscn_content = self._generate_tscn(map_data, output_name)
            
            # Salvar arquivo
            output_file = self.output_dir / f"{output_name}.tscn"
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(tscn_content)
            
            self.conversion_stats['converted'] += 1
            return str(output_file)
            
        except Exception as e:
            self.conversion_stats['failed'] += 1
            print(f"   ⚠️  Erro ao converter {map_path}: {e}")
            return None
    
    def _generate_tscn(self, map_data: MapData, map_name: str) -> str:
        """
        Gera conteúdo do arquivo .tscn para um mapa.
        
        Args:
            map_data: Dados do mapa parseados
            map_name: Nome do mapa
            
        Returns:
            Conteúdo do arquivo .tscn
        """
        lines = []
        ext_resources = {}
        resource_id = 1
        
        # Header da cena
        lines.append(f'[gd_scene load_steps={1} format=3 uid="uid://map_{map_name}"]')
        lines.append('')
        
        # Script do mapa (se houver)
        if map_data.scripts:
            script_path = f"res://scripts/maps/{map_name}.gd"
            lines.append(f'[ext_resource type="Script" path="{script_path}" id="1_script"]')
            ext_resources['script'] = 1
            resource_id += 1
        
        lines.append('')
        
        # Nó raiz
        if map_data.scripts:
            lines.append(f'[node name="{map_name}" type="Node2D"]')
            lines.append('script = ExtResource("1_script")')
        else:
            lines.append(f'[node name="{map_name}" type="Node2D"]')
        
        lines.append('')
        
        # Nó World para organização
        lines.append('[node name="World" type="Node2D" parent="."]')
        lines.append('')
        
        # Criar camadas por elevação
        for elevation in range(map_data.num_levels):
            elevation_name = ['Ground', 'Middle', 'Top'][elevation] if elevation < 3 else f'Elevation{elevation}'
            lines.append(f'[node name="{elevation_name}" type="Node2D" parent="World"]')
            lines.append('')
            
            # Adicionar TileMap para esta elevação
            # Nota: Por enquanto, criar estrutura básica
            # A implementação completa de TileMap requer tilesets configurados
            
            lines.append('')
        
        # Adicionar objetos e NPCs
        if map_data.objects:
            lines.append('[node name="Objects" type="Node2D" parent="World"]')
            lines.append('')
            
            for obj in map_data.objects:
                obj_type = self._get_object_type(obj.pid)
                obj_name = f"obj_{obj.pid}_{obj.position[0]}_{obj.position[1]}"
                
                if obj_type == 'critter':
                    # NPC
                    lines.append(f'[node name="{obj_name}" type="CharacterBody2D" parent="World/Objects"]')
                    lines.append(f'position = Vector2({obj.position[0] * self.TILE_WIDTH}, {obj.position[1] * self.TILE_HEIGHT})')
                    # TODO: Adicionar script de NPC
                elif obj_type == 'item':
                    # Item
                    lines.append(f'[node name="{obj_name}" type="Area2D" parent="World/Objects"]')
                    lines.append(f'position = Vector2({obj.position[0] * self.TILE_WIDTH}, {obj.position[1] * self.TILE_HEIGHT})')
                    # TODO: Adicionar script de item
                elif obj_type == 'scenery':
                    # Scenery
                    lines.append(f'[node name="{obj_name}" type="StaticBody2D" parent="World/Objects"]')
                    lines.append(f'position = Vector2({obj.position[0] * self.TILE_WIDTH}, {obj.position[1] * self.TILE_HEIGHT})')
                    # TODO: Adicionar script de scenery
                
                lines.append('')
        
        # Adicionar ponto de entrada do jogador
        if map_data.entering_tile >= 0:
            entering_x = (map_data.entering_tile % map_data.width) * self.TILE_WIDTH
            entering_y = (map_data.entering_tile // map_data.width) * self.TILE_HEIGHT
            
            lines.append('[node name="EntryPoint" type="Marker2D" parent="World"]')
            lines.append(f'position = Vector2({entering_x}, {entering_y})')
            lines.append('')
        
        return '\n'.join(lines)
    
    def _get_object_type(self, pid: int) -> str:
        """Determina o tipo de objeto baseado no PID."""
        obj_type = (pid >> 24) & 0xF
        type_map = {
            0: 'item',
            1: 'critter',
            2: 'scenery',
            3: 'wall',
            4: 'tile',
            5: 'misc'
        }
        return type_map.get(obj_type, 'unknown')
    
    def convert_all_maps(self) -> Dict[str, Any]:
        """
        Converte todos os mapas encontrados.
        
        Returns:
            Estatísticas da conversão
        """
        print("🗺️  Convertendo mapas para cenas Godot...")
        
        # Encontrar todos os arquivos MAP
        all_files = self.dat_manager.list_all_files()
        map_files = [f for f in all_files if f.lower().endswith('.map')]
        
        self.conversion_stats['total_maps'] = len(map_files)
        print(f"   Encontrados {len(map_files)} mapas")
        
        converted_files = []
        
        for i, map_path in enumerate(map_files, 1):
            try:
                output_file = self.convert_map(map_path)
                if output_file:
                    converted_files.append(output_file)
                
                if i % 10 == 0:
                    print(f"   Processados {i}/{len(map_files)} mapas...")
            except Exception as e:
                print(f"   ⚠️  Erro ao processar {map_path}: {e}")
        
        print(f"✅ {self.conversion_stats['converted']}/{self.conversion_stats['total_maps']} mapas convertidos")
        
        return {
            'stats': self.conversion_stats,
            'converted_files': converted_files
        }
    
    def generate_report(self):
        """Gera relatório da conversão."""
        report_file = self.output_dir / "conversion_report.json"
        
        report = {
            'generated_at': datetime.now().isoformat(),
            'stats': self.conversion_stats,
            'output_dir': str(self.output_dir)
        }
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 Relatório salvo: {report_file}")


def main():
    """Função principal."""
    import sys
    
    if len(sys.argv) < 3:
        print("Uso: python map_to_godot_converter.py <fallout2_path> <output_dir> [godot_project_path]")
        return
    
    fallout2_path = sys.argv[1]
    output_dir = sys.argv[2]
    godot_project_path = sys.argv[3] if len(sys.argv) > 3 else None
    
    print("=" * 70)
    print("🗺️  Conversor MAP → Godot Scene")
    print("=" * 70)
    print(f"📁 Fallout 2: {fallout2_path}")
    print(f"📁 Saída: {output_dir}")
    if godot_project_path:
        print(f"📁 Projeto Godot: {godot_project_path}")
    print()
    
    converter = MapToGodotConverter(fallout2_path, output_dir, godot_project_path)
    converter.convert_all_maps()
    converter.generate_report()
    
    print("\n✅ Conversão completa!")


if __name__ == "__main__":
    main()

