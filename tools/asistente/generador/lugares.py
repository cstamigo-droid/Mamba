"""Genera addon/Asistente/Lugares.lua: los lugares que «Ir a…» busca y que no están en otro lado (fila K118).

1) Subzonas y poblados ("Poblado Magram", "El Cruce"): cada AreaTable que el mapa del mundo del cliente dibuja como
   una zona descubrible (WorldMapOverlay), con su mapa (UiMapXMapArt) y el centro de su rectángulo de clic
   (HitRect; si no hay, el de su textura) en % de un mapa de 1002 x 668, como lo dibuja el juego. Nombres: AreaTable
   en inglés y en esMX (wago.tools, tablas del cliente WoW Forever).
2) Recompensas de misión que el Codex no trae como fuente ("Gran bastón de los necrokhans", recompensa a elegir de
   «Khan Jehn»): objeto -> misión, leídas de las metas `turnin` de las guías de Polestar (rewards.choices / items).

Uso (desde el repositorio Mamba):  python -I tools/asistente/generador/lugares.py
Licencia: GPL-3.0-only. Datos: tablas del cliente (Blizzard) vía wago.tools; guías de Polestar (GPL-3.0).
"""
from __future__ import annotations

import csv
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parents[3]
WAGO = RAIZ / "data" / "sources" / "wago"
WAGO_ES = pathlib.Path(r"D:\rust\polestar-data\sources\wago")
SALIDA = RAIZ / "addon" / "Asistente" / "Lugares.lua"
ANCHO, ALTO = 1002.0, 668.0


def tabla(nombre: str, es: bool = False) -> list[dict]:
    """La copia más nueva de una tabla del cliente 1.60.1 (esMX: la de polestar-data, si está; si no, la del repo)."""
    candidatos = []
    if es:
        candidatos += sorted(WAGO_ES.glob(f"1.60.1.*/esMX/{nombre}.csv")) + sorted(WAGO.glob(f"1.60.1.*/esMX/{nombre}.csv"))
    else:
        candidatos += sorted(WAGO.glob(f"1.60.1.*/{nombre}.csv"))
    if not candidatos:
        raise SystemExit(f"falta la tabla {nombre}{' (esMX)' if es else ''} en {WAGO}")
    with candidatos[-1].open(encoding="utf-8", newline="") as h:
        return list(csv.DictReader(h))


def lua_txt(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def subzonas() -> list[tuple]:
    en = {int(r["ID"]): r for r in tabla("AreaTable")}
    es = {int(r["ID"]): r["AreaName_lang"] for r in tabla("AreaTable", es=True)}
    arte = {}
    for r in tabla("UiMapXMapArt"):
        if r["PhaseID"] in ("0", ""):
            arte.setdefault(int(r["UiMapArtID"]), int(r["UiMapID"]))
    tipo = {int(r["ID"]): int(r["Type"]) for r in tabla("UiMap")}
    out, vistos = [], set()
    for r in tabla("WorldMapOverlay"):
        mapa = arte.get(int(r["UiMapArtID"]))
        if not mapa or tipo.get(mapa) != 3:  # solo mapas de zona (Enum.UIMapType.Zone)
            continue
        top, bottom, left, right = (float(r[k]) for k in ("HitRectTop", "HitRectBottom", "HitRectLeft", "HitRectRight"))
        if right > left and bottom > top:
            cx, cy = (left + right) / 2, (top + bottom) / 2
        else:
            cx = float(r["OffsetX"]) + float(r["TextureWidth"]) / 2
            cy = float(r["OffsetY"]) + float(r["TextureHeight"]) / 2
        for k in ("AreaID_0", "AreaID_1", "AreaID_2", "AreaID_3"):
            a = int(r[k] or 0)
            if not a or (a, mapa) in vistos or a not in en:
                continue
            vistos.add((a, mapa))
            nombre_en = en[a]["AreaName_lang"]
            out.append((a, mapa, round(cx / ANCHO * 100, 1), round(cy / ALTO * 100, 1), es.get(a) or nombre_en, nombre_en))
            break  # el primer área del dibujo es la que nombra (las otras son partes)
    out.sort()
    return out


def recompensas() -> dict[int, tuple[int, int]]:
    """objeto -> (misión, área), de las metas turnin de Polestar_Guides con rewards. El área: el {area:N} que nombra
    la nota más cercana antes de la meta ("una tienda junto al lago en medio de {area:604}"); 0 si no hay."""
    txt = (RAIZ / "addon" / "Polestar_Guides" / "Guides.lua").read_text(encoding="utf-8")
    out: dict[int, tuple[int, int]] = {}
    for m in re.finditer(r't = "turnin", quest = (\d+)[^\n]*?rewards = \{(.*?)\} \}', txt):
        q = int(m[1])
        area = 0
        for nota in reversed(re.findall(r'note = "([^"\n]*)"', txt[max(0, m.start() - 3000):m.end()])):
            a = re.search(r"\{area:(\d+)\}", nota)
            if a:
                area = int(a[1])
                break
        for item in re.findall(r"item = (\d+)", m[2]):
            out.setdefault(int(item), (q, area))
    return out


def main() -> int:
    sz = subzonas()
    rc = recompensas()
    lineas = [
        "-- Generado por tools/asistente/generador/lugares.py. NO editar a mano: volver a generar.",
        "-- Subzonas: tablas del cliente WoW Forever (WorldMapOverlay, UiMapXMapArt, UiMap, AreaTable enUS y esMX; Blizzard,",
        "-- vía wago.tools). Recompensas: metas turnin de las guías de Polestar (GPL-3.0). Fila K118 de MAMBA_ACEPTACION.",
        "-- areas: { areaID, uiMap, x %, y %, nombre esMX, nombre enUS }  ·  recompensas: [objeto] = { misión, área donde se entrega (0: no se sabe) }",
        "Asistente_Lugares = {",
        "\tareas = {",
    ]
    for a, mapa, x, y, nes, nen in sz:
        lineas.append(f"\t\t{{ {a}, {mapa}, {x}, {y}, {lua_txt(nes)}, {lua_txt(nen)} }},")
    lineas += ["\t},", "\trecompensas = {"]
    for item in sorted(rc):
        q, area = rc[item]
        lineas.append(f"\t\t[{item}] = {{ {q}, {area} }},")
    lineas += ["\t},", "}", ""]
    SALIDA.write_text("\n".join(lineas), encoding="utf-8", newline="\n")
    print(f"{SALIDA.relative_to(RAIZ)}: {len(sz)} subzonas, {len(rc)} recompensas")
    return 0


if __name__ == "__main__":
    sys.exit(main())
