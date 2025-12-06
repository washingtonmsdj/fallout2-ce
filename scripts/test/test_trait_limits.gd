extends GdUnitTestSuite
## Property test for trait limit enforcement
## **Feature: fallout2-complete-migration, Property 21: Trait Limit Enforcement**
## **Validates: Requirements 8.3**

class_name TestTraitLimits
extends GdUnitTestSuite

var character_editor: CharacterEditor

func before_test() -> void:
	character_editor = CharacterEditor.new()
	add_child(character_editor)
	character_editor._initialize_temp_data()

func after_test() -> void:
	if character_editor:
		character_editor.queue_free()

## Property: For any character, selected_traits.size() SHALL never exceed MAX_TRAITS (2)
func test_trait_limit_property() -> void:
	# Tentar selecionar mais de MAX_TRAITS
	var traits = [
		TraitData.Trait.FAST_METABOLISM,
		TraitData.Trait.BRUISER,
		TraitData.Trait.SMALL_FRAME,
		TraitData.Trait.ONE_HANDER,
		TraitData.Trait.FINESSE
	]
	
	# Selecionar os primeiros MAX_TRAITS
	for i in range(CharacterEditor.MAX_TRAITS):
		var result = character_editor.select_trait(traits[i])
		assert_that(result).is_true("Should be able to select trait %d" % i)
		assert_that(character_editor.selected_traits.size()).is_equal(i + 1, 
			"Should have %d traits selected" % (i + 1))
	
	# Verificar que temos exatamente MAX_TRAITS
	assert_that(character_editor.selected_traits.size()).is_equal(CharacterEditor.MAX_TRAITS, 
		"Should have exactly %d traits" % CharacterEditor.MAX_TRAITS)
	
	# Tentar selecionar mais (deve falhar)
	var result = character_editor.select_trait(traits[CharacterEditor.MAX_TRAITS])
	assert_that(result).is_false("Should not be able to select more than %d traits" % CharacterEditor.MAX_TRAITS)
	assert_that(character_editor.selected_traits.size()).is_equal(CharacterEditor.MAX_TRAITS, 
		"Should still have exactly %d traits" % CharacterEditor.MAX_TRAITS)

## Test that traits can be deselected
func test_trait_deselection() -> void:
	# Selecionar um trait
	character_editor.select_trait(TraitData.Trait.FAST_METABOLISM)
	assert_that(character_editor.selected_traits.size()).is_equal(1, "Should have 1 trait")
	
	# Desselecionar
	character_editor.select_trait(TraitData.Trait.FAST_METABOLISM)
	assert_that(character_editor.selected_traits.size()).is_equal(0, "Should have 0 traits after deselection")
	
	# Agora deve ser possível selecionar outro
	character_editor.select_trait(TraitData.Trait.BRUISER)
	assert_that(character_editor.selected_traits.size()).is_equal(1, "Should be able to select different trait")

## Test that same trait cannot be selected twice
func test_duplicate_trait_prevention() -> void:
	# Selecionar trait
	character_editor.select_trait(TraitData.Trait.FAST_METABOLISM)
	assert_that(character_editor.selected_traits.size()).is_equal(1, "Should have 1 trait")
	
	# Tentar selecionar o mesmo trait novamente (deve desselecionar)
	var result = character_editor.select_trait(TraitData.Trait.FAST_METABOLISM)
	assert_that(result).is_true("Should be able to toggle trait off")
	assert_that(character_editor.selected_traits.size()).is_equal(0, "Should have 0 traits after toggle")

## Test that limit is enforced across multiple selections
func test_limit_enforced_multiple_selections() -> void:
	# Selecionar MAX_TRAITS diferentes
	character_editor.select_trait(TraitData.Trait.FAST_METABOLISM)
	character_editor.select_trait(TraitData.Trait.BRUISER)
	
	assert_that(character_editor.selected_traits.size()).is_equal(2, "Should have 2 traits")
	
	# Tentar selecionar um terceiro (deve falhar)
	var result = character_editor.select_trait(TraitData.Trait.SMALL_FRAME)
	assert_that(result).is_false("Should not be able to select third trait")
	assert_that(character_editor.selected_traits.size()).is_equal(2, "Should still have 2 traits")

## Test that trait limit is enforced in TraitData
func test_trait_data_limit() -> void:
	var trait_data = TraitData.new()
	
	# Selecionar MAX_TRAITS
	var result1 = trait_data.select_trait(TraitData.Trait.FAST_METABOLISM)
	var result2 = trait_data.select_trait(TraitData.Trait.BRUISER)
	
	assert_that(result1).is_true("Should be able to select first trait")
	assert_that(result2).is_true("Should be able to select second trait")
	assert_that(trait_data.selected_traits.size()).is_equal(2, "Should have 2 traits")
	
	# Tentar selecionar terceiro
	var result3 = trait_data.select_trait(TraitData.Trait.SMALL_FRAME)
	assert_that(result3).is_false("Should not be able to select third trait")
	assert_that(trait_data.selected_traits.size()).is_equal(2, "Should still have 2 traits")

## Test random trait selection within limits
func test_random_trait_selection() -> void:
	# Selecionar traits aleatórios até o limite
	var all_traits = TraitData.Trait.values()
	var selected_count = 0
	
	for i in range(100):  # Muitas tentativas
		var random_trait = all_traits[randi() % all_traits.size()]
		var result = character_editor.select_trait(random_trait)
		
		if result:
			selected_count = character_editor.selected_traits.size()
		
		# Nunca deve exceder MAX_TRAITS
		assert_that(character_editor.selected_traits.size()).is_less_equal(CharacterEditor.MAX_TRAITS, 
			"Should never exceed MAX_TRAITS, iteration %d" % i)
		
		if selected_count >= CharacterEditor.MAX_TRAITS:
			break
