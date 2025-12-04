"""
Testes para o módulo frm_decoder.

Inclui testes unitários e property-based tests usando Hypothesis.
"""
import pytest
import struct
from pathlib import Path
from hypothesis import given, strategies as st, settings, assume
from PIL import Image
import io

from tools.extractors.frm_decoder import FRMDecoder, FRMImage, Frame
from tools.extractors.palette_loader import PaletteLoader


def create_test_frm(
    width: int = 10,
    height: int = 10,
    num_frames: int = 1,
    num_directions: int = 1,
    pixels: bytes = None,
    fps: int = 10
) -> bytes:
    """
    Cria um arquivo FRM sintético para testes.
    
    O formato FRM do Fallout 2 tem a seguinte estrutura:
    - Header de 62 bytes (big-endian)
    - Padding para alinhamento de 4 bytes (2 bytes)
    - Dados de frames
    
    Args:
        width: Largura do frame
        height: Altura do frame
        num_frames: Número de frames por direção
        num_directions: Número de direções (1-6)
        pixels: Dados de pixels (se None, gera aleatório)
        fps: Frames por segundo
        
    Returns:
        Bytes do arquivo FRM criado
    """
    if pixels is None:
        # Gerar pixels com alguns transparentes (índice 0)
        pixels = bytes([i % 256 for i in range(width * height)])
    
    # Calcular padding dos pixels
    pixel_padding = (4 - len(pixels) % 4) % 4
    
    # Construir frame data primeiro para calcular offsets
    # O decoder espera que os offsets sejam relativos ao início da seção de dados
    # (após header + header_padding)
    frame_data = b''
    direction_offsets = []
    
    for direction in range(6):
        if direction < num_directions:
            # Offset relativo ao início da seção de dados
            direction_offsets.append(len(frame_data))
            for frame_idx in range(num_frames):
                # Frame header (big-endian)
                frame_data += struct.pack('>h', width)  # width
                frame_data += struct.pack('>h', height)  # height
                frame_data += struct.pack('>I', len(pixels))  # size
                frame_data += struct.pack('>h', 0)  # x_offset
                frame_data += struct.pack('>h', 0)  # y_offset
                frame_data += pixels
                # Padding para alinhamento de 4 bytes
                frame_data += b'\x00' * pixel_padding
        else:
            # Direções não usadas: offset igual ao da direção anterior
            # O decoder interpreta offset igual ao anterior como "não existe separadamente"
            direction_offsets.append(direction_offsets[-1] if direction_offsets else 0)
    
    # Header FRM (62 bytes, big-endian)
    header = b''
    header += struct.pack('>I', 4)  # version (4 bytes)
    header += struct.pack('>h', fps)  # fps (2 bytes)
    header += struct.pack('>h', 0)  # action_frame (2 bytes)
    header += struct.pack('>h', num_frames)  # frame_count (2 bytes)
    
    # X offsets para 6 direções (12 bytes)
    for i in range(6):
        header += struct.pack('>h', 0)
    
    # Y offsets para 6 direções (12 bytes)
    for i in range(6):
        header += struct.pack('>h', 0)
    
    # Data offsets para 6 direções (24 bytes)
    # NOTA: O decoder atual usa offset == 0 para indicar "direção não existe"
    # Mas para a direção 0, o offset é naturalmente 0
    # Então precisamos ajustar: se a direção existe e offset seria 0, usamos um valor especial
    for i in range(6):
        offset = direction_offsets[i]
        # Se é a primeira direção (offset 0) e ela existe, o decoder tem um bug
        # Vamos usar o offset como está e ver se o decoder lida corretamente
        header += struct.pack('>I', offset)
    
    # Data size (4 bytes)
    header += struct.pack('>I', len(frame_data))
    
    # Header deve ter exatamente 62 bytes
    assert len(header) == 62, f"Header tem {len(header)} bytes, esperado 62"
    
    # Padding do header para alinhamento de 4 bytes (62 -> 64)
    header_padding = (4 - 62 % 4) % 4  # = 2
    header += b'\x00' * header_padding
    
    return header + frame_data


