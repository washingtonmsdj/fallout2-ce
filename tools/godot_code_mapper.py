"""
Godot Code Mapper - Sistema profissional de mapeamento do código Godot.

Este módulo mapeia completamente o código Godot existente:
- Todos os scripts (.gd) com suas classes, responsabilidades e dependências
- Todas as cenas (.tscn) com estrutura de nós e scripts anexados
- Autoloads e singletons
- Recursos (.tres) utilizados

Requirements: 6.1, 6.2, 6.3, 6.4, 6.5
"""
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Any
from dataclasses import dataclass, asdict, field
from datetime import datetime
from collections import defaultdict


@dataclass
class ScriptDependency:
    """Dependência entre scripts."""
    target_script: str
    dependency_type: str  # 'extends', 'preload', 'load', 'autoload', 'signal'
    line_number: Optional[int] = None


@dataclass
class ScriptInfo:
    """Informações sobre um script GDScript."""
    path: str
    class_name: Optional[str] = None
    extends: Optional[str] = None
    description: str = ""
    functions: List[str] = field(default_factory=list)
    signals: List[str] = field(default_factory=list)
    properties: List[str] = field(default_factory=list)
    dependencies: List[ScriptDependency] = field(default_factory=list)
    is_autoload: bool = False
    autoload_name: Optional[str] = None
    lines_of_code: int = 0
    complexity: str = "low"  # low, medium, high


@dataclass
class SceneNode:
    """Nó em uma cena."""
    name: str
    type: str
    path: str
    script: Optional[str] = None
    children: List['SceneNode'] = field(default_factory=list)
    properties: Dict[str, Any] = field(default_factory=dict)


@dataclass
class SceneInfo:
    """Informações sobre uma cena."""
    path: str
    name: str
    root_node: Optional[SceneNode] = None
    scripts: List[str] = field(default_factory=list)
    resources: List[str] = field(default_factory=list)
    total_nodes: int = 0


@dataclass
class ResourceInfo:
    """Informações sobre um recurso."""
    path: str
    type: str
    used_in: List[str] = field(default_factory=list)  # Scripts/cenas que usam


