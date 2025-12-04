"""
Testes para o módulo dat2_reader.

Inclui testes unitários e property-based tests usando Hypothesis.
"""
import pytest
import struct
import zlib
import tempfile
from pathlib import Path
from hypothesis import given, strategies as st, settings, HealthCheck
from hypothesis.stateful import RuleBasedStateMachine, rule, invariant

from tools.extractors.dat2_reader import DAT2Reader, DAT2Manager, FileInfo


def create_test_dat2(files: dict[str, bytes], compressed: dict[str, bool] = None) -> bytes:
    """
    Cria um arquivo DAT2 sintético para testes.
    
    O formato DAT2 é:
    - Dados dos arquivos (no início)
    - Tabela de entradas (após os dados)
    - Footer: entries_data_size (4 bytes) + dbase_data_size (4 bytes)
    
    O dbase_data_size inclui os dados + tabela de entradas + footer.
    O data_offset é relativo ao início dos dados (que está em file_size - dbase_data_size).
    
    Args:
        files: Dicionário mapeando caminhos para dados
        compressed: Dicionário indicando quais arquivos estão comprimidos
        
    Returns:
        Bytes do arquivo DAT2 criado
    """
    if compressed is None:
        compressed = {}
        
    # Construir dados e entradas
    entries = []
    data_offset = 0
    data_section = b''
    
    for path, data in files.items():
        is_comp = compressed.get(path, False)
        
        # Comprimir se necessário
        if is_comp:
            compressed_data = zlib.compress(data)
        else:
            compressed_data = data
        
        # Adicionar dados
        data_section += compressed_data
            
        # Criar entrada
        path_bytes = path.encode('latin-1')
        entry = struct.pack('<I', len(path_bytes))  # path_length
        entry += path_bytes  # path
        entry += struct.pack('B', 1 if is_comp else 0)  # compressed
        entry += struct.pack('<I', len(data))  # uncompressed_size
        entry += struct.pack('<I', len(compressed_data))  # data_size
        entry += struct.pack('<I', data_offset)  # data_offset (relativo ao início dos dados)
        
        entries.append(entry)
        data_offset += len(compressed_data)
    
    # Construir tabela de entradas
    entries_table = struct.pack('<I', len(entries))  # entries_length
    entries_table += b''.join(entries)
    
    # Calcular tamanhos para o footer
    entries_data_size = len(entries_table)
    # dbase_data_size é o tamanho total dos dados + tabela + footer
    dbase_data_size = len(data_section) + entries_data_size + 8
    
    # Construir arquivo completo
    dat2_file = data_section
    dat2_file += entries_table
    dat2_file += struct.pack('<I', entries_data_size)  # entries_data_size
    dat2_file += struct.pack('<I', dbase_data_size)  # dbase_data_size
    
    return dat2_file


