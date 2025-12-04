#!/usr/bin/env python3
"""
Conversor CORRIGIDO de .FRM para PNG - NPCs/Critters
Versão que lê corretamente os offsets e padding
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
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
CRITTERS_DIR = EXTRACTED_DIR / "critter" / "art" / "critters"
IMAGES_DIR = EXTRACTED_DIR / "images" / "critters"
IMAGES_DIR.mkdir(parents=True, exist_ok=True)

def padding_for_size(size):
    """Calcula padding para alinhamento (baseado em src/art.cc)"""
    return (4 - size % 4) % 4

def load_palette():
    """Carrega paleta"""
    palette_path = BASE_DIR / "Fallout 2" / "color.pal"
    if not palette_path.exists():
        # Paleta padrão
        palette = [(0, 0, 0)]  # Transparente
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
        r = data[i * 3] * 4
        g = data[i * 3 + 1] * 4
        b = data[i * 3 + 2] * 4
        palette.append((min(255, r), min(255, g), min(255, b)))
    return palette

def frm_to_png(frm_path, output_dir, palette):
    """Converte .FRM para PNG - VERSÃO CORRIGIDA"""
    try:
        with open(frm_path, 'rb') as f:
            # Ler header completo
            field_0 = struct.unpack('<I', f.read(4))[0]
            fps = struct.unpack('<h', f.read(2))[0]
            action_frame = struct.unpack('<h', f.read(2))[0]
            frame_count = struct.unpack('<h', f.read(2))[0]
            
            x_offsets = [struct.unpack('<h', f.read(2))[0] for _ in range(6)]
            y_offsets = [struct.unpack('<h', f.read(2))[0] for _ in range(6)]
            data_offsets = [struct.unpack('<I', f.read(4))[0] for _ in range(6)]
            padding_array = [struct.unpack('<I', f.read(4))[0] for _ in range(6)]
            data_size = struct.unpack('<I', f.read(4))[0]
            
            # Header tem 80 bytes total
            header_size = 80
            
            sprite_name = Path(frm_path).stem
            output_base = output_dir / sprite_name
            output_base.mkdir(parents=True, exist_ok=True)
            
            direction_names = ['NE', 'E', 'SE', 'SW', 'W', 'NW']
            converted_frames = []
            
            # Para cada direção
            for direction in range(6):
                if data_offsets[direction] == 0:
                    continue
                
                # Offset é relativo ao início dos dados (após header + padding do header)
                header_padding = padding_for_size(header_size)
                actual_offset = header_size + header_padding + data_offsets[direction] + padding_array[direction]
                
                f.seek(actual_offset)
                
                # Ler frames desta direção
                for frame_idx in range(frame_count):
                    try:
                        # Ler header do frame
                        width = struct.unpack('<h', f.read(2))[0]
                        height = struct.unpack('<h', f.read(2))[0]
                        size = struct.unpack('<I', f.read(4))[0]
                        x_offset = struct.unpack('<h', f.read(2))[0]
                        y_offset = struct.unpack('<h', f.read(2))[0]
                        
                        if width <= 0 or height <= 0 or size <= 0:
                            break
                        
                        # Ler pixels
                        pixels_data = f.read(size)
                        if len(pixels_data) < size:
                            break
                        
                        # Pular padding do frame
                        frame_padding = padding_for_size(size)
                        f.read(frame_padding)
                        
                        # Converter para imagem
                        img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
                        pixels = img.load()
                        
                        # Preencher pixels
                        pixel_idx = 0
                        for y in range(height):
                            for x in range(width):
                                if pixel_idx < len(pixels_data):
                                    palette_idx = pixels_data[pixel_idx]
                                    pixel_idx += 1
                                    
                                    if palette_idx == 0:
                                        pixels[x, y] = (0, 0, 0, 0)  # Transparente
                                    elif palette_idx < len(palette):
                                        r, g, b = palette[palette_idx]
                                        pixels[x, y] = (r, g, b, 255)
                                    else:
                                        pixels[x, y] = (0, 0, 0, 0)
                                else:
                                    pixels[x, y] = (0, 0, 0, 0)
                        
                        # Salvar PNG
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
                    except (struct.error, Exception) as e:
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
    print("Conversor .FRM para PNG - NPCs (VERSÃO CORRIGIDA)")
    print("=" * 60)
    
    palette = load_palette()
    print(f"\nPaleta carregada: {len(palette)} cores")
    
    # Procurar apenas alguns NPCs conhecidos primeiro para testar
    known_npcs = ['HMWARR', 'HFPRIM', 'HMJMPS', 'HFJMPS']
    frm_files = []
    
    if CRITTERS_DIR.exists():
        for npc_prefix in known_npcs:
            for frm_file in CRITTERS_DIR.glob(f"{npc_prefix}*.FRM"):
                frm_files.append(frm_file)
            for frm_file in CRITTERS_DIR.glob(f"{npc_prefix}*.frm"):
                frm_files.append(frm_file)
    
    print(f"\nEncontrados {len(frm_files)} arquivos de NPCs conhecidos")
    
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
    
    # Salvar índice
    index_file = IMAGES_DIR / "critters_index.json"
    with open(index_file, 'w', encoding='utf-8') as f:
        json.dump(converted, f, indent=2, ensure_ascii=False)
    
    print(f"\n{'='*60}")
    print(f"Concluido: {len(converted)} sprites convertidos")
    print(f"Salvo em: {IMAGES_DIR}")

if __name__ == "__main__":
    try:
        from PIL import Image
        main()
    except ImportError:
        print("ERRO: Instale Pillow: pip install Pillow")

