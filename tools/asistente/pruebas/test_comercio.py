"""Pruebas del comerciante del Tasador 0.4 (Comercio.lua, Escaneo.lua, Recetas.lua, Oportunidades.lua), con Lua 5.1.
Criterios: WOW_FOREVER/addon/TASADOR_0.4_CRITERIOS.md (C1..C17). Uso: python -I test_comercio.py ../../../addon/Tasador
"""
import pathlib
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

D = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).parent.parent.parent.parent / "addon" / "Tasador"
AQUI = pathlib.Path(__file__).parent
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


# Funciones del juego que compran, pujan, publican, cancelan, fabrican o mueven objetos. Ninguna puede aparecer
# en el Tasador (C12). Si un día se agrega "publicar con un clic", tiene que ir detrás de un OnClick y esta
# prueba se cambia a "solo dentro de un manejador de clic", nunca se borra.
PROHIBIDAS = [
    "PlaceAuctionBid", "PostAuction", "StartAuction", "PlaceBid", "ConfirmCommoditiesPurchase", "StartCommoditiesPurchase",
    "PostItem", "PostCommodity", "CancelAuction", "CancelSell", "ClickAuctionSellItemButton", "PickupContainerItem",
    "UseContainerItem", "BuyMerchantItem", "PickupMerchantItem", "DoTradeSkill", "CraftRecipe", "ConfirmPostCommodity",
    "ConfirmPostItem", "SellCursorItem", "PickupItem", "AutoEquipCursorItem", "SplitContainerItem", "DeleteCursorItem",
    "SellAllJunkItems", "BuybackItem", "RepairAllItems", "DoCraft", "TakeInboxItem", "TakeInboxMoney", "SendMail",
    "PlaceAuction", "PostCommodityAuction", "RunScript", "loadstring", "getglobal", "SecureCmdOptionParse",
]


def sin_comentarios(src):
    """Quita los textos entre comillas ANTES de cortar los comentarios: un "--" dentro de un texto no esconde nada."""
    fuera = []
    for linea in src.splitlines():
        linea = re.sub(r'"(?:[^"\\]|\\.)*"', '""', linea)
        linea = re.sub(r"'(?:[^'\\]|\\.)*'", "''", linea)
        fuera.append(linea.split("--")[0])
    return "\n".join(fuera)

EXTRA = r'''
-- Reloj controlable: OFFSET en segundos. Con tabla, os.time (para el calendario de eventos).
OFFSET = 0
function time(t) if t then return os.time(t) end return DAY0 + TODAY * 86400 + 3600 + OFFSET end
-- Marcos falsos que aceptan cualquier método (para la ventana).
function Falso(nombre)
	local o = { scripts = {}, texto = "", visible = false, nombre = nombre }
	return setmetatable(o, { __index = function(t, k)
		if k == "SetScript" then return function(self, n, fn) self.scripts[n] = fn end end
		if k == "SetText" then return function(self, x) self.texto = x end end
		if k == "GetText" then return function(self) return self.texto end end
		if k == "Show" then return function(self) self.visible = true end end
		if k == "Hide" then return function(self) self.visible = false end end
		if k == "IsShown" then return function(self) return self.visible end end
		return function() end
	end })
end
local CF = CreateFrame
function CreateFrame(tipo, nombre, padre, plantilla)
	local f = CF()
	for _, m in ipairs({"SetSize","SetPoint","SetText","Show","Hide","SetParent"}) do f[m] = function() end end
	local orig = f.SetScript
	f.SetScript = function(self, n, fn) if n == "OnClick" then self.click = fn else orig(self, n, fn) end end
	if nombre then _G[nombre] = f end
	return f
end
-- Subasta moderna simulada: SUBASTAS = { {id, cantidad, compraYa, vendedor, tramo0a3}, ... }
SUBASTAS = {}
function UsarModerna()
	C_AuctionHouse = {
		ReplicateItems = function() end,
		GetNumReplicateItems = function() return #SUBASTAS end,
		GetReplicateItemInfo = function(i) local s = SUBASTAS[i + 1]
			return "x", 0, s[2], 1, true, 1, 0, 1, 1, s[3], 0, false, nil, s[4], s[4], 0, s[1], true end,
		GetReplicateItemTimeLeft = function(i) return SUBASTAS[i + 1][5] end,
	}
end
-- TRAMPAS (C12): cualquier función que compre, publique, cancele, fabrique o mueva objetos cuenta una llamada.
TRAMPAS = 0
local function trampa() TRAMPAS = TRAMPAS + 1 end
function PonerTrampas(lista)
	for _, n in ipairs(lista) do _G[n] = trampa end
	for _, tabla in ipairs({ "C_AuctionHouse", "C_Container", "C_TradeSkillUI", "C_MerchantFrame" }) do
		_G[tabla] = _G[tabla] or {}
		for _, n in ipairs(lista) do if _G[tabla][n] == nil then _G[tabla][n] = trampa end end
	end
end
'''


