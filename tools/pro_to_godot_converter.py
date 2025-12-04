"""
PRO to Godot Resource Converter - Conversor profissional de PRO para Resource do Godot.

Converte arquivos PRO do Fallout 2 diretamente para recursos (.tres) do Godot,
gerando ItemData, NPCData e TileData resources.

Requirements: 3.4
"""
import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

from extractors.dat2_reader import DAT2Manager
from extractors.pro_parser import parse_proto


class PROToGodotConverter:
    """
    Conversor profissional de PRO para Godot Resource.
    
    Converte protótipos do Fallout 2 diretamente para recursos .tres do Godot,
    gerando ItemData, NPCData e TileData resources.
    """
    
    def __init__(self, fallout2_path: str, output_dir: str,
                 godot_project_path: Optional[str] = None):
        """
        Inicializa o conversor.
        
        Args:
            fallout2_path: Caminho para a pasta do Fallout 2
            output_dir: Diretório de saída para recursos
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
        
        self.conversion_stats = {
            'total_protos': 0,
            'converted': 0,
            'failed': 0,
            'by_type': {
                'item': 0,
                'critter': 0,
                'scenery': 0,
                'wall': 0,
                'tile': 0,
                'misc': 0
            }
        }
    
    def convert_proto(self, proto_path: str, output_name: Optional[str] = None) -> Optional[str]:
        """
        Converte um único protótipo para recurso Godot.
        
        Args:
            proto_path: Caminho interno do PRO no DAT
            output_name: Nome do arquivo de saída (opcional)
            
        Returns:
            Caminho do arquivo .tres gerado ou None se falhar
        """
        try:
            # Ler e parsear PRO
            proto_data = self.dat_manager.get_file(proto_path)
            if not proto_data:
                return None
            
            parsed_proto = parse_proto(proto_data)
            if not parsed_proto:
                return None
            
            proto_type = parsed_proto.get('type', 'unknown')
            pid = parsed_proto.get('pid', 0)
            
            # Gerar nome de saída
            if not output_name:
                output_name = f"{proto_type}_{pid:08x}"
            
            # Gerar conteúdo do recurso baseado no tipo
            if proto_type == 'item':
                tres_content = self._generate_item_resource(parsed_proto)
                subdir = "items"
            elif proto_type == 'critter':
                tres_content = self._generate_critter_resource(parsed_proto)
                subdir = "critters"
            elif proto_type == 'tile':
                tres_content = self._generate_tile_resource(parsed_proto)
                subdir = "tiles"
            else:
                # Outros tipos (scenery, wall, misc)
                tres_content = self._generate_generic_resource(parsed_proto, proto_type)
                subdir = proto_type
            
            # Salvar arquivo
            output_file = self.output_dir / subdir / f"{output_name}.tres"
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(tres_content)
            
            self.conversion_stats['converted'] += 1
            self.conversion_stats['by_type'][proto_type] = self.conversion_stats['by_type'].get(proto_type, 0) + 1
            
            return str(output_file)
            
        except Exception as e:
            self.conversion_stats['failed'] += 1
            print(f"   ⚠️  Erro ao converter {proto_path}: {e}")
            return None
    
    def _generate_item_resource(self, proto: Dict[str, Any]) -> str:
        """
        Gera recurso ItemData para um item.
        
        Args:
            proto: Dados do protótipo parseados
            
        Returns:
            Conteúdo do arquivo .tres
        """
        lines = []
        lines.append('[gd_resource type="Resource" format=3]')
        lines.append('')
        lines.append('[resource]')
        lines.append('')
        
        # Dados básicos
        pid = proto.get('pid', 0)
        item_type = proto.get('item_type', 'misc')
        weight = proto.get('weight', 0)
        cost = proto.get('cost', 0)
        item_data = proto.get('item_data', {})
        
        # Criar estrutura de dados do item
        lines.append(f'pid = {pid}')
        lines.append(f'item_type = "{item_type}"')
        lines.append(f'weight = {weight}')
        lines.append(f'cost = {cost}')
        lines.append('')
        
        # Dados específicos por tipo
        if item_type == 'weapon':
            lines.append('# Weapon Data')
            lines.append(f'min_damage = {item_data.get("min_damage", 0)}')
            lines.append(f'max_damage = {item_data.get("max_damage", 0)}')
            lines.append(f'damage_type = {item_data.get("damage_type", 0)}')
            lines.append(f'action_point_cost1 = {item_data.get("action_point_cost1", 0)}')
            lines.append(f'action_point_cost2 = {item_data.get("action_point_cost2", 0)}')
            lines.append(f'min_strength = {item_data.get("min_strength", 0)}')
            lines.append(f'ammo_capacity = {item_data.get("ammo_capacity", 0)}')
        elif item_type == 'armor':
            lines.append('# Armor Data')
            lines.append(f'armor_class = {item_data.get("armor_class", 0)}')
            # TODO: Adicionar damage_resistance e damage_threshold
        elif item_type == 'drug':
            lines.append('# Drug Data')
            lines.append(f'stat = {item_data.get("stat", [])}')
            lines.append(f'amount = {item_data.get("amount", [])}')
            lines.append(f'duration1 = {item_data.get("duration1", 0)}')
        
        return '\n'.join(lines)
    
    def _generate_critter_resource(self, proto: Dict[str, Any]) -> str:
        """
        Gera recurso NPCData para uma criatura.
        
        Args:
            proto: Dados do protótipo parseados
            
        Returns:
            Conteúdo do arquivo .tres
        """
        lines = []
        lines.append('[gd_resource type="Resource" format=3]')
        lines.append('')
        lines.append('[resource]')
        lines.append('')
        
        # Dados básicos
        pid = proto.get('pid', 0)
        critter_data = proto.get('critter_data', {})
        base_stats = critter_data.get('base_stats', {})
        skills = critter_data.get('skills', {})
        
        lines.append(f'pid = {pid}')
        lines.append('')
        
        # Stats
        lines.append('# Base Stats')
        for stat_name, stat_value in base_stats.items():
            if stat_name in ['strength', 'perception', 'endurance', 'charisma', 'intelligence', 'agility', 'luck']:
                lines.append(f'{stat_name} = {stat_value}')
        
        lines.append('')
        lines.append('# Skills')
        for skill_name, skill_value in skills.items():
            lines.append(f'{skill_name} = {skill_value}')
        
        lines.append('')
        lines.append(f'experience = {critter_data.get("experience", 0)}')
        lines.append(f'body_type = {critter_data.get("body_type", 0)}')
        
        return '\n'.join(lines)
    
    def _generate_tile_resource(self, proto: Dict[str, Any]) -> str:
        """
        Gera recurso TileData para um tile.
        
        Args:
            proto: Dados do protótipo parseados
            
        Returns:
            Conteúdo do arquivo .tres
        """
        lines = []
        lines.append('[gd_resource type="Resource" format=3]')
        lines.append('')
        lines.append('[resource]')
        lines.append('')
        
        pid = proto.get('pid', 0)
        fid = proto.get('fid', 0)
        
        lines.append(f'pid = {pid}')
        lines.append(f'fid = {fid}')
        lines.append(f'flags = {proto.get("flags", 0)}')
        
        return '\n'.join(lines)
    
    def _generate_generic_resource(self, proto: Dict[str, Any], proto_type: str) -> str:
        """
        Gera recurso genérico para outros tipos.
        
        Args:
            proto: Dados do protótipo parseados
            proto_type: Tipo do protótipo
            
        Returns:
            Conteúdo do arquivo .tres
        """
        lines = []
        lines.append('[gd_resource type="Resource" format=3]')
        lines.append('')
        lines.append('[resource]')
        lines.append('')
        
        pid = proto.get('pid', 0)
        fid = proto.get('fid', 0)
        
        lines.append(f'pid = {pid}')
        lines.append(f'fid = {fid}')
        lines.append(f'type = "{proto_type}"')
        lines.append(f'flags = {proto.get("flags", 0)}')
        
        return '\n'.join(lines)
    
    def convert_all_protos(self, category: Optional[str] = None) -> Dict[str, Any]:
        """
        Converte todos os protótipos encontrados.
        
        Args:
            category: Categoria específica (items, critters, tiles) ou None para todas
            
        Returns:
            Estatísticas da conversão
        """
        print("📋 Convertendo protótipos para recursos Godot...")
        
        # Encontrar arquivos PRO
        all_files = self.dat_manager.list_all_files()
        
        if category and category in ['items', 'critters', 'tiles']:
            pro_files = [
                f for f in all_files 
                if f.lower().endswith('.pro') and f'proto\\{category}' in f.lower()
            ]
        else:
            pro_files = [f for f in all_files if f.lower().endswith('.pro')]
        
        self.conversion_stats['total_protos'] = len(pro_files)
        print(f"   Encontrados {len(pro_files)} protótipos")
        
        converted_files = []
        
        # Limitar a uma amostra para teste
        sample_size = min(500, len(pro_files))
        for i, proto_path in enumerate(pro_files[:sample_size], 1):
            try:
                output_file = self.convert_proto(proto_path)
                if output_file:
                    converted_files.append(output_file)
                
                if i % 50 == 0:
                    print(f"   Processados {i}/{sample_size} protótipos...")
            except Exception as e:
                print(f"   ⚠️  Erro ao processar {proto_path}: {e}")
        
        print(f"✅ {self.conversion_stats['converted']}/{sample_size} protótipos convertidos")
        
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
        print(f"\n📊 Estatísticas por tipo:")
        for proto_type, count in self.conversion_stats['by_type'].items():
            if count > 0:
                print(f"   {proto_type}: {count}")


def main():
    """Função principal."""
    import sys
    
    if len(sys.argv) < 3:
        print("Uso: python pro_to_godot_converter.py <fallout2_path> <output_dir> [godot_project_path] [category]")
        print("     category: items, critters, tiles (opcional)")
        return
    
    fallout2_path = sys.argv[1]
    output_dir = sys.argv[2]
    godot_project_path = sys.argv[3] if len(sys.argv) > 3 and not sys.argv[3] in ['items', 'critters', 'tiles'] else None
    category = sys.argv[4] if len(sys.argv) > 4 else (sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] in ['items', 'critters', 'tiles'] else None)
    
    print("=" * 70)
    print("📋 Conversor PRO → Godot Resource")
    print("=" * 70)
    print(f"📁 Fallout 2: {fallout2_path}")
    print(f"📁 Saída: {output_dir}")
    if godot_project_path:
        print(f"📁 Projeto Godot: {godot_project_path}")
    if category:
        print(f"📁 Categoria: {category}")
    print()
    
    converter = PROToGodotConverter(fallout2_path, output_dir, godot_project_path)
    converter.convert_all_protos(category)
    converter.generate_report()
    
    print("\n✅ Conversão completa!")


if __name__ == "__main__":
    main()

