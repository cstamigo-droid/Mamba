"""Pruebas de Mamba_Profesiones con Lua 5.1 (lupa). Uso: python test_profesiones.py [--romper]

Reusa la simulación de mock_barras.lua (eventos que Forever no conoce dan error, combate) y le suma lo que lee el
módulo: SkillUp Forever (API.Professions), precios (MambaAPI.PrecioObjeto), mapas, la flecha de Polestar y
C_TradeSkillUI. --romper quita el filtro de zonas del otro bando: las pruebas tienen que fallar (control negativo).
Lo que NO prueba: cómo se ve (eso, en el juego).
"""
import sys, pathlib
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
D = AQUI.parent.parent.parent / "addon" / "Mamba_Profesiones"
ROMPER = "--romper" in sys.argv
toc = (D / "Mamba_Profesiones.toc").read_text(encoding="utf-8")
ARCHIVOS = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua")]
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


MOCK = r'''
NIVEL = 39
function UnitLevel() return NIVEL end
function UnitFactionGroup() return "Horde" end
function UnitRace() return "Tauren", "Tauren" end
function GetTime() return RELOJ or 1000 end
PROFS = { { "Herboristería", 212, 225 }, { "Alquimia", 190, 225 } }
function GetProfessions() return 1, 2 end
function GetProfessionInfo(i) local p = PROFS[i]; return p[1], 0, p[2], p[3] end
MAPA = 1411
C_Map = { GetMapInfo = function(id) return { name = "Zona " .. id } end, GetBestMapForUnit = function() return MAPA end }
BOLSA = {}
function GetItemCount(id) return BOLSA[id] or 0 end
C_Item = { GetItemNameByID = function(id) return "Obj" .. id end, RequestLoadItemDataByID = function() end }
function GetItemInfo(id) return "Obj" .. id, nil, 1, 1, 1, "", "", 20, "", 0, 5 end
PRECIOS = { [2447] = 30, [3820] = 5000, [2450] = 400 }
MambaAPI = { PrecioObjeto = function(id) return PRECIOS[id], "subasta", 600 end, OroPorHora = function() return HORA end }
NAVEGO = {}
Polestar = { Nav = { API = { version = 1,
  Navigate = function(o, m, x, y, t) table.insert(NAVEGO, { o, m, x, y, t }); return true end,
  Estimate = function() return 120 end } },
  UI = { RegisterSection = function(s) SECCION = s; return true end, ShowPicker = function() end,
         Picker = { ShowSection = function() end, Render = function() end } } }
SUBIDOS = 0
SkillUpForever = { API = {
  Professions = function()
    return { { name = "Alquimia", skillLineID = 171, rank = 190, maxRank = 225, title = "Experto",
      steps = { { kind = "buy", text = "Compra 15 Obj2447", nav = false },
                { kind = "train", text = "Entrena Experto", detail = "Instructor, Cima del Trueno · 1 o", cost = 10000, nav = true } },
      recipes = {},
      reagents = { { itemID = 2447, need = 20, have = 5, source = "gather" },
                   { itemID = 3820, need = 10, have = 0, source = "gather" },
                   { itemID = 2450, need = 4, have = 4, source = "gather" },
                   { itemID = 9999, need = 2, have = 0, source = "vendor" } } } }
  end,
  Navigate = function(l, i) NAV_SKILL = { l, i }; return true end,
  OpenRecipes = function() ABRIO = true; return true end,
  Subscribe = function(fn) SUBIDOS = SUBIDOS + 1; return function() end end,
} }
C_TradeSkillUI = {
  GetBaseProfessionInfo = function() return { professionName = "Alquimia", professionID = 171 } end,
  GetAllRecipeIDs = function() return { 1, 2 } end,
  GetRecipeInfo = function(id) return { name = "Receta " .. id, learned = id == 1 } end,
  GetRecipeSchematic = function(id) return { outputItemID = 118, quantityMin = 1, quantityMax = 1,
    reagentSlotSchematics = { { quantityRequired = 2, reagents = { { itemID = 2447 } } } } } end,
}
PRECIOS[118] = 500
'''


def nuevo():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute('EVENTOS_DESCONOCIDOS.TRADE_SKILL_UPDATE = true')
    L.execute(MOCK)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Profesiones", M) end')
    for n in ARCHIVOS:
        cargar((D / n).read_text(encoding="utf-8"), n, M)
    if ROMPER:
        L.execute("MambaProfesiones.C.ZONA_BANDO = {}")
    return L, M


