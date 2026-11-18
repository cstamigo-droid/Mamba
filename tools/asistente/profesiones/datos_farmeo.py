"""Datos de farmeo de Mamba (Mamba_Profesiones y Mamba_Mapa), sacados de hechos de ForeverTDB 2026-10-14
(autorizada el 17-11, solo hechos: quién suelta qué, con qué %, cuántas unidades, dónde aparece cada criatura y
cada nodo).

Escribe:
  addon/Mamba_Profesiones/DatosFarmeo.lua   M.FUENTES[item] = hasta 4 formas de juntarlo (criatura, nodo, desuello)
                                            M.LUGARES[objetivo] = las mejores zonas por tramo, con SU objeto
  addon/Mamba_Mapa/DatosNodos.lua           nodos de hierbas y vetas por mapa (x, y en %), con la habilidad pedida

Cuentas (aproximadas; la interfaz las marca con "≈"):
  - % de caída: el de la tabla; por referencia, % de la referencia × % dentro de ella; en un grupo de igual
    probabilidad (Chance 0), lo que queda del grupo repartido entre sus objetos.
  - unidades por caída: (MinCount + MaxCount) / 2.
  - zona de cada punto: los rectángulos de los mapas se pisan (Costa Oscura dentro de Frondavil), así que entre
    los que contienen el punto gana el de rango de nivel más parecido al de la criatura (o al del nodo:
    habilidad / 5), y después el más chico. Rangos de nivel de cada zona: los del juego clásico.
  - se descartan las criaturas amistosas con algún bando (guardias, PNJ de ciudad) y las que tienen función
    (npcflag): no se farmean.
Revisión wow-economía/profesiones del 18-11 (veto por zonas mal asignadas, guardias, objeto de otro tramo y
unidades por caída): arreglado aquí.
Uso: python -I tools/asistente/profesiones/datos_farmeo.py
Licencia: GPL-3.0-only.
"""
import collections, csv, json, pathlib, re, sqlite3, sys

sys.stdout.reconfigure(encoding="utf-8")
RAIZ = pathlib.Path(__file__).resolve().parents[3]
TDB = pathlib.Path(r"D:\rust\forever-tdb\world.sqlite")
UIMAPS = RAIZ / "forever-db" / "data" / "ui_map.jsonl"
FT = pathlib.Path(r"D:\rust\polestar-data\sources\wago\1.60.1.70938\FactionTemplate.csv")
RECETAS = RAIZ / "addon" / "SkillUpForever" / "Data" / "Recipes.lua"
OUT_P = RAIZ / "addon" / "Mamba_Profesiones" / "DatosFarmeo.lua"
OUT_N = RAIZ / "addon" / "Mamba_Mapa" / "DatosNodos.lua"

HIERBAS = {"Peacebloom": 1, "Silverleaf": 1, "Earthroot": 15, "Mageroyal": 50, "Briarthorn": 70, "Stranglekelp": 85,
           "Bruiseweed": 100, "Wild Steelbloom": 115, "Grave Moss": 120, "Kingsblood": 125, "Liferoot": 150,
           "Fadeleaf": 160, "Goldthorn": 170, "Khadgar's Whisker": 185, "Wintersbite": 195, "Firebloom": 205,
           "Purple Lotus": 210, "Arthas' Tears": 220, "Sungrass": 230, "Blindweed": 235, "Ghost Mushroom": 245,
           "Gromsblood": 250, "Golden Sansam": 260, "Dreamfoil": 270, "Mountain Silversage": 280,
           "Plaguebloom": 285, "Icecap": 290, "Black Lotus": 300}
