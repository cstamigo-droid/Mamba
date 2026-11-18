# -*- coding: utf-8 -*-
"""Nombres en español mexicano (esMX) para el asesor de equipo (18-11-2026). Corre AFUERA del juego.

Solo las fuentes esMX que ya usa Mamba (brief_equipo_esmx.md), todas nombres del propio juego:
  1. Caché WDB del cliente instalado: Mamba/data/i18n/names-observed/esMX.json (tools/asistente/nombres_wdb.py).
  2. ForeverTDB: Mamba/data/local/forever-tdb/world.sqlite (creature_template_locale, quest_template_locale).
  3. Tablas del cliente en esMX vía wago.tools (&locale=esMX, como `forge data names`), en
     D:/rust/polestar-data/sources/wago/<build>/esMX: GroupFinderActivity y AreaTable (build 1.60.1.70959,
     la del cliente que llenó la caché), ItemSparse, ItemSet y SkillLine (1.60.1.70532), e ItemSparse de
     Classic Era 1.15.9.70576 para los objetos que Forever no rehízo.
  4. Caché de hotfixes del cliente (Cache/ADB/esMX/DBCache.bin, build 1.60.1.70959), leída con
     `forge gamedata hotfix --table ItemSparse` (definiciones de WoWDBDefs con la 70959 agregada a la
     estructura de la 70938): los objetos nuevos de Forever (ids 27xxxx), que no vienen en las tablas.
Si un nombre no está en ninguna, queda en inglés con "*" al final (NO VERIFICADO: sin traducción).
"""
import csv
import hashlib
import json
import pathlib
import sqlite3

MAMBA = pathlib.Path(r"C:\Users\<usuario>\Mamba")
WAGO_ES = pathlib.Path(r"D:\rust\polestar-data\sources\wago")
BUILD_MAPAS = "1.60.1.70959"
BUILD_OBJ = "1.60.1.70532"
BUILD_ERA = "1.15.9.70576"
HOTFIX_OBJ = pathlib.Path(r"D:\rust\polestar-data\sources\cliente-hotfix\ItemSparse.esMX.csv")
MARCA = "*"

# Nombre que usa el generador -> nombre que usa el cliente en inglés (mismo lugar, otra grafía).
ALIAS = {
    "The Stockade": "Stormwind Stockades",
    "Krol'Dok Stronghold": "Krol'dok Stronghold",
    "Shaper's Terrace": "The Shaper's Terrace",
    "Ashenvale Forest": "Ashenvale",
    "Zul'Farak": "Zul'Farrak",
}


