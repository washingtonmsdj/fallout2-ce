#!/usr/bin/env python3
"""
Extrator e Organizador COMPLETO de TODOS os Arquivos .DAT
Extrai TUDO e organiza de forma estruturada para análise e edição
"""

import struct
import os
import zlib
import json
import shutil
from pathlib import Path
from collections import defaultdict

BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
ORGANIZED_DIR = BASE_DIR / "web_server" / "assets" / "organized"

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

def get_file_category(path):
    """Categoriza arquivo por tipo"""
    path_lower = path.lower()
    ext = Path(path).suffix.lower()
    
    # Por extensão
    if ext == '.frm':
        if 'critter' in path_lower or 'art/critters' in path_lower:
            return 'sprites/critters'
        elif 'item' in path_lower or 'art/items' in path_lower:
            return 'sprites/items'
        elif 'tile' in path_lower or 'art/tiles' in path_lower:
            return 'sprites/tiles'
        elif 'wall' in path_lower or 'art/walls' in path_lower:
            return 'sprites/walls'
        elif 'scenery' in path_lower or 'art/scenery' in path_lower:
            return 'sprites/scenery'
        elif 'interface' in path_lower or 'art/intrface' in path_lower:
            return 'sprites/interface'
        elif 'inven' in path_lower or 'art/inven' in path_lower:
            return 'sprites/inventory'
        elif 'head' in path_lower or 'art/heads' in path_lower:
            return 'sprites/heads'
        elif 'backgrnd' in path_lower or 'art/backgrnd' in path_lower:
            return 'sprites/backgrounds'
        else:
            return 'sprites/other'
    
    elif ext == '.map':
        return 'maps'
    
    elif ext == '.msg':
        if 'quest' in path_lower:
            return 'texts/quests'
        elif 'item' in path_lower:
            return 'texts/items'
        elif 'misc' in path_lower:
            return 'texts/misc'
        else:
            return 'texts'
    
    elif ext == '.int':
        return 'scripts'
    
    elif ext == '.pro':
        if 'critter' in path_lower:
            return 'prototypes/critters'
        elif 'item' in path_lower:
            return 'prototypes/items'
        else:
            return 'prototypes'
    
    elif ext == '.acm':
        return 'audio/music'
    
    elif ext == '.wav' or ext == '.voc':
        return 'audio/sounds'
    
    elif ext == '.dat':
        return 'data'
    
    elif ext == '.txt':
        return 'texts'
    
    elif ext == '.lst':
        return 'lists'
    
    else:
        return 'other'

