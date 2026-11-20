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

# ---------- 8. A2 (20-11): «Ya estoy escaneando» + «no mandó la lista en 60 segundos», nunca escaneaba.
# Medido: Forever trae la subasta MODERNA (TasadorDB.diag) y la lista completa la da el servidor una vez cada 15 min
# por cuenta; pedida antes, no contesta. Ahora: tiempo restante real, respuesta tardía o sin evento, y por páginas.
RELOJ = r'''
-- reloj que avanza a mano y temporizador con demora: RunDelay(d) corre solo los de esa demora
SEG = 0
local t0 = time
function time(t) if t then return t0(t) end return t0() + SEG end
TIMERS2 = {}
C_Timer = { After = function(d, fn) table.insert(TIMERS2, { d, fn }) end }
function RunDelay(max)
	local hubo = true
	while hubo do
		hubo = false
		for k, x in ipairs(TIMERS2) do
			if x[1] == max then table.remove(TIMERS2, k); x[2](); hubo = true; break end
		end
	end
end
-- búsqueda por páginas simulada: PAGINAS = { { {id, cantidad, minimo}, ... }, ... } (una tabla por página)
BROWSE, MAS, PAGINAS, VISTAS = 0, 0, {}, 0
function ConPaginas()
	C_AuctionHouse.SendBrowseQuery = function(q) BROWSE = BROWSE + 1; QUERY = q; VISTAS = 1 end
	C_AuctionHouse.RequestMoreBrowseResults = function() MAS = MAS + 1; VISTAS = VISTAS + 1 end
	C_AuctionHouse.HasFullBrowseResults = function() return VISTAS >= #PAGINAS end
	C_AuctionHouse.GetBrowseResults = function()
		local r = {}
		for p = 1, math.min(VISTAS, #PAGINAS) do
			for _, x in ipairs(PAGINAS[p]) do
				table.insert(r, { itemKey = { itemID = x[1], itemLevel = 1 }, totalQuantity = x[2], minPrice = x[3] })
			end
		end
		return r
	end
end
'''


def nuevo_a2(paginas=True):
    L, T = nuevo()
    L.execute(RELOJ)
    G = L.globals()
    G.UsarModerna()
    if paginas:
        G.ConPaginas()
    G.AuctionHouseFrame = L.table()
    L.execute('Fire("AUCTION_HOUSE_SHOW")')
    return L, T, G


# puras (con el Escaneo.lua de antes del arreglo no existen: falla, no se cae)
if T.FaltaEspera is None or T.Reloj is None:
    check(False, "A2: faltan T.FaltaEspera / T.Reloj")
else:
    check(T.FaltaEspera(1000, 1060, 900) == 840 and T.Reloj(840) == "14:00", "A2: faltan 14:00 un minuto después del pedido")
    check(T.FaltaEspera(1000, 1900, 900) == 0 and T.FaltaEspera(None, 5, 900) == 0, "A2: pasados 15 min (o sin pedido) ya se puede")
    check(T.FaltaEspera(1000, 500, 900) == 0, "A2: un reloj que retrocede no deja el botón trabado")

# a) el caso de Cristian: el servidor no contesta -> a los 60 s sigue por páginas y GUARDA precios
L, T, G = nuevo_a2()
L.execute('PAGINAS = { { {2447, 20, 100}, {785, 2, 150} }, { {2447, 5, 80} } }')
check(T.Escanear() and G.PEDIDOS == 1, "A2a: el clic pide la lista completa")
T.Escanear()
check(any("pedí la lista hace" in c for c in chat(L)), "A2a: doble clic dice hace cuánto pidió y hasta cuándo espera")
L.execute('RunDelay(0)')
check(G.BROWSE == 0, "A2a (control): antes de los 60 s no escanea por páginas")
G.SEG = 60
L.execute('RunDelay(60)')
check(G.BROWSE == 1 and G.QUERY.searchString == "" and any("Sigo por páginas" in c for c in chat(L)), "A2a: a los 60 s sin lista sigue por páginas")
L.execute('Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")')
check(G.MAS == 1 and T.escaneo.activo, "A2a: pide la página siguiente")
L.execute('Fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")')
dia = str(T.DiaHoy())
p = G.TasadorDB.precios
check(p is not None and p["2447"] is not None and p["2447"].l[dia] == 80 and p["2447"].a[dia] == 25 and p["785"].l[dia] == 150,
      "A2a: precios guardados por páginas (mínimo por unidad y cantidad total)")
check(not T.escaneo.activo and any("Escaneo por páginas listo" in c and "14:" in c for c in chat(L)),
      "A2a: termina, suelta el botón y dice el tiempo real que falta para el completo")