class GodotCodeMapper:
    """
    Sistema profissional de mapeamento do código Godot.
    
    Analisa scripts, cenas, recursos e autoloads, criando um mapa
    completo da arquitetura do projeto.
    """
    
    def __init__(self, godot_project_path: str, output_dir: str = "analysis/godot_code_map"):
        """
        Inicializa o mapeador.
        
        Args:
            godot_project_path: Caminho para a pasta do projeto Godot
            output_dir: Diretório de saída para os mapas
        """
        self.project_path = Path(godot_project_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        self.scripts: Dict[str, ScriptInfo] = {}
        self.scenes: Dict[str, SceneInfo] = {}
        self.resources: Dict[str, ResourceInfo] = {}
        self.autoloads: Dict[str, str] = {}  # name -> script_path
        
        # Ler autoloads do project.godot
        self._load_autoloads()
    
    def _load_autoloads(self):
        """Carrega autoloads do project.godot."""
        project_file = self.project_path / "project.godot"
        if not project_file.exists():
            return
        
        with open(project_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Procurar seção [autoload]
        autoload_match = re.search(r'\[autoload\](.*?)(?=\[|\Z)', content, re.DOTALL)
        if autoload_match:
            autoload_section = autoload_match.group(1)
            # Procurar linhas no formato: Name="*res://path/to/script.gd"
            pattern = r'(\w+)="\*?(res://[^"]+\.gd)"'
            matches = re.findall(pattern, autoload_section)
            for name, path in matches:
                self.autoloads[name] = path
    
    def map_scripts(self) -> Dict[str, ScriptInfo]:
        """
        Mapeia todos os scripts GDScript do projeto.
        
        Returns:
            Dicionário mapeando caminho do script para ScriptInfo
        """
        print("📜 Mapeando scripts GDScript...")
        
        # Encontrar todos os arquivos .gd
        script_files = list(self.project_path.rglob("*.gd"))
        print(f"   Encontrados {len(script_files)} scripts")
        
        for script_file in script_files:
            try:
                script_info = self._analyze_script(script_file)
                if script_info:
                    self.scripts[script_info.path] = script_info
            except Exception as e:
                print(f"   ⚠️  Erro ao analisar {script_file}: {e}")
        
        print(f"✅ {len(self.scripts)} scripts mapeados")
        return self.scripts
    
    def _analyze_script(self, script_path: Path) -> Optional[ScriptInfo]:
        """
        Analisa um script GDScript individual.
        
        Args:
            script_path: Caminho para o arquivo .gd
            
        Returns:
            ScriptInfo com informações do script
        """
        with open(script_path, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
        
        # Caminho relativo ao projeto
        rel_path = str(script_path.relative_to(self.project_path))
        
        script_info = ScriptInfo(
            path=rel_path,
            lines_of_code=len([l for l in lines if l.strip() and not l.strip().startswith('#')])
        )
        
        # Verificar se é autoload
        for name, path in self.autoloads.items():
            if path == f"res://{rel_path}" or path == f"*res://{rel_path}":
                script_info.is_autoload = True
                script_info.autoload_name = name
                break
        
        # Analisar conteúdo
        self._parse_script_content(content, script_info, lines)
        
        # Determinar complexidade
        if script_info.lines_of_code < 100:
            script_info.complexity = "low"
        elif script_info.lines_of_code < 500:
            script_info.complexity = "medium"
        else:
            script_info.complexity = "high"
        
        return script_info
    
    def _parse_script_content(self, content: str, script_info: ScriptInfo, lines: List[str]):
        """Parseia o conteúdo do script para extrair informações."""
        
        # Procurar class_name
        class_name_match = re.search(r'^class_name\s+(\w+)', content, re.MULTILINE)
        if class_name_match:
            script_info.class_name = class_name_match.group(1)
        
        # Procurar extends
        extends_match = re.search(r'^extends\s+([^\n]+)', content, re.MULTILINE)
        if extends_match:
            extends_str = extends_match.group(1).strip()
            script_info.extends = extends_str
            # Adicionar dependência
            script_info.dependencies.append(ScriptDependency(
                target_script=extends_str,
                dependency_type='extends'
            ))
        
        # Procurar funções
        func_pattern = r'^func\s+(\w+)\s*\([^)]*\)'
        functions = re.findall(func_pattern, content, re.MULTILINE)
        script_info.functions = functions
        
        # Procurar sinais
        signal_pattern = r'^signal\s+(\w+)'
        signals = re.findall(signal_pattern, content, re.MULTILINE)
        script_info.signals = signals
        
        # Procurar propriedades (var e const)
        var_pattern = r'^(?:var|const)\s+(\w+)'
        properties = re.findall(var_pattern, content, re.MULTILINE)
        script_info.properties = properties
        
        # Procurar preload/load
        preload_pattern = r'preload\s*\(\s*["\']([^"\']+)["\']\s*\)'
        load_pattern = r'load\s*\(\s*["\']([^"\']+)["\']\s*\)'
        
        for match in re.finditer(preload_pattern, content):
            dep_path = match.group(1)
            line_num = content[:match.start()].count('\n') + 1
            script_info.dependencies.append(ScriptDependency(
                target_script=dep_path,
                dependency_type='preload',
                line_number=line_num
            ))
        
        for match in re.finditer(load_pattern, content):
            dep_path = match.group(1)
            line_num = content[:match.start()].count('\n') + 1
            script_info.dependencies.append(ScriptDependency(
                target_script=dep_path,
                dependency_type='load',
                line_number=line_num
            ))
        
        # Procurar referências a autoloads
        for autoload_name in self.autoloads.keys():
            if re.search(rf'\b{autoload_name}\b', content):
                script_info.dependencies.append(ScriptDependency(
                    target_script=f"autoload:{autoload_name}",
                    dependency_type='autoload'
                ))
        
        # Procurar descrição (comentário no início)
        desc_match = re.search(r'^##\s*(.+?)(?:\n|$)', content, re.MULTILINE)
        if desc_match:
            script_info.description = desc_match.group(1).strip()
    
    def map_scenes(self) -> Dict[str, SceneInfo]:
        """
        Mapeia todas as cenas do projeto.
        
        Returns:
            Dicionário mapeando caminho da cena para SceneInfo
        """
        print("🎬 Mapeando cenas...")
        
        # Encontrar todos os arquivos .tscn
        scene_files = list(self.project_path.rglob("*.tscn"))
        print(f"   Encontrados {len(scene_files)} cenas")
        
        for scene_file in scene_files:
            try:
                scene_info = self._analyze_scene(scene_file)
                if scene_info:
                    self.scenes[scene_info.path] = scene_info
            except Exception as e:
                print(f"   ⚠️  Erro ao analisar {scene_file}: {e}")
        
        print(f"✅ {len(self.scenes)} cenas mapeadas")
        return self.scenes
    
    def _analyze_scene(self, scene_path: Path) -> Optional[SceneInfo]:
        """
        Analisa uma cena individual.
        
        Args:
            scene_path: Caminho para o arquivo .tscn
            
        Returns:
            SceneInfo com informações da cena
        """
        with open(scene_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        rel_path = str(scene_path.relative_to(self.project_path))
        scene_name = scene_path.stem
        
        scene_info = SceneInfo(
            path=rel_path,
            name=scene_name
        )
        
        # Parsear estrutura básica da cena
        # Formato TSCN é complexo, vamos fazer parsing básico
        
        # Procurar scripts anexados
        script_pattern = r'script\s*=\s*ExtResource\(\s*"([^"]+)"\s*\)'
        scripts = re.findall(script_pattern, content)
        scene_info.scripts = scripts
        
        # Procurar recursos
        resource_pattern = r'ExtResource\(\s*"([^"]+)"\s*\)'
        resources = re.findall(resource_pattern, content)
        scene_info.resources = list(set(resources))
        
        # Contar nós (aproximado)
        node_count = content.count('[node')
        scene_info.total_nodes = node_count
        
        # Parsear estrutura de nós (simplificado)
        # TODO: Implementar parsing completo de nós
        
        return scene_info
    
    def map_resources(self) -> Dict[str, ResourceInfo]:
        """
        Mapeia todos os recursos do projeto.
        
        Returns:
            Dicionário mapeando caminho do recurso para ResourceInfo
        """
        print("📦 Mapeando recursos...")
        
        # Encontrar todos os arquivos .tres
        resource_files = list(self.project_path.rglob("*.tres"))
        print(f"   Encontrados {len(resource_files)} recursos")
        
        for resource_file in resource_files:
            try:
                rel_path = str(resource_file.relative_to(self.project_path))
                
                # Ler tipo do recurso
                with open(resource_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    type_match = re.search(r'\[resource\]\s+type\s*=\s*"([^"]+)"', content)
                    resource_type = type_match.group(1) if type_match else "Unknown"
                
                resource_info = ResourceInfo(
                    path=rel_path,
                    type=resource_type
                )
                
                # Procurar onde o recurso é usado
                resource_info.used_in = self._find_resource_usage(rel_path)
                
                self.resources[rel_path] = resource_info
            except Exception as e:
                print(f"   ⚠️  Erro ao analisar {resource_file}: {e}")
        
        print(f"✅ {len(self.resources)} recursos mapeados")
        return self.resources
    
    def _find_resource_usage(self, resource_path: str) -> List[str]:
        """Encontra onde um recurso é usado."""
        used_in = []
        resource_name = Path(resource_path).name
        
        # Procurar em scripts
        for script_path, script_info in self.scripts.items():
            script_file = self.project_path / script_path
            if script_file.exists():
                with open(script_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if resource_path in content or resource_name in content:
                        used_in.append(f"script:{script_path}")
        
        # Procurar em cenas
        for scene_path, scene_info in self.scenes.items():
            if resource_path in scene_info.resources:
                used_in.append(f"scene:{scene_path}")
        
        return used_in
    
    def generate_dependency_graph(self) -> Dict[str, Any]:
        """
        Gera grafo de dependências entre scripts.
        
        Returns:
            Dicionário com informações do grafo de dependências
        """
        graph = {
            'nodes': [],
            'edges': []
        }
        
        # Adicionar nós
        for script_path, script_info in self.scripts.items():
            node = {
                'id': script_path,
                'label': Path(script_path).stem,
                'type': 'autoload' if script_info.is_autoload else 'script',
                'complexity': script_info.complexity,
                'lines': script_info.lines_of_code
            }
            graph['nodes'].append(node)
        
        # Adicionar arestas (dependências)
        for script_path, script_info in self.scripts.items():
            for dep in script_info.dependencies:
                if dep.dependency_type in ['extends', 'preload', 'load']:
                    # Tentar resolver caminho
                    target = self._resolve_dependency_path(dep.target_script, script_path)
                    if target:
                        edge = {
                            'source': script_path,
                            'target': target,
                            'type': dep.dependency_type
                        }
                        graph['edges'].append(edge)
        
        return graph
    
    def _resolve_dependency_path(self, dep_path: str, from_script: str) -> Optional[str]:
        """Resolve caminho de dependência para caminho relativo do projeto."""
        # Se já é um caminho res://
        if dep_path.startswith('res://'):
            rel_path = dep_path[6:]  # Remove 'res://'
            if (self.project_path / rel_path).exists():
                return rel_path
        
        # Se é um caminho relativo
        if not dep_path.startswith('/') and not dep_path.startswith('res://'):
            from_dir = Path(from_script).parent
            rel_path = str(from_dir / dep_path)
            if (self.project_path / rel_path).exists():
                return rel_path
        
        # Procurar por nome de classe
        for script_path, script_info in self.scripts.items():
            if script_info.class_name == dep_path:
                return script_path
        
        return None
    
    def save_maps(self):
        """Salva todos os mapas em arquivos JSON."""
        print("\n💾 Salvando mapas...")
        
        # Salvar scripts
        scripts_dict = {k: self._script_to_dict(v) for k, v in self.scripts.items()}
        scripts_file = self.output_dir / "scripts_map.json"
        with open(scripts_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'total_scripts': len(self.scripts),
                'autoloads': {name: path for name, path in self.autoloads.items()},
                'scripts': scripts_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Scripts: {scripts_file}")
        
        # Salvar cenas
        scenes_dict = {k: self._scene_to_dict(v) for k, v in self.scenes.items()}
        scenes_file = self.output_dir / "scenes_map.json"
        with open(scenes_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'total_scenes': len(self.scenes),
                'scenes': scenes_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Cenas: {scenes_file}")
        
        # Salvar recursos
        resources_dict = {k: asdict(v) for k, v in self.resources.items()}
        resources_file = self.output_dir / "resources_map.json"
        with open(resources_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'total_resources': len(self.resources),
                'resources': resources_dict
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Recursos: {resources_file}")
        
        # Salvar grafo de dependências
        dep_graph = self.generate_dependency_graph()
        graph_file = self.output_dir / "dependency_graph.json"
        with open(graph_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'graph': dep_graph
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Grafo de dependências: {graph_file}")
        
        # Salvar mapa consolidado
        consolidated_file = self.output_dir / "code_map.json"
        with open(consolidated_file, 'w', encoding='utf-8') as f:
            json.dump({
                'generated_at': datetime.now().isoformat(),
                'summary': {
                    'total_scripts': len(self.scripts),
                    'total_scenes': len(self.scenes),
                    'total_resources': len(self.resources),
                    'total_autoloads': len(self.autoloads)
                },
                'autoloads': {name: path for name, path in self.autoloads.items()},
                'scripts': scripts_dict,
                'scenes': scenes_dict,
                'resources': resources_dict,
                'dependency_graph': dep_graph
            }, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Mapa consolidado: {consolidated_file}")
    
    def _script_to_dict(self, script_info: ScriptInfo) -> Dict[str, Any]:
        """Converte ScriptInfo para dicionário."""
        return {
            'path': script_info.path,
            'class_name': script_info.class_name,
            'extends': script_info.extends,
            'description': script_info.description,
            'functions': script_info.functions,
            'signals': script_info.signals,
            'properties': script_info.properties,
            'dependencies': [asdict(d) for d in script_info.dependencies],
            'is_autoload': script_info.is_autoload,
            'autoload_name': script_info.autoload_name,
            'lines_of_code': script_info.lines_of_code,
            'complexity': script_info.complexity
        }
    
    def _scene_to_dict(self, scene_info: SceneInfo) -> Dict[str, Any]:
        """Converte SceneInfo para dicionário."""
        return {
            'path': scene_info.path,
            'name': scene_info.name,
            'scripts': scene_info.scripts,
            'resources': scene_info.resources,
            'total_nodes': scene_info.total_nodes
        }


def main():
    """Função principal para executar mapeamento completo."""
    import sys
    
    # Caminho padrão
    if len(sys.argv) > 1:
        godot_project_path = sys.argv[1]
    else:
        godot_project_path = Path(__file__).parent.parent / "godot_project"
        if not godot_project_path.exists():
            print("❌ Erro: Pasta do projeto Godot não encontrada!")
            print(f"   Procurando em: {godot_project_path}")
            print("   Use: python godot_code_mapper.py <caminho_do_projeto_godot>")
            return
    
    print("=" * 70)
    print("🗺️  Sistema de Mapeamento de Código Godot")
    print("=" * 70)
    print(f"📁 Projeto Godot: {godot_project_path}")
    print()
    
    mapper = GodotCodeMapper(str(godot_project_path))
    
    # Mapear tudo
    scripts = mapper.map_scripts()
    scenes = mapper.map_scenes()
    resources = mapper.map_resources()
    
    # Salvar mapas
    mapper.save_maps()
    
    print("\n" + "=" * 70)
    print("✅ Mapeamento completo finalizado!")
    print("=" * 70)
    print(f"📊 Resumo:")
    print(f"   📜 Scripts: {len(scripts)}")
    print(f"   🎬 Cenas: {len(scenes)}")
    print(f"   📦 Recursos: {len(resources)}")
    print(f"   🔄 Autoloads: {len(mapper.autoloads)}")
    print(f"\n📁 Mapas salvos em: {mapper.output_dir}")


if __name__ == "__main__":
    main()

