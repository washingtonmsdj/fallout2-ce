extends Node

func _ready():
    print("Testing GameLogger...")

    # Test if GameLogger is available
    var logger = get_node_or_null("/root/GameLogger")
    if logger:
        print("✓ GameLogger autoload found")
        if logger.has_method("info"):
            print("✓ GameLogger has info method")
            logger.info("GameLogger test message")
            print("✓ GameLogger.info() called successfully")
        else:
            print("✗ GameLogger missing info method")
    else:
        print("✗ GameLogger autoload not found")

    print("Test completed.")
    get_tree().quit()