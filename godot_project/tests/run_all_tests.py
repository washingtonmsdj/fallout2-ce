#!/usr/bin/env python3
"""
Run all property-based test verification scripts
This can be used in CI or for quick verification without Godot
"""

import subprocess
import sys
from pathlib import Path

def run_test(script_path):
    """Run a single test script and return success status"""
    print(f"\n{'='*60}")
    print(f"Running: {script_path.name}")
    print('='*60)
    
    try:
        result = subprocess.run(
            [sys.executable, str(script_path)],
            capture_output=False,
            check=False
        )
        return result.returncode == 0
    except Exception as e:
        print(f"ERROR running {script_path.name}: {e}")
        return False

def main():
    """Run all verification tests"""
    tests_dir = Path(__file__).parent
    
    # Find all verify_*.py scripts
    test_scripts = sorted(tests_dir.glob("verify_*.py"))
    
    if not test_scripts:
        print("No test scripts found!")
        return 1
    
    print(f"Found {len(test_scripts)} test scripts")
    
    results = {}
    for script in test_scripts:
        results[script.name] = run_test(script)
    
    # Print summary
    print(f"\n{'='*60}")
    print("TEST SUMMARY")
    print('='*60)
    
    passed = sum(1 for success in results.values() if success)
    failed = len(results) - passed
    
    for script_name, success in results.items():
        status = "✅ PASSED" if success else "❌ FAILED"
        print(f"{status}: {script_name}")
    
    print(f"\nTotal: {passed} passed, {failed} failed out of {len(results)} tests")
    
    return 0 if failed == 0 else 1

def run_all_tests_summary():
    """Run all tests and provide detailed summary"""
    tests_dir = Path(__file__).parent
    test_scripts = sorted(tests_dir.glob("verify_*.py"))
    
    if not test_scripts:
        print("No test scripts found!")
        return 1
    
    print("="*70)
    print("FALLOUT 2 GODOT MIGRATION - TEST SUITE")
    print("="*70)
    print(f"\nRunning {len(test_scripts)} property-based tests...\n")
    
    results = {}
    for script in test_scripts:
        results[script.name] = run_test(script)
    
    # Print detailed summary
    print(f"\n{'='*70}")
    print("DETAILED TEST RESULTS")
    print('='*70)
    
    categories = {
        'Rendering': ['verify_roundtrip.py', 'verify_sprite_ordering.py', 'verify_elevation_layers.py'],
        'Camera': ['verify_camera_clamping.py'],
        'Pathfinding': ['verify_pathfinding.py', 'verify_ap_consumption.py', 'verify_run_speed.py'],
        'Combat': ['verify_combat_turn_order.py', 'verify_hit_chance.py', 'verify_damage_formula.py', 'verify_combat_state.py'],
        'Save System': ['verify_save_system.py', 'verify_save_load_roundtrip.py'],
        'Map System': ['verify_map_system_loading.py']
    }
    
    for category, test_files in categories.items():
        print(f"\n{category}:")
        for test_file in test_files:
            if test_file in results:
                status = "✅ PASSED" if results[test_file] else "❌ FAILED"
                print(f"  {status}: {test_file}")
    
    # Overall summary
    passed = sum(1 for success in results.values() if success)
    failed = len(results) - passed
    
    print(f"\n{'='*70}")
    print("OVERALL SUMMARY")
    print('='*70)
    print(f"Total Tests: {len(results)}")
    print(f"Passed: {passed} ({passed*100//len(results)}%)")
    print(f"Failed: {failed}")
    print(f"\nStatus: {'✅ ALL TESTS PASSED' if failed == 0 else '❌ SOME TESTS FAILED'}")
    print('='*70)
    
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(run_all_tests_summary())
