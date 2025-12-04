"""
PRO Parser - Parser completo de arquivos PRO do Fallout 2.

Baseado na estrutura de src/proto.cc e src/proto_types.h.
"""
import struct
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field


# Tamanhos dos protótipos (em bytes)
PROTO_SIZES = {
    0: 0x84,   # ItemProto
    1: 0x1A0,  # CritterProto
    2: 0x38,   # SceneryProto
    3: 0x24,   # WallProto
    4: 0x1C,   # TileProto
    5: 0x1C,   # MiscProto
}

# Tipos de objetos
OBJ_TYPE_ITEM = 0
OBJ_TYPE_CRITTER = 1
OBJ_TYPE_SCENERY = 2
OBJ_TYPE_WALL = 3
OBJ_TYPE_TILE = 4
OBJ_TYPE_MISC = 5

# Tipos de itens
ITEM_TYPE_ARMOR = 0
ITEM_TYPE_CONTAINER = 1
ITEM_TYPE_DRUG = 2
ITEM_TYPE_WEAPON = 3
ITEM_TYPE_AMMO = 4
ITEM_TYPE_MISC = 5
ITEM_TYPE_KEY = 6

ITEM_TYPE_NAMES = {
    ITEM_TYPE_ARMOR: 'armor',
    ITEM_TYPE_CONTAINER: 'container',
    ITEM_TYPE_DRUG: 'drug',
    ITEM_TYPE_WEAPON: 'weapon',
    ITEM_TYPE_AMMO: 'ammo',
    ITEM_TYPE_MISC: 'misc',
    ITEM_TYPE_KEY: 'key',
}

# Tipos de dano
DAMAGE_TYPE_NORMAL = 0
DAMAGE_TYPE_LASER = 1
DAMAGE_TYPE_FIRE = 2
DAMAGE_TYPE_PLASMA = 3
DAMAGE_TYPE_ELECTRICAL = 4
DAMAGE_TYPE_EMP = 5
DAMAGE_TYPE_EXPLOSION = 6

# Stats (índices)
STAT_STRENGTH = 0
STAT_PERCEPTION = 1
STAT_ENDURANCE = 2
STAT_CHARISMA = 3
STAT_INTELLIGENCE = 4
STAT_AGILITY = 5
STAT_LUCK = 6

STAT_NAMES = {
    STAT_STRENGTH: 'strength',
    STAT_PERCEPTION: 'perception',
    STAT_ENDURANCE: 'endurance',
    STAT_CHARISMA: 'charisma',
    STAT_INTELLIGENCE: 'intelligence',
    STAT_AGILITY: 'agility',
    STAT_LUCK: 'luck',
}

# Skills (índices)
SKILL_SMALL_GUNS = 0
SKILL_BIG_GUNS = 1
SKILL_ENERGY_WEAPONS = 2
SKILL_UNARMED = 3
SKILL_MELEE_WEAPONS = 4
SKILL_THROWING = 5
SKILL_FIRST_AID = 6
SKILL_DOCTOR = 7
SKILL_SNEAK = 8
SKILL_LOCKPICK = 9
SKILL_STEAL = 10
SKILL_TRAPS = 11
SKILL_SCIENCE = 12
SKILL_REPAIR = 13
SKILL_SPEECH = 14
SKILL_BARTER = 15
SKILL_GAMBLING = 16
SKILL_OUTDOORSMAN = 17

SKILL_NAMES = {
    SKILL_SMALL_GUNS: 'small_guns',
    SKILL_BIG_GUNS: 'big_guns',
    SKILL_ENERGY_WEAPONS: 'energy_weapons',
    SKILL_UNARMED: 'unarmed',
    SKILL_MELEE_WEAPONS: 'melee_weapons',
    SKILL_THROWING: 'throwing',
    SKILL_FIRST_AID: 'first_aid',
    SKILL_DOCTOR: 'doctor',
    SKILL_SNEAK: 'sneak',
    SKILL_LOCKPICK: 'lockpick',
    SKILL_STEAL: 'steal',
    SKILL_TRAPS: 'traps',
    SKILL_SCIENCE: 'science',
    SKILL_REPAIR: 'repair',
    SKILL_SPEECH: 'speech',
    SKILL_BARTER: 'barter',
    SKILL_GAMBLING: 'gambling',
    SKILL_OUTDOORSMAN: 'outdoorsman',
}


