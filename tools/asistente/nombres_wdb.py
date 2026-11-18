"""Nombres en el idioma del cliente desde la caché del PROPIO cliente (18-11).

Sin DingDB (QuestieDB) y sin pfQuest para esMX, `forge data names` dejaba esMX sin nombres de misiones,
PNJ ni objetos. La caché WDB del cliente instalado de Cristian (lo que el servidor de Forever le mandó en
su idioma) es la fuente que forge pone primero entre las observadas ("client-wdb"): son hechos del juego,
del cliente propio, como la grilla. Este script la vuelca a data/i18n/names-observed/<locale>.json.

Uso: python -I tools/asistente/nombres_wdb.py [<locale>]   (por omisión esMX)
     Requiere forge compilado. ref 1 = Mamba (no hay issue público; ver LICENCIAS_TERCEROS.md).
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
FORGE = Path(r"D:\rust\target\release\forge.exe")
WOW = Path(r"C:\Program Files (x86)\World of Warcraft\_forever_")


def main() -> int:
    loc = sys.argv[1] if len(sys.argv) > 1 else "esMX"
    tmp = Path(r"D:\rust\noche") / f"wdb_{loc}.json"
    r = subprocess.run([str(FORGE), "gamedata", "cache", "--kind", "all", "--locale", loc, "--out", str(tmp)],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    print(r.stdout + r.stderr)
    if r.returncode != 0:
        return r.returncode
    build = next((l.split("build ")[1].split()[0] for l in r.stdout.splitlines() + r.stderr.splitlines()
                  if "creaturecache.wdb: build" in l), None)
    d = json.loads(tmp.read_text(encoding="utf-8"))
    wdb = WOW / "Cache" / "WDB" / loc
    sha = {f: hashlib.sha256((wdb / f).read_bytes()).hexdigest() for f in ("questcache.wdb", "creaturecache.wdb", "gameobjectcache.wdb")}
    full_build = f"1.60.1.{build}" if build else None
    names = []
    for kind, clave, archivo, campo in (("quest", "quest", "questcache.wdb", "LogTitle"),
                                        ("npc", "creature", "creaturecache.wdb", "Name"),
                                        ("object", "gameobject", "gameobjectcache.wdb", "Name")):
        for i, rec in sorted(d.get(clave, {}).items(), key=lambda x: int(x[0])):
            n = rec.get(campo)
            n = (n[0] if isinstance(n, list) else n) or ""
            n = n.strip()
            if not n or int(i) <= 0:
                continue
            names.append({"token": f"{kind}:{int(i)}", "name": n, "source": "client-wdb", "build": full_build,
                          "sha256": sha[archivo], "ref": 1})
    # Lo que la caché no tiene: la base del servidor de Forever (ForeverTDB, *_template_locale), solo
    # para los ids que nombran los datos de Polestar. La caché manda: es lo que el servidor manda hoy.
    tdb = RAIZ / "data" / "local" / "forever-tdb" / "world.sqlite"
    if tdb.is_file():
        import sqlite3
        ya = {x["token"] for x in names}
        datos = RAIZ / "data" / "forever"
        ids = {"quest": set(json.loads((datos / "quests.json").read_text(encoding="utf-8"))),
               "npc": set(json.loads((datos / "npcs.json").read_text(encoding="utf-8"))),
               "object": set(json.loads((datos / "objects.json").read_text(encoding="utf-8")))}
        sha_tdb = hashlib.sha256(tdb.read_bytes()).hexdigest()
        c = sqlite3.connect(f"file:{tdb}?mode=ro", uri=True)
        antes = len(names)
        for kind, sql in (("quest", "select ID, LogTitle from quest_template_locale where locale=?"),
                          ("npc", "select entry, Name from creature_template_locale where locale=?"),
                          ("object", "select entry, name from gameobject_template_locale where locale=?")):
            for i, n in c.execute(sql, (loc,)):
                n = (n or "").strip()
                tok = f"{kind}:{int(i)}"
                if n and int(i) > 0 and str(int(i)) in ids[kind] and tok not in ya:
                    names.append({"token": tok, "name": n, "source": "forever-tdb", "build": None, "sha256": sha_tdb, "ref": 1})
        print(f"ForeverTDB: {len(names) - antes} nombres más")
    out = RAIZ / "data" / "i18n" / "names-observed" / f"{loc}.json"
    doc = {
        "about": [
            "Mamba: names the Forever client installed on this PC cached in this language (Cache/WDB/" + loc + "), read by "
            "`forge gamedata cache` and written by tools/asistente/nombres_wdb.py. The game's own names, never translations "
            "from websites or other addons. ref 1: Mamba, no public issue.",
        ],
        "schema": 1,
        "locale": loc,
        "names": names,
    }
    out.write_text(json.dumps(doc, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
    print(f"{out}: {len(names)} nombres ({sum(1 for x in names if x['token'].startswith('quest'))} misiones, "
          f"{sum(1 for x in names if x['token'].startswith('npc'))} PNJ, {sum(1 for x in names if x['token'].startswith('object'))} objetos)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