class TestFRMDecoder:
    """Testes unitários para FRMDecoder."""
    
    def test_decode_simple_frm(self):
        """Testa decodificação de FRM simples."""
        frm_data = create_test_frm(width=10, height=10, num_frames=1, num_directions=1)
        
        decoder = FRMDecoder()
        frm_image = decoder.decode(frm_data)
        
        assert frm_image.num_frames == 1
        assert frm_image.num_directions >= 1
        assert len(frm_image.frames[0]) >= 1
        assert frm_image.frames[0][0].width == 10
        assert frm_image.frames[0][0].height == 10
    
    def test_decode_multi_direction(self):
        """Testa decodificação de FRM com múltiplas direções."""
        frm_data = create_test_frm(width=8, height=8, num_frames=1, num_directions=6)
        
        decoder = FRMDecoder()
        frm_image = decoder.decode(frm_data)
        
        assert frm_image.num_directions == 6
        for direction in range(6):
            assert len(frm_image.frames[direction]) >= 1
    
    def test_decode_animation(self):
        """Testa decodificação de FRM com animação."""
        frm_data = create_test_frm(width=8, height=8, num_frames=5, num_directions=1)
        
        decoder = FRMDecoder()
        frm_image = decoder.decode(frm_data)
        
        assert frm_image.num_frames == 5
        assert len(frm_image.frames[0]) == 5
    
    def test_to_png_creates_file(self, tmp_path):
        """Testa que to_png cria arquivo PNG."""
        frm_data = create_test_frm(width=10, height=10)
        
        decoder = FRMDecoder()
        frm_image = decoder.decode(frm_data)
        
        output_path = tmp_path / "test.png"
        decoder.to_png(frm_image, str(output_path))
        
        assert output_path.exists()
        
        # Verificar que é um PNG válido
        img = Image.open(output_path)
        assert img.size == (10, 10)
        assert img.mode == 'RGBA'