def PID_TYPE(pid: int) -> int:
    """Extrai o tipo de objeto do PID."""
    return (pid >> 24) & 0xF


def read_int32(data: bytes, offset: int) -> tuple[int, int]:
    """Lê um int32 little-endian."""
    if offset + 4 > len(data):
        raise ValueError("Dados insuficientes")
    value = struct.unpack('<i', data[offset:offset+4])[0]
    return value, offset + 4


def read_uint32(data: bytes, offset: int) -> tuple[int, int]:
    """Lê um uint32 little-endian."""
    if offset + 4 > len(data):
        raise ValueError("Dados insuficientes")
    value = struct.unpack('<I', data[offset:offset+4])[0]
    return value, offset + 4


def read_int16(data: bytes, offset: int) -> tuple[int, int]:
    """Lê um int16 little-endian."""
    if offset + 2 > len(data):
        raise ValueError("Dados insuficientes")
    value = struct.unpack('<h', data[offset:offset+2])[0]
    return value, offset + 2


def read_uint8(data: bytes, offset: int) -> tuple[int, int]:
    """Lê um uint8."""
    if offset + 1 > len(data):
        raise ValueError("Dados insuficientes")
    value = struct.unpack('<B', data[offset:offset+1])[0]
    return value, offset + 1


def read_item_proto_data(data: bytes, offset: int, item_type: int) -> tuple[Dict[str, Any], int]:
    """
    Lê dados específicos de um item baseado no tipo.
    
    Baseado em protoItemDataRead() de src/proto.cc
    """
    result = {}
    
    if item_type == ITEM_TYPE_ARMOR:
        # ProtoItemArmorData
        armor_class, offset = read_int32(data, offset)
        result['armor_class'] = armor_class
        
        # damageResistance[7]
        dr = []
        for i in range(7):
            val, offset = read_int32(data, offset)
            dr.append(val)
        result['damage_resistance'] = dr
        
        # damageThreshold[7]
        dt = []
        for i in range(7):
            val, offset = read_int32(data, offset)
            dt.append(val)
        result['damage_threshold'] = dt
        
        perk, offset = read_int32(data, offset)
        result['perk'] = perk
        
        male_fid, offset = read_int32(data, offset)
        result['male_fid'] = male_fid
        
        female_fid, offset = read_int32(data, offset)
        result['female_fid'] = female_fid
        
    elif item_type == ITEM_TYPE_CONTAINER:
        # ProtoItemContainerData
        max_size, offset = read_int32(data, offset)
        result['max_size'] = max_size
        
        open_flags, offset = read_int32(data, offset)
        result['open_flags'] = open_flags
        
    elif item_type == ITEM_TYPE_DRUG:
        # ProtoItemDrugData
        # stat[3]
        stats = []
        for i in range(3):
            val, offset = read_int32(data, offset)
            stats.append(val)
        result['stat'] = stats
        
        # amount[3]
        amounts = []
        for i in range(3):
            val, offset = read_int32(data, offset)
            amounts.append(val)
        result['amount'] = amounts
        
        duration1, offset = read_int32(data, offset)
        result['duration1'] = duration1
        
        # amount1[3]
        amounts1 = []
        for i in range(3):
            val, offset = read_int32(data, offset)
            amounts1.append(val)
        result['amount1'] = amounts1
        
        duration2, offset = read_int32(data, offset)
        result['duration2'] = duration2
        
        # amount2[3]
        amounts2 = []
        for i in range(3):
            val, offset = read_int32(data, offset)
            amounts2.append(val)
        result['amount2'] = amounts2
        
        addiction_chance, offset = read_int32(data, offset)
        result['addiction_chance'] = addiction_chance
        
        withdrawal_effect, offset = read_int32(data, offset)
        result['withdrawal_effect'] = withdrawal_effect
        
        withdrawal_onset, offset = read_int32(data, offset)
        result['withdrawal_onset'] = withdrawal_onset
        
    elif item_type == ITEM_TYPE_WEAPON:
        # ProtoItemWeaponData
        animation_code, offset = read_int32(data, offset)
        result['animation_code'] = animation_code
        
        min_damage, offset = read_int32(data, offset)
        result['min_damage'] = min_damage
        
        max_damage, offset = read_int32(data, offset)
        result['max_damage'] = max_damage
        
        damage_type, offset = read_int32(data, offset)
        result['damage_type'] = damage_type
        
        max_range1, offset = read_int32(data, offset)
        result['max_range1'] = max_range1
        
        max_range2, offset = read_int32(data, offset)
        result['max_range2'] = max_range2
        
        projectile_pid, offset = read_int32(data, offset)
        result['projectile_pid'] = projectile_pid
        
        min_strength, offset = read_int32(data, offset)
        result['min_strength'] = min_strength
        
        ap_cost1, offset = read_int32(data, offset)
        result['action_point_cost1'] = ap_cost1
        
        ap_cost2, offset = read_int32(data, offset)
        result['action_point_cost2'] = ap_cost2
        
        crit_fail_table, offset = read_int32(data, offset)
        result['critical_failure_type'] = crit_fail_table
        
        perk, offset = read_int32(data, offset)
        result['perk'] = perk
        
        rounds, offset = read_int32(data, offset)
        result['rounds'] = rounds
        
        caliber, offset = read_int32(data, offset)
        result['caliber'] = caliber
        
        ammo_type_pid, offset = read_int32(data, offset)
        result['ammo_type_pid'] = ammo_type_pid
        
        ammo_capacity, offset = read_int32(data, offset)
        result['ammo_capacity'] = ammo_capacity
        
        sound_code, offset = read_uint8(data, offset)
        result['sound_code'] = sound_code
        
    elif item_type == ITEM_TYPE_AMMO:
        # ProtoItemAmmoData
        caliber, offset = read_int32(data, offset)
        result['caliber'] = caliber
        
        quantity, offset = read_int32(data, offset)
        result['quantity'] = quantity
        
        ac_modifier, offset = read_int32(data, offset)
        result['armor_class_modifier'] = ac_modifier
        
        dr_modifier, offset = read_int32(data, offset)
        result['damage_resistance_modifier'] = dr_modifier
        
        dam_mult, offset = read_int32(data, offset)
        result['damage_multiplier'] = dam_mult
        
        dam_div, offset = read_int32(data, offset)
        result['damage_divisor'] = dam_div
        
    elif item_type == ITEM_TYPE_MISC:
        # ProtoItemMiscData
        power_type_pid, offset = read_int32(data, offset)
        result['power_type_pid'] = power_type_pid
        
        power_type, offset = read_int32(data, offset)
        result['power_type'] = power_type
        
        charges, offset = read_int32(data, offset)
        result['charges'] = charges
        
    elif item_type == ITEM_TYPE_KEY:
        # ProtoItemKeyData
        key_code, offset = read_int32(data, offset)
        result['key_code'] = key_code
        
    return result, offset


