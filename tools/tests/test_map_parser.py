"""
Testes para o módulo map_parser.

Inclui testes unitários e property-based tests usando Hypothesis.
"""
import pytest
import struct
import json
import tempfile
import os
from pathlib import Path
from hypothesis import given, strategies as st, settings

from tools.extractors.map_parser import MAPParser, MapData, MapObject


def create_test_map(
    version: int = 19,
    name: str = "testmap",
    entering_tile: int = 100,
    entering_elevation: int = 0,
    entering_rotation: int = 0,
    local_vars: int = 10,
    script_index: int = 1,
    flags: int = 0,
    darkness: int = 0,
    global_vars: int = 5,
    map_index: int = 1,
    last_visit: int = 0
) -> bytes:
    """
    Cria um arquivo MAP sintético para testes.
    
    Args:
        version: Versão do mapa
        name: Nome do mapa (max 16 chars)
        entering_tile: Tile de entrada
        entering_elevation: Elevação de entrada
        entering_rotation: Rotação de entrada
        local_vars: Número de variáveis locais
        script_index: Índice do script
        flags: Flags do mapa
        darkness: Nível de escuridão
        global_vars: Número de variáveis globais
        map_index: Índice do mapa
        last_visit: Timestamp da última visita
        
    Returns:
        Bytes do arquivo MAP criado
    """
    data = b''
    
    # Version (4 bytes)
    data += struct.pack('<I', version)
    
    # Name (16 bytes, padded with nulls)
    name_bytes = name.encode('latin-1')[:16]
    name_bytes = name_bytes.ljust(16, b'\x00')
    data += name_bytes
    
    # Entering tile, elevation, rotation (4 bytes each)
    data += struct.pack('<I', entering_tile)
    data += struct.pack('<I', entering_elevation)
    data += struct.pack('<I', entering_rotation)
    
    # Local variables count
    data += struct.pack('<I', local_vars)
    
    # Script index
    data += struct.pack('<I', script_index)
    
    # Flags
    data += struct.pack('<I', flags)
    
    # Darkness
    data += struct.pack('<I', darkness)
    
    # Global variables count
    data += struct.pack('<I', global_vars)
    
    # Map index
    data += struct.pack('<I', map_index)
    
    # Last visit time
    data += struct.pack('<I', last_visit)
    
    # Reserved fields (44 * 4 bytes)
    data += b'\x00' * (44 * 4)
    
    return data


class TestMAPParser:
    """Testes unitários para MAPParser."""
    
    def test_parse_simple_map(self):
        """Testa parsing de mapa simples."""
        map_data = create_test_map(name="testmap", version=19)
        
        parser = MAPParser()
        parsed = parser.parse(map_data)
        
        assert parsed.version == 19
        assert parsed.name == "testmap"
    
    def test_parse_map_with_script(self):
        """Testa parsing de mapa com script."""
        map_data = create_test_map(script_index=42)
        
        parser = MAPParser()
        parsed = parser.parse(map_data)
        
        assert parsed.script_index == 42
        assert len(parsed.scripts) == 1
        assert "script_42.int" in parsed.scripts[0]
    
    def test_to_json_creates_file(self):
        """Testa que to_json cria arquivo JSON."""
        map_data = create_test_map(name="jsontest")
        
        parser = MAPParser()
        parsed = parser.parse(map_data)
        
        with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as f:
            output_path = f.name
        
        try:
            parser.to_json(parsed, output_path)
            
            assert os.path.exists(output_path)
            
            with open(output_path, 'r', encoding='utf-8') as f:
                loaded = json.load(f)
            
            assert loaded['name'] == 'jsontest'
            assert 'tiles' in loaded
            assert 'objects' in loaded
            assert 'scripts' in loaded
        finally:
            os.unlink(output_path)


