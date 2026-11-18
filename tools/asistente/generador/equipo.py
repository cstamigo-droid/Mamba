# -*- coding: utf-8 -*-
"""Generador de datos del asesor de equipo (addon/Asistente_Equipo). Corre AFUERA del juego.

Lee (solo lectura):
  1. Polestar instalado (GPL-3.0-only, https://github.com/fitzforge/polestar, versión en el .toc):
     - Polestar/Gear/SpecData.lua  -> pesos por clase, especialización y tramo de nivel
       (Polestar + simulaciones wowsims, MIT).
     - Polestar/Gear/Weights.lua   -> pesos de respaldo y qué armadura y armas usa cada clase.
     - Polestar_ItemDB/Items.lua   -> estadísticas de objetos (tablas del cliente Classic Era, como hechos).
     - Polestar_ItemDB/Forever.lua -> estadísticas de Forever y DE DÓNDE SALE cada pieza de subida
       (botín de jefe con %, misiones), de ForeverLevelingBiS v0.12.0-beta de Thunder (MIT, datos del 13-10-2026).
  2. Tablas del cliente de Forever (beta 1.60.1.70532, 22-10-2026) bajadas de wago.tools:
     ItemSet.csv, ItemSparse.csv, Item.csv -> conjuntos JcJ (nombres, piezas, quién los usa).
     Huellas en _descargas/wago_1.60.1.70532/SHA256.txt.
  3. Lista de mazmorras y niveles: Warcraft Tavern (https://www.warcrafttavern.com/forever/guides/dungeons/,
     leída el 16-11-2026; dice que coincide con el buscador de grupo del juego). Solo hechos (nombres y números).

NO lee AtlasLoot (GPL-2.0 solo), QuestieDB ni Polestar_Codex (permisos solo para Polestar).

  4. Nombres en español mexicano (esMX): nombres_esmx.py (caché WDB del cliente, ForeverTDB y tablas del
     cliente en esMX). Lo que no tiene nombre esMX queda en inglés con "*" (NO VERIFICADO).

Uso:  python -I equipo.py [carpeta AddOns] [carpeta wago]
Escribe Mamba/addon/Asistente_Equipo/Datos_*.lua y LICENSE-DATA.txt (el addon vive en el repositorio Mamba,
rama asistente, desde el 18-11-2026: así lo arma e instala tools/asistente/armar_instalar.py).
"""
import csv
import hashlib
import pathlib
import re
import sys

from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
RAIZ = AQUI.parent
MAMBA = pathlib.Path(r"C:\Users\<usuario>\Mamba")
ADDONS = MAMBA / "addon"  # el Polestar de Mamba (lo mismo que se instala)
WOW_FOREVER = pathlib.Path(r"C:\Users\<usuario>\OneDrive\Escritorio\WOW_FOREVER")
WAGO = WOW_FOREVER / "generador" / "_descargas" / "wago_1.60.1.70532"  # ItemSet/ItemSparse/Item en inglés
SALIDA = MAMBA / "addon" / "Asistente_Equipo"
BUILD_WAGO = "1.60.1.70532"

sys.path.insert(0, str(AQUI))
from generador import a_lua  # noqa: E402  (mismo serializador que el resto de los datos)
from nombres_esmx import Nombres  # noqa: E402

# ---------------------------------------------------------------- mazmorras
# Niveles: Warcraft Tavern, 16-11-2026 (35 filas; Stratholme en dos entradas). "datos": de qué zona de ForeverLevelingBiS sale el
# botín y, cuando una zona junta varias alas, qué jefes son de esta ala (hechos del juego conocidos).
# lado: "A" / "H" = la entrada está dentro de una capital de esa facción (regla propia: la otra facción no la
#   recibe como consejo; NO VERIFICADO si el buscador de grupo de Forever te lleva igual); None = cualquiera.
# Los "bichos" (trash) de Cumbre de Roca Negra se asignan a la Superior (regla propia: los datos no dicen el ala).
SM_CEMENTERIO = {"Interrogator Vishas", "Bloodmage Thalnos", "Azshir the Sleepless", "Fallen Champion", "Ironspine", "Scorn", "trash"}
SM_BIBLIOTECA = {"Houndmaster Loksey", "Arcanist Doan"}
SM_ARMERIA = {"Herod"}
SM_CATEDRAL = {"High Inquisitor Fairbanks", "Scarlet Commander Mograine", "High Inquisitor Whitemane"}
LBRS = {"Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Mother Smolderweb", "Gizrul the Slavener", "Overlord Wyrmthalak"}
UBRS = {"Pyroguard Emberseer", "Solakar Flamewreath", "Gyth", "Warchief Rend Blackhand", "The Beast", "General Drakkisath", "trash"}
STRAT_VIVOS = {"Timmy the Cruel", "Cannon Master Willey", "Archivist Galford", "Balzaphon", "Hearthsinger Forresten", "The Unforgiven", "trash"}
STRAT_MUERTOS = {"Baron Rivendare", "Baroness Anastari", "Nerub'enkan", "Maleki the Pallid", "Ramstein the Gorger"}

