#!/usr/bin/env python3
"""
Extrai sprites de objetos do ARTEMPLE baseado nos PIDs.
Lê os arquivos .PRO para obter os FRM IDs corretos.
"""

import struct
import zlib
import json
from pathlib import Path
from PIL import Image
import sys

# Paleta padrão do Fallout 2
FALLOUT_PALETTE = None

class DAT2Reader:
    def __init__(self, path):
        self.path = Path(path)
        self.files = {}
        self.fh = None
        
    def open(self):
        self.fh = open(self.path, 'rb')
        self.fh.seek(-8, 2)
        tree_size = struct.unpack('<I', self.fh.read(4))[0]
        data_size = struct.unpack('<I', self.fh.read(4))[0]
        self.fh.seek(data_size - tree_size - 8)
        count = struct.unpack('<I', self.fh.read(4))[0]
        for _ in range(count):
            nlen = struct.unpack('<I', self.fh.read(4))[0]
            name = self.fh.read(nlen).decode('ascii', errors='ignore').rstrip('\x00')
            comp = struct.unpack('<B', self.fh.read(1))[0]
            rsize = struct.unpack('<I', self.fh.read(4))[0]
            psize = struct.unpack('<I', self.fh.read(4))[0]
            off = struct.unpack('<I', self.fh.read(4))[0]
            self.files[name.lower().replace('\\', '/')] = (comp, rsize, psize, off)
        return len(self.files)
    
    def close(self):
        if self.fh:
            self.fh.close()
    
    def get(self, name):
        name = name.lower().replace('\\', '/')
        if name not in self.files:
            return None
        comp, rsize, psize, off = self.files[name]
        self.fh.seek(off)
        data = self.fh.read(psize)
        if comp:
            try:
                data = zlib.decompress(data)
            except:
                pass
        return data


def load_palette(dat_reader):
    """Carrega a paleta de cores do Fallout 2."""
    global FALLOUT_PALETTE
    
    pal_data = dat_reader.get('color.pal')
    if not pal_data:
        print("ERRO: color.pal não encontrado!")
        return False
    
    # Paleta tem 256 cores RGB (768 bytes)
    FALLOUT_PALETTE = []
    for i in range(0, 768, 3):
        r = pal_data[i] * 4  # Fallout usa 0-63, converter para 0-255
        g = pal_data[i+1] * 4
        b = pal_data[i+2] * 4
        FALLOUT_PALETTE.extend([r, g, b])
    
    print(f"✓ Paleta carregada: {len(FALLOUT_PALETTE)//3} cores")
    return True


def pid_to_pro_path(pid):
    """Converte PID para caminho do arquivo PRO."""
    obj_type = (pid >> 24) & 0xFF
    proto_id = pid & 0xFFFF
    
    type_dirs = {
        0: 'proto/items',
        1: 'proto/critters',
        2: 'proto/scenery',
        3: 'proto/walls',
        4: 'proto/tiles',
        5: 'proto/misc',
    }
    
    base_dir = type_dirs.get(obj_type, 'proto/items')
    return f"{base_dir}/{proto_id:08d}.pro"


def read_pro_fid(pro_data):
    """Lê o FID de um arquivo PRO."""
    if len(pro_data) < 8:
        return None
    
    # FID está no offset 4 (depois do PID)
    fid = struct.unpack('<I', pro_data[4:8])[0]
    return fid


def fid_to_frm_path(fid):
    """Converte FID para caminho do arquivo FRM."""
    # FID format no Fallout 2: [Type:4][Flags:12][ID:16]
    fid_type = (fid >> 24) & 0x0F
    fid_id = fid & 0x00000FFF  # 12 bits para ID
    
    type_dirs = {
        0: 'art/items',
        1: 'art/critters',
        2: 'art/scenery',
        3: 'art/walls',
        4: 'art/tiles',
        5: 'art/misc',
        6: 'art/intrface',
    }
    
    base_dir = type_dirs.get(fid_type, 'art/items')
    
    # Critters usam formato especial
    if fid_type == 1:
        # Critters: HMABCD00.FRM
        return f"{base_dir}/{fid_id:06d}.frm"
    else:
        # Outros tipos
        return f"{base_dir}/{fid_id:06d}.frm"


def decode_frm(frm_data):
    """Decodifica arquivo FRM do Fallout 2."""
    if len(frm_data) < 62:
        return None
    
    # Header do FRM
    version = struct.unpack('<I', frm_data[0:4])[0]
    fps = struct.unpack('<H', frm_data[4:6])[0]
    action_frame = struct.unpack('<H', frm_data[6:8])[0]
    frames_per_dir = struct.unpack('<H', frm_data[8:10])[0]
    
    # Shift values
    shift_x = []
    shift_y = []
    for i in range(6):
        sx = struct.unpack('<h', frm_data[10 + i*2:12 + i*2])[0]
        sy = struct.unpack('<h', frm_data[22 + i*2:24 + i*2])[0]
        shift_x.append(sx)
        shift_y.append(sy)
    
    # Frame offsets
    offset = struct.unpack('<I', frm_data[34:38])[0]
    
    # Tamanho do frame
    frame_area = struct.unpack('<I', frm_data[38:42])[0]
    
    # Dimensões do primeiro frame
    width = struct.unpack('<H', frm_data[42:44])[0]
    height = struct.unpack('<H', frm_data[44:46])[0]
    
    if width == 0 or height == 0 or width > 2000 or height > 2000:
        return None
    
    # Dados do pixel (primeiro frame, primeira direção)
    pixel_offset = 62  # Header size
    pixel_data = frm_data[pixel_offset:pixel_offset + width * height]
    
    if len(pixel_data) < width * height:
        return None
    
    return {
        'width': width,
        'height': height,
        'pixels': pixel_data,
        'shift_x': shift_x[0],
        'shift_y': shift_y[0]
    }


