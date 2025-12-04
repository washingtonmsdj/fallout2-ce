"""
Content Cataloger - Sistema profissional de catalogação de conteúdo do Fallout 2.

Este módulo cria catálogos completos de:
- Mapas (~160 mapas)
- NPCs (~1000 NPCs)
- Itens (~500 itens)
- Quests (~100 quests)
- Diálogos (todas as árvores de diálogo)

Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
"""
import json
import struct
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict, field
from datetime import datetime
from collections import defaultdict

from extractors.dat2_reader import DAT2Reader, DAT2Manager, FileInfo
from extractors.map_parser import MAPParser, MapData, MapObject
from extractors.msg_parser import MSGParser
from extractors.pro_parser import parse_proto


@dataclass
class MapConnection:
    """Conexão entre mapas."""
    target_map: str
    connection_type: str  # 'exit_grid', 'stairs', 'elevator', 'door'
    tile_position: Tuple[int, int]
    elevation: int


@dataclass
class MapCatalogEntry:
    """Entrada no catálogo de mapas."""
    map_id: str
    name: str
    file_path: str
    version: int
    width: int
    height: int
    num_levels: int
    entering_tile: int
    entering_elevation: int
    entering_rotation: int
    script_index: int
    flags: int
    darkness: int
    connections: List[MapConnection] = field(default_factory=list)
    npcs: List[Dict[str, Any]] = field(default_factory=list)
    items: List[Dict[str, Any]] = field(default_factory=list)
    scripts: List[str] = field(default_factory=list)
    global_variables_count: int = 0
    local_variables_count: int = 0


@dataclass
class NPCCatalogEntry:
    """Entrada no catálogo de NPCs."""
    pid: int
    name: str
    proto_file: str
    stats: Dict[str, int] = field(default_factory=dict)
    skills: Dict[str, int] = field(default_factory=dict)
    traits: List[str] = field(default_factory=list)
    perks: List[str] = field(default_factory=list)
    location: Optional[Dict[str, Any]] = None  # {map_id, tile, elevation}
    ai_packages: List[str] = field(default_factory=list)
    dialogue_file: Optional[str] = None
    script_file: Optional[str] = None
    inventory: List[Dict[str, Any]] = field(default_factory=list)
    description: str = ""


@dataclass
class ItemCatalogEntry:
    """Entrada no catálogo de itens."""
    pid: int
    name: str
    proto_file: str
    item_type: str  # 'weapon', 'armor', 'ammo', 'drug', 'misc', 'key', 'container'
    weight: int
    cost: int
    description: str = ""
    stats: Dict[str, Any] = field(default_factory=dict)
    effects: List[Dict[str, Any]] = field(default_factory=list)
    requirements: Dict[str, int] = field(default_factory=dict)


@dataclass
class QuestCatalogEntry:
    """Entrada no catálogo de quests."""
    quest_id: str
    name: str
    description: str
    objectives: List[str] = field(default_factory=list)
    rewards: List[Dict[str, Any]] = field(default_factory=list)
    npcs_involved: List[int] = field(default_factory=list)
    locations_involved: List[str] = field(default_factory=list)
    conditions: Dict[str, Any] = field(default_factory=dict)
    consequences: Dict[str, Any] = field(default_factory=dict)
    script_file: Optional[str] = None


@dataclass
class DialogueNode:
    """Nó de diálogo."""
    node_id: int
    text: str
    speaker: Optional[str] = None
    conditions: Dict[str, Any] = field(default_factory=dict)
    consequences: Dict[str, Any] = field(default_factory=dict)
    options: List[Dict[str, Any]] = field(default_factory=list)


@dataclass
class DialogueCatalogEntry:
    """Entrada no catálogo de diálogos."""
    dialogue_id: str
    npc_pid: int
    npc_name: str
    dialogue_file: str
    nodes: List[DialogueNode] = field(default_factory=list)
    conditions: Dict[str, Any] = field(default_factory=dict)


