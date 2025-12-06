# BuildingRenderer Documentation

## Overview

The BuildingRenderer is a specialized rendering component that draws buildings as 3D-looking isometric cubes with proper shading and visual variants based on building condition.

## Features

### 1. 3D Isometric Cubes

Buildings are rendered as three-faced isometric cubes with:
- **Top face**: Base color
- **Right face**: Lightened by 15% (simulating light from the right)
- **Left face**: Darkened by 25% (simulating shadow)
- **Outlines**: Darkened by 50% for definition

### 2. Visual Variants

Buildings have 5 visual variants based on their condition:

| Variant | Condition Range | Visual Effect |
|---------|----------------|---------------|
| PRISTINE | 90-100% | Lightened colors, bright windows, clean appearance |
| GOOD | 70-89% | Normal colors, standard windows |
| DAMAGED | 40-69% | Darkened colors, broken windows, visible cracks |
| RUINED | 10-39% | Very dark colors, holes in walls, debris |
| MAKESHIFT | 0-9% | Patched appearance with metal plates |

### 3. Building-Specific Details

Each building type has unique visual details:

- **Houses**: Triangular roofs
- **Water Pump**: Circular water tank on top
- **Farms/Greenhouses**: Plant decorations
- **Medical Clinic**: Red cross symbol
- **Shops/Markets**: Dollar sign ($)
- **Power Plant**: Chimney with animated smoke (when operational)
- **Watchtower**: Observation platform at the top

### 4. Construction Progress

Buildings under construction display a progress bar showing completion percentage.

## Usage

### Basic Setup

```gdscript
# Create renderer
var building_renderer = BuildingRenderer.new()

# Set up systems
building_renderer.set_systems(grid_system, building_system, building_templates)
building_renderer.set_tile_size(64.0, 32.0)

# Draw a single building
building_renderer.draw_building(canvas_item, building)

# Draw all buildings (with automatic depth sorting)
building_renderer.draw_all_buildings(canvas_item)
```

### Getting Building Properties

```gdscript
# Get base color for a building type
var color = building_renderer.get_building_base_color(BuildingSystem.BuildingType.SMALL_HOUSE)

# Get visual variant based on condition
var variant = building_renderer.get_visual_variant(building)

# Get height based on type and level
var height = building_renderer.get_building_height(building_type, level)

# Apply variant modifier to a color
var modified_color = building_renderer.apply_variant_modifier(base_color, variant)
```

### Coordinate Conversion

```gdscript
# Convert grid coordinates to isometric
var iso_pos = building_renderer.grid_to_iso(Vector2(10, 10))
```

## Architecture

### Class Structure

```
BuildingRenderer
├── Visual Variant System
│   ├── get_visual_variant()
│   └── apply_variant_modifier()
├── Color System
│   └── get_building_base_color()
├── Height System
│   └── get_building_height()
├── Drawing System
│   ├── draw_iso_cube()
│   ├── draw_building()
│   └── draw_all_buildings()
└── Detail System
    ├── _draw_variant_details()
    ├── _draw_windows()
    ├── _draw_cracks()
    ├── _draw_holes()
    ├── _draw_debris()
    ├── _draw_patches()
    ├── _draw_building_type_details()
    └── _draw_construction_indicator()
```

### Rendering Pipeline

1. **Depth Sorting**: Buildings are sorted by (x + y) position for correct visual layering
2. **Base Cube**: Draw the three faces of the isometric cube with shading
3. **Variant Details**: Add condition-specific details (cracks, holes, patches)
4. **Type Details**: Add building-type-specific decorations
5. **Construction Indicator**: Show progress bar if under construction

## Color Palette

### Residential Buildings
- Small House: `Color(0.75, 0.55, 0.35)` - Light brown
- Medium House: `Color(0.70, 0.50, 0.30)` - Medium brown
- Large House: `Color(0.65, 0.45, 0.25)` - Dark brown
- Apartment: `Color(0.60, 0.50, 0.40)` - Gray-brown

### Commercial Buildings
- Shop: `Color(0.35, 0.55, 0.75)` - Light blue
- Market: `Color(0.30, 0.50, 0.70)` - Medium blue
- Restaurant: `Color(0.40, 0.60, 0.80)` - Bright blue
- Bank: `Color(0.25, 0.45, 0.65)` - Dark blue

### Industrial Buildings
- Factory: `Color(0.55, 0.55, 0.55)` - Light gray
- Workshop: `Color(0.50, 0.50, 0.50)` - Medium gray
- Warehouse: `Color(0.45, 0.45, 0.45)` - Dark gray
- Power Plant: `Color(0.85, 0.85, 0.25)` - Yellow

### Agricultural Buildings
- Farm: `Color(0.35, 0.70, 0.25)` - Bright green
- Greenhouse: `Color(0.40, 0.75, 0.30)` - Light green
- Grain Mill: `Color(0.50, 0.60, 0.30)` - Olive green

### Military Buildings
- Guard Post: `Color(0.40, 0.50, 0.40)` - Light military green
- Barracks: `Color(0.35, 0.45, 0.35)` - Medium military green
- Watchtower: `Color(0.45, 0.55, 0.45)` - Bright military green
- Armory: `Color(0.30, 0.40, 0.30)` - Dark military green

### Utility Buildings
- Water Pump: `Color(0.25, 0.45, 0.85)` - Water blue
- Medical Clinic: `Color(0.85, 0.25, 0.25)` - Medical red
- School: `Color(0.70, 0.60, 0.40)` - Tan
- Library: `Color(0.60, 0.50, 0.70)` - Purple

### Special Buildings
- Vault: `Color(0.20, 0.30, 0.50)` - Dark blue
- Settlement Center: `Color(0.65, 0.45, 0.25)` - Brown

## Performance Considerations

- Buildings are depth-sorted once per frame
- Drawing operations use Godot's built-in canvas drawing functions
- No texture loading required - all visuals are procedurally generated
- Efficient for rendering 100+ buildings simultaneously

## Testing

The BuildingRenderer includes comprehensive tests in `scripts/test/test_building_renderer.gd`:

- Visual variant determination
- Color assignment and modification
- Height calculation
- Coordinate conversion
- Drawing operations
- Building type distinctiveness

## Requirements Validation

This implementation satisfies:
- **Requirement 7.4**: Buildings rendered as 3D-looking isometric cubes with proper shading
- **Requirement 22.7**: Visual variants (damaged, pristine, makeshift) based on building condition

## Future Enhancements

Potential improvements:
1. Animated details (smoke, lights, movement)
2. Weather effects on building appearance
3. Time-of-day lighting variations
4. Seasonal decorations
5. Damage animations during raids
6. Construction animation sequences
