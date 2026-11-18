"""Pruebas de Mamba_Bolsas 0.2 con Lua 5.1 (lupa).
Uso: python test_bolsas.py [carpeta de Mamba_Bolsas] [--romper]
--romper: control negativo; rompe a propósito cinco reglas (crear casillas en combate, leer la bolsa 5 como banco,
juntar dos "alternar" en dos, escribir campos propios en el botón del juego y comprar aunque atrase la montura)
y las pruebas TIENEN que fallar."""
import sys, pathlib, re
sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
args = [a for a in sys.argv[1:] if not a.startswith("--")]
ROMPER = "--romper" in sys.argv
D = pathlib.Path(args[0]) if args else AQUI.parent.parent.parent / "addon" / "Mamba_Bolsas"
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


# Lo que el cliente de Forever tiene y la simulación de mock_barras no: bolsas 0-5 (5 = componentes), banco por
# pestañas 6-8 (C_Bank), la plantilla del botón de la bolsa, temporizadores en cola, OnShow/OnHide, ganchos.
MOCK = r'''
local Marco = getmetatable(CreateFrame("Frame")).__index
function Marco:Show() if COMBATE and self.protegido then error("ADDON_ACTION_BLOCKED Show") end
	local antes = self.visible; self.visible = true
	if not antes and self.scripts.OnShow then self.scripts.OnShow(self) end end
function Marco:Hide() local antes = self.visible; self.visible = false
	if antes and self.scripts.OnHide then self.scripts.OnHide(self) end end
function Marco:IsShown() return self.visible end
function Marco:HookScript(k, fn)
	local viejo = self.scripts[k]
	self.scripts[k] = viejo and function(...) viejo(...); fn(...) end or fn
end
function Marco:SetID(i) self.id = i end
function Marco:GetID() return self.id or 0 end
function Marco:SetDesaturated() end
function Marco:SetPropagateKeyboardInput() end
function Marco:SetParent(p) self.padre = p end
function Marco:Click() if self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end end
function Marco:GetNumPoints() return self.punto and 1 or 0 end
function Marco:GetPoint() return unpack(self.punto or {}) end
function Marco:GetTop() return 500 end
function Marco:SetFrameStrata(s) self.estrato = s end
function Marco:GetFrameStrata() return self.estrato or "MEDIUM" end
function Marco:Raise() end
local CF = CreateFrame
CREADOS_EN_COMBATE = 0
PLANTILLAS = {}
function CreateFrame(tipo, nombre, padre, plantilla)
	if plantilla == "ContainerFrameItemButtonTemplate" then
		if COMBATE then CREADOS_EN_COMBATE = CREADOS_EN_COMBATE + 1 end
		PLANTILLAS[#PLANTILLAS + 1] = tipo
	end
	local f = CF(tipo, nombre, padre, plantilla)
	f.visible = (plantilla ~= nil and plantilla:find("Item") ~= nil) or tipo ~= "Frame" or nombre ~= nil or true
	if plantilla == "ContainerFrameItemButtonTemplate" then f.icon = f:CreateTexture(); f.Cooldown = f:CreateTexture(); f.IconBorder = f:CreateTexture() end
	return f
end
TIMERS = {}
C_Timer = { After = function(_, fn) table.insert(TIMERS, fn) end }
function Correr() local n = 0; while #TIMERS > 0 and n < 500 do local t = TIMERS; TIMERS = {}; for _, fn in ipairs(t) do fn() end; n = n + 1 end end
GANCHOS = {}
function hooksecurefunc(a, b, c)
	local nombre, fn = a, b
	if type(a) == "table" then return end
	local orig = _G[nombre]
	_G[nombre] = function(...) local r = { orig(...) }; fn(...); return unpack(r) end
end
function ToggleAllBags() ToggleBackpack() end
function ToggleBackpack() end
function ToggleBag() end
function OpenAllBags() end
function OpenBackpack() end
function OpenBag() end
function CloseAllBags() end
function CloseBackpack() end
function ShowUIPanel(p) p:Show() end
function HideUIPanel(p) p:Hide() end
BankFrame = CreateFrame("Frame", "BankFrame", UIParent)
ContainerFrame1 = CreateFrame("Frame", "ContainerFrame1", UIParent)
ContainerFrameCombinedBags = CreateFrame("Frame", "ContainerFrameCombinedBags", UIParent)
NUM_CONTAINER_FRAMES = 1
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5
Enum = { BagIndex = { Backpack = 0, ReagentBag = 5, CharacterBankTab_1 = 6 }, BankType = { Character = 0 } }
CVARS = { combinedBags = "0" }
C_CVar = { GetCVar = function(k) return CVARS[k] end, SetCVar = function(k, v) CVARS[k] = v end }
TAM = { [0] = 16, [1] = 12, [2] = 12, [3] = 0, [4] = 0, [5] = 4, [6] = 48, [7] = 8, [8] = 10 }
function L(id, n, q) return { itemID = id, stackCount = n or 1, quality = q or 1, iconFileID = 100 + id,
	hyperlink = "|cffffffff|Hitem:" .. id .. "::::|h[" .. (NOMBRES[id] or ("O" .. id)) .. "]|h|r" } end
NOMBRES = { [2447] = "Hojaplata", [765] = "Flor de paz", [3821] = "Agria", [4306] = "Paño de seda", [117] = "Cecina dura", [9999] = "Gris roto", [1201] = "Espada buena" }
CLASES = { [2447] = 7, [765] = 7, [3821] = 7, [4306] = 7, [117] = 0, [9999] = 15, [1201] = 2 }
ITEMS = {
	[0] = { [1] = L(2447, 5), [2] = L(765, 3), [3] = L(9999, 1, 0), [4] = L(117, 4), [5] = L(1201, 1, 2) },
	[1] = { [1] = L(2447, 2) },
	[5] = { [1] = L(3821, 2) },
	[6] = { [1] = L(2447, 10), [2] = L(4306, 20) },
	[7] = { [1] = L(765, 7) },
}
ABIERTO = false
C_Container = {
	GetContainerNumSlots = function(b) if b >= 6 and not ABIERTO then return 0 end; return TAM[b] or 0 end,
	GetContainerItemInfo = function(b, s) if b >= 6 and not ABIERTO then return nil end; return ITEMS[b] and ITEMS[b][s] end,
	GetContainerItemID = function(b, s) local i = ITEMS[b] and ITEMS[b][s]; return i and i.itemID end,
	ContainerIDToInventoryID = function(b) return 30 + b end,
	GetContainerItemCooldown = function() return 0, 0, 0 end,
	SortBags = function() ORDENADO = (ORDENADO or 0) + 1 end,
	SortBank = function(t) ORDENADO_BANCO = t end,
	PickupContainerItem = function(b, s) table.insert(MOVIDOS, b .. ":" .. s) end,
}
MOVIDOS = {}
C_Bank = { FetchPurchasedBankTabData = function() return { { ID = 6, name = "Hierbas", icon = 1 }, { ID = 7, name = "Pestaña 2", icon = 2 }, { ID = 8, name = "Pestaña 3", icon = 3 } } end,
	CloseBankFrame = function() BANCO_CERRADO = (BANCO_CERRADO or 0) + 1 end }
NUEVOS = { ["0:4"] = true }
C_NewItems = { IsNewItem = function(b, s) return NUEVOS[b .. ":" .. s] or false end, RemoveNewItem = function(b, s) NUEVOS[b .. ":" .. s] = nil end }
C_Item = { GetItemNameByID = function(id) return NOMBRES[id] end,
	GetItemInfoInstant = function(id) return id, "t", "s", CLASES[id] == 2 and "INVTYPE_WEAPON" or "", 1, CLASES[id] or 15, 0 end,
	GetItemQualityColor = function(q) return 0.1 * q, 1, 1 end,
	GetItemIconByID = function(id) return 100 + id end,
	GetItemMaxStackSizeByID = function(id) return 20 end }
function GetInventoryItemLink(_, inv) return "|cffffffff|Hitem:4500::|h[Bolsa " .. inv .. "]|h|r" end
function GetInventoryItemTexture() return 133 end
function SetItemButtonTexture(b, t) b.tex = t end
function SetItemButtonCount(b, n) b.n = n end
function SetItemButtonDesaturated() end
function CooldownFrame_Set() end
function GetMoney() return 841200 end
function GetCoinTextureString(c) return c .. "c" end
LINEAS = {}
Polestar = { Hooks = { ItemLines = function(o, fn) HOOK = fn; return true end, AddLine = function(t, l) table.insert(LINEAS, l) end },
	QoL = { Marks = { Get = function(id) return MARCAS and MARCAS[id] end } },
	Gear = { Bags = { IsUpgrade = function(link) return link and link:find("item:1201") ~= nil end } },
	QuestDB = { IsItemNeeded = function(id) return id == 765 end } }
'''


