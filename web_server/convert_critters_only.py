#!/usr/bin/env python3
"""
Conversor de .FRM para PNG - APENAS NPCs/Critters
Versão otimizada para converter apenas sprites de personagens
"""

import struct
import os
import sys
import io
from pathlib import Path
from PIL import Image
import json

# Configurar encoding UTF-8 no Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
CRITTERS_DIR = EXTRACTED_DIR / "critter" / "art" / "critters"
IMAGES_DIR = EXTRACTED_DIR / "images" / "critters"

# Criar diretório de imagens
IMAGES_DIR.mkdir(parents=True, exist_ok=True)

# Paleta padrão do Fallout 2
def load_palette():
    """Carrega paleta do arquivo color.pal"""
    palette_path = FALLOUT_DIR / "color.pal"
    
    if not palette_path.exists():
        print("AVISO: color.pal nao encontrado, usando paleta padrao")
        return create_default_palette()
    
    try:
        with open(palette_path, 'rb') as f:
            palette_data = f.read(768)  # 256 cores × 3 bytes (RGB)
            
        palette = []
        for i in range(256):
            r = palette_data[i * 3]
            g = palette_data[i * 3 + 1]
            b = palette_data[i * 3 + 2]
            # Paleta do Fallout usa 6 bits, converter para 8 bits
            palette.append((r * 4, g * 4, b * 4))
        
        return palette
    except Exception as e:
        print(f"AVISO: Erro ao carregar paleta: {e}, usando padrao")
        return create_default_palette()

def create_default_palette():
    """Cria paleta padrão"""
    palette = []
    for i in range(256):
        if i == 0:
            palette.append((0, 0, 0))  # Transparente/preto
        else:
            # Gradiente de cores para visualização
            r = min(255, (i * 3) % 256)
            g = min(255, (i * 5) % 256)
            b = min(255, (i * 7) % 256)
            palette.append((r, g, b))
    return palette

def frm_to_png(frm_path, output_dir, palette):
    """Converte .FRM para PNG"""
    try:
        with open(frm_path, 'rb') as f:
            # Ler header
            field_0 = struct.unpack('<I', f.read(4))[0]
            fps = struct.unpack('<h', f.read(2))[0]
            action_frame = struct.unpack('<h', f.read(2))[0]
            frame_count = struct.unpack('<h', f.read(2))[0]
            
            x_offsets = [struct.unpack('<h', f.read(2))[0] for _ in range(6)]
            y_offsets = [struct.unpack('<h', f.read(2))[0] for _ in range(6)]
            data_offsets = [struct.unpack('<I', f.read(4))[0] for _ in range(6)]
            padding = [struct.unpack('<I', f.read(4))[0] for _ in range(6)]
            data_size = struct.unpack('<I', f.read(4))[0]
            
            sprite_name = Path(frm_path).stem
            output_base = output_dir / sprite_name
            output_base.mkdir(parents=True, exist_ok=True)
            
            direction_names = ['NE', 'E', 'SE', 'SW', 'W', 'NW']
            converted_frames = []
            
            # Para cada direção
            for direction in range(6):
                if data_offsets[direction] == 0:
                    continue
                
                # Ir para offset da direção
                f.seek(data_offsets[direction])
                
                # Ler frames desta direção
                for frame_idx in range(frame_count):
                    try:
                        # Ler header do frame
                        width = struct.unpack('<h', f.read(2))[0]
                        height = struct.unpack('<h', f.read(2))[0]
                        size = struct.unpack('<I', f.read(4))[0]
                        x_offset = struct.unpack('<h', f.read(2))[0]
                        y_offset = struct.unpack('<h', f.read(2))[0]
                        
                        if width <= 0 or height <= 0:
                            break
                        
                        # Ler pixels
                        expected_size = width * height
                        pixels_data = f.read(min(size, expected_size))
                        
                        if len(pixels_data) == 0:
                            break
                        
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
                                    
                                    # Cor 0 é transparente
                                    if palette_idx == 0:
                                        pixels[x, y] = (0, 0, 0, 0)
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
                    except struct.error:
                        break
                    except Exception as e:
                        if frame_idx == 0:  # Só mostrar erro no primeiro frame
                            print(f"    AVISO: Erro no frame {frame_idx} direcao {direction}: {e}")
                        break
        
        return {
            'name': sprite_name,
            'frames': converted_frames,
            'total_frames': len(converted_frames),
            'fps': fps,
            'frame_count': frame_count
        }
        
    except Exception as e:
        print(f"ERRO ao converter {frm_path.name}: {e}")
        return None

def main():
    """Função principal"""
    print("=" * 60)
    print("Conversor .FRM para PNG - APENAS NPCs/Critters")
    print("=" * 60)
    
    # Carregar paleta
    print("\nCarregando paleta...")
    palette = load_palette()
    print(f"OK: Paleta carregada ({len(palette)} cores)")
    
    # Encontrar arquivos .FRM de critters
    print("\nProcurando sprites de NPCs...")
    frm_files = []
    
    if CRITTERS_DIR.exists():
        for frm_file in CRITTERS_DIR.glob("*.FRM"):
            frm_files.append(frm_file)
        for frm_file in CRITTERS_DIR.glob("*.frm"):
            frm_files.append(frm_file)
    
    # Também procurar em subdiretórios
    if CRITTERS_DIR.exists():
        for frm_file in CRITTERS_DIR.rglob("*.FRM"):
            if frm_file not in frm_files:
                frm_files.append(frm_file)
        for frm_file in CRITTERS_DIR.rglob("*.frm"):
            if frm_file not in frm_files:
                frm_files.append(frm_file)
    
    print(f"OK: Encontrados {len(frm_files)} arquivos .FRM de NPCs")
    
    if len(frm_files) == 0:
        print("\nAVISO: Nenhum arquivo .FRM de critters encontrado!")
        print(f"   Procurando em: {CRITTERS_DIR}")
        return
    
    # Converter cada arquivo
    print(f"\nConvertendo para PNG...")
    converted = []
    failed = []
    
    for i, frm_file in enumerate(frm_files, 1):
        print(f"  [{i}/{len(frm_files)}] Convertendo: {frm_file.name}")
        result = frm_to_png(frm_file, IMAGES_DIR, palette)
        if result and result['total_frames'] > 0:
            converted.append(result)
            print(f"    OK: {result['total_frames']} frames convertidos")
        else:
            failed.append(frm_file.name)
            if result:
                print(f"    AVISO: Nenhum frame convertido")
            else:
                print(f"    ERRO: Falha na conversao")
    
    # Salvar índice
    index_file = IMAGES_DIR / "critters_index.json"
    with open(index_file, 'w', encoding='utf-8') as f:
        json.dump(converted, f, indent=2, ensure_ascii=False)
    
    print(f"\n" + "=" * 60)
    print(f"Conversao concluida!")
    print(f"  OK: {len(converted)} sprites convertidos")
    if failed:
        print(f"  ERRO: {len(failed)} sprites falharam")
    print(f"  Arquivos salvos em: {IMAGES_DIR}")
    print(f"  Indice salvo em: {index_file}")
    print("=" * 60)

if __name__ == "__main__":
    try:
        from PIL import Image
    except ImportError:
        print("ERRO: Biblioteca PIL (Pillow) nao instalada!")
        print("   Instale com: pip install Pillow")
        sys.exit(1)
    
    main()