def _csv(p):
    with open(p, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def _sha(p):
    return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()


class Nombres:
    def __init__(self, mamba=MAMBA, wago=WAGO_ES):
        self.huellas = {}
        self.sin = set()  # (tipo, inglés) que quedaron sin traducción
        self.mapas, self.areas = {}, {}
        en_dir, es_dir = wago / BUILD_MAPAS, wago / BUILD_MAPAS / "esMX"
        en = {r["ID"]: r for r in _csv(en_dir / "GroupFinderActivity.csv")}
        for r in _csv(es_dir / "GroupFinderActivity.csv"):
            e = en.get(r["ID"])
            if e:
                for campo in ("ShortName_lang", "FullName_lang"):
                    if e[campo] and r["ShortName_lang"]:
                        self.mapas.setdefault(e[campo], r["ShortName_lang"])
        en = {r["ID"]: r for r in _csv(en_dir / "AreaTable.csv")}
        filas = sorted(_csv(es_dir / "AreaTable.csv"), key=lambda r: (r["ParentAreaID"] != "0", int(r["ID"])))
        for r in filas:  # zonas de primer nivel primero
            e = en.get(r["ID"])
            if e and e["AreaName_lang"] and r["AreaName_lang"]:
                self.areas.setdefault(e["AreaName_lang"], r["AreaName_lang"])
        obj_dir = wago / BUILD_OBJ / "esMX"
        self.items = {int(r["ID"]): r["Display_lang"] for r in _csv(obj_dir / "ItemSparse.csv") if r["Display_lang"]}
        era = wago / BUILD_ERA / "esMX" / "ItemSparse.csv"  # objetos de Classic que Forever no rehízo
        for r in _csv(era):
            if r["Display_lang"]:
                self.items.setdefault(int(r["ID"]), r["Display_lang"])
        # Hotfixes que el servidor le mandó al cliente (Cache/ADB/esMX/DBCache.bin): trae los objetos nuevos de
        # Forever y gana sobre las tablas (es lo que el juego muestra hoy).
        # forge gamedata hotfix --table ItemSparse --status valid --locale esMX --out HOTFIX_OBJ
        for r in _csv(HOTFIX_OBJ):
            if r["Display_lang"]:
                self.items[int(r["ID"])] = r["Display_lang"]
        self.conjuntos = {int(r["ID"]): r["Name_lang"] for r in _csv(obj_dir / "ItemSet.csv") if r["Name_lang"]}
        en_sk = {r["ID"]: r["DisplayName_lang"] for r in _csv(mamba / "data/sources/wago" / BUILD_OBJ / "SkillLine.csv")}
        self.profesiones = {en_sk[r["ID"]]: r["DisplayName_lang"] for r in _csv(obj_dir / "SkillLine.csv")
                            if en_sk.get(r["ID"]) and r["DisplayName_lang"]}
        self.npcs, self.misiones = {}, {}
        obs = mamba / "data/i18n/names-observed/esMX.json"
        for n in json.loads(obs.read_text(encoding="utf-8"))["names"]:
            tipo, _, i = n["token"].partition(":")
            if i.isdigit() and n.get("name"):
                {"npc": self.npcs, "quest": self.misiones, "item": self.items}.get(tipo, {})[int(i)] = n["name"]
        tdb = mamba / "data/local/forever-tdb/world.sqlite"
        c = sqlite3.connect(f"file:{tdb}?mode=ro", uri=True)
        for i, n in c.execute("select entry, Name from creature_template_locale where locale='esMX'"):
            if n:
                self.npcs.setdefault(int(i), n)
        for i, n in c.execute("select ID, LogTitle from quest_template_locale where locale='esMX'"):
            if n:
                self.misiones.setdefault(int(i), n)
        c.close()
        for p in (en_dir / "GroupFinderActivity.csv", es_dir / "GroupFinderActivity.csv", en_dir / "AreaTable.csv",
                  es_dir / "AreaTable.csv", obj_dir / "ItemSparse.csv", obj_dir / "ItemSet.csv", obj_dir / "SkillLine.csv", era, HOTFIX_OBJ, obs, tdb):
            self.huellas[str(p).replace("\\", "/")] = _sha(p)

    def _falta(self, tipo, ingles):
        if not ingles:
            return ingles
        self.sin.add((tipo, ingles))
        return ingles + MARCA

    def mazmorra(self, ingles):
        k = ALIAS.get(ingles, ingles)
        return self.mapas.get(k) or self.areas.get(k) or self._falta("mazmorra", ingles)

    def zona(self, ingles):
        k = ALIAS.get(ingles, ingles)
        return self.areas.get(k) or self.mapas.get(k) or self._falta("zona", ingles)

    def lugar(self, ingles):
        """Una zona de los datos que puede ser mazmorra o zona del mundo."""
        k = ALIAS.get(ingles, ingles)
        return self.mapas.get(k) or self.areas.get(k) or self._falta("lugar", ingles)

    def npc(self, npc_id, ingles):
        return self.npcs.get(npc_id) or self._falta("jefe", ingles)

    def mision(self, qid, ingles):
        return self.misiones.get(qid) or self._falta("mision", ingles)

    def objeto(self, iid, ingles):
        return self.items.get(iid) or self._falta("objeto", ingles or f"objeto {iid}")

    def conjunto(self, sid, ingles):
        return self.conjuntos.get(sid) or self._falta("conjunto", ingles)

    def profesion(self, ingles):
        return self.profesiones.get(ingles) or self._falta("profesion", ingles)