MAZMORRAS = [
    # clave, nombre (inglés, el juego lo muestra en español), min, max, dónde, nueva, zona FLB, jefes (None = todos), lado
    ("rfc", "Ragefire Chasm", 13, 18, "Orgrimmar", False, 2437, None, "H"),
    ("thanes", "Hall of Thanes", 13, 20, "Ironforge", True, 16919, None, "A"),
    ("lordaeron", "Ruins of Lordaeron", 15, 22, "Tirisfal Glades", True, 16611, None, None),
    ("wc", "Wailing Caverns", 15, 24, "The Barrens", False, 718, None, None),
    ("vc", "Deadmines", 17, 26, "Westfall", False, 1581, None, None),
    ("sfk", "Shadowfang Keep", 20, 30, "Silverpine Forest", False, 209, None, None),
    ("bfd", "Blackfathom Deeps", 24, 32, "Ashenvale", False, 719, None, None),
    ("stocks", "The Stockade", 24, 32, "Stormwind City", False, 717, None, "A"),
    ("excavacion", "Excavation Site: Wetlands", 26, 33, "Wetlands", True, 16732, None, None),
    ("dalaran", "City of Dalaran", 28, 35, "Alterac Mountains", True, 16544, None, None),
    ("rfk", "Razorfen Kraul", 29, 38, "The Barrens", False, 491, None, None),
    ("gnomer", "Gnomeregan", 29, 38, "Dun Morogh", False, 721, None, None),
    ("smcem", "Scarlet Graveyard", 30, 38, "Tirisfal Glades", False, 796, SM_CEMENTERIO, None),
    ("smbib", "Scarlet Library", 33, 41, "Tirisfal Glades", False, 796, SM_BIBLIOTECA, None),
    ("ahogada", "The Drowned City", 35, 42, "Stranglethorn Vale", True, None, None, None),
    ("smarm", "Scarlet Armory", 36, 44, "Tirisfal Glades", False, 796, SM_ARMERIA, None),
    ("rfd", "Razorfen Downs", 37, 46, "The Barrens", False, 722, None, None),
    ("smcat", "Scarlet Cathedral", 38, 46, "Tirisfal Glades", False, 796, SM_CATEDRAL, None),
    ("kroldok", "Krol'Dok Stronghold", 40, 47, "Riverglades", True, None, None, None),
    ("ulda", "Uldaman", 41, 51, "Badlands", False, 1337, None, None),
    ("zf", "Zul'Farrak", 44, 54, "Tanaris", False, 1176, None, None),
    ("mara", "Maraudon", 46, 55, "Desolace", False, None, None, None),
    ("alcaz", "Alcaz Prison", 48, 55, "Dustwallow Marsh", True, None, None, None),
    ("st", "Sunken Temple", 50, 60, "Swamp of Sorrows", False, None, None, None),
    ("brd", "Blackrock Depths", 52, 60, "Blackrock Mountain", False, None, None, None),
    ("dme", "Dire Maul (East)", 54, 60, "Feralas", False, None, None, None),
    ("lbrs", "Lower Blackrock Spire", 55, 60, "Blackrock Mountain", False, 1583, LBRS, None),
    ("blackmaw", "Blackmaw Hold", 55, 60, "Azshara", True, None, None, None),
    ("dmw", "Dire Maul (West)", 56, 60, "Feralas", False, None, None, None),
    ("dmn", "Dire Maul (North)", 56, 60, "Feralas", False, None, None, None),
    ("shaper", "Shaper's Terrace", 58, 60, "Un'Goro Crater", True, None, None, None),
    ("stratv", "Stratholme (Main Gate)", 58, 60, "Eastern Plaguelands", False, 2017, STRAT_VIVOS, None),
    ("stratm", "Stratholme (Service Gate)", 58, 60, "Eastern Plaguelands", False, 2017, STRAT_MUERTOS, None),
    ("scholo", "Scholomance", 58, 60, "Western Plaguelands", False, 2057, None, None),
    ("ubrs", "Upper Blackrock Spire", 59, 60, "Blackrock Mountain", False, 1583, UBRS, None),
]