class TestDAT2Reader:
    """Testes unitários para DAT2Reader."""
    
    def test_list_files(self, temp_dir):
        """Testa listagem de arquivos."""
        # Criar DAT2 de teste
        test_files = {
            'data/test1.txt': b'conteudo 1',
            'data/test2.txt': b'conteudo 2',
            'art/sprite.frm': b'frm data'
        }
        
        dat2_data = create_test_dat2(test_files)
        dat2_path = temp_dir / 'test.dat'
        dat2_path.write_bytes(dat2_data)
        
        # Testar listagem
        reader = DAT2Reader(str(dat2_path))
        reader.open()
        files = reader.list_files()
        reader.close()
        
        assert len(files) == 3
        assert 'data/test1.txt' in files
        assert 'data/test2.txt' in files
        assert 'art/sprite.frm' in files
        
    def test_extract_file_uncompressed(self, temp_dir):
        """Testa extração de arquivo não comprimido."""
        test_files = {
            'test.txt': b'conteudo nao comprimido'
        }
        
        dat2_data = create_test_dat2(test_files, compressed={'test.txt': False})
        dat2_path = temp_dir / 'test.dat'
        dat2_path.write_bytes(dat2_data)
        
        reader = DAT2Reader(str(dat2_path))
        reader.open()
        data = reader.extract_file('test.txt')
        reader.close()
        
        assert data == b'conteudo nao comprimido'
        
    def test_extract_file_compressed(self, temp_dir):
        """Testa extração de arquivo comprimido."""
        original_data = b'conteudo comprimido ' * 100
        
        test_files = {
            'test.txt': original_data
        }
        
        dat2_data = create_test_dat2(test_files, compressed={'test.txt': True})
        dat2_path = temp_dir / 'test.dat'
        dat2_path.write_bytes(dat2_data)
        
        reader = DAT2Reader(str(dat2_path))
        reader.open()
        data = reader.extract_file('test.txt')
        reader.close()
        
        assert data == original_data
        
    def test_get_file_info(self, temp_dir):
        """Testa obtenção de informações de arquivo."""
        test_files = {
            'test.txt': b'conteudo'
        }
        
        dat2_data = create_test_dat2(test_files)
        dat2_path = temp_dir / 'test.dat'
        dat2_path.write_bytes(dat2_data)
        
        reader = DAT2Reader(str(dat2_path))
        reader.open()
        info = reader.get_file_info('test.txt')
        reader.close()
        
        assert info is not None
        assert info.name == 'test.txt'
        assert info.path == 'test.txt'
        assert info.size == len(b'conteudo')
        assert isinstance(info.is_compressed, bool)