L, M = nuevo()
G = L.globals()
check(len(list(G.ERRORES.values())) == 0, "cargar sin errores: " + str(list(G.ERRORES.values())))
L.execute('Fire("PLAYER_LOGIN")')
check(G.SECCION is not None and G.SECCION.order == 260 and G.SECCION.label == "Profesiones", "sección Profesiones en el lugar 260")
check(G.SUBIDOS == 1, "se suscribe a los cambios de SkillUp")
check(G.MambaProfesiones.DB().diag.eventosNo is None or G.MambaProfesiones.DB().diag.eventosNo["TRADE_SKILL_UPDATE"] is None,
      "no registra TRADE_SKILL_UPDATE (Forever no lo conoce)")

# ---------- datos generados
check(G.MambaProfesiones.FUENTES[2589] is not None and G.MambaProfesiones.FUENTES[2447] is not None, "datos de farmeo: tela de lino y flor de paz")
fila = G.MambaProfesiones.FUENTES[2447][1]
check(fila[1] == "hierba" and fila[8] == 100.0, "la flor de paz sale de un nodo al 100 %")

# ---------- Farmeo: bando y habilidad
C = G.MambaProfesiones.C
p = C.Personaje()
check(p.bando == "Horde" and p.profs["Herboristería"].rango == 212, "lee bando y profesiones")
formas = C.Farmeo(2589, p)  # tela de lino
zonas_ok = [f.mapa for f in formas.values() if f.sirve]
check(1436 not in zonas_ok and 1438 not in zonas_ok, "no recomienda zonas de la Alianza a la Horda (Páramos de Poniente, Teldrassil)")
check(all(not f.sirve for f in formas.values() if f.nivel[1] > 42), "no recomienda criaturas muy altas")
cobre = C.Farmeo(2770, p)  # cobre: Hope no tiene Minería
check(all(not f.sirve for f in cobre.values()), "sin Minería, las vetas no sirven")

# ---------- K60: lista de compra
G.HORA = None
lc = C.ListaCompra(171)
check(lc is not None, "lista de compra de Alquimia")
filas = {lc[i].id: lc[i] for i in range(1, len(lc) + 1)}
check(filas[2447].falta == 15, "flor de paz: faltan 15 (20 - 5)")
check(filas[2447].elige == "comprar", "flor de paz barata (30 c): se compra")
check(filas[2450].falta == 0 and filas[2450].elige is None, "lo que ya tienes no pide nada")
check(filas[3820].comprar.total == 50000, "comprar 10 × 50 p = 5 o")
t = lc.total
check(t.comprar == 15 * 30 + 50000, "total comprando todo")
check(t.sinPrecio == 1, "uno sin precio (el del vendedor sin dato)")
check(abs(t.mixtoOro - sum(f.comprar.total for f in filas.values() if f.elige == "comprar")) < 1, "el total mixto suma lo elegido para comprar")
check(lc.valorMedido is False and lc.valorHora == 39 * 2500, "sin medir: la hora vale ≈ por nivel")
G.HORA = L.eval("{ actual = 1 }")
lc2 = C.ListaCompra(171)
check(lc2.valorMedido is True, "con el Medidor, la hora medida manda")
G.HORA = None

# ---------- E8: VITAL
v = C.Vital(2447)[0]
check(v is not None and "VITAL" in v and "te faltan 15" in v, "flor de paz es VITAL para Alquimia")
check("ya tienes" in C.Vital(2450)[0], "lo que ya tienes no es VITAL")
check(C.Vital(12345) is None, "lo que no pide tu plan no dice nada")

# ---------- R0.2: lo medido corrige lo estimado
G.MambaProfesiones.Medir.Empezar(2447, 1411)
G.BOLSA[2447] = 40
G.RELOJ = 1400
G.MambaProfesiones.Medir.Tick()
m = C.Medido(2447, 1411)
check(m is not None and abs(m - 40 / (400 / 3600)) < 0.01, "40 unidades en 400 s = 360 por hora medidas")
formas = C.Farmeo(2447, p)
d1411 = [f for f in formas.values() if f.mapa == 1411][0]
check(d1411.medido and abs(d1411.porHora - 360) < 0.01, "la forma medida usa lo medido")
G.MAPA = 1412
G.RELOJ = 1500
G.MambaProfesiones.Medir.Tick()
check(abs(G.MambaProfesiones.DB().medido["2447:1411"][2] - 400) < 0.01, "fuera del mapa no suma tiempo")

# ---------- O7: lugares
lug = C.Lugares("tela", p)
check(len(lug) > 0, "hay lugares de tela para nivel 39")
oro = [x.oroHora or 0 for x in lug.values()]
check(oro == sorted(oro, reverse=True), "ordenados por oro por hora")
check(all(x.mapa not in (1436, 1438, 1429) for x in lug.values()), "sin zonas de la Alianza")
_, motivo = C.Lugares("minerales", p)
check(motivo is not None and "Minería" in motivo, "minerales sin Minería: dice qué falta")