VETAS = {"Copper Vein": 1, "Tin Vein": 65, "Incendicite Mineral Vein": 65, "Silver Vein": 75,
         "Lesser Bloodstone Deposit": 75, "Iron Deposit": 125, "Indurium Mineral Vein": 150, "Gold Vein": 155,
         "Mithril Deposit": 175, "Truesilver Deposit": 230, "Dark Iron Deposit": 230, "Small Thorium Vein": 245,
         "Ooze Covered Silver Vein": 75, "Ooze Covered Gold Vein": 155, "Ooze Covered Mithril Deposit": 175,
         "Ooze Covered Truesilver Deposit": 230, "Ooze Covered Thorium Vein": 245, "Rich Thorium Vein": 275,
         "Ooze Covered Rich Thorium Vein": 275}
OBJETIVOS = {
    "tela": [2589, 2592, 4306, 4338, 14047],
    "cuero": [2318, 2319, 4234, 4304, 8170, 783, 4232, 4235, 8169, 8171],
    "carne": [769, 2672, 2673, 3173, 3404, 3667, 3712, 3730, 3731, 12037, 12184, 12202, 12203, 12204, 12205],
}
MAPAS_CONTINENTE = {1414, 1415, 947}
# Rango de nivel de cada zona en el juego clásico (para desempatar rectángulos que se pisan).
NIVELES = {1411: (1, 10), 1412: (1, 10), 1413: (10, 25), 1416: (30, 40), 1417: (30, 40), 1418: (35, 45),
           1419: (45, 55), 1420: (1, 10), 1421: (10, 20), 1422: (51, 58), 1423: (53, 60), 1424: (20, 30),
           1425: (40, 50), 1426: (1, 10), 1427: (43, 50), 1428: (50, 58), 1429: (1, 10), 1430: (55, 60),
           1431: (18, 30), 1432: (10, 20), 1433: (15, 25), 1434: (30, 45), 1435: (35, 45), 1436: (10, 20),
           1437: (20, 30), 1438: (1, 10), 1439: (10, 20), 1440: (18, 30), 1441: (25, 35), 1442: (15, 27),
           1443: (30, 40), 1444: (40, 50), 1445: (35, 45), 1446: (40, 50), 1447: (45, 55), 1448: (48, 55),
           1449: (48, 55), 1450: (55, 60), 1451: (55, 60), 1452: (55, 60)}


def uimaps():
    return [json.loads(l) for l in open(UIMAPS, encoding="utf-8")]


def a_mapa(mapas, mapa, x, y, nivel=None):
    cand = [m for m in mapas if m["map"] == mapa and m["right"] <= y <= m["left"] and m["bottom"] <= x <= m["top"]
            and m["ui_map"] not in MAPAS_CONTINENTE]
    if not cand:
        return None

    def lejos(m):
        r = NIVELES.get(m["ui_map"])
        if nivel is None or not r:
            return 100 if not r else 0
        return 0 if r[0] <= nivel <= r[1] else min(abs(nivel - r[0]), abs(nivel - r[1]))
    m = min(cand, key=lambda m: (lejos(m), (m["left"] - m["right"]) * (m["top"] - m["bottom"])))
    return m["ui_map"], round((m["left"] - y) / (m["left"] - m["right"]) * 100, 1), \
        round((m["top"] - x) / (m["top"] - m["bottom"]) * 100, 1)


def bandos():
    """plantilla de facción -> 'A', 'H' o 'AH' si es amistosa (misma regla que datos_plan.py y forge)."""
    out = {}
    for r in csv.DictReader(open(FT, encoding="utf-8", newline="")):
        g = lambda k: int(r.get(k) or 0)
        idd, grp, fr, en = g("ID"), g("FactionGroup"), g("FriendGroup"), g("EnemyGroup")
        lado = lambda b: (fr & (1 | b) != 0 or grp & b != 0) and en & (1 | b) == 0
        v = ("A" if lado(2) else "") + ("H" if lado(4) else "")
        if v:
            out[idd] = v
    return out


def reactivos():
    t = RECETAS.read_text(encoding="utf-8")
    return {int(i) for i in re.findall(r"itemID = (\d+), quantity", t)}