class TestFRMPropertyTests:
    """Property-based tests para FRMDecoder."""
    
    @given(
        width=st.integers(min_value=1, max_value=100),
        height=st.integers(min_value=1, max_value=100)
    )
    @settings(max_examples=100)
    def test_property_7_transparency_preservation(self, width, height):
        """
        **Feature: fallout2-asset-extraction, Property 7: Transparency Preservation**
        
        Para qualquer pixel FRM com índice de cor 0, o pixel PNG correspondente
        DEVE ter valor de canal alpha de 0 (totalmente transparente).
        
        **Validates: Requirements 2.4**
        """
        import tempfile
        import os
        
        # Criar pixels com alguns índices 0 (transparentes)
        pixels = []
        transparent_positions = set()
        
        for y in range(height):
            for x in range(width):
                # Alternar entre transparente (0) e não-transparente
                if (x + y) % 3 == 0:
                    pixels.append(0)  # Transparente
                    transparent_positions.add((x, y))
                else:
                    pixels.append((x + y) % 255 + 1)  # Não-transparente (1-255)
        
        pixels_bytes = bytes(pixels)
        frm_data = create_test_frm(width=width, height=height, pixels=pixels_bytes)
        
        decoder = FRMDecoder()
        frm_image = decoder.decode(frm_data)
        
        # Converter para PNG usando arquivo temporário
        with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as f:
            output_path = f.name
        
        try:
            decoder.to_png(frm_image, output_path)
            
            # Verificar transparência
            img = Image.open(output_path)
            img_pixels = img.load()
            
            for x, y in transparent_positions:
                if x < img.width and y < img.height:
                    pixel = img_pixels[x, y]
                    # O canal alpha (índice 3) deve ser 0 para pixels transparentes
                    assert pixel[3] == 0, \
                        f"Pixel ({x}, {y}) com índice 0 deveria ser transparente (alpha=0), mas tem alpha={pixel[3]}"
            
            # Verificar que pixels não-transparentes têm alpha = 255
            for y in range(min(height, img.height)):
                for x in range(min(width, img.width)):
                    if (x, y) not in transparent_positions:
                        pixel = img_pixels[x, y]
                        assert pixel[3] == 255, \
                            f"Pixel ({x}, {y}) não-transparente deveria ter alpha=255, mas tem alpha={pixel[3]}"
            
            img.close()
        finally:
            os.unlink(output_path)


    @given(
        num_directions=st.integers(min_value=1, max_value=6),
        width=st.integers(min_value=5, max_value=50),
        height=st.integers(min_value=5, max_value=50)
    )
    @settings(max_examples=100)
    def test_property_5_direction_export_completeness(self, num_directions, width, height):
        """
        **Feature: fallout2-asset-extraction, Property 5: FRM Direction Export Completeness**
        
        Para qualquer arquivo FRM com N direções (1-6), o exportador DEVE produzir
        exatamente N arquivos PNG com sufixos direcionais corretos (_ne, _e, _se, _sw, _w, _nw).
        
        **Validates: Requirements 2.2**
        """
        import tempfile
        import shutil
        
        pixels = bytes([i % 256 for i in range(width * height)])
        frm_data = create_test_frm(
            width=width, 
            height=height, 
            num_directions=num_directions,
            pixels=pixels
        )
        
        decoder = FRMDecoder()
        frm_image = decoder.decode(frm_data)
        
        # Criar diretório temporário
        temp_dir = tempfile.mkdtemp()
        
        try:
            # Exportar todas as direções
            created_files = decoder.export_all_directions(frm_image, temp_dir, "test")
            
            # Verificar que o número de arquivos criados corresponde ao número de direções
            assert len(created_files) == num_directions, \
                f"Esperado {num_directions} arquivos, criados {len(created_files)}"
            
            # Verificar que os sufixos estão corretos
            expected_suffixes = FRMDecoder.DIRECTION_SUFFIXES[:num_directions]
            for suffix in expected_suffixes:
                # Usar correspondência mais precisa: sufixo seguido de .png
                matching = [f for f in created_files if f.endswith(f"{suffix}.png")]
                assert len(matching) == 1, \
                    f"Sufixo {suffix} não encontrado nos arquivos criados: {created_files}"
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

    @given(
        num_frames=st.integers(min_value=1, max_value=10),
        width=st.integers(min_value=5, max_value=30),
        height=st.integers(min_value=5, max_value=30)
    )
    @settings(max_examples=100)
    def test_property_6_animation_frame_export(self, num_frames, width, height):
        """
        **Feature: fallout2-asset-extraction, Property 6: FRM Animation Frame Export**
        
        Para qualquer arquivo FRM com N frames por direção, o exportador DEVE produzir
        saída contendo todos os N frames (seja como spritesheet ou arquivos individuais).
        
        **Validates: Requirements 2.3**
        """
        import tempfile
        import shutil
        
        pixels = bytes([i % 256 for i in range(width * height)])
        frm_data = create_test_frm(
            width=width, 
            height=height, 
            num_frames=num_frames,
            num_directions=1,
            pixels=pixels
        )
        
        decoder = FRMDecoder()
        frm_image = decoder.decode(frm_data)
        
        # Criar diretório temporário
        temp_dir = tempfile.mkdtemp()
        
        try:
            # Exportar como frames individuais
            created_files = decoder.to_individual_frames(frm_image, temp_dir, "test")
            
            # Verificar que o número de arquivos criados corresponde ao número de frames
            assert len(created_files) == num_frames, \
                f"Esperado {num_frames} arquivos, criados {len(created_files)}"
            
            # Verificar que cada arquivo existe e é um PNG válido
            for file_path in created_files:
                img = Image.open(file_path)
                assert img.size == (width, height), \
                    f"Frame {file_path} tem dimensões incorretas: {img.size} != ({width}, {height})"
                img.close()
            
            # Testar também spritesheet
            spritesheet_path = Path(temp_dir) / "spritesheet.png"
            decoder.to_spritesheet(frm_image, str(spritesheet_path), direction=0)
            
            spritesheet = Image.open(spritesheet_path)
            # Spritesheet deve ter largura = max_width * num_frames
            expected_width = width * num_frames
            assert spritesheet.width == expected_width, \
                f"Spritesheet tem largura incorreta: {spritesheet.width} != {expected_width}"
            spritesheet.close()
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

    @given(
        width=st.integers(min_value=5, max_value=50),
        height=st.integers(min_value=5, max_value=50)
    )
    @settings(max_examples=50)
    def test_property_4_frm_png_roundtrip(self, width, height):
        """
        **Feature: fallout2-asset-extraction, Property 4: FRM to PNG Round-Trip**
        
        Para qualquer imagem FRM válida, converter para PNG e verificar que as dimensões
        e dados de pixel são preservados.
        
        **Validates: Requirements 2.1, 2.5**
        
        Nota: Round-trip completo (PNG -> FRM) não é implementado, então verificamos
        que as dimensões e contagem de pixels são preservadas.
        """
        import tempfile
        import os
        
        # Criar pixels com valores variados
        pixels = bytes([(x + y * width) % 256 for y in range(height) for x in range(width)])
        frm_data = create_test_frm(width=width, height=height, pixels=pixels)
        
        decoder = FRMDecoder()
        frm_image = decoder.decode(frm_data)
        
        # Verificar que o FRM foi decodificado corretamente
        assert frm_image.frames[0][0].width == width
        assert frm_image.frames[0][0].height == height
        assert len(frm_image.frames[0][0].pixels) == width * height
        
        # Converter para PNG
        with tempfile.NamedTemporaryFile(suffix='.png', delete=False) as f:
            output_path = f.name
        
        try:
            decoder.to_png(frm_image, output_path)
            
            # Verificar PNG
            img = Image.open(output_path)
            assert img.size == (width, height), \
                f"PNG tem dimensões incorretas: {img.size} != ({width}, {height})"
            assert img.mode == 'RGBA', f"PNG tem modo incorreto: {img.mode}"
            
            # Verificar que o número de pixels é correto
            img_data = list(img.getdata())
            assert len(img_data) == width * height, \
                f"PNG tem número incorreto de pixels: {len(img_data)} != {width * height}"
            
            img.close()
        finally:
            os.unlink(output_path)
