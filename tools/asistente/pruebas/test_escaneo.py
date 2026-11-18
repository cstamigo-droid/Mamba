"""Pruebas del escaneo PROPIO de subasta del Tasador (Escaneo.lua), con Lua 5.1 (lupa).
Uso: python -I test_escaneo.py ../Tasador
"""
import pathlib
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

D = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).parent.parent / "Tasador"
AQUI = pathlib.Path(__file__).parent
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


EXTRA = r'''
-- Marcos con los métodos que usa el botón
local CF = CreateFrame
function CreateFrame(tipo, nombre, padre, plantilla)
	local f = CF()
	for _, m in ipairs({"SetSize","SetPoint","SetText","Show","Hide"}) do f[m] = function() end end
	local orig = f.SetScript
	f.SetScript = function(self, n, fn) if n == "OnClick" then self.click = fn else orig(self, n, fn) end end
	if nombre then _G[nombre] = f end
	return f
end
-- Subasta moderna simulada: SUBASTAS = { {id, cantidad, compraYa}, ... }
SUBASTAS = {}
PEDIDOS = 0
function UsarModerna()
	QueryAuctionItems, GetNumAuctionItems, GetAuctionItemInfo = nil, nil, nil
	C_AuctionHouse = {
		ReplicateItems = function() PEDIDOS = PEDIDOS + 1 end,
		GetNumReplicateItems = function() return #SUBASTAS end,
		GetReplicateItemInfo = function(i) local s = SUBASTAS[i + 1]
			return "x", 0, s[2], 1, true, 1, 0, 1, 1, s[3], 0, false, nil, "v", "v", 0, s[1], true end,
	}
end
function UsarAntigua(puede)
	C_AuctionHouse = nil
	CanSendAuctionQuery = function() return true, puede end
	QueryAuctionItems = function(...) PEDIDOS = PEDIDOS + 1; ARGS = {...} end
	GetNumAuctionItems = function() return #SUBASTAS, #SUBASTAS end
	GetAuctionItemInfo = function(_, i) local s = SUBASTAS[i]
		return "x", 0, s[2], 1, true, 1, 0, 1, 1, s[3], 0, false, nil, "v", "v", 0, s[1], true end
end
'''


def nuevo(con_auctionator=False, cliente_antiguo=False):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_wow.lua").read_text(encoding="utf-8"))
    if cliente_antiguo:  # en un cliente con la subasta antigua esos eventos sí existen
        L.execute("EVENTOS_DESCONOCIDOS = {}")
    L.execute(EXTRA)
    if not con_auctionator:
        L.execute("Auctionator = nil")
    T = L.table()
    cargar = L.eval('function(src, name, T) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Tasador", T) end')
    toc = [l.strip() for l in (D / "Tasador.toc").read_text(encoding="utf-8").splitlines() if l.strip().endswith(".lua")]
    for n in toc:
        cargar((D / n).read_text(encoding="utf-8"), n, T)
    L.execute('Fire("ADDON_LOADED", "Tasador")')
    return L, T


def chat(L):
    return [str(x) for x in L.globals().chat.values()]


toc = (D / "Tasador.toc").read_text(encoding="utf-8")
check("Escaneo.lua" in toc and toc.index("Mercado.lua") < toc.index("Escaneo.lua") < toc.index("Juego.lua"), "Escaneo.lua en el toc, después de Mercado")

# ---------- 1. Nunca compra, vende, publica ni cancela
src = (D / "Escaneo.lua").read_text(encoding="utf-8")
codigo = "\n".join(l.split("--")[0] for l in src.splitlines())
prohibidas = ["PlaceAuctionBid", "PostAuction", "StartAuction", "PlaceBid", "ConfirmCommoditiesPurchase", "StartCommoditiesPurchase",
              "PostItem", "PostCommodity", "CancelAuction", "CancelSell", "ClickAuctionSellItemButton"]
check(not any(p in codigo for p in prohibidas), "el escaneo no llama a nada que compre, venda o publique")

# ---------- 2. Cálculo puro
L, T = nuevo()
buf = L.table()
T.SumarSubasta(buf, 2447, 20, 2000)      # 100 c/u
T.SumarSubasta(buf, 2447, 5, 400)        # 80 c/u: el más bajo
T.SumarSubasta(buf, 2447, 10, 0)         # solo puja: no cuenta
T.SumarSubasta(buf, 2449, 0, 100)        # cantidad 0: no cuenta
T.SumarSubasta(buf, None, 1, 100)        # sin id: no cuenta
check(buf[2447].min == 80 and buf[2447].cant == 25, f"mínimo por unidad y cantidad ({buf[2447].min}, {buf[2447].cant})")
check(buf[2449] is None, "subasta rara ignorada")
precios = L.table()
n = T.GuardarEscaneo(precios, buf, 2000)
check(n == 1 and precios["2447"].l["2000"] == 80 and precios["2447"].a["2000"] == 25, "guardado con día como texto (como Auctionator)")
buf2 = L.table()
T.SumarSubasta(buf2, 2447, 3, 270)       # 90 c/u, mismo día
T.GuardarEscaneo(precios, buf2, 2000)
check(precios["2447"].l["2000"] == 80 and precios["2447"].a["2000"] == 3, "dos escaneos el mismo día: queda el más bajo")
viejo = L.table()
T.SumarSubasta(viejo, 2447, 1, 50)
T.GuardarEscaneo(precios, viejo, 1980)
T.GuardarEscaneo(precios, L.table(), 2001)
check(precios["2447"].l["1980"] is None and precios["2447"].l["2000"] == 80, "borra lo de más de 14 días")

