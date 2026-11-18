"""Agrega a los LICENSE-DATA.txt del addon lo que Cristian autorizó el 18-11-2026 ("Aceptar todo").

forge escribe esos avisos en cada construcción; este paso (al final de compilar_addon.sh) agrega una
sección "Mamba" con el crédito de QuestieDB como consulta de hechos (guías escritas a mano por Polestar
y 8 filas de correcciones) y de webxp. Idempotente: reemplaza su propia sección si ya está.

Uso: python -I tools/asistente/avisos_mamba.py
"""
from __future__ import annotations

import sys
from pathlib import Path

ADDON = Path(__file__).resolve().parents[2] / "addon"
INICIO = "Mamba: sources authorized by Cristian"
TEXTO = f"""{INICIO} (18-11-2026)
--------------------------------------------------
QuestieDB (https://github.com/Questie/QuestieDB), used as a facts reference only, as forever-db's
NOTICE does: 21 guides hand-written by Polestar cite it for titles, levels, objectives or places, and
8 correction rows (forever-db/corrections: quests 79980, 91899, 91900, NPC 270513, object 5359;
data/codex/journal-quests.json: 3 rows) rest on it. Mamba's data build reads no QuestieDB
(--no-questie). Accepted by Cristian on 18-11-2026; to be replaced by ForeverTDB facts.
Quest XP from two Forever web quest databases: facts (numbers) only, accepted by Cristian on
18-11-2026, provisional.
"""
CARPETAS = ["Polestar_Guides", "Polestar_Guides_Horde", "Polestar_Guides_Alliance", "Polestar_QuestDB", "Polestar_Codex"]


def main() -> int:
    n = 0
    for c in CARPETAS:
        f = ADDON / c / "LICENSE-DATA.txt"
        if not f.is_file():
            continue
        t = f.read_text(encoding="utf-8")
        if INICIO in t:
            t = t[: t.index(INICIO)].rstrip("\n") + "\n"
        f.write_text(t.rstrip("\n") + "\n\n" + TEXTO, encoding="utf-8", newline="\n")
        n += 1
    print(f"avisos Mamba: {n} LICENSE-DATA.txt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