def nuevo(asistente=False):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_wow.lua").read_text(encoding="utf-8"))
    L.execute(EXTRA)
    L.execute("Auctionator = nil")
    if asistente:
        L.execute(r'''
        Asistente = {
            Color = function(n, t) return "<" .. n .. ">" .. tostring(t) end,
            ColorOscuro = function(n, t) return "<" .. n .. ">" .. tostring(t) end,
            CrearVentana = function(nombre) local f = Falso(nombre); f.cuerpo, f.margen = 56, 24; return f end,
            Texto = function() return Falso() end,
            Fila = function() return Falso() end,
            CuadroAyuda = function(_, titulo, lineas) AYUDA = { titulo = titulo, lineas = lineas } end,
            OcultarAyuda = function() end,
            AlCambiarApariencia = function(fn) REPINTAR = fn end,
        }''')
    T = L.table()
    cargar = L.eval('function(src, name, T) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Tasador", T) end')
    toc = [l.strip() for l in (D / "Tasador.toc").read_text(encoding="utf-8").splitlines() if l.strip().endswith(".lua")]
    for n in toc:
        cargar((D / n).read_text(encoding="utf-8"), n, T)
    L.execute('Fire("ADDON_LOADED", "Tasador")')
    return L, T


def chat(L):
    return [str(x) for x in L.globals().chat.values()]


def limpiar(L):
    L.execute("chat = {}")


def tabla(L, d):
    """dict de Python -> tabla de Lua (recursivo)."""
    t = L.table()
    for k, v in d.items():
        t[k] = tabla(L, v) if isinstance(v, dict) else v
    return t


# ================================================================ C16: archivos y orden
toc = (D / "Tasador.toc").read_text(encoding="utf-8")
orden = [l.strip() for l in toc.splitlines() if l.strip().endswith(".lua")]
check(orden.index("Reglas.lua") < orden.index("Comercio.lua") < orden.index("Escaneo.lua") < orden.index("Oportunidades.lua") < orden.index("Comandos.lua"),
      "toc: Comercio antes de Escaneo; Recetas y Oportunidades antes de Comandos")
check("Recetas.lua" in orden and "## Version: 0.4.0" in toc, "toc 0.4.0 con Recetas.lua")

# ================================================================ C12 (estático): nada que compre ni publique
for archivo in sorted(D.glob("*.lua")):
    texto = archivo.read_text(encoding="utf-8")
    codigo = sin_comentarios(texto)
    hallado = [p for p in PROHIBIDAS if re.search(r"\b" + p + r"\b", codigo)]
    check(not hallado, f"{archivo.name} no llama a {hallado}")
    # un nombre armado con texto (_G["Post".."Auction"]) no lo ve la búsqueda: _G[...] solo en la lectura de
    # textos del juego de Juego.lua (ITEM_SOULBOUND...), que no se llama.
    dinamico = [l for l in codigo.splitlines() if "_G[" in l and "local t = _G[clave]" not in l]
    check(not dinamico, f"{archivo.name}: sin _G[...] dinámico ({dinamico})")
# control: un "--" dentro de un texto no esconde una compra
check(re.search(r"\bPostAuction\b", sin_comentarios('local a = "x--y"; PostAuction(1)')), "control: el texto con -- no esconde la llamada")

# ================================================================ C15: estética en lo nuevo
for n in ("Comercio.lua", "Recetas.lua", "Oportunidades.lua"):
    src = (D / n).read_text(encoding="utf-8")
    codigo = "\n".join(l.split("--")[0] for l in src.splitlines())
    check("|cff" not in codigo and "GameFont" not in codigo and "SetFont" not in codigo and "Template" not in codigo,
          f"{n}: sin colores fijos, GameFont ni plantillas propias (E2-E4)")

# ================================================================ C1: percentil 20 y subastas distintas
L, T = nuevo()
G = L.globals()
lista = L.eval("{ {100, 10}, {50, 2}, {80, 8}, {200, 80} }")  # 100 unidades: el 20 % más barato (20 u) llega hasta 100
check(T.Percentil(lista, 0.2) == 100, "percentil 20 por unidades")
buf = L.table()
T.SumarSubasta(buf, 2447, 2, 100, "Ana", 4)
T.SumarSubasta(buf, 2447, 8, 640, "Beto", 3)
T.SumarSubasta(buf, 2447, 90, 18000, "Caro", 2)
T.SumarSubasta(buf, 2447, 5, 0, "Dani", 4)  # solo puja
precios = L.table()
T.GuardarEscaneo(precios, buf, 3000, L.eval('function() return "hierba" end'))
e = precios["2447"]
check(e.p["3000"] == 200 and e.n["3000"] == 3 and e.l["3000"] == 50 and e.a["3000"] == 100,
      f"guarda p20={e.p['3000']}, subastas={e.n['3000']}, mínimo y unidades")
check(e.k == "hierba", "categoría para eventos")
check(buf[2447].foto["Ana"][50][4] == 2 and buf[2447].foto["Caro"][200][2] == 90, "foto por vendedor, precio y tramo")
# 60 días para la categoría de eventos, 14 para el resto
T.GuardarEscaneo(precios, L.table(), 3030)
check(precios["2447"].p["3000"] == 200 and precios["2447"].l["3000"] is None, "p de hierbas dura 60 días; el mínimo, 14")
T.GuardarEscaneo(precios, L.table(), 3061)
check(precios["2447"].p["3000"] is None, "y a los 60 se borra")

