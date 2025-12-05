#!/usr/bin/env python3
"""
Verification script for Save/Load Round-Trip Property Test
Runs the GDScript property test and reports results
"""

import subprocess
import sys
import os

def run_property_test():
    """Run the save/load round-trip property test"""
    print("=" * 60)
    print("Save/Load Round-Trip Property Test")
    print("=" * 60)
    
    # Check if Godot is available
    godot_path = os.environ.get('GODOT_BIN', 'godot')
    
    # Check if test file exists
    test_file = "godot_project/tests/property/test_save_load_roundtrip.gd"
    if not os.path.exists(test_file):
        print(f"❌ FAILED: Test file not found: {test_file}")
        return False
    
    print(f"✅ Test file exists: {test_file}")
    
    # Create a minimal test scene to run the test
    test_scene_content = '''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/property/test_save_load_roundtrip.gd" id="1"]

[node name="TestRunner" type="Node"]
script = ExtResource("1")
'''
    
    test_scene_path = "godot_project/tests/property/test_save_load_roundtrip.tscn"
    with open(test_scene_path, 'w') as f:
        f.write(test_scene_content)
    
    print(f"✅ Created test scene: {test_scene_path}")
    
    # Run the test
    print("\nRunning property test...")
    print("-" * 60)
    
    try:
        result = subprocess.run(
            [godot_path, '--headless', '--path', 'godot_project', 'tests/property/test_save_load_roundtrip.tscn'],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        # Print output
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        
        # Check exit code
        if result.returncode == 0:
            print("-" * 60)
            print("✅ Property test PASSED")
            return True
        else:
            print("-" * 60)
            print(f"❌ Property test FAILED (exit code: {result.returncode})")
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ Test timed out after 60 seconds")
        return False
    except FileNotFoundError:
        print(f"❌ Godot executable not found: {godot_path}")
        print("Set GODOT_BIN environment variable to the Godot executable path")
        return False
    except Exception as e:
        print(f"❌ Error running test: {e}")
        return False

def main():
    """Main entry point"""
    print("\n" + "=" * 60)
    print("Property Test: Save/Load Round-Trip")
    print("Feature: complete-migration-master")
    print("Property 1: Round-trip de Formatos de Arquivo")
    print("Validates: Requirements 3.4")
    print("=" * 60 + "\n")
    
    success = run_property_test()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ VERIFICATION COMPLETE: All tests passed")
    else:
        print("❌ VERIFICATION FAILED: Some tests failed")
    print("=" * 60 + "\n")
    
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())
