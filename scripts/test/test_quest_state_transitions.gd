extends GdUnitTestSuite
## Property test for quest state transitions
## **Feature: fallout2-complete-migration, Property 18: Quest State Transitions**
## **Validates: Requirements 6.1, 6.2, 6.3, 6.6**

class_name TestQuestStateTransitions
extends GdUnitTestSuite

var quest_system: QuestSystem
var player: Critter

func before_test() -> void:
	quest_system = QuestSystem.new()
	player = Critter.new()
	player.critter_name = "Player"
	player.is_player = true
	player.stats = StatData.new()
	player.skills = SkillData.new()
	player.experience = 0
	player.karma = 0
	quest_system.set_player(player)

## Property: For any quest, state transitions SHALL follow: 
## INACTIVE→ACTIVE→(COMPLETED|FAILED), never backwards
func test_quest_state_transitions_property() -> void:
	# Test valid state transitions
	var quest = Quest.new()
	quest.id = "test_quest"
	quest.title = "Test Quest"
	quest.description = "A test quest"
	
	# Initial state should be INACTIVE
	assert_that(quest.state).is_equal(Quest.QuestState.INACTIVE, "Quest should start as INACTIVE")
	
	# INACTIVE → ACTIVE
	quest.activate()
	assert_that(quest.state).is_equal(Quest.QuestState.ACTIVE, "Quest should transition to ACTIVE")
	
	# ACTIVE → COMPLETED
	quest.complete()
	assert_that(quest.state).is_equal(Quest.QuestState.COMPLETED, "Quest should transition to COMPLETED")
	
	# Test that we cannot go backwards
	# COMPLETED → ACTIVE (should not work)
	var old_state = quest.state
	quest.activate()
	assert_that(quest.state).is_equal(old_state, "Quest should not transition backwards from COMPLETED to ACTIVE")
	
	# Test FAILED transition
	var quest2 = Quest.new()
	quest2.id = "test_quest2"
	quest2.activate()
	quest2.fail()
	assert_that(quest2.state).is_equal(Quest.QuestState.FAILED, "Quest should transition to FAILED")
	
	# FAILED → ACTIVE (should not work)
	old_state = quest2.state
	quest2.activate()
	assert_that(quest2.state).is_equal(old_state, "Quest should not transition backwards from FAILED to ACTIVE")

## Test that quest system manages state transitions correctly
func test_quest_system_state_management() -> void:
	var quest = Quest.new()
	quest.id = "system_test_quest"
	quest.title = "System Test Quest"
	
	# Add quest (should be INACTIVE initially, then activated)
	quest_system.add_quest(quest)
	assert_that(quest.state).is_equal(Quest.QuestState.ACTIVE, "Quest should be activated when added")
	assert_that(quest_system.is_quest_active(quest.id)).is_true("Quest should be in active list")
	
	# Complete quest
	quest_system.complete_quest(quest.id)
	assert_that(quest.state).is_equal(Quest.QuestState.COMPLETED, "Quest should be completed")
	assert_that(quest_system.is_quest_completed(quest.id)).is_true("Quest should be in completed list")
	assert_that(quest_system.is_quest_active(quest.id)).is_false("Quest should not be in active list")

## Test quest failure state transition
func test_quest_failure_transition() -> void:
	var quest = Quest.new()
	quest.id = "failure_test_quest"
	quest.title = "Failure Test Quest"
	
	quest_system.add_quest(quest)
	quest_system.fail_quest(quest.id)
	
	assert_that(quest.state).is_equal(Quest.QuestState.FAILED, "Quest should be failed")
	assert_that(quest_system.is_quest_failed(quest.id)).is_true("Quest should be in failed list")
	assert_that(quest_system.is_quest_active(quest.id)).is_false("Quest should not be in active list")

## Test that objectives are marked as failed when quest fails
func test_objectives_fail_with_quest() -> void:
	var quest = Quest.new()
	quest.id = "objective_fail_test"
	quest.title = "Objective Fail Test"
	
	var objective = QuestObjective.new()
	objective.id = "obj1"
	objective.title = "Objective 1"
	objective.required_count = 1
	quest.objectives = [objective]
	
	quest_system.add_quest(quest)
	quest_system.fail_quest(quest.id)
	
	assert_that(objective.is_failed()).is_true("Objective should be marked as failed when quest fails")

