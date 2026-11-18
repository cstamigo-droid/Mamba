"""Datos de farmeo de Mamba (Mamba_Profesiones y Mamba_Mapa), sacados de hechos de ForeverTDB 2026-10-14
(autorizada el 17-11, solo hechos: quién suelta qué, con qué %, dónde aparece cada criatura y cada nodo).

Escribe:
  addon/Mamba_Profesiones/DatosFarmeo.lua   M.FUENTES[item] = hasta 4 formas de juntarlo (criatura, nodo, desuello)
                                            M.LUGARES[objetivo] = las mejores zonas por tramo de nivel
  addon/Mamba_Mapa/DatosNodos.lua           nodos de hierbas y vetas por mapa (x, y en %), con la habilidad pedida

Cuentas (todas aproximadas, por eso la interfaz las marca con "≈"):
  - % de caída: el de la tabla; si el objeto viene por una tabla de referencia, % de la referencia × % dentro de ella;
    en un grupo de igual probabilidad (Chance 0), lo que queda del grupo repartido entre sus objetos.
  - "aparece N veces": puntos de aparición de la criatura en la zona.
Uso: python -I tools/asistente/profesiones/datos_farmeo.py
Licencia: GPL-3.0-only.
"""
import collections, json, pathlib, re, sqlite3, sys

sys.stdout.reconfigure(encoding="utf-8")
RAIZ = pathlib.Path(__file__).resolve().parents[3]
TDB = pathlib.Path(r"D:\rust\forever-tdb\world.sqlite")
UIMAPS = RAIZ / "forever-db" / "data" / "ui_map.jsonl"
RECETAS = RAIZ / "addon" / "SkillUpForever" / "Data" / "Recipes.lua"
OUT_P = RAIZ / "addon" / "Mamba_Profesiones" / "DatosFarmeo.lua"
OUT_N = RAIZ / "addon" / "Mamba_Mapa" / "DatosNodos.lua"

# Habilidad que pide cada nodo (valores del juego clásico, iguales en Forever según las fichas de SkillUpForever).
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
OBJETIVOS = {  # objetivo -> objetos que cuentan
    "tela": [2589, 2592, 4306, 4338, 14047],
    "cuero": [2318, 2319, 4234, 4304, 8170, 783, 4232, 4235, 8169, 8171],
    "carne": [769, 2672, 2673, 3173, 3404, 3667, 3712, 3730, 3731, 12037, 12184, 12202, 12203, 12204, 12205],
}
MAPAS_CONTINENTE = {1414, 1415, 947}


def uimaps():
    return [json.loads(l) for l in open(UIMAPS, encoding="utf-8")]


def a_mapa(mapas, mapa, x, y):
    cand = [m for m in mapas if m["map"] == mapa and m["right"] <= y <= m["left"] and m["bottom"] <= x <= m["top"]
            and m["ui_map"] not in MAPAS_CONTINENTE]
    if not cand:
        return None
    m = min(cand, key=lambda m: (m["left"] - m["right"]) * (m["top"] - m["bottom"]))
    return m["ui_map"], round((m["left"] - y) / (m["left"] - m["right"]) * 100, 1), \
        round((m["top"] - x) / (m["top"] - m["bottom"]) * 100, 1)


def reactivos():
    t = RECETAS.read_text(encoding="utf-8")
    return {int(i) for i in re.findall(r"itemID = (\d+), quantity", t)}


def tabla_ref(db):
    """referencia -> {item: % dentro de la referencia}"""
    filas = collections.defaultdict(list)
    for e, typ, it, ch, grp in db.execute("select Entry, ItemType, Item, Chance, GroupId from reference_loot_template"):
        if typ == 0:
            filas[e].append((it, ch, grp))
    return {e: chances(f) for e, f in filas.items()}


def chances(filas):
    out, grupos = {}, collections.defaultdict(list)
    for it, ch, grp in filas:
        grupos[grp].append((it, ch))
    for grp, lista in grupos.items():
        if grp == 0:
            for it, ch in lista:
                out[it] = max(out.get(it, 0), ch)
        else:
            fijo = sum(ch for _, ch in lista if ch > 0)
            ceros = [it for it, ch in lista if ch == 0]
            for it, ch in lista:
                out[it] = ch if ch > 0 else max(0.0, 100 - fijo) / len(ceros)
    return out