class TestMAPPropertyTests:
    """Property-based tests para MAPParser."""
    
    @given(
        version=st.integers(min_value=1, max_value=100),
        name=st.text(min_size=1, max_size=15, alphabet=st.characters(min_codepoint=32, max_codepoint=126)),
        entering_tile=st.integers(min_value=0, max_value=40000),
        entering_elevation=st.integers(min_value=0, max_value=2),
        script_index=st.integers(min_value=0, max_value=1000),
        local_vars=st.integers(min_value=0, max_value=100),
        global_vars=st.integers(min_value=0, max_value=100)
    )
    @settings(max_examples=100)
    def test_property_12_map_data_completeness(self, version, name, entering_tile, 
                                               entering_elevation, script_index,
                                               local_vars, global_vars):
        """
        **Feature: fallout2-asset-extraction, Property 12: MAP Data Completeness**
        
        Para qualquer arquivo MAP, o JSON exportado DEVE conter arrays de tiles válidos,
        arrays de objetos, e referências de scripts correspondentes aos dados originais.
        
        **Validates: Requirements 7.1, 7.2, 7.3**
        """
        # Criar mapa de teste
        map_bytes = create_test_map(
            version=version,
            name=name,
            entering_tile=entering_tile,
            entering_elevation=entering_elevation,
            script_index=script_index,
            local_vars=local_vars,
            global_vars=global_vars
        )
        
        parser = MAPParser()
        parsed = parser.parse(map_bytes)
        
        # Verificar que os dados foram parseados corretamente
        assert parsed.version == version, \
            f"Versão incorreta: {parsed.version} != {version}"
        assert parsed.name == name, \
            f"Nome incorreto: {parsed.name} != {name}"
        assert parsed.entering_tile == entering_tile, \
            f"Entering tile incorreto: {parsed.entering_tile} != {entering_tile}"
        assert parsed.entering_elevation == entering_elevation, \
            f"Entering elevation incorreto: {parsed.entering_elevation} != {entering_elevation}"
        assert parsed.script_index == script_index, \
            f"Script index incorreto: {parsed.script_index} != {script_index}"
        assert parsed.local_variables_count == local_vars, \
            f"Local vars incorreto: {parsed.local_variables_count} != {local_vars}"
        assert parsed.global_variables_count == global_vars, \
            f"Global vars incorreto: {parsed.global_variables_count} != {global_vars}"
        
        # Verificar estrutura de tiles
        assert isinstance(parsed.tiles, list), "Tiles deve ser uma lista"
        assert len(parsed.tiles) == parsed.num_levels, \
            f"Número de níveis de tiles incorreto: {len(parsed.tiles)} != {parsed.num_levels}"
        
        # Verificar estrutura de objetos
        assert isinstance(parsed.objects, list), "Objects deve ser uma lista"
        
        # Verificar scripts
        assert isinstance(parsed.scripts, list), "Scripts deve ser uma lista"
        if script_index > 0:
            assert len(parsed.scripts) >= 1, "Deve haver pelo menos um script se script_index > 0"
    
    @given(
        version=st.integers(min_value=1, max_value=50),
        name=st.text(min_size=1, max_size=10, alphabet=st.characters(min_codepoint=65, max_codepoint=90))
    )
    @settings(max_examples=50)
    def test_property_12_json_roundtrip(self, version, name):
        """
        **Feature: fallout2-asset-extraction, Property 12: MAP to JSON Round-Trip**
        
        Para qualquer mapa parseado, exportar para JSON e carregar de volta
        DEVE preservar todos os campos principais.
        
        **Validates: Requirements 7.1, 7.2, 7.3**
        """
        # Criar mapa de teste
        map_bytes = create_test_map(version=version, name=name)
        
        parser = MAPParser()
        parsed = parser.parse(map_bytes)
        
        with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as f:
            output_path = f.name
        
        try:
            # Exportar para JSON
            parser.to_json(parsed, output_path)
            
            # Carregar de volta
            with open(output_path, 'r', encoding='utf-8') as f:
                loaded = json.load(f)
            
            # Verificar campos principais
            assert loaded['version'] == version, \
                f"Versão não preservada: {loaded['version']} != {version}"
            assert loaded['name'] == name, \
                f"Nome não preservado: {loaded['name']} != {name}"
            assert 'tiles' in loaded, "Falta campo 'tiles'"
            assert 'objects' in loaded, "Falta campo 'objects'"
            assert 'scripts' in loaded, "Falta campo 'scripts'"
            assert 'entering' in loaded, "Falta campo 'entering'"
            assert 'variables' in loaded, "Falta campo 'variables'"
        finally:
            os.unlink(output_path)
