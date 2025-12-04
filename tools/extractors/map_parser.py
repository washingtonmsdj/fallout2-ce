"""
Módulo para parsing de arquivos MAP do Fallout 2.

Este módulo implementa o MAPParser que lê arquivos de mapa, extrai
tiles, objetos e scripts, exportando em formato JSON.
"""
import struct
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict


@dataclass
class MapObject:
    """Objeto em um mapa."""
    pid: int
    position: Tuple[int, int]
    level: int
    orientation: int
    script_id: int


@dataclass
class MapData:
    """Dados completos de um mapa."""
    version: int
    name: str
    width: int
    height: int
    num_levels: int
    tiles: List[List[int]]  # [level][tile_index]
    objects: List[MapObject]
    scripts: List[str]
    entering_tile: int
    entering_elevation: int
    entering_rotation: int
    script_index: int
    flags: int
    darkness: int
    global_variables_count: int
    local_variables_count: int


class MAPParser:
    """
    Parser de arquivos MAP do Fallout 2.
    
    Lê arquivos de mapa, extrai informações de tiles, objetos e scripts,
    exportando em formato JSON legível para importação no Godot.
    """
    
    # Tamanho do grid de tiles (geralmente 200x200)
    DEFAULT_MAP_SIZE = 200
    
    def __init__(self):
        """Inicializa o parser de mapas."""
        pass
    
    def parse(self, map_data: bytes) -> MapData:
        """
        Parseia dados de um arquivo MAP.
        
        Args:
            map_data: Dados binários do arquivo MAP
            
        Returns:
            MapData com todas as informações do mapa
        """
        offset = 0
        
        # Ler header
        version = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        
        # Nome do mapa (16 bytes)
        name_bytes = map_data[offset:offset+16]
        # Remover caracteres nulos antes de decodificar
        name_bytes_clean = name_bytes.split(b'\x00')[0]
        name = name_bytes_clean.decode('latin-1', errors='ignore').strip()
        if not name:
            name = f"map_{version}"
        offset += 16
        
        # Entrada
        entering_tile = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        entering_elevation = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        entering_rotation = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        
        # Variáveis
        local_variables_count = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        script_index = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        flags = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        darkness = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        global_variables_count = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        
        # Índice do mapa
        map_index = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        
        # Last visit time
        last_visit_time = struct.unpack('<I', map_data[offset:offset+4])[0]
        offset += 4
        
        # Pular campos reservados (44 * 4 bytes)
        offset += 44 * 4
        
        # Por enquanto, usar valores padrão para dimensões
        # A leitura completa de tiles requer análise mais profunda
        width = self.DEFAULT_MAP_SIZE
        height = self.DEFAULT_MAP_SIZE
        num_levels = 3  # Geralmente 3 níveis (chão, meio, teto)
        
        # Ler tiles (estrutura simplificada)
        # Nota: A estrutura completa de tiles é complexa e varia por versão
        tiles: List[List[int]] = []
        for level in range(num_levels):
            level_tiles = []
            # Por enquanto, criar array vazio
            # Implementação completa requereria parsing detalhado de src/map.cc
            tiles.append(level_tiles)
        
        # Ler objetos (estrutura simplificada)
        objects: List[MapObject] = []
        # Nota: Parsing completo de objetos requer análise de src/map.cc
        
        # Scripts (referências)
        scripts: List[str] = []
        if script_index > 0:
            scripts.append(f"script_{script_index}.int")
        
        return MapData(
            version=version,
            name=name,
            width=width,
            height=height,
            num_levels=num_levels,
            tiles=tiles,
            objects=objects,
            scripts=scripts,
            entering_tile=entering_tile,
            entering_elevation=entering_elevation,
            entering_rotation=entering_rotation,
            script_index=script_index,
            flags=flags,
            darkness=darkness,
            global_variables_count=global_variables_count,
            local_variables_count=local_variables_count
        )
    
    def to_json(self, map_data: MapData, output_path: str):
        """
        Exporta dados do mapa para JSON.
        
        Args:
            map_data: Dados do mapa parseados
            output_path: Caminho do arquivo JSON de saída
        """
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Converter para formato serializável
        output_dict = {
            'version': map_data.version,
            'name': map_data.name,
            'width': map_data.width,
            'height': map_data.height,
            'num_levels': map_data.num_levels,
            'tiles': map_data.tiles,
            'objects': [asdict(obj) for obj in map_data.objects],
            'scripts': map_data.scripts,
            'entering': {
                'tile': map_data.entering_tile,
                'elevation': map_data.entering_elevation,
                'rotation': map_data.entering_rotation
            },
            'script_index': map_data.script_index,
            'flags': map_data.flags,
            'darkness': map_data.darkness,
            'variables': {
                'global_count': map_data.global_variables_count,
                'local_count': map_data.local_variables_count
            }
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output_dict, f, indent=2, ensure_ascii=False)
    
    def get_tiles(self, map_data: MapData) -> List[List[int]]:
        """
        Obtém array de tiles do mapa.
        
        Args:
            map_data: Dados do mapa
            
        Returns:
            Lista de tiles por nível
        """
        return map_data.tiles
    
    def get_objects(self, map_data: MapData) -> List[MapObject]:
        """
        Obtém lista de objetos do mapa.
        
        Args:
            map_data: Dados do mapa
            
        Returns:
            Lista de objetos
        """
        return map_data.objects

