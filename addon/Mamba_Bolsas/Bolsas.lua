-- Mamba_Bolsas: los datos de las bolsas (qué bolsas hay, qué lleva cada casilla y lo guardado de cada personaje).
--  * Bolsas de Forever (cliente moderno, WOW_PROJECT_ID 18): mochila 0, bolsas 1-4 y la bolsa de componentes 5
--    (Enum.BagIndex.ReagentBag). El banco son PESTAÑAS: bolsas 6, 7, 8… (Enum.BagIndex.CharacterBankTab_1..),
--    cada una con su nombre e ícono (C_Bank.FetchPurchasedBankTabData). Si el cliente fuera el viejo, banco -1 y
--    bolsas de banco detrás de las del personaje.
--  * Lo guardado (MambaBolsasDB.personajes[clave]): casilla por casilla (slots[bolsa] = { n, nombre, icono,
--    items = { [casilla] = "enlace;cantidad" } }), para ver las bolsas y el banco de cualquier personaje sin estar
--    ahí, y los totales por objeto (bolsas, banco) que leen el buscador y el cuadro del objeto.
--  * En el cuadro de cada objeto: "Tienes N: Hope 7, Cazador 4 (banco)".
-- Solo lee: lo que mueve objetos (ordenar, apilar) está en Ordenar.lua. Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaBolsas = M

local VERSION_DATOS = 2 -- 2: el banco por pestañas (la 0.1 leía la bolsa 5 como banco)

---------------------------------------------------------------- guardado
local POR_DEFECTO = {
	propia = true,      -- la ventana de Mamba en vez de las bolsas del juego
	unir = true,        -- sin la ventana de Mamba: la ventana unida del juego
	cuadro = true,      -- "Tienes N…" en el cuadro del objeto
	columnas = 12, tamano = 37, escala = 1, fondo = 0.96,
	fija = false, separar = false, vista = "todas", reves = false,
	columnasBanco = 14,
	marcas = true, nuevo = true, mejora = true,
}

local function db()
	MambaBolsasDB = MambaBolsasDB or {}
	local d = MambaBolsasDB
	d.personajes = d.personajes or {}
	d.opciones = d.opciones or {}
	for k, v in pairs(POR_DEFECTO) do if d.opciones[k] == nil then d.opciones[k] = v end end
	if (d.version or 1) < VERSION_DATOS then
		-- la 0.1 guardó como "banco" la bolsa de componentes: ese dato no sirve
		for _, p in pairs(d.personajes) do p.banco, p.fechaBanco = nil, nil end
		d.version = VERSION_DATOS
	end
	return d
end
M.DB = db
function M.Op(k) return db().opciones[k] end

local function clave()
	return (UnitName("player") or "?") .. " - " .. (GetRealmName and GetRealmName() or "")
end
M.Clave = clave
function M.NombreDe(k) return (k or ""):match("^(.-) %-") or k end

---------------------------------------------------------------- qué bolsas hay
local function C() return C_Container end

