#!/usr/bin/env python3
"""
Extrator de Arquivos .DAT do Fallout 2
Baseado no código de src/dfile.cc
"""

import struct
import os
import zlib
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"

class DATExtractor:
    """Extrator de arquivos .DAT"""
    
    def __init__(self, dat_path):
        self.dat_path = Path(dat_path)
        self.stream = None
        self.entries = []
        self.data_offset = 0
        
    def open(self):
        """Abre o arquivo .DAT"""
        if not self.dat_path.exists():
            raise FileNotFoundError(f"Arquivo não encontrado: {self.dat_path}")
        
        self.stream = open(self.dat_path, 'rb')
        return True
    
    def close(self):
        """Fecha o arquivo"""
        if self.stream:
            self.stream.close()
            self.stream = None
    
    def read_entries(self):
        """Lê a tabela de entradas do .DAT"""
        if not self.stream:
            raise RuntimeError("Arquivo não aberto")
        
        # Ir para o final do arquivo para ler o footer
        self.stream.seek(0, 2)  # SEEK_END
        file_size = self.stream.tell()
        
        # Ler footer: entriesDataSize (4 bytes) + dbaseDataSize (4 bytes)
        self.stream.seek(file_size - 8, 0)
        entries_data_size = struct.unpack('<I', self.stream.read(4))[0]
        dbase_data_size = struct.unpack('<I', self.stream.read(4))[0]
        
        # Ir para o início da tabela de entradas
        entries_table_start = file_size - entries_data_size - 8
        self.stream.seek(entries_table_start, 0)
        
        # Ler número de entradas
        entries_length = struct.unpack('<I', self.stream.read(4))[0]
        
        # Ler cada entrada
        self.entries = []
        for i in range(entries_length):
            # Ler tamanho do caminho
            path_length = struct.unpack('<I', self.stream.read(4))[0]
            
            # Ler caminho
            path_bytes = self.stream.read(path_length)
            path = path_bytes.decode('latin-1', errors='ignore')
            
            # Ler flags
            compressed = struct.unpack('B', self.stream.read(1))[0]
            uncompressed_size = struct.unpack('<I', self.stream.read(4))[0]
            data_size = struct.unpack('<I', self.stream.read(4))[0]
            data_offset = struct.unpack('<I', self.stream.read(4))[0]
            
            self.entries.append({
                'path': path,
                'compressed': compressed,
                'uncompressed_size': uncompressed_size,
                'data_size': data_size,
                'data_offset': data_offset
            })
        
        # Calcular offset dos dados
        self.data_offset = file_size - dbase_data_size
        
        return len(self.entries)
    
    def extract_file(self, entry, output_path):
        """Extrai um arquivo do .DAT"""
        if not self.stream:
            raise RuntimeError("Arquivo não aberto")
        
        # Criar diretório de destino
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Ir para a posição dos dados
        actual_offset = self.data_offset + entry['data_offset']
        self.stream.seek(actual_offset, 0)
        
        # Ler dados
        data = self.stream.read(entry['data_size'])
        
        # Descomprimir se necessário
        if entry['compressed'] == 1:
            try:
                data = zlib.decompress(data)
            except zlib.error as e:
                print(f"    ⚠️  Erro ao descomprimir {entry['path']}: {e}")
                return False
        
        # Salvar arquivo
        with open(output_path, 'wb') as f:
            f.write(data)
        
        return True
    
    def extract_all(self, output_dir, filter_pattern=None):
        """Extrai todos os arquivos"""
        if not self.stream:
            raise RuntimeError("Arquivo não aberto")
        
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        extracted = []
        skipped = []
        
        for entry in self.entries:
            # Filtrar por padrão se especificado
            if filter_pattern:
                if filter_pattern not in entry['path'].lower():
                    continue
            
            # Construir caminho de saída
            output_path = output_dir / entry['path'].replace('\\', '/')
            
            # Extrair
            try:
                if self.extract_file(entry, output_path):
                    extracted.append(entry['path'])
                    print(f"  ✅ {entry['path']}")
                else:
                    skipped.append(entry['path'])
            except Exception as e:
                print(f"  ❌ Erro ao extrair {entry['path']}: {e}")
                skipped.append(entry['path'])
        
        return extracted, skipped

def main():
    """Função principal"""
    print("=" * 60)
    print("📦 Extrator de Arquivos .DAT - Fallout 2")
    print("=" * 60)
    
    # Arquivos .DAT para extrair
    dat_files = {
        'critter.dat': {
            'path': FALLOUT_DIR / 'critter.dat',
            'output': EXTRACTED_DIR / 'critter',
            'filter': '.frm'  # Apenas sprites
        },
        'master.dat': {
            'path': FALLOUT_DIR / 'master.dat',
            'output': EXTRACTED_DIR / 'master',
            'filter': '.frm'  # Apenas sprites
        }
    }
    
    for dat_name, config in dat_files.items():
        dat_path = config['path']
        
        if not dat_path.exists():
            print(f"\n⚠️  {dat_name} não encontrado: {dat_path}")
            continue
        
        print(f"\n📂 Processando: {dat_name}")
        print(f"   Tamanho: {dat_path.stat().st_size / (1024*1024):.2f} MB")
        
        extractor = DATExtractor(dat_path)
        
        try:
            # Abrir
            extractor.open()
            
            # Ler entradas
            print("   Lendo tabela de entradas...")
            count = extractor.read_entries()
            print(f"   ✅ {count} arquivos encontrados")
            
            # Filtrar apenas .FRM
            frm_entries = [e for e in extractor.entries if e['path'].lower().endswith('.frm')]
            print(f"   🎨 {len(frm_entries)} arquivos .FRM encontrados")
            
            if len(frm_entries) == 0:
                print("   ⚠️  Nenhum arquivo .FRM encontrado")
                extractor.close()
                continue
            
            # Extrair
            print(f"\n   🔄 Extraindo sprites...")
            output_dir = config['output']
            extracted, skipped = extractor.extract_all(output_dir, filter_pattern='.frm')
            
            print(f"\n   ✅ {len(extracted)} arquivos extraídos")
            if skipped:
                print(f"   ⚠️  {len(skipped)} arquivos ignorados")
            
            extractor.close()
            
        except Exception as e:
            print(f"   ❌ Erro: {e}")
            import traceback
            traceback.print_exc()
            extractor.close()
    
    print("\n" + "=" * 60)
    print("✅ Extração concluída!")
    print(f"📁 Arquivos extraídos em: {EXTRACTED_DIR}")
    print("\n💡 Próximo passo: Converter para PNG")
    print("   python web_server/frm_to_png.py")

if __name__ == "__main__":
    main()

