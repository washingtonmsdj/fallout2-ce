"""
Testes para o módulo msg_parser.

Inclui testes unitários e property-based tests usando Hypothesis.
"""
import pytest
import json
import tempfile
import os
from pathlib import Path
from hypothesis import given, strategies as st, settings, assume

from tools.extractors.msg_parser import MSGParser


def create_msg_file(messages: dict) -> bytes:
    """
    Cria um arquivo MSG sintético para testes.
    
    Args:
        messages: Dicionário mapeando IDs para textos
        
    Returns:
        Bytes do arquivo MSG criado
    """
    content = ""
    for msg_id, text in sorted(messages.items()):
        content += f"{{{msg_id}}}{{}}{text}"
    return content.encode('latin-1')


class TestMSGParser:
    """Testes unitários para MSGParser."""
    
    def test_parse_simple_message(self):
        """Testa parsing de mensagem simples."""
        msg_data = b'{100}{}Hello World'
        
        parser = MSGParser()
        messages = parser.parse(msg_data)
        
        assert 100 in messages
        assert messages[100] == 'Hello World'
    
    def test_parse_multiple_messages(self):
        """Testa parsing de múltiplas mensagens."""
        msg_data = b'{100}{}First message{200}{}Second message{300}{}Third message'
        
        parser = MSGParser()
        messages = parser.parse(msg_data)
        
        assert len(messages) == 3
        assert messages[100] == 'First message'
        assert messages[200] == 'Second message'
        assert messages[300] == 'Third message'
    
    def test_parse_message_with_newlines(self):
        """Testa parsing de mensagem com quebras de linha."""
        msg_data = b'{100}{}Line 1\nLine 2\nLine 3'
        
        parser = MSGParser()
        messages = parser.parse(msg_data)
        
        assert 100 in messages
        assert 'Line 1' in messages[100]
        assert 'Line 2' in messages[100]
    
    def test_to_json_creates_file(self):
        """Testa que to_json cria arquivo JSON."""
        messages = {100: 'Test message', 200: 'Another message'}
        
        parser = MSGParser()
        
        with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as f:
            output_path = f.name
        
        try:
            parser.to_json(messages, output_path)
            
            assert os.path.exists(output_path)
            
            with open(output_path, 'r', encoding='utf-8') as f:
                loaded = json.load(f)
            
            assert '100' in loaded
            assert loaded['100'] == 'Test message'
        finally:
            os.unlink(output_path)


class TestMSGPropertyTests:
    """Property-based tests para MSGParser."""
    
    @given(
        messages=st.dictionaries(
            keys=st.integers(min_value=1, max_value=10000),
            values=st.text(
                min_size=1, 
                max_size=100,
                alphabet=st.characters(
                    min_codepoint=32, 
                    max_codepoint=126,
                    blacklist_characters='{}'  # Evitar caracteres especiais do formato MSG
                )
            ),
            min_size=1,
            max_size=20
        )
    )
    @settings(max_examples=100)
    def test_property_13_msg_parsing_roundtrip(self, messages):
        """
        **Feature: fallout2-asset-extraction, Property 13: MSG Parsing Round-Trip**
        
        Para qualquer arquivo MSG com N entradas de mensagem, parsear e re-serializar
        DEVE preservar todas as N entradas com IDs e conteúdo de texto idênticos.
        
        **Validates: Requirements 8.1, 8.2**
        """
        # Criar arquivo MSG
        msg_data = create_msg_file(messages)
        
        # Parsear
        parser = MSGParser()
        parsed_messages = parser.parse(msg_data)
        
        # Verificar que todas as mensagens foram preservadas
        assert len(parsed_messages) == len(messages), \
            f"Número de mensagens diferente: {len(parsed_messages)} != {len(messages)}"
        
        # Verificar que IDs e textos são idênticos
        for msg_id, text in messages.items():
            assert msg_id in parsed_messages, \
                f"ID {msg_id} não encontrado nas mensagens parseadas"
            
            # O parser pode fazer strip no texto
            assert parsed_messages[msg_id].strip() == text.strip(), \
                f"Texto diferente para ID {msg_id}: '{parsed_messages[msg_id]}' != '{text}'"
    
    @given(
        messages=st.dictionaries(
            keys=st.integers(min_value=1, max_value=10000),
            values=st.text(
                min_size=1, 
                max_size=50,
                alphabet=st.characters(
                    min_codepoint=32, 
                    max_codepoint=126,
                    blacklist_characters='{}'
                )
            ),
            min_size=1,
            max_size=10
        )
    )
    @settings(max_examples=50)
    def test_property_13_json_roundtrip(self, messages):
        """
        **Feature: fallout2-asset-extraction, Property 13: MSG to JSON Round-Trip**
        
        Para qualquer conjunto de mensagens, exportar para JSON e carregar de volta
        DEVE preservar todas as mensagens com IDs e textos idênticos.
        
        **Validates: Requirements 8.1, 8.2**
        """
        parser = MSGParser()
        
        with tempfile.NamedTemporaryFile(suffix='.json', delete=False) as f:
            output_path = f.name
        
        try:
            # Exportar para JSON
            parser.to_json(messages, output_path)
            
            # Carregar de volta
            with open(output_path, 'r', encoding='utf-8') as f:
                loaded = json.load(f)
            
            # Verificar que todas as mensagens foram preservadas
            for msg_id, text in messages.items():
                str_id = str(msg_id)
                assert str_id in loaded, \
                    f"ID {msg_id} não encontrado no JSON"
                assert loaded[str_id] == text, \
                    f"Texto diferente para ID {msg_id}: '{loaded[str_id]}' != '{text}'"
        finally:
            os.unlink(output_path)