# ================================================================ C3: ventas por desaparición (simulación)
F = lambda d: tabla(L, d)
vieja = F({100: {"Ana": {50: {4: 20}}, "Beto": {55: {3: 10}}, "Caro": {60: {1: 5}}, "Dani": {70: {4: 10}}},
           200: {"?": {30: {4: 6}}}})
nueva = F({100: {"Ana": {50: {4: 12}}, "Dani": {68: {4: 10}}},
           200: {"?": {30: {4: 2}}}})
v = T.CompararFotos(vieja, nueva, 90 * 60)
# Ana vendió 8 (50). Beto (55) desapareció, pero queda Ana más barata a 50: quien compra se lleva primero lo
# más barato, así que eso fue una cancelación -> 0 (v2). Caro, tramo corto: pudo vencer -> 0. Dani republicó: 0.
check(v[100].u == 8 and abs(v[100].c - 8 * 50) < 0.01, f"ventas del 100: {v[100].u} u, {v[100].c} c (esperado 8, 400)")
# compradores que se llevan de lo más barato hacia arriba: Ana entera y 6 de Beto
r = T.CompararFotos(F({1: {"Ana": {50: {4: 20}}, "Beto": {55: {4: 10}}}}), F({1: {"Beto": {55: {4: 4}}}}), 3600)
check(r[1].u == 26, "compras de lo más barato hacia arriba: 20 + 6")
# cancelación de lo caro con lo barato todavía ahí: no es venta (hallazgo ALTA del revisor de economía)
r = T.CompararFotos(F({1: {"Ana": {120: {4: 20}}, "Beto": {100: {4: 10}}}}), F({1: {"Beto": {100: {4: 10}}}}), 3600)
check(r[1].u == 0, "cancelar lo caro mientras lo barato sigue: 0")
# las subastas del jugador no miden al mercado
r = T.CompararFotos(F({1: {"Hope": {10: {4: 5}}}}), F({}), 3600, "Hope")
check(r[1].u == 0, "tus propias subastas no cuentan")
check(v[200].u == 4, "vendedor desconocido: se cuenta juntando")
v8 = T.CompararFotos(vieja, nueva, 8 * 3600)
check(v8[100].u == 0, "con 8 h todo lo de tramo largo o muy largo pudo vencer: 0 (control negativo)")
check(T.CompararFotos(vieja, nueva, 9 * 3600) is None, "más de 8 h: no estima ni cuenta horas observadas")
# dueño conocido en una foto y desconocido en la otra (hallazgo ALTA del revisor de Lua): 0, no 20
r = T.CompararFotos(F({1: {"Ana": {50: {4: 20}}}}), F({1: {"?": {50: {4: 20}}}}), 3600)
check(r[1].u == 0, "Ana en una foto y '?' en la otra: nadie vendió")
r = T.CompararFotos(F({1: {"?": {50: {4: 20}}}}), F({1: {"Ana": {50: {4: 15}}}}), 3600)
check(r[1].u == 5, "y si de verdad bajó, se cuenta con el tope del objeto entero")
# foto compacta (texto) de ida y vuelta
t = T.FotoTabla(T.FotoTexto(F({"Ana": {50: {4: 20, 3: 2}}, "Beto Cruz": {7: {0: 1}}})))
check(t["Ana"][50][4] == 20 and t["Ana"][50][3] == 2 and t["Beto Cruz"][7][0] == 1, "foto compacta: ida y vuelta")
r = T.CompararFotos(L.eval('{ [1] = "Ana\\t50\\t4\\t20" }'), L.eval('{ [1] = "Ana\\t50\\t4\\t12" }'), 3600)
check(r[1].u == 8, "CompararFotos lee la foto compacta")
check(T.CompararFotos(None, nueva, 3600) is None, "primera foto: no estima")
# vendedor que vende 5 y publica 5 nuevas a otro precio: tope por vendedor -> 0 (mínimo conservador)
r = T.CompararFotos(F({1: {"Eva": {10: {4: 5}}}}), F({1: {"Eva": {9: {4: 5}}}}), 3600)
check(r[1].u == 0, "republicar a otro precio no es venta")
# compra parcial de una subasta de materiales: baja la cantidad del mismo precio
r = T.CompararFotos(F({1: {"Eva": {10: {3: 20}}}}), F({1: {"Eva": {10: {3: 15}}}}), 3600)
check(r[1].u == 5, "compra parcial cuenta")
# lo que se vendió TODO: el objeto desaparece de la foto nueva
r = T.CompararFotos(F({1: {"Eva": {10: {4: 3}}}}), F({}), 3600)
check(r[1].u == 3, "si desaparece entero, cuenta")

