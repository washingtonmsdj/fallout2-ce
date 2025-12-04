#!/usr/bin/env python3
"""
Extrator COMPLETO de TODOS os Arquivos .DAT do Fallout 2
Extrai TUDO: .FRM, .MAP, .MSG, .INT, .PRO, .ACM, etc.
"""

import struct
import os
import zlib
from pathlib import Path
from collections import defaultdict

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
        stats = defaultdict(int)
        
        total = len(self.entries)
        for idx, entry in enumerate(self.entries):
            # Filtrar por padrão se especificado
            if filter_pattern:
                if filter_pattern not in entry['path'].lower():
                    continue
            
            # Estatísticas por extensão
            ext = Path(entry['path']).suffix.lower()
            stats[ext] += 1
            
            # Construir caminho de saída
            output_path = output_dir / entry['path'].replace('\\', '/')
            
            # Progresso
            if (idx + 1) % 100 == 0:
                print(f"  📊 Progresso: {idx + 1}/{total} ({100 * (idx + 1) / total:.1f}%)")
            
            # Extrair
            try:
                if self.extract_file(entry, output_path):
                    extracted.append(entry['path'])
                else:
                    skipped.append(entry['path'])
            except Exception as e:
                print(f"  ❌ Erro ao extrair {entry['path']}: {e}")
                skipped.append(entry['path'])
        
        return extracted, skipped, stats

def main():
    """Função principal - Extrai TUDO"""
    print("=" * 70)
    print("📦 EXTRATOR COMPLETO - TODOS os Arquivos .DAT do Fallout 2")
    print("=" * 70)
    print("\n⚠️  ATENÇÃO: Isso vai extrair TODOS os arquivos!")
    print("   Pode levar vários minutos e ocupar bastante espaço em disco.\n")
    
    # Arquivos .DAT para extrair
    dat_files = {
        'critter.dat': {
            'path': FALLOUT_DIR / 'critter.dat',
            'output': EXTRACTED_DIR / 'critter',
        },
        'master.dat': {
            'path': FALLOUT_DIR / 'master.dat',
            'output': EXTRACTED_DIR / 'master',
        },
        'patch000.dat': {
            'path': FALLOUT_DIR / 'patch000.dat',
            'output': EXTRACTED_DIR / 'patch000',
        },
        'f2_res.dat': {
            'path': FALLOUT_DIR / 'f2_res.dat',
            'output': EXTRACTED_DIR / 'f2_res',
        }
    }
    
    all_stats = defaultdict(int)
    total_extracted = 0
    total_skipped = 0
    
    for dat_name, config in dat_files.items():
        dat_path = config['path']
        
        if not dat_path.exists():
            print(f"\n⚠️  {dat_name} não encontrado: {dat_path}")
            continue
        
        print(f"\n{'='*70}")
        print(f"📂 Processando: {dat_name}")
        print(f"   Tamanho: {dat_path.stat().st_size / (1024*1024):.2f} MB")
        print(f"   Destino: {config['output']}")
        
        extractor = DATExtractor(dat_path)
        
        try:
            # Abrir
            extractor.open()
            
            # Ler entradas
            print("   📖 Lendo tabela de entradas...")
            count = extractor.read_entries()
            print(f"   ✅ {count} arquivos encontrados no .DAT")
            
            if count == 0:
                print("   ⚠️  Nenhum arquivo encontrado")
                extractor.close()
                continue
            
            # Extrair TUDO (sem filtro)
            print(f"\n   🔄 Extraindo TODOS os arquivos...")
            print(f"   ⏳ Isso pode levar alguns minutos...\n")
            
            output_dir = config['output']
            extracted, skipped, stats = extractor.extract_all(output_dir, filter_pattern=None)
            
            # Atualizar estatísticas globais
            for ext, count in stats.items():
                all_stats[ext] += count
            
            total_extracted += len(extracted)
            total_skipped += len(skipped)
            
            print(f"\n   ✅ {len(extracted)} arquivos extraídos com sucesso")
            if skipped:
                print(f"   ⚠️  {len(skipped)} arquivos com problemas")
            
            # Mostrar estatísticas por tipo
            print(f"\n   📊 Estatísticas por tipo de arquivo:")
            for ext in sorted(stats.keys()):
                print(f"      {ext or '(sem extensão)':15} : {stats[ext]:6} arquivos")
            
            extractor.close()
            
        except Exception as e:
            print(f"   ❌ Erro: {e}")
            import traceback
            traceback.print_exc()
            extractor.close()
    
    # Resumo final
    print("\n" + "=" * 70)
    print("✅ EXTRAÇÃO COMPLETA!")
    print("=" * 70)
    print(f"\n📊 RESUMO GERAL:")
    print(f"   ✅ Total extraído: {total_extracted} arquivos")
    print(f"   ⚠️  Total com problemas: {total_skipped} arquivos")
    print(f"\n📁 Arquivos extraídos em: {EXTRACTED_DIR}")
    
    print(f"\n📊 ESTATÍSTICAS POR TIPO DE ARQUIVO:")
    print(f"   {'Extensão':15} {'Quantidade':>12}")
    print(f"   {'-'*15} {'-'*12}")
    for ext in sorted(all_stats.keys(), key=lambda x: all_stats[x], reverse=True):
        print(f"   {ext or '(sem extensão)':15} {all_stats[ext]:>12}")
    
    print(f"\n💡 Próximos passos:")
    print(f"   1. Visualizar no navegador: http://localhost:8000/asset_viewer.html")
    print(f"   2. Converter sprites .FRM para PNG: python web_server/frm_to_png.py")
    print(f"   3. Explorar mapas, scripts e outros assets")

if __name__ == "__main__":
    main()

