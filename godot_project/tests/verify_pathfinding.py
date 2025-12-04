#!/usr/bin/env python3
"""
Verify the pathfinding validity logic
This tests that paths don't pass through blocked tiles
"""

import random
from collections import deque

class PathNode:
    def __init__(self, pos, elevation=0):
        self.position = pos
        self.elevation = elevation
        self.g_cost = float('inf')
        self.h_cost = 0.0
        self.f_cost = float('inf')
        self.parent = None
    
    def calculate_f_cost(self):
        self.f_cost = self.g_cost + self.h_cost

def heuristic(from_pos, to_pos):
    """Hexagonal distance heuristic"""
    dx = abs(to_pos[0] - from_pos[0])
    dy = abs(to_pos[1] - from_pos[1])
    return float(max(dx, dy))

def get_neighbors(tile, map_width, map_height):
    """Get valid hexagonal neighbors"""
    hex_offsets = [
        (1, -1),   # NE
        (1, 0),    # E
        (0, 1),    # SE
        (-1, 1),   # SW
        (-1, 0),   # W
        (0, -1)    # NW
    ]
    
    neighbors = []
    for offset in hex_offsets:
        neighbor = (tile[0] + offset[0], tile[1] + offset[1])
        if 0 <= neighbor[0] < map_width and 0 <= neighbor[1] < map_height:
            neighbors.append(neighbor)
    
    return neighbors

def find_path(start, end, obstacles, map_width=200, map_height=200):
    """A* pathfinding implementation"""
    if start == end:
        return []
    
    if end in obstacles:
        return []
    
    open_list = []
    closed_set = set()
    node_map = {}
    
    start_node = PathNode(start)
    start_node.g_cost = 0
    start_node.h_cost = heuristic(start, end)
    start_node.calculate_f_cost()
    
    open_list.append(start_node)
    node_map[start] = start_node
    
    while open_list:
        # Find node with lowest f_cost
        current = min(open_list, key=lambda n: n.f_cost)
        open_list.remove(current)
        closed_set.add(current.position)
        
        # Reached destination?
        if current.position == end:
            path = []
            node = current
            while node:
                path.insert(0, node.position)
                node = node.parent
            return path
        
        # Process neighbors
        neighbors = get_neighbors(current.position, map_width, map_height)
        for neighbor_pos in neighbors:
            if neighbor_pos in closed_set:
                continue
            
            if neighbor_pos in obstacles:
                continue
            
            movement_cost = 1.0
            tentative_g_cost = current.g_cost + movement_cost
            
            if neighbor_pos in node_map:
                neighbor_node = node_map[neighbor_pos]
            else:
                neighbor_node = PathNode(neighbor_pos)
                neighbor_node.h_cost = heuristic(neighbor_pos, end)
                node_map[neighbor_pos] = neighbor_node
            
            if tentative_g_cost < neighbor_node.g_cost:
                neighbor_node.parent = current
                neighbor_node.g_cost = tentative_g_cost
                neighbor_node.calculate_f_cost()
                
                if neighbor_node not in open_list:
                    open_list.append(neighbor_node)
    
    return []

def verify_path_validity(path, obstacles):
    """
    Verify that a path doesn't pass through any obstacles
    """
    if not path:
        return True  # Empty path is valid
    
    for tile in path:
        if tile in obstacles:
            return False
    
    return True

def verify_path_connectivity(path):
    """
    Verify that path tiles are connected (adjacent)
    """
    if len(path) <= 1:
        return True
    
    hex_offsets = [
        (1, -1), (1, 0), (0, 1),
        (-1, 1), (-1, 0), (0, -1)
    ]
    
    for i in range(len(path) - 1):
        current = path[i]
        next_tile = path[i + 1]
        
        # Check if next tile is adjacent to current
        diff = (next_tile[0] - current[0], next_tile[1] - current[1])
        if diff not in hex_offsets:
            return False
    
    return True

def test_pathfinding_validity(num_iterations=100):
    """Test the pathfinding validity property"""
    passed = 0
    failed = 0
    failures = []
    
    map_width = 50
    map_height = 50
    
    for i in range(num_iterations):
        # Generate random obstacles
        num_obstacles = random.randint(10, 100)
        obstacles = set()
        for _ in range(num_obstacles):
            obs_x = random.randint(0, map_width - 1)
            obs_y = random.randint(0, map_height - 1)
            obstacles.add((obs_x, obs_y))
        
        # Generate random start and end
        start = (random.randint(0, map_width - 1), random.randint(0, map_height - 1))
        end = (random.randint(0, map_width - 1), random.randint(0, map_height - 1))
        
        # Make sure start and end are not obstacles
        obstacles.discard(start)
        obstacles.discard(end)
        
        # Find path
        path = find_path(start, end, obstacles, map_width, map_height)
        
        # Verify properties
        valid_no_obstacles = verify_path_validity(path, obstacles)
        valid_connectivity = verify_path_connectivity(path)
        
        # If path exists, verify it's valid
        # If path doesn't exist, that's also valid (no path possible)
        if valid_no_obstacles and valid_connectivity:
            passed += 1
        else:
            failed += 1
            failures.append({
                'iteration': i,
                'start': start,
                'end': end,
                'path_length': len(path),
                'num_obstacles': len(obstacles),
                'valid_no_obstacles': valid_no_obstacles,
                'valid_connectivity': valid_connectivity
            })
    
    print(f"=== Property Test: Pathfinding Validity ===")
    print(f"Passed: {passed} / {num_iterations}")
    print(f"Failed: {failed} / {num_iterations}")
    
    if failed > 0:
        print("\n=== Failed Cases (first 5) ===")
        for failure in failures[:5]:
            print(f"Iteration {failure['iteration']}:")
            print(f"  Start: {failure['start']}")
            print(f"  End: {failure['end']}")
            print(f"  Path length: {failure['path_length']}")
            print(f"  Obstacles: {failure['num_obstacles']}")
            print(f"  No obstacles in path: {failure['valid_no_obstacles']}")
            print(f"  Path connected: {failure['valid_connectivity']}")
        
        if len(failures) > 5:
            print(f"... and {len(failures) - 5} more failures")
        
        print("\nPROPERTY TEST FAILED")
        return False
    else:
        print("\nPROPERTY TEST PASSED")
        return True

if __name__ == "__main__":
    success = test_pathfinding_validity(100)
    exit(0 if success else 1)