# ================================================================ C3+C4 en el juego: dos escaneos reales
L, T = nuevo()
G = L.globals()
G.UsarModerna()
G.AuctionHouseFrame = L.table()
L.execute('Fire("AUCTION_HOUSE_SHOW")')
L.execute('ITEMS[2447] = { name = "Peacebloom", q = 1, sell = 5, cls = 7, sub = 9, stack = 20 }')
# tramo de la API moderna: 0 corto .. 3 muy largo
L.execute('SUBASTAS = { {2447, 20, 2000, "Ana", 3}, {2447, 10, 1100, "Beto", 2}, {2447, 4, 480, "Caro", 0} }')
G.TasadorBotonEscanear.click()
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")'); L.execute("RunTimers()")
check(any("Vuelve a escanear" in c for c in chat(L)), "primera foto: pide otro escaneo")
check(G.TasadorDB.precios["2447"].k == "hierba", "la hierba queda marcada para eventos")
L.execute("OFFSET = 3 * 3600")
L.execute('SUBASTAS = { {2447, 5, 500, "Ana", 3} }')  # Ana vendió 15; Beto 10 (tramo largo, 3 h < 2 h? no: 2 h <= 3 h, pudo vencer); Caro corto
limpiar(L)
G.TasadorBotonEscanear.click()
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")'); L.execute("RunTimers()")
dia = str(T.DiaHoy())
e = G.TasadorDB.precios["2447"]
check(type(G.TasadorDB.foto[2447]) == "str" or isinstance(G.TasadorDB.foto[2447], str), "la foto se guarda compacta (texto)")
check(e.v[dia] == 15 and e.o[dia] == 3 * 3600 and e.vc[dia] == 1500, f"ventas anotadas: {e.v[dia]} u, {e.vc[dia]} c en {e.o[dia]} s")
check(any("ventas estimadas anotadas" in c for c in chat(L)), "avisa que comparó")
liq = T.Liquidez(e, T.DiaHoy())
check(liq.midiendo and liq.ventasDia is None and liq.realizado == 100, "con 3 h vistas: 'midiendo', sin número de ventas por día")
e.o[dia] = 12 * 3600
liq = T.Liquidez(e, T.DiaHoy())
check(not liq.midiendo and abs(liq.ventasDia - 30) < 0.01, f"15 en 12 h = 30 al día ({liq.ventasDia})")

# ================================================================ C9: tendencia
L, T = nuevo()
def hist(L, serie, hoy, extra=None):
    e = {"h": {}, "l": {}, "a": {}, "p": {}}
    for i, p in enumerate(serie):
        d = str(hoy - len(serie) + 1 + i)
        e["p"][d] = p; e["l"][d] = p; e["h"][d] = p; e["a"][d] = 50
    if extra:
        e.update(extra)
    return tabla(L, e)
TEN = lambda serie: T.Tendencia(hist(L, serie, 3000), 3000)
check(TEN([100, 95, 90, 85])[0] == "bajando", "bajó 15 %: bajando")
check(TEN([100, 99, 98, 97])[0] == "estable", "bajó solo 3 %: no es 'bajando' (ruido)")
check(TEN([100, 90, 95, 85])[0] == "bajando", "una caída con un rebote sigue siendo caída (v2)")
check(TEN([100, 65, 66, 65])[0] == "bajando", "caída de 35 % con rebote de 1 %: bajando (sonda del revisor)")
check(TEN([100, 90, 80]) is None, "con 3 días no opina")
check(TEN([80, 90, 100, 115])[0] == "subiendo", "subiendo")
check(TEN([100, 104, 97, 101, 99, 103, 100])[0] == "estable", "ruido de ±4 %: estable")

# ================================================================ C6: comprar para revender
a = T.Ajustes()
check(T.Reventa(hist(L, [100, 102, 98, 100, 101], 3000, {"v": {"3000": 60}, "vc": {"3000": 6000}, "o": {"3000": 86400}}),
                F({"Ana": {60: {4: 10}}}), 5, 3000, 600, a, 2447, "Hope")[1] == "no hay margen", "ganancia de 3p 50c: menos de 1 oro, nada")
a.minGanancia = 100  # precios chicos en la prueba
liq_ok = {"v": {"3000": 60}, "vc": {"3000": 60 * 100}, "o": {"3000": 24 * 3600}}
base = lambda **kw: hist(L, [100, 102, 98, 100, 101], 3000, dict(liq_ok, **kw))
foto = F({"Ana": {60: {4: 10}}, "Beto": {98: {4: 30}}, "Caro": {150: {4: 50}}})
r = T.Reventa(base(), foto, 5, 3000, 600, a, 2447, "Hope")
if isinstance(r, tuple): print("motivo:", r)
check(r is not None and r.unidades == 10 and r.comprarHasta == 60, f"reventa: compra 10 a 60 ({r and r.unidades}, {r and r.comprarHasta})")
if r:
    neto = r.venta * 0.95 * 10 - 600 - r.perdidaDeposito - r.riesgo
    check(abs(r.ganancia - neto) < 0.01 and abs(r.pct - neto / 600) < 1e-9 and r.riesgo > 0, "margen en oro y en % con comisión, depósito y riesgo")
    check(r.venta == 98, f"revende al percentil 20 de lo que queda HOY (98), no al normal de antes (100): {r.venta}")
    check(abs(r.ventasDia - (60 - 1.2816 * 60 ** 0.5)) < 0.01, "usa el límite bajo de ventas por día (60 vistas -> ~50)")
    check(r.prob <= 1 and r.perdidaDeposito >= 0, "probabilidad y pérdida de depósito")