# ---------------------------------------------------------------- JcJ
# Tipos de estadística de ItemSparse (StatModifier_bonusStat): hechos del cliente.
STAT_SANACION = {41}
STAT_HECHIZO = {42, 45, 18, 21}
STAT_FISICO = {3, 4, 38, 39, 16, 19, 31, 32, 50}
STAT_TANQUE = {12, 14, 15, 48}  # 13 sale en casi todos los conjuntos físicos: no sirve para decir "tanque"
# Rol de cada especialización (claves de Polestar).
CATEGORIA = {
    "DRUID": {"balance": "hechizo", "feral": "fisico", "restoration": "sanacion"},
    "PALADIN": {"holy": "sanacion", "protection": "tanque", "retribution": "fisico"},
    "PRIEST": {"discipline": "sanacion", "holy": "sanacion", "shadow": "hechizo"},
    "SHAMAN": {"elemental": "hechizo", "enhancement": "fisico", "restoration": "sanacion"},
    "WARRIOR": {"arms": "fisico", "fury": "fisico", "protection": "tanque"},
    "ROGUE": {"assassination": "fisico", "combat": "fisico", "subtlety": "fisico"},
    "HUNTER": {"beastmastery": "fisico", "marksmanship": "fisico", "survival": "fisico"},
    "MAGE": {"arcane": "hechizo", "fire": "hechizo", "frost": "hechizo"},
    "WARLOCK": {"affliction": "hechizo", "demonology": "hechizo", "destruction": "hechizo"},
}
BIT_CLASE = {1: "WARRIOR", 2: "PALADIN", 4: "HUNTER", 8: "ROGUE", 16: "PRIEST", 64: "SHAMAN", 128: "MAGE", 256: "WARLOCK", 1024: "DRUID"}
PRIMER_ID_FOREVER = 272000  # los conjuntos rehechos para Forever usan objetos nuevos (272xxx-274xxx)

# Guía al 60 "sin bandas": las bandas de Forever abren el 9-12-2026 y son otras (Barrow Deeps, Hyjal Summit,
# Onyxia: https://worldofwarcraft.blizzard.com/news/24303009). ForeverLevelingBiS trae también misiones y
# botín de bandas de Vanilla (Naxxramas, Ahn'Qiraj...). Regla PROPIA (no viene de una fuente): se dejan fuera
# las piezas de nivel de objeto > 66 (lo mejor de mazmorras y misiones de Vanilla llega a 63-65) y el
# botín de las bandas de Vanilla.
ILVL_TOPE = 66
BANDAS_VANILLA = {"Molten Core", "Blackwing Lair", "Zul'Gurub", "Ruins of Ahn'Qiraj", "Ahn'Qiraj Temple",
                  "Temple of Ahn'Qiraj", "Ahn'Qiraj", "Naxxramas", "Onyxia's Lair"}
# Misiones que dependen de Ahn'Qiraj (anillos de Silithus y de Tanaris "The Path of the ...") o de la
# Feria de la Luna Negra (premios por boletos): ni una ni otra está anunciada para Forever (NO VERIFICADO
# que existan). Regla propia, se quita cuando haya fuente.
ZONAS_MISION_FUERA = {"Silithus"}
MISIONES_FUERA = ("The Path of the", "Tickets - ")

NOMBRE_ROL = {
    "balance": "Equilibrio", "feral": "Feral", "restoration": "Restauración", "holy": "Sagrado",
    "protection": "Protección", "retribution": "Reprensión", "discipline": "Disciplina", "shadow": "Sombra",
    "elemental": "Elemental", "enhancement": "Mejora", "arms": "Armas", "fury": "Furia",
    "assassination": "Asesinato", "combat": "Combate", "subtlety": "Sutileza", "beastmastery": "Bestias",
    "marksmanship": "Puntería", "survival": "Supervivencia", "arcane": "Arcano", "fire": "Fuego",
    "frost": "Escarcha", "affliction": "Aflicción", "demonology": "Demonología", "destruction": "Destrucción",
}


