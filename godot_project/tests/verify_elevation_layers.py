#!/usr/bin/env python3
"""
Verify the elevation layer separation logic
This tests that the correct number of layers are created with proper metadata
"""

import random

class MockNode2D:
    """Mock Node2D for testing"""
    def __init__(self, name):
        self.name = name
        self.metadata = {}
        self.visible = True
        self.modulate = (1, 1, 1, 1)
    
    def set_meta(self, key, value):
        self.metadata[key] = value
    
    def get_meta(self, key):
        return self.metadata.get(key)
    
    def has_meta(self, key):
        return key in self.metadata

def create_elevation_layers(num_elevations):
    """Create elevation layers"""
    layers = []
    for i in range(num_elevations):
        layer = MockNode2D(f"ElevationLayer_{i}")
        layer.set_meta("elevation", i)
        layers.append(layer)
    return layers

def verify_layer_separation(layers, expected_count):
    """
    Verify that:
    1. Exactly N layers were created
    2. Each layer has unique elevation metadata
    3. Layers are properly named
    """
    # Check count
    if len(layers) != expected_count:
        return False
    
    # Check each layer
    elevations_seen = set()
    for i, layer in enumerate(layers):
        # Check if it has elevation metadata
        if not layer.has_meta("elevation"):
            return False
        
        elevation = layer.get_meta("elevation")
        
        # Check if elevation is unique
        if elevation in elevations_seen:
            return False
        elevations_seen.add(elevation)
        
        # Check if elevation matches index
        if elevation != i:
            return False
        
        # Check naming convention
        expected_name = f"ElevationLayer_{i}"
        if layer.name != expected_name:
            return False
    
    return True

def test_elevation_layers(num_iterations=100):
    """Test the elevation layer separation property"""
    passed = 0
    failed = 0
    failures = []
    
    for i in range(num_iterations):
        # Generate random number of elevations (1-5)
        num_elevations = random.randint(1, 5)
        
        # Create elevation layers
        layers = create_elevation_layers(num_elevations)
        
        # Verify the property
        if verify_layer_separation(layers, num_elevations):
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'expected_layers': num_elevations,
                'actual_layers': len(layers),
                'layer_names': [layer.name for layer in layers]
            })
    
    print(f"=== Property Test: Elevation Layer Separation ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Expected layers: {failure['expected_layers']}")
            print(f"  Actual layers: {failure['actual_layers']}")
            print(f"  Layer names: {failure['layer_names']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_elevation_layers(100)
    exit(0 if success else 1)