check(T.Reventa(base(), foto, 5, 3000, 4000, a, 2447, "Hope")[1] == "escanea", "foto de hace más de 60 min: escanea")
check(T.Reventa(hist(L, [100], 3000, liq_ok), foto, 5, 3000, 600, a, 2447, "Hope")[0] is None, "historia corta: nada")
check(T.Reventa(hist(L, [130, 120, 110, 100], 3000, liq_ok), foto, 5, 3000, 600, a, 2447, "Hope")[1] == "el precio viene bajando", "precio bajando: nada")
poca = {"v": {"3000": 2}, "vc": {"3000": 200}, "o": {"3000": 24 * 3600}}
check(T.Reventa(hist(L, [100, 102, 98, 100], 3000, poca), foto, 5, 3000, 600, a, 2447, "Hope")[1] == "se vende poco", "poca liquidez: nada")
check(T.Reventa(hist(L, [100, 102, 98, 100], 3000), foto, 5, 3000, 600, a, 2447, "Hope")[0] is None, "liquidez sin medir: nada")
foto_justa = F({"Ana": {90: {4: 10}}})  # 95 - 90 = 5 %: menos del 10 %
check(T.Reventa(base(), foto_justa, 5, 3000, 600, a, 2447, "Hope")[0] is None, "margen de 5 %: es ruido, nada")
check(T.Reventa(base(), F({"Hope": {60: {4: 10}}}), 5, 3000, 600, a, 2447, "Hope")[0] is None, "no te propone comprar tus propias subastas")
# nunca más de lo que se vende en un día
r = T.Reventa(base(), F({"Ana": {40: {4: 55}}, "Beto": {99: {4: 20}}, "Caro": {150: {4: 100}}}), 5, 3000, 600, a, 2447, "Hope")
check(not isinstance(r, tuple) and r.unidades == 50, "tope: compra solo lo que se vende en un día (50 de 55)")
r = T.Reventa(base(), F({"Ana": {40: {4: 80}}}), 5, 3000, 600, a, 2447, "Hope")
check(isinstance(r, tuple), "si después de tu compra quedan 30 a 40, ese es el precio de hoy: nada")
r = T.Reventa(hist(L, [100, 80, 60], 3000, liq_ok), F({"Ana": {60: {4: 16}}, "Beto": {70: {4: 100}}}), 5, 3000, 600, a, 2447, "Hope")
check(isinstance(r, tuple), "100 -> 80 -> 60 con el mercado de hoy a 70: nada (sonda del revisor)")
r = T.Reventa(base(), F({"Ana": {40: {4: 55}}, "Beto": {99: {4: 300}}}), 5, 3000, 600, a, 2447, "Hope")
check(isinstance(r, tuple), "si tardaría más de 2 días en venderse: nada (riesgo de inventario)")
r = T.Reventa(base(), F({"Ana": {40: {4: 500}}}), 5, 3000, 600, a, 2447, "Hope")
check(isinstance(r, tuple), "si quedan 440 baratas delante de ti, no conviene: nada")
# el depósito que se pierde puede matar la operación: vendedor caro (depósito alto) y poca prob.
caro = T.Reventa(base(), F({"Ana": {80: {4: 10}}, "Beto": {99: {4: 3000}}}), 400, 3000, 600, a, 2447, "Hope")
check(isinstance(caro, tuple), "con depósito alto y 3.000 delante en la fila, no hay operación")

# ================================================================ C7: reventa al vendedor
v = T.ReventaVendedor(F({"Ana": {80: {4: 3}}, "Beto": {220: {4: 5}}}), 200, 600, a, 1, "Hope")
check(v is not None and v.unidades == 3 and v.ganancia == 360 and v.comprarHasta == 80, "subastas bajo el pago del PNJ")
check(T.ReventaVendedor(F({"Ana": {80: {4: 3}}}), 100, 7200, a, 1, "Hope")[1] == "escanea", "foto vieja: escanea")
check(T.ReventaVendedor(F({"Ana": {80: {4: 3}}}), 0, 600, a, 1, "Hope") is None, "el PNJ no lo compra: nada")

# ================================================================ C8: consejo de venta
c = T.ConsejoVenta(hist(L, [13000, 12000, 11000, 10000], 3000), F({"Ana": {10000: {4: 5}}}), 1, 3000, 600, a, "Hope")
check(c.accion == "vende ya" and c.precio == 10000, "bajando: VENDE YA")
c = T.ConsejoVenta(hist(L, [10000, 10100, 9900, 10000], 3000), F({"Ana": {6000: {4: 5}}, "Beto": {10000: {4: 100}}}), 1, 3000, 600, a, "Hope")
check(c.accion == "espera" and c.precio == 10000, "unos pocos rematan a 60p y la mayoría está a 1o: espera")
c = T.ConsejoVenta(hist(L, [10000, 10100, 9900, 10000], 3000), F({"Ana": {6000: {4: 100}}, "Beto": {6500: {4: 50}}}), 1, 3000, 600, a, "Hope")
check(c.accion == "vende", "todo el mercado de hoy está abajo: vende (no 'espera'; sonda del revisor)")
c = T.ConsejoVenta(hist(L, [10000, 8000, 6000], 3000), F({"Ana": {6000: {4: 5}}, "Beto": {10000: {4: 100}}}), 1, 3000, 600, a, "Hope")
check(c.accion != "espera", "sin tendencia medida (3 días) nunca dice 'espera'")
c = T.ConsejoVenta(hist(L, [10000, 10100, 9900, 10000], 3000), F({"Ana": {1: {4: 1}}, "Beto": {8700: {4: 100}}}), 1, 3000, 600, a, "Hope")
check(c.precio == 8700, "una unidad suelta a 1 cobre no fija el precio (percentil 20)")
c = T.ConsejoVenta(hist(L, [10000, 10100, 9900, 10000], 3000, liq_ok), F({"Ana": {9500: {4: 30}}, "Beto": {9800: {4: 40}}}), 1, 3000, 600, a, "Hope")
check(c.accion == "vende" and c.precio == 9800 and c.cuantas == 50, f"vende en el escalón donde lo de delante pasa de un día de ventas ({c.precio}, {c.cuantas})")
c = T.ConsejoVenta(hist(L, [1007, 1007, 1007, 1007], 3000), F({"Ana": {1060: {4: 300}}}), 1000, 3000, 600, a, "Hope", 20)
check(c.accion == "vendedor", "subasta apenas sobre el PNJ, con depósito y fila: al vendedor (sonda del revisor)")
c = T.ConsejoVenta(hist(L, [10, 10, 10, 10], 3000), F({"Ana": {10: {4: 5}}}), 20, 3000, 600, a, "Hope")
check(c.accion == "vendedor", "si el PNJ paga más: al vendedor")
check(T.ConsejoVenta(hist(L, [10, 10], 3000), None, 1, 3000, None, a, "Hope")[1] == "escanea", "sin foto: escanea (C13)")

