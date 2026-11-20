# K101: al entregar una misión, Mamba resalta la recompensa que más conviene (mejora para las builds de Mi plan o,
# si ninguna mejora, la que más vale) y dice por qué en una línea. NUNCA elige por el jugador.
# Uso: python -I tools/asistente/pruebas/test_recompensa.py addon/Tasador [--romper-k101]
#   --romper-k101: control negativo (Mamba elige siempre la primera opción); la prueba DEBE fallar.
import sys, pathlib
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

D = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "addon/Tasador")
ROMPER = "--romper-k101" in sys.argv
L = LuaRuntime(unpack_returned_tuples=True)
L.execute((pathlib.Path(__file__).parent / "mock_wow.lua").read_text(encoding="utf-8"))
T = L.table()
loader = L.eval('function(src, name, T) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Tasador", T) end')
toc = [l.strip() for l in (D / "Tasador.toc").read_text(encoding="utf-8").splitlines() if l.strip().endswith(".lua")]
check_toc = "Recompensa.lua" in toc and toc.index("Recompensa.lua") > toc.index("Cuadro.lua")
for name in toc:
    loader((D / name).read_text(encoding="utf-8"), name, T)
L.execute('Fire("ADDON_LOADED", "Tasador")')
L.globals().T = T
if ROMPER:
    L.execute('local orig = T.ElegirRecompensa; T.ElegirRecompensa = function(o, c) local r = orig(o, c); if r then r.index = o[1].index end; return r end')

ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


check(check_toc, "Recompensa.lua va en el .toc después de Cuadro.lua")

# ---------------------------------------------------------------- lógica pura
L.execute('''
function OP(index, mejoras, subasta, vendedor, cantidad)
  return { index = index, mejoras = mejoras or {}, subasta = subasta, vendedor = vendedor or 0, cantidad = cantidad or 1 }
end
function M(nombre, pct, ranura, extra)
  local m = { nombre = nombre, pct = pct, ranura = ranura or 2 }
  for k, v in pairs(extra or {}) do m[k] = v end
  return m
end
function ELIGE(...) return T.ElegirRecompensa({ ... }, 0.05) end
''')
E = L.globals()

r = L.eval('ELIGE(OP(1, {M("Equilibrio", 5, 1)}), OP(2, {M("Equilibrio", 12, 2)}), OP(3, {}))')
check(r.index == 2 and r.tipo == "mejora", f"gana la de mayor mejora: {r.index} {r.tipo}")
check(r.texto.startswith("Mejora tu cuello +12 % para Equilibrio"), f"texto con ranura, % y build: {r.texto}")
check("la siguiente, +5 %" in r.texto, f"R0: muestra la que sigue: {r.texto}")

# la mejora para la SEGUNDA build también cuenta (K59)
r = L.eval('ELIGE(OP(1, {M("Equilibrio", 3, 8)}), OP(2, {M("Equilibrio", -4, 6), M("Restauración", 20, 6)}))')
check(r.index == 2 and "+20 % para Restauración" in r.texto, f"la segunda build cuenta: {r.index} {r.texto}")

# una pieza que mejora las dos builds lo dice
r = L.eval('ELIGE(OP(1, {M("Equilibrio", 10, 9), M("Restauración", 6, 9)}), OP(2, {}))')
check(r.index == 1 and r.texto == "Mejora tus muñecas +10 % para Equilibrio y +6 % para Restauración", f"las dos builds: {r.texto}")

# llenar una ranura vacía gana a cualquier %
r = L.eval('ELIGE(OP(1, {M("Equilibrio", 80, 1)}), OP(2, {M("Equilibrio", nil, 15, {vacia = true})}))')
check(r.index == 2 and r.texto.startswith("Llena tu ranura vacía de capa para Equilibrio"), f"ranura vacía: {r.index} {r.texto}")

# lo de más nivel (aún no la puede usar) y lo «igual que lo tuyo» no son mejora
r = L.eval('ELIGE(OP(1, {M("Equilibrio", 40, 1, {despues = 30})}, nil, 100), OP(2, {M("Equilibrio", 0.3, 2)}, nil, 900))')
check(r.tipo == "valor" and r.index == 2, f"nivel futuro e igual no cuentan: {r.tipo} {r.index}")

# sobre +200 %: «5,4 veces»
r = L.eval('ELIGE(OP(1, {M("Equilibrio", 443, 2)}), OP(2, {}))')
check("5,4 veces" in r.texto and "%" not in r.texto, f"veces: {r.texto}")

# sin plan (sin nombre de build)
r = L.eval('ELIGE(OP(1, {M(nil, 7, 5)}), OP(2, {}))')
check(r.texto == "Mejora tu pecho +7 %", f"sin plan: {r.texto}")

