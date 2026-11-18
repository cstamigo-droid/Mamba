"""Escribe addon/Mamba_Barras/DeBartender.lua con las barras de Bartender4 de cada personaje de este PC.

Uso: python copiar_bartender.py <carpeta WTF/Account> <DeBartender.lua de salida>
Lee cada SavedVariables/Bartender4.lua, toma el perfil de cada personaje (profileKeys) y guarda, por
personaje, solo los módulos que Mamba usa: ActionBars, StanceBar y PetBar. Nada sale del computador.
Licencia: GPL-3.0-only.
"""
import sys, pathlib
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

MODULOS = ("ActionBars", "StanceBar", "PetBar")


def a_lua(v, sangria=1):
    t = " " * sangria
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, dict):
        partes = []
        for k in sorted(v, key=lambda k: (isinstance(k, str), str(k))):
            clave = f"[{k}]" if isinstance(k, (int, float)) else "[" + a_lua(k) + "]"
            partes.append(f"{t}{clave} = {a_lua(v[k], sangria + 1)},")
        return "{\n" + "\n".join(partes) + "\n" + " " * (sangria - 1) + "}"
    raise TypeError(type(v))


def a_python(x):
    if hasattr(x, "items"):
        return {(int(k) if isinstance(k, float) and k.is_integer() else k): a_python(v) for k, v in x.items()}
    return x


def leer(archivo):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute(archivo.read_text(encoding="utf-8", errors="replace"))
    db = L.globals().Bartender4DB
    if db is None:
        return {}
    db = a_python(db)
    out = {}
    for pj, perfil in (db.get("profileKeys") or {}).items():
        p = {}
        for mod in MODULOS:
            ns = (db.get("namespaces") or {}).get(mod) or {}
            pr = (ns.get("profiles") or {}).get(perfil)
            if pr is not None:
                p[mod] = pr
        if p:
            out[pj] = p
    return out


def main():
    cuentas, salida = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    todo = {}
    for f in sorted(cuentas.glob("*/SavedVariables/Bartender4.lua")):
        todo.update(leer(f))
    cab = salida.read_text(encoding="utf-8").split("M.COPIA_BT")[0] if salida.exists() else "local _, M = ...\n"
    cuerpo = cab + "M.COPIA_BT = " + a_lua(todo) + "\n"
    salida.write_text(cuerpo, encoding="utf-8")
    print(f"{len(todo)} personaje(s) copiados: {', '.join(todo) or 'ninguno'}")


if __name__ == "__main__":
    main()