def save_as_png(frame_data, output_path):
    """Salva frame como PNG."""
    if not FALLOUT_PALETTE:
        print("ERRO: Paleta não carregada!")
        return False
    
    width = frame_data['width']
    height = frame_data['height']
    pixels = frame_data['pixels']
    
    # Criar imagem RGBA
    img = Image.new('RGBA', (width, height))
    img_data = []
    
    for i in range(len(pixels)):
        color_idx = pixels[i]
        if color_idx == 0:  # Transparente
            img_data.extend([0, 0, 0, 0])
        else:
            r = FALLOUT_PALETTE[color_idx * 3]
            g = FALLOUT_PALETTE[color_idx * 3 + 1]
            b = FALLOUT_PALETTE[color_idx * 3 + 2]
            img_data.extend([r, g, b, 255])
    
    img.putdata([tuple(img_data[i:i+4]) for i in range(0, len(img_data), 4)])
    
    # Salvar
    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path)
    return True


def extract_object_sprites():
    """Extrai sprites de objetos do mapa ARTEMPLE usando PIDs."""
    
    # Caminhos
    fallout2_path = Path("Fallout 2")
    master_dat = fallout2_path / "master.dat"
    critter_dat = fallout2_path / "critter.dat"
    json_path = Path("godot_project/assets/data/maps/artemple.json")
    output_base = Path("godot_project/assets/sprites")
    
    # Verificar arquivos
    if not master_dat.exists():
        print(f"ERRO: {master_dat} não encontrado!")
        return False
    
    if not json_path.exists():
        print(f"ERRO: {json_path} não encontrado!")
        return False
    
    print("=" * 70)
    print("EXTRAÇÃO DE SPRITES DE OBJETOS DO ARTEMPLE (via PID)")
    print("=" * 70)
    
    # Carregar JSON
    print(f"\n1. Carregando {json_path}...")
    with open(json_path) as f:
        map_data = json.load(f)
    
    # Coletar PIDs únicos (exceto misc que são muitos)
    pids = set()
    for obj in map_data['objects']:
        obj_type = obj.get('object_type', '')
        if obj_type != 'misc':  # Pular misc por enquanto
            pids.add(obj['pid'])
    
    print(f"   ✓ {len(pids)} PIDs únicos (sem misc)")
    
    # Abrir DAT files
    print(f"\n2. Abrindo {master_dat}...")
    dat_master = DAT2Reader(master_dat)
    dat_master.open()
    print(f"   ✓ {len(dat_master.files)} arquivos")
    
    dat_critter = None
    if critter_dat.exists():
        print(f"\n3. Abrindo {critter_dat}...")
        dat_critter = DAT2Reader(critter_dat)
        dat_critter.open()
        print(f"   ✓ {len(dat_critter.files)} arquivos")
    
    # Carregar paleta
    print(f"\n4. Carregando paleta...")
    if not load_palette(dat_master):
        return False
    
    # Extrair sprites
    print(f"\n5. Extraindo sprites via PRO files...")
    extracted = 0
    failed = 0
    
    for pid in sorted(pids):
        # Obter caminho do PRO
        pro_path = pid_to_pro_path(pid)
        
        # Ler PRO
        pro_data = dat_master.get(pro_path)
        if not pro_data and dat_critter:
            pro_data = dat_critter.get(pro_path)
        
        if not pro_data:
            print(f"   ✗ PID 0x{pid:08X}: {pro_path} não encontrado")
            failed += 1
            continue
        
        # Extrair FID do PRO
        fid = read_pro_fid(pro_data)
        if not fid:
            print(f"   ✗ PID 0x{pid:08X}: Erro ao ler FID do PRO")
            failed += 1
            continue
        
        # Obter caminho do FRM
        frm_path = fid_to_frm_path(fid)
        
        # Ler FRM
        frm_data = dat_master.get(frm_path)
        if not frm_data and dat_critter:
            frm_data = dat_critter.get(frm_path)
        
        if not frm_data:
            print(f"   ✗ PID 0x{pid:08X}: {frm_path} não encontrado (FID: 0x{fid:08X})")
            failed += 1
            continue
        
        # Decodificar FRM
        frame = decode_frm(frm_data)
        if not frame:
            print(f"   ✗ PID 0x{pid:08X}: Erro ao decodificar FRM")
            failed += 1
            continue
        
        # Determinar pasta de saída
        obj_type = (pid >> 24) & 0xFF
        type_folders = {
            0: 'items',
            1: 'characters',
            2: 'scenery',
            3: 'walls',
        }
        folder = type_folders.get(obj_type, 'misc')
        
        # Salvar PNG
        proto_id = pid & 0xFFFF
        output_path = output_base / folder / f"pid_{pid:08x}.png"
        if save_as_png(frame, output_path):
            print(f"   ✓ PID 0x{pid:08X} → {output_path.relative_to('godot_project')}")
            extracted += 1
        else:
            print(f"   ✗ PID 0x{pid:08X}: Erro ao salvar PNG")
            failed += 1
    
    # Fechar DATs
    dat_master.close()
    if dat_critter:
        dat_critter.close()
    
    # Resumo
    print("\n" + "=" * 70)
    print("RESUMO")
    print("=" * 70)
    print(f"PIDs processados:    {len(pids)}")
    print(f"Sprites extraídos:   {extracted}")
    print(f"Falhas:              {failed}")
    print("=" * 70)
    
    return extracted > 0


if __name__ == '__main__':
    success = extract_object_sprites()
    sys.exit(0 if success else 1)
