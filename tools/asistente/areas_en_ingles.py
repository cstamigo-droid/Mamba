"""Nombres de área de la grilla en inglés (18-11).

`forge nav grid` sacó data/areas.json de la grilla del cliente instalado, que está en esMX, y `forge nav
pack` copia esos nombres a Polestar_Nav/Nav/Nav<map>.lua (`areaNames`). El addon los compara con
GetSubZoneText en inglés (la cabecera lo dice): en español, la caminata partía del piso equivocado en
Entrañas (pruebas nav_e2e/nav_reported undercity_*). areas.json es { WMOAreaTableID: [nombre, AreaTableID] }:
el nombre pasa al AreaName_lang (enUS, wago.tools) de WMOAreaTable con ese ID; si está vacío, al de
AreaTable del AreaTableID. Siempre parte de la copia esMX original (areas.esMX.json). Correr antes de
`forge nav pack`.

Uso: python -I tools/asistente/areas_en_ingles.py <grilla>   (p. ej. D:\\rust\\forge-out\\grid)
"""
from __future__ import annotations

import csv
import json
import shutil
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]


def _tabla(nombre: str) -> dict[int, str]:
    f = sorted((RAIZ / "data" / "sources" / "wago").glob(f"1.60.1.*/{nombre}.csv"))[-1]
    with f.open(encoding="utf-8", newline="") as h:
        return {int(r["ID"]): r["AreaName_lang"] for r in csv.DictReader(h)}


def main() -> int:
    grilla = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(r"D:\rust\forge-out\grid")
    f = grilla / "areas.json"
    original = f.with_suffix(".esMX.json")
    if not original.exists():
        shutil.copyfile(f, original)
    wmo, area = _tabla("WMOAreaTable"), _tabla("AreaTable")
    a = json.loads(original.read_text(encoding="utf-8"))
    n = 0
    for k, v in a.items():
        if not (v and v[0]):
            continue
        en = wmo.get(int(k)) or (area.get(int(v[1])) if len(v) > 1 else None)
        if en and en != v[0]:
            v[0] = en
            n += 1
    f.write_text(json.dumps(a, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"áreas: {n} nombres pasados al inglés (WMOAreaTable, si no AreaTable)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
