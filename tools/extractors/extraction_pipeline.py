"""
Módulo principal de pipeline de extração de assets.

Este módulo orquestra todos os extratores em sequência e gera
relatórios finais com estatísticas.
"""
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass
from datetime import datetime
import time

from .dat2_reader import DAT2Manager
from .palette_loader import PaletteLoader
from .critter_extractor import CritterExtractor
from .tile_extractor import TileExtractor
from .ui_extractor import UIExtractor
from .acm_decoder import ACMDecoder
from .map_parser import MAPParser
from .msg_parser import MSGParser
from .asset_organizer import AssetOrganizer


@dataclass
class ExtractionError:
    """Erro ocorrido durante extração."""
    file_path: str
    error_type: str
    message: str
    timestamp: str
    recoverable: bool


@dataclass
class ExtractionReport:
    """Relatório final de extração."""
    total_files: int
    extracted_files: int
    failed_files: int
    errors: List[ExtractionError]
    manifest_path: str
    duration_seconds: float


class ExtractionPipeline:
    """
    Pipeline principal de extração de assets do Fallout 2.
    
    Orquestra todos os extratores em sequência e gera relatórios
    finais com estatísticas.
    """
    
    def __init__(self, fallout2_path: str, godot_path: str):
        """
        Inicializa o pipeline de extração.
        
        Args:
            fallout2_path: Caminho para instalação do Fallout 2
            godot_path: Caminho do projeto Godot
        """
        self.fallout2_path = Path(fallout2_path)
        self.godot_path = Path(godot_path)
        
        # Inicializar componentes
        self._init_components()
        
        # Estatísticas
        self.errors: List[ExtractionError] = []
        self.start_time: Optional[float] = None
    
    def _init_components(self):
        """Inicializa todos os componentes do pipeline."""
        # DAT2 Manager
        dat_files = []
        for dat_name in ['master.dat', 'critter.dat', 'patch000.dat']:
            dat_path = self.fallout2_path / dat_name
            if dat_path.exists():
                dat_files.append(str(dat_path))
        
        self.dat_manager = DAT2Manager(dat_files)
        
        # Palette
        palette_path = self.fallout2_path / 'color.pal'
        if palette_path.exists():
            self.palette = PaletteLoader(str(palette_path))
        else:
            self.palette = PaletteLoader()
        
        # Asset Organizer
        self.organizer = AssetOrganizer(str(self.godot_path))
        
        # Extratores
        output_dir = self.godot_path / 'assets' / 'temp'
        self.critter_extractor = CritterExtractor(
            self.dat_manager, self.palette, str(output_dir / 'critters')
        )
        self.tile_extractor = TileExtractor(
            self.dat_manager, self.palette, str(output_dir / 'tiles')
        )
        self.ui_extractor = UIExtractor(
            self.dat_manager, self.palette, str(output_dir / 'ui')
        )
        
        # Decoders
        self.acm_decoder = ACMDecoder()
        self.map_parser = MAPParser()
        self.msg_parser = MSGParser()
    
    def extract_all(self) -> ExtractionReport:
        """
        Extrai todos os assets do Fallout 2.
        
        Returns:
            Relatório de extração completo
        """
        self.start_time = time.time()
        
        print("=" * 60)
        print("Pipeline de Extração de Assets - Fallout 2")
        print("=" * 60)
        
        total_files = 0
        extracted_files = 0
        
        try:
            # Extrair sprites
            print("\n[1/4] Extraindo sprites...")
            sprites_count = self.extract_sprites()
            extracted_files += sprites_count
            total_files += sprites_count
            
            # Extrair áudio
            print("\n[2/4] Extraindo áudio...")
            audio_count = self.extract_audio()
            extracted_files += audio_count
            total_files += audio_count
            
            # Extrair mapas
            print("\n[3/4] Extraindo mapas...")
            maps_count = self.extract_maps()
            extracted_files += maps_count
            total_files += maps_count
            
            # Extrair textos
            print("\n[4/4] Extraindo textos...")
            texts_count = self.extract_texts()
            extracted_files += texts_count
            total_files += texts_count
            
        except Exception as e:
            self._log_error('pipeline', 'extraction', str(e), recoverable=False)
        
        # Gerar manifesto
        print("\n[Final] Gerando manifesto...")
        manifest_path = str(self.godot_path / 'assets' / 'manifest.json')
        self.organizer.save_manifest(manifest_path)
        
        # Calcular duração
        duration = time.time() - self.start_time if self.start_time else 0
        
        return ExtractionReport(
            total_files=total_files,
            extracted_files=extracted_files,
            failed_files=len(self.errors),
            errors=self.errors,
            manifest_path=manifest_path,
            duration_seconds=duration
        )
    
    def extract_sprites(self) -> int:
        """
        Extrai todos os sprites (criaturas, tiles, UI).
        
        Returns:
            Número de sprites extraídos
        """
        count = 0
        
        try:
            # Criaturas
            critters = self.critter_extractor.extract_all_critters()
            for critter_type, metadata_list in critters.items():
                count += len(metadata_list)
            
            # Tiles
            tiles = self.tile_extractor.extract_all_tiles()
            for tile_type, metadata_list in tiles.items():
                count += len(metadata_list)
            
            # UI
            ui_elements = self.ui_extractor.extract_all_ui()
            for ui_type, metadata_list in ui_elements.items():
                count += len(metadata_list)
                
        except Exception as e:
            self._log_error('sprites', 'extraction', str(e), recoverable=True)
        
        return count
    
    def extract_audio(self) -> int:
        """
        Extrai todos os arquivos de áudio.
        
        Returns:
            Número de arquivos de áudio extraídos
        """
        count = 0
        
        try:
            all_files = self.dat_manager.list_all_files()
            acm_files = [f for f in all_files if f.lower().endswith('.acm')]
            
            for acm_path in acm_files:
                try:
                    acm_data = self.dat_manager.get_file(acm_path)
                    if acm_data:
                        output_path = self.acm_decoder.organize_audio(
                            acm_path, str(self.godot_path / 'assets'), None
                        )
                        if self.acm_decoder.convert_to_ogg(acm_data, output_path):
                            count += 1
                except Exception as e:
                    self._log_error(acm_path, 'audio', str(e), recoverable=True)
                    
        except Exception as e:
            self._log_error('audio', 'extraction', str(e), recoverable=True)
        
        return count
    
    def extract_maps(self) -> int:
        """
        Extrai todos os mapas.
        
        Returns:
            Número de mapas extraídos
        """
        count = 0
        
        try:
            all_files = self.dat_manager.list_all_files()
            map_files = [f for f in all_files if f.lower().endswith('.map')]
            
            for map_path in map_files:
                try:
                    map_data = self.dat_manager.get_file(map_path)
                    if map_data:
                        parsed_map = self.map_parser.parse(map_data)
                        
                        output_name = Path(map_path).stem + '.json'
                        output_path = str(self.godot_path / 'assets' / 'data' / 'maps' / output_name)
                        
                        self.map_parser.to_json(parsed_map, output_path)
                        count += 1
                except Exception as e:
                    self._log_error(map_path, 'map', str(e), recoverable=True)
                    
        except Exception as e:
            self._log_error('maps', 'extraction', str(e), recoverable=True)
        
        return count
    
    def extract_texts(self) -> int:
        """
        Extrai todos os textos/mensagens.
        
        Returns:
            Número de arquivos de texto extraídos
        """
        count = 0
        
        try:
            all_files = self.dat_manager.list_all_files()
            msg_files = [f for f in all_files if f.lower().endswith('.msg')]
            
            for msg_path in msg_files:
                try:
                    msg_data = self.dat_manager.get_file(msg_path)
                    if msg_data:
                        messages = self.msg_parser.parse(msg_data)
                        
                        output_name = Path(msg_path).stem + '.json'
                        output_path = str(self.godot_path / 'assets' / 'data' / 'messages' / output_name)
                        
                        self.msg_parser.to_json(messages, output_path)
                        count += 1
                except Exception as e:
                    self._log_error(msg_path, 'message', str(e), recoverable=True)
                    
        except Exception as e:
            self._log_error('texts', 'extraction', str(e), recoverable=True)
        
        return count
    
    def _log_error(self, file_path: str, error_type: str, message: str, recoverable: bool = True):
        """Registra um erro."""
        error = ExtractionError(
            file_path=file_path,
            error_type=error_type,
            message=message,
            timestamp=datetime.now().isoformat(),
            recoverable=recoverable
        )
        self.errors.append(error)
        self.organizer.log_error(file_path, error_type, message)
    
    def close(self):
        """Fecha todos os recursos."""
        self.dat_manager.close()

