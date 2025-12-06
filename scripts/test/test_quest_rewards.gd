extends GdUnitTestSuite
## Property test for quest rewards
## **Feature: fallout2-complete-migration, Property 19: Quest Reward Distribution**
## **Validates: Requirements 6.4**

class_name TestQuestRewards
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

## Property: For any completed quest, the player SHALL receive exactly 
## the XP, items, and reputation specified in QuestRewards
func test_quest_reward_distribution_property() -> void:
	var quest = Quest.new()
	quest.id = "reward_test_quest"
	quest.title = "Reward Test Quest"
	
	# Create rewards
	var rewards = Quest.QuestRewards.new()
	rewards.experience = 100
	rewards.caps = 50
	rewards.karma = 10
	rewards.items = ["item1", "item2"]
	rewards.reputation_changes = {"faction1": 5, "faction2": -3}
	
	quest.rewards = rewards
	
	# Set initial player values
	player.experience = 0
	player.karma = 0
	
	# Add and complete quest
	quest_system.add_quest(quest)
	quest_system.complete_quest(quest.id)
	
	# Verify XP was granted
	assert_that(player.experience).is_equal(100, "Player should receive exactly 100 XP")
	
	# Verify karma was granted
	assert_that(player.karma).is_equal(10, "Player should receive exactly 10 karma")
	
	# Note: Items and caps will be verified when inventory system is implemented
	# Note: Reputation changes will be verified when reputation system is implemented

## Test experience reward
func test_experience_reward() -> void:
	var quest = Quest.new()
	quest.id = "exp_test"
	quest.title = "Experience Test"
	
	var rewards = Quest.QuestRewards.new()
	rewards.experience = 250
	quest.rewards = rewards
	
	player.experience = 100
	quest_system.add_quest(quest)
	quest_system.complete_quest(quest.id)
	
	assert_that(player.experience).is_equal(350, "Experience should be added correctly")

## Test karma reward
func test_karma_reward() -> void:
	var quest = Quest.new()
	quest.id = "karma_test"
	quest.title = "Karma Test"
	
	var rewards = Quest.QuestRewards.new()
	rewards.karma = 25
	quest.rewards = rewards
	
	player.karma = 50
	quest_system.add_quest(quest)
	quest_system.complete_quest(quest.id)
	
	assert_that(player.karma).is_equal(75, "Karma should be added correctly")

## Test negative karma reward
func test_negative_karma_reward() -> void:
	var quest = Quest.new()
	quest.id = "negative_karma_test"
	quest.title = "Negative Karma Test"
	
	var rewards = Quest.QuestRewards.new()
	rewards.karma = -15
	quest.rewards = rewards
	
	player.karma = 100
	quest_system.add_quest(quest)
	quest_system.complete_quest(quest.id)
	
	assert_that(player.karma).is_equal(85, "Negative karma should be subtracted correctly")

## Test zero rewards
func test_zero_rewards() -> void:
	var quest = Quest.new()
	quest.id = "zero_reward_test"
	quest.title = "Zero Reward Test"
	
	var rewards = Quest.QuestRewards.new()
	rewards.experience = 0
	rewards.karma = 0
	quest.rewards = rewards
	
	player.experience = 100
	player.karma = 50
	quest_system.add_quest(quest)
	quest_system.complete_quest(quest.id)
	
	assert_that(player.experience).is_equal(100, "Experience should not change with zero reward")
	assert_that(player.karma).is_equal(50, "Karma should not change with zero reward")

## Test multiple quest completions accumulate rewards
func test_accumulated_rewards() -> void:
	player.experience = 0
	player.karma = 0
	
	# Complete first quest
	var quest1 = Quest.new()
	quest1.id = "accum_test_1"
	quest1.title = "Accum Test 1"
	var rewards1 = Quest.QuestRewards.new()
	rewards1.experience = 50
	rewards1.karma = 5
	quest1.rewards = rewards1
	quest_system.add_quest(quest1)
	quest_system.complete_quest(quest1.id)
	
	# Complete second quest
	var quest2 = Quest.new()
	quest2.id = "accum_test_2"
	quest2.title = "Accum Test 2"
	var rewards2 = Quest.QuestRewards.new()
	rewards2.experience = 75
	rewards2.karma = 10
	quest2.rewards = rewards2
	quest_system.add_quest(quest2)
	quest_system.complete_quest(quest2.id)
	
	# Verify accumulated rewards
	assert_that(player.experience).is_equal(125, "Experience should accumulate: 50 + 75 = 125")
	assert_that(player.karma).is_equal(15, "Karma should accumulate: 5 + 10 = 15")

## Test failure rewards
func test_failure_rewards() -> void:
	var quest = Quest.new()
	quest.id = "failure_reward_test"
	quest.title = "Failure Reward Test"
	
	var success_rewards = Quest.QuestRewards.new()
	success_rewards.experience = 100
	success_rewards.karma = 10
	quest.rewards = success_rewards
	
	var failure_rewards = Quest.QuestRewards.new()
	failure_rewards.experience = 25
	failure_rewards.karma = -5
	quest.failure_rewards = failure_rewards
	
	player.experience = 0
	player.karma = 0
	
	quest_system.add_quest(quest)
	quest_system.fail_quest(quest.id)
	
	# Should receive failure rewards, not success rewards
	assert_that(player.experience).is_equal(25, "Should receive failure experience reward")
	assert_that(player.karma).is_equal(-5, "Should receive failure karma reward")

## Test that rewards are only given once
func test_rewards_given_once() -> void:
	var quest = Quest.new()
	quest.id = "once_test"
	quest.title = "Once Test"
	
	var rewards = Quest.QuestRewards.new()
	rewards.experience = 100
	quest.rewards = rewards
	
	player.experience = 0
	quest_system.add_quest(quest)
	
	# Complete quest
	quest_system.complete_quest(quest.id)
	assert_that(player.experience).is_equal(100, "Should receive 100 XP on completion")
	
	# Try to complete again (should not work, but if it did, shouldn't give rewards again)
	var old_exp = player.experience
	quest_system.complete_quest(quest.id)
	assert_that(player.experience).is_equal(old_exp, "Should not receive rewards again")

## Test quest with no rewards
func test_quest_no_rewards() -> void:
	var quest = Quest.new()
	quest.id = "no_reward_test"
	quest.title = "No Reward Test"
	
	# No rewards set (default QuestRewards with all zeros)
	player.experience = 100
	player.karma = 50
	
	quest_system.add_quest(quest)
	quest_system.complete_quest(quest.id)
	
	# Should not change
	assert_that(player.experience).is_equal(100, "Experience should not change")
	assert_that(player.karma).is_equal(50, "Karma should not change")

## Test large reward values
func test_large_rewards() -> void:
	var quest = Quest.new()
	quest.id = "large_reward_test"
	quest.title = "Large Reward Test"
	
	var rewards = Quest.QuestRewards.new()
	rewards.experience = 10000
	rewards.karma = 1000
	quest.rewards = rewards
	
	player.experience = 5000
	player.karma = 2000
	
	quest_system.add_quest(quest)
	quest_system.complete_quest(quest.id)
	
	assert_that(player.experience).is_equal(15000, "Large experience rewards should work")
	assert_that(player.karma).is_equal(3000, "Large karma rewards should work")
