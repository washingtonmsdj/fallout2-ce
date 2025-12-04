"""
Testes para o módulo critter_extractor.

Inclui testes unitários e property-based tests usando Hypothesis.
"""
import pytest
import struct
import json
import tempfile
import shutil
from pathlib import Path
from hypothesis import given, strategies as st, settings, assume
from dataclasses import asdict

from tools.extractors.critter_extractor import CritterExtractor, CritterMetadata, CritterAnimation
from tools.extractors.frm_decoder import FRMDecoder, FRMImage, Frame
from tools.extractors.palette_loader import PaletteLoader


def create_test_frm(
    width: int = 10,
    height: int = 10,
    num_frames: int = 1,
    num_directions: int = 1,
    pixels: bytes = None,
    fps: int = 10,
    offset_x: int = 0,
    offset_y: int = 0
) -> bytes:
    """Cria um arquivo FRM sintético para testes."""
    if pixels is None:
        pixels = bytes([i % 256 for i in range(width * height)])
    
    pixel_padding = (4 - len(pixels) % 4) % 4
    frame_data = b''
    direction_offsets = []
    
    for direction in range(6):
        if direction < num_directions:
            direction_offsets.append(len(frame_data))
            for frame_idx in range(num_frames):
                frame_data += struct.pack('>h', width)
                frame_data += struct.pack('>h', height)
                frame_data += struct.pack('>I', len(pixels))
                frame_data += struct.pack('>h', offset_x)
                frame_data += struct.pack('>h', offset_y)
                frame_data += pixels
                frame_data += b'\x00' * pixel_padding
        else:
            direction_offsets.append(direction_offsets[-1] if direction_offsets else 0)
    
    header = b''
    header += struct.pack('>I', 4)
    header += struct.pack('>h', fps)
    header += struct.pack('>h', 0)
    header += struct.pack('>h', num_frames)
    for i in range(6):
        header += struct.pack('>h', 0)
    for i in range(6):
        header += struct.pack('>h', 0)
    for i in range(6):
        header += struct.pack('>I', direction_offsets[i])
    header += struct.pack('>I', len(frame_data))
    
    header_padding = (4 - 62 % 4) % 4
    header += b'\x00' * header_padding
    
    return header + frame_data


class MockDAT2Manager:
    """Mock do DAT2Manager para testes."""
    
    def __init__(self, files: dict):
        """
        Args:
            files: Dicionário mapeando caminhos para dados binários
        """
        self.files = files
    
    def get_file(self, path: str) -> bytes:
        return self.files.get(path)
    
    def list_all_files(self) -> list:
        return list(self.files.keys())


