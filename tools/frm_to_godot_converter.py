"""
FRM to Godot Converter - Conversor profissional de FRM para SpriteFrames do Godot.

Converte arquivos FRM do Fallout 2 diretamente para SpriteFrames (.tres) do Godot,
gerando também os PNGs necessários.

Requirements: 3.4
"""
import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

from extractors.dat2_reader import DAT2Manager
from extractors.frm_decoder import FRMDecoder, FRMImage
from extractors.palette_loader import PaletteLoader
from extractors.spriteframes_generator import SpriteFramesGenerator


class FRMToGodotConverter:
    """
    Conversor profissional de FRM para Godot SpriteFrames.
    
    Converte arquivos FRM diretamente para o formato nativo do Godot,
    gerando PNGs e arquivos .tres de SpriteFrames.
    """
    
    def __init__(self, fallout2_path: str, output_dir: str, 
                 godot_project_path: Optional[str] = None):
        """
        Inicializa o conversor.
        
        Args:
            fallout2_path: Caminho para a pasta do Fallout 2
            output_dir: Diretório de saída para PNGs e .tres
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
        self.palette_loader = PaletteLoader()
        self.frm_decoder = FRMDecoder(self.palette_loader)
        
        # Configurar caminho base dos assets no Godot
        if self.godot_project_path:
            assets_base = f"res://assets"
        else:
            assets_base = "res://assets"
        
        self.spriteframes_generator = SpriteFramesGenerator(
            str(self.output_dir / "spriteframes"),
            assets_base
        )
        
        self.conversion_stats = {
            'total_frms': 0,
            'converted': 0,
            'failed': 0,
            'pngs_generated': 0,
            'tres_generated': 0
        }
    
    def convert_all_character_animations(self) -> Dict[str, Any]:
        """
        Converte todas as animações de personagens.
        
        Returns:
            Estatísticas da conversão
        """
        print("🎭 Convertendo animações de personagens...")
        
        # Encontrar FRMs de criaturas
        all_files = self.dat_manager.list_all_files()
        critter_frms = [
            f for f in all_files 
            if ('art/critters' in f.lower() or 'art\\critters' in f.lower()) and f.lower().endswith('.frm')
        ]
        
        print(f"   Encontrados {len(critter_frms)} FRMs de criaturas")
        
        for i, frm_path in enumerate(critter_frms[:100], 1):  # Limitar a 100 para teste
            try:
                self._convert_single_frm(frm_path, "critters")
                self.conversion_stats['converted'] += 1
                
                if i % 10 == 0:
                    print(f"   Processados {i}/{min(100, len(critter_frms))}...")
            except Exception as e:
                self.conversion_stats['failed'] += 1
                print(f"   ⚠️  Erro ao converter {frm_path}: {e}")
        
        self.conversion_stats['total_frms'] = len(critter_frms)
        return self.conversion_stats
    
    def convert_all_item_sprites(self) -> Dict[str, Any]:
        """
        Converte todos os sprites de itens.
        
        Returns:
            Estatísticas da conversão
        """
        print("📦 Convertendo sprites de itens...")
        
        # Encontrar FRMs de itens
        all_files = self.dat_manager.list_all_files()
        item_frms = [
            f for f in all_files 
            if ('art/items' in f.lower() or 'art\\items' in f.lower()) and f.lower().endswith('.frm')
        ]
        
        print(f"   Encontrados {len(item_frms)} FRMs de itens")
        
        for i, frm_path in enumerate(item_frms[:200], 1):  # Limitar a 200
            try:
                self._convert_single_frm(frm_path, "items")
                self.conversion_stats['converted'] += 1
                
                if i % 20 == 0:
                    print(f"   Processados {i}/{min(200, len(item_frms))}...")
            except Exception as e:
                self.conversion_stats['failed'] += 1
                print(f"   ⚠️  Erro ao converter {frm_path}: {e}")
        
        self.conversion_stats['total_frms'] += len(item_frms)
        return self.conversion_stats
    
    def convert_all_tiles(self) -> Dict[str, Any]:
        """
        Converte todos os tiles.
        
        Returns:
            Estatísticas da conversão
        """
        print("🧱 Convertendo tiles...")
        
        # Encontrar FRMs de tiles
        all_files = self.dat_manager.list_all_files()
        tile_frms = [
            f for f in all_files 
            if ('art/tiles' in f.lower() or 'art\\tiles' in f.lower()) and f.lower().endswith('.frm')
        ]
        
        print(f"   Encontrados {len(tile_frms)} FRMs de tiles")
        
        for i, frm_path in enumerate(tile_frms[:100], 1):  # Limitar a 100
            try:
                self._convert_single_frm(frm_path, "tiles")
                self.conversion_stats['converted'] += 1
                
                if i % 10 == 0:
                    print(f"   Processados {i}/{min(100, len(tile_frms))}...")
            except Exception as e:
                self.conversion_stats['failed'] += 1
                print(f"   ⚠️  Erro ao converter {frm_path}: {e}")
        
        self.conversion_stats['total_frms'] += len(tile_frms)
        return self.conversion_stats
    
    def _convert_single_frm(self, frm_path: str, category: str):
        """
        Converte um único arquivo FRM.
        
        Args:
            frm_path: Caminho interno do FRM
            category: Categoria (critters, items, tiles)
        """
        # Ler FRM
        frm_data = self.dat_manager.get_file(frm_path)
        if not frm_data:
            raise ValueError(f"Arquivo não encontrado: {frm_path}")
        
        # Decodificar
        frm_image = self.frm_decoder.decode(frm_data)
        
        # Extrair nome base
        frm_name = Path(frm_path).stem
        output_base = self.output_dir / category / frm_name
        output_base.mkdir(parents=True, exist_ok=True)
        
        # Converter para PNGs
        png_paths = []
        for direction in range(frm_image.num_directions):
            if direction >= len(frm_image.frames) or not frm_image.frames[direction]:
                continue
            
            direction_name = self.frm_decoder.DIRECTION_NAMES[direction]
            
            # Se tem múltiplos frames, criar spritesheet
            if frm_image.num_frames > 1:
                spritesheet_path = output_base / f"{frm_name}_{direction_name}.png"
                self.frm_decoder.to_spritesheet(frm_image, str(spritesheet_path), direction)
                png_paths.append(str(spritesheet_path))
                self.conversion_stats['pngs_generated'] += 1
            else:
                # Frame único
                frame_path = output_base / f"{frm_name}_{direction_name}_frame000.png"
                self.frm_decoder.to_png(frm_image, str(frame_path), direction, 0)
                png_paths.append(str(frame_path))
                self.conversion_stats['pngs_generated'] += 1
        
        # Gerar SpriteFrames se aplicável (apenas para criaturas com animações)
        if category == "critters" and frm_image.num_frames > 1:
            self._generate_spriteframes(frm_name, frm_image, png_paths, category)
    
    def _generate_spriteframes(self, name: str, frm_image: FRMImage, 
                               png_paths: List[str], category: str):
        """
        Gera arquivo SpriteFrames para uma criatura.
        
        Args:
            name: Nome da criatura
            frm_image: Imagem FRM decodificada
            png_paths: Lista de caminhos dos PNGs
            category: Categoria
        """
        # Organizar frames por direção
        frames_by_dir = {}
        for i, png_path in enumerate(png_paths):
            # Extrair direção do nome do arquivo
            for dir_idx, dir_name in enumerate(self.frm_decoder.DIRECTION_NAMES):
                if f"_{dir_name}" in png_path:
                    if dir_name not in frames_by_dir:
                        frames_by_dir[dir_name] = []
                    frames_by_dir[dir_name].append(png_path)
                    break
        
        # Gerar SpriteFrames
        if frames_by_dir:
            # Construir caminhos relativos ao Godot
            godot_paths = {}
            for dir_name, paths in frames_by_dir.items():
                godot_paths[dir_name] = [
                    f"res://assets/{category}/{name}/{Path(p).name}" 
                    for p in paths
                ]
            
            # Gerar .tres
            tres_content = self.spriteframes_generator.generate_simple_tres(
                name,
                "idle",  # Tipo de animação padrão
                list(godot_paths.values())[0] if godot_paths else [],
                fps=frm_image.fps if frm_image.fps > 0 else 10.0,
                loop=True
            )
            
            # Salvar .tres
            tres_path = self.output_dir / "spriteframes" / f"{name}.tres"
            tres_path.parent.mkdir(parents=True, exist_ok=True)
            with open(tres_path, 'w', encoding='utf-8') as f:
                f.write(tres_content)
            
            self.conversion_stats['tres_generated'] += 1
    
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
        print(f"\n📊 Estatísticas:")
        print(f"   Total FRMs: {self.conversion_stats['total_frms']}")
        print(f"   Convertidos: {self.conversion_stats['converted']}")
        print(f"   Falhas: {self.conversion_stats['failed']}")
        print(f"   PNGs gerados: {self.conversion_stats['pngs_generated']}")
        print(f"   SpriteFrames gerados: {self.conversion_stats['tres_generated']}")


def main():
    """Função principal."""
    import sys
    
    if len(sys.argv) < 3:
        print("Uso: python frm_to_godot_converter.py <fallout2_path> <output_dir> [godot_project_path]")
        return
    
    fallout2_path = sys.argv[1]
    output_dir = sys.argv[2]
    godot_project_path = sys.argv[3] if len(sys.argv) > 3 else None
    
    print("=" * 70)
    print("🎨 Conversor FRM → Godot SpriteFrames")
    print("=" * 70)
    print(f"📁 Fallout 2: {fallout2_path}")
    print(f"📁 Saída: {output_dir}")
    if godot_project_path:
        print(f"📁 Projeto Godot: {godot_project_path}")
    print()
    
    converter = FRMToGodotConverter(fallout2_path, output_dir, godot_project_path)
    
    # Converter tudo
    converter.convert_all_character_animations()
    converter.convert_all_item_sprites()
    converter.convert_all_tiles()
    
    # Gerar relatório
    converter.generate_report()
    
    print("\n✅ Conversão completa!")


if __name__ == "__main__":
    main()