# ================================================================ C10: fabricar
receta = L.eval("{ producto = 900, n = 1, mats = { {10, 2}, {11, 1} } }")
precio = L.eval("function(id) local p = { [10] = 30, [11] = 20, [900] = 200 }; return p[id] end")
f = T.Fabricar(receta, precio, a)
check(abs(f.costo - 80) < 0.01 and f.sinLiquidez and abs(f.ganancia - (200 * 0.95 - 100 - 80)) < 0.01,
      f"margen de una receta con depósito supuesto ({f.ganancia})")
nada = T.Fabricar(receta, precio, a, None, L.eval("function() return { midiendo = false, ventasDia = 0, ventasDiaBaja = 0, horas = 20 } end"))
check(nada.noSeVende and nada.ganancia is None, "producto medido que no se vende: 'no se vende', no 'sin medir'")
a2 = T.Ajustes(); a2.horasPublicacion = 48
check(T.Deposito(1, 100, 10, a2) == 4 * T.Deposito(1, 100, 10, a) / 2 * 1, "el depósito sube con la duración (48 h = 4 veces 12 h)")
falta = T.Fabricar(receta, L.eval("function(id) if id == 10 then return 30 end end"), a)
check(falta.falta is not None and falta.ganancia is None, "falta el precio: sin margen (C13)")

# ================================================================ C11: eventos
def evento(L, T, dia, cambios):
    precios = {}
    i = 0
    for k, cambio in cambios.items():
        for j in range(cambios[k][1]):
            i += 1
            e = {"h": {}, "l": {}, "a": {}, "p": {}, "k": k}
            for d in range(dia - 7, dia + 7):
                e["p"][str(d)] = 100 if d < dia else 100 * (1 + cambio[0])
            precios[str(5000 + i)] = e
    return tabla(L, precios)
m = T.MedirEvento(evento(L, T, 3100, {"hierba": (0.30, 6), "consumible": (0.10, 6), "control": (-0.10, 6)}), 3100)
check(abs(m.grupos["hierba"].cambio - 0.30) < 1e-9 and abs(m.efecto["hierba"] - 0.40) < 1e-9 and abs(m.efecto["consumible"] - 0.20) < 1e-9,
      "evento: cambio de cada grupo menos el control")
m = T.MedirEvento(evento(L, T, 3100, {"hierba": (0.30, 4), "control": (0.0, 6)}), 3100)
check(m.grupos["hierba"].cambio is None and m.efecto["hierba"] is None, "con 4 objetos no se mide")

