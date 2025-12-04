# Godot Game Migration Tests

This directory contains property-based tests and unit tests for the Fallout 2 to Godot migration project.

## Test Structure

```
tests/
├── property/           # Property-based tests (PBT)
│   ├── test_isometric_coordinate_roundtrip.gd
│   ├── test_sprite_depth_ordering.gd
│   └── test_elevation_layer_separation.gd
├── verify_*.py        # Python verification scripts (for CI/testing without Godot)
└── README.md          # This file
```

## Running Tests

### With Godot Engine

To run a specific property test in Godot:

```bash
godot --headless --path godot_project tests/property/test_isometric_coordinate_roundtrip.tscn
```

### With Python (Verification)

Python scripts verify the mathematical correctness without requiring Godot:

```bash
python godot_project/tests/verify_roundtrip.py
python godot_project/tests/verify_sprite_ordering.py
python godot_project/tests/verify_elevation_layers.py
```

## Property Tests

### Property 1: Isometric Coordinate Conversion Round-Trip
**Validates: Requirements 1.1, 1.5**

For any tile position (x, y) and elevation e, converting to screen coordinates and back to tile coordinates SHALL produce the original tile position.

- **Test File**: `test_isometric_coordinate_roundtrip.gd`
- **Verification**: `verify_roundtrip.py`
- **Status**: ✅ PASSED (100/100 iterations)

### Property 2: Sprite Depth Ordering Consistency
**Validates: Requirements 1.2**

For any set of sprites with different positions, the sort order SHALL be deterministic and consistent with the rule: sprites with higher y + elevation * offset appear in front.

- **Test File**: `test_sprite_depth_ordering.gd`
- **Verification**: `verify_sprite_ordering.py`
- **Status**: ✅ PASSED (100/100 iterations)

### Property 3: Elevation Layer Separation
**Validates: Requirements 1.4**

For any map with N distinct elevations, the renderer SHALL create exactly N separate rendering layers.

- **Test File**: `test_elevation_layer_separation.gd`
- **Verification**: `verify_elevation_layers.py`
- **Status**: ✅ PASSED (100/100 iterations)

## Test Configuration

All property tests run with:
- **Iterations**: 100 per test
- **Random seed**: Different each run for comprehensive coverage
- **Exit codes**: 0 for success, 1 for failure

## Adding New Tests

To add a new property test:

1. Create a new `.gd` file in `tests/property/`
2. Extend `Node` and implement `_ready()` function
3. Include the property comment header:
   ```gdscript
   ## **Feature: godot-game-migration, Property N: Property Name**
   ## **Validates: Requirements X.Y**
   ```
4. Run at least 100 iterations with random inputs
5. Create a corresponding `.tscn` file
6. Optionally create a Python verification script

## CI Integration

The Python verification scripts can be run in CI without requiring Godot installation:

```bash
# Run all verification tests
python godot_project/tests/verify_roundtrip.py && \
python godot_project/tests/verify_sprite_ordering.py && \
python godot_project/tests/verify_elevation_layers.py
```