def sha(p):
    return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()


def a_py(t):
    """Tabla de Lua -> dict/list de Python."""
    if hasattr(t, "items") and not isinstance(t, (str, bytes)):
        d = {k: a_py(v) for k, v in t.items()}
        if d and all(isinstance(k, int) for k in d) and sorted(d) == list(range(1, len(d) + 1)):
            return [d[i] for i in range(1, len(d) + 1)]
        return d
    return t


def leer_polestar(addons):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute("""
        REG = {}; LEV = nil
        Polestar = { ItemDB = {} }
        function Polestar.ItemDB.Register(m, items) REG[#REG + 1] = items end
        function Polestar.ItemDB.RegisterLeveling(m, d) LEV = { m = m, d = d } end
        NS = { Gear = {} }
        function cargar(src, nombre) local f, e = loadstring(src, "@" .. nombre); if not f then error(e) end; f("Polestar", NS) end
    """)
    g = L.globals()
    gear = addons / "Polestar" / "Gear"
    for f in ("Weights.lua", "SpecData.lua"):
        g.cargar((gear / f).read_text(encoding="utf-8"), f)
    for f in ("Items.lua", "Forever.lua"):
        L.execute((addons / "Polestar_ItemDB" / f).read_text(encoding="utf-8"))
    G = g.NS.Gear
    items = {}
    for reg in g.REG.values():
        for k, v in reg.items():
            items[int(k)] = v
    version = re.search(r"## Version: (\S+)", (addons / "Polestar" / "Polestar.toc").read_text(encoding="utf-8")).group(1)
    return {
        "clases": a_py(G.CLASSES), "pesos": a_py(G.WEIGHTS), "bandas": a_py(G.WEIGHT_BANDS),
        "prof": a_py(G.PROFICIENCY), "items": items, "lev": a_py(g.LEV.d), "levmeta": a_py(g.LEV.m),
        "version": version,
    }


def parse_item(s):
    """Mismo formato que Polestar/Gear/ItemDB.lua (parse)."""
    m = re.match(r"^(\d+) (\d+) (\d+) (\d+) (\d+) (\d+)", s)
    if not m:
        return None
    inv, ilvl, req, q, cl, sub = map(int, m.groups())
    rec = {"i": inv, "l": ilvl, "r": req, "q": q, "c": cl, "s": sub, "st": {}}
    dmin = dmax = speed = None
    unt = {"mpr": "mp5", "hpr": "hp5"}
    for k, n in re.findall(r"([a-zA-Z]+)(-?\d+)", s):
        n = int(n)
        if k == "dmin":
            dmin = n
        elif k == "dmax":
            dmax = n
        elif k == "speed":
            speed = n
        elif k == "cls":
            rec["a"] = n
        elif k == "uniq":
            rec["u"] = n == 1 or None
        else:
            rec["st"][unt.get(k, k)] = n
    if dmin is not None and dmax is not None and speed:
        rec["st"]["dps"] = round((dmin + dmax) / 2 / (speed / 1000), 1)
    return rec


def pesos_lua(P):
    clases, pesos = {}, {}
    for clase, meta in P["clases"].items():
        roles = [{"clave": s["key"], "nombre": NOMBRE_ROL.get(s["key"], s["label"])} for s in meta["specs"]]
        clases[clase] = {"bit": meta["bit"], "defecto": meta["default"], "roles": roles}
        pesos[clase] = {}
        for s in meta["specs"]:
            bandas = (P["bandas"].get(clase) or {}).get(s["key"])
            if bandas:
                pesos[clase][s["key"]] = [{"hasta": b["upTo"], "w": b["weights"], "fuente": b["source"]} for b in bandas]
            else:
                pesos[clase][s["key"]] = [{"hasta": 60, "w": P["pesos"][clase][s["key"]], "fuente": "polestar"}]
    puede = {}
    for clase, p in P["prof"].items():
        puede[clase] = {"armadura": p["armor"], "armadura40": p.get("armorAt40"), "escudo": p.get("shield") or None,
                        "reliquia": p.get("relic"), "ambidiestro": p.get("dualWield"),
                        "armas": sorted(int(k) for k, v in p["weapons"].items() if v)}
    return clases, pesos, puede


