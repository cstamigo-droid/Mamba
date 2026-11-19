"""Genera addon/Tasador/Mecanicas.lua: los objetos que el Tasador NUNCA recomienda vender ni marcar como basura
(fila K115, 18-11: recomendaba vender el saco de dormir, una mecánica de Forever).

Fuente: ForeverTDB 2026-10-14 (D:/rust/forever-tdb/world.sqlite, tabla armory_item, armada con tdb_a_sqlite.py).
Regla: clase 15 (Miscelánea) con un efecto de USO ("0:<hechizo>:...") que está ligado al recogerlo (bonding 1)
o es de misión (bonding 4), o que no tiene precio de venta. Son cosas que el jugador USA (saco de dormir, ecos,
apuntes de hechizos, letreros y certificados de profesión, llaves, monturas y mascotas ligadas...).
Uso: python -I tools/asistente/tasador_mecanicas.py [world.sqlite]
"""
import datetime as dt
import pathlib
import sqlite3
import sys

RAIZ = pathlib.Path(__file__).resolve().parents[2]
DB = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else r"D:\rust\forever-tdb\world.sqlite")
SALIDA = RAIZ / "addon" / "Tasador" / "Mecanicas.lua"

c = sqlite3.connect(DB)
filas = c.execute(
    "select id, name, bonding, sellPrice from armory_item "
    "where class = 15 and effects like '0:%' and (bonding in (1, 4) or sellPrice = 0) order by id").fetchall()
lineas = [
    "-- Generado por tools/asistente/tasador_mecanicas.py; no editar a mano.",
    f"-- Objetos que se USAN y que el Tasador nunca recomienda vender ni botar (K115), de ForeverTDB 2026-10-14",
    "-- (armory_item: clase 15 con efecto de uso, ligados al recogerlo o de misión, o sin precio de venta).",
    "-- Licencia: GPL-3.0-only.",
    "local _, T = ...",
    "T.MECANICAS = {",
]
for i, n, b, p in filas:
    lineas.append(f"\t[{i}] = true, -- {n.replace(chr(10), ' ')}")
lineas.append("}")
SALIDA.write_text("\n".join(lineas) + "\n", encoding="utf-8", newline="\n")
print(f"{len(filas)} objetos -> {SALIDA}")