## Test that completed quests cannot be reactivated
func test_completed_quest_cannot_reactivate() -> void:
	var quest = Quest.new()
	quest.id = "completed_reactivate_test"
	quest.title = "Completed Reactivate Test"
	
	quest_system.add_quest(quest)
	quest_system.complete_quest(quest.id)
	
	# Try to activate again
	var old_state = quest.state
	quest.activate()
	assert_that(quest.state).is_equal(old_state, "Completed quest should not be reactivated")

## Test that failed quests cannot be reactivated
func test_failed_quest_cannot_reactivate() -> void:
	var quest = Quest.new()
	quest.id = "failed_reactivate_test"
	quest.title = "Failed Reactivate Test"
	
	quest_system.add_quest(quest)
	quest_system.fail_quest(quest.id)
	
	# Try to activate again
	var old_state = quest.state
	quest.activate()
	assert_that(quest.state).is_equal(old_state, "Failed quest should not be reactivated")

## Test quest with prerequisites
func test_quest_prerequisites() -> void:
	# Create prerequisite quest
	var prereq_quest = Quest.new()
	prereq_quest.id = "prereq_quest"
	prereq_quest.title = "Prerequisite Quest"
	quest_system.add_quest(prereq_quest)
	quest_system.complete_quest(prereq_quest.id)
	
	# Create quest with prerequisite
	var quest = Quest.new()
	quest.id = "dependent_quest"
	quest.title = "Dependent Quest"
	quest.prerequisites = [prereq_quest.id]
	
	# Add quest (should be inactive until prerequisite is met)
	quest_system.add_quest(quest)
	
	# Quest should be active because prerequisite is completed
	assert_that(quest.state).is_equal(Quest.QuestState.ACTIVE, "Quest should be active when prerequisites are met")
	
	# Test with unmet prerequisite
	var quest2 = Quest.new()
	quest2.id = "dependent_quest2"
	quest2.title = "Dependent Quest 2"
	quest2.prerequisites = ["non_existent_quest"]
	
	quest_system.add_quest(quest2)
	# Quest should remain inactive
	assert_that(quest2.state).is_equal(Quest.QuestState.INACTIVE, "Quest should remain inactive when prerequisites are not met")

## Test multiple state transitions in sequence
func test_multiple_state_transitions() -> void:
	# Test a complete lifecycle
	var quest = Quest.new()
	quest.id = "lifecycle_test"
	quest.title = "Lifecycle Test"
	
	# INACTIVE
	assert_that(quest.state).is_equal(Quest.QuestState.INACTIVE)
	
	# INACTIVE → ACTIVE
	quest.activate()
	assert_that(quest.state).is_equal(Quest.QuestState.ACTIVE)
	
	# ACTIVE → COMPLETED
	quest.complete()
	assert_that(quest.state).is_equal(Quest.QuestState.COMPLETED)
	
	# Verify no backwards transitions possible
	quest.activate()
	assert_that(quest.state).is_equal(Quest.QuestState.COMPLETED, "Should not transition backwards")

## Test that quest system tracks state correctly
func test_quest_system_state_tracking() -> void:
	var quest1 = Quest.new()
	quest1.id = "tracking_test_1"
	quest_system.add_quest(quest1)
	
	var quest2 = Quest.new()
	quest2.id = "tracking_test_2"
	quest_system.add_quest(quest2)
	
	# Both should be active
	assert_that(quest_system.get_active_quests().size()).is_equal(2, "Should have 2 active quests")
	
	# Complete one
	quest_system.complete_quest(quest1.id)
	assert_that(quest_system.get_active_quests().size()).is_equal(1, "Should have 1 active quest")
	assert_that(quest_system.get_completed_quests().size()).is_equal(1, "Should have 1 completed quest")
	
	# Fail the other
	quest_system.fail_quest(quest2.id)
	assert_that(quest_system.get_active_quests().size()).is_equal(0, "Should have 0 active quests")
	assert_that(quest_system.get_failed_quests().size()).is_equal(1, "Should have 1 failed quest")
