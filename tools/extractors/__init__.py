"""
Módulo de extratores de assets do Fallout 2.

Este módulo contém todos os extratores necessários para extrair e converter
assets do Fallout 2 para formatos compatíveis com Godot Engine.
"""

__version__ = "1.0.0"

from .animation_extractor import (
    AnimationExtractor,
    AnimationData,
    AnimationFrame,
    CritterData,
    extract_all_animations,
)

from .spritesheet_generator import (
    SpritesheetGenerator,
    SpritesheetMetadata,
    SpritesheetCollection,
)

from .spriteframes_generator import (
    SpriteFramesGenerator,
    SpriteFramesConfig,
    generate_godot_spriteframes,
)