check(p is not None and p["2447"] is not None and p["2447"].p is None and G.TasadorDB.foto is None, "A2a: por páginas no inventa percentil ni foto de ventas")
check(G.TasadorDB.ultimoEscaneo == T.DiaHoy(), "A2a: cuenta como día escaneado")
diag = G.TasadorDB.diagEscaneo
res = [diag[i].resultado for i in range(1, len(diag) + 1)]
check(res == ["pedida", "sin respuesta", "paginas"], f"A2a: cada intento queda en TasadorDB.diagEscaneo ({res})")

# b) otro clic dentro de los 15 min: NO pide la lista (no contestaría), dice cuánto falta y va por páginas
G.SEG = 300
L.execute('VISTAS = 0')
T.Escanear()
check(G.PEDIDOS == 1 and G.BROWSE == 2 and any("faltan 10:00" in c for c in chat(L)), "A2b: dentro de los 15 min dice «faltan 10:00» y va por páginas")
L.execute('Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED"); Fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")')
check(not T.escaneo.activo, "A2b: termina")
# control negativo: pasados los 15 min, SÍ pide la lista completa
G.SEG = 15 * 60 + 1
check(T.Escanear() and G.PEDIDOS == 2, "A2b (control): pasados los 15 min pide la lista completa otra vez")

# c) la lista completa llega TARDE (ya escaneando por páginas): se lee la completa (trae vendedores y foto)
L, T, G = nuevo_a2()
L.execute('PAGINAS = { { {2447, 1, 999} }, { {785, 1, 999} } }')
T.Escanear()
L.execute('RunDelay(60)')
L.execute('SUBASTAS = { {2447, 20, 2000}, {2447, 5, 400} }')
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")')
L.execute('RunDelay(0)')
L.execute('Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")')  # una página que llega después: ya no cuenta
L.execute('RunDelay(30)')
p = G.TasadorDB.precios
check(any("tarde" in c for c in chat(L)) and p["2447"].l[str(T.DiaHoy())] == 80 and p["785"] is None,
      "A2c: la respuesta tardía gana al escaneo por páginas")
check(G.TasadorDB.foto is not None and not T.escaneo.activo, "A2c: con la completa sí guarda la foto de ventas")

# d) la lista llega SIN evento: a los 60 s la ve en el cliente y la lee (no va por páginas)
L, T, G = nuevo_a2()
T.Escanear()
L.execute('SUBASTAS = { {2447, 4, 400} }')
L.execute('RunDelay(60)')
check(G.BROWSE == 0 and G.TasadorDB.precios["2447"].l[str(T.DiaHoy())] == 100, "A2d: lista sin evento: la lee igual")

# e) una página que nunca llega: a los 30 s guarda lo que hay y suelta el botón (no queda «Ya estoy escaneando»)
L, T, G = nuevo_a2()
L.execute('PAGINAS = { { {2447, 3, 90} }, { {785, 1, 50} } }')
T.Escanear()
L.execute('RunDelay(60)')
L.execute('Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")')
L.execute('RunDelay(30)')
check(not T.escaneo.activo and G.TasadorDB.precios["2447"] is not None and any("incompleto" in c for c in chat(L)),
      "A2e: página que no llega: guarda lo que hay y suelta el botón")
T.Escanear()
check(not any("Ya estoy escaneando" in c for c in chat(L)[-1:]), "A2e: el botón responde de nuevo")

# f) sin páginas en el cliente: mensaje con el tiempo real, nunca «Ya estoy escaneando» pegado
L, T, G = nuevo_a2(paginas=False)
T.Escanear()
G.SEG = 60
L.execute('RunDelay(60)')
check(not T.escaneo.activo and any("prueba de nuevo en 14:" in c for c in chat(L)), "A2f: sin respaldo dice cuánto falta de verdad")
check(not T.Escanear() and any("faltan 14:" in c for c in chat(L)[-1:]), "A2f: otro clic: «faltan» con el tiempo restante")

# g) cerrar la subasta a medias del escaneo por páginas: no queda pegado
L, T, G = nuevo_a2()
L.execute('PAGINAS = { { {2447, 3, 90} }, { {785, 1, 50} } }')
T.Escanear()
L.execute('RunDelay(60)')
L.execute('Fire("AUCTION_HOUSE_CLOSED")')
check(not T.escaneo.activo and not T.escaneo.tarde, "A2g: cerrar la subasta suelta el escaneo por páginas")
L.execute('Fire("REPLICATE_ITEM_LIST_UPDATE")')
check(not T.escaneo.activo, "A2g: una lista que llega después de cerrar no reabre nada")

# h) el diag guarda solo los últimos 10
L, T, G = nuevo_a2(paginas=False)
for k in range(12):
    G.SEG = k * 1000
    T.Escanear()
    L.execute('RunDelay(60)')
check(len(G.TasadorDB.diagEscaneo) == 10, "A2h: diagEscaneo guarda los últimos 10")

print(f"OK {ok} · FALLAS {fail}")
sys.exit(1 if fail else 0)
