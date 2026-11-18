"""Pruebas de Mamba_Bolsas con Lua 5.1 (lupa). Uso: python test_bolsas.py [carpeta de Mamba_Bolsas]"""
import sys, pathlib, re
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else AQUI.parent.parent.parent / "addon" / "Mamba_Bolsas"
toc = (D / "Mamba_Bolsas.toc").read_text(encoding="utf-8")
ARCHIVOS = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua")]
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


MOCK = '''
CVARS = { combinedBags = "0" }
C_CVar = { GetCVar = function(k) return CVARS[k] end, SetCVar = function(k, v) CVARS[k] = v end }
ITEMS = { [0] = { [1] = { itemID = 2447, stackCount = 5 }, [2] = { itemID = 765, stackCount = 3 } },
          [1] = { [1] = { itemID = 2447, stackCount = 2 } } }
BANCO = { [-1] = { [1] = { itemID = 2447, stackCount = 10 } } }
ABIERTO = false
C_Container = {
  GetContainerNumSlots = function(b) if b >= 0 and b <= 4 then return 16 end; if ABIERTO and (b == -1) then return 28 end; return 0 end,
  GetContainerItemInfo = function(b, s) local t = (b == -1 and BANCO[-1]) or ITEMS[b]; return t and t[s] end,
}
NOMBRES = { [2447] = "Hojaplata", [765] = "Flor de paz" }
C_Item = { GetItemNameByID = function(id) return NOMBRES[id] end }
function GetMoney() return 841200 end
LINEAS = {}
Polestar = { Hooks = { ItemLines = function(o, fn) HOOK = fn; return true end, AddLine = function(t, l) table.insert(LINEAS, l) end } }
'''


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute(MOCK)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Bolsas", M) end')
    for n in ARCHIVOS:
        cargar((D / n).read_text(encoding="utf-8"), n, M)
    return L, M


L, M = nuevo()
G = L.globals()
L.execute('Fire("PLAYER_LOGIN")')
check(not list(G.ERRORES.values()), "errores: %s" % list(G.ERRORES.values()))
check(G.CVARS.combinedBags == "1", "bolsas unidas encendidas")
p = G.MambaBolsasDB.personajes["Hope - Fé"]
check(p.bolsas[2447] == 7 and p.bolsas[765] == 3 and p.banco is None, "bolsas guardadas; banco todavía no")
L.execute('ABIERTO = true; Fire("BANKFRAME_OPENED")')
check(G.MambaBolsasDB.personajes["Hope - Fé"].banco[2447] == 10, "banco guardado al abrirlo")
L.execute('MambaBolsasDB.personajes["Cazador - Fé"] = { bolsas = { [2447] = 4 }, oro = 0 }')
donde, total = M.Donde(2447)
check(total == 21 and donde[1].nombre == "Hope" and donde[1].banco == 10, "dónde: %s" % total)
G.HOOK(L.table(), "item:2447", 2447)
check(len(list(G.LINEAS.values())) == 1 and "Tienes 21" in G.LINEAS[1] and "Cazador 4" in G.LINEAS[1], "línea en el cuadro: %s" % list(G.LINEAS.values()))
res = list(M.Buscar("hoja").values())
check(len(res) == 1 and res[0].nombre == "Hojaplata", "buscar en todos")
check(len(list(M.Buscar("").values())) == 2, "sin texto: todo")
G.MambaBolsasDB.opciones.unir = False
M.AplicarUnir()
check(G.CVARS.combinedBags == "0", "apagar bolsas unidas")
# en Interfaz
L2, M2 = nuevo()
L2.execute('Polestar.UI = { Picker = {} }; function Polestar.UI.RegisterSection(s) SECCION = s; return true end; '
           'function Polestar.UI.ShowPicker() end; function Polestar.UI.Picker.ShowSection() end; function Polestar.UI.Picker.Render() end')
G2 = L2.globals()
L2.execute('Fire("PLAYER_LOGIN")')
S = G2.SECCION
check(S is not None and S.key == "MambaInterfaz", "Bolsas dentro de Interfaz")
items, _ = S.nav()
check(any(i.label == "Bolsas" and i.heading for i in items.values()), "título Bolsas en el índice")
padre = L2.eval('function() local f = CreateFrame("Frame", nil, UIParent); f.w, f.h = 640, 480; return f end')()
S.build(padre)
for k in ["bolsas:buscar", "bolsas:Hope - Fé", "bolsas:opciones"]:
    S.onNav(k); S.render()
check(not list(G2.ERRORES.values()), "panel sin errores: %s" % list(G2.ERRORES.values())[:3])
for n in ARCHIVOS:
    src = (D / n).read_text(encoding="utf-8")
    check(not re.search(r"\b(PickupContainerItem|UseContainerItem|DeleteCursorItem|SplitContainerItem)\b", src), n + ": no mueve ni borra objetos")
print(f"{ok} OK, {fail} FALLAN")
sys.exit(1 if fail else 0)