def tabla(db, nombre, refs):
    filas = collections.defaultdict(list)
    ref_de = collections.defaultdict(list)
    for e, typ, it, ch, grp in db.execute(f"select Entry, ItemType, Item, Chance, GroupId from {nombre}"):
        if typ == 0:
            filas[e].append((it, ch, grp))
        elif typ == 1:
            ref_de[e].append((it, ch))
    out = {}
    for e in set(filas) | set(ref_de):
        c = chances(filas.get(e, []))
        for ref, ch in ref_de.get(e, []):
            for it, dentro in refs.get(ref, {}).items():
                c[it] = max(c.get(it, 0), (ch or 100) * dentro / 100)
        out[e] = c
    return out


def main():
    db = sqlite3.connect(TDB)
    mapas = uimaps()
    refs = tabla_ref(db)
    botin = tabla(db, "creature_loot_template", refs)
    pieles = tabla(db, "skinning_loot_template", refs)
    nodos_b = tabla(db, "gameobject_loot_template", refs)
    nombre_es = dict(db.execute("select entry, Name from creature_template_locale where locale='esMX'"))
    go_es = dict(db.execute("select entry, name from gameobject_template_locale where locale='esMX'"))
    nivel = {e: (a, b) for e, a, b in db.execute("select entry, level_min, level_max from creature_classic_level")}
    dif = {e: (l, s) for e, l, s in db.execute(
        "select Entry, LootID, SkinLootID from creature_template_difficulty where DifficultyID=0")}
    clase = dict(db.execute("select entry, Classification from creature_template"))
    nombre_en = dict(db.execute("select entry, name from creature_template"))
    # apariciones por criatura y zona
    ap = collections.defaultdict(lambda: collections.defaultdict(list))
    for cid, mapa, x, y in db.execute("select id, map, position_x, position_y from creature where map in (0, 1)"):
        r = a_mapa(mapas, mapa, x, y)
        if r:
            ap[cid][r[0]].append((r[1], r[2]))
    # nodos
    nodos = collections.defaultdict(lambda: collections.defaultdict(list))  # nombre -> ui_map -> [(x,y)]
    go_nodo = {}
    for gid, nom, d1 in db.execute("select entry, name, Data1 from gameobject_template where type=3"):
        if nom in HIERBAS or nom in VETAS:
            go_nodo[gid] = (nom, d1)
    for gid, mapa, x, y in db.execute("select id, map, position_x, position_y from gameobject where map in (0, 1)"):
        if gid in go_nodo:
            r = a_mapa(mapas, mapa, x, y)
            if r:
                nodos[go_nodo[gid][0]][r[0]].append((r[1], r[2]))
    nodo_items = collections.defaultdict(dict)  # nombre de nodo -> {item: %}
    nodo_es = {}
    for gid, (nom, d1) in go_nodo.items():
        for it, ch in nodos_b.get(d1, {}).items():
            nodo_items[nom][it] = max(nodo_items[nom].get(it, 0), ch)
        if gid in go_es and go_es[gid]:
            nodo_es.setdefault(nom, go_es[gid])

    def centro(pts):
        return round(sum(p[0] for p in pts) / len(pts), 1), round(sum(p[1] for p in pts) / len(pts), 1)

    def esc(s):
        return (s or "").replace("\\", "\\\\").replace('"', '\\"')

    # fuentes por objeto
    quiero = reactivos() | {i for l in OBJETIVOS.values() for i in l}
    fuentes = collections.defaultdict(list)
    for cid, zonas in ap.items():
        lid, sid = dif.get(cid, (0, 0))
        if clase.get(cid, 0) not in (0,):  # solo criaturas normales (las élite no se farmean solas)
            continue
        nom = nombre_es.get(cid) or nombre_en.get(cid)
        if not nom or "(" in nom or "[" in nom:
            continue
        lv = nivel.get(cid, (0, 0))
        for tipo, tab, idx in (("mob", botin, lid or cid), ("piel", pieles, sid)):
            if not idx:
                continue
            for it, ch in tab.get(idx, {}).items():
                if it in quiero and ch >= 2:
                    for zona, pts in zonas.items():
                        if len(pts) >= 4:
                            x, y = centro(pts)
                            fuentes[it].append((ch * len(pts), tipo, zona, x, y, nom, lv, round(ch, 1), len(pts)))
    for nom, its in nodo_items.items():
        for it, ch in its.items():
            if it in quiero and ch >= 2:
                for zona, pts in nodos[nom].items():
                    if len(pts) >= 4:
                        x, y = centro(pts)
                        hab = HIERBAS.get(nom) or VETAS.get(nom)
                        fuentes[it].append((ch * len(pts) * 1.5, "hierba" if nom in HIERBAS else "veta", zona, x, y, nodo_es.get(nom, nom), (hab, hab),
                                            round(ch, 1), len(pts)))
    out = ["-- Generado por tools/asistente/profesiones/datos_farmeo.py; no editar a mano.",
           "-- Fuente: ForeverTDB 2026-10-14 (hechos: botín, desuello, nodos y apariciones). Los % son de la tabla; con",
           "-- referencias y grupos, aproximados (≈). Licencia: GPL-3.0-only.",
           "local _, M = ...",
           "-- [objeto] = { { tipo (mob|piel|hierba|veta), mapa, x, y, nombre, nivelMin, nivelMax (o habilidad), %, apariciones } }",
           "M.FUENTES = {"]
    n = 0
    for it in sorted(fuentes):
        lista = sorted(fuentes[it], key=lambda r: -r[0])
        vistos, sel = set(), []
        for r in lista:
            k = (r[1], r[2])
            if k in vistos:
                continue
            vistos.add(k)
            sel.append(r)
            if len(sel) >= 4:
                break
        filas = ", ".join('{"%s",%d,%s,%s,"%s",%d,%d,%s,%d}' % (r[1], r[2], r[3], r[4], esc(r[5]), r[6][0] or 0,
                                                                  r[6][1] or 0, r[7], r[8]) for r in sel)
        out.append("\t[%d] = { %s }," % (it, filas))
        n += 1
    out.append("}")
    # lugares por objetivo y tramo de nivel (10 en 10)
    out.append("-- [objetivo] = { { tramo (1 = niveles 1-10...), mapa, x, y, criatura, nivelMin, nivelMax, puntaje (≈ unidades por cada 100 muertes × apariciones) } }")
    out.append("M.LUGARES = {")
    for obj, items in OBJETIVOS.items():
        mejor = collections.defaultdict(list)
        for it in items:
            for r in fuentes.get(it, []):
                if r[1] in ("hierba", "veta"):
                    continue
                tramo = max(1, min(6, (r[6][1] + 9) // 10))
                mejor[tramo].append(r)
        filas = []
        for tramo in sorted(mejor):
            usados = set()
            for r in sorted(mejor[tramo], key=lambda r: -r[0]):
                if r[2] in usados:
                    continue
                usados.add(r[2])
                filas.append('{%d,%d,%s,%s,"%s",%d,%d,%d}' % (tramo, r[2], r[3], r[4], esc(r[5]), r[6][0], r[6][1], r[0]))
                if len(usados) >= 3:
                    break
        out.append("\t%s = { %s }," % (obj, ", ".join(filas)))
    # hierbas y minerales: zonas con más nodos por tramo de habilidad
    for obj, tabla_h in (("hierbas", HIERBAS), ("minerales", VETAS)):
        por = collections.defaultdict(lambda: collections.Counter())
        for nom, hab in tabla_h.items():
            tramo = max(1, min(6, hab // 50 + 1))
            for zona, pts in nodos[nom].items():
                por[tramo][zona] += len(pts)
        filas = []
        for tramo in sorted(por):
            for zona, cnt in por[tramo].most_common(3):
                filas.append('{%d,%d,0,0,"",0,0,%d}' % (tramo, zona, cnt))
        out.append("\t%s = { %s }," % (obj, ", ".join(filas)))
    out.append("}")
    OUT_P.write_bytes(("\n".join(out) + "\n").encode("utf-8"))
    # nodos para el mapa
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
    print(f"fuentes de {n} objetos; nodos: {len(nodos)} tipos, {total} puntos")


if __name__ == "__main__":
    main()
