"""¿Hay una versión nueva de Polestar, y cambió lo que nuestro addon usa de ella?

Uso:
  python -I polestar_al_dia.py            revisa (no cambia nada)
  python -I polestar_al_dia.py --fijar    guarda el contrato actual como el aceptado (después de probar)
  python -I polestar_al_dia.py --fork RUTA_REPO
      solo la versión: ¿hay una etiqueta vX.Y.Z publicada que la rama `asistente` del fork todavía no
      fusionó? Imprime "FUSIONAR vX.Y.Z" (sale 1), "AL DÍA vX.Y.Z" (sale 0) o el error (sale 2).
      La usa tools/asistente/seguir_polestar.sh (ARQUITECTURA §13f.7, M4). No cambia nada.

Qué compara (ARQUITECTURA.md §6 y §13):
  - la versión instalada (Polestar.toc) contra la última publicada en GitHub (fitzforge/polestar);
  - la huella sha256 de su contrato público en esa versión: docs/API.md (Polestar.API) y la sección
    "Nav API" de docs/ARCHITECTURE.md (Polestar.Nav.API), contra polestar_contrato.json;
  - el aviso de licencia (LICENSE, LICENSE-EXCEPTION.md, THIRD_PARTY.md): si cambia, hay que releerlo.
Salida: una línea por cosa, y código 0 = nada que hacer, 1 = hay algo que revisar, 2 = no se pudo revisar.
No baja ni instala nada: solo avisa. En el fork (ARQUITECTURA §13/§15) se actualiza FUSIONANDO la etiqueta nueva.
"""
import hashlib
import json
import pathlib
import re
import sys
import urllib.request

REPO = "fitzforge/polestar"
ADDONS = pathlib.Path(r"C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns")
FIJADO = pathlib.Path(__file__).parent / "polestar_contrato.json"
CABECERA = {"User-Agent": "asistente-addon-check"}  # cliente genérico, sin datos del usuario


def bajar(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=CABECERA), timeout=30) as r:
        return r.read().decode("utf-8")


def huella(texto):
    return "sha256:" + hashlib.sha256(texto.replace("\r\n", "\n").encode("utf-8")).hexdigest()


def seccion_nav_api(arquitectura):
    m = re.search(r"^### Nav API.*?(?=^### )", arquitectura, re.S | re.M)
    if not m:  # el título cambió o se movió: no fijar la huella de un texto vacío
        raise ValueError("no encuentro la sección 'Nav API' en docs/ARCHITECTURE.md")
    return m.group(0)


def ultima_version():
    # solo las versiones del addon ("v0.4.0"); el repositorio publica también client-v*, data-v*, lib-v*
    lista = json.loads(bajar(f"https://api.github.com/repos/{REPO}/releases?per_page=50"))
    tags = [r["tag_name"] for r in lista if re.match(r"^v\d", r["tag_name"]) and not r.get("draft") and not r.get("prerelease")]
    if not tags:
        raise ValueError("no hay versiones v* publicadas")
    return max(tags, key=lambda t: [int(x) for x in re.findall(r"\d+", t)])


def instalada():
    toc = ADDONS / "Polestar" / "Polestar.toc"
    if not toc.exists():
        return None
    m = re.search(r"^## Version:\s*(\S+)", toc.read_text(encoding="utf-8", errors="replace"), re.M)
    # el fork marca su versión como 0.4.0-asistente.N: se compara la versión base de Polestar
    return re.sub(r"-asistente.*$", "", m.group(1)) if m else None


def contrato(tag):
    raw = f"https://raw.githubusercontent.com/{REPO}/{tag}/"
    c = {
        "api": huella(bajar(raw + "docs/API.md")),
        "nav_api": huella(seccion_nav_api(bajar(raw + "docs/ARCHITECTURE.md"))),
        "licencia": huella(bajar(raw + "LICENSE") + bajar(raw + "LICENSE-EXCEPTION.md")),
        "terceros": huella(bajar(raw + "THIRD_PARTY.md")),
    }
    # Funciones y tablas INTERNAS de Polestar que usa un módulo nuestro (solo valen porque Mamba es el fork,
    # ARQUITECTURA §4 regla 2). Cualquier cambio en su texto (firma, cuerpo o contenido) = revisar ese módulo.
    fuentes = {}
    for archivo, prefijo, nombre, _modulo in INTERNAS:
        if archivo not in fuentes:
            fuentes[archivo] = bajar(raw + archivo)
        c[f"interna:{prefijo}.{nombre}"] = huella(cuerpo_definicion(fuentes[archivo], prefijo, nombre))
    for archivo in FORMATOS:
        c[f"formato:{archivo}"] = huella(cabecera_formato(bajar(raw + archivo)))
    return c