def nuevo(antes=""):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute((AQUI / "mock_barras.lua").read_text(encoding="utf-8"))
    L.execute(MOCK)
    if antes:
        L.execute(antes)
    M = L.table()
    cargar = L.eval('function(src, name, M) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Bolsas", M) end')
    for n in ARCHIVOS:
        src = (D / n).read_text(encoding="utf-8")
        if ROMPER and n == "Ventana.lua":
            src = src.replace("if InCombatLockdown and InCombatLockdown() then falta = true; break end", "")
        if ROMPER and n == "Ventana.lua":
            src = src.replace("-- sin escribir campos propios en el botón del juego", "b.hasItem = d.id and true or nil --")
        if ROMPER and n == "Ventana.lua":
            src = src.replace("if InCombatLockdown and InCombatLockdown() and M.EsVivo(f) and f.lista then", "if false then")
        if ROMPER and n == "Banco.lua":
            src = src.replace("if ok and retrasa then", "if false then")
        if ROMPER and n == "Bolsas.lua":
            src = src.replace("if E and E.CharacterBankTab_1 then", "if false then").replace("return E and E.CharacterBankTab_1 or nil", "return nil")
        if ROMPER and n == "Reemplazo.lua":
            src = src.replace('if j.alternar then M.AbrirInventario(nil)', 'if j.alternar then M.AbrirInventario(nil); M.AbrirInventario(nil)')
        cargar(src, n, M)
    return L, M


