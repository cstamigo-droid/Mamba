"""Genera los datos de "Mi plan" (Mamba_Plan): bolsas y dinero. Solo hechos, con su fuente.

Uso: python -I tools/asistente/plan/datos_plan.py [salida: addon/Mamba_Plan]
Fuentes (autorizadas, FUENTES.md):
  - tablas del cliente (wago.tools, build 1.15.9.70576, esMX): ItemSparse (nombre, casillas, familia, precio,
    nivel), Item (clase), SpellEffect + SkillLineAbility (qué receta la fabrica y con qué habilidad);
  - ForeverTDB 2026-10-14 (autorizada 17-11, solo hechos): npc_vendor (quién la vende), quest_template
    (qué misión la da), trainer_spell + creature_trainer (entrenamientos por clase y nivel, equitación).
Licencia: GPL-3.0-only.
"""
import csv, sqlite3, sys, pathlib, collections
sys.stdout.reconfigure(encoding="utf-8")
csv.field_size_limit(10**8)

WAGO = pathlib.Path(r"D:\rust\polestar-data\sources\wago\1.15.9.70576")
TDB = pathlib.Path(r"D:\rust\forever-tdb\world.sqlite")
RAIZ = pathlib.Path(__file__).resolve().parents[3]
SALIDA = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "addon" / "Mamba_Plan"

PROF = {197: "Sastrería", 165: "Peletería", 202: "Ingeniería", 164: "Herrería", 333: "Encantamiento", 171: "Alquimia"}
# familia de la bolsa (subclase de la clase 1 "Contenedor"; 11 = carcaj o canana)
FAMILIA = {(1, 0): "bolsa", (1, 1): "almas", (1, 2): "hierbas", (1, 3): "encantamiento", (1, 4): "ingeniería",
           (11, 2): "carcaj", (11, 3): "canana"}
CLASES = {1: "WARRIOR", 2: "PALADIN", 3: "HUNTER", 4: "ROGUE", 5: "PRIEST", 7: "SHAMAN", 8: "MAGE", 9: "WARLOCK", 11: "DRUID"}


def leer(nombre, sub=""):
    p = WAGO / sub / nombre if sub else WAGO / nombre
    with open(p, encoding="utf-8", newline="") as f:
        yield from csv.DictReader(f)


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def bolsas(db):
    clase = {}
    for r in leer("Item.csv"):
        c, s = int(r["ClassID"]), int(r["SubclassID"])
        if c in (1, 11):
            clase[int(r["ID"])] = (c, s)
    items = {}
    for r in leer("ItemSparse.csv", "esMX"):
        i = int(r["ID"])
        if i not in clase:
            continue
        slots = int(r["ContainerSlots"] or 0)
        fam = FAMILIA.get(clase[i])
        if slots <= 0 or not fam:
            continue
        items[i] = {"nombre": r["Display_lang"], "casillas": slots, "familia": fam,
                    "nivel": int(r["RequiredLevel"] or 0), "calidad": int(r["OverallQualityID"] or 0),
                    "precio": int(r["BuyPrice"] or 0)}
    # fabricar: hechizo que crea el objeto -> profesión y habilidad
    crea = collections.defaultdict(list)
    for r in leer("SpellEffect.csv"):
        if r["Effect"] == "24":
            it = int(r["EffectItemType"] or 0)
            if it in items:
                crea[int(r["SpellID"])].append(it)
    for r in leer("SkillLineAbility.csv"):
        sp, sk = int(r["Spell"]), int(r["SkillLine"])
        if sp in crea and sk in PROF:
            for it in crea[sp]:
                items[it].setdefault("fabrica", (PROF[sk], int(r["MinSkillLineRank"] or 0), sp))
    # vendedores y misiones (ForeverTDB)
    for it in items:
        n = db.execute("select count(distinct entry) from npc_vendor where item=?", (it,)).fetchone()[0]
        if n:
            items[it]["vendedores"] = n
    cols = [r[1] for r in db.execute("pragma table_info(quest_template)")]
    rew = [c for c in cols if c.startswith("RewardItem") or c.startswith("RewardChoiceItemID")]
    for c in rew:
        for q, it in db.execute(f"select ID, {c} from quest_template where {c} in ({','.join(map(str, items))})"):
            items[it].setdefault("misiones", set()).add(q)
    out = {i: d for i, d in items.items() if d.get("vendedores") or d.get("fabrica") or d.get("misiones")}
    return out