# ninguna mejora: la que más vale, subasta (neto de comisión) contra vendedor, por la pila
r = L.eval('ELIGE(OP(1, {}, 13000, 500), OP(2, {}, nil, 2000), OP(3, {}, 100, 1500))')
check(r.index == 1 and r.tipo == "valor", f"subasta gana: {r.index}")
check(r.texto.startswith("Ninguna te mejora: esta vale 1o 23p 50c en la subasta"), f"texto valor subasta: {r.texto}")
check("(1 sin precio de subasta aún)" in r.texto, f"avisa lo que no tiene precio: {r.texto}")
r = L.eval('ELIGE(OP(1, {}, 1000, 3000), OP(2, {}, 1200, 400, 5))')
check(r.index == 2 and "con el vendedor" not in r.texto and "5o" not in r.texto, f"la pila cuenta: {r.index} {r.texto}")
r = L.eval('ELIGE(OP(1, {}, nil, 2500), OP(2, {}, nil, 900))')
check(r.index == 1 and r.texto.startswith("Ninguna te mejora: esta vale 25p con el vendedor"), f"vendedor: {r.texto}")
r = L.eval('ELIGE(OP(1, {}, nil, 0), OP(2, {}, nil, 0))')
check(r.tipo == "nada" and r.index is None, "sin mejora ni precio: no resalta nada")

# empate de mejora: decide lo que vale
r = L.eval('ELIGE(OP(1, {M("Feral", 9, 10)}, nil, 100), OP(2, {M("Feral", 9, 10)}, nil, 800))')
check(r.index == 2, f"empate: gana la que más vale: {r.index}")

# ---------------------------------------------------------------- MejorasDeBuilds: los mismos números del cuadro (E8)
L.execute('''
GI = {}
CMP = {}
Polestar = Polestar or {}
Polestar.Gear = {
  CLASSES = { DRUID = { default = "balance", specs = { { key = "balance", label = "Balance" },
    { key = "feral", label = "Feral (tank)" }, { key = "restoration", label = "Restoration (healer)" } } } },
  GetPlayer = function() return { class = "DRUID", level = 30 } end,
  PlayerLevel = function() return 30 end,
  WeightsFor = function(_, rol) return { rol = rol } end,
  GetItemInfo = function(link) return GI[link] end,
  ScoreWith = function(info, w) return info[w.rol] or 0 end,
  CompareToEquipped = function(link) return CMP[link] end,
}
MambaPlanPJ = { respuestas = { rol = "danio", arbol = 1, rol2 = "sanar" } }
EQUIP_LINK[2] = "puesto2"
GI["puesto2"] = { balance = 10, restoration = 10 }
GI["collar"] = { balance = 11, restoration = 15 }
CMP["collar"] = { usable = true, slot = 2, pct = 12, delta = 1.2 }
''')
m = T.MejorasDeBuilds("collar")
check(m[1].nombre == "Equilibrio" and m[1].pct == 12 and m[1].ranura == 2, "la principal usa el % de Polestar (el del cuadro)")
check(m[2].nombre == "Restauración" and abs(m[2].pct - 50) < 0.01, f"la segunda build con sus pesos: {m[2] and m[2].pct}")
L.execute('CMP["casco"] = { usable = true, slot = 1, pct = 30, minLevel = 35 }; GI["casco"] = { balance = 5 }')
m = T.MejorasDeBuilds("casco")
check(m[1].despues == 35, "pieza de más nivel: queda para después")
L.execute('CMP["hacha"] = { usable = false, reason = "weapon" }')
check(len(list(T.MejorasDeBuilds("hacha").values())) == 0, "lo que no puede usar no es mejora")