def visibles(L, f):
    return L.eval('function(f) local n = 0; for _, m in pairs(f.marcos or {}) do for _, b in ipairs(m.botones) do if b.visible then n = n + 1 end end end; return n end')(f)


L, M = nuevo('MambaBolsasDB = { personajes = { ["Hope - Fé"] = { banco = { [3821] = 2 }, fechaBanco = "18-11-2026" } } }')
G = L.globals()
L.execute('Fire("PLAYER_LOGIN"); Correr()')
check(not list(G.ERRORES.values()), "errores al entrar: %s" % list(G.ERRORES.values())[:3])
p = G.MambaBolsasDB.personajes["Hope - Fé"]
check(p.banco is None, "la 0.1 guardó la bolsa 5 como banco: ese dato se borra")
check(p.bolsas[2447] == 7 and p.bolsas[3821] == 2, "bolsas guardadas, con la bolsa de componentes (5)")
check(p.slots[5] is not None and p.slots[5].n == 4, "bolsa 5 guardada casilla por casilla")
# banco por pestañas
L.execute('ABIERTO = true; Fire("BANKFRAME_OPENED"); Correr()')
p = G.MambaBolsasDB.personajes["Hope - Fé"]
check(p.banco is not None and p.banco[2447] == 10 and p.banco[4306] == 20 and p.banco[765] == 7, "banco = pestañas 6-8")
check(p.banco is not None and p.banco[3821] is None, "la bolsa 5 NO es banco")
check(p.slots[6] is not None and p.slots[6].nombre == "Hierbas", "nombre de la pestaña guardado")
check(L.eval("BankFrame.padre ~= UIParent and BankFrame.padre ~= nil"), "la ventana del banquero queda escondida (diminuta, sin cerrarse)")
fb = M.ventanas.banco
fi = M.ventanas.inventario
check(fb.visible and M.EsVivo(fb), "ventana del banco abierta, en vivo")
check(fi.visible, "con el banco se abren también las bolsas")
check(visibles(L, fb) == 66, "banco: 48+8+10 casillas, hay %s" % visibles(L, fb))
check(visibles(L, fi) == 44, "bolsas: 16+12+12+4 casillas, hay %s" % visibles(L, fi))
plantillas = list(G.PLANTILLAS.values())
check(len(plantillas) >= 110 and all(t == "ItemButton" for t in plantillas), "casillas con ContainerFrameItemButtonTemplate (ItemButton)")
padre_id = L.eval('function(f) local m = f.marcos[5]; local b = m.botones[1]; return b:GetParent():GetID(), rawget(b:GetParent(), "GetBagID") == nil, b:GetID() end')(fi)
check(tuple(padre_id) == (5, True, 1), "la casilla sabe su bolsa por el marco padre (SetID), sin funciones del addon en el camino del clic: %s" % (padre_id,))
L.execute('MambaBolsas.ventanas.banco:Hide()')
check(G.BANCO_CERRADO == 1, "cerrar la ventana del banco cierra el banco")
L.execute('ABIERTO = false; Fire("BANKFRAME_CLOSED"); Correr()')
check(L.eval("BankFrame.padre == UIParent"), "el banquero vuelve a su lugar")
check(not fb.visible, "ventana del banco cerrada")
# tecla B: alternar una sola vez aunque el juego llame a dos funciones
L.execute('MambaBolsas.ventanas.inventario:Hide(); ToggleAllBags(); Correr()')
check(fi.visible, "B abre las bolsas (ToggleAllBags + ToggleBackpack = un alternar)")
L.execute('ToggleAllBags(); Correr()')
check(not fi.visible, "B otra vez las cierra")
L.execute('OpenAllBags(); Correr()')
check(fi.visible, "vendedor/correo: OpenAllBags las abre")
L.execute('CloseAllBags(); Correr()')
check(not fi.visible, "CloseAllBags cierra las que abrió el juego (vendedor)")
L.execute('ToggleAllBags(); Correr(); OpenAllBags(); Correr(); CloseAllBags(); Correr()')
check(fi.visible, "las que abriste con B siguen abiertas al cerrar al vendedor")
L.execute('ToggleAllBags(); Correr()')
check(not fi.visible, "y B las cierra")
# el cerrojo de redibujo: un repintado parcial en espera no se come el completo
L.execute('''local f = MambaBolsas.ventanas.inventario; f:Show(); Correr()
COMPLETOS = 0; local orig = MambaBolsas.Dibujar; MambaBolsas.Dibujar = function(x) COMPLETOS = COMPLETOS + 1; return orig(x) end
Fire("ITEM_LOCK_CHANGED"); Fire("BAG_UPDATE_DELAYED"); Correr(); MambaBolsas.Dibujar = orig''')
check(G.COMPLETOS == 1, "parcial en espera + cambio de bolsas = un redibujo completo (%s)" % G.COMPLETOS)
L.execute('MambaBolsas.ventanas.inventario:Hide()')
check(L.eval("ContainerFrame1.padre ~= UIParent and ContainerFrameCombinedBags.padre ~= UIParent"), "las bolsas del juego quedan escondidas")
# una por una
L.execute('OpenAllBags(); Correr()')
L.execute('MambaBolsas.ventanas.inventario.celdas[2]:Click()')
check(visibles(L, fi) == 12 and fi.sola == 1, "clic en la bolsa 1 del pie: solo sus 12 casillas")
L.execute('MambaBolsas.ventanas.inventario.celdas[2]:Click()')
check(visibles(L, fi) == 44 and fi.sola is None, "otro clic: todas juntas")
L.execute('MambaBolsas.ventanas.inventario.celdas[1]:Click()')
check(fi.sola == 0 and visibles(L, fi) == 16, "clic en la mochila: solo la mochila")
L.execute('MambaBolsas.ventanas.inventario.celdas[1]:Click()')
# K104: la estructura de Bagnon
check(fi.titulo.texto == "Inventario de Hope", "título como Bagnon: %s" % fi.titulo.texto)
check(fi.retrato is not None and fi.botonRetrato is not None, "retrato (clic = otro personaje)")
check(len(list(fi.pestanas.values())) == 7, "filtros como pestañas en el borde")
check(L.eval("MambaBolsas.ventanas.inventario.filaBolsas.punto[5]") > -80, "la fila de bolsas va ARRIBA, bajo el buscador")
L.execute('MambaBolsas.ventanas.inventario.botonFila.scripts.OnClick(MambaBolsas.ventanas.inventario.botonFila); Correr()')
check(not fi.celdas[1].visible and G.MambaBolsasDB.opciones.verBolsas == False, "el botón esconde la fila de bolsas")
L.execute('MambaBolsas.ventanas.inventario.botonFila.scripts.OnClick(MambaBolsas.ventanas.inventario.botonFila); Correr()')
check(fi.celdas[1].visible, "y la vuelve a mostrar")
c = fi.celdas[1]
check(c.libres == 11 and c.total == 16, "pie: libres/total de la mochila (%s/%s)" % (c.libres, c.total))
check(fi.libresTexto.texto == "37/44", "pie: libres/total (%s)" % fi.libresTexto.texto)
check(fi.oroTexto.texto == "841200c", "pie: el oro (%s)" % fi.oroTexto.texto)
# resaltar al pasar el ratón
L.execute('local f = MambaBolsas.ventanas.inventario; f.celdas[4].scripts.OnEnter(f.celdas[4])')
resaltadas = L.eval('function(f) local n = 0; for i, b in pairs(f.mostrados) do if b.mamba and b.mamba.resalte.__vis then n = n + 1 end end; return n end')
check(fi.resalte == 5, "pasar el ratón por la bolsa 5 la resalta")
L.execute('local f = MambaBolsas.ventanas.inventario; f.celdas[4].scripts.OnLeave(f.celdas[4])')
check(fi.resalte is None, "al salir se apaga")
# filtros y buscador
alfa = L.eval('function(f, bolsa, casilla) for i, d in ipairs(f.lista) do if d.bolsa == bolsa and d.casilla == casilla then return f.mostrados[i].alfa or 1 end end end')
for ch in fi.pestanas.values():
    if ch.clave == "basura":
        L.eval('function(c) c.scripts.OnClick(c) end')(ch)