# Historial y "barato" funcionan con los datos propios (misma forma que Auctionator)
hist = L.table()
for dia, p in ((2010, 100), (2011, 110), (2012, 90), (2013, 60)):
    b = L.table()
    T.SumarSubasta(b, 785, 5, p * 5)
    T.GuardarEscaneo(hist, b, dia)
h = T.Historial(hist["785"], None, 2013)
check(h is not None and h.hoy == 60 and abs(h.media - 100) < 0.01 and h.esHoy and h.disponible == 5, "T.Historial lee el escaneo propio")
check(T.EsBarato(h), "60 contra media 100: barato")

# ---------- 3. En el juego: subasta moderna
L, T = nuevo()
G = L.globals()
G.UsarModerna()
G.AuctionHouseFrame = L.table()
L.execute('Fire("AUCTION_HOUSE_SHOW")')
check(G.TasadorBotonEscanear is not None, "botón 'Escanear (Tasador)' en la subasta")
L.execute('SUBASTAS = { {2447, 20, 2000}, {2447, 5, 400}, {785, 2, 300} }')
for i in range(1, 1201):  # una lista grande: se lee en tandas
    L.execute(f'table.insert(SUBASTAS, {{ {10000 + i}, 1, 100 }})')
G.TasadorBotonEscanear.click()
check(G.PEDIDOS == 1 and T.escaneo.activo, "el clic pide la lista al servidor")
G.TasadorBotonEscanear.click()
check(G.PEDIDOS == 1 and any("Ya estoy escaneando" in c for c in chat(L)), "doble clic: no pide dos veces")
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")')
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")')  # el evento puede llegar dos veces
L.execute('RunTimers()')
check(G.TIMER_CALLS >= 2, "lee en tandas, sin congelar el juego")
dia = T.DiaHoy()
p = G.TasadorDB.precios
check(p["2447"].l[str(dia)] == 80 and p["785"].l[str(dia)] == 150, "precios guardados por unidad")
check(sum(1 for _ in p.keys()) == 1202, "todas las subastas leídas una sola vez")
check(any("Escaneo listo: 1202" in c for c in chat(L)) and not T.escaneo.activo, "avisa al terminar")
precio, dias = T.PrecioSubasta("|Hitem:2447::::::::|h[x]|h", 2447)[:2]
check(precio == 80 and dias == 0, f"sin Auctionator, el cuadro del objeto usa el precio propio ({precio}, {dias})")
r = T.PrecioSubasta("|Hitem:785:0:0:0:0:0:-12:0|h[x]|h", 785)
check(r[0] is None and "sufijo" in str(r[2]), "con sufijo aleatorio no adivina")

# cerrar la subasta a medias: no guarda
L, T = nuevo()
G = L.globals()
G.UsarModerna()
L.execute('SUBASTAS = { {2447, 20, 2000} }')
L.execute('for i = 1, 1200 do table.insert(SUBASTAS, { 20000 + i, 1, 100 }) end')  # más de una tanda
T.Escanear()
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")')
L.execute('Fire("AUCTION_HOUSE_CLOSED")')
L.execute('RunTimers()')
check(G.TasadorDB.precios is None or G.TasadorDB.precios["2447"] is None, "cerrada a medias: no se guarda nada")
check(any("a medias" in c for c in chat(L)), "y lo avisa")

# ---------- 4. Subasta antigua
L, T = nuevo(cliente_antiguo=True)
G = L.globals()
G.UsarAntigua(False)
check(not T.Escanear() and G.PEDIDOS == 0 and any("15 minutos" in c for c in chat(L)), "antigua: respeta la espera de 15 minutos del juego")
G.UsarAntigua(True)
L.execute('SUBASTAS = { {2447, 4, 400} }')
check(T.Escanear() and G.ARGS[7] is True, "antigua: pide todo (getAll)")
L.execute('Fire("AUCTION_ITEM_LIST_UPDATE")')
L.execute('RunTimers()')
check(G.TasadorDB.precios["2447"].l[str(T.DiaHoy())] == 100, "antigua: precio guardado")

# ---------- 5. /tasador baratos sin Auctionator usa la base propia
L, T = nuevo()
G = L.globals()
hoy = T.DiaHoy()
G.TasadorDB.precios = L.table()
for k, pr in enumerate((100, 110, 90, 60)):
    b = L.table()
    T.SumarSubasta(b, 2447, 5, pr * 5)
    T.GuardarEscaneo(G.TasadorDB.precios, b, hoy - 3 + k)