def chances(filas):
    """filas (item, %, grupo, min, max) -> {item: (%, unidades promedio)}"""
    out, grupos = {}, collections.defaultdict(list)
    for it, ch, grp, mn, mx in filas:
        grupos[grp].append((it, ch, (mn + mx) / 2))
    for grp, lista in grupos.items():
        if grp == 0:
            for it, ch, u in lista:
                if ch > out.get(it, (0, 1))[0]:
                    out[it] = (ch, u)
        else:
            fijo = sum(ch for _, ch, _ in lista if ch > 0)
            ceros = [it for it, ch, _ in lista if ch == 0]
            for it, ch, u in lista:
                out[it] = (ch if ch > 0 else max(0.0, 100 - fijo) / len(ceros), u)
    return out


def tabla_ref(db):
    filas = collections.defaultdict(list)
    for e, typ, it, ch, grp, mn, mx in db.execute(
            "select Entry, ItemType, Item, Chance, GroupId, MinCount, MaxCount from reference_loot_template"):
        if typ == 0:
            filas[e].append((it, ch, grp, mn, mx))
    return {e: chances(f) for e, f in filas.items()}


def tabla(db, nombre, refs):
    filas = collections.defaultdict(list)
    ref_de = collections.defaultdict(list)
    for e, typ, it, ch, grp, mn, mx in db.execute(
            f"select Entry, ItemType, Item, Chance, GroupId, MinCount, MaxCount from {nombre}"):
        if typ == 0:
            filas[e].append((it, ch, grp, mn, mx))
        elif typ == 1:
            ref_de[e].append((it, ch, mx))
    out = {}
    for e in set(filas) | set(ref_de):
        c = chances(filas.get(e, []))
        for ref, ch, veces in ref_de.get(e, []):
            for it, (dentro, u) in refs.get(ref, {}).items():
                pct = (ch or 100) * dentro / 100
                if pct > c.get(it, (0, 1))[0]:
                    c[it] = (pct, u * max(1, veces or 1))
        out[e] = c
    return out


def esc(s):
    return (s or "").replace("\\", "\\\\").replace('"', '\\"')