check(alfa(fi, 0, 3) == 1 and alfa(fi, 0, 1) < 0.5, "filtro Basura: lo gris se ve, la hierba se apaga")
for ch in fi.pestanas.values():
    if ch.clave == "equipo":
        L.eval('function(c) c.scripts.OnClick(c) end')(ch)
check(alfa(fi, 0, 5) == 1 and alfa(fi, 0, 4) < 0.5, "filtro Equipo")
for ch in fi.pestanas.values():
    if ch.clave == "consumibles":
        L.eval('function(c) c.scripts.OnClick(c) end')(ch)
check(alfa(fi, 0, 4) == 1 and alfa(fi, 0, 5) < 0.5, "filtro Consumibles")
for ch in fi.pestanas.values():
    if ch.clave == "materiales":
        L.eval('function(c) c.scripts.OnClick(c) end')(ch)
check(alfa(fi, 0, 1) == 1 and alfa(fi, 5, 1) == 1 and alfa(fi, 0, 4) < 0.5, "filtro Materiales")
for ch in fi.pestanas.values():
    if ch.clave == "mision":
        L.eval('function(c) c.scripts.OnClick(c) end')(ch)
check(alfa(fi, 0, 2) == 1 and alfa(fi, 0, 1) < 0.5, "filtro Misión (lo que pide una misión, según Polestar)")
for ch in fi.pestanas.values():
    if ch.clave == "nuevo":
        L.eval('function(c) c.scripts.OnClick(c) end')(ch)