# ---------------------------------------------------------------- el enganche con Polestar (QoL/Rewards.lua)
L.execute('''
TOMADA = nil
function GetQuestReward(i) TOMADA = i end
local function region()
  local r = {}
  setmetatable(r, { __index = function(t, k) return function() end end })
  r.SetText = function(self, t) self.text = t end
  r.GetStringHeight = function() return 14 end
  return r
end
CreateFrame = (function(viejo)
  return function(tipo, nombre, padre)
    local f = viejo(tipo, nombre, padre)
    f.shown = false
    f.CreateTexture = function() return region() end
    f.SetHeight = function(self, h) self.h = h end
    f.SetPoint = function() end
    f.SetFrameLevel = function() end
    f.GetFrameLevel = function() return 1 end
    f.Show = function(self) self.shown = true end
    f.Hide = function(self) self.shown = false end
    f.IsShown = function(self) return self.shown end
    return f
  end
end)(CreateFrame)
QuestFrame = CreateFrame("Frame")
QuestFrameRewardPanel = CreateFrame("Frame"); QuestFrameRewardPanel.shown = true
QuestInfoFrame = { questLog = false }
ULTIMO_TEXTO = nil
Polestar.Widgets = { Fill = function() return region() end, Text = function()
  local r = region()
  r.SetText = function(self, t) ULTIMO_TEXTO = t end
  return r
end }
Polestar.Theme = { Media = function() return "white" end }
Polestar.Hidden = function() return false end
ITEMS[901] = { name = "Collar de la luna", q = 2, sell = 300, cls = 4, sub = 0, bind = 1, loc = "INVTYPE_NECK" }
ITEMS[902] = { name = "Botas de tela", q = 2, sell = 900, cls = 4, sub = 1, bind = 1, loc = "INVTYPE_FEET" }
CMP["item:901"] = { usable = true, slot = 2, pct = 12, delta = 1 }
CMP["item:902"] = { usable = true, slot = 8, pct = -3, delta = -1 }
ELECCION = { { index = 1, link = "item:902", itemID = 902, count = 1 }, { index = 2, link = "item:901", itemID = 901, count = 1 } }
POLESTAR_MARCO = nil
Polestar.QoL = { Rewards = {
  ReadChoices = function() return ELECCION, true, true end,
  -- Polestar por su cuenta elegiría la de más valor de vendedor (la 1)
  Rank = function(c) return { 1, 2 }, "value" end,
}}
local R = Polestar.QoL.Rewards
R.Mark = function() local o = R.Rank(R.ReadChoices()); POLESTAR_MARCO = o[1]; return MARCA ~= false end
''')
check(T.EngancharRecompensas() is True, "se engancha a las recompensas de Polestar")
check(T.EngancharRecompensas() is True, "engancharse dos veces no rompe")
L.execute('Polestar.QoL.Rewards.Mark()')
g = L.globals()
check(g.POLESTAR_MARCO == 2, f"el marco de Polestar va a la que dice Mamba (el collar): {g.POLESTAR_MARCO}")
t = g.ULTIMO_TEXTO or ""
check("Collar de la luna" in t and "Mejora tu cuello +12 %" in t and "Equilibrio" in t, f"la línea del motivo con el nombre: {t!r}")
check(g.TOMADA is None, "NUNCA elige por el jugador (no llama a GetQuestReward)")

# en el registro de misiones (no al entregar) no hay franja
L.execute('ULTIMO_TEXTO = nil; QuestInfoFrame.questLog = true; Polestar.QoL.Rewards.Mark(); QuestInfoFrame.questLog = false')
check(g.ULTIMO_TEXTO is None, "en el registro de misiones no se muestra la franja")
# una sola recompensa: nada que elegir
L.execute('ULTIMO_TEXTO = nil; local e = ELECCION; ELECCION = { e[1] }; Polestar.QoL.Rewards.Mark(); ELECCION = e')
check(g.ULTIMO_TEXTO is None, "con una sola recompensa no hay franja")
# con Polestar oculto, nada
L.execute('ULTIMO_TEXTO = nil; Polestar.Hidden = function() return true end; Polestar.QoL.Rewards.Mark(); Polestar.Hidden = function() return false end')
check(g.ULTIMO_TEXTO is None, "con Polestar oculto no se muestra")
# si Mamba falla, Polestar sigue con su orden (no rompe la ventana)
L.execute('local e = T.RecompensaDe; T.RecompensaDe = function() error("x") end; ORD = Polestar.QoL.Rewards.Rank(ELECCION); T.RecompensaDe = e')
check(g.ORD[1] == 1, "si el cálculo de Mamba falla, queda el orden de Polestar")


# revisor t5 (BAJA): sin el marco de Polestar (resaltado apagado o datos sin cargar) no sale la franja
L.execute('ULTIMO_TEXTO = "x"; MARCA = false; Polestar.QoL.Rewards.Mark(); MARCA = nil')
check(g.ULTIMO_TEXTO == "x", "si Polestar no marca, la franja no se muestra")
L.execute('ULTIMO_TEXTO = nil; Polestar.QoL.Rewards.Mark()')
check(g.ULTIMO_TEXTO is not None, "con el marco de Polestar, la franja vuelve")

# revisor t5 (MEDIA), DECIDIDO: con la elección automática de Polestar encendida por el jugador, toma la del marco
# (la de Mamba). Simula el camino de Polestar (QoL/Rewards.lua, evaluate: order = Rewards.Rank(...); GetQuestReward(order[1]))
L.execute('''
TOMADA = nil
local R = Polestar.QoL.Rewards
local order = R.Rank(R.ReadChoices())
GetQuestReward(order[1])
''')
check(g.TOMADA == 2, f"elección automática (encendida por el jugador): toma la misma del marco: {g.TOMADA}")
qol = (D.parent / "Polestar" / "QoL" / "QoL.lua").read_text(encoding="utf-8")
check("rewardAutoPick = false," in qol, "la elección automática de Polestar viene apagada: por defecto el clic es del jugador")

print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
