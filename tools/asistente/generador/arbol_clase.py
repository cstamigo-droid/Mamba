"""K109: el dibujo de los árboles de talentos de las 9 clases, para el planificador de Mamba (Clase › Talentos y
la entrada «Talentos» del riel).

Fuentes:
  - el árbol (fila, columna, rangos, puntos que pide y flechas) de ForeverDB, la MISMA versión que las builds de
    Datos_Builds.lua (1.60.1.70938): WOW_FOREVER/generador/_descargas/foreverdb/Talents.lua (lo baja
    builds_clase.py; GPL-3.0 con término de crédito);
  - el hechizo de cada talento (para su ícono y su texto en el idioma del juego) de addon/Polestar/Talents/Builds.lua
    (GPL-3.0-only), por el número de nodo. Los talentos nuevos que Polestar no tiene van con hechizo 0: el juego
    lo da por su entrada (C_Traits), al menos para la clase del jugador.
Escribe addon/Asistente_Clase/Datos_Arbol.lua:
  nodos[id] = { hechizo, árbol (1-3), fila, columna, rangos, entrada, nombre en inglés }
  pide[id]  = puntos en ese árbol que hacen falta para abrirlo
  flechas   = { {desde, hasta}, ... }
Hace falta aparte porque Polestar, en el juego, solo guarda la clase del jugador; el planificador deja mirar
cualquier clase ("si me hago un paladín, ¿tendré guía?").

    python -I tools/asistente/generador/arbol_clase.py [--comprobar]

--comprobar: no escribe; sale con 1 si el archivo no es el que saldría.
Licencia: GPL-3.0-only.
"""
from __future__ import annotations

import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime

RAIZ = Path(__file__).resolve().parents[3]
POLESTAR = RAIZ / "addon" / "Polestar" / "Talents" / "Builds.lua"
FOREVERDB = Path.home() / "OneDrive" / "Escritorio" / "WOW_FOREVER" / "generador" / "_descargas" / "foreverdb" / "Talents.lua"
SALIDA = RAIZ / "addon" / "Asistente_Clase" / "Datos_Arbol.lua"


def leer():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute("""
    ARBOLES = {}
    NS = { Talents = { Register = function(d) ARBOLES[#ARBOLES + 1] = d end },
           L = setmetatable({}, { __index = function(_, k) return k end }) }
    """)
    cargar = L.eval('function(src, n) local f, e = loadstring(src, "@" .. n); if not f then error(e) end; f("x", NS) end')
    cargar(POLESTAR.read_text(encoding="utf-8"), "Builds.lua")
    hechizos = {}
    for d in L.globals().ARBOLES.values():
        for nid, n in d.nodes.items():
            hechizos[int(nid)] = int(n[3])
    cargar(FOREVERDB.read_text(encoding="utf-8"), "Talents.lua")
    out = {}
    for clase, arboles in L.globals().NS.talentTrees.items():
        nodos, pide, flechas, specs = {}, {}, [], []
        for s, arbol in sorted(arboles.items()):
            specs.append(str(arbol.name))
            lista = [arbol.talents[i] for i in range(1, len(arbol.talents) + 1)]
            for t in lista:
                nombre, fila, col, rangos, nodo, entrada, puntos = (str(t[1]), int(t[2]), int(t[3]), int(t[4]),
                                                                    int(t[5]), int(t[6]), int(t[7]))
                nodos[nodo] = (hechizos.get(nodo, 0), int(s), fila + 1, col + 1, rangos, entrada, nombre)
                if puntos > 0:
                    pide[nodo] = puntos
                for i in list(t[9].values()) + list(t[10].values()):
                    padre = lista[int(i) - 1]
                    # una flecha siempre baja: ForeverDB da a Intimidación (cazador, fila 5) como padre a Cólera de
                    # las bestias (fila 7); dibujada sería una raya hacia arriba y «abre Intimidación» sería falso
                    if int(padre[2]) < fila:
                        flechas.append((int(padre[5]), nodo))
        out[str(clase)] = {"specs": specs, "nodos": nodos, "pide": pide, "flechas": flechas}
    return out


def lua_texto(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def escribir(datos) -> str:
    o = ["-- Generado por tools/asistente/generador/arbol_clase.py. NO EDITAR A MANO: volver a generar.",
         "-- Data: ForeverDB.net (https://foreverdb.net), build 1.60.1.70938. Reuse requires this credit: see NOTICE-ForeverDB.txt (GPL-3.0 section 7(b)).",
         "-- Hechizo de cada talento: Polestar Talents/Builds.lua (GPL-3.0-only), por el número de nodo. Licencia: GPL-3.0-only.",
         "-- nodos[id] = { hechizo (0: lo da el juego por la entrada), árbol, fila, columna, rangos, entrada, nombre en inglés }",
         "-- pide[id] = puntos en ese árbol para abrirlo · flechas = { {desde, hasta} }: el de destino pide el de origen.",
         "local _, ns = ...", "ns.ARBOL = {"]
    for clase in sorted(datos):
        d = datos[clase]
        o.append(f"\t{clase} = {{")
        o.append("\t\tspecs = { " + ", ".join(lua_texto(s) for s in d["specs"]) + " },")
        o.append("\t\tnodos = {")
        for nid in sorted(d["nodos"]):
            h, s, f, c, m, e, n = d["nodos"][nid]
            o.append(f"\t\t\t[{nid}] = {{ {h}, {s}, {f}, {c}, {m}, {e}, {lua_texto(n)} }},")
        o.append("\t\t},")
        o.append("\t\tpide = { " + ", ".join(f"[{k}] = {v}" for k, v in sorted(d["pide"].items())) + " },")
        o.append("\t\tflechas = { " + ", ".join(f"{{ {a}, {b} }}" for a, b in d["flechas"]) + " },")
        o.append("\t},")
    o.append("}")
    return "\n".join(o) + "\n"


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    if not FOREVERDB.exists():
        print("falta", FOREVERDB, "(lo baja WOW_FOREVER/generador/builds_clase.py)")
        sys.exit(0 if "--comprobar" in sys.argv else 1)
    texto = escribir(leer())
    if "--comprobar" in sys.argv:
        actual = SALIDA.read_text(encoding="utf-8") if SALIDA.exists() else ""
        if actual != texto:
            print("Datos_Arbol.lua no está al día: vuelve a correr arbol_clase.py")
            sys.exit(1)
        print("Datos_Arbol.lua al día")
        return
    SALIDA.write_text(texto, encoding="utf-8", newline="\n")
    print("escrito", SALIDA)


if __name__ == "__main__":
    main()