def organize_files(extracted_dir, organized_dir):
    """Organiza arquivos extraídos em estrutura lógica"""
    print("\n" + "=" * 70)
    print("📁 Organizando arquivos extraídos...")
    print("=" * 70)
    
    organized_dir.mkdir(parents=True, exist_ok=True)
    
    stats = defaultdict(int)
    organized = 0
    skipped = 0
    
    # Processar todos os arquivos extraídos
    for file_path in extracted_dir.rglob('*'):
        if file_path.is_file():
            try:
                # Manter estrutura relativa
                rel_path = file_path.relative_to(extracted_dir)
                
                # Determinar categoria
                category = get_file_category(str(rel_path))
                
                # Caminho organizado
                file_name = file_path.name
                organized_path = organized_dir / category / file_name
                
                # Se já existe, adicionar número
                counter = 1
                while organized_path.exists():
                    stem = file_path.stem
                    ext = file_path.suffix
                    organized_path = organized_dir / category / f"{stem}_{counter}{ext}"
                    counter += 1
                
                # Copiar arquivo
                organized_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(file_path, organized_path)
                
                stats[category] += 1
                organized += 1
                
                if organized % 100 == 0:
                    print(f"  📊 Organizados: {organized} arquivos...")
                    
            except Exception as e:
                print(f"  ⚠️  Erro ao organizar {file_path}: {e}")
                skipped += 1
    
    # Criar índice
    index = {
        'total_files': organized,
        'categories': dict(stats),
        'structure': {}
    }
    
    # Mapear estrutura
    for category in stats.keys():
        category_path = organized_dir / category
        if category_path.exists():
            files = list(category_path.glob('*'))
            index['structure'][category] = {
                'count': len(files),
                'files': [f.name for f in files[:50]]  # Primeiros 50
            }
    
    # Salvar índice
    with open(organized_dir / 'index.json', 'w', encoding='utf-8') as f:
        json.dump(index, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Organização concluída!")
    print(f"   ✅ {organized} arquivos organizados")
    print(f"   ⚠️  {skipped} arquivos ignorados")
    print(f"\n📊 Estatísticas por categoria:")
    for category, count in sorted(stats.items()):
        print(f"   {category:30} : {count:6} arquivos")
    
    return organized, skipped, stats

def main():
    """Função principal"""
    print("=" * 70)
    print("📦 EXTRATOR E ORGANIZADOR COMPLETO - Fallout 2")
    print("=" * 70)
    print("\n⚠️  ATENÇÃO: Isso vai extrair e organizar TODOS os arquivos!")
    print("   Pode levar vários minutos e ocupar bastante espaço.\n")
    
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
    
    # FASE 1: EXTRAIR
    print("\n" + "=" * 70)
    print("FASE 1: EXTRAÇÃO")
    print("=" * 70)
    
    for dat_name, config in dat_files.items():
        dat_path = config['path']
        
        if not dat_path.exists():
            print(f"\n⚠️  {dat_name} não encontrado: {dat_path}")
            continue
        
        print(f"\n📂 Processando: {dat_name}")
        print(f"   Tamanho: {dat_path.stat().st_size / (1024*1024):.2f} MB")
        
        extractor = DATExtractor(dat_path)
        
        try:
            extractor.open()
            
            print("   📖 Lendo tabela de entradas...")
            count = extractor.read_entries()
            print(f"   ✅ {count} arquivos encontrados")
            
            if count == 0:
                extractor.close()
                continue
            
            print(f"   🔄 Extraindo TODOS os arquivos...")
            
            output_dir = config['output']
            extracted = 0
            skipped = 0
            stats = defaultdict(int)
            
            total = len(extractor.entries)
            for idx, entry in enumerate(extractor.entries):
                if (idx + 1) % 100 == 0:
                    print(f"      Progresso: {idx + 1}/{total} ({100 * (idx + 1) / total:.1f}%)")
                
                ext = Path(entry['path']).suffix.lower()
                stats[ext] += 1
                
                output_path = output_dir / entry['path'].replace('\\', '/')
                
                try:
                    if extractor.extract_file(entry, output_path):
                        extracted += 1
                    else:
                        skipped += 1
                except Exception as e:
                    skipped += 1
                    if idx < 10:  # Mostrar primeiros erros
                        print(f"      ⚠️  Erro: {entry['path']}")
            
            for ext, count in stats.items():
                all_stats[ext] += count
            
            total_extracted += extracted
            total_skipped += skipped
            
            print(f"   ✅ {extracted} arquivos extraídos")
            if skipped > 0:
                print(f"   ⚠️  {skipped} arquivos com problemas")
            
            extractor.close()
            
        except Exception as e:
            print(f"   ❌ Erro: {e}")
            import traceback
            traceback.print_exc()
            extractor.close()
    
    # FASE 2: ORGANIZAR
    print("\n" + "=" * 70)
    print("FASE 2: ORGANIZAÇÃO")
    print("=" * 70)
    
    organized, org_skipped, org_stats = organize_files(EXTRACTED_DIR, ORGANIZED_DIR)
    
    # RESUMO FINAL
    print("\n" + "=" * 70)
    print("✅ PROCESSO COMPLETO!")
    print("=" * 70)
    print(f"\n📊 RESUMO:")
    print(f"   ✅ Total extraído: {total_extracted} arquivos")
    print(f"   ✅ Total organizado: {organized} arquivos")
    print(f"   ⚠️  Total com problemas: {total_skipped + org_skipped} arquivos")
    
    print(f"\n📁 ESTRUTURA ORGANIZADA:")
    print(f"   {ORGANIZED_DIR}")
    print(f"\n   📂 Categorias criadas:")
    for category in sorted(org_stats.keys()):
        print(f"      {category}/")
    
    print(f"\n💡 Próximos passos:")
    print(f"   1. Visualizar: http://localhost:8000/fallout_game_web.html")
    print(f"   2. Editar: Todos os arquivos estão em {ORGANIZED_DIR}")
    print(f"   3. Analisar: Use as ferramentas web para explorar")

if __name__ == "__main__":
    main()

