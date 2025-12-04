#!/usr/bin/env python3
"""
Conversor de Mapas .MAP do Fallout 2 para Visualização Web
Converte mapas para JSON que pode ser visualizado no navegador
"""

import struct
import json
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
WEB_ASSETS = BASE_DIR / "web_server" / "assets" / "web"

class MapConverter:
    """Converte mapas .MAP para formato web"""
    
    def __init__(self, map_path):
        self.map_path = Path(map_path)
        self.stream = None
        self.header = {}
        self.tiles = []
        self.objects = []
        
    def open(self):
        """Abre o arquivo .MAP"""
        if not self.map_path.exists():
            raise FileNotFoundError(f"Mapa não encontrado: {self.map_path}")
        
        self.stream = open(self.map_path, 'rb')
        return True
    
    def close(self):
        """Fecha o arquivo"""
        if self.stream:
            self.stream.close()
            self.stream = None
    
    def read_header(self):
        """Lê o header do mapa"""
        if not self.stream:
            raise RuntimeError("Arquivo não aberto")
        
        # Versão do mapa (19 ou 20)
        version = struct.unpack('<I', self.stream.read(4))[0]
        
        # Nome do mapa (16 bytes)
        name_bytes = self.stream.read(16)
        name = name_bytes.decode('latin-1', errors='ignore').rstrip('\x00')
        
        # Variáveis globais e locais
        global_vars_count = struct.unpack('<I', self.stream.read(4))[0]
        local_vars_count = struct.unpack('<I', self.stream.read(4))[0]
        
        # Flags
        flags = struct.unpack('<I', self.stream.read(4))[0]
        
        # Informações de entrada
        entering_elevation = struct.unpack('<I', self.stream.read(4))[0]
        entering_tile = struct.unpack('<I', self.stream.read(4))[0]
        entering_rotation = struct.unpack('<I', self.stream.read(4))[0]
        
        # Script index
        script_index = struct.unpack('<I', self.stream.read(4))[0]
        
        self.header = {
            'version': version,
            'name': name,
            'global_vars_count': global_vars_count,
            'local_vars_count': local_vars_count,
            'flags': flags,
            'entering_elevation': entering_elevation,
            'entering_tile': entering_tile,
            'entering_rotation': entering_rotation,
            'script_index': script_index
        }
        
        return self.header
    
    def read_tiles_simple(self):
        """Lê informações básicas dos tiles"""
        # Esta é uma versão simplificada
        # O formato completo é muito complexo
        tiles = []
        
        # Por enquanto, retornamos estrutura básica
        # Para implementação completa, ver src/map.cc e src/tile.cc
        return tiles
    
    def convert_to_json(self):
        """Converte o mapa para JSON"""
        data = {
            'header': self.header,
            'tiles': self.tiles,
            'objects': self.objects,
            'metadata': {
                'source_file': str(self.map_path.name),
                'converted': True
            }
        }
        
        return json.dumps(data, indent=2, ensure_ascii=False)

def find_maps():
    """Encontra todos os mapas extraídos"""
    maps = []
    
    # Procurar em master.dat extraído
    master_maps = list(EXTRACTED_DIR.glob('master/data/maps/**/*.MAP'))
    master_maps += list(EXTRACTED_DIR.glob('master/data/maps/**/*.map'))
    
    # Procurar em outras pastas
    for pattern in ['**/*.MAP', '**/*.map']:
        maps.extend(EXTRACTED_DIR.glob(pattern))
    
    # Filtrar apenas mapas (não outros arquivos)
    maps = [m for m in maps if m.suffix.upper() == '.MAP']
    
    return maps

def main():
    """Função principal"""
    print("=" * 70)
    print("🗺️  Conversor de Mapas .MAP para Visualização Web")
    print("=" * 70)
    
    # Criar diretório de saída
    WEB_ASSETS.mkdir(parents=True, exist_ok=True)
    maps_dir = WEB_ASSETS / "maps"
    maps_dir.mkdir(exist_ok=True)
    
    # Encontrar mapas
    print("\n🔍 Procurando mapas...")
    maps = find_maps()
    
    if not maps:
        print("⚠️  Nenhum mapa encontrado!")
        print("   Execute primeiro: python web_server/extract_all_dat.py")
        return
    
    print(f"✅ {len(maps)} mapas encontrados\n")
    
    converted = 0
    failed = 0
    
    for map_path in maps[:10]:  # Limitar a 10 para teste
        try:
            print(f"📂 Processando: {map_path.name}")
            
            converter = MapConverter(map_path)
            converter.open()
            
            # Ler header
            header = converter.read_header()
            
            # Criar JSON simplificado
            map_data = {
                'header': header,
                'metadata': {
                    'source_file': map_path.name,
                    'path': str(map_path.relative_to(EXTRACTED_DIR))
                }
            }
            
            # Salvar JSON
            output_file = maps_dir / f"{map_path.stem}.json"
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(map_data, f, indent=2, ensure_ascii=False)
            
            print(f"   ✅ Convertido: {output_file.name}")
            converted += 1
            
            converter.close()
            
        except Exception as e:
            print(f"   ❌ Erro: {e}")
            failed += 1
    
    # Criar índice
    index = {
        'maps': [],
        'total': len(maps),
        'converted': converted,
        'failed': failed
    }
    
    for json_file in maps_dir.glob('*.json'):
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            index['maps'].append({
                'name': data['header']['name'],
                'file': json_file.name,
                'version': data['header']['version']
            })
    
    # Salvar índice
    with open(maps_dir / 'index.json', 'w', encoding='utf-8') as f:
        json.dump(index, f, indent=2, ensure_ascii=False)
    
    print("\n" + "=" * 70)
    print(f"✅ Conversão concluída!")
    print(f"   ✅ {converted} mapas convertidos")
    print(f"   ❌ {failed} mapas com erro")
    print(f"📁 Arquivos salvos em: {maps_dir}")
    print("\n💡 Próximo passo:")
    print(f"   Abra: http://localhost:8000/map_viewer.html")

if __name__ == "__main__":
    main()

