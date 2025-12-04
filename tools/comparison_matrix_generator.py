"""
Comparison Matrix Generator - Sistema profissional de comparação Original vs Implementado.

Este módulo cria uma matriz completa comparando funcionalidades do jogo original
Fallout 2 com a implementação atual no Godot, calculando percentuais de completude.

Requirements: 7.1, 7.2, 7.3, 7.4, 7.5
"""
import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict, field
from datetime import datetime
from enum import Enum

from godot_code_mapper import GodotCodeMapper


class ImplementationStatus(Enum):
    """Status de implementação de uma funcionalidade."""
    NOT_IMPLEMENTED = "not_implemented"
    PARTIAL = "partial"
    COMPLETE = "complete"


@dataclass
class FunctionalityFeature:
    """Funcionalidade do jogo."""
    id: str
    name: str
    category: str
    description: str
    status: ImplementationStatus
    implementation_details: str = ""
    missing_features: List[str] = field(default_factory=list)
    code_references: List[str] = field(default_factory=list)
    original_requirements: List[str] = field(default_factory=list)


@dataclass
class ComparisonMatrix:
    """Matriz de comparação completa."""
    generated_at: str
    total_features: int
    by_status: Dict[str, int] = field(default_factory=dict)
    by_category: Dict[str, Dict[str, int]] = field(default_factory=dict)
    completeness_percentage: float = 0.0
    features: List[FunctionalityFeature] = field(default_factory=list)


