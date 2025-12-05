#!/usr/bin/env python3
import json

with open('godot_project/assets/data/maps/artemple.json') as f:
    data = json.load(f)

print("Análise de FRM IDs do ARTEMPLE\n")

# Agrupar por tipo
by_type = {}
for obj in data['objects']:
    obj_type = obj['object_type']
    if obj_type not in by_type:
        by_type[obj_type] = []
    by_type[obj_type].append(obj)

for obj_type, objs in by_type.items():
    print(f"\n{obj_type.upper()} ({len(objs)} objetos):")
    for obj in objs[:3]:
        pid = obj['pid']
        frm_id = obj['frm_id']
        print(f"  PID: 0x{pid:08X}, FRM ID: 0x{frm_id:08X} ({frm_id})")