class ContentCataloger:
    """
    Sistema profissional de catalogação de conteúdo do Fallout 2.
    
    Cria catálogos completos de mapas, NPCs, itens, quests e diálogos
    extraindo informações dos arquivos DAT, PRO, MAP, MSG e scripts.
    """
    
    def __init__(self, fallout2_path: str, output_dir: str = "analysis/content_catalogs"):
        """
        Inicializa o catalogador.
        
        Args:
            fallout2_path: Caminho para a pasta do Fallout 2
            output_dir: Diretório de saída para os catálogos
        """
        self.fallout2_path = Path(fallout2_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Criar lista de caminhos DAT
        dat_files = []
        for dat_name in ['master.dat', 'critter.dat', 'patch000.dat']:
            dat_path = self.fallout2_path / dat_name
            if dat_path.exists():
                dat_files.append(str(dat_path))
        
        # Inicializar DAT2Manager
        self.dat_manager = DAT2Manager(dat_files)
        self.map_parser = MAPParser()
        self.msg_parser = MSGParser()
        
        # Cache de dados parseados
        self._map_cache: Dict[str, MapData] = {}
        self._proto_cache: Dict[int, Dict[str, Any]] = {}
        self._msg_cache: Dict[str, Dict[int, str]] = {}
        
    def catalog_maps(self) -> Dict[str, MapCatalogEntry]:
        """
        Cria catálogo completo de mapas.
        
        Returns:
            Dicionário mapeando map_id para MapCatalogEntry
        """
        print("🗺️  Catalogando mapas...")
        maps: Dict[str, MapCatalogEntry] = {}
        
        # Encontrar todos os arquivos MAP
        map_files = []
        all_files = self.dat_manager.list_all_files()
        for file_path in all_files:
            if file_path.lower().endswith('.map'):
                map_files.append(file_path)
        
        print(f"   Encontrados {len(map_files)} arquivos MAP")
        
        for i, file_path in enumerate(map_files, 1):
            try:
                # Extrair nome do mapa
                map_id = Path(file_path).stem.upper()
                
                # Ler dados do mapa
                map_data = self.dat_manager.get_file(file_path)
                if not map_data:
                    continue
                
                # Parsear mapa
                parsed_map = self.map_parser.parse(map_data)
                self._map_cache[map_id] = parsed_map
                
                # Extrair objetos (NPCs e itens)
                npcs = []
                items = []
                for obj in parsed_map.objects:
                    # Determinar tipo baseado no PID
                    obj_type = self._get_object_type(obj.pid)
                    obj_info = {
                        'pid': obj.pid,
                        'position': obj.position,
                        'level': obj.level,
                        'orientation': obj.orientation,
                        'script_id': obj.script_id
                    }
                    
                    if obj_type == 'critter':
                        npcs.append(obj_info)
                    elif obj_type == 'item':
                        items.append(obj_info)
                
                # Extrair conexões (simplificado - requer análise mais profunda)
                connections = self._extract_map_connections(parsed_map)
                
                # Criar entrada no catálogo
                catalog_entry = MapCatalogEntry(
                    map_id=map_id,
                    name=parsed_map.name,
                    file_path=file_path,
                    version=parsed_map.version,
                    width=parsed_map.width,
                    height=parsed_map.height,
                    num_levels=parsed_map.num_levels,
                    entering_tile=parsed_map.entering_tile,
                    entering_elevation=parsed_map.entering_elevation,
                    entering_rotation=parsed_map.entering_rotation,
                    script_index=parsed_map.script_index,
                    flags=parsed_map.flags,
                    darkness=parsed_map.darkness,
                    connections=connections,
                    npcs=npcs,
                    items=items,
                    scripts=parsed_map.scripts,
                    global_variables_count=parsed_map.global_variables_count,
                    local_variables_count=parsed_map.local_variables_count
                )
                
                maps[map_id] = catalog_entry
                
                if i % 10 == 0:
                    print(f"   Processados {i}/{len(map_files)} mapas...")
                    
            except Exception as e:
                print(f"   ⚠️  Erro ao processar {file_path}: {e}")
                continue
        
        print(f"✅ {len(maps)} mapas catalogados")
        return maps
    
    def catalog_npcs(self) -> Dict[int, NPCCatalogEntry]:
        """
        Cria catálogo completo de NPCs.
        
        Returns:
            Dicionário mapeando PID para NPCCatalogEntry
        """
        print("👥 Catalogando NPCs...")
        npcs: Dict[int, NPCCatalogEntry] = {}
        
        # Encontrar todos os arquivos PRO de criaturas
        proto_files = []
        all_files = self.dat_manager.list_all_files()
        for file_path in all_files:
            # Procurar em proto/critters/
            if 'proto/critters' in file_path.lower() and file_path.lower().endswith('.pro'):
                proto_files.append(file_path)
        
        print(f"   Encontrados {len(proto_files)} arquivos PRO de criaturas")
        
        for i, file_path in enumerate(proto_files, 1):
            try:
                # Ler e parsear PRO
                proto_data = self.dat_manager.get_file(file_path)
                if not proto_data:
                    continue
                
                parsed_proto = self._parse_proto(proto_data)
                if not parsed_proto or parsed_proto.get('type') != 'critter':
                    continue
                
                pid = parsed_proto.get('pid', 0)
                if pid == 0:
                    continue
                
                # Extrair informações do NPC
                name = f"NPC_{pid}"  # Nome será obtido do MSG depois
                critter_data = parsed_proto.get('critter_data', {})
                base_stats = critter_data.get('base_stats', {})
                bonus_stats = critter_data.get('bonus_stats', {})
                skills = critter_data.get('skills', {})
                
                # Combinar stats base e bonus
                stats = {}
                for stat_name in base_stats:
                    stats[stat_name] = base_stats.get(stat_name, 0) + bonus_stats.get(stat_name, 0)
                
                # Procurar diálogo associado
                dialogue_file = self._find_dialogue_file(pid)
                
                # Procurar script associado
                script_file = self._find_script_file(pid, 'critter')
                
                # Criar entrada no catálogo
                catalog_entry = NPCCatalogEntry(
                    pid=pid,
                    name=name,
                    proto_file=file_path,
                    stats=stats,
                    skills=skills,
                    traits=[],  # TODO: Extrair traits
                    perks=[],  # TODO: Extrair perks
                    ai_packages=[f"ai_packet_{parsed_proto.get('ai_packet', 1)}"],
                    dialogue_file=dialogue_file,
                    script_file=script_file,
                    inventory=[],
                    description=''
                )
                
                npcs[pid] = catalog_entry
                
                if i % 50 == 0:
                    print(f"   Processados {i}/{len(proto_files)} NPCs...")
                    
            except Exception as e:
                print(f"   ⚠️  Erro ao processar {file_path}: {e}")
                continue
        
        print(f"✅ {len(npcs)} NPCs catalogados")
        return npcs
    
    def catalog_items(self) -> Dict[int, ItemCatalogEntry]:
        """
        Cria catálogo completo de itens.
        
        Returns:
            Dicionário mapeando PID para ItemCatalogEntry
        """
        print("📦 Catalogando itens...")
        items: Dict[int, ItemCatalogEntry] = {}
        
        # Encontrar todos os arquivos PRO de itens
        proto_files = []
        all_files = self.dat_manager.list_all_files()
        for file_path in all_files:
            # Procurar em proto/items/
            if 'proto/items' in file_path.lower() and file_path.lower().endswith('.pro'):
                proto_files.append(file_path)
        
        print(f"   Encontrados {len(proto_files)} arquivos PRO de itens")
        
        for i, file_path in enumerate(proto_files, 1):
            try:
                # Ler e parsear PRO
                proto_data = self.dat_manager.get_file(file_path)
                if not proto_data:
                    continue
                
                parsed_proto = self._parse_proto(proto_data)
                if not parsed_proto or parsed_proto.get('type') != 'item':
                    continue
                
                pid = parsed_proto.get('pid', 0)
                if pid == 0:
                    continue
                
                # Extrair informações do item
                name = f"Item_{pid}"  # Nome será obtido do MSG depois
                item_type = parsed_proto.get('item_type', 'misc')
                weight = parsed_proto.get('weight', 0)
                cost = parsed_proto.get('cost', 0)
                item_data = parsed_proto.get('item_data', {})
                
                # Criar entrada no catálogo
                catalog_entry = ItemCatalogEntry(
                    pid=pid,
                    name=name,
                    proto_file=file_path,
                    item_type=item_type,
                    weight=weight,
                    cost=cost,
                    description='',  # Será obtido do MSG depois
                    stats=item_data,
                    effects=[],  # TODO: Extrair efeitos de drugs
                    requirements={'strength': item_data.get('min_strength', 0)} if item_type == 'weapon' else {}
                )
                
                items[pid] = catalog_entry
                
                if i % 50 == 0:
                    print(f"   Processados {i}/{len(proto_files)} itens...")
                    
            except Exception as e:
                print(f"   ⚠️  Erro ao processar {file_path}: {e}")
                continue
        
        print(f"✅ {len(items)} itens catalogados")
        return items
    
    def catalog_quests(self) -> Dict[str, QuestCatalogEntry]:
        """
        Cria catálogo completo de quests.
        
        Nota: Quests são tipicamente definidas em scripts, então esta função
        faz uma análise básica. Uma análise completa requereria interpretação
        de scripts .INT.
        
        Returns:
            Dicionário mapeando quest_id para QuestCatalogEntry
        """
        print("📜 Catalogando quests...")
        quests: Dict[str, QuestCatalogEntry] = {}
        
        # Análise básica - quests são tipicamente definidas em scripts
        # Por enquanto, vamos procurar por padrões conhecidos em scripts e MSG
        
        # TODO: Implementar análise mais profunda de scripts .INT
        # para extrair informações completas de quests
        
        print(f"✅ {len(quests)} quests catalogadas (análise básica)")
        return quests
    
    def catalog_dialogues(self) -> Dict[int, DialogueCatalogEntry]:
        """
        Cria catálogo completo de diálogos.
        
        Returns:
            Dicionário mapeando NPC PID para DialogueCatalogEntry
        """
        print("💬 Catalogando diálogos...")
        dialogues: Dict[int, DialogueCatalogEntry] = {}
        
        # Encontrar todos os arquivos MSG de diálogo
        msg_files = []
        all_files = self.dat_manager.list_all_files()
        for file_path in all_files:
            # Procurar arquivos MSG em text/english/dialog/
            if 'text/english/dialog' in file_path.lower() and file_path.lower().endswith('.msg'):
                msg_files.append(file_path)
        
        print(f"   Encontrados {len(msg_files)} arquivos MSG de diálogo")
        
        for i, file_path in enumerate(msg_files, 1):
            try:
                # Ler e parsear MSG
                msg_data = self.dat_manager.get_file(file_path)
                if not msg_data:
                    continue
                
                messages = self.msg_parser.parse(msg_data)
                if not messages:
                    continue
                
                # Tentar extrair PID do NPC do nome do arquivo
                # Formato típico: text/english/dialog/00000001.msg
                file_stem = Path(file_path).stem
                try:
                    npc_pid = int(file_stem)
                except ValueError:
                    # Tentar extrair de outro formato
                    npc_pid = 0
                
                # Criar nós de diálogo
                nodes = []
                for msg_id, text in messages.items():
                    node = DialogueNode(
                        node_id=msg_id,
                        text=text,
                        conditions={},
                        consequences={},
                        options=[]
                    )
                    nodes.append(node)
                
                # Criar entrada no catálogo
                catalog_entry = DialogueCatalogEntry(
                    dialogue_id=str(npc_pid) if npc_pid > 0 else file_stem,
                    npc_pid=npc_pid,
                    npc_name=f"NPC_{npc_pid}" if npc_pid > 0 else file_stem,
                    dialogue_file=file_path,
                    nodes=nodes
                )
                
                if npc_pid > 0:
                    dialogues[npc_pid] = catalog_entry
                else:
                    dialogues[hash(file_stem)] = catalog_entry
                
                if i % 10 == 0:
                    print(f"   Processados {i}/{len(msg_files)} diálogos...")
                    
            except Exception as e:
                print(f"   ⚠️  Erro ao processar {file_path}: {e}")
                continue
        
        print(f"✅ {len(dialogues)} diálogos catalogados")
        return dialogues
    
    def save_catalogs(self, maps: Dict[str, MapCatalogEntry],
                      npcs: Dict[int, NPCCatalogEntry],
                      items: Dict[int, ItemCatalogEntry],
                      quests: Dict[str, QuestCatalogEntry],
                      dialogues: Dict[int, DialogueCatalogEntry]):
        """
        Salva todos os catálogos em arquivos JSON.
        
        Args:
            maps: Catálogo de mapas
            npcs: Catálogo de NPCs
            items: Catálogo de itens
            quests: Catálogo de quests
            dialogues: Catálogo de diálogos
        """
        print("\n💾 Salvando catálogos...")
        
        # Função auxiliar para converter dataclasses para dict
        def to_dict(obj):
            if hasattr(obj, '__dict__'):
                return {k: to_dict(v) for k, v in obj.__dict__.items()}
            elif isinstance(obj, list):
                return [to_dict(item) for item in obj]
            elif isinstance(obj, dict):
                return {k: to_dict(v) for k, v in obj.items()}
            else:
                return obj
        
        # Salvar catálogo de mapas
        maps_dict = {k: to_dict(v) for k, v in maps.items()}
        maps_file = self.output_dir / "maps_catalog.json"
        with open(maps_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'total_maps': len(maps),
                'maps': maps_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Mapas: {maps_file}")
        
        # Salvar catálogo de NPCs
        npcs_dict = {str(k): to_dict(v) for k, v in npcs.items()}
        npcs_file = self.output_dir / "npcs_catalog.json"
        with open(npcs_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'total_npcs': len(npcs),
                'npcs': npcs_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ NPCs: {npcs_file}")
        
        # Salvar catálogo de itens
        items_dict = {str(k): to_dict(v) for k, v in items.items()}
        items_file = self.output_dir / "items_catalog.json"
        with open(items_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'total_items': len(items),
                'items': items_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Itens: {items_file}")
        
        # Salvar catálogo de quests
        quests_dict = {k: to_dict(v) for k, v in quests.items()}
        quests_file = self.output_dir / "quests_catalog.json"
        with open(quests_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'total_quests': len(quests),
                'quests': quests_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Quests: {quests_file}")
        
        # Salvar catálogo de diálogos
        dialogues_dict = {str(k): to_dict(v) for k, v in dialogues.items()}
        dialogues_file = self.output_dir / "dialogues_catalog.json"
        with open(dialogues_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'total_dialogues': len(dialogues),
                'dialogues': dialogues_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Diálogos: {dialogues_file}")
        
        # Salvar catálogo consolidado
        consolidated_file = self.output_dir / "content_catalog.json"
        with open(consolidated_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'summary': {
                    'total_maps': len(maps),
                    'total_npcs': len(npcs),
                    'total_items': len(items),
                    'total_quests': len(quests),
                    'total_dialogues': len(dialogues)
                },
                'maps': maps_dict,
                'npcs': npcs_dict,
                'items': items_dict,
                'quests': quests_dict,
                'dialogues': dialogues_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Catálogo consolidado: {consolidated_file}")
    
    # Métodos auxiliares privados
    
    def _get_object_type(self, pid: int) -> str:
        """Determina o tipo de objeto baseado no PID."""
        # PID encoding: bits 24-27 determinam o tipo
        obj_type = (pid >> 24) & 0xF
        type_map = {
            0: 'item',
            1: 'critter',
            2: 'scenery',
            3: 'wall',
            4: 'tile',
            5: 'misc'
        }
        return type_map.get(obj_type, 'unknown')
    
    def _extract_map_connections(self, map_data: MapData) -> List[MapConnection]:
        """Extrai conexões do mapa (simplificado)."""
        connections = []
        # TODO: Implementar análise completa de objetos de scenery
        # para detectar exit grids, stairs, elevators, etc.
        return connections
    
    def _parse_proto(self, proto_data: bytes) -> Optional[Dict[str, Any]]:
        """
        Parseia um arquivo PRO usando o parser completo.
        """
        return parse_proto(proto_data)
    
    def _find_dialogue_file(self, npc_pid: int) -> Optional[str]:
        """Encontra arquivo de diálogo associado a um NPC."""
        # Formato típico: text/english/dialog/{pid:08d}.msg
        dialogue_path = f"text/english/dialog/{npc_pid:08d}.msg"
        
        all_files = self.dat_manager.list_all_files()
        for file_path in all_files:
            if file_path.lower() == dialogue_path.lower():
                return file_path
        
        return None
    
    def _find_script_file(self, pid: int, obj_type: str) -> Optional[str]:
        """Encontra arquivo de script associado."""
        # Formato típico varia por tipo
        # Por enquanto, retornar None (requer análise mais profunda)
        return None


def main():
    """Função principal para executar catalogação completa."""
    import sys
    
    # Caminho padrão
    if len(sys.argv) > 1:
        fallout2_path = sys.argv[1]
    else:
        fallout2_path = Path(__file__).parent.parent / "Fallout 2"
        if not fallout2_path.exists():
            print("❌ Erro: Pasta do Fallout 2 não encontrada!")
            print(f"   Procurando em: {fallout2_path}")
            print("   Use: python content_cataloger.py <caminho_do_fallout2>")
            return
    
    print("=" * 70)
    print("📚 Sistema de Catalogação de Conteúdo - Fallout 2")
    print("=" * 70)
    print(f"📁 Pasta do Fallout 2: {fallout2_path}")
    print()
    
    cataloger = ContentCataloger(str(fallout2_path))
    
    # Catalogar tudo
    maps = cataloger.catalog_maps()
    npcs = cataloger.catalog_npcs()
    items = cataloger.catalog_items()
    quests = cataloger.catalog_quests()
    dialogues = cataloger.catalog_dialogues()
    
    # Salvar catálogos
    cataloger.save_catalogs(maps, npcs, items, quests, dialogues)
    
    print("\n" + "=" * 70)
    print("✅ Catalogação completa finalizada!")
    print("=" * 70)
    print(f"📊 Resumo:")
    print(f"   🗺️  Mapas: {len(maps)}")
    print(f"   👥 NPCs: {len(npcs)}")
    print(f"   📦 Itens: {len(items)}")
    print(f"   📜 Quests: {len(quests)}")
    print(f"   💬 Diálogos: {len(dialogues)}")
    print(f"\n📁 Catálogos salvos em: {cataloger.output_dir}")


if __name__ == "__main__":
    main()

