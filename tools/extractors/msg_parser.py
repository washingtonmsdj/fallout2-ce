"""
Módulo para parsing de arquivos MSG do Fallout 2.

Este módulo implementa o MSGParser que lê arquivos de mensagens/diálogos,
preservando IDs e exportando em formato JSON.
"""
import json
import re
from pathlib import Path
from typing import Dict, Optional


class MSGParser:
    """
    Parser de arquivos MSG do Fallout 2.
    
    Lê arquivos de mensagens no formato {id}{}{texto}, preserva IDs
    e exporta em formato JSON organizado por locale.
    """
    
    # Padrão regex para mensagens: {id}{}{texto}
    MSG_PATTERN = re.compile(r'\{(\d+)\}\{\}(.*?)(?=\{\d+\}\{\}|$)', re.DOTALL)
    
    def __init__(self):
        """Inicializa o parser de mensagens."""
        pass
    
    def parse(self, msg_data: bytes) -> Dict[int, str]:
        """
        Parseia dados de um arquivo MSG.
        
        Args:
            msg_data: Dados do arquivo MSG (bytes)
            
        Returns:
            Dicionário mapeando IDs para textos
        """
        # Tentar diferentes encodings
        encodings = ['latin-1', 'cp1252', 'utf-8', 'iso-8859-1']
        text = None
        
        for encoding in encodings:
            try:
                text = msg_data.decode(encoding)
                break
            except UnicodeDecodeError:
                continue
        
        if text is None:
            # Fallback: usar latin-1 com tratamento de erros
            text = msg_data.decode('latin-1', errors='ignore')
        
        messages: Dict[int, str] = {}
        
        # Procurar por padrões {id}{}{texto}
        matches = self.MSG_PATTERN.findall(text)
        
        for match in matches:
            msg_id = int(match[0])
            msg_text = match[1].strip()
            
            # Limpar texto (remover caracteres de controle comuns)
            msg_text = msg_text.replace('\r\n', '\n').replace('\r', '\n')
            msg_text = re.sub(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]', '', msg_text)
            
            messages[msg_id] = msg_text
        
        # Se não encontrou padrões, tentar parsing linha por linha
        if not messages:
            lines = text.split('\n')
            current_id = None
            current_text = []
            
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                
                # Tentar encontrar ID no início da linha
                id_match = re.match(r'\{(\d+)\}', line)
                if id_match:
                    # Salvar mensagem anterior
                    if current_id is not None and current_text:
                        messages[current_id] = '\n'.join(current_text).strip()
                    
                    # Nova mensagem
                    current_id = int(id_match.group(1))
                    current_text = [line[len(id_match.group(0)):].strip()]
                else:
                    if current_id is not None:
                        current_text.append(line)
            
            # Salvar última mensagem
            if current_id is not None and current_text:
                messages[current_id] = '\n'.join(current_text).strip()
        
        return messages
    
    def to_json(self, messages: Dict[int, str], output_path: str, locale: Optional[str] = None):
        """
        Exporta mensagens para JSON.
        
        Args:
            messages: Dicionário de mensagens (id -> texto)
            output_path: Caminho do arquivo JSON de saída
            locale: Locale opcional (en, pt, etc.)
        """
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Converter IDs para strings para JSON
        output_dict = {str(k): v for k, v in messages.items()}
        
        # Adicionar metadados se locale fornecido
        if locale:
            output_dict['_metadata'] = {
                'locale': locale,
                'message_count': len(messages)
            }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output_dict, f, indent=2, ensure_ascii=False)

