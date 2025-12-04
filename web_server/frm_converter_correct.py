#!/usr/bin/env python3
"""
Conversor .FRM para PNG - CORRIGIDO (BIG-ENDIAN)
Fallout 2 usa BIG-ENDIAN, não little-endian!
"""

import struct
import sys
import io
from pathlib import Path
from PIL import Image
import json

if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
CRITTERS_DIR = EXTRACTED_DIR / "critter" / "art" / "critters"
IMAGES_DIR = EXTRACTED_DIR / "images" / "critters"
IMAGES_DIR.mkdir(parents=True, exist_ok=True)

def padding_for_size(size):
    """Calcula padding para alinhamento"""
    return (4 - size % 4) % 4

def load_palette():
    """Carrega paleta do color.pal"""
    palette_path = FALLOUT_DIR / "color.pal"
    if not palette_path.exists():
        palette = [(0, 0, 0)]
        for i in range(1, 256):
            r = min(255, (i * 3) % 256)
            g = min(255, (i * 5) % 256)
            b = min(255, (i * 7) % 256)
            palette.append((r, g, b))
        return palette
    
    with open(palette_path, 'rb') as f:
        data = f.read(768)
    palette = []
    for i in range(256):
        r = min(255, data[i * 3] * 4)
        g = min(255, data[i * 3 + 1] * 4)
        b = min(255, data[i * 3 + 2] * 4)
        palette.append((r, g, b))
    return palette

def read_int16_be(f):
    """Lê int16 big-endian (como fileReadInt16 do código)"""
    high = struct.unpack('B', f.read(1))[0]
    low = struct.unpack('B', f.read(1))[0]
    value = (high << 8) | low
    if value > 32767:
        value -= 65536  # Signed
    return value

def read_int32_be(f):
    """Lê int32 big-endian (como fileReadInt32 do código)"""
    bytes_data = f.read(4)
    value = struct.unpack('>I', bytes_data)[0]
    # Converter para signed se necessário
    if value > 2147483647:
        value -= 4294967296
    return value

def frm_to_png(frm_path, output_dir, palette):
    """Converte .FRM para PNG usando BIG-ENDIAN"""
    try:
        with open(frm_path, 'rb') as f:
            # Ler header (BIG-ENDIAN!)
            field_0 = read_int32_be(f)
            fps = read_int16_be(f)
            action_frame = read_int16_be(f)
            frame_count = read_int16_be(f)
            
            x_offsets = [read_int16_be(f) for _ in range(6)]
            y_offsets = [read_int16_be(f) for _ in range(6)]
            data_offsets = [read_int32_be(f) for _ in range(6)]
            data_size = read_int32_be(f)
            
            # Header tem 62 bytes
            header_size = 62
            header_padding = padding_for_size(header_size)
            
            sprite_name = Path(frm_path).stem
            output_base = output_dir / sprite_name
            output_base.mkdir(parents=True, exist_ok=True)
            
            direction_names = ['NE', 'E', 'SE', 'SW', 'W', 'NW']
            converted_frames = []
            
            current_padding = header_padding
            previous_padding = 0
            
            for direction in range(6):
                direction_padding = current_padding
                
                if direction == 0 or data_offsets[direction - 1] != data_offsets[direction]:
                    direction_padding += previous_padding
                    current_padding += previous_padding
                    
                    actual_offset = header_size + header_padding + data_offsets[direction] + direction_padding
                    
                    if actual_offset >= frm_path.stat().st_size:
                        continue
                    
                    f.seek(actual_offset)
                    
                    for frame_idx in range(frame_count):
                        try:
                            width = read_int16_be(f)
                            height = read_int16_be(f)
                            size = read_int32_be(f)
                            x_offset = read_int16_be(f)
                            y_offset = read_int16_be(f)
                            
                            if width <= 0 or height <= 0 or size <= 0:
                                break
                            
                            pixels_data = f.read(size)
                            if len(pixels_data) < size:
                                break
                            
                            frame_padding = padding_for_size(size)
                            f.read(frame_padding)
                            previous_padding += frame_padding
                            
                            # Converter para imagem
                            img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
                            pixels = img.load()
                            
                            pixel_idx = 0
                            for y in range(height):
                                for x in range(width):
                                    if pixel_idx < len(pixels_data):
                                        palette_idx = pixels_data[pixel_idx]
                                        pixel_idx += 1
                                        
                                        if palette_idx == 0:
                                            pixels[x, y] = (0, 0, 0, 0)
                                        elif palette_idx < len(palette):
                                            r, g, b = palette[palette_idx]
                                            pixels[x, y] = (r, g, b, 255)
                                        else:
                                            pixels[x, y] = (0, 0, 0, 0)
                                    else:
                                        pixels[x, y] = (0, 0, 0, 0)
                            
                            output_file = output_base / f"{direction_names[direction]}_frame{frame_idx:03d}.png"
                            img.save(output_file, 'PNG')
                            
                            converted_frames.append({
                                'direction': direction,
                                'direction_name': direction_names[direction],
                                'frame': frame_idx,
                                'width': width,
                                'height': height,
                                'path': str(output_file.relative_to(BASE_DIR))
                            })
                        except (struct.error, Exception):
                            break
            
            return {
                'name': sprite_name,
                'frames': converted_frames,
                'total_frames': len(converted_frames)
            }
    except Exception as e:
        return None

def main():
    print("=" * 60)
    print("Conversor .FRM para PNG - BIG-ENDIAN CORRIGIDO")
    print("=" * 60)
    
    palette = load_palette()
    print(f"\nPaleta carregada: {len(palette)} cores")
    
    # NPCs conhecidos
    known_npcs = ['HMWARR', 'HFPRIM', 'HMJMPS', 'HFJMPS']
    frm_files = []
    
    if CRITTERS_DIR.exists():
        for npc_prefix in known_npcs:
            for frm_file in CRITTERS_DIR.glob(f"{npc_prefix}*.FRM"):
                if frm_file not in frm_files:
                    frm_files.append(frm_file)
    
    print(f"\nEncontrados {len(frm_files)} arquivos de NPCs")
    
    if len(frm_files) == 0:
        print("Nenhum arquivo encontrado!")
        return
    
    converted = []
    for i, frm_file in enumerate(frm_files, 1):
        print(f"  [{i}/{len(frm_files)}] {frm_file.name}")
        result = frm_to_png(frm_file, IMAGES_DIR, palette)
        if result and result['total_frames'] > 0:
            converted.append(result)
            print(f"    OK: {result['total_frames']} frames")
        else:
            print(f"    FALHOU")
    
    index_file = IMAGES_DIR / "critters_index.json"
    with open(index_file, 'w', encoding='utf-8') as f:
        json.dump(converted, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*60}")
    print(f"Concluido: {len(converted)} sprites convertidos")
    print(f"Salvo em: {IMAGES_DIR}")
    
    if len(converted) > 0:
        print(f"\nSUCESSO! Acesse: http://localhost:8000/sprite_gallery.html")

if __name__ == "__main__":
    try:
        from PIL import Image
        main()
    except ImportError:
        print("ERRO: Instale Pillow: pip install Pillow")