def dinero(db):
    # entrenamientos de clase: costo por nivel (hechizos distintos que pide ese nivel, con ese costo)
    filas = db.execute("""select ct.trainer_class, ts.ReqLevel, ts.SpellId, max(ts.MoneyCost)
        from trainer t join creature_trainer cr on cr.TrainerID = t.Id
        join creature_template ct on ct.entry = cr.CreatureID
        join trainer_spell ts on ts.TrainerId = t.Id
        where t.Type = 0 and ts.ReqLevel > 0 group by ct.trainer_class, ts.SpellId""").fetchall()
    por = collections.defaultdict(lambda: collections.defaultdict(int))
    for cl, nivel, sp, costo in filas:
        if cl in CLASES:
            por[CLASES[cl]][nivel] += costo
    equit = {sp: (nivel, costo) for sp, nivel, costo in
             db.execute("select SpellId, ReqLevel, max(MoneyCost) from trainer_spell where SpellId in (33388, 33391) group by SpellId")}
    return por, equit


# Rangos de cada profesión: Aprendiz, Oficial, Experto, Artesano (ids de hechizo de los instructores del juego;
# se comprueba en ForeverTDB que cada uno lo enseña algún instructor).
RANGOS = {
    "Alquimia": [2259, 3101, 3464, 11611], "Herboristería": [2366, 2368, 3570, 11993],
    "Minería": [2575, 2576, 3564, 10248], "Desuello": [8613, 8617, 8618, 10768],
    "Peletería": [2108, 3104, 3811, 10662], "Sastrería": [3908, 3909, 3910, 12180],
    "Herrería": [2018, 3100, 3538, 9785], "Ingeniería": [4036, 4037, 4038, 12656],
    "Encantamiento": [7411, 7412, 7413, 13920], "Cocina": [2550, 3102, 3413, 18260],
    "Primeros auxilios": [3273, 3274, 7924, 10846], "Pesca": [7620, 7731, 7732, 18248],
}
TOPES = [75, 150, 225, 300]
FT = WAGO.parent / "1.60.1.70938" / "FactionTemplate.csv"
FDB = RAIZ / "forever-db" / "data"


def bandos():
    """Plantilla de facción -> 'A', 'H' o 'AH' (misma regla que forge, mamba_foreverdb.rs: faction_sides)."""
    out = {}
    for r in csv.DictReader(open(FT, encoding="utf-8", newline="")):
        g = lambda k: int(r.get(k) or 0)
        idd, grp, fr, en = g("ID"), g("FactionGroup"), g("FriendGroup"), g("EnemyGroup")
        lado = lambda b: (fr & (1 | b) != 0 or grp & b != 0) and en & (1 | b) == 0
        v = ("A" if lado(2) else "") + ("H" if lado(4) else "")
        if v:
            out[idd] = v
    return out


def lugares_npc(ids):
    """npc -> (bando, ui_map, x%, y%) con su primera aparición, por forever-db (spawn, npc, ui_map)."""
    import json
    lados = bandos()
    plantilla = {}
    for l in open(FDB / "npc.jsonl", encoding="utf-8"):
        r = json.loads(l)
        if r["id"] in ids:
            plantilla[r["id"]] = r.get("faction_template")
    mapas = [json.loads(l) for l in open(FDB / "ui_map.jsonl", encoding="utf-8")]
    out = {}
    for l in open(FDB / "spawn.jsonl", encoding="utf-8"):
        r = json.loads(l)
        if r.get("kind") != "npc" or r["id"] not in ids or r["id"] in out:
            continue
        x, y = r["x"], r["y"]
        cand = [m for m in mapas if m["map"] == r["map"] and m["right"] <= y <= m["left"] and m["bottom"] <= x <= m["top"]]
        if not cand:
            continue
        m = min(cand, key=lambda m: (m["left"] - m["right"]) * (m["top"] - m["bottom"]))
        px = (m["left"] - y) / (m["left"] - m["right"]) * 100
        py = (m["top"] - x) / (m["top"] - m["bottom"]) * 100
        out[r["id"]] = (lados.get(plantilla.get(r["id"]), ""), m["ui_map"], round(px, 1), round(py, 1))
    return out


def rangos(db):
    out, npcs = {}, set()
    for prof, ids in RANGOS.items():
        fila = []
        for n, sp in enumerate(ids):
            nivel, costo, cnt = db.execute("select max(ReqLevel), max(MoneyCost), count(*) from trainer_spell where SpellId=?", (sp,)).fetchone()
            quien = [c for (c,) in db.execute("select distinct cr.CreatureID from trainer_spell ts join creature_trainer cr on cr.TrainerID=ts.TrainerId where ts.SpellId=?", (sp,))]
            npcs.update(quien)
            fila.append({"hechizo": sp, "tope": TOPES[n], "nivel": nivel or 0, "costo": costo or 0,
                         "instructor": bool(cnt), "quien": quien})
        out[prof] = fila
    equit = [c for (c,) in db.execute("select distinct cr.CreatureID from trainer_spell ts join creature_trainer cr on cr.TrainerID=ts.TrainerId where ts.SpellId=33388")]
    npcs.update(equit)
    return out, equit, lugares_npc(npcs)


