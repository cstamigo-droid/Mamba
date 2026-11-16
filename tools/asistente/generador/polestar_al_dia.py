"""¿Hay una versión nueva de Polestar, y cambió lo que nuestro addon usa de ella?

Uso:
  python -I polestar_al_dia.py            revisa (no cambia nada)
  python -I polestar_al_dia.py --fijar    guarda el contrato actual como el aceptado (después de probar)

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
    return {
        "api": huella(bajar(raw + "docs/API.md")),
        "nav_api": huella(seccion_nav_api(bajar(raw + "docs/ARCHITECTURE.md"))),
        "licencia": huella(bajar(raw + "LICENSE") + bajar(raw + "LICENSE-EXCEPTION.md")),
        "terceros": huella(bajar(raw + "THIRD_PARTY.md")),
    }


QUE = {
    "api": "Polestar.API (docs/API.md): orden del registro, guías propias",
    "nav_api": "Polestar.Nav.API (flecha y viajes): buscador de servicios",
    "licencia": "LICENSE / LICENSE-EXCEPTION.md: releer antes de compartir",
    "terceros": "THIRD_PARTY.md (qué datos trae y con qué permiso): releer antes de compartir",
}


def main(argv):
    sys.stdout.reconfigure(encoding="utf-8")
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