def mazmorras_lua(P, N):
    lev = P["lev"]
    npcs = {int(k): v for k, v in lev["npcs"].items()}
    zonas_usadas = {m[6] for m in MAZMORRAS if m[6]}
    caidas = {}  # zona -> [(item, npc, pct)]
    for iid, s in lev["src"].items():
        for npc, pct, zona in re.findall(r"d(\d+)x(\d+)z(\d+)", s):
            zona = int(zona)
            if zona in zonas_usadas:
                caidas.setdefault(zona, []).append((int(iid), int(npc), int(pct) / 10))
    # Misiones de mazmorra (FLB: dungeon=1) cuya zona es una de estas mazmorras: la recompensa es segura.
    misiones = {}
    for qid, s in lev["quests"].items():
        head, choices, items, nombre = s.split("|", 3)
        nivel, req, lado, zona, raza, clase, dungeon = map(int, head.split())
        if dungeon == 1 and zona in zonas_usadas:
            ids = [int(x) for x in re.findall(r"\d+", choices + " " + items)]
            if ids:
                misiones.setdefault(zona, []).append({"q": int(qid), "n": nombre, "lado": lado, "nivel": nivel, "ids": ids,
                                                      "rc": clase or None, "rr": raza or None})
    lista, botin, obj = [], {}, {}
    for clave, nombre, mn, mx, donde, nueva, zona, jefes, lado in MAZMORRAS:
        ent = {"clave": clave, "nombre": N.mazmorra(nombre), "min": mn, "max": mx, "donde": N.zona(donde), "nueva": nueva or None, "lado": lado,
               "datos": bool(zona)}
        lista.append(ent)
        filas = []
        for iid, npc, pct in caidas.get(zona, []):
            jefe = "trash" if npc == 0 else npcs.get(npc, str(npc))
            if jefes is not None and jefe not in jefes:
                continue
            filas.append({"id": iid, "jefe": "" if jefe == "trash" else N.npc(npc, jefe), "pct": pct, "bichos": (jefe == "trash") or None})
        for m in misiones.get(zona, []):
            # Una misión de una zona con varias alas (Monasterio, Cumbre, Stratholme) se muestra en todas.
            for iid in m["ids"]:
                filas.append({"id": iid, "mision": m["q"], "jefe": N.mision(m["q"], m["n"]), "pct": 100, "lado": m["lado"] if m["lado"] != 3 else None,
                              "rc": m["rc"], "rr": m["rr"]})
        filas.sort(key=lambda f: (f["id"], f.get("mision") or 0))
        if filas:
            botin[clave] = filas
        for f in filas:
            s = P["items"].get(f["id"])
            rec = parse_item(s) if isinstance(s, str) else None
            if rec:
                rec["n"] = N.objeto(f["id"], lev["names"].get(f["id"]))
                obj[f["id"]] = rec
    # Fuera los ids sin estadísticas (no se pueden puntuar).
    for k in list(botin):
        botin[k] = [dict(f, n=obj[f["id"]].get("n")) for f in botin[k] if f["id"] in obj]
    return lista, botin, obj


