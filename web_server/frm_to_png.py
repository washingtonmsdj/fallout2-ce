#!/usr/bin/env python3
"""
Conversor de .FRM para PNG
Converte sprites do Fallout 2 para imagens PNG visíveis
"""

import struct
import os
from pathlib import Path
from PIL import Image
import json

BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
IMAGES_DIR = EXTRACTED_DIR / "images"

# Criar diretório de imagens
IMAGES_DIR.mkdir(parents=True, exist_ok=True)

# Paleta padrão do Fallout 2 (fallback se não encontrar color.pal)
DEFAULT_PALETTE = [
    (0, 0, 0), (0, 0, 42), (0, 42, 0), (0, 42, 42), (42, 0, 0), (42, 0, 42),
    (42, 21, 0), (42, 42, 42), (21, 21, 21), (21, 21, 63), (21, 63, 21),
    (21, 63, 63), (63, 21, 21), (63, 21, 63), (63, 63, 21), (63, 63, 63)
] * 16  # Simplificado - precisa da paleta real

def load_palette():
    """Carrega paleta do arquivo color.pal"""
    palette_path = FALLOUT_DIR / "color.pal"
    
    if not palette_path.exists():
        print("⚠️  color.pal não encontrado, usando paleta padrão")
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
        print(f"⚠️  Erro ao carregar paleta: {e}, usando padrão")
        return create_default_palette()

def create_default_palette():
    """Cria paleta padrão"""
    palette = []
    for i in range(256):
        # Gradiente simples para visualização
        if i == 0:
            palette.append((0, 0, 0))  # Transparente/preto
        else:
            # Gradiente de cores
            r = min(255, (i * 3) % 256)
            g = min(255, (i * 5) % 256)
            b = min(255, (i * 7) % 256)
            palette.append((r, g, b))
    return palette

def read_frm_file(frm_path):
    """Lê arquivo .FRM completo"""
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
        
        return {
            'fps': fps,
            'action_frame': action_frame,
            'frame_count': frame_count,
            'x_offsets': x_offsets,
            'y_offsets': y_offsets,
            'data_offsets': data_offsets,
            'file': f,
            'file_size': f.seek(0, 2)  # Tamanho total do arquivo
        }

def read_frame(f, width, height):
    """Lê dados de um frame"""
    pixels = []
    for y in range(height):
        row = []
        for x in range(width):
            pixel_index = struct.unpack('B', f.read(1))[0]
            row.append(pixel_index)
        pixels.append(row)
    return pixels

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
                            # Tentar pular para próximo frame ou direção
                            break
                        
                        # Ler pixels (pode ser menor que width*height devido a compressão)
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
                        # Fim dos dados ou erro de leitura
                        break
                    except Exception as e:
                        print(f"    ⚠️  Erro no frame {frame_idx} direção {direction}: {e}")
                        break
        
        return {
            'name': sprite_name,
            'frames': converted_frames,
            'total_frames': len(converted_frames),
            'fps': fps,
            'frame_count': frame_count
        }
        
    except Exception as e:
        print(f"❌ Erro ao converter {frm_path}: {e}")
        import traceback
        traceback.print_exc()
        return None

def main():
    """Função principal"""
    import sys
    import io
    # Configurar stdout para UTF-8 no Windows
    if sys.platform == 'win32':
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    
    print("=" * 60)
    print("Conversor .FRM para PNG")
    print("=" * 60)
    
    # Carregar paleta
    print("\n📦 Carregando paleta...")
    palette = load_palette()
    print(f"✅ Paleta carregada: {len(palette)} cores")
    
    # Encontrar arquivos .FRM
    print("\n🔍 Procurando arquivos .FRM...")
    frm_files = []
    
    # Procurar em arquivos extraídos primeiro
    extracted_critter = EXTRACTED_DIR / "critter"
    extracted_master = EXTRACTED_DIR / "master"
    
    for extracted_dir in [extracted_critter, extracted_master]:
        if extracted_dir.exists():
            for frm_file in extracted_dir.rglob("*.FRM"):
                frm_files.append(frm_file)
            for frm_file in extracted_dir.rglob("*.frm"):
                frm_files.append(frm_file)
    
    # Procurar em data/art/ (fallback)
    art_dir = FALLOUT_DIR / "data" / "art"
    if art_dir.exists():
        for frm_file in art_dir.rglob("*.FRM"):
            frm_files.append(frm_file)
        for frm_file in art_dir.rglob("*.frm"):
            frm_files.append(frm_file)
    
    print(f"✅ Encontrados {len(frm_files)} arquivos .FRM")
    
    if len(frm_files) == 0:
        print("\n⚠️  Nenhum arquivo .FRM encontrado em pastas!")
        print("   Os sprites estão dentro dos arquivos .DAT.")
        print("   Use ferramentas como 'dat2' para extrair primeiro.")
        return
    
    # Converter cada arquivo
    print("\n🔄 Convertendo para PNG...")
    converted = []
    
    for frm_file in frm_files:
        print(f"  Convertendo: {frm_file.name}")
        result = frm_to_png(frm_file, IMAGES_DIR, palette)
        if result:
            converted.append(result)
            print(f"    ✅ {result['total_frames']} frames convertidos")
    
    # Salvar índice
    index_file = IMAGES_DIR / "sprites_index.json"
    with open(index_file, 'w', encoding='utf-8') as f:
        json.dump(converted, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Índice salvo em: {index_file}")
    print(f"\n✅ Conversão concluída! {len(converted)} sprites convertidos.")
    print(f"📁 Imagens salvas em: {IMAGES_DIR}")

if __name__ == "__main__":
    try:
        from PIL import Image
    except ImportError:
        print("❌ Erro: Biblioteca PIL (Pillow) não instalada!")
        print("   Instale com: pip install Pillow")
        sys.exit(1)
    
    main()