def main():
    db = sqlite3.connect(TDB)
    mapas = uimaps()
    lados = bandos()
    refs = tabla_ref(db)
    botin = tabla(db, "creature_loot_template", refs)
    pieles = tabla(db, "skinning_loot_template", refs)
    nodos_b = tabla(db, "gameobject_loot_template", refs)
    nombre_es = dict(db.execute("select entry, Name from creature_template_locale where locale='esMX'"))
    go_es = dict(db.execute("select entry, name from gameobject_template_locale where locale='esMX'"))
    nivel = {e: (a, b) for e, a, b in db.execute("select entry, level_min, level_max from creature_classic_level")}
    dif = {e: (l, s) for e, l, s in db.execute(
        "select Entry, LootID, SkinLootID from creature_template_difficulty where DifficultyID=0")}
    plantilla = {e: (cl, fa, nf, nom) for e, cl, fa, nf, nom in
                 db.execute("select entry, Classification, faction, npcflag, name from creature_template")}
    # criaturas que se farmean: normales, hostiles a los dos bandos y sin función
    farmeables = {e for e, (cl, fa, nf, nom) in plantilla.items() if cl == 0 and not nf and fa not in lados}
    ap = collections.defaultdict(lambda: collections.defaultdict(list))
    for cid, mapa, x, y in db.execute("select id, map, position_x, position_y from creature where map in (0, 1)"):
        if cid not in farmeables:
            continue
        lv = nivel.get(cid, (0, 0))
        r = a_mapa(mapas, mapa, x, y, (lv[0] + lv[1]) / 2 if lv[1] else None)
        if r:
            ap[cid][r[0]].append((r[1], r[2]))
    nodos = collections.defaultdict(lambda: collections.defaultdict(list))
    go_nodo = {}
    for gid, nom, d1 in db.execute("select entry, name, Data1 from gameobject_template where type=3"):
        if nom in HIERBAS or nom in VETAS:
            go_nodo[gid] = (nom, d1)
    for gid, mapa, x, y in db.execute("select id, map, position_x, position_y from gameobject where map in (0, 1)"):
        if gid in go_nodo:
            nom = go_nodo[gid][0]
            hab = HIERBAS.get(nom) or VETAS.get(nom)
            r = a_mapa(mapas, mapa, x, y, max(1, min(60, hab / 5)))
            if r:
                nodos[nom][r[0]].append((r[1], r[2]))
    nodo_items = collections.defaultdict(dict)  # nodo -> {item: (%, u)}
    nodo_es = {}
    for gid, (nom, d1) in go_nodo.items():
        for it, cu in nodos_b.get(d1, {}).items():
            if cu[0] > nodo_items[nom].get(it, (0, 1))[0]:
                nodo_items[nom][it] = cu
        if go_es.get(gid):
            nodo_es.setdefault(nom, go_es[gid])
    # objeto principal de cada nodo: el de mayor % (la hierba o el mineral; las gemas caen poco)
    principal = {nom: max(its.items(), key=lambda kv: kv[1][0]) for nom, its in nodo_items.items() if its}

    def centro(pts):
        return round(sum(p[0] for p in pts) / len(pts), 1), round(sum(p[1] for p in pts) / len(pts), 1)

    quiero = reactivos() | {i for l in OBJETIVOS.values() for i in l}
    fuentes = collections.defaultdict(list)
    for cid, zonas in ap.items():
        lid, sid = dif.get(cid, (0, 0))
        nom = nombre_es.get(cid) or plantilla[cid][3]
        if not nom or "(" in nom or "[" in nom:
            continue
        lv = nivel.get(cid, (0, 0))
        for tipo, tab, idx in (("mob", botin, lid or cid), ("piel", pieles, sid)):
            if not idx:
                continue
            for it, (ch, u) in tab.get(idx, {}).items():
                if it in quiero and ch >= 2:
                    for zona, pts in zonas.items():
                        if len(pts) >= 4:
                            x, y = centro(pts)
                            fuentes[it].append((ch * u * len(pts), tipo, zona, x, y, nom, lv, round(ch, 1), len(pts), round(u, 2)))
    for nom, its in nodo_items.items():
        for it, (ch, u) in its.items():
            if it in quiero and ch >= 2:
                for zona, pts in nodos[nom].items():
                    if len(pts) >= 4:
                        x, y = centro(pts)
                        hab = HIERBAS.get(nom) or VETAS.get(nom)
                        fuentes[it].append((ch * u * min(len(pts), 100), "hierba" if nom in HIERBAS else "veta", zona, x, y,
                                            nodo_es.get(nom, nom), (hab, hab), round(ch, 1), len(pts), round(u, 2)))
    out = ["-- Generado por tools/asistente/profesiones/datos_farmeo.py; no editar a mano.",
           "-- Fuente: ForeverTDB 2026-10-14 (hechos: botín, desuello, nodos y apariciones). Los % son de la tabla; con",
           "-- referencias y grupos, aproximados (≈). Licencia: GPL-3.0-only.",
           "local _, M = ...",
           "-- [objeto] = { { tipo (mob|piel|hierba|veta), mapa, x, y, nombre, nivelMin, nivelMax (o habilidad), %, apariciones, unidades por caída } }",
           "M.FUENTES = {"]
    n = 0
    for it in sorted(fuentes):
        vistos, sel = set(), []
        for r in sorted(fuentes[it], key=lambda r: -r[0]):
            k = (r[1], r[2])
            if k in vistos:
                continue
            vistos.add(k)
            sel.append(r)
            if len(sel) >= 4:
                break
        filas = ", ".join('{"%s",%d,%s,%s,"%s",%d,%d,%s,%d,%s}' % (r[1], r[2], r[3], r[4], esc(r[5]), r[6][0] or 0,
                                                                     r[6][1] or 0, r[7], r[8], r[9]) for r in sel)
        out.append("\t[%d] = { %s }," % (it, filas))
        n += 1
    out.append("}")
    out.append("-- [objetivo] = { { tramo (1 = niveles 1-10 o habilidad 1-49...), mapa, x, y, criatura o nodo, nivelMin, nivelMax,")
    out.append("--   puntaje, objeto, %, unidades por caída, apariciones } }: cada fila con SU objeto")
    out.append("M.LUGARES = {")
    for obj, items in OBJETIVOS.items():
        mejor = collections.defaultdict(list)
        for it in items:
            for r in fuentes.get(it, []):
                if r[1] in ("hierba", "veta"):
                    continue
                mejor[max(1, min(6, (r[6][1] + 9) // 10))].append((it,) + r)
        filas = []
        for tramo in sorted(mejor):
            usados = set()
            for r in sorted(mejor[tramo], key=lambda r: -r[1]):
                if r[3] in usados:
                    continue
                usados.add(r[3])
                filas.append('{%d,%d,%s,%s,"%s",%d,%d,%d,%d,%s,%s,%d}' % (tramo, r[3], r[4], r[5], esc(r[6]), r[7][0], r[7][1],
                                                                          r[1], r[0], r[8], r[10], r[9]))
                if len(usados) >= 3:
                    break
        out.append("\t%s = { %s }," % (obj, ", ".join(filas)))
    for obj, tabla_h in (("hierbas", HIERBAS), ("minerales", VETAS)):
        por = collections.defaultdict(dict)  # tramo -> zona -> (nodo con más puntos, cuántos)
        for nom, hab in tabla_h.items():
            if nom not in principal:
                continue
            tramo = max(1, min(6, hab // 50 + 1))
            for zona, pts in nodos[nom].items():
                if len(pts) > por[tramo].get(zona, ("", 0))[1]:
                    por[tramo][zona] = (nom, len(pts))
        filas = []
        for tramo in sorted(por):
            for zona, (nom, cnt) in sorted(por[tramo].items(), key=lambda kv: -kv[1][1])[:3]:
                it, (ch, u) = principal[nom]
                x, y = centro(nodos[nom][zona])
                hab = tabla_h[nom]
                filas.append('{%d,%d,%s,%s,"%s",%d,%d,%d,%d,%s,%s,%d}' % (tramo, zona, x, y, esc(nodo_es.get(nom, nom)), hab, hab,
                                                                          cnt, it, round(ch, 1), round(u, 2), cnt))
        out.append("\t%s = { %s }," % (obj, ", ".join(filas)))
    out.append("}")
    OUT_P.write_bytes(("\n".join(out) + "\n").encode("utf-8"))
    o = ["-- Generado por tools/asistente/profesiones/datos_farmeo.py; no editar a mano.",
         "-- Nodos de hierbas y vetas por mapa, de ForeverTDB 2026-10-14 (apariciones de objetos). Licencia: GPL-3.0-only.",
         "local _, M = ...",
         "-- [nombre en inglés] = { tipo (h|v), habilidad, nombre esMX, { [mapa] = \"x,y;x,y;...\" } }",
         "M.NODOS = {"]
    total = 0
    for nom in sorted(nodos):
        tipo = "h" if nom in HIERBAS else "v"
        hab = HIERBAS.get(nom) or VETAS.get(nom)
        partes = []
        for zona in sorted(nodos[nom]):
            pts = sorted(set(nodos[nom][zona]))
            total += len(pts)
            partes.append('[%d]="%s"' % (zona, ";".join("%s,%s" % p for p in pts)))
        o.append('\t["%s"] = { "%s", %d, "%s", { %s } },' % (esc(nom), tipo, hab, esc(nodo_es.get(nom, nom)), ", ".join(partes)))
    o.append("}")
    OUT_N.write_bytes(("\n".join(o) + "\n").encode("utf-8"))
    print(f"fuentes de {n} objetos; nodos: {len(nodos)} tipos, {total} puntos; criaturas farmeables: {len(farmeables)}")


if __name__ == "__main__":
    main()