CONOCIDAS = pathlib.Path(r"C:\Users\<usuario>\OneDrive\Escritorio\WOW_FOREVER\BUILDS_CONOCIDOS.md")
SECCION_CLASE = {"Guerrero": "WARRIOR", "Pícaro": "ROGUE", "Cazador": "HUNTER", "Mago": "MAGE", "Brujo": "WARLOCK",
                 "Sacerdote": "PRIEST", "Chamán": "SHAMAN", "Druida": "DRUID", "Paladín": "PALADIN"}


def conocidas():
    """Builds de autores con nombre, verificadas en su fuente (BUILDS_CONOCIDOS.md, 18-11). Solo hechos: uso, autor,
    reparto, talentos clave, enlace y fecha. El texto de las guías no se copia."""
    import re, html
    out, clase = [], None
    for l in CONOCIDAS.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^## (\S+)", l)
        if m:
            clase = SECCION_CLASE.get(m.group(1))
            continue
        if not clase or not l.startswith("|") or l.startswith("|---") or "Autor |" in l:
            continue
        c = [html.unescape(x.strip()) for x in l.strip().strip("|").split("|")]
        if len(c) < 7 or not re.match(r"^\d+/\d+/\d+$", c[3]):
            continue
        url = re.search(r"https?://\S+", c[5])
        url = url.group(0).rstrip(")") if url else ""
        if not url and out and out[-1]["autor"] == c[1]:
            url = out[-1]["url"]  # "misma guía" que la fila de arriba
        out.append({"clase": clase, "uso": c[0], "autor": c[1], "destaca": c[2], "reparto": c[3],
                    "clave": c[4], "url": url, "fecha": c[6]})
    return out


HOTFIX = pathlib.Path(r"D:\rust\polestar-data\sources\cliente-hotfix\ItemSparse.esMX.csv")
RIDING = {"148", "149", "150", "152", "533", "553", "554", "713", "762"}  # equitación de raza (Classic) y la de Forever


def monturas(db):
    """Monturas que se compran (clase 15, se venden, piden nivel 40 o 60): precio, nivel y quién las vende.
    El precio sale de las tablas CORREGIDAS de Forever (cliente-hotfix: el kodo gris cuesta 20 o) y si no, de Classic."""
    mont = set()
    for r in leer("Item.csv"):
        if r["ClassID"] == "15":
            mont.add(int(r["ID"]))
    precioF = {}
    if HOTFIX.exists():
        with open(HOTFIX, encoding="utf-8", newline="") as f:
            for r in csv.DictReader(f):
                if int(r["ID"]) in mont:
                    precioF[int(r["ID"])] = int(r["BuyPrice"] or 0)
    out = {}
    for r in leer("ItemSparse.csv", "esMX"):
        i = int(r["ID"])
        if i in mont and r.get("RequiredSkill") in RIDING and r.get("RequiredLevel") in ("40", "60"):
            vend = [c for (c,) in db.execute("select distinct entry from npc_vendor where item=?", (i,))]
            if vend:
                out[i] = {"nombre": r["Display_lang"], "precio": precioF.get(i, int(r["BuyPrice"] or 0)),
                          "forever": i in precioF, "nivel": int(r["RequiredLevel"] or 0), "quien": vend}
    return out