def fuentes_al_60(P, obj_maz, N):
    """Todas las piezas de nivel 50-60 con fuente en ForeverLevelingBiS (botín, misión o profesión), para el BiS al 60."""
    lev = P["lev"]
    npcs = {int(k): v for k, v in lev["npcs"].items()}
    zonas = {int(k): v for k, v in lev["zones"].items()}
    pr = lev.get("professions") or {}
    profs = {i + 1: v for i, v in enumerate(pr)} if isinstance(pr, list) else {int(k): v for k, v in pr.items()}
    quests = {}
    for qid, s in lev["quests"].items():
        head, _, _, nombre = s.split("|", 3)
        nivel, req, lado, zona, raza, clase, dungeon = map(int, head.split())
        quests[int(qid)] = {"n": nombre, "lado": lado, "zona": zonas.get(zona), "maz": dungeon == 1}
    obj, origen = {}, {}
    fuera = {"ilvl": 0, "banda": 0}
    for iid, s in lev["src"].items():
        iid = int(iid)
        raw = P["items"].get(iid)
        rec = parse_item(raw) if isinstance(raw, str) else None
        if not rec or rec["r"] < 50:
            continue
        if rec["l"] > ILVL_TOPE:  # equipo de banda (Naxxramas, Ahn'Qiraj, Atiesh...): no existe en Forever hoy
            fuera["ilvl"] += 1
            continue
        lst = []
        for tok in s.split():
            m = re.match(r"^q(\d+)$", tok)
            if m:
                q = quests.get(int(m.group(1)))
                if q and (q["zona"] in ZONAS_MISION_FUERA or any(p in (q["n"] or "") for p in MISIONES_FUERA)):
                    fuera["banda"] += 1
                    continue
                if q:
                    lst.append({"tipo": "mision", "q": int(m.group(1)), "n": N.mision(int(m.group(1)), q["n"]),
                                "zona": N.lugar(q["zona"]) if q["zona"] else None, "lado": q["lado"] if q["lado"] != 3 else None})
                continue
            m = re.match(r"^d(\d+)x(\d+)z(\d+)$", tok)
            if m:
                npc, pct, z = int(m.group(1)), int(m.group(2)) / 10, int(m.group(3))
                if zonas.get(z) in BANDAS_VANILLA:
                    fuera["banda"] += 1
                    continue
                jefe = npcs.get(npc, "") if npc else ""
                zona = zonas.get(z)
                # Una zona de los datos junta dos mazmorras: se nombra la de verdad por su jefe.
                if z == 1583:
                    zona = "Lower Blackrock Spire" if jefe in LBRS else "Upper Blackrock Spire"
                elif z == 2017:
                    zona = "Stratholme (Service Gate)" if jefe in STRAT_MUERTOS else "Stratholme (Main Gate)"
                elif z == 796:
                    zona = ("Scarlet Library" if jefe in SM_BIBLIOTECA else "Scarlet Armory" if jefe in SM_ARMERIA
                            else "Scarlet Cathedral" if jefe in SM_CATEDRAL else "Scarlet Graveyard")
                lst.append({"tipo": "botin", "jefe": N.npc(npc, jefe) if jefe else "", "pct": pct, "zona": N.lugar(zona) if zona else None})
                continue
            m = re.match(r"^c(\d+)p(\d+)s(\d+)$", tok)
            if m:
                prof = profs.get(int(m.group(2)))
                lst.append({"tipo": "profesion", "prof": N.profesion(prof) if prof else None, "nivel": int(m.group(3))})
        if lst:
            rec["n"] = N.objeto(iid, lev["names"].get(iid))
            obj[iid] = rec
            origen[iid] = lst
    print(f"guía al 60: fuera por nivel de objeto > {ILVL_TOPE}: {fuera['ilvl']} · fuentes de banda quitadas: {fuera['banda']}")
    return obj, origen