check(alfa(fi, 0, 4) == 1 and alfa(fi, 0, 1) < 0.5, "filtro Nuevo")
L.execute('local f = MambaBolsas.ventanas.inventario; f.filtro = "todo"; f.texto = "hoja"; MambaBolsas.DibujarCasillas(f)')
check(alfa(fi, 0, 1) == 1 and alfa(fi, 1, 1) == 1 and alfa(fi, 0, 2) < 0.5, "buscador: 'hoja' encuentra Hojaplata en dos bolsas")
L.execute('local f = MambaBolsas.ventanas.inventario; f.texto = ""; MambaBolsas.DibujarCasillas(f)')
# marcas
marca = L.eval('function(f, bolsa, casilla, que) for i, d in ipairs(f.lista) do if d.bolsa == bolsa and d.casilla == casilla then local o = f.mostrados[i].mamba; return o[que].__shown end end end')
L.execute('''local M = MambaBolsas
for _, o in pairs({"marca","mejora","mejoraBrillo","mision","nuevo","resalte"}) do end''')
# las texturas del mock no guardan Show: se lee la decisión con las funciones de Filtros
check(M.Marca(L.eval('{ id = 9999, calidad = 0 }')) == "basura", "marca basura en lo gris")
L.execute('MARCAS = { [2447] = "keep" }')
check(M.Marca(L.eval('{ id = 2447, calidad = 1 }')) == "guardar", "marca guardar (Ctrl+Alt+clic de Polestar)")
L.execute('MARCAS = { [2447] = "junk" }')
check(M.Marca(L.eval('{ id = 2447, calidad = 1 }')) == "basura", "marca basura puesta por el jugador")
L.execute('MambaAPI = { Bolsas = function() return { { id = 4306, sug = "subastar" }, { id = 117, sug = "vendedor", elegido = "guardar" } } end }; MambaBolsas.RefrescarSugerencias()')
check(M.Marca(L.eval('{ id = 4306, calidad = 1 }')) == "subastar", "marca subastar (sugerencia del Tasador)")
check(M.Marca(L.eval('{ id = 117, calidad = 1 }')) == "guardar", "lo que eligió el jugador manda sobre la sugerencia")
check(M.EsMejora(L.eval('{ id = 1201, link = "item:1201" }')) and not M.EsMejora(L.eval('{ id = 2447, link = "item:2447" }')), "brillo de mejora: el veredicto de Polestar")
# lo nuevo se apaga al pasar el ratón
L.execute('local f = MambaBolsas.ventanas.inventario; for i, d in ipairs(f.lista) do if d.bolsa == 0 and d.casilla == 4 then f.mostrados[i].scripts.OnEnter(f.mostrados[i]) end end')
check(not G.NUEVOS["0:4"], "lo nuevo deja de serlo al pasar el ratón")
# combate: una bolsa nueva en combate
creados = G.CREADOS_EN_COMBATE
L.execute('COMBATE = true; TAM[3] = 10; ITEMS[3] = { [1] = L(2447, 1) }; Fire("BAG_UPDATE", 3); Fire("BAG_UPDATE_DELAYED"); Correr()')
check(G.CREADOS_EN_COMBATE == 0, "en combate NO se crean casillas (creadas: %s)" % G.CREADOS_EN_COMBATE)
L.execute('COMBATE = false; Fire("PLAYER_REGEN_ENABLED"); Correr()')
check(visibles(L, fi) == 54, "al salir de combate aparecen las 10 casillas nuevas (%s)" % visibles(L, fi))
check(not list(G.ERRORES.values()), "sin errores hasta aquí: %s" % list(G.ERRORES.values())[:3])
# el banco lejos del banquero (guardado) y otro personaje
L.execute('MambaBolsas.AbrirBanco(MambaBolsas.Clave()); Correr()')
check(fb.visible and not M.EsVivo(fb), "banco guardado: se ve sin estar en el banco")
n_guard = L.eval('function(f) local n = 0; for _, b in ipairs(f.guardados or {}) do if b.visible then n = n + 1 end end; return n end')(fb)
check(n_guard == 66, "banco guardado: 66 casillas (%s)" % n_guard)
check("visto el" in (fb.libresTexto.texto or "") and fb.titulo.texto == "Banco de Hope", "el pie dice cuándo se vio; el título no se alarga (%s | %s)" % (fb.titulo.texto, fb.libresTexto.texto))
link = L.eval('function(f) for _, b in ipairs(f.guardados) do if b.link then return b.link end end end')(fb)
check(link and "item:2447" in link, "casilla guardada con su enlace (cuadro del objeto y precio del Tasador)")
L.execute('MambaBolsas.ventanas.banco:Hide()')
check(G.BANCO_CERRADO == 1, "cerrar el banco guardado no le habla al banquero")
L.execute('MambaBolsasDB.personajes["Cazador - Fé"] = { oro = 5000, fecha = "17-11-2026", bolsas = { [2447] = 4 }, slots = { [0] = { n = 16, items = { [1] = "|cffffffff|Hitem:2447::|h[Hojaplata]|h|r;4" } } } }')
L.execute('local f = MambaBolsas.ventanas.inventario; f.dueno = "Cazador - Fé"; MambaBolsas.Dibujar(f)')
check(not M.EsVivo(fi) and visibles(L, fi) == 0, "otro personaje: sin casillas en vivo")
check("Cazador" in fi.titulo.texto, "título con el otro personaje: %s" % fi.titulo.texto)
L.execute('local f = MambaBolsas.ventanas.inventario; f.dueno = MambaBolsas.Clave(); MambaBolsas.Dibujar(f)')
# cuadro del objeto y buscador común
donde, total = M.Donde(2447)
check(total == 22, "dónde: Hope 8 (con la bolsa nueva) + banco 10 + Cazador 4 = %s" % total)
G.HOOK(L.table(), "item:2447", 2447)
check(any("Tienes 22" in l and "Cazador 4" in l for l in G.LINEAS.values()), "línea en el cuadro: %s" % list(G.LINEAS.values()))
res = list(M.Buscar("hoja").values())
check(len(res) == 1 and res[0].total == 22, "buscador entre personajes")
# ordenar y apilar
L.execute('MambaBolsas.ventanas.inventario.botonOrdenar.scripts.OnClick(MambaBolsas.ventanas.inventario.botonOrdenar)')
check(G.ORDENADO == 1, "Ordenar = el ordenado del juego (que también apila)")
L.execute('ABIERTO = true; MambaBolsas.bancoAbierto = true; MambaBolsas.Ordenar(true)')
check(G.ORDENADO_BANCO == 0, "ordenar el banco: SortBank(personaje)")
L.execute('ABIERTO = false; MambaBolsas.bancoAbierto = false')
plan = M.PlanApilar(L.eval('''{ { bolsa = 0, casilla = 1, id = 1, n = 5, max = 20 }, { bolsa = 0, casilla = 2, id = 2, n = 3, max = 20 },
  { bolsa = 1, casilla = 1, id = 1, n = 18, max = 20 }, { bolsa = 1, casilla = 2, id = 1, n = 4, max = 20 }, { bolsa = 1, casilla = 3, id = 3, n = 1, max = 1 } }'''))
