-- Mamba_Bolsas: las bolsas, como Bagnon pero sobre las piezas del juego.
--  * Todas tus bolsas en UNA ventana: la ventana de bolsas unidas del propio juego (opción combinedBags),
--    con su buscador y su botón de ordenar. Es la del juego: sus botones de objeto son seguros y funcionan
--    en combate, cosa que una ventana propia no garantiza.
--  * Lo que Bagnon agrega: el inventario de TODOS tus personajes (bolsas y banco, guardado al verlos), un
--    buscador entre personajes (Interfaz › Bolsas) y, en el cuadro de cada objeto, cuántos tienes y dónde.
-- Solo lee y muestra: no mueve, no vende ni borra nada. Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaBolsas = M
local P = M.Piezas

---------------------------------------------------------------- guardado
local function db()
	MambaBolsasDB = MambaBolsasDB or {}
	local d = MambaBolsasDB
	d.personajes = d.personajes or {}
	d.opciones = d.opciones or {}
	if d.opciones.unir == nil then d.opciones.unir = true end
	if d.opciones.cuadro == nil then d.opciones.cuadro = true end
	return d
end
M.DB = db

local function clave()
	return (UnitName("player") or "?") .. " - " .. (GetRealmName and GetRealmName() or "")
end
M.Clave = clave

local function contar(desde, hasta, destino)
	local C = C_Container
	if not (C and C.GetContainerNumSlots and C.GetContainerItemInfo) then return end
	for b = desde, hasta do
		local okN, n = pcall(C.GetContainerNumSlots, b)
		for s = 1, (okN and n or 0) do
			local ok, info = pcall(C.GetContainerItemInfo, b, s)
			if ok and type(info) == "table" and info.itemID then
				destino[info.itemID] = (destino[info.itemID] or 0) + (info.stackCount or 1)
			end
		end
	end
end

-- Lo que este personaje lleva en las bolsas (siempre se puede leer).
function M.GuardarBolsas()
	local p = db().personajes
	local k = clave()
	p[k] = p[k] or {}
	local bolsas = {}
	contar(0, 4, bolsas)
	p[k].bolsas = bolsas
	local _, clase = UnitClass("player")
	p[k].clase = clase
	p[k].oro = GetMoney and GetMoney() or 0
	p[k].fecha = date and date("%d-%m-%Y") or ""
end

-- El banco solo se puede leer con el banco abierto: se guarda en ese momento.
function M.GuardarBanco()
	local p = db().personajes
	local k = clave()
	p[k] = p[k] or {}
	local banco = {}
	local BANCO = (Enum and Enum.BagIndex and Enum.BagIndex.Bank) or -1
	contar(BANCO, BANCO, banco)
	local N = NUM_BANKBAGSLOTS or 6
	contar(5, 4 + N, banco)
	p[k].banco = banco
	p[k].fechaBanco = date and date("%d-%m-%Y") or ""
end

-- Cuántos hay de un objeto en cada personaje: { { nombre, bolsas, banco }, ... } y el total.
function M.Donde(itemID)
	local out, total = {}, 0
	for k, p in pairs(db().personajes) do
		local b = p.bolsas and p.bolsas[itemID] or 0
		local n = p.banco and p.banco[itemID] or 0
		if b + n > 0 then
			out[#out + 1] = { nombre = k:match("^(.-) %-") or k, clave = k, bolsas = b, banco = n }
			total = total + b + n
		end
	end
	table.sort(out, function(a, b) return (a.bolsas + a.banco) > (b.bolsas + b.banco) end)
	return out, total
end

-- Buscar por nombre en todos los personajes. -> { { id, nombre, total, donde } } (nombre del caché del juego)
function M.Buscar(texto)
	texto = (texto or ""):lower()
	local ids = {}
	for _, p in pairs(db().personajes) do
		for id in pairs(p.bolsas or {}) do ids[id] = true end
		for id in pairs(p.banco or {}) do ids[id] = true end
	end
	local out = {}
	for id in pairs(ids) do
		local nombre = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
		if not nombre and GetItemInfo then nombre = GetItemInfo(id) end
		if texto == "" or (nombre and nombre:lower():find(texto, 1, true)) then
			local donde, total = M.Donde(id)
			out[#out + 1] = { id = id, nombre = nombre or ("objeto " .. id), total = total, donde = donde }
		end
	end
	table.sort(out, function(a, b) return a.nombre < b.nombre end)
	return out
end

---------------------------------------------------------------- bolsas unidas del juego
function M.AplicarUnir()
	local get = (C_CVar and C_CVar.GetCVar) or GetCVar
	local set = (C_CVar and C_CVar.SetCVar) or SetCVar
	if not (get and set) then return end
	local ok, v = pcall(get, "combinedBags")
	if not ok or v == nil then
		M.sinUnir = true -- este cliente no tiene la opción
		return
	end
	local quiero = db().opciones.unir and "1" or "0"
	if v ~= quiero then pcall(set, "combinedBags", quiero) end
end

---------------------------------------------------------------- cuadro del objeto
local function lineas(tooltip, _, id)
	if not db().opciones.cuadro or not id then return end
	local donde, total = M.Donde(id)
	if total == 0 then return end
	local H = _G.Polestar and _G.Polestar.Hooks
	local partes = {}
	for i, d in ipairs(donde) do
		if i > 4 then partes[#partes + 1] = "…"; break end
		local t = d.nombre .. " " .. (d.bolsas + d.banco)
		if d.banco > 0 then t = t .. (d.bolsas > 0 and (" (banco " .. d.banco .. ")") or " (banco)") end
		partes[#partes + 1] = t
	end
	local texto = "Tienes " .. total .. ": " .. table.concat(partes, ", ")
	-- el cuadro del objeto tiene SIEMPRE fondo oscuro: el color va con A.ColorOscuro (ESTETICA_MAMBA, excepciones)
	local A = _G.Asistente
	if A and A.ColorOscuro then texto = A.ColorOscuro("gris", texto) end
	if H and H.AddLine then H.AddLine(tooltip, texto) elseif tooltip.AddLine then tooltip:AddLine(texto) end
end
M.LineasCuadro = lineas

---------------------------------------------------------------- eventos
local ev = CreateFrame("Frame")
local function escuchar(e) pcall(ev.RegisterEvent, ev, e) end
for _, e in ipairs({ "PLAYER_LOGIN", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED", "PLAYERBANKSLOTS_CHANGED", "PLAYER_MONEY" }) do escuchar(e) end
ev:SetScript("OnEvent", function(_, e)
	if e == "PLAYER_LOGIN" then
		pcall(M.AplicarUnir)
		pcall(M.GuardarBolsas)
		local H = _G.Polestar and _G.Polestar.Hooks
		if H and H.ItemLines then H.ItemLines("MambaBolsas", lineas) end
		if M.Registrar then pcall(M.Registrar) end
	elseif e == "BANKFRAME_OPENED" or e == "PLAYERBANKSLOTS_CHANGED" then
		pcall(M.GuardarBanco)
		pcall(M.GuardarBolsas)
	else
		pcall(M.GuardarBolsas)
	end
end)