# ---------- revisión wow-economía (18-11): zonas, guardias, objeto de cada fila, unidades
F = G.MambaProfesiones.FUENTES
todas = [F[k][i] for k in F.keys() for i in range(1, len(F[k]) + 1)]
check(not any("Guardia" in r[5] for r in todas), "sin guardias ni PNJ amistosos en las fuentes")
osos = [r for r in todas if r[5] == "Oso cardo rabioso"]
check(osos and all(r[2] == 1439 for r in osos), "Oso cardo rabioso en Costa Oscura (1439), no en Frondavil")
check(all(r[10] is not None for r in todas), "cada fuente trae sus unidades por caída")
veta = F[2770][1]
check(veta[10] == 1.0, "una veta de cobre da 1 mineral por nodo, no 2")
LUG = G.MambaProfesiones.LUGARES
TELAS = {2589: 1, 2592: 2, 4306: 3, 4338: 4, 14047: 5}
filas = [LUG.tela[i] for i in range(1, len(LUG.tela) + 1)]
check(all(r[9] in TELAS for r in filas), "tela: cada lugar trae su tela")
h2 = [LUG.hierbas[i] for i in range(1, len(LUG.hierbas) + 1) if LUG.hierbas[i][1] == 2]
check(h2 and all(r[9] != 2453 for r in h2), "hierbas del tramo 2 (50-99): no usa Hierba cardenal (100)")
lug = C.Lugares("tela", p)
check(all(x.oroHora is None or abs(x.oroHora - C.Precio(x.item) * x.porHora * 0.95) < 0.01 for x in lug.values()), "oro por hora neto (menos 5 %)")

# ---------- Recetas y ganar oro
n = G.MambaProfesiones.Medir.LeerRecetas()
check(n == 1, "lee solo las recetas aprendidas")
res, leidas = C.Fabricar()
check(leidas == 1 and len(res) == 1, "una receta leída")
r1 = res[1]
check(abs(r1.ganancia - (500 * 0.95 - 5 * 0.15 - 60)) < 0.01, "ganancia = 500 × 0,95 - depósito (15 % de 5) - 2 × 30")

# ---------- sección: todas las partes se dibujan con su botón
s = G.SECCION
padre = L.eval('CreateFrame("Frame")')
s.build(padre)
for v in ["tuyas", "compra", "instructores", "ganar", "farmeo"]:
    s.onNav(v)
    s.render()
check(len(list(G.ERRORES.values())) == 0, "dibujar todas las partes sin errores: " + str(list(G.ERRORES.values()))[:300])
check(G.MambaProfesiones.DB().diag.fallas is None, "sin fallas en el diagnóstico: " + str(G.MambaProfesiones.DB().diag.fallas and list(G.MambaProfesiones.DB().diag.fallas.values())))
items, act = s.nav()
check(len(items) == 5, "el índice tiene 5 partes")
# llévame en la lista de compra
lc = C.ListaCompra(171)
far = [f for f in [lc[i] for i in range(1, len(lc) + 1)] if f.farmear]
check(len(far) > 0, "hay al menos una fila con farmeo")
if far:
    f = far[0]
    G.MambaProfesiones.Llevame(f.farmear.forma.mapa, f.farmear.forma.x, f.farmear.forma.y, "x")
    check(len(G.NAVEGO) == 1 and G.NAVEGO[1][1] == "MambaProfesiones", "Llévame pone la flecha de Polestar")
check(abs(G.MambaProfesiones.MinutosViaje(1411, 50, 50) - 2) < 0.01, "minutos de viaje del motor de Ir a… (120 s = 2 min)")

# ---------- K61/K62: recomendaciones para Mi plan
rec = G.MambaProfesiones.Recomendaciones()
check(len(rec) == 1 and rec[1].puntos == 35 and rec[1].solo and rec[1].estrellas != "", "recomendación con número, solo y estrellas")
check(rec[1].como is not None and (rec[1].llevame is not None), "trae el cómo y el Llévame")
check(len(G.MambaProfesiones.Recomendaciones(L.eval("{ minutos = 0 }"))) <= 1, "filtro de minutos")

# ---------- sin SkillUp: mensaje, sin error
G.SkillUpForever = None
C.Olvidar()
lista, motivo = C.Profesiones()
check(lista is None and "SkillUp" in motivo, "sin SkillUp Forever dice qué falta")
s.onNav("compra"); s.render()
check(len(list(G.ERRORES.values())) == 0, "sin SkillUp no da error")

print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
