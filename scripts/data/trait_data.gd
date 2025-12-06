extends Resource
class_name TraitData
## Sistema de Traits (características) inspirado no Fallout
## Traits são escolhidos na criação do personagem e têm vantagens/desvantagens

enum Trait {
	FAST_METABOLISM,    # +2 Healing Rate, mas radiação e veneno duram mais
	BRUISER,            # +2 Strength, -2 Action Points
	SMALL_FRAME,        # +1 Agility, mas carry weight reduzido
	ONE_HANDER,         # +20% acerto com armas de uma mão, -40% com duas mãos
	FINESSE,            # +10% Critical Chance, -30% dano geral
	KAMIKAZE,           # +5 Sequence, mas Armor Class = 0
	HEAVY_HANDED,       # +4 dano corpo-a-corpo, mas -30% Critical Chance
	FAST_SHOT,          # Não pode fazer targeted shots, mas -1 AP em ataques
	BLOODY_MESS,        # +5% dano, animações de morte mais violentas
	JINXED,             # Todos (incluindo você) têm mais critical failures
	GOOD_NATURED,       # +15% em skills não-combate, -10% em skills de combate
	CHEM_RELIANT,       # Drogas duram 2x mais, mas vício é 2x mais rápido
	CHEM_RESISTANT,     # 50% resistência a vício, mas drogas duram metade
	SEX_APPEAL,         # Reações melhores com sexo oposto, piores com mesmo sexo
	SKILLED,            # +5 pontos de skill por nível, mas perk a cada 4 níveis
	GIFTED              # +1 em todos SPECIAL, mas -10% em todas skills e -5 skill points/nível
}

const MAX_TRAITS := 2
const TRAIT_COUNT := 16

var selected_traits: Array[Trait] = []

func select_trait(t: Trait) -> bool:
	if selected_traits.size() >= MAX_TRAITS:
		return false
	
	if t in selected_traits:
		return false
	
	selected_traits.append(t)
	return true

func has_trait(t: Trait) -> bool:
	return t in selected_traits

func remove_trait(t: Trait) -> bool:
	var index: int = selected_traits.find(t)
	if index != -1:
		selected_traits.remove_at(index)
		return true
	return false

func get_trait_name(t: Trait) -> String:
	return Trait.keys()[t].replace("_", " ").capitalize()

func get_trait_description(t: Trait) -> String:
	match t:
		Trait.FAST_METABOLISM:
			return "Seu metabolismo é duas vezes mais rápido. Você cura mais rápido, mas radiação e veneno duram mais tempo."
		Trait.BRUISER:
			return "Você é um lutador nato. +2 Strength, mas -2 Action Points."
		Trait.SMALL_FRAME:
			return "Você é menor e mais ágil. +1 Agility, mas carry weight reduzido em 10%."
		Trait.ONE_HANDER:
			return "Especialista em armas de uma mão. +20% acerto com uma mão, -40% com duas mãos."
		Trait.FINESSE:
			return "Seus ataques são precisos. +10% Critical Chance, mas -30% dano base."
		Trait.KAMIKAZE:
			return "Você ataca primeiro, sem se defender. +5 Sequence, mas Armor Class = 0."
		Trait.HEAVY_HANDED:
			return "Você bate forte, mas sem finesse. +4 dano corpo-a-corpo, -30% Critical Chance."
		Trait.FAST_SHOT:
			return "Você atira rápido. -1 AP em ataques, mas não pode fazer targeted shots."
		Trait.BLOODY_MESS:
			return "Você deixa um rastro de destruição. +5% dano em todos ataques."
		Trait.JINXED:
			return "Você tem azar... e todos ao seu redor também. Mais critical failures para todos."
		Trait.GOOD_NATURED:
			return "Você prefere conversar. +15% em skills sociais, -10% em skills de combate."
		Trait.CHEM_RELIANT:
			return "Drogas funcionam melhor em você. Efeitos duram 2x, mas vício é 2x mais rápido."
		Trait.CHEM_RESISTANT:
			return "Você é resistente a drogas. 50% resistência a vício, mas efeitos duram metade."
		Trait.SEX_APPEAL:
			return "Você é atraente. Reações melhores com sexo oposto, piores com mesmo sexo."
		Trait.SKILLED:
			return "Você aprende rápido. +5 skill points por nível, mas perk a cada 4 níveis."
		Trait.GIFTED:
			return "Você nasceu talentoso. +1 em todos SPECIAL, mas -10% em skills e -5 skill points/nível."
		_:
			return ""

func apply_trait_effects(stats: StatData, skills: SkillData) -> void:
	for t in selected_traits:
		_apply_single_trait(t, stats, skills)

func _apply_single_trait(t: Trait, stats: StatData, skills: SkillData) -> void:
	match t:
		Trait.FAST_METABOLISM:
			stats.healing_rate += 2
		
		Trait.BRUISER:
			stats.strength = clamp(stats.strength + 2, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			stats.max_ap -= 2
			stats.current_ap = stats.max_ap
		
		Trait.SMALL_FRAME:
			stats.agility = clamp(stats.agility + 1, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			stats.carry_weight = int(stats.carry_weight * 0.9)
		
		Trait.FINESSE:
			stats.critical_chance += 10.0
		
		Trait.KAMIKAZE:
			stats.sequence += 5
			stats.armor_class = 0
		
		Trait.HEAVY_HANDED:
			stats.melee_damage += 4
			stats.critical_chance -= 30.0
		
		Trait.GOOD_NATURED:
			# Aplica modificadores em skills
			for sk in [SkillData.Skill.FIRST_AID, SkillData.Skill.DOCTOR, 
						  SkillData.Skill.SPEECH, SkillData.Skill.BARTER, 
						  SkillData.Skill.SCIENCE, SkillData.Skill.REPAIR]:
				var current_val: int = skills.get_skill_value(sk)
				skills.skill_values[sk] = int(current_val * 1.15)
			
			for sk in [SkillData.Skill.SMALL_GUNS, SkillData.Skill.BIG_GUNS,
						  SkillData.Skill.ENERGY_WEAPONS, SkillData.Skill.UNARMED,
						  SkillData.Skill.MELEE_WEAPONS, SkillData.Skill.THROWING]:
				var current_val: int = skills.get_skill_value(sk)
				skills.skill_values[sk] = int(current_val * 0.9)
		
		Trait.GIFTED:
			# +1 em todos SPECIAL
			stats.strength = clamp(stats.strength + 1, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			stats.perception = clamp(stats.perception + 1, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			stats.endurance = clamp(stats.endurance + 1, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			stats.charisma = clamp(stats.charisma + 1, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			stats.intelligence = clamp(stats.intelligence + 1, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			stats.agility = clamp(stats.agility + 1, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			stats.luck = clamp(stats.luck + 1, GameConstants.PRIMARY_STAT_MIN, GameConstants.PRIMARY_STAT_MAX)
			
			# -10% em todas skills
			for sk in skills.skill_values:
				var val: int = skills.skill_values[sk]
				skills.skill_values[sk] = int(val * 0.9)

func get_damage_modifier(t: Trait) -> float:
	match t:
		Trait.BLOODY_MESS:
			return 1.05
		Trait.FINESSE:
			return 0.7
		_:
			return 1.0

func get_total_damage_modifier() -> float:
	var modifier: float = 1.0
	for t in selected_traits:
		modifier *= get_damage_modifier(t)
	return modifier

func can_do_targeted_shots() -> bool:
	return not has_trait(Trait.FAST_SHOT)

func get_ap_cost_modifier() -> int:
	if has_trait(Trait.FAST_SHOT):
		return -1
	return 0
