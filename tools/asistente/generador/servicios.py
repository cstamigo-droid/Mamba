"""Genera los datos del buscador de servicios (módulo Asistente_Servicios) desde forever-db.

Uso:  python -I servicios.py _descargas/polestar ../addon/Asistente_Servicios

Para cada ciudad: cada PNJ de servicio (banco, subasta, posada, vuelo, establos, reparar,
instructores, vendedores...) y cada buzón, con su posición en el mundo (yardas) y en el mapa (%).
La categoría sale del TÍTULO del PNJ (forever-db no trae las banderas de servicio). "Reparar"
se deduce del título y queda marcado como "sin verificar" (conf = "titulo").
"""
import json
import math
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from generador import cargar_forever_db, a_lua, ErrorFuente  # noqa: E402  (reusa la huella sha256 y la licencia)

# uiMap de la ciudad -> nombre en español (el juego da el suyo con C_Map.GetMapInfo)
CIUDADES = {1454: "Orgrimmar", 1456: "Cima del Trueno", 1458: "Entrañas"}
JUNTAR_NPC = 15.0     # yardas: dos apariciones del mismo PNJ a menos de esto son el mismo lugar
JUNTAR_BUZON = 15.0   # yardas: buzones repetidos (capas) a menos de esto son uno solo

CLASES = {"Druid": "DRUID", "Hunter": "HUNTER", "Mage": "MAGE", "Paladin": "PALADIN", "Priest": "PRIEST",
          "Rogue": "ROGUE", "Shaman": "SHAMAN", "Warlock": "WARLOCK", "Warrior": "WARRIOR"}
# palabra del título -> (clave, id de habilidad del juego)
PROFES = {
    "Alchemy": ("alquimia", 171), "Alchemist": ("alquimia", 171),
    "Blacksmith": ("herreria", 164), "Blacksmithing": ("herreria", 164),
    "Armorsmith": ("herreria", 164), "Weaponsmith": ("herreria", 164),
    "Enchanter": ("encantamiento", 333), "Enchanting": ("encantamiento", 333),
    "Engineer": ("ingenieria", 202), "Engineering": ("ingenieria", 202),
    "Herbalism": ("herboristeria", 182), "Mining": ("mineria", 186), "Skinning": ("desuello", 393),
    "Leatherworker": ("peleteria", 165), "Leatherworking": ("peleteria", 165),
    "Tailor": ("sastreria", 197), "Tailoring": ("sastreria", 197),
    "Cooking": ("cocina", 185), "First Aid": ("primeros_auxilios", 129), "Fishing": ("pesca", 356),
}
RX_CLASE = re.compile(r"^(%s) Trainer$" % "|".join(CLASES))
RX_PROFE = re.compile(r"^(?:(?:Journeyman|Expert|Artisan|Master) )?(%s)(?: Trainer)?$" % "|".join(sorted(PROFES, key=len, reverse=True)))
RX_VUELO = re.compile(r"^(Wind Rider Master|Flight Master|Gryphon Master|Bat Handler|Hippogryph Master)$")
RX_REPARA = re.compile(r"(Armor|Weapon|Blacksmith|Mace|Staff|Staves|Sword|Axe|Blade|Two.Handed|Bow|Gun).*(Merchant|Vendor|Supplies|Supplier)"
                       r"|^(Armorer|Weaponsmith)$")
VENDE = [  # (regex sobre el título, clase de vendedor)
    (r"Reagent", "reactivos"), (r"Poison", "venenos"), (r"Bag Vendor", "bolsas"),
    (r"Meat|Bread|Fruit|Mushroom|Food|Drink|Cheese|Baker", "comida"),
    (r"General Goods", "general"), (r"Trade Goods|Trade Supplies", "comercio"),
    (r"Recipe", "recetas"), (r"Fishing Suppl", "pesca"),
    (r"Ammo|Guns|Bow|Fletching|Arrow", "municion"),
    (r"Armor", "armaduras"), (r"Weapon|Mace|Staff|Staves|Sword|Axe|Blade|Two.Handed|Wand", "armas"),
    (r"Suppl", "suministros"), (r"Tabard", "tabardos"),
]
OTROS = [
    (r"^Guild Master$", "hermandad"), (r"^Weapon Master$", "maestro_armas"), (r"Zeppelin Master", "zepelin"),
    (r"Battlemaster$", "campo_batalla"), (r"Riding Instructor$", "monta"), (r"^Pet Trainer$", "mascotas"),
    (r"^Portal Trainer$", "portales"), (r"^Demon Trainer$", "demonios"), (r"^Barber$", "barbero"),
]


def clasificar(npc):
    """-> (categoria, detalle, confianza) o None. Confianza: 'fdb' = título claro; 'titulo' = deducido."""
    nombre, t = npc.get("name", ""), npc.get("subname")
    if t is None:
        if nombre.startswith("Auctioneer ") and nombre != "Test Auctioneer":
            return ("subasta", None, "fdb")
        return None
    if t == "Banker":
        return ("banco", None, "fdb")
    if t == "Innkeeper":
        return ("posada", None, "fdb")
    if RX_VUELO.match(t):
        return ("vuelo", None, "fdb")
    if t == "Stable Master":
        return ("establo", None, "fdb")
    m = RX_CLASE.match(t)
    if m:
        return ("clase", CLASES[m.group(1)], "fdb")
    m = RX_PROFE.match(t)
    if m:
        return ("profesion", PROFES[m.group(1)][0], "fdb")
    for rx, det in OTROS:
        if re.search(rx, t):
            return ("otros", det, "fdb")
    if re.search(r"Merchant|Vendor|Supplies|Supplier|Goods", t):
        for rx, det in VENDE:
            if re.search(rx, t):
                return ("vendedor", det, "fdb")
        return ("vendedor", "otros", "fdb")
    return None


