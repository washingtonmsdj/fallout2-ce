"""
Testes para o módulo tile_extractor.

Inclui testes unitários e property-based tests usando Hypothesis.
"""
import pytest
import struct
import tempfile
import shutil
from pathlib import Path
from hypothesis import given, strategies as st, settings

from tools.extractors.tile_extractor import TileExtractor, TileMetadata
from tools.extractors.frm_decoder import FRMDecoder
from tools.extractors.palette_loader import PaletteLoader


def create_test_frm(width: int = 80, height: int = 36, pixels: bytes = None) -> bytes:
    """Cria um arquivo FRM sintético para testes de tiles."""
    if pixels is None:
        pixels = bytes([i % 256 for i in range(width * height)])
    
    pixel_padding = (4 - len(pixels) % 4) % 4
    
    # Frame data
    frame_data = b''
    frame_data += struct.pack('>h', width)
    frame_data += struct.pack('>h', height)
    frame_data += struct.pack('>I', len(pixels))
    frame_data += struct.pack('>h', 0)  # x_offset
    frame_data += struct.pack('>h', 0)  # y_offset
    frame_data += pixels
    frame_data += b'\x00' * pixel_padding
    
    # Direction offsets - apenas direção 0
    direction_offsets = [0, 0, 0, 0, 0, 0]
    
    # Header
    header = b''
    header += struct.pack('>I', 4)  # version
    header += struct.pack('>h', 10)  # fps
    header += struct.pack('>h', 0)  # action_frame
    header += struct.pack('>h', 1)  # frame_count
    for i in range(6):
        header += struct.pack('>h', 0)  # x_offsets
    for i in range(6):
        header += struct.pack('>h', 0)  # y_offsets
    for i in range(6):
        header += struct.pack('>I', direction_offsets[i])
    header += struct.pack('>I', len(frame_data))  # data_size
    
    header_padding = (4 - 62 % 4) % 4
    header += b'\x00' * header_padding
    
    return header + frame_data


class MockDAT2Manager:
    """Mock do DAT2Manager para testes."""
    
    def __init__(self, files: dict):
        self.files = files
    
    def get_file(self, path: str) -> bytes:
        return self.files.get(path)
    
    def list_all_files(self) -> list:
        return list(self.files.keys())


class TestTileExtractor:
    """Testes unitários para TileExtractor."""
    
    def test_identify_tile_type_floor(self):
        """Testa identificação de tipo floor."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = TileExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._identify_tile_type('art/tiles/floor001.frm') == 'floor'
            assert extractor._identify_tile_type('art/tiles/desert_tile.frm') == 'floor'
    
    def test_identify_tile_type_roof(self):
        """Testa identificação de tipo roof."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = TileExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._identify_tile_type('art/tiles/roof001.frm') == 'roof'
            assert extractor._identify_tile_type('art/tiles/ceiling.frm') == 'roof'
    
    def test_identify_tile_category(self):
        """Testa identificação de categoria."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = TileExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._identify_tile_category('art/tiles/desert_floor.frm') == 'desert'
            assert extractor._identify_tile_category('art/tiles/vault_tile.frm') == 'vault'
            assert extractor._identify_tile_category('art/tiles/city_street.frm') == 'city'


class TestTilePropertyTests:
    """Property-based tests para TileExtractor."""
    
    @given(
        num_tiles=st.integers(min_value=1, max_value=10)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_10_isometric_tile_dimensions(self, num_tiles):
        """
        **Feature: fallout2-asset-extraction, Property 10: Isometric Tile Dimensions**
        
        Para qualquer tile de chão extraído do jogo, o PNG resultante DEVE ter
        dimensões de exatamente 80x36 pixels.
        
        **Validates: Requirements 4.3**
        
        Nota: Este teste verifica que tiles criados com dimensões 80x36 são
        preservados corretamente durante a extração.
        """
        # Dimensões padrão de tiles isométricos do Fallout 2
        EXPECTED_WIDTH = 80
        EXPECTED_HEIGHT = 36
        
        # Criar tiles de teste com dimensões corretas
        files = {}
        for i in range(num_tiles):
            frm_path = f'art/tiles/floor_tile_{i:03d}.frm'
            frm_data = create_test_frm(width=EXPECTED_WIDTH, height=EXPECTED_HEIGHT)
            files[frm_path] = frm_data
        
        mock_dat = MockDAT2Manager(files)
        palette = PaletteLoader()
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = TileExtractor(mock_dat, palette, temp_dir)
            
            # Extrair todos os tiles
            results = extractor.extract_all_tiles()
            
            # Verificar que todos os tiles foram extraídos
            all_tiles = results['floor'] + results['roof']
            assert len(all_tiles) == num_tiles, \
                f"Esperado {num_tiles} tiles, extraídos {len(all_tiles)}"
            
            # Verificar dimensões de cada tile
            for tile in all_tiles:
                assert tile.width == EXPECTED_WIDTH, \
                    f"Tile {tile.name} tem largura incorreta: {tile.width} != {EXPECTED_WIDTH}"
                assert tile.height == EXPECTED_HEIGHT, \
                    f"Tile {tile.name} tem altura incorreta: {tile.height} != {EXPECTED_HEIGHT}"
    
    @given(
        width=st.integers(min_value=10, max_value=200),
        height=st.integers(min_value=10, max_value=200)
    )
    @settings(max_examples=50, deadline=None)
    def test_tile_dimension_preservation(self, width, height):
        """
        Testa que as dimensões dos tiles são preservadas durante a extração,
        independentemente do tamanho original.
        """
        # Criar tile com dimensões arbitrárias
        frm_data = create_test_frm(width=width, height=height)
        files = {'art/tiles/test_tile.frm': frm_data}
        
        mock_dat = MockDAT2Manager(files)
        palette = PaletteLoader()
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = TileExtractor(mock_dat, palette, temp_dir)
            
            # Extrair tile
            metadata = extractor.extract_tile('art/tiles/test_tile.frm')
            
            assert metadata is not None, "Falha ao extrair tile"
            assert metadata.width == width, \
                f"Largura incorreta: {metadata.width} != {width}"
            assert metadata.height == height, \
                f"Altura incorreta: {metadata.height} != {height}"