L.execute('ITEMS[2447] = { name = "Peacebloom", q = 1, sell = 5, cls = 7, sub = 9 }')
T.MostrarBaratos()
L.execute('RunTimers()')
check(any("Peacebloom" in c for c in chat(L)), "/tasador baratos funciona con el escaneo propio")
L, T = nuevo()
T.MostrarBaratos()
check(any("Escanear (Tasador)" in c for c in chat(L)), "sin precios: dice que aprietes el botón")

# ---------- 6. Hallazgos del revisor externo
# A2: con Auctionator instalado, gana el precio MÁS RECIENTE de los dos
L, T = nuevo(con_auctionator=True)
G = L.globals()
hoy = T.DiaHoy()
G.TasadorDB.precios = L.table()
b = L.table()
T.SumarSubasta(b, 2447, 1, 70)
T.GuardarEscaneo(G.TasadorDB.precios, b, hoy)
G.TasadorDB.ultimoEscaneo = hoy
L.execute('PRICES[2447] = 120; AGES = { [2447] = 6 }')     # Auctionator: de hace 6 días
r = T.PrecioSubasta("|Hitem:2447::::::::|h[x]|h", 2447)
check(r[0] == 70 and r[1] == 0, f"A2: el propio de hoy gana al de Auctionator de hace 6 días ({r[0]}, {r[1]})")
L.execute('AGES = { [2447] = 0 }')                          # Auctionator también de hoy: empate
r = T.PrecioSubasta("|Hitem:2447::::::::|h[x]|h", 2447)
check(r[0] == 120, "A2: mismo día: Auctionator")
L.execute('Auctionator.Database.db = {}')                   # instalado pero sin escanear
db, cual = T.BasePrecios()
check(cual == "propio", "A2: Auctionator vacío no tapa el escaneo propio")
L.execute('Auctionator.Database.db = { ["785"] = {} }')
G.TasadorDB.ultimoEscaneo = hoy - 5
db, cual = T.BasePrecios()
check(cual == "Auctionator", "A2: escaneo propio viejo: Auctionator")
G.TasadorDB.ultimoEscaneo = hoy - 1
check(T.BasePrecios()[1] == "propio", "A2: escaneo propio de ayer: el propio")
# B1: si el servidor no contesta, a los 60 s se suelta
L, T = nuevo()
G = L.globals()
G.UsarModerna()
T.Escanear()
check(T.escaneo.activo, "B1: escaneando")
L.execute('RunTimers()')  # el aviso de 60 s
check(not T.escaneo.activo and any("60 segundos" in c for c in chat(L)), "B1: sin respuesta, se suelta y avisa")

# ---------- 7. Segunda pasada del revisor
# 1: el botón se crea sin padre y se cuelga después
L, T = nuevo()
G = L.globals()
L.execute('''local CF2 = CreateFrame; PADRES = {}
CreateFrame = function(t, n, p, pl) table.insert(PADRES, p == nil); local f = CF2(t, n, p, pl); f.SetParent = function(self, x) self.colgado = x end; return f end''')
G.AuctionHouseFrame = L.table()
L.execute('Fire("AUCTION_HOUSE_SHOW")')
check(all(G.PADRES.values()) and G.TasadorBotonEscanear.colgado is not None, "botón de subasta creado sin padre y colgado con SetParent")
# 3: valores secretos en la lista: se saltan, no rompen el escaneo
L, T = nuevo()
G = L.globals()
G.UsarModerna()
L.execute('SUBASTAS = { {2447, SECRET, 400}, {785, 2, SECRET}, {SECRET, 1, 100}, {2449, 4, 40} }')
T.Escanear()
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")')
L.execute('RunTimers()')
p = G.TasadorDB.precios
check(not T.escaneo.activo and p["2449"] is not None and p["2447"] is None and p["785"] is None, "valores secretos: se saltan y el escaneo termina")
# 2: con 1 día escaneado no promete /tasador baratos
check(any("3 días distintos" in c and "llevas 1" in c for c in chat(L)), "avisa que faltan días para /tasador baratos")
# 9: lista vacía: no marca el día como escaneado
L, T = nuevo()
G = L.globals()
G.UsarModerna()
T.Escanear()
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")')
L.execute('RunTimers()')
check(G.TasadorDB.ultimoEscaneo is None and any("lista vacía" in c for c in chat(L)), "lista vacía: no se guarda ni cuenta como escaneo")
# 4: Auctionator con precio pero sin edad: gana Auctionator
L, T = nuevo(con_auctionator=True)
G = L.globals()
G.TasadorDB.precios = L.table()
b = L.table()
T.SumarSubasta(b, 2447, 1, 70)
T.GuardarEscaneo(G.TasadorDB.precios, b, T.DiaHoy() - 10)
L.execute('PRICES[2447] = 120; AGES = nil')
check(T.PrecioSubasta("|Hitem:2447::::::::|h[x]|h", 2447)[0] == 120, "Auctionator sin edad gana a un propio de hace 10 días")

print(f"OK {ok} · FALLAS {fail}")
sys.exit(1 if fail else 0)
