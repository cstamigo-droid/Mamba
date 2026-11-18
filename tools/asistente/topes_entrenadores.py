"""Topes de nivel de los entrenadores de clase desde ForeverTDB (18-11).

`forge data trainers` conserva el `top` (el nivel más alto que enseña un entrenador) que ya trae
data/forever/trainers.json; sin QuestieDB, la construcción de Mamba lo dejaba en 9 entrenadores y el
motor podía mandar a un nivel 37 a un entrenador inicial que enseña hasta el 6 (revisión wow-clases).
Aquí: top = el ReqLevel más alto de trainer_spell para cada creature_trainer de ForeverTDB (autorizada
17-11, hechos). Correr ANTES de `forge data trainers`.

Uso: python -I tools/asistente/topes_entrenadores.py
"""
from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]


def main() -> int:
    tdb = RAIZ / "data" / "local" / "forever-tdb" / "world.sqlite"
    tj = RAIZ / "data" / "forever" / "trainers.json"
    c = sqlite3.connect(f"file:{tdb}?mode=ro", uri=True)
    top: dict[int, int] = {}
    for cid, tid in c.execute("select CreatureID, TrainerID from creature_trainer"):
        m = c.execute("select max(ReqLevel) from trainer_spell where TrainerId=?", (tid,)).fetchone()[0]
        if m:
            top[cid] = max(top.get(cid, 0), int(m))
    t = json.loads(tj.read_text(encoding="utf-8"))
    n = 0
    for k, v in t.items():
        tp = top.get(int(k))
        if tp and v.get("top") != tp:
            v["top"] = tp
            n += 1
    tj.write_text(json.dumps(t, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
    print(f"topes: {n} entrenadores actualizados desde ForeverTDB ({sum(1 for v in t.values() if 0 < v.get('top', 0) < 60)} con tope < 60)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
