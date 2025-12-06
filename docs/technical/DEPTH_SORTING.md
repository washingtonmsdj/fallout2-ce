# Depth Sorting Implementation

## Overview

The depth sorting system ensures correct visual layering of all entities in the isometric city view. This is critical for maintaining visual coherence when buildings, citizens, and roads overlap.

## Implementation Details

### RenderEntity Class

A lightweight structure that wraps entities with their depth information:

```gdscript
class RenderEntity:
    var type: String      # "road", "building", "citizen"
    var depth: float      # Depth value for sorting (y + x)
    var data: Dictionary  # Original entity data
```

### Depth Calculation

Different entity types use different depth calculations to ensure proper layering:

1. **Roads**: `depth = position.x + position.y`
   - Uses the tile position directly

2. **Buildings**: `depth = position.x + position.y + 2.0`
   - Adds +2.0 to account for building size (2x2 tiles)
   - This ensures buildings appear in front of their base tiles

3. **Citizens**: `depth = (position.x + 0.5) + (position.y + 0.5)`
   - Uses center position of the tile
   - Ensures citizens appear correctly relative to tiles they occupy

### Rendering Order

The `_draw_entities_with_depth_sorting()` function:

1. Collects all entities (roads, buildings, citizens) into a single array
2. Calculates depth for each entity
3. Sorts entities by depth (ascending)
4. Renders entities in sorted order

This ensures that entities further back (lower depth) are drawn first, and entities in front (higher depth) are drawn last, appearing on top.

### Example

For entities at these positions:
- Road at (2, 2): depth = 4.0
- Building at (3, 3): depth = 8.0 (6 + 2)
- Citizen at (4, 4): depth = 8.5 (4.5 + 4.5)

Render order: Road → Building → Citizen

## Benefits

1. **Correct Occlusion**: Entities properly occlude those behind them
2. **Visual Clarity**: No z-fighting or visual artifacts
3. **Scalable**: Works with any number of entities
4. **Efficient**: Single sort per frame, O(n log n) complexity

## Testing

See `scripts/test/test_depth_sorting.gd` for comprehensive tests covering:
- Basic depth sorting
- Overlapping entities
- Same-depth entities
- Edge cases

## Requirements Validation

This implementation validates **Requirement 7.2**: "THE Renderer SHALL implement depth sorting for correct visual layering"
