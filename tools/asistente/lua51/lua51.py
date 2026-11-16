"""Intérprete Lua 5.1 mínimo sobre lupa, para correr las pruebas de Polestar en Node
sin instalar Lua (Windows). Uso: python -I lua51.py <archivo.lua> | -e <código>"""
import sys
from lupa.lua51 import LuaRuntime, LuaError

def main(argv):
    L = LuaRuntime(unpack_returned_tuples=True)
    flush = L.eval("function() io.stdout:flush(); io.stderr:flush() end")
    try:
        if argv and argv[0] == "-e":
            L.execute(argv[1])
        elif argv:
            src = open(argv[0], "rb").read().decode("utf-8", "surrogateescape")
            f = L.eval("function(src, name) local f, e = loadstring(src, '@' .. name); if not f then error(e, 0) end; return f end")(src, argv[0])
            f()
        flush()
        return 0
    except LuaError as e:
        flush()
        sys.stderr.write(str(e) + "\n")
        return 1

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
