-- Medidor: lee el juego y suma en los cubos. Solo LEE; no hace nada por el jugador.
-- Funciones del juego usadas: todas aparecen en addons de Forever instalados (lista en MEDIDOR_LEEME.md).
-- Licencia GPL-3.0-only.
local NOMBRE, M = ...

local f = CreateFrame("Frame")
local base = {}          -- últimas lecturas: xp, max, dinero
local reloj = 0          -- para recalcular la clave cada 2 s
M.pausa = false
M.banco = false

-- Forever oculta algunos valores ("secretos", sobre todo en combate): compararlos da error.
-- Igual que Polestar (Core\Compat.lua), un valor secreto se lee como "no sé" (nil).
local function Legible(v)
	if v ~= nil and issecretvalue and issecretvalue(v) then return nil end
	return v
end
M.Legible = Legible

local function Pj() return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?") end

local function Zona()
	-- Dentro de una mazmorra, el nombre de la instancia (GetRealZoneText puede venir atrasado en la
	-- pantalla de carga). Igual que ForeverDungeonJournal (Systems\RunLog.lua).
	local enInst, tipo = IsInInstance()
	if enInst and (tipo == "party" or tipo == "raid") and GetInstanceInfo then
		local n = Legible((GetInstanceInfo()))
		if type(n) == "string" and n ~= "" then return n end
	end
	local z = GetRealZoneText()
	if not z or z == "" then return "?" end
	return z
end

-- Recalcula en qué cubo estamos (zona, actividad, nivel).
function M.ActualizarClave()
	local enInst, tipo = IsInInstance()
	local act = M.Actividad(enInst, tipo, M.pj and M.pj.act)
	local nivel = Legible(UnitLevel("player")) or 0
	-- Al subir de nivel, UnitLevel puede atrasarse: manda el nivel que trajo el evento.
	if M.nivelEvento and M.nivelEvento > nivel then nivel = M.nivelEvento end
	local zona = Zona()
	M.actual = { zona = zona, act = act, nivel = nivel, clave = M.Clave(zona, act, nivel) }
	M.RevisarPasada(enInst and act == "mazmorra", zona)
	return M.actual
end

-- Pasadas por mazmorra: cuenta cada vez que entras a una. Morir y volver corriendo a la misma
-- mazmorra antes de 15 minutos es la misma pasada, salvo que el juego avise que la reiniciaste. Al cargar el addon (o /reload) dentro de una
-- mazmorra no se cuenta: no se sabe si la pasada ya estaba contada.
M.MISMA_PASADA = 15 * 60
function M.RevisarPasada(dentro, zona)
	if M.dentro == nil then M.dentro = dentro; M.mazmorra = dentro and zona or nil; return end
	if dentro and not M.dentro then
		local misma = M.mazmorra == zona and M.salida and (time() - M.salida) < M.MISMA_PASADA
		if not misma then M.Sumar("pasadas", 1, true) end
		M.mazmorra = zona
	elseif M.dentro and not dentro then
		M.salida = time()
	end
	M.dentro = dentro
end

-- Devuelve los dos cubos donde se suma: el guardado (total) y el de esta sesión.
local function Cubos()
	local a = M.actual or M.ActualizarClave()
	local t = M.pj.cubos[a.clave]
	if not t then t = M.NuevoCubo(a.zona, a.act, a.nivel); M.pj.cubos[a.clave] = t end
	local s = M.sesion[a.clave]
	if not s then s = M.NuevoCubo(a.zona, a.act, a.nivel); M.sesion[a.clave] = s end
	return t, s
end

-- En pausa no se suma nada (pero las lecturas base sí se actualizan, para no sumarlo después).
function M.Sumar(campo, v, aunEnPausa)
	if v == 0 or (M.pausa and not aunEnPausa) then return end
	local t, s = Cubos()
	t[campo] = (t[campo] or 0) + v   -- "or 0": cubos guardados por la versión anterior no tienen "pasadas"
	s[campo] = (s[campo] or 0) + v
end

local function SumarProf(nombre, v)
	if M.pausa then return end
	local t, s = Cubos()
	t.prof[nombre] = (t.prof[nombre] or 0) + v
	s.prof[nombre] = (s.prof[nombre] or 0) + v