# (archivo del repositorio de Polestar, prefijo en ese archivo, nombre, módulo nuestro que la usa)
# Lista del módulo de equipo: E.CONTRATO en addon/Asistente_Equipo/Logica.lua. Mantener las dos iguales.
GEAR, WEIGHTS, ITEMDB = "addon/Polestar/Gear/Gear.lua", "addon/Polestar/Gear/Weights.lua", "addon/Polestar/Gear/ItemDB.lua"
INTERNAS = [(GEAR, "Gear", n, "Asistente_Equipo") for n in
            ["CompareToEquipped", "GetItemInfo", "ScoreWith", "WeightsFor", "GetSpec", "Usability", "GetPlayer", "GetWeights"]]
INTERNAS += [(WEIGHTS, "Gear", "CLASSES", "Asistente_Equipo"), (WEIGHTS, "Gear", "PROFICIENCY", "Asistente_Equipo")]
INTERNAS += [(ITEMDB, "DB", "Get", "Asistente_Equipo (Polestar.ItemDB.Get)"),
             (ITEMDB, "DB", "ItemName", "Asistente_Equipo (Polestar.ItemDB.ItemName)")]
# Regla de estética (WOW_FOREVER/ESTETICA_MAMBA.md): addon/Asistente/Estilo.lua dibuja con estas piezas de
# Polestar. Si cambian, revisar Estilo.lua y correr tests/mamba-estetica.test.js.
THEME, WIDGETS, INIT = "addon/Polestar/Theme/Theme.lua", "addon/Polestar/Theme/Widgets.lua", "addon/Polestar/Core/Init.lua"
ESTILO = "Asistente/Estilo.lua (estética)"
INTERNAS += [(THEME, "Theme", n, ESTILO) for n in ["Skin", "Band", "BandCoords", "Hex"]]
INTERNAS += [(WIDGETS, "W", n, ESTILO) for n in ["Text", "IconButton", "FrameClose", "SearchBox", "Hover", "Rim", "Haze"]]
INTERNAS += [(WIDGETS, "ns", "RegisterOptions", ESTILO), (INIT, "ns", "DragWindow", ESTILO), (INIT, "ns", "CloseOnEscape", ESTILO)]
# archivos de datos cuyo FORMATO de entrada leemos (las líneas "-- Entry:" de su cabecera)
FORMATOS = ["addon/Polestar_ItemDB/Items.lua", "addon/Polestar_ItemDB/Forever.lua"]  # los lee generador/equipo.py


def cuerpo_definicion(fuente, prefijo, nombre):
    """Texto de <prefijo>.<nombre>: `function P.X(` / `P.X = local` + `local function local(` hasta el `end`
    de columna 0, o una tabla `P.X = {` hasta su `}` de columna 0."""
    lineas = fuente.replace(chr(13) + chr(10), chr(10)).split(chr(10))
    p, n = re.escape(prefijo), re.escape(nombre)
    inicio, fin = None, "end"
    for l in lineas:
        m = re.match(rf"^{p}\.{n}\s*=\s*([A-Za-z_]\w*)\s*$", l)
        if m:
            inicio = rf"^local function {re.escape(m.group(1))}\("
            break
    if inicio is None:
        if any(re.match(rf"^{p}\.{n}\s*=\s*\{{", l) for l in lineas):
            inicio, fin = rf"^{p}\.{n}\s*=\s*\{{", "}"
        else:
            inicio = rf"^function {p}\.{n}\("
    for i, l in enumerate(lineas):
        if re.match(inicio, l):
            for k in range(i + 1, len(lineas)):
                if lineas[k] == fin:
                    return "\n".join(lineas[i:k + 1])
    raise ValueError(f"no encuentro {prefijo}.{nombre} en Polestar: ¿la quitaron o la renombraron?")


