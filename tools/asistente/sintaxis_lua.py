"""sintaxis_lua.py CARPETA: compila (sin ejecutar) cada .lua con Lua 5.1 (lupa), como lo haría el cliente.
Sale con 1 y lista los archivos con error de sintaxis. Para el gate de la tanda (tools/asistente/gate_tanda.sh)."""
import pathlib
import sys

from lupa.lua51 import LuaRuntime

raiz = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "addon")
L = LuaRuntime()
compilar = L.eval("function(src, nombre) local f, e = loadstring(src, '@' .. nombre); return e end")
n = malos = 0
for f in sorted(raiz.rglob("*.lua")):
    n += 1
    try:
        src = f.read_bytes().decode("utf-8", "replace")
    except OSError as e:
        print("NO SE LEE", f, e)
        malos += 1
        continue
    err = compilar(src, str(f.relative_to(raiz)))
    if err:
        malos += 1
        print("ERROR", err)
print(f"{n} archivos, {malos} con error de sintaxis")
sys.exit(1 if malos else 0)