def juntar(puntos, radio):
    """Agrupa puntos (x, y, z) a menos de `radio` yardas; devuelve el centro de cada grupo."""
    grupos = []
    for p in puntos:
        for g in grupos:
            cx, cy = g["sx"] / g["n"], g["sy"] / g["n"]
            if math.hypot(p[0] - cx, p[1] - cy) <= radio:
                g["sx"] += p[0]; g["sy"] += p[1]; g["n"] += 1
                if p[2] is not None:
                    g["z"].append(p[2])
                break
        else:
            grupos.append({"sx": p[0], "sy": p[1], "n": 1, "z": [p[2]] if p[2] is not None else []})
    out = []
    for g in grupos:
        z = sorted(g["z"])[len(g["z"]) // 2] if g["z"] else None
        out.append((round(g["sx"] / g["n"], 1), round(g["sy"] / g["n"], 1), z))
    return out


def pct(um, x, y):
    """Mundo (x norte, y oeste) -> % del mapa (px izquierda->derecha, py arriba->abajo)."""
    px = (y - um["left"]) / (um["right"] - um["left"]) * 100
    py = (x - um["top"]) / (um["bottom"] - um["top"]) * 100
    return round(px, 2), round(py, 2)


def construir(raiz):
    t = cargar_forever_db(raiz)
    uimaps = {u["ui_map"]: u for u in t["ui_map"]}
    npc = {n["id"]: n for n in t["npc"]}
    buzones = {o["id"] for o in t["object"] if o.get("name") == "Mailbox"}
    ciudades = {}
    for um_id, nombre in CIUDADES.items():
        um = uimaps.get(um_id)
        if um is None:
            raise ErrorFuente(f"forever-db ya no trae el mapa {um_id} ({nombre})")
        dentro = lambda s: (s["map"] == um["map"] and 0 <= pct(um, s["x"], s["y"])[0] <= 100
                            and 0 <= pct(um, s["x"], s["y"])[1] <= 100)
        por_npc, por_buzon = {}, {}
        for s in t["spawn"]:
            if not dentro(s):
                continue
            if s["kind"] == "npc":
                n = npc.get(s["id"])
                if n and "faction_template" in n:   # sin facción = PNJ de prueba o sin datos
                    por_npc.setdefault(s["id"], []).append((s["x"], s["y"], s.get("z")))
            elif s["id"] in buzones:
                por_buzon.setdefault(0, []).append((s["x"], s["y"], s.get("z")))
        lugares = []
        for nid in sorted(por_npc):
            c = clasificar(npc[nid])
            if c is None:
                continue
            cat, det, conf = c
            for x, y, z in juntar(por_npc[nid], JUNTAR_NPC):
                px, py = pct(um, x, y)
                fila = {"id": nid, "nombre": npc[nid]["name"], "titulo": npc[nid].get("subname"),
                        "cat": cat, "det": det, "conf": conf, "x": x, "y": y, "z": z, "px": px, "py": py}
                lugares.append(fila)
                # Reparar: un vendedor de armas/armaduras/herrería suele reparar (no viene en los datos).
                if cat == "vendedor" and RX_REPARA.search(npc[nid].get("subname") or ""):
                    lugares.append(dict(fila, cat="reparar", det=None, conf="titulo"))
        for x, y, z in juntar(por_buzon.get(0, []), JUNTAR_BUZON):
            px, py = pct(um, x, y)
            lugares.append({"id": 0, "nombre": "Mailbox", "cat": "buzon", "conf": "fdb",
                            "x": x, "y": y, "z": z, "px": px, "py": py})
        lugares.sort(key=lambda l: (l["cat"], l.get("det") or "", l["nombre"], l["x"]))
        ciudades[um_id] = {"nombre": nombre, "mapa": um["map"], "lugares": lugares}
    return t["_indice"], ciudades


def escribir(indice, ciudades, carpeta, raiz):
    carpeta = pathlib.Path(carpeta)
    carpeta.mkdir(parents=True, exist_ok=True)
    datos = {"version": indice["version"], "build": indice["clientBuild"], "ciudades": {}}
    for um, c in ciudades.items():
        datos["ciudades"][um] = {"nombre": c["nombre"], "mapa": c["mapa"],
                                 "lugares": [{k: v for k, v in l.items() if v is not None} for l in c["lugares"]]}
    cab = ("-- Generado por WOW_FOREVER/generador/servicios.py. NO editar a mano: volver a generar.\n"
           f"-- Datos: forever-db {indice['version']} (Polestar, GPL-3.0-only), build {indice['clientBuild']}.\n"
           "-- Ver NOTICE-forever-db.md (créditos y aviso MIT de pfQuest). Nombres y títulos: de Blizzard.\n")
    (carpeta / "Ciudades.lua").write_text(cab + "Asistente_ServiciosDatos = " + a_lua(datos) + "\n", encoding="utf-8")
    fdb = pathlib.Path(raiz) / "forever-db"
    (carpeta / "NOTICE-forever-db.md").write_text((fdb / "NOTICE.md").read_text(encoding="utf-8"), encoding="utf-8")


def main(argv):
    raiz, salida = argv[1], argv[2]
    indice, ciudades = construir(raiz)
    escribir(indice, ciudades, salida, raiz)
    for um, c in ciudades.items():
        cuenta = {}
        for l in c["lugares"]:
            cuenta[l["cat"]] = cuenta.get(l["cat"], 0) + 1
        print(um, c["nombre"], len(c["lugares"]), dict(sorted(cuenta.items())))
    return indice, ciudades


if __name__ == "__main__":
    main(sys.argv)