class TestCritterExtractor:
    """Testes unitários para CritterExtractor."""
    
    def test_identify_critter_type_human(self):
        """Testa identificação de tipo humano."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = CritterExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._identify_critter_type('hmwarrda.frm') == 'human'
            assert extractor._identify_critter_type('hfprimaa.frm') == 'human'
    
    def test_identify_critter_type_animal(self):
        """Testa identificação de tipo animal."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = CritterExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._identify_critter_type('radscorpaa.frm') == 'animal'
            assert extractor._identify_critter_type('geckoaa.frm') == 'animal'
    
    def test_identify_animation_type(self):
        """Testa identificação de tipo de animação."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = CritterExtractor(mock_dat, palette, temp_dir)
            
            # O extrator usa padrões que podem coincidir com partes do nome
            # Testamos o comportamento real
            result_walk = extractor._identify_animation_type('walk.frm')
            assert result_walk == 'walk', f"Esperado 'walk', obtido '{result_walk}'"
            
            result_idle = extractor._identify_animation_type('idle.frm')
            assert result_idle == 'idle', f"Esperado 'idle', obtido '{result_idle}'"
            
            result_attack = extractor._identify_animation_type('attack.frm')
            assert result_attack == 'attack', f"Esperado 'attack', obtido '{result_attack}'"
            
            result_death = extractor._identify_animation_type('death.frm')
            assert result_death == 'death', f"Esperado 'death', obtido '{result_death}'"


class TestCritterPropertyTests:
    """Property-based tests para CritterExtractor."""
    
    @given(
        num_animations=st.integers(min_value=1, max_value=4),
        num_frames=st.integers(min_value=1, max_value=5),
        num_directions=st.integers(min_value=1, max_value=6)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_8_critter_animation_completeness(self, num_animations, num_frames, num_directions):
        """
        **Feature: fallout2-asset-extraction, Property 8: Critter Animation Completeness**
        
        Para qualquer tipo de criatura com animações definidas (idle, walk, attack, death),
        o extrator DEVE exportar todas as variantes de animação com nomenclatura padronizada.
        
        **Validates: Requirements 3.2**
        """
        # Usar nomes de animação que o extrator consegue identificar corretamente
        animation_names = ['idle', 'walk', 'attack', 'death'][:num_animations]
        
        files = {}
        for anim_name in animation_names:
            # Usar nome completo da animação para garantir identificação correta
            frm_path = f'art/critters/testcritter_{anim_name}.frm'
            frm_data = create_test_frm(
                width=10, 
                height=10, 
                num_frames=num_frames,
                num_directions=num_directions
            )
            files[frm_path] = frm_data
        
        mock_dat = MockDAT2Manager(files)
        palette = PaletteLoader()
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = CritterExtractor(mock_dat, palette, temp_dir)
            
            # Extrair todas as criaturas
            results = extractor.extract_all_critters()
            
            # Verificar que todas as animações foram extraídas
            all_animations = []
            for critter_type, metadata_list in results.items():
                for metadata in metadata_list:
                    all_animations.extend(metadata.animations)
            
            # Verificar que temos o número esperado de animações
            # Cada animação tem num_directions direções e num_frames frames
            expected_total = num_animations * num_directions * num_frames
            assert len(all_animations) == expected_total, \
                f"Esperado {expected_total} animações, encontrado {len(all_animations)}"
            
            # Verificar que os tipos de animação estão corretos
            animation_types_found = set(a.animation_type for a in all_animations)
            for expected_name in animation_names:
                assert expected_name in animation_types_found, \
                    f"Tipo de animação '{expected_name}' não encontrado. Encontrados: {animation_types_found}"

    @given(
        offset_x=st.integers(min_value=-100, max_value=100),
        offset_y=st.integers(min_value=-100, max_value=100),
        fps=st.integers(min_value=1, max_value=30),
        num_frames=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=100)
    def test_property_9_sprite_offset_metadata_preservation(self, offset_x, offset_y, fps, num_frames):
        """
        **Feature: fallout2-asset-extraction, Property 9: Sprite Offset Metadata Preservation**
        
        Para qualquer sprite extraído, o JSON de metadados DEVE conter valores de
        offset_x e offset_y correspondentes ao header FRM original.
        
        **Validates: Requirements 3.3**
        """
        # Criar FRM com offsets específicos
        frm_data = create_test_frm(
            width=10,
            height=10,
            num_frames=num_frames,
            num_directions=1,
            fps=fps,
            offset_x=offset_x,
            offset_y=offset_y
        )
        
        files = {'art/critters/testcritteraa.frm': frm_data}
        mock_dat = MockDAT2Manager(files)
        palette = PaletteLoader()
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = CritterExtractor(mock_dat, palette, temp_dir)
            
            # Extrair criatura
            metadata = extractor.extract_critter_sprite('art/critters/testcritteraa.frm')
            
            assert metadata is not None, "Falha ao extrair criatura"
            
            # Verificar que os metadados de offset estão preservados
            for animation in metadata.animations:
                assert animation.offset_x == offset_x, \
                    f"offset_x incorreto: {animation.offset_x} != {offset_x}"
                assert animation.offset_y == offset_y, \
                    f"offset_y incorreto: {animation.offset_y} != {offset_y}"
                assert animation.fps == fps, \
                    f"fps incorreto: {animation.fps} != {fps}"
                assert animation.frame_count == num_frames, \
                    f"frame_count incorreto: {animation.frame_count} != {num_frames}"