def read_critter_proto_data(data: bytes, offset: int) -> tuple[Dict[str, Any], int]:
    """
    Lê dados de um critter.
    
    Baseado em protoCritterDataRead() de src/proto.cc
    """
    result = {}
    
    # flags
    flags, offset = read_int32(data, offset)
    result['flags'] = flags
    
    # baseStats[35] - stats base
    base_stats = {}
    for i in range(35):
        val, offset = read_int32(data, offset)
        if i < 7:  # SPECIAL stats
            stat_name = STAT_NAMES.get(i, f'stat_{i}')
            base_stats[stat_name] = val
        elif i < 25:  # Skills (7-24)
            skill_idx = i - 7
            if skill_idx < len(SKILL_NAMES):
                skill_name = SKILL_NAMES[skill_idx]
                base_stats[skill_name] = val
    result['base_stats'] = base_stats
    
    # bonusStats[35] - bonus stats
    bonus_stats = {}
    for i in range(35):
        val, offset = read_int32(data, offset)
        if i < 7:  # SPECIAL stats
            stat_name = STAT_NAMES.get(i, f'stat_{i}')
            bonus_stats[stat_name] = val
        elif i < 25:  # Skills
            skill_idx = i - 7
            if skill_idx < len(SKILL_NAMES):
                skill_name = SKILL_NAMES[skill_idx]
                bonus_stats[skill_name] = val
    result['bonus_stats'] = bonus_stats
    
    # skills[18] - skill points
    skills = {}
    for i in range(18):
        val, offset = read_int32(data, offset)
        if i < len(SKILL_NAMES):
            skill_name = SKILL_NAMES[i]
            skills[skill_name] = val
    result['skills'] = skills
    
    # bodyType
    body_type, offset = read_int32(data, offset)
    result['body_type'] = body_type
    
    # experience
    experience, offset = read_int32(data, offset)
    result['experience'] = experience
    
    # killType
    kill_type, offset = read_int32(data, offset)
    result['kill_type'] = kill_type
    
    # damageType
    damage_type, offset = read_int32(data, offset)
    result['damage_type'] = damage_type
    
    return result, offset