pasos = [tuple(x.values()) for x in plan.values()]
check(len(pasos) == 2 and pasos[0] == (1, 2, 0, 1), "apilar: junta los montones a medias del mismo objeto (%s)" % pasos)
L.execute('C_Container.SortBags = nil; ITEMS[1][2] = L(2447, 3); TAM[1] = 12')
r = M.Ordenar(False)
L.execute('Correr()')
check(len(list(G.MOVIDOS.values())) >= 2, "sin SortBags: apila a mano (%s)" % list(G.MOVIDOS.values()))
L.execute('COMBATE = true')
okc, msg = M.Ordenar(False)
check(not okc and "combate" in msg, "en combate no se ordena")
L.execute('COMBATE = false')
# opciones
L.execute('MambaBolsasDB.opciones.columnas = 8; MambaBolsasDB.opciones.tamano = 30; MambaBolsas.Dibujar(MambaBolsas.ventanas.inventario)')
check(fi.anchoRejilla == 8 * 32 - 2, "columnas y tamaño cambian la rejilla (%s)" % fi.anchoRejilla)
escala = L.eval('function(f) for _, m in pairs(f.marcos) do for _, b in ipairs(m.botones) do if b.visible then return b.escala, b.w end end end end')(fi)
check(abs(escala[0] - 30 / 37) < 1e-6 and escala[1] is None, "las casillas del juego se ESCALAN (no se estiran): %s" % (escala,))
L.execute('TAM[6] = 98; TAM[7] = 98; TAM[8] = 98; ABIERTO = true; MambaBolsas.bancoAbierto = true; MambaBolsas.AbrirBanco(MambaBolsas.Clave()); Correr()')
alto = L.eval('MambaBolsas.ventanas.banco.h * (MambaBolsas.ventanas.banco.escala or 1)')
check(alto <= 1080, "un banco de 294 casillas cabe en la pantalla (alto %s)" % alto)
L.execute('ABIERTO = false; MambaBolsas.bancoAbierto = false; TAM[6] = 48; TAM[7] = 8; TAM[8] = 10; MambaBolsas.ventanas.banco:Hide()')
L.execute('MambaBolsasDB.opciones.escala = 0.8; MambaBolsasDB.opciones.fondo = 0.5; MambaBolsas.Dibujar(MambaBolsas.ventanas.inventario)')
check(fi.escala == 0.8 and fi.alfa == 0.5, "escala y transparencia")
L.execute('MambaBolsasDB.opciones.separar = true; MambaBolsas.Dibujar(MambaBolsas.ventanas.inventario)')
filas_sep = sum(1 for d in fi.lista.values() if d.filaNueva)
check(filas_sep >= 3, "separar: cada bolsa en fila nueva (%s)" % filas_sep)
L.execute('MambaBolsasDB.opciones.propia = false; MambaBolsas.AplicarReemplazo(); OpenAllBags(); Correr()')
check(not fi.visible and L.eval("ContainerFrame1.padre == UIParent") and G.CVARS.combinedBags == "1", "apagada: vuelven las bolsas del juego (unidas)")
check(not list(G.ERRORES.values()), "sin errores: %s" % list(G.ERRORES.values())[:3])