class TestDAT2PropertyTests:
    """Property-based tests para DAT2Reader."""
    
    @given(
        files=st.dictionaries(
            keys=st.text(min_size=1, max_size=50, alphabet=st.characters(min_codepoint=32, max_codepoint=126)),
            values=st.binary(min_size=1, max_size=1000),
            min_size=1,
            max_size=20
        )
    )
    @settings(max_examples=50, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
    def test_property_1_file_listing_completeness(self, temp_dir, files):
        """
        Property 1: DAT2 File Listing Completeness
        
        Para qualquer arquivo DAT2 válido contendo N arquivos, quando o extrator
        lista o conteúdo, a lista retornada DEVE conter exatamente N entradas
        com caminhos de arquivo corretos.
        """
        # Normalizar caminhos (remover caracteres inválidos)
        normalized_files = {}
        for path, data in files.items():
            # Remover caracteres que podem causar problemas
            clean_path = ''.join(c if c.isprintable() and c not in '<>:"|?*\\' else '_' for c in path)
            if clean_path:
                normalized_files[clean_path] = data
        
        if not normalized_files:
            return  # Skip se não houver arquivos válidos
            
        # Criar DAT2
        dat2_data = create_test_dat2(normalized_files)
        dat2_path = temp_dir / 'test.dat'
        dat2_path.write_bytes(dat2_data)
        
        # Testar listagem
        reader = DAT2Reader(str(dat2_path))
        reader.open()
        listed_files = reader.list_files()
        reader.close()
        
        # Verificar completude
        assert len(listed_files) == len(normalized_files), \
            f"Esperado {len(normalized_files)} arquivos, encontrado {len(listed_files)}"
        
        # Verificar que todos os caminhos estão presentes
        for path in normalized_files.keys():
            assert path in listed_files, f"Caminho {path} não encontrado na listagem"
    
    @given(
        data=st.binary(min_size=1, max_size=500),
        compressed=st.booleans()
    )
    @settings(max_examples=50, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
    def test_property_2_extraction_round_trip(self, temp_dir, data, compressed):
        """
        Property 2: DAT2 Extraction Round-Trip
        
        Para qualquer conteúdo de arquivo comprimido com zlib e armazenado em um
        container DAT2, extrair e descomprimir DEVE produzir conteúdo idêntico
        ao original (byte-identical).
        """
        test_files = {'test.bin': data}
        compressed_dict = {'test.bin': compressed}
        
        dat2_data = create_test_dat2(test_files, compressed=compressed_dict)
        dat2_path = temp_dir / 'test.dat'
        dat2_path.write_bytes(dat2_data)
        
        reader = DAT2Reader(str(dat2_path))
        reader.open()
        extracted_data = reader.extract_file('test.bin')
        reader.close()
        
        # Verificar que os dados são idênticos
        assert extracted_data == data, \
            "Dados extraídos não são idênticos aos dados originais"


class TestDAT2Manager:
    """Testes para DAT2Manager."""
    
    def test_priority_resolution(self, temp_dir):
        """Testa resolução de prioridade entre múltiplos DAT2."""
        # Criar múltiplos DAT2 com o mesmo arquivo
        master_files = {'common.txt': b'from master'}
        critter_files = {'common.txt': b'from critter'}
        patch_files = {'common.txt': b'from patch'}
        
        master_dat = create_test_dat2(master_files)
        critter_dat = create_test_dat2(critter_files)
        patch_dat = create_test_dat2(patch_files)
        
        master_path = temp_dir / 'master.dat'
        critter_path = temp_dir / 'critter.dat'
        patch_path = temp_dir / 'patch000.dat'
        
        master_path.write_bytes(master_dat)
        critter_path.write_bytes(critter_dat)
        patch_path.write_bytes(patch_dat)
        
        # Criar manager
        manager = DAT2Manager([
            str(master_path),
            str(critter_path),
            str(patch_path)
        ])
        
        # Deve retornar do patch (maior prioridade)
        data = manager.get_file('common.txt')
        assert data == b'from patch'
        
        manager.close()
    
    @given(
        files=st.dictionaries(
            keys=st.text(min_size=1, max_size=30, alphabet=st.characters(min_codepoint=32, max_codepoint=126)),
            values=st.binary(min_size=1, max_size=100),
            min_size=1,
            max_size=10
        )
    )
    @settings(max_examples=30, deadline=None, suppress_health_check=[HealthCheck.function_scoped_fixture])
    def test_property_3_priority_resolution(self, temp_dir, files):
        """
        Property 3: DAT2 Priority Resolution
        
        Para qualquer caminho de asset que existe em múltiplos arquivos DAT2,
        o extrator DEVE retornar o conteúdo da fonte com maior prioridade
        (patch000.dat > critter.dat > master.dat).
        """
        # Normalizar arquivos (remover caracteres inválidos para caminhos)
        normalized_files = {}
        for path, data in files.items():
            clean_path = ''.join(c if c.isprintable() and c not in '<>:"|?*\\/' else '_' for c in path)
            if clean_path and clean_path.strip():
                normalized_files[clean_path] = data
        
        if not normalized_files:
            return
            
        # Criar DAT2s com diferentes prioridades
        master_files = {path: data + b'_master' for path, data in normalized_files.items()}
        critter_files = {path: data + b'_critter' for path, data in normalized_files.items()}
        patch_files = {path: data + b'_patch' for path, data in normalized_files.items()}
        
        master_dat = create_test_dat2(master_files)
        critter_dat = create_test_dat2(critter_files)
        patch_dat = create_test_dat2(patch_files)
        
        master_path = temp_dir / 'master.dat'
        critter_path = temp_dir / 'critter.dat'
        patch_path = temp_dir / 'patch000.dat'
        
        master_path.write_bytes(master_dat)
        critter_path.write_bytes(critter_dat)
        patch_path.write_bytes(patch_dat)
        
        # Testar todas as combinações de ordem
        for order in [
            [master_path, critter_path, patch_path],
            [patch_path, master_path, critter_path],
            [critter_path, patch_path, master_path],
        ]:
            manager = DAT2Manager([str(p) for p in order])
            
            for path in normalized_files.keys():
                data = manager.get_file(path)
                # Sempre deve retornar do patch (maior prioridade)
                assert data == normalized_files[path] + b'_patch', \
                    f"Arquivo {path} não retornou da fonte com maior prioridade"
            
            manager.close()