end

-- Inventario: bolsas (0 a NUM_BAG_SLOTS) + lo que llevas puesto (huecos 1 a 19). id -> cantidad.
function M.LeerInventario()
	local c = {}
	for b = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4) do
		for s = 1, (C_Container.GetContainerNumSlots(b) or 0) do
			local i = C_Container.GetContainerItemInfo(b, s)
			if i and i.itemID then c[i.itemID] = (c[i.itemID] or 0) + (i.stackCount or 1) end
		end
	end
	for s = 1, 19 do
		local id = GetInventoryItemID("player", s)
		if id then c[id] = (c[id] or 0) + 1 end
	end
	return c
end

-- Profesiones: id de la línea -> {nombre, rango}. Forever no tiene GetSkillLineInfo; se usa
-- GetProfessions/GetProfessionInfo como ForeverDungeonJournal y EllesmereUIDataBars.
function M.LeerProfesiones()
	local r = {}
	local lista = { GetProfessions() }
	for i = 1, select("#", GetProfessions()) do
		local idx = lista[i]
		if idx then
			local nombre, _, rango, _, _, _, id = GetProfessionInfo(idx)
			if nombre and id then r[id] = { nombre = nombre, rango = rango or 0 } end
		end
	end
	return r
end

local function InfoObjeto(id)
	local nombre, _, _, _, _, _, _, _, _, _, vendedor, _, _, liga = C_Item.GetItemInfo(id)
	if not nombre then
		if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
		return nil
	end
	return vendedor or 0, liga
end

local function PrecioSubasta(id)
	local api = Auctionator and Auctionator.API and Auctionator.API.v1
	if not api or not api.GetAuctionPriceByItemID then return nil end
	local ok, p = pcall(api.GetAuctionPriceByItemID, NOMBRE, id)
	return ok and p or nil
end

-- Precio de una unidad. Se usa el MISMO precio con que entró mientras lo tengas y hasta 3 días
-- después de que salga (si no, publicar en la subasta y recibirlo de vuelta, o recomprarlo,
-- contaría la subida de precio como botín).
M.OLVIDO = 3 * 86400
function M.Precio(id)
	local fijo = M.pj.precios[id]
	if fijo then return fijo.p end
	local p = M.PrecioUnidad(id, InfoObjeto, PrecioSubasta)
	if p then M.pj.precios[id] = { p = p, visto = time() } end
	return p
end

local function OlvidarPrecios(actual)
	local ahora = time()
	for id, f in pairs(M.pj.precios) do
		if type(f) ~= "table" then
			M.pj.precios[id] = nil
		elseif actual[id] and actual[id] > 0 then
			f.visto = ahora
		elseif ahora - (f.visto or 0) > M.OLVIDO then
			M.pj.precios[id] = nil
		end
	end
end

-- Toma el inventario actual como nuevo punto de partida SIN contarlo (banco, pantalla de carga),
-- pero conserva lo que esperaba precio: eso se contará cuando llegue el dato.
function M.Rebase()
	local nuevo = M.LeerInventario()
	local base = {}
	for id, c in pairs(nuevo) do base[id] = c end
	local ultimo, ids = M.ultimo or {}, {}
	for id in pairs(ultimo) do ids[id] = true end
	for id in pairs(M.inv) do ids[id] = true end
	for id in pairs(ids) do
		local pendiente = (ultimo[id] or 0) - (M.inv[id] or 0)
		if pendiente ~= 0 then base[id] = (base[id] or 0) - pendiente end
	end
	M.inv, M.ultimo = base, nuevo
end

function M.RevisarInventario()
	if M.banco then
		-- Con el banco abierto, lo que entra o sale de las bolsas es solo un traslado: no cuenta.
		M.Rebase()
		return
	end
	local actual = M.LeerInventario()
	M.ultimo = actual
	local v = M.DiffValor(M.inv, actual, M.Precio)
	if not M.pausa then M.Sumar("valor", v) end
	OlvidarPrecios(actual)
end

function M.RevisarProfesiones()
	for nombre, d in pairs(M.DiffProf(M.prof, M.LeerProfesiones())) do SumarProf(nombre, d) end