def parse_proto(proto_data: bytes) -> Optional[Dict[str, Any]]:
    """
    Parseia um arquivo PRO completo.
    
    Baseado em protoRead() de src/proto.cc
    """
    if len(proto_data) < 12:
        return None
    
    try:
        offset = 0
        
        # Ler header comum
        pid, offset = read_int32(proto_data, offset)
        message_id, offset = read_int32(proto_data, offset)
        fid, offset = read_int32(proto_data, offset)
        
        obj_type = PID_TYPE(pid)
        
        result = {
            'pid': pid,
            'message_id': message_id,
            'fid': fid,
            'type': ['item', 'critter', 'scenery', 'wall', 'tile', 'misc'][obj_type] if obj_type < 6 else 'unknown'
        }
        
        if obj_type == OBJ_TYPE_ITEM:
            # ItemProto
            light_distance, offset = read_int32(proto_data, offset)
            result['light_distance'] = light_distance
            
            light_intensity, offset = read_int16(proto_data, offset)
            result['light_intensity'] = light_intensity
            
            flags, offset = read_int32(proto_data, offset)
            result['flags'] = flags
            
            extended_flags, offset = read_int32(proto_data, offset)
            result['extended_flags'] = extended_flags
            
            sid, offset = read_int32(proto_data, offset)
            result['sid'] = sid
            
            item_type, offset = read_int32(proto_data, offset)
            result['item_type'] = ITEM_TYPE_NAMES.get(item_type, f'unknown_{item_type}')
            
            material, offset = read_int32(proto_data, offset)
            result['material'] = material
            
            size, offset = read_int32(proto_data, offset)
            result['size'] = size
            
            weight, offset = read_int16(proto_data, offset)
            result['weight'] = weight
            
            cost, offset = read_int32(proto_data, offset)
            result['cost'] = cost
            
            inventory_fid, offset = read_int32(proto_data, offset)
            result['inventory_fid'] = inventory_fid
            
            field_80, offset = read_uint8(proto_data, offset)
            result['field_80'] = field_80
            
            # Ler dados específicos do tipo de item
            item_data, offset = read_item_proto_data(proto_data, offset, item_type)
            result['item_data'] = item_data
            
        elif obj_type == OBJ_TYPE_CRITTER:
            # CritterProto
            light_distance, offset = read_int32(proto_data, offset)
            result['light_distance'] = light_distance
            
            light_intensity, offset = read_int16(proto_data, offset)
            result['light_intensity'] = light_intensity
            
            flags, offset = read_int32(proto_data, offset)
            result['flags'] = flags
            
            extended_flags, offset = read_int32(proto_data, offset)
            result['extended_flags'] = extended_flags
            
            sid, offset = read_int32(proto_data, offset)
            result['sid'] = sid
            
            head_fid, offset = read_int32(proto_data, offset)
            result['head_fid'] = head_fid
            
            ai_packet, offset = read_int32(proto_data, offset)
            result['ai_packet'] = ai_packet
            
            team, offset = read_int32(proto_data, offset)
            result['team'] = team
            
            # Ler dados do critter
            critter_data, offset = read_critter_proto_data(proto_data, offset)
            result['critter_data'] = critter_data
            
        # TODO: Implementar parsing para outros tipos (scenery, wall, tile, misc)
        # Por enquanto, retornar estrutura básica
        
        return result
        
    except (ValueError, struct.error, IndexError) as e:
        return None

