extends GdUnitTestSuite
## Property test for dialog option filtering
## **Feature: fallout2-complete-migration, Property 15: Dialog Option Filtering**
## **Validates: Requirements 5.2**

class_name TestDialogOptionFiltering
	
	var dialog_system: DialogSystem
	var player: Critter
	var npc: Critter
	
	func before_test() -> void:
		dialog_system = DialogSystem.new()
		player = Critter.new()
		player.critter_name = "Player"
		player.is_player = true
		player.stats = StatData.new()
		player.skills = SkillData.new()
		
		npc = Critter.new()
		npc.critter_name = "NPC"
		npc.stats = StatData.new()
		npc.skills = SkillData.new()
	
	## Property: For any dialog node, only options whose conditions evaluate to true for the current player state SHALL be displayed
	func test_dialog_option_filtering_property() -> void:
		# Run 100 iterations with random player stats and skill values
		for i in range(100):
			# Randomize player stats
			player.stats.strength = randi_range(1, 10)
			player.stats.perception = randi_range(1, 10)
			player.stats.endurance = randi_range(1, 10)
			player.stats.charisma = randi_range(1, 10)
			player.stats.intelligence = randi_range(1, 10)
			player.stats.agility = randi_range(1, 10)
			player.stats.luck = randi_range(1, 10)
			
			# Randomize player skills
			for skill in SkillData.Skill.values():
				player.skills.skill_values[skill] = randi_range(0, 200)
			
			player.karma = randi_range(-1000, 1000)
			
			# Create a dialog node with multiple options
			var node = DialogNode.new()
			node.id = "test_node"
			node.speaker = "NPC"
			node.text = "What do you want?"
			
			# Option 1: Always available
			var option1 = DialogOption.new()
			option1.id = "opt1"
			option1.text = "Hello"
			option1.next_node_id = "node2"
			option1.conditions = []
			
			# Option 2: Requires high charisma
			var condition2 = DialogCondition.new()
			condition2.condition_type = DialogCondition.ConditionType.STAT_CHECK
			condition2.stat = GameConstants.PrimaryStat.CHARISMA
			condition2.stat_threshold = 7
			
			var option2 = DialogOption.new()
			option2.id = "opt2"
			option2.text = "Charm them"
			option2.next_node_id = "node3"
			option2.conditions = [condition2]
			
			# Option 3: Requires high speech skill
			var condition3 = DialogCondition.new()
			condition3.condition_type = DialogCondition.ConditionType.SKILL_CHECK
			condition3.skill = SkillData.Skill.SPEECH
			condition3.skill_difficulty = 60
			
			var option3 = DialogOption.new()
			option3.id = "opt3"
			option3.text = "Persuade them"
			option3.next_node_id = "node4"
			option3.conditions = [condition3]
			
			# Option 4: Requires good karma
			var condition4 = DialogCondition.new()
			condition4.condition_type = DialogCondition.ConditionType.KARMA
			condition4.karma_threshold = 100
			
			var option4 = DialogOption.new()
			option4.id = "opt4"
			option4.text = "Help them"
			option4.next_node_id = "node5"
			option4.conditions = [condition4]
			
			node.options = [option1, option2, option3, option4]
			
			# Get available options
			var available = node.get_available_options(player)
			
			# Verify that option1 is always available
			assert_true(option1 in available, "Option 1 should always be available")
			
			# Verify that option2 is available only if charisma >= 7
			if player.stats.charisma >= 7:
				assert_true(option2 in available, "Option 2 should be available when charisma >= 7")
			else:
				assert_false(option2 in available, "Option 2 should not be available when charisma < 7")
			
			# Verify that option3 is available only if speech skill >= 60
			if player.skills.get_skill_value(SkillData.Skill.SPEECH) >= 60:
				assert_true(option3 in available, "Option 3 should be available when speech >= 60")
			else:
				assert_false(option3 in available, "Option 3 should not be available when speech < 60")
			
			# Verify that option4 is available only if karma >= 100
			if player.karma >= 100:
				assert_true(option4 in available, "Option 4 should be available when karma >= 100")
			else:
				assert_false(option4 in available, "Option 4 should not be available when karma < 100")
			
			# Verify that all returned options are actually available
			for option in available:
				assert_true(option.is_available(player), "All returned options should be available")