def cabecera_formato(fuente):
    cab = [l for l in fuente.split("\n")[:40] if l.startswith("--")]
    # solo las líneas que describen el FORMATO (no "Generated by ...", que cambia con cada versión de los datos)
    texto = "\n".join(l for l in cab if re.match(r"^--\s+(Entry|items|src|quests|\[)", l) or "mpr" in l)
    if not texto:
        raise ValueError("no encuentro la descripción de formato (-- Entry:) en el ItemDB")
    return texto


QUE = {
    "api": "Polestar.API (docs/API.md): orden del registro, guías propias",
    "nav_api": "Polestar.Nav.API (flecha y viajes): buscador de servicios",
    "licencia": "LICENSE / LICENSE-EXCEPTION.md: releer antes de compartir",
    "terceros": "THIRD_PARTY.md (qué datos trae y con qué permiso): releer antes de compartir",
}
for _a, _p, _n, _m in INTERNAS:
    QUE[f"interna:{_p}.{_n}"] = f"{_p}.{_n} ({_a.split('/')[-1]}, interna de Polestar): revisar {_m}"
for _f in FORMATOS:
    QUE[f"formato:{_f}"] = f"formato de {_f}: revisar el generador de Asistente_Equipo (generador/equipo.py)"


def numeros(tag):
    return [int(x) for x in re.findall(r"\d+", tag)]


def fusionada(repo):
    """Última etiqueta de Polestar (v*) que ya está dentro de la rama asistente del fork."""
    import subprocess
    r = subprocess.run(["git", "-C", str(repo), "describe", "--tags", "--abbrev=0", "--match", "v*", "asistente"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise ValueError("git describe falló en " + str(repo) + ": " + r.stderr.strip())
    return re.sub(r"-asistente.*$", "", r.stdout.strip())


def main_fork(repo):
    try:
        ultima, base = ultima_version(), fusionada(repo)
    except Exception as e:  # sin internet, GitHub caído, repositorio movido
        print("NO SE PUDO REVISAR:", e)
        return 2
    if numeros(ultima) > numeros(base):
        print(f"FUSIONAR {ultima} (Mamba está sobre {base})")
        return 1
    print(f"AL DÍA {base} (última publicada: {ultima})")
    return 0


def main(argv):
    sys.stdout.reconfigure(encoding="utf-8")
    if "--fork" in argv:
        return main_fork(pathlib.Path(argv[argv.index("--fork") + 1]))
    try:
        ultima = ultima_version()
        actual = contrato(ultima)
    except Exception as e:  # sin internet, GitHub caído, archivo movido
        print("NO SE PUDO REVISAR:", e)
        return 2
    inst = instalada()
    print(f"Polestar instalada: {inst or 'no encontrada'} · última publicada: {ultima}")
    if not inst:
        print("  Polestar NO está instalado (o se movió su carpeta): revisar antes de seguir.")
    if "--fijar" in argv:
        if not inst or inst.lstrip("v") != ultima.lstrip("v"):
            print("No fijo: la versión instalada no es la última publicada. Instalar y probar", ultima, "primero.")
            return 1
        FIJADO.write_text(json.dumps({"version": ultima, **actual}, indent=2), encoding="utf-8")
        print("Contrato fijado:", FIJADO.name)
        return 0
    if not FIJADO.exists():
        print("Todavía no hay contrato fijado: correr con --fijar después de probar el addon con", ultima)
        return 1
    fijo = json.loads(FIJADO.read_text(encoding="utf-8"))
    revisar = not inst
    for k, txt in QUE.items():
        igual = fijo.get(k) == actual[k]
        revisar |= not igual
        print(("  igual    " if igual else "  CAMBIÓ   ") + txt)
    if inst and inst.lstrip("v") != ultima.lstrip("v"):
        print(f"  Hay versión nueva ({ultima}). En el fork: fusionar {ultima} en la rama asistente (ARQUITECTURA §15, 13f.3).")
        revisar = True
    print("Siguiente paso:", "correr las pruebas del addon y probar en el juego; luego --fijar" if revisar else "nada")
    return 1 if revisar else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