# Bagnon encendido: no se pisan, y se pregunta una vez
L2, M2 = nuevo('CARGADOS = { Bagnon = true, BagBrother = true }')
G2 = L2.globals()
L2.execute('Fire("PLAYER_LOGIN"); Correr(); OpenAllBags(); Correr()')
check(not M2.Activa() and not M2.ventanas.inventario.visible, "con Bagnon encendido manda Bagnon")
check(G2.MambaBolsasOtro is not None and G2.MambaBolsasOtro.visible, "pregunta '¿Usar las bolsas de Mamba?'")
check(G2.MambaBolsasDB.preguntado.Bagnon, "pregunta una sola vez")
check(not list(G2.ERRORES.values()), "sin errores con Bagnon: %s" % list(G2.ERRORES.values())[:3])

# En Interfaz (menú de Polestar)
L3, M3 = nuevo()
L3.execute('Polestar.UI = { Picker = {} }; function Polestar.UI.RegisterSection(s) SECCION = s; return true end; '
           'function Polestar.UI.ShowPicker() end; function Polestar.UI.Picker.ShowSection() end; function Polestar.UI.Picker.Render() end')
G3 = L3.globals()
L3.execute('Fire("PLAYER_LOGIN"); Correr()')
S = G3.SECCION
check(S is not None and S.key == "MambaInterfaz", "Bolsas dentro de Interfaz")
items, _ = S.nav()
check(any(i.label == "Bolsas" and i.heading for i in items.values()), "título Bolsas en el índice")
padre = L3.eval('function() local f = CreateFrame("Frame", nil, UIParent); f.w, f.h = 640, 480; return f end')()
S.build(padre)
for k in ["bolsas:buscar", "bolsas:Hope - Fé", "bolsas:opciones"]:
    S.onNav(k); S.render()
check(not list(G3.ERRORES.values()), "panel sin errores: %s" % list(G3.ERRORES.values())[:3])

# K102: el banco cuenta para los demás módulos
t = M.Tengo(2447)
check(t.bolsas == 8 and t.banco == 10 and t.otros == 4 and t.total == 22 and (t.bancoVisto or "").startswith("18-11"), "Tengo(): bolsas, banco y otros personajes (%s)" % dict(t))
check(M.Banco()[4306] == 20, "Banco(): el banco guardado")
L.execute('function GetMoney() return ORO end; ORO = 50000; C_Bank.FetchNextPurchasableBankTabData = function() return { tabCost = 100000 } end; C_Bank.CanPurchaseBankTab = function() return true end')
c = M.ConsejoPestana(3)
check(c and not c.conviene and "te faltan 5 o" in c.texto, "sin oro: dice cuánto falta (%s)" % (c and c.texto))
L.execute('ORO = 2000000')
c = M.ConsejoPestana(3)
check(c and c.conviene and "3 casillas libres" in c.texto and "5 %" in c.texto, "pocas casillas libres: conviene, con números (%s)" % (c and c.texto))
c = M.ConsejoPestana(30)
check(c and not c.conviene and "30 casillas libres" in c.texto, "con espacio: todavía no hace falta (%s)" % (c and c.texto))
L.execute('MambaPlan = { Estado = function() return {} end, RetrasaMontura = function(e, costo) return true, 400000 end }')
c = M.ConsejoPestana(2)
check(c and not c.conviene and "montura" in c.texto and "40 o" in c.texto, "si atrasa la montura, espera (R0 con Mi plan): %s" % (c and c.texto))
L.execute('MambaPlan = nil; C_Bank.CanPurchaseBankTab = function() return false end')
check(M.ConsejoPestana(2) is None, "sin pestañas por comprar: no se ofrece")
L.execute('MambaBolsasDB.opciones.propia = true; MambaBolsas.AplicarReemplazo(); C_Bank.CanPurchaseBankTab = function() return true end; ABIERTO = true; Fire("BANKFRAME_OPENED"); Correr()')
fb = M.ventanas.banco
check(fb.compra is not None and fb.compra.visible and "Comprar pestaña" in (fb.compra.boton.texto or ""), "botón Comprar pestaña en el banco en vivo")
L.execute('MambaBolsas.ventanas.banco.compra.boton.scripts.OnClick(MambaBolsas.ventanas.banco.compra.boton)')
check(L.eval("BankFrame.padre == UIParent"), "Comprar pestaña muestra la compra DEL JUEGO (el clic que paga es del jugador)")
check(G.BankFrame.estrato == "DIALOG", "la compra del juego queda ENCIMA de la ventana de Mamba")
L.execute('TAM[9] = 20; C_Bank.FetchPurchasedBankTabData = function() return { { ID = 6 }, { ID = 7 }, { ID = 8 }, { ID = 9 } } end; Fire("BANK_TABS_CHANGED"); Correr()')
check(L.eval("BankFrame.padre ~= UIParent"), "comprada la pestaña, el banquero del juego se vuelve a esconder")
check(G.BankFrame.estrato == "MEDIUM", "y recupera su estrato")
L.execute('ABIERTO = false; Fire("BANKFRAME_CLOSED"); Correr()')

