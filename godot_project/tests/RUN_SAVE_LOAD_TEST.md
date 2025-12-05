# How to Run the Save/Load Round-Trip Property Test

## Quick Start

### Option 1: Logic Test Only (No Godot Required)

This verifies the mathematical correctness without running Godot:

```bash
python godot_project/tests/test_save_load_roundtrip_logic.py
```

**Expected Output**: All 4 logic tests should pass ✅

### Option 2: Full Property Test (Requires Godot)

This runs 100 iterations with random game states in Godot:

```bash
# Method 1: Direct Godot execution
godot --headless --path godot_project tests/property/test_save_load_roundtrip.tscn

# Method 2: Using Python wrapper
python godot_project/tests/verify_save_load_roundtrip.py
```

**Expected Output**: 100/100 iterations should pass ✅

### Option 3: Run All Tests

To run all property tests including this one:

```bash
python godot_project/tests/run_all_tests.py
```

## Test Configuration

- **Iterations**: 100 per run
- **Test Slot**: Slot 9 (to avoid conflicts with user saves)
- **Timeout**: 60 seconds
- **Exit Codes**: 0 = success, 1 = failure

## What the Test Does

1. **Generates** random game states (player stats, inventory, maps, etc.)
2. **Applies** the state to the game
3. **Saves** the game to a test slot
4. **Loads** the game back
5. **Compares** the loaded state with the original
6. **Reports** any differences found

## Interpreting Results

### Success (Exit Code 0)
```
=== Test Results ===
Passed: 100 / 100
Failed: 0 / 100

PROPERTY TEST PASSED
```

All game states were correctly preserved through save/load cycles.

### Failure (Exit Code 1)
```
=== Test Results ===
Passed: 95 / 100
Failed: 5 / 100

=== Failed Cases ===
Iteration 23:
  Differences found:
    - Player.hp: 50 != 45
    - Inventory item count: 5 != 4
```

Some game states were not correctly preserved. The test will show the first 5 failures with details.

## Troubleshooting

### "Godot executable not found"

Set the `GODOT_BIN` environment variable:

```bash
# Windows
set GODOT_BIN=C:\path\to\godot.exe

# Linux/Mac
export GODOT_BIN=/path/to/godot
```

### "SaveSystem not found"

Make sure the SaveSystem autoload is configured in `project.godot`:

```ini
[autoload]
SaveSystem="*res://scripts/systems/save_system.gd"
```

### "Test times out"

The test has a 60-second timeout. If it times out:
- Check if Godot is hanging
- Reduce NUM_ITERATIONS in the test file
- Check system resources

### "Save failed" or "Load failed"

Check the save directory permissions:
- Default: `user://saves/`
- On Windows: `%APPDATA%\Godot\app_userdata\<project_name>/saves/`
- On Linux: `~/.local/share/godot/app_userdata/<project_name>/saves/`

## Advanced Usage

### Running with Custom Iterations

Edit `test_save_load_roundtrip.gd`:

```gdscript
const NUM_ITERATIONS = 1000  # Change from 100 to 1000
```

### Running with Specific Seed

For reproducible tests, add a seed:

```gdscript
func _ready():
    seed(12345)  # Add this line
    # ... rest of code
```

### Debugging Failed Cases

To see more details about failures, increase the failure display limit:

```gdscript
for i in range(min(10, test_results.size())):  # Change from 5 to 10
```

## CI Integration

For continuous integration, use the logic test (no Godot required):

```yaml
# .github/workflows/test.yml
- name: Run Save/Load Logic Tests
  run: python godot_project/tests/test_save_load_roundtrip_logic.py
```

For full testing with Godot in CI:

```yaml
- name: Install Godot
  run: |
    wget https://downloads.tuxfamily.org/godotengine/4.2/Godot_v4.2-stable_linux.x86_64.zip
    unzip Godot_v4.2-stable_linux.x86_64.zip
    
- name: Run Property Tests
  run: |
    export GODOT_BIN=./Godot_v4.2-stable_linux.x86_64
    python godot_project/tests/verify_save_load_roundtrip.py
```

## Related Files

- **Test Implementation**: `tests/property/test_save_load_roundtrip.gd`
- **Python Wrapper**: `tests/verify_save_load_roundtrip.py`
- **Logic Tests**: `tests/test_save_load_roundtrip_logic.py`
- **System Under Test**: `scripts/systems/save_system.gd`
- **Documentation**: `tests/SAVE_LOAD_ROUNDTRIP_TEST_SUMMARY.md`

## Support

If you encounter issues:

1. Check the test summary: `tests/SAVE_LOAD_ROUNDTRIP_TEST_SUMMARY.md`
2. Review the SaveSystem implementation: `scripts/systems/save_system.gd`
3. Check the test README: `tests/README.md`
4. Run the logic test first to isolate issues

---

**Property**: Round-trip de Formatos de Arquivo  
**Validates**: Requirements 3.4  
**Status**: ✅ Implementation Complete