def jcj_lua(wago, N):
    sparse = {}
    with open(wago / "ItemSparse.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            sparse[int(r["ID"])] = r
    item = {}
    with open(wago / "Item.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            item[int(r["ID"])] = r
    conjuntos = {}
    with open(wago / "ItemSet.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            ids = [int(r[f"ItemID_{i}"]) for i in range(17) if r.get(f"ItemID_{i}") and int(r[f"ItemID_{i}"]) > 0]
            nombre = r["Name_lang"]
            if not ids or min(ids) < PRIMER_ID_FOREVER:
                continue
            m = re.match(r"^(Champion's|Warlord's|Lieutenant Commander's|Field Marshal's) (.+)$", nombre)
            if not m:
                continue
            rango, resto = m.groups()
            lado = "H" if rango in ("Champion's", "Warlord's") else "A"
            epico = rango in ("Warlord's", "Field Marshal's")
            tipos, clases, piezas = set(), set(), []
            for iid in ids:
                s = sparse.get(iid)
                if not s:
                    continue
                for i in range(10):
                    t = int(s[f"StatModifier_bonusStat_{i}"] or -1)
                    if t > 0:
                        tipos.add(t)
                ac = int(s["AllowableClass"] or 0)
                for b, c in BIT_CLASE.items():
                    if ac > 0 and ac & b:
                        clases.add(c)
                piezas.append({"id": iid, "nombre": s["Display_lang"], "inv": int(s["InventoryType"]),
                               "req": int(s["RequiredLevel"]), "ilvl": int(s["ItemLevel"]), "q": int(s["OverallQualityID"])})
            if tipos & STAT_SANACION:
                cat = "sanacion"
            elif tipos & STAT_TANQUE:
                cat = "tanque"
            elif tipos & STAT_HECHIZO and not (tipos & {3, 4, 38}):
                cat = "hechizo"
            else:
                cat = "fisico"
            conjuntos[int(r["ID"])] = {"set": int(r["ID"]), "nombre": nombre, "lado": lado, "epico": epico, "cat": cat,
                                       "clases": sorted(clases), "piezas": sorted(piezas, key=lambda p: p["inv"])}
    # Por clase y especialización: el conjunto azul y el épico de su rol (si no hay de su rol, el más cercano).
    jcj = {}
    for clase, roles in CATEGORIA.items():
        jcj[clase] = {}
        for rol, cat in roles.items():
            for lado in ("H", "A"):
                cands = [c for c in conjuntos.values() if clase in c["clases"] and c["lado"] == lado]
                for epico in (False, True):
                    elegidos = [c for c in cands if c["epico"] == epico and c["cat"] == cat]
                    nota = None
                    if not elegidos and cat == "tanque":
                        elegidos = [c for c in cands if c["epico"] == epico and c["cat"] == "fisico"]
                        nota = "no hay conjunto de tanque: se usa el físico"
                    if not elegidos:
                        continue
                    c = sorted(elegidos, key=lambda c: c["set"])[0]
                    jcj[clase].setdefault(rol, {}).setdefault(lado, {})["epico" if epico else "azul"] = {
                        "set": c["set"], "nombre": N.conjunto(c["set"], c["nombre"]), "nota": nota,
                        "piezas": [p["id"] for p in c["piezas"]],
                    }
    nombres = {p["id"]: N.objeto(p["id"], p["nombre"]) for c in conjuntos.values() for p in c["piezas"]}
    return jcj, conjuntos, nombres


CABECERA = """-- Generado por WOW_FOREVER/generador/equipo.py el {fecha}. NO editar a mano: volver a generar.
-- Licencia: GPL-3.0-only. De dónde viene cada dato: LICENSE-DATA.txt de esta carpeta.
local _, A = ...
A = A or {{}}
"""


def main(argv):
    addons = pathlib.Path(argv[1]) if len(argv) > 1 else ADDONS
    wago = pathlib.Path(argv[2]) if len(argv) > 2 else WAGO
    import datetime
    fecha = datetime.date.today().isoformat()
    P = leer_polestar(addons)
    N = Nombres()
    lista, botin, obj = mazmorras_lua(P, N)
    obj60, origen60 = fuentes_al_60(P, obj, N)
    for k, v in obj60.items():
        obj.setdefault(k, v)
    jcj, conjuntos, nombres_jcj = jcj_lua(wago, N)
    # Nombre esMX de todo objeto que se puede mostrar (respaldo de Juego.lua si el cliente aún no lo cargó).
    nombres_obj = {i: o["n"] for i, o in obj.items() if o.get("n")}
    nombres_obj.update(nombres_jcj)
    SALIDA.mkdir(parents=True, exist_ok=True)
    cab = CABECERA.format(fecha=fecha)
    viejo = SALIDA / "Datos_Pesos.lua"  # de la primera versión: los pesos ahora los da Polestar.Gear
    if viejo.exists():
        viejo.unlink()
    (SALIDA / "Datos_Mazmorras.lua").write_text(
        cab + "-- Mazmorras y niveles: Warcraft Tavern (16-11-2026). Botín y %: ForeverLevelingBiS "
        + f"{P['levmeta'].get('version')} de Thunder (MIT, datos del {P['levmeta'].get('generated')}, BETA) vía Polestar_ItemDB.\n"
        + "-- Solo el ÍNDICE (qué sale de dónde). Estadísticas, pesos y comparación: Polestar.Gear en el juego.\n"
        + "A.MAZMORRAS = " + a_lua(lista) + "\n\nA.BOTIN = " + a_lua(botin)
        + "\n\nA.ORIGEN60 = " + a_lua(origen60)
        + "\n\n-- Nombres esMX de los objetos (caché WDB del cliente o ItemSparse esMX). \"*\" al final = sin traducción (NO VERIFICADO).\n"
        + "A.NOMBRES_OBJ = " + a_lua(nombres_obj) + "\n",
        encoding="utf-8")
    (SALIDA / "Datos_JcJ.lua").write_text(
        cab + f"-- Conjuntos JcJ: tablas del cliente de Forever {BUILD_WAGO} (beta, 22-10-2026) vía wago.tools (ItemSet, ItemSparse).\n"
        + "-- Rangos: Blizzard, \"How PvP Progression in World of Warcraft: Forever Works\" (7-10-2026).\n"
        + "A.JCJ = " + a_lua(jcj) + "\n\nA.JCJ_NOMBRES = " + a_lua(nombres_jcj) + "\n",
        encoding="utf-8")
    huellas = {f: sha(wago / f) for f in ("ItemSet.csv", "ItemSparse.csv", "Item.csv")}
    for f in ("Polestar_ItemDB/Items.lua", "Polestar_ItemDB/Forever.lua"):
        huellas[f] = sha(addons / f)
    huellas.update(N.huellas)
    (SALIDA / "LICENSE-DATA.txt").write_text(LICENSE_DATA.format(
        fecha=fecha, version=P["version"], flb=P["levmeta"].get("version"), flbfecha=P["levmeta"].get("generated"),
        build=BUILD_WAGO, huellas="\n".join(f"  {v}  {k}" for k, v in sorted(huellas.items()))), encoding="utf-8")
    con = sum(1 for m in lista if m["clave"] in botin)
    sin = sorted(N.sin)
    print(f"sin traducción esMX (quedan en inglés con *): {len(sin)}")
    for t, n in sin:
        print("   ", t, n)
    print(f"mazmorras={len(lista)} con_botin={con} objetos={len(obj)} piezas60={len(origen60)} conjuntos_jcj={len(conjuntos)}")
    for c, d in jcj.items():
        print(" ", c, {r: {l: {k: x['nombre'] for k, x in v.items()} for l, v in lados.items()} for r, lados in d.items()})
    return P, lista, botin, obj, jcj


LICENSE_DATA = """Asistente_Equipo: de dónde viene cada dato (generado el {fecha})
==================================================================

Licencia del addon y de estos datos: GPL-3.0-only.
Nombres, números e ids del juego: de Blizzard Entertainment, usados como hechos. Este addon no está
hecho ni respaldado por Blizzard.

1. Polestar {version} (GPL-3.0-only) — https://github.com/fitzforge/polestar
   - En el juego, este módulo NO trae pesos ni estadísticas propias: llama a Polestar.Gear (pesos de
     Polestar con simulaciones de wowsims, rol, "¿lo puede usar?", comparación con lo puesto) y a su
     ItemDB. Este paquete es un fork de Polestar (ARQUITECTURA §13).
   - El índice de abajo se armó leyendo Polestar_ItemDB/Items.lua (tablas del cliente Classic Era vía
     wago.tools) para saber qué ids tienen estadísticas y su nivel de objeto.
2. ForeverLevelingBiS {flb} de Thunder (MIT, Copyright (c) 2026 Thunder), datos del {flbfecha}, leído desde
   Polestar_ItemDB/Forever.lua: estadísticas de Forever, botín de jefe con % de caída, misiones y
   profesiones de cada pieza. OJO: son datos de la BETA, anteriores al lanzamiento (4-11-2026).
3. Tablas del cliente de WoW: Forever {build} (beta, 22-10-2026) vía https://wago.tools: ItemSet,
   ItemSparse, Item. Solo ids, nombres de conjuntos y tipos de estadística, como hechos.
4. Niveles de las mazmorras: Warcraft Tavern, https://www.warcrafttavern.com/forever/guides/dungeons/
   (leída el 16-11-2026). Solo hechos (nombre y rango de nivel); no se copia texto.
5. Nombres en español mexicano (esMX), todos del propio juego: la caché WDB del cliente instalado
   (Mamba data/i18n/names-observed/esMX.json), ForeverTDB (GPL-2.0, creature_template_locale y
   quest_template_locale, solo nombres como hechos) y las tablas del cliente en esMX vía wago.tools
   (&locale=esMX): GroupFinderActivity y AreaTable 1.60.1.70959; ItemSparse, ItemSet y SkillLine
   {build} (+ ItemSparse esMX de Classic Era 1.15.9.70576), y la caché de hotfixes del cliente en esMX
   (Cache/ADB/esMX/DBCache.bin) para los objetos nuevos de Forever. Lo que no tiene nombre esMX queda en inglés con "*" (NO VERIFICADO).

NO se usa: AtlasLoot (GPL-2.0 solo, choca con GPL-3.0), QuestieDB ni Polestar_Codex (permisos solo
para Polestar), Wowhead ni otros sitios que prohíben copiar.

Huellas sha256 de lo que se leyó:
{huellas}

---- Aviso MIT de ForeverLevelingBiS ----
MIT License

Copyright (c) 2026 Thunder

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
THE USE OR OTHER DEALINGS IN THE SOFTWARE.

"""

if __name__ == "__main__":
    main(sys.argv)