# el buscador: una sola fila (arriba izquierda y arriba derecha), no estirado hasta el centro
anclas = L.eval("MambaBolsas.ventanas.inventario.buscador.punto[1]")
check(anclas == "TOPRIGHT", "buscador anclado arriba a la derecha (%s)" % anclas)
# en combate: un cambio de bolsas no mueve ni muestra casillas del juego; se rehace al salir
L.execute("""OpenAllBags(); Correr()
local Marco = getmetatable(CreateFrame("Frame")).__index
MOVIDAS = 0
local sp, sh = Marco.SetPoint, Marco.Show
Marco.SetPoint = function(self, ...) if self.vivo and COMBATE then MOVIDAS = MOVIDAS + 1 end; return sp(self, ...) end
Marco.Show = function(self, ...) if self.vivo and COMBATE then MOVIDAS = MOVIDAS + 1 end; return sh(self, ...) end
COMBATE = true; Fire("BAG_UPDATE_DELAYED"); Correr(); COMBATE = false""")
check(G.MOVIDAS == 0 and M.ventanas.inventario.pendiente, "en combate no se mueven casillas del juego (%s) y queda pendiente" % G.MOVIDAS)
L.execute('Fire("PLAYER_REGEN_ENABLED"); Correr()')
check(not M.ventanas.inventario.pendiente, "al salir de combate se rehace")

# poción en combate: nada del addon en el camino del clic de una casilla en vivo (riesgo de acción bloqueada).
# La prueba de verdad es en el juego; aquí se fija que el addon no ponga código ni campos propios en ese camino.
L.execute('OpenAllBags(); Correr()')
camino = L.eval("""function(f)
  local malos = {}
  local permitidos = { mamba = true, vivo = true, icon = true, Cooldown = true, IconBorder = true,
    ev = true, scripts = true, attr = true, nombre = true, padre = true, tipo = true, plantilla = true, visible = true,
    punto = true, escala = true, alfa = true, id = true, w = true, h = true, tex = true, n = true }
  for _, m in pairs(f.marcos) do for _, b in ipairs(m.botones) do
    for _, k in ipairs({ "OnClick", "PreClick", "PostClick", "OnMouseDown", "OnMouseUp", "OnDragStart", "OnReceiveDrag" }) do
      if b.scripts[k] then malos[#malos + 1] = k end
    end
    for k in pairs(b) do if not permitidos[k] then malos[#malos + 1] = "campo " .. tostring(k) end end
    for k in pairs(m) do if k ~= "botones" and type(m[k]) == "function" then malos[#malos + 1] = "marco." .. k end end
  end end
  return table.concat(malos, ",")
end""")(fi)
check(camino == "", "camino del clic limpio (scripts y campos del juego solamente): %s" % camino[:200])

# sin variables globales sueltas (solo las de Mamba_Bolsas y los nombres de sus marcos)
L4, M4 = nuevo()
antes = set(L4.eval('function() local t = {} for k in pairs(_G) do t[#t + 1] = k end return t end')().values())
L4.execute('Fire("PLAYER_LOGIN"); Correr(); OpenAllBags(); Correr(); ABIERTO = true; Fire("BANKFRAME_OPENED"); Correr()')
despues = set(L4.eval('function() local t = {} for k in pairs(_G) do t[#t + 1] = k end return t end')().values())
sueltas = [k for k in despues - antes if not re.match(r"^(MambaBolsas\w*|MambaInterfaz|ABIERTO|HOOK)$", str(k))]
check(not sueltas, "globales sueltas: %s" % sueltas)

# reglas de código
for n in ARCHIVOS:
    src = (D / n).read_text(encoding="utf-8")
    if n != "Ordenar.lua":
        check(not re.search(r"\b(PickupContainerItem|UseContainerItem|SplitContainerItem)\b", src), n + ": solo Ordenar.lua mueve objetos")
    check(not re.search(r"\bDeleteCursorItem\b", src), n + ": nunca borra objetos")
    check(not re.search(r"SLASH_|SlashCmdList", src), n + ": sin comandos")
    check(not re.search(r"\bBagnon\b.*(function|local)", src) or n == "Reemplazo.lua", n + ": código propio")
print(f"{ok} OK, {fail} FALLAN")
sys.exit(1 if fail else 0)
