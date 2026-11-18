"""Textos de guía en esMX que quedaron "" después de `forge i18n guides sync esMX` (18-11).

Las guías de la ruta de Mamba se reescribieron (forge build) y casi la mitad de sus textos del tramo
37-60 Horda quedó sin traducción (revisión wow-experiencia). Cristian no habla inglés.

    python -I tools/asistente/traducir_guias.py exportar <locales/esMX> <pendientes.json> [carpeta ...]
        1) llena cada "" cuyo inglés ya está traducido en OTRA guía (misma clave exacta);
        2) escribe los que siguen vacíos: {"inglés": "contexto (nombres de los {kind:id})"}.
    python -I tools/asistente/traducir_guias.py importar <locales/esMX> <traducidos.json>
        llena cada "" con la traducción del JSON ({"inglés": "español"}), si conserva los mismos
        {kind:id} que el inglés; si no, la deja vacía y lo dice.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

LINEA = re.compile(r'^(\t\[)("(?:[^"\\]|\\.)*")(\] = )("(?:[^"\\]|\\.)*")(,\s*)$')
TOKEN = re.compile(r"\{[a-z]+:\d+\}")


def _lua_str(s: str) -> str:
    return json.loads(s)  # las cadenas de sync usan escapes compatibles con JSON (\" \\ \n)


def _a_lua(s: str) -> str:
    return json.dumps(s, ensure_ascii=False)


def _archivos(raiz: Path, carpetas: list[str]):
    if not carpetas:
        yield from raiz.rglob("*.lua")
        return
    for c in carpetas:
        yield from (raiz / c).glob("*.lua")


def exportar(raiz: Path, salida: Path, carpetas: list[str]) -> int:
    hechas: dict[str, str] = {}
    for f in raiz.rglob("*.lua"):
        for l in f.read_text(encoding="utf-8").splitlines():
            m = LINEA.match(l)
            if m and m[4] != '""':
                hechas.setdefault(_lua_str(m[2]), _lua_str(m[4]))
    pend: dict[str, str] = {}
    reus = 0
    for f in _archivos(raiz, carpetas):
        lineas = f.read_text(encoding="utf-8").split("\n")
        cambio = False
        for i, l in enumerate(lineas):
            m = LINEA.match(l)
            if not m or m[4] != '""':
                continue
            en = _lua_str(m[2])
            if en in hechas:
                lineas[i] = f"{m[1]}{m[2]}{m[3]}{_a_lua(hechas[en])}{m[5]}"
                cambio = True
                reus += 1
                continue
            ctx = lineas[i - 1].strip() if i and lineas[i - 1].strip().startswith("--") else ""
            pend.setdefault(en, ctx)
        if cambio:
            f.write_text("\n".join(lineas), encoding="utf-8", newline="\n")
    salida.write_text(json.dumps(pend, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"reutilizadas: {reus}; por traducir (únicas): {len(pend)} -> {salida}")
    return 0


def importar(raiz: Path, entrada: Path) -> int:
    tr = json.loads(entrada.read_text(encoding="utf-8"))
    n = malas = 0
    for f in raiz.rglob("*.lua"):
        lineas = f.read_text(encoding="utf-8").split("\n")
        cambio = False
        for i, l in enumerate(lineas):
            m = LINEA.match(l)
            if not m or m[4] != '""':
                continue
            en = _lua_str(m[2])
            es = (tr.get(en) or "").strip()
            if not es:
                continue
            if sorted(TOKEN.findall(en)) != sorted(TOKEN.findall(es)):
                malas += 1
                print(f"tokens distintos, se deja en inglés: {f.name}: {en[:70]}")
                continue
            lineas[i] = f"{m[1]}{m[2]}{m[3]}{_a_lua(es)}{m[5]}"
            cambio = True
            n += 1
        if cambio:
            f.write_text("\n".join(lineas), encoding="utf-8", newline="\n")
    print(f"importadas: {n}; rechazadas por tokens: {malas}")
    return 0


def desde_otro(origen: Path, destino: Path) -> int:
    """Llena los "" de `destino` (p. ej. esES) con las traducciones de `origen` (p. ej. esMX) del mismo
    inglés: mejor español de otra variante que inglés para quien no lo habla (18-11)."""
    tr: dict[str, str] = {}
    for f in origen.rglob("*.lua"):
        for l in f.read_text(encoding="utf-8").splitlines():
            m = LINEA.match(l)
            if m and m[4] != '""':
                tr.setdefault(_lua_str(m[2]), _lua_str(m[4]))
    tmp = destino.parent / "_desde_otro.json"
    tmp.write_text(json.dumps(tr, ensure_ascii=False), encoding="utf-8")
    r = importar(destino, tmp)
    tmp.unlink()
    return r


def main(a: list[str]) -> int:
    if len(a) == 3 and a[0] == "desde":
        return desde_otro(Path(a[1]), Path(a[2]))
    if len(a) >= 3 and a[0] == "exportar":
        return exportar(Path(a[1]), Path(a[2]), a[3:])
    if len(a) == 3 and a[0] == "importar":
        return importar(Path(a[1]), Path(a[2]))
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