function M.BolsasInventario()
	local n = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
	local t = {}
	for b = 0, n do t[#t + 1] = b end
	return t
end

function M.PrimeraPestana()
	local E = Enum and Enum.BagIndex
	return E and E.CharacterBankTab_1 or nil
end

-- Las pestañas (o bolsas) del banco que existen. Con el banco cerrado vale lo guardado.
function M.BolsasBanco()
	local t = {}
	local primera = M.PrimeraPestana()
	if primera then
		local hay = {}
		local B = C_Bank
		local tipo = Enum and Enum.BankType and Enum.BankType.Character or 0
		if B and B.FetchPurchasedBankTabData then
			local ok, datos = pcall(B.FetchPurchasedBankTabData, tipo)
			if ok and type(datos) == "table" then
				for _, d in ipairs(datos) do
					if d.ID then hay[d.ID] = true; t[#t + 1] = d.ID end
				end
			end
		end
		if #t == 0 then
			local n = (Constants and Constants.InventoryConstants and Constants.InventoryConstants.NumCharacterBankSlots) or 6
			for i = 0, n - 1 do t[#t + 1] = primera + i end
		end
		table.sort(t)
		return t
	end
	local banco = (Enum and Enum.BagIndex and Enum.BagIndex.Bank) or BANK_CONTAINER or -1
	t[1] = banco
	local desde = (NUM_BAG_SLOTS or 4) + 1
	for b = desde, desde + (NUM_BANKBAGSLOTS or 6) - 1 do t[#t + 1] = b end
	return t
end

function M.EsBanco(bolsa)
	local primera = M.PrimeraPestana()
	if primera then return bolsa >= primera end
	return bolsa < 0 or bolsa > (NUM_BAG_SLOTS or 4)
end

function M.Casillas(bolsa)
	local c = C()
	if not (c and c.GetContainerNumSlots) then return 0 end
	local ok, n = pcall(c.GetContainerNumSlots, bolsa)
	return ok and n or 0
end

function M.Info(bolsa, casilla)
	local c = C()
	if not (c and c.GetContainerItemInfo) then return nil end
	local ok, info = pcall(c.GetContainerItemInfo, bolsa, casilla)
	if ok and type(info) == "table" and info.itemID then return info end
	return nil
end

-- Libres y totales de una bolsa (en vivo). Las bolsas de profesión cuentan aparte en el total.
function M.Espacio(bolsa)
	local n = M.Casillas(bolsa)
	local usadas = 0
	for s = 1, n do if M.Info(bolsa, s) then usadas = usadas + 1 end end
	return n - usadas, n
end

-- Nombre e ícono de una bolsa (en vivo).
function M.DatosBolsa(bolsa)
	if bolsa == 0 then return BACKPACK_TOOLTIP or "Mochila", "Interface\\Buttons\\Button-Backpack-Up" end
	if M.EsBanco(bolsa) and M.PrimeraPestana() then
		local B = C_Bank
		local tipo = Enum and Enum.BankType and Enum.BankType.Character or 0
		if B and B.FetchPurchasedBankTabData then
			local ok, datos = pcall(B.FetchPurchasedBankTabData, tipo)
			for _, d in ipairs(ok and datos or {}) do
				if d.ID == bolsa then return d.name or ("Pestaña " .. (bolsa - M.PrimeraPestana() + 1)), d.icon end
			end
		end
		return "Pestaña " .. (bolsa - M.PrimeraPestana() + 1), 134400
	end
	local c = C()
	local inv = c and c.ContainerIDToInventoryID and select(2, pcall(c.ContainerIDToInventoryID, bolsa))
	if type(inv) == "number" then
		local link = GetInventoryItemLink and GetInventoryItemLink("player", inv)
		local icono = GetInventoryItemTexture and GetInventoryItemTexture("player", inv)
		local nombre = link and link:match("%[(.-)%]")
		return nombre or (bolsa == 5 and "Bolsa de componentes" or ("Bolsa " .. bolsa)), icono, inv
	end
	return "Bolsa " .. bolsa, nil
end

---------------------------------------------------------------- guardar lo de este personaje
local function guardarBolsa(p, bolsa)
	local n = M.Casillas(bolsa)
	p.slots = p.slots or {}
	if n <= 0 then p.slots[bolsa] = nil; return end
	local nombre, icono = M.DatosBolsa(bolsa)
	local s = { n = n, nombre = nombre, icono = icono, items = {} }
	for i = 1, n do
		local info = M.Info(bolsa, i)
		if info then s.items[i] = (info.hyperlink or ("item:" .. info.itemID)) .. ";" .. (info.stackCount or 1) end
	end
	p.slots[bolsa] = s
end

local function totales(p, banco)
	local t = {}
	for bolsa, s in pairs(p.slots or {}) do
		if M.EsBanco(bolsa) == banco then
			for _, x in pairs(s.items or {}) do
				local id, n = M.Partir(x)
				if id then t[id] = (t[id] or 0) + n end
			end
		end
	end
	return t
end

-- "enlace;cantidad" -> id, cantidad, enlace
function M.Partir(x)
	if type(x) ~= "string" then return nil end
	local link, n = x:match("^(.*);(%d+)$")
	link = link or x
	local id = tonumber(link:match("item:(%d+)"))
	return id, tonumber(n) or 1, link
end

local function yo()
	local p = db().personajes
	local k = clave()
	p[k] = p[k] or {}
	return p[k]
end

function M.GuardarBolsas()
	local p = yo()
	for _, b in ipairs(M.BolsasInventario()) do guardarBolsa(p, b) end
	p.bolsas = totales(p, false)
	local _, clase = UnitClass("player")
	p.clase = clase
	p.oro = GetMoney and GetMoney() or 0
	p.fecha = date and date("%d-%m-%Y") or ""
end

M.bancoAbierto = false
-- El banco solo se puede leer con el banco abierto: se guarda en ese momento.
function M.GuardarBanco()
	if not M.bancoAbierto then return end
	local p = yo()
	for bolsa in pairs(p.slots or {}) do if M.EsBanco(bolsa) then p.slots[bolsa] = nil end end
	for _, b in ipairs(M.BolsasBanco()) do guardarBolsa(p, b) end
	p.banco = totales(p, true)
	p.fechaBanco = date and date("%d-%m-%Y") or ""
end

---------------------------------------------------------------- consultas
-- Cuántos hay de un objeto en cada personaje: { { nombre, bolsas, banco }, ... } y el total.
function M.Donde(itemID)
	local out, total = {}, 0
	for k, p in pairs(db().personajes) do
		local b = p.bolsas and p.bolsas[itemID] or 0
		local n = p.banco and p.banco[itemID] or 0
		if b + n > 0 then
			out[#out + 1] = { nombre = M.NombreDe(k), clave = k, bolsas = b, banco = n }
			total = total + b + n
		end
	end
	table.sort(out, function(a, b)
		if a.bolsas + a.banco ~= b.bolsas + b.banco then return (a.bolsas + a.banco) > (b.bolsas + b.banco) end
		return a.nombre < b.nombre
	end)
	return out, total
end

function M.NombreObjeto(id)
	local nombre = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
	if not nombre and GetItemInfo then nombre = GetItemInfo(id) end
	return nombre
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
		local nombre = M.NombreObjeto(id)
		if texto == "" or (nombre and nombre:lower():find(texto, 1, true)) then
			local donde, total = M.Donde(id)
			out[#out + 1] = { id = id, nombre = nombre or ("objeto " .. id), total = total, donde = donde }
		end
	end
	table.sort(out, function(a, b) return a.nombre < b.nombre end)
	return out
end

-- Los personajes guardados, el actual primero.
function M.Personajes()
	local t, yoK = {}, clave()
	for k in pairs(db().personajes) do if k ~= yoK then t[#t + 1] = k end end
	table.sort(t)
	table.insert(t, 1, yoK)
	return t
end

---------------------------------------------------------------- bolsas unidas del juego (sin la ventana de Mamba)
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
M.alCambiar = {} -- fn(motivo, bolsa) de las ventanas
local function avisar(motivo, bolsa)
	for _, fn in ipairs(M.alCambiar) do
		local ok, err = pcall(fn, motivo, bolsa)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	end
end
M.Avisar = avisar

local ev = CreateFrame("Frame")
M.eventos = ev
local function escuchar(e) pcall(ev.RegisterEvent, ev, e) end
for _, e in ipairs({ "PLAYER_LOGIN", "BAG_UPDATE", "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
	"PLAYERBANKSLOTS_CHANGED", "BANK_TABS_CHANGED", "PLAYER_MONEY", "ITEM_LOCK_CHANGED", "BAG_UPDATE_COOLDOWN",
	"PLAYER_REGEN_ENABLED", "GET_ITEM_INFO_RECEIVED", "QUEST_LOG_UPDATE", "BAG_NEW_ITEMS_UPDATED" }) do escuchar(e) end

local sucias = {}
ev:SetScript("OnEvent", function(_, e, a1)
	if e == "PLAYER_LOGIN" then
		db()
		pcall(M.GuardarBolsas)
		local H = _G.Polestar and _G.Polestar.Hooks
		if H and H.ItemLines then H.ItemLines("MambaBolsas", lineas) end
		if M.Registrar then pcall(M.Registrar) end
		if M.Iniciar then
			local ok, err = pcall(M.Iniciar)
			if not ok and geterrorhandler then geterrorhandler()(err) end
		end
		if not M.Op("propia") then pcall(M.AplicarUnir) end
	elseif e == "BANKFRAME_OPENED" then
		M.bancoAbierto = true
		pcall(M.GuardarBanco)
		pcall(M.GuardarBolsas)
		avisar("banco-abierto")
		-- en Forever las pestañas pueden llegar un instante después de abrir (la 0.1 guardó un banco vacío)
		if C_Timer and C_Timer.After then
			for _, t in ipairs({ 0.3, 1.5 }) do
				C_Timer.After(t, function()
					if not M.bancoAbierto then return end
					pcall(M.GuardarBanco)
					avisar("bolsas", {})
				end)
			end
		end
	elseif e == "BANKFRAME_CLOSED" then
		-- lo guardado es lo último que se leyó con el banco abierto: al cerrarse el juego ya no lo deja leer
		M.bancoAbierto = false
		avisar("banco-cerrado")
	elseif e == "BAG_UPDATE" then
		if type(a1) == "number" then sucias[a1] = true end
	elseif e == "BAG_UPDATE_DELAYED" or e == "PLAYERBANKSLOTS_CHANGED" or e == "BANK_TABS_CHANGED" then
		pcall(M.GuardarBolsas)
		if M.bancoAbierto then pcall(M.GuardarBanco) end
		local s = sucias
		sucias = {}
		avisar("bolsas", s)
	elseif e == "PLAYER_MONEY" then
		local p = yo()
		p.oro = GetMoney and GetMoney() or p.oro
		avisar("oro")
	elseif e == "ITEM_LOCK_CHANGED" or e == "BAG_UPDATE_COOLDOWN" or e == "BAG_NEW_ITEMS_UPDATED" then
		avisar("casillas")
	elseif e == "PLAYER_REGEN_ENABLED" then
		avisar("fuera-de-combate")
	elseif e == "GET_ITEM_INFO_RECEIVED" or e == "QUEST_LOG_UPDATE" then
		avisar("datos")
	end
end)