class ComparisonMatrixGenerator:
    """
    Sistema profissional de geração de matriz de comparação.
    
    Compara funcionalidades do jogo original Fallout 2 com a implementação
    atual no Godot, identificando o que está completo, parcial ou faltando.
    """
    
    # Definição completa de funcionalidades do Fallout 2 original
    ORIGINAL_FEATURES = {
        'core_systems': {
            'rendering': {
                'name': 'Sistema de Renderização',
                'description': 'Renderização isométrica 2D com sprites',
                'requirements': ['IsometricRenderer', 'isometric_renderer.gd']
            },
            'input': {
                'name': 'Sistema de Input',
                'description': 'Gerenciamento de entrada (teclado, mouse)',
                'requirements': ['InputManager', 'input_manager.gd']
            },
            'save_load': {
                'name': 'Sistema de Save/Load',
                'description': 'Salvar e carregar estado do jogo',
                'requirements': ['SaveSystem', 'save_system.gd']
            },
            'game_state': {
                'name': 'Máquina de Estados do Jogo',
                'description': 'Gerenciamento de estados (MENU, EXPLORATION, COMBAT, etc)',
                'requirements': ['GameManager', 'game_manager.gd']
            },
            'time_system': {
                'name': 'Sistema de Tempo',
                'description': 'Ciclo dia/noite, passagem de tempo',
                'requirements': ['GameManager', 'time_system']
            }
        },
        'gameplay_systems': {
            'combat': {
                'name': 'Sistema de Combate',
                'description': 'Combate por turnos com AP, hit chance, dano',
                'requirements': ['CombatSystem', 'combat_system.gd']
            },
            'dialogue': {
                'name': 'Sistema de Diálogo',
                'description': 'Árvores de diálogo com condições e consequências',
                'requirements': ['DialogSystem', 'dialog_system.gd']
            },
            'inventory': {
                'name': 'Sistema de Inventário',
                'description': 'Gerenciamento de itens, peso, equipamento',
                'requirements': ['InventorySystem', 'inventory_system.gd']
            },
            'barter': {
                'name': 'Sistema de Barter',
                'description': 'Troca de itens com NPCs baseado em skill Barter',
                'requirements': ['DialogSystem', 'barter']
            },
            'crafting': {
                'name': 'Sistema de Crafting',
                'description': 'Criação de itens a partir de receitas',
                'requirements': ['InventorySystem', 'crafting']
            },
            'script_interpreter': {
                'name': 'Interpretador de Scripts',
                'description': 'Execução de scripts SSL/INT do jogo original',
                'requirements': ['ScriptInterpreter', 'script_interpreter.gd']
            }
        },
        'world_systems': {
            'map_loading': {
                'name': 'Carregamento de Mapas',
                'description': 'Carregar e renderizar mapas do jogo',
                'requirements': ['MapSystem', 'map_system.gd', 'MapManager', 'map_manager.gd']
            },
            'map_transitions': {
                'name': 'Transições entre Mapas',
                'description': 'Mudança de mapa com posicionamento correto',
                'requirements': ['MapSystem', 'map_transitions']
            },
            'elevations': {
                'name': 'Sistema de Elevações',
                'description': '3 níveis de elevação com oclusão',
                'requirements': ['IsometricRenderer', 'elevations']
            },
            'pathfinding': {
                'name': 'Pathfinding',
                'description': 'Cálculo de caminhos para NPCs e jogador',
                'requirements': ['Pathfinder', 'pathfinder.gd']
            },
            'world_map': {
                'name': 'Mapa Mundial',
                'description': 'Navegação no mapa mundial entre locais',
                'requirements': ['world_map']
            }
        },
        'content': {
            'maps': {
                'name': 'Mapas do Jogo',
                'description': 'Todos os ~160 mapas do jogo original',
                'requirements': ['map_loader.gd', 'map_parser']
            },
            'npcs': {
                'name': 'NPCs',
                'description': 'Todos os ~1000 NPCs com AI e diálogos',
                'requirements': ['npc.gd', 'prototype_system.gd']
            },
            'items': {
                'name': 'Itens',
                'description': 'Todos os ~500 itens com stats e efeitos',
                'requirements': ['inventory_system.gd', 'prototype_system.gd']
            },
            'quests': {
                'name': 'Quests',
                'description': 'Todas as ~100 quests do jogo',
                'requirements': ['quest_system']
            },
            'dialogues': {
                'name': 'Diálogos',
                'description': 'Todas as árvores de diálogo',
                'requirements': ['dialog_system.gd']
            }
        },
        'audio': {
            'music': {
                'name': 'Sistema de Música',
                'description': 'Reprodução de músicas do jogo',
                'requirements': ['AudioManager', 'audio_manager.gd']
            },
            'sfx': {
                'name': 'Efeitos Sonoros',
                'description': 'Reprodução de sons e efeitos',
                'requirements': ['AudioManager', 'audio_manager.gd']
            },
            'positional_audio': {
                'name': 'Áudio Posicional',
                'description': 'Áudio baseado em posição 2D',
                'requirements': ['AudioManager', 'positional']
            }
        },
        'ui': {
            'main_menu': {
                'name': 'Menu Principal',
                'description': 'Menu inicial do jogo',
                'requirements': ['main_menu.gd', 'main_menu.tscn']
            },
            'hud': {
                'name': 'HUD',
                'description': 'Interface durante o jogo',
                'requirements': ['fallout_hud.gd', 'fallout_hud.tscn']
            },
            'inventory_ui': {
                'name': 'Interface de Inventário',
                'description': 'Tela de inventário',
                'requirements': ['inventory_screen.gd']
            },
            'character_screen': {
                'name': 'Tela de Personagem',
                'description': 'Tela de stats e skills',
                'requirements': ['character_screen.gd']
            },
            'dialogue_ui': {
                'name': 'Interface de Diálogo',
                'description': 'Interface de diálogos',
                'requirements': ['dialog_system.gd', 'dialogue_ui']
            }
        }
    }
    
    def __init__(self, godot_project_path: str, code_map_path: Optional[str] = None,
                 output_dir: str = "analysis/comparison_matrix"):
        """
        Inicializa o gerador de matriz de comparação.
        
        Args:
            godot_project_path: Caminho para o projeto Godot
            code_map_path: Caminho para o code_map.json (opcional)
            output_dir: Diretório de saída
        """
        self.project_path = Path(godot_project_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Carregar mapa de código
        if code_map_path:
            with open(code_map_path, 'r', encoding='utf-8') as f:
                self.code_map = json.load(f)
        else:
            # Tentar encontrar automaticamente
            code_map_file = Path("tools/analysis/godot_code_map/code_map.json")
            if code_map_file.exists():
                with open(code_map_file, 'r', encoding='utf-8') as f:
                    self.code_map = json.load(f)
            else:
                # Gerar mapa de código
                print("📜 Gerando mapa de código...")
                mapper = GodotCodeMapper(str(self.project_path))
                mapper.map_scripts()
                mapper.map_scenes()
                self.code_map = {
                    'scripts': {k: mapper._script_to_dict(v) for k, v in mapper.scripts.items()},
                    'scenes': {k: mapper._scene_to_dict(v) for k, v in mapper.scenes.items()},
                    'autoloads': mapper.autoloads
                }
    
    def generate_matrix(self) -> ComparisonMatrix:
        """
        Gera matriz de comparação completa.
        
        Returns:
            ComparisonMatrix com todas as comparações
        """
        print("📊 Gerando matriz de comparação...")
        
        features = []
        
        # Analisar cada categoria de funcionalidades
        for category, category_features in self.ORIGINAL_FEATURES.items():
            print(f"   Analisando categoria: {category}")
            
            for feature_id, feature_def in category_features.items():
                feature = self._analyze_feature(
                    f"{category}.{feature_id}",
                    feature_def['name'],
                    category,
                    feature_def['description'],
                    feature_def.get('requirements', [])
                )
                features.append(feature)
        
        # Calcular estatísticas
        by_status = {
            'not_implemented': len([f for f in features if f.status == ImplementationStatus.NOT_IMPLEMENTED]),
            'partial': len([f for f in features if f.status == ImplementationStatus.PARTIAL]),
            'complete': len([f for f in features if f.status == ImplementationStatus.COMPLETE])
        }
        
        # Por categoria
        by_category = {}
        for category in set(f.category for f in features):
            by_category[category] = {
                'not_implemented': len([f for f in features if f.category == category and f.status == ImplementationStatus.NOT_IMPLEMENTED]),
                'partial': len([f for f in features if f.category == category and f.status == ImplementationStatus.PARTIAL]),
                'complete': len([f for f in features if f.category == category and f.status == ImplementationStatus.COMPLETE])
            }
        
        # Calcular percentual de completude
        total = len(features)
        complete = by_status['complete']
        partial_weight = by_status['partial'] * 0.5  # Contar parcial como 50%
        completeness = ((complete + partial_weight) / total * 100) if total > 0 else 0
        
        matrix = ComparisonMatrix(
            generated_at=datetime.now().isoformat(),
            total_features=total,
            by_status=by_status,
            by_category=by_category,
            completeness_percentage=completeness,
            features=features
        )
        
        print(f"✅ Matriz gerada: {total} funcionalidades analisadas")
        print(f"   Completude: {completeness:.1f}%")
        
        return matrix
    
    def _analyze_feature(self, feature_id: str, name: str, category: str,
                        description: str, requirements: List[str]) -> FunctionalityFeature:
        """
        Analisa uma funcionalidade específica.
        
        Args:
            feature_id: ID único da funcionalidade
            name: Nome da funcionalidade
            category: Categoria
            description: Descrição
            requirements: Lista de requisitos (scripts, autoloads, etc)
            
        Returns:
            FunctionalityFeature com status de implementação
        """
        # Verificar quais requisitos estão implementados
        found_requirements = []
        missing_requirements = []
        code_refs = []
        
        scripts = self.code_map.get('scripts', {})
        autoloads = self.code_map.get('autoloads', {})
        
        for req in requirements:
            found = False
            
            # Verificar se é autoload
            if req in autoloads:
                found_requirements.append(req)
                code_refs.append(f"autoload:{req}")
                found = True
            
            # Verificar se é script
            for script_path, script_info in scripts.items():
                script_name = Path(script_path).stem
                if req == script_name or req in script_path:
                    found_requirements.append(req)
                    code_refs.append(f"script:{script_path}")
                    found = True
                    break
            
            if not found:
                missing_requirements.append(req)
        
        # Determinar status
        if len(found_requirements) == len(requirements) and len(requirements) > 0:
            status = ImplementationStatus.COMPLETE
            impl_details = f"Implementado: {', '.join(found_requirements)}"
        elif len(found_requirements) > 0:
            status = ImplementationStatus.PARTIAL
            impl_details = f"Parcial: {len(found_requirements)}/{len(requirements)} requisitos implementados"
        else:
            status = ImplementationStatus.NOT_IMPLEMENTED
            impl_details = "Não implementado"
        
        return FunctionalityFeature(
            id=feature_id,
            name=name,
            category=category,
            description=description,
            status=status,
            implementation_details=impl_details,
            missing_features=missing_requirements,
            code_references=code_refs,
            original_requirements=requirements
        )
    
    def save_matrix(self, matrix: ComparisonMatrix):
        """Salva matriz de comparação em arquivo JSON."""
        print("\n💾 Salvando matriz de comparação...")
        
        # Converter para dicionário
        matrix_dict = {
            'generated_at': matrix.generated_at,
            'total_features': matrix.total_features,
            'by_status': matrix.by_status,
            'by_category': matrix.by_category,
            'completeness_percentage': matrix.completeness_percentage,
            'features': [
                {
                    'id': f.id,
                    'name': f.name,
                    'category': f.category,
                    'description': f.description,
                    'status': f.status.value,
                    'implementation_details': f.implementation_details,
                    'missing_features': f.missing_features,
                    'code_references': f.code_references,
                    'original_requirements': f.original_requirements
                }
                for f in matrix.features
            ]
        }
        
        output_file = self.output_dir / "comparison_matrix.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(matrix_dict, f, indent=2, ensure_ascii=False)
        
        print(f"   ✅ Matriz salva: {output_file}")
        
        # Gerar relatório resumido
        self._generate_summary_report(matrix)
    
    def _generate_summary_report(self, matrix: ComparisonMatrix):
        """Gera relatório resumido em Markdown."""
        report_file = self.output_dir / "comparison_report.md"
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write("# Relatório de Comparação: Original vs Implementado\n\n")
            f.write(f"**Gerado em:** {matrix.generated_at}\n\n")
            f.write(f"**Completude Total:** {matrix.completeness_percentage:.1f}%\n\n")
            
            f.write("## Resumo por Status\n\n")
            f.write(f"- ✅ **Completo:** {matrix.by_status['complete']}\n")
            f.write(f"- ⚠️ **Parcial:** {matrix.by_status['partial']}\n")
            f.write(f"- ❌ **Não Implementado:** {matrix.by_status['not_implemented']}\n\n")
            
            f.write("## Resumo por Categoria\n\n")
            for category, stats in matrix.by_category.items():
                total = stats['complete'] + stats['partial'] + stats['not_implemented']
                complete_pct = (stats['complete'] / total * 100) if total > 0 else 0
                f.write(f"### {category.replace('_', ' ').title()}\n")
                f.write(f"- Completo: {stats['complete']}/{total} ({complete_pct:.1f}%)\n")
                f.write(f"- Parcial: {stats['partial']}/{total}\n")
                f.write(f"- Não Implementado: {stats['not_implemented']}/{total}\n\n")
            
            f.write("## Detalhes por Funcionalidade\n\n")
            for feature in matrix.features:
                status_icon = {
                    ImplementationStatus.COMPLETE: '✅',
                    ImplementationStatus.PARTIAL: '⚠️',
                    ImplementationStatus.NOT_IMPLEMENTED: '❌'
                }[feature.status]
                
                f.write(f"### {status_icon} {feature.name}\n\n")
                f.write(f"**Categoria:** {feature.category}\n\n")
                f.write(f"**Descrição:** {feature.description}\n\n")
                f.write(f"**Status:** {feature.status.value}\n\n")
                f.write(f"**Detalhes:** {feature.implementation_details}\n\n")
                
                if feature.code_references:
                    f.write(f"**Referências de Código:**\n")
                    for ref in feature.code_references:
                        f.write(f"- {ref}\n")
                    f.write("\n")
                
                if feature.missing_features:
                    f.write(f"**Faltando:**\n")
                    for missing in feature.missing_features:
                        f.write(f"- {missing}\n")
                    f.write("\n")
        
        print(f"   ✅ Relatório salvo: {report_file}")


def main():
    """Função principal."""
    import sys
    
    if len(sys.argv) > 1:
        godot_project_path = sys.argv[1]
    else:
        godot_project_path = Path(__file__).parent.parent / "godot_project"
    
    print("=" * 70)
    print("📊 Gerador de Matriz de Comparação")
    print("=" * 70)
    print(f"📁 Projeto Godot: {godot_project_path}")
    print()
    
    generator = ComparisonMatrixGenerator(str(godot_project_path))
    matrix = generator.generate_matrix()
    generator.save_matrix(matrix)
    
    print("\n" + "=" * 70)
    print("✅ Matriz de comparação gerada!")
    print("=" * 70)
    print(f"📊 Completude: {matrix.completeness_percentage:.1f}%")
    print(f"📁 Arquivos salvos em: {generator.output_dir}")


if __name__ == "__main__":
    main()