end

function M.TomarBase()
	base.xp, base.max, base.dinero = Legible(UnitXP("player")), Legible(UnitXPMax("player")), Legible(GetMoney())
	M.inv = M.LeerInventario()
	M.ultimo = M.inv
	M.inv = {}
	for id, c in pairs(M.ultimo) do M.inv[id] = c end
	M.prof = M.LeerProfesiones()
	M.ActualizarClave()
end

function M.Iniciar()
	MedidorDB = MedidorDB or {}
	MedidorDB.version = M.VERSION
	MedidorDB.pj = MedidorDB.pj or {}
	local p = MedidorDB.pj[Pj()]
	if not p then p = { cubos = {}, act = "misiones", precios = {} }; MedidorDB.pj[Pj()] = p end
	p.precios = p.precios or {}
	M.pj = p
	M.sesion = {}
end

-- "%s has been reset." -> patrón Lua (el texto viene en el idioma del cliente)
local function PatronReinicio()
	local t = INSTANCE_RESET_SUCCESS or "%s has been reset."
	t = t:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	return "^" .. t:gsub("%%s", "(.+)") .. "$"
end
function M.MensajeSistema(texto)
	texto = Legible(texto)
	if type(texto) ~= "string" then return end
	if texto:match(PatronReinicio()) then M.salida = nil end   -- la próxima entrada es pasada nueva
end

local manejar = {
	ADDON_LOADED = function(nombre) if nombre == NOMBRE then M.Iniciar() end end,
	PLAYER_ENTERING_WORLD = function()
		if not M.pj then M.Iniciar() end
		-- Solo la primera vez: en cada pantalla de carga se repite el evento y no hay que perder nada.
		if not M.listo then M.TomarBase(); M.listo = true else M.ActualizarClave() end
	end,
	PLAYER_XP_UPDATE = function()
		local xp, max = Legible(UnitXP("player")), Legible(UnitXPMax("player"))
		if not xp or not max then return end   -- secreto: se cuenta en la próxima lectura legible
		if base.xp then M.Sumar("xp", M.DeltaXP(base.xp, base.max, xp, max)) end
		base.xp, base.max = xp, max
	end,
	PLAYER_LEVEL_UP = function(nuevo) M.nivelEvento = Legible(nuevo); M.ActualizarClave() end,
	PLAYER_MONEY = function()
		local ahora = Legible(GetMoney())
		if not ahora then return end
		local d = ahora - (base.dinero or ahora)
		base.dinero = ahora
		if d > 0 then M.Sumar("ganado", d) elseif d < 0 then M.Sumar("gastado", -d) end
	end,
	BAG_UPDATE_DELAYED = function() M.RevisarInventario() end,
	PLAYER_EQUIPMENT_CHANGED = function() M.RevisarInventario() end,
	BANKFRAME_OPENED = function() M.RevisarInventario(); M.banco = true end,
	BANKFRAME_CLOSED = function() M.Rebase(); M.banco = false end,
	SKILL_LINES_CHANGED = function() M.RevisarProfesiones() end,
	CHAT_MSG_SKILL = function() M.RevisarProfesiones() end,
	ZONE_CHANGED_NEW_AREA = function() M.ActualizarClave() end,
	CHAT_MSG_SYSTEM = function(texto) M.MensajeSistema(texto) end,
}

for e in pairs(manejar) do f:RegisterEvent(e) end
f:SetScript("OnEvent", function(_, e, ...)
	if e ~= "ADDON_LOADED" and e ~= "PLAYER_ENTERING_WORLD" and not M.listo then return end
	manejar[e](...)
end)

-- El tiempo solo corre si no estás en pausa ni ausente (AFK).
f:SetScript("OnUpdate", function(_, transcurrido)
	if not M.listo then return end
	reloj = reloj + transcurrido
	if reloj >= 2 then reloj = 0; M.ActualizarClave() end
	-- UnitIsAFK puede venir secreto en Forever: probarlo directo rompía en cada cuadro (32 mil errores el 19-11)
	if M.pausa or Legible(UnitIsAFK("player")) then return end
	M.Sumar("seg", math.min(transcurrido, M.MAX_PASO))
end)
