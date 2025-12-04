"""
Testes para o módulo animation_extractor.

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

from tools.extractors.animation_extractor import (
    AnimationExtractor, 
    AnimationData, 
    AnimationFrame, 
    CritterData
)
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


class TestAnimationExtractor:
    """Testes unitários para AnimationExtractor."""
    
    def test_identify_critter_type_human(self):
        """Testa identificação de tipo humano."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = AnimationExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._identify_critter_type('hmwarr') == 'human'
            assert extractor._identify_critter_type('hfprim') == 'human'
            assert extractor._identify_critter_type('nmguard') == 'human'
    
    def test_identify_critter_type_animal(self):
        """Testa identificação de tipo animal."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = AnimationExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._identify_critter_type('radscorp') == 'animal'
            assert extractor._identify_critter_type('gecko') == 'animal'
            assert extractor._identify_critter_type('rat') == 'animal'
    
    def test_extract_critter_id(self):
        """Testa extração do ID da criatura do caminho."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = AnimationExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._extract_critter_id('art/critters/hmwarraa.frm') == 'hmwarr'
            assert extractor._extract_critter_id('art/critters/radscorpab.frm') == 'radscorp'
    
    def test_extract_animation_code(self):
        """Testa extração do código de animação."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = AnimationExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._extract_animation_code('art/critters/hmwarraa.frm') == 'aa'
            assert extractor._extract_animation_code('art/critters/hmwarrab.frm') == 'ab'
            assert extractor._extract_animation_code('art/critters/hmwarrba.frm') == 'ba'
    
    def test_get_animation_type(self):
        """Testa mapeamento de código para tipo de animação."""
        palette = PaletteLoader()
        mock_dat = MockDAT2Manager({})
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = AnimationExtractor(mock_dat, palette, temp_dir)
            
            assert extractor._get_animation_type('aa') == 'idle'
            assert extractor._get_animation_type('ab') == 'walk'
            assert extractor._get_animation_type('at') == 'run'
            assert extractor._get_animation_type('ba') == 'death_normal'


class TestAnimationPropertyTests:
    """Property-based tests para AnimationExtractor."""
    
    @given(
        num_frames=st.integers(min_value=1, max_value=10),
        num_directions=st.integers(min_value=1, max_value=6),
        width=st.integers(min_value=5, max_value=50),
        height=st.integers(min_value=5, max_value=50)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_1_frm_frame_extraction_completeness(self, num_frames, num_directions, width, height):
        """
        **Feature: npc-quest-content, Property 1: FRM Frame Extraction Completeness**
        
        Para qualquer arquivo FRM válido com N frames e D direções, o extrator
        DEVE produzir exatamente N × D imagens de frame individuais.
        
        **Validates: Requirements 1.1, 1.2**
        """
        # Criar FRM sintético
        pixels = bytes([i % 256 for i in range(width * height)])
        frm_data = create_test_frm(
            width=width,
            height=height,
            num_frames=num_frames,
            num_directions=num_directions,
            pixels=pixels
        )
        
        # Criar mock DAT2 com o arquivo
        files = {'art/critters/testcritteraa.frm': frm_data}
        mock_dat = MockDAT2Manager(files)
        palette = PaletteLoader()
        
        with tempfile.TemporaryDirectory() as temp_dir:
            extractor = AnimationExtractor(mock_dat, palette, temp_dir)
            
            # Extrair animação
            animation_data = extractor.extract_animation(
                'art/critters/testcritteraa.frm',
                'testcritter',
                'aa'
            )
            
            assert animation_data is not None, "Falha ao extrair animação"
            
            # Verificar número total de frames extraídos
            expected_total = num_frames * num_directions
            actual_total = len(animation_data.frames)
            
            assert actual_total == expected_total, \
                f"Esperado {expected_total} frames (N={num_frames} × D={num_directions}), " \
                f"obtido {actual_total}"
            
            # Verificar que cada direção tem o número correto de frames
            frames_by_direction = {}
            for frame in animation_data.frames:
                dir_name = frame.direction_name
                if dir_name not in frames_by_direction:
                    frames_by_direction[dir_name] = 0
                frames_by_direction[dir_name] += 1
            
            assert len(frames_by_direction) == num_directions, \
                f"Esperado {num_directions} direções, obtido {len(frames_by_direction)}"
            
            for dir_name, count in frames_by_direction.items():
                assert count == num_frames, \
                    f"Direção {dir_name}: esperado {num_frames} frames, obtido {count}"
            
            # Verificar que os arquivos PNG foram criados
            for frame in animation_data.frames:
                frame_path = Path(temp_dir) / frame.output_path
                assert frame_path.exists(), f"Arquivo não criado: {frame_path}"


    @given(
        num_frames=st.integers(min_value=1, max_value=5),
        num_directions=st.integers(min_value=1, max_value=6)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_3_direction_mapping_consistency(self, num_frames, num_directions):
        """
        **Feature: npc-quest-content, Property 3: Direction Mapping Consistency**
        
        Para qualquer criatura com 6 direções, o conversor DEVE produzir saída com
        exatamente 8 direções, onde direções N e S são interpoladas ou duplicadas
        das direções adjacentes (NE e SE respectivamente).
        
        **Validates: Requirements 2.3**
        """
        from tools.extractors.spriteframes_generator import SpriteFramesGenerator
        
        # Criar frames de teste para cada direção disponível
        direction_names = ['ne', 'e', 'se', 'sw', 'w', 'nw'][:num_directions]
        
        frames_6dir = {}
        for dir_name in direction_names:
            frames_6dir[dir_name] = [f"frame_{dir_name}_{i}.png" for i in range(num_frames)]
        
        # Criar gerador
        with tempfile.TemporaryDirectory() as temp_dir:
            generator = SpriteFramesGenerator(temp_dir)
            
            # Mapear 6 para 8 direções
            frames_8dir = generator.map_6_to_8_directions(frames_6dir)
            
            # Verificar que temos no máximo 8 direções
            assert len(frames_8dir) <= 8, \
                f"Esperado no máximo 8 direções, obtido {len(frames_8dir)}"
            
            # Verificar que as direções originais estão presentes
            for dir_name in direction_names:
                assert dir_name in frames_8dir, \
                    f"Direção original {dir_name} não encontrada no mapeamento"
            
            # Se temos NE, devemos ter N (duplicado de NE)
            if 'ne' in frames_6dir:
                assert 'n' in frames_8dir, \
                    "Direção N deveria existir (duplicada de NE)"
                assert frames_8dir['n'] == frames_8dir['ne'], \
                    "Direção N deveria ser igual a NE"
            
            # Se temos SE, devemos ter S (duplicado de SE)
            if 'se' in frames_6dir:
                assert 's' in frames_8dir, \
                    "Direção S deveria existir (duplicada de SE)"
                assert frames_8dir['s'] == frames_8dir['se'], \
                    "Direção S deveria ser igual a SE"
            
            # Verificar que cada direção tem o número correto de frames
            for dir_name, frames in frames_8dir.items():
                assert len(frames) == num_frames, \
                    f"Direção {dir_name}: esperado {num_frames} frames, obtido {len(frames)}"


    @given(
        width=st.integers(min_value=5, max_value=50),
        height=st.integers(min_value=5, max_value=50),
        transparent_ratio=st.floats(min_value=0.1, max_value=0.9)
    )
    @settings(max_examples=100, deadline=None)
    def test_property_2_png_transparency_correctness(self, width, height, transparent_ratio):
        """
        **Feature: npc-quest-content, Property 2: PNG Transparency Correctness**
        
        Para qualquer sprite extraído, pixels com índice de paleta 0 DEVEM ter
        valor de canal alpha 0 (totalmente transparente) no PNG de saída.
        
        **Validates: Requirements 2.1**
        """
        from PIL import Image
        import os
        
        # Criar pixels com alguns índices 0 (transparentes)
        pixels = []
        transparent_positions = set()
        
        for y in range(height):
            for x in range(width):
                # Usar ratio para determinar transparência
                if (x * height + y) % int(1 / transparent_ratio) == 0:
                    pixels.append(0)  # Transparente (índice 0)
                    transparent_positions.add((x, y))
                else:
                    pixels.append((x + y) % 255 + 1)  # Não-transparente (1-255)
        
        pixels_bytes = bytes(pixels)
        frm_data = create_test_frm(
            width=width,
            height=height,
            num_frames=1,
            num_directions=1,
            pixels=pixels_bytes
        )
        
        # Criar mock DAT2 com o arquivo
        files = {'art/critters/testcritteraa.frm': frm_data}
        mock_dat = MockDAT2Manager(files)
        palette = PaletteLoader()
        
        with tempfile.TemporaryDirectory() as temp_dir:
            from tools.extractors.animation_extractor import AnimationExtractor
            
            extractor = AnimationExtractor(mock_dat, palette, temp_dir)
            
            # Extrair animação
            animation_data = extractor.extract_animation(
                'art/critters/testcritteraa.frm',
                'testcritter',
                'aa'
            )
            
            assert animation_data is not None, "Falha ao extrair animação"
            assert len(animation_data.frames) > 0, "Nenhum frame extraído"
            
            # Verificar o PNG gerado
            frame = animation_data.frames[0]
            png_path = Path(temp_dir) / frame.output_path
            
            assert png_path.exists(), f"PNG não criado: {png_path}"
            
            # Abrir e verificar transparência
            img = Image.open(png_path)
            assert img.mode == 'RGBA', f"Modo incorreto: {img.mode}"
            
            img_pixels = img.load()
            
            # Verificar pixels transparentes
            for x, y in transparent_positions:
                if x < img.width and y < img.height:
                    pixel = img_pixels[x, y]
                    alpha = pixel[3]
                    assert alpha == 0, \
                        f"Pixel ({x}, {y}) com índice 0 deveria ter alpha=0, tem alpha={alpha}"
            
            # Verificar pixels opacos
            for y in range(min(height, img.height)):
                for x in range(min(width, img.width)):
                    if (x, y) not in transparent_positions:
                        pixel = img_pixels[x, y]
                        alpha = pixel[3]
                        assert alpha == 255, \
                            f"Pixel ({x}, {y}) não-transparente deveria ter alpha=255, tem alpha={alpha}"
            
            img.close()