# ================================================================ juego: recetas y vendedores
L, T = nuevo()
G = L.globals()
L.execute(r'''
ITEMS[118] = { name = "Poción de sanación menor", q = 1, sell = 5, cls = 0, sub = 1, stack = 5 }
ITEMS[2447] = { name = "Peacebloom", q = 1, sell = 1, cls = 7, sub = 9, stack = 20 }
ITEMS[765] = { name = "Silverleaf", q = 1, sell = 1, cls = 7, sub = 9, stack = 20 }
ITEMS[3371] = { name = "Vial vacío", q = 1, sell = 1, cls = 7, sub = 11, stack = 20 }
GetTradeSkillLine = function() return "Alquimia" end
GetNumTradeSkills = function() return 2 end
GetTradeSkillInfo = function(i) if i == 1 then return "Pociones", "header" end return "Poción", "easy" end
GetTradeSkillItemLink = function(i) return "|Hitem:118|h[x]|h" end
GetTradeSkillNumMade = function() return 1, 1 end
GetTradeSkillNumReagents = function() return 3 end
local R = { {2447, 1}, {765, 1}, {3371, 1} }
GetTradeSkillReagentInfo = function(i, r) return "x", "", R[r][2], 0 end
GetTradeSkillReagentItemLink = function(i, r) return "|Hitem:" .. R[r][1] .. "|h[x]|h" end
UNITS.player = { name = "Hope" }
GetRealmName = function() return "Forever" end
''')
L.execute('Fire("TRADE_SKILL_SHOW")')
rec = G.TasadorDB.recetas["Hope-Forever"]
check(rec is not None and rec[118] is not None and rec[118].mats[3][1] == 3371 and rec[118].prof == "Alquimia", "lee las recetas de la ventana antigua")
check(any("Anoté 1 recetas de Alquimia" in c for c in chat(L)), "avisa una vez")
L.execute(r'''
GetMerchantNumItems = function() return 2 end
GetMerchantItemLink = function(i) return i == 1 and "|Hitem:3371|h[x]|h" or "|Hitem:999|h[x]|h" end
GetMerchantItemInfo = function(i) if i == 1 then return "Vial", "", 20, 5, -1, true, true, false end return "Ficha", "", 0, 1, -1, true, true, true end
''')
L.execute('Fire("MERCHANT_SHOW")')
check(G.TasadorDB.precioPNJ["3371"] == 4 and G.TasadorDB.precioPNJ["999"] is None, "precio del vendedor por unidad; sin monedas raras")
# moderna
L2, T2 = nuevo()
G2 = L2.globals()
L2.execute(r'''
UNITS.player = { name = "Hope" }
C_TradeSkillUI = {
  GetBaseProfessionInfo = function() return { professionName = "Cocina" } end,
  GetAllRecipeIDs = function() return { 7, 8 } end,
  GetRecipeInfo = function(id) return { learned = id == 7 } end,
  GetRecipeSchematic = function(id) return { outputItemID = 2680, quantityMin = 1,
     reagentSlotSchematics = { { reagents = { { itemID = 769 } }, quantityRequired = 1, reagentType = 1 },
                               { reagents = { { itemID = 2678 } }, quantityRequired = 1, reagentType = 1 } } } end,
}''')
L2.execute('Fire("TRADE_SKILL_LIST_UPDATE")')
r2 = G2.TasadorDB.recetas["Hope-"]
check(r2 is not None and r2[2680].mats[2][1] == 2678 and r2[2680].prof == "Cocina", "lee la ventana moderna (solo recetas aprendidas)")

# fabricar de punta a punta con precios de hoy y el vial del vendedor
hoy = T.DiaHoy()
G.TasadorDB.precios = tabla(L, {"2447": {"h": {}, "l": {}, "a": {}, "p": {str(hoy): 30}},
                                 "765": {"h": {}, "l": {}, "a": {}, "p": {str(hoy - 1): 20}},
                                 "118": {"h": {}, "l": {}, "a": {}, "p": {str(hoy): 300}}})
limpiar(L)
L.execute("SlashCmdList.TASADOR('fabricar')")
txt = "\n".join(chat(L))
check("Poción de sanación menor" in txt and "+" in txt and "materiales 54c" in txt, "fabricar: costo 30 + 20 + vial 4 = 54c y ganancia")

# ================================================================ C13: sin datos, "escanea"
L, T = nuevo()
for cmd in ("reventa", "pnj", "op"):
    limpiar(L)
    L.execute(f"SlashCmdList.TASADOR('{cmd}')")
    check(any("Escanear (Tasador)" in c for c in chat(L)), f"/tasador {cmd} sin escaneo: pide escanear")
limpiar(L)
L.execute("SlashCmdList.TASADOR('fabricar')")
check(any("abre la ventana de tu profesión" in c for c in chat(L)), "fabricar sin recetas: pide abrir la profesión")
limpiar(L)
L.execute("SlashCmdList.TASADOR('eventos')")
check(any("SIN VERIFICAR" in c for c in chat(L)), "eventos: dice que es hipótesis")
limpiar(L)
L.execute("SlashCmdList.TASADOR('ayuda')")
check(any("/tasador op" in c for c in chat(L)) and any("NO VERIFICADO" in c for c in chat(L)), "ayuda con los comandos nuevos y NO VERIFICADO")
L.execute("SlashCmdList.TASADOR('deposito 10')")
L.execute("SlashCmdList.TASADOR('duracion 48')")
check(T.Ajustes().depositoPct == 0.1 and T.Ajustes().horasPublicacion == 48, "ajustes de depósito y duración")


