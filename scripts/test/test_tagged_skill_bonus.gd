extends GdUnitTestSuite
## Property test for tagged skill bonus
## **Feature: fallout2-complete-migration, Property 22: Tagged Skill Bonus**
## **Validates: Requirements 8.4**

class_name TestTaggedSkillBonus
extends GdUnitTestSuite

var character_editor: CharacterEditor

func before_test() -> void:
	character_editor = CharacterEditor.new()
	add_child(character_editor)
	character_editor._initialize_temp_data()

func after_test() -> void:
	if character_editor:
		character_editor.queue_free()

## Helper para usar todos os pontos
func _use_all_points(editor: CharacterEditor) -> void:
	var stats = [
		GameConstants.PrimaryStat.STRENGTH,
		GameConstants.PrimaryStat.PERCEPTION,
		GameConstants.PrimaryStat.ENDURANCE,
		GameConstants.PrimaryStat.CHARISMA,
		GameConstants.PrimaryStat.INTELLIGENCE,
		GameConstants.PrimaryStat.AGILITY,
		GameConstants.PrimaryStat.LUCK
	]
	
	# Usar todos os pontos disponíveis
	while editor.special_points_remaining > 0:
		var used = false
		for stat in stats:
			if editor._get_stat_value(stat) < 10 and editor.special_points_remaining > 0:
				editor.allocate_stat(stat, 1)
				used = true
				break
		if not used:
			break

## Property: For any tagged skill, the skill value SHALL include a +20 bonus 
## and skill point cost SHALL be halved
func test_tagged_skill_bonus_property() -> void:
	# Taggar uma skill
	var skill = SkillData.Skill.SMALL_GUNS
	var base_value = character_editor.temp_skills.get_skill_value(skill)
	
	character_editor.tag_skill(skill)
	assert_that(skill in character_editor.tagged_skills).is_true("Skill should be tagged")
	
	# Finalizar personagem e verificar bonus
	character_editor.set_name("Test Character")
	_use_all_points(character_editor)
	
	var critter = character_editor.finalize_character()
	assert_that(critter).is_not_null("Should be able to create character")
	
	# Verificar que a skill taggeada tem +20
	var final_value = critter.skills.get_skill_value(skill)
	assert_that(final_value).is_equal(base_value + 20, 
		"Tagged skill should have +20 bonus, expected %d, got %d" % [base_value + 20, final_value])

## Test that multiple tagged skills get bonus
func test_multiple_tagged_skills_bonus() -> void:
	var skills_to_tag = [
		SkillData.Skill.SMALL_GUNS,
		SkillData.Skill.SPEECH,
		SkillData.Skill.LOCKPICK
	]
	
	# Taggar todas
	for skill in skills_to_tag:
		character_editor.tag_skill(skill)
	
	assert_that(character_editor.tagged_skills.size()).is_equal(3, "Should have 3 tagged skills")
	
	# Finalizar
	character_editor.set_name("Test Character")
	_use_all_points(character_editor)
	
	var critter = character_editor.finalize_character()
	
	# Verificar que todas têm +20
	for skill in skills_to_tag:
		var base_value = character_editor.temp_skills.get_skill_value(skill)
		var final_value = critter.skills.get_skill_value(skill)
		assert_that(final_value).is_equal(base_value + 20, 
			"Tagged skill %s should have +20 bonus" % SkillData.new().get_skill_name(skill))

## Test that non-tagged skills don't get bonus
func test_non_tagged_skills_no_bonus() -> void:
	# Taggar apenas uma skill
	character_editor.tag_skill(SkillData.Skill.SMALL_GUNS)
	
	# Finalizar
	character_editor.set_name("Test Character")
	_use_all_points(character_editor)
	
	var critter = character_editor.finalize_character()
	
	# Verificar que outras skills não têm bonus
	var other_skill = SkillData.Skill.BIG_GUNS
	var base_value = character_editor.temp_skills.get_skill_value(other_skill)
	var final_value = critter.skills.get_skill_value(other_skill)
	
	assert_that(final_value).is_equal(base_value, 
		"Non-tagged skill should not have bonus")

## Test tagged skill limit
func test_tagged_skill_limit() -> void:
	# Tentar taggar mais de TAGGED_SKILLS_COUNT
	var all_skills = SkillData.Skill.values()
	
	# Taggar exatamente TAGGED_SKILLS_COUNT
	for i in range(CharacterEditor.TAGGED_SKILLS_COUNT):
		character_editor.tag_skill(all_skills[i])
	
	assert_that(character_editor.tagged_skills.size()).is_equal(CharacterEditor.TAGGED_SKILLS_COUNT, 
		"Should have exactly %d tagged skills" % CharacterEditor.TAGGED_SKILLS_COUNT)
	
	# Tentar taggar mais (deve remover o primeiro e adicionar o novo)
	var first_tagged = character_editor.tagged_skills[0]
	character_editor.tag_skill(all_skills[CharacterEditor.TAGGED_SKILLS_COUNT])
	
	assert_that(character_editor.tagged_skills.size()).is_equal(CharacterEditor.TAGGED_SKILLS_COUNT, 
		"Should still have exactly %d tagged skills" % CharacterEditor.TAGGED_SKILLS_COUNT)
	assert_that(first_tagged in character_editor.tagged_skills).is_false("First tagged skill should be removed")

## Test that skills can be untagged
func test_skill_untagging() -> void:
	var skill = SkillData.Skill.SMALL_GUNS
	
	# Taggar
	character_editor.tag_skill(skill)
	assert_that(skill in character_editor.tagged_skills).is_true("Skill should be tagged")
	
	# Untaggar
	character_editor.tag_skill(skill)
	assert_that(skill in character_editor.tagged_skills).is_false("Skill should be untagged")

## Test that tagged skills are preserved in final character
func test_tagged_skills_preserved() -> void:
	var skills_to_tag = [
		SkillData.Skill.SMALL_GUNS,
		SkillData.Skill.SPEECH,
		SkillData.Skill.LOCKPICK
	]
	
	for skill in skills_to_tag:
		character_editor.tag_skill(skill)
	
	character_editor.set_name("Test Character")
	_use_all_points(character_editor)
	
	var critter = character_editor.finalize_character()
	
	# Verificar que todas as skills taggeadas têm o bonus
	for skill in skills_to_tag:
		var base_value = character_editor.temp_skills.get_skill_value(skill)
		var final_value = critter.skills.get_skill_value(skill)
		assert_that(final_value).is_equal(base_value + 20, 
			"Tagged skill should have +20 bonus in final character")