def main():
    db = sqlite3.connect(TDB)
    bc = conocidas()
    mo = monturas(db)
    b = bolsas(db)
    por, equit = dinero(db)
    rg, instEquit, lug = rangos(db)
    extra = set(n for d in mo.values() for n in d['quien']) - set(lug)
    lug.update(lugares_npc(extra))
    SALIDA.mkdir(parents=True, exist_ok=True)
    L = ["-- Generado por tools/asistente/plan/datos_plan.py. No editar: se rehace con ese script.",
         "-- Fuentes: tablas del cliente (wago.tools 1.15.9.70576, esMX: ItemSparse, Item, SpellEffect, SkillLineAbility)",
         "-- y ForeverTDB 2026-10-14 (npc_vendor, quest_template, trainer_spell): hechos, sin código. Licencia: GPL-3.0-only.",
         "local _, M = ...",
         "-- BOLSAS[id] = { nombre, casillas, familia, nivel, calidad, precio (cobre, vendedor), vendedores = n,",
         "--   fabrica = { profesión, habilidad, hechizo }, misiones = { ids } }",
         "M.BOLSAS = {"]
    for i in sorted(b):
        d = b[i]
        partes = [f"nombre = {lua_str(d['nombre'])}", f"casillas = {d['casillas']}", f"familia = {lua_str(d['familia'])}",
                  f"nivel = {d['nivel']}", f"calidad = {d['calidad']}", f"precio = {d['precio']}"]
        if d.get("vendedores"):
            partes.append(f"vendedores = {d['vendedores']}")
        if d.get("fabrica"):
            p, s, sp = d["fabrica"]
            partes.append(f"fabrica = {{ {lua_str(p)}, {s}, {sp} }}")
        if d.get("misiones"):
            partes.append("misiones = { " + ", ".join(map(str, sorted(d["misiones"])[:6])) + " }")
        L.append(f"\t[{i}] = {{ {', '.join(partes)} }},")
    L.append("}")
    L.append("-- ENTRENAR[clase][nivel] = cobre que cuesta todo lo nuevo de ese nivel en el instructor de clase (máximo:")
    L.append("-- incluye rangos que piden talento). EQUITACION = { [hechizo] = { nivel, cobre } } (sin la montura).")
    L.append("M.ENTRENAR = {")
    for cl in sorted(por):
        L.append(f"\t{cl} = {{ " + ", ".join(f"[{n}] = {c}" for n, c in sorted(por[cl].items())) + " },")
    L.append("}")
    L.append("M.EQUITACION = { " + ", ".join(f"[{sp}] = {{ {n}, {c} }}" for sp, (n, c) in sorted(equit.items())) + " }")
    L.append("-- RANGOS[profesión] = { { hechizo, tope, nivel, cobre, instructor = true|false (false: libro o misión),")
    L.append("--   quien = { npc } }, ... } en orden Aprendiz, Oficial, Experto, Artesano")
    L.append("M.RANGOS = {")
    for prof in RANGOS:
        partes = []
        for f in rg[prof]:
            q = "{ " + ", ".join(map(str, f["quien"][:8])) + " }"
            partes.append(f"{{ hechizo = {f['hechizo']}, tope = {f['tope']}, nivel = {f['nivel']}, costo = {f['costo']}, "
                          f"instructor = {'true' if f['instructor'] else 'false'}, quien = {q} }}")
        L.append(f"\t[{lua_str(prof)}] = {{ " + ", ".join(partes) + " },")
    L.append("}")
    L.append("M.INSTRUCTORES_EQUITACION = { " + ", ".join(map(str, instEquit)) + " }")
    L.append("-- CONOCIDAS = builds de autores con nombre (BUILDS_CONOCIDOS.md, verificadas el 18-11 en su fuente).")
    L.append("-- Ninguna viene de un ranking de daño real: Forever no tiene todavía (bandas el 9-12-2026).")
    L.append("M.CONOCIDAS = {")
    for bb in bc:
        L.append("\t{ " + ", ".join(f"{k} = {lua_str(bb[k])}" for k in ("clase", "uso", "autor", "destaca", "reparto", "clave", "url", "fecha")) + " },")
    L.append("}")
    L.append("-- MONTURAS[id] = { nombre, precio (cobre; forever = precio de las tablas corregidas de Forever), nivel, quien = { npc } }")
    L.append("M.MONTURAS = {")
    for i in sorted(mo):
        d = mo[i]
        L.append(f"\t[{i}] = {{ nombre = {lua_str(d['nombre'])}, precio = {d['precio']}, forever = {'true' if d['forever'] else 'false'}, "
                 f"nivel = {d['nivel']}, quien = {{ " + ", ".join(map(str, d["quien"][:6])) + " } },")
    L.append("}")
    L.append("-- LUGAR[npc] = { bando ('A', 'H', 'AH'), uiMap, x %, y % } (primera aparición; el nombre de la zona lo da el juego)")
    L.append("M.LUGAR = {")
    for n in sorted(lug):
        s, m, x, y = lug[n]
        L.append(f"\t[{n}] = {{ {lua_str(s)}, {m}, {x}, {y} }},")
    L.append("}")
    (SALIDA / "DatosPlan.lua").write_text("\n".join(L) + "\n", encoding="utf-8")
    fam = collections.Counter(d["familia"] for d in b.values())
    print(f"bolsas: {len(b)} ({dict(fam)}); clases con entrenamiento: {len(por)}; equitación: {equit}")


if __name__ == "__main__":
    main()