# ================================================================ escenario completo + ventana + C12 con trampas
def escenario(asistente):
    L, T = nuevo(asistente=asistente)
    G = L.globals()
    L.execute("PonerTrampas({" + ",".join(f'"{p}"' for p in PROHIBIDAS) + "})")
    G.UsarModerna()
    L.execute("PonerTrampas({" + ",".join(f'"{p}"' for p in PROHIBIDAS) + "})")  # también dentro de C_AuctionHouse
    G.AuctionHouseFrame = L.table()
    L.execute('Fire("AUCTION_HOUSE_SHOW")')
    L.execute(r'''
    UNITS.player = { name = "Hope" }
    ITEMS[2447] = { name = "Peacebloom", q = 1, sell = 5, cls = 7, sub = 9, stack = 20 }
    ITEMS[4306] = { name = "Silk Cloth", q = 1, sell = 150, cls = 7, sub = 5, stack = 20 }
    BAG = { 2447 }; STACK = { 20 }
    ''')
    hoy = T.DiaHoy()
    # historia: 5 días a ~100 y liquidez medida
    G.TasadorDB.precios = tabla(L, {"2447": {"h": {}, "l": {}, "a": {}, "k": "hierba",
                                             "p": {str(hoy - k): 5000 for k in range(1, 6)},
                                             "v": {str(hoy - 1): 40}, "vc": {str(hoy - 1): 200000}, "o": {str(hoy - 1): 16 * 3600}}})
    L.execute('SUBASTAS = { {2447, 20, 50000, "Ana", 3}, {2447, 40, 198000, "Beto", 3}, {4306, 3, 300, "Caro", 3} }')
    G.TasadorBotonEscanear.click()
    L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")'); L.execute("RunTimers()")
    # todos los eventos que registra el addon, sin ninguna pulsación
    for ev in ("TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_UPDATE", "MERCHANT_SHOW", "NAME_PLATE_UNIT_ADDED",
               "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "AUCTION_ITEM_LIST_UPDATE", "AUCTION_HOUSE_CLOSED", "AUCTION_HOUSE_SHOW"):
        L.execute(f'Fire("{ev}", "nameplate1")')
    for cmd in ("op", "reventa", "pnj", "vender", "fabricar", "eventos", "", "baratos", "hierbas"):
        L.execute(f"SlashCmdList.TASADOR('{cmd}')"); L.execute("RunTimers()")
    return L, T, G

L, T, G = escenario(asistente=False)
txt = "\n".join(chat(L))
if "-v" in sys.argv:
    print(txt)
check("compra 20 hasta 25p, revende a 49p 50c" in txt and "6 días, 16 h vistas" in txt, "reventa del escenario: 20 hasta 25p, revende al precio de hoy 49p 50c, con días y horas vistas")
check("vende al PNJ" in txt or "véndelas al PNJ" in txt, "seda bajo el precio del PNJ")
check("sanación" not in txt, "sin recetas no inventa ninguna")
check("La ventana necesita el addon Asistente" in txt, "sin Asistente: todo por el chat")
check(G.TRAMPAS == 0, f"C12: ninguna función de comprar/publicar llamada sin pulsación (llamadas: {G.TRAMPAS})")

L, T, G = escenario(asistente=True)
w = T._Ventana()
check(w is not None and w.visible, "ventana de oportunidades abierta (estilo de Asistente/Polestar)")
filas = [L.globals().tostring(w) for _ in range(0)]
textos = []
L.execute("RunTimers()")
vistas = T.RefrescarVentana()
check(vistas is not None and len(list(vistas.values())) >= 2, "la ventana ordena las oportunidades")
primero = vistas[1]
check("<bueno>" in str(primero.der), "la ganancia va con el color 'bueno' de la apariencia")
check(G.REPINTAR is not None, "se repinta al cambiar de apariencia (E3)")
check(G.TRAMPAS == 0, f"C12 con ventana: 0 llamadas ({G.TRAMPAS})")
# controles positivos: la trampa y el buscador SÍ detectan una llamada (si no, el 0 de arriba no mediría nada)
L.execute("C_AuctionHouse.PlaceBid(1, 1); PostAuction(1, 1)")
check(G.TRAMPAS == 2, "control: la trampa cuenta las llamadas")
falso = "local x = 1\nC_AuctionHouse.StartCommoditiesPurchase(2447, 20) -- comprar\n"
falso = "\n".join(l.split("--")[0] for l in falso.splitlines())
check(any(re.search(r"\b" + p + r"\b", falso) for p in PROHIBIDAS), "control: la búsqueda estática encuentra una compra")

# subasta ANTIGUA con las trampas puestas
L, T = nuevo()
G = L.globals()
L.execute(r'''
C_AuctionHouse = nil
CanSendAuctionQuery = function() return true, true end
QueryAuctionItems = function() end
GetNumAuctionItems = function() return #SUBASTAS, #SUBASTAS end
GetAuctionItemInfo = function(_, i) local s = SUBASTAS[i]
	return "x", 0, s[2], 1, true, 1, 0, 1, 1, s[3], 0, false, nil, s[4], s[4], 0, s[1], true end
GetAuctionItemTimeLeft = function(_, i) return SUBASTAS[i][5] end
SUBASTAS = { {2447, 20, 2000, "Ana", 4}, {2447, 5, 600, "Beto", 4} }
ITEMS[2447] = { name = "Peacebloom", q = 1, sell = 5, cls = 7, sub = 9, stack = 20 }
''')
L.execute("PonerTrampas({" + ",".join(f'"{p}"' for p in PROHIBIDAS) + "})")
T.Escanear(); L.execute('Fire("AUCTION_ITEM_LIST_UPDATE")'); L.execute("RunTimers()")
L.execute("OFFSET = 3600; SUBASTAS = { {2447, 5, 600, \"Beto\", 4} }")
T.Escanear(); L.execute('Fire("AUCTION_ITEM_LIST_UPDATE")'); L.execute("RunTimers()")
for cmd in ("op", "reventa", "pnj", "vender", "fabricar", "eventos"):
    L.execute(f"SlashCmdList.TASADOR('{cmd}')"); L.execute("RunTimers()")
check(G.TasadorDB.precios["2447"].v[str(T.DiaHoy())] == 20, "subasta antigua: tramos 1-4 y ventas estimadas (20 de Ana)")
check(G.TRAMPAS == 0, f"C12 con la subasta antigua: 0 llamadas ({G.TRAMPAS})")

print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
