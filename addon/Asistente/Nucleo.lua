-- Asistente: núcleo. Se carga siempre. Guarda los ajustes comunes, carga cada módulo
-- solo cuando hace falta (nunca en combate) y avisa a los módulos cuando entras a una ciudad.
-- Licencia: GPL-3.0-only. Autor: Cristian Amigo. Ver ARQUITECTURA.md.
local NOMBRE = ...

local A = _G.Asistente or {}
_G.Asistente = A
A.version = "0.1.0"
A.modulos = A.modulos or {}      -- nombre -> tabla del módulo (cada módulo se registra al cargar)
A.porDefecto = A.porDefecto or {} -- modulo -> { clave = valor }

-- Ciudades que tienen buscador de servicios (uiMap del juego). Los datos están en Asistente_Servicios.
A.CIUDADES = { [1454] = true, [1456] = true, [1458] = true }

---------------------------------------------------------------- ajustes comunes
-- Rellena lo que falte sin borrar lo que el jugador ya cambió.
local function rellenar(destino, origen)
	for k, v in pairs(origen) do
		if type(v) == "table" then
			if type(destino[k]) ~= "table" then destino[k] = {} end
			rellenar(destino[k], v)
		elseif destino[k] == nil then
			destino[k] = v
		end
	end
end

function A.Defaults(modulo, tabla)
	A.porDefecto[modulo] = tabla
	if AsistenteDB then
		AsistenteDB.ajustes[modulo] = AsistenteDB.ajustes[modulo] or {}
		rellenar(AsistenteDB.ajustes[modulo], tabla)
	end
end

-- A.Ajuste("servicios", "abrirAlEntrar") -> valor (o el de por defecto si aún no hay tabla guardada)
function A.Ajuste(modulo, clave)
	local db = AsistenteDB and AsistenteDB.ajustes and AsistenteDB.ajustes[modulo]
	if db and db[clave] ~= nil then return db[clave] end
	local d = A.porDefecto[modulo]
	return d and d[clave]
end

function A.FijarAjuste(modulo, clave, valor)
	A.PrepararDB()
	AsistenteDB.ajustes[modulo] = AsistenteDB.ajustes[modulo] or {}
	AsistenteDB.ajustes[modulo][clave] = valor
end

function A.PrepararDB()
	if type(AsistenteDB) ~= "table" then AsistenteDB = {} end
	AsistenteDB.ajustes = AsistenteDB.ajustes or {}
	for m, t in pairs(A.porDefecto) do
		AsistenteDB.ajustes[m] = AsistenteDB.ajustes[m] or {}
		rellenar(AsistenteDB.ajustes[m], t)
	end
end

A.Defaults("nucleo", { avisos = true })

---------------------------------------------------------------- mensajes
function A.Decir(texto)
	-- el chat tiene fondo oscuro: el nombre va en el acento de la apariencia, aclarado si hace falta (Estilo.lua)
	local nombre = A.ColorOscuro and A.ColorOscuro("titulo", "Asistente:") or "|cffffd100Asistente:|r"
	if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(nombre .. " " .. tostring(texto)) end
end

---------------------------------------------------------------- combate
function A.EnCombate()
	return InCombatLockdown ~= nil and InCombatLockdown() and true or false
end

---------------------------------------------------------------- carga de módulos
local pendientes = {} -- módulos pedidos en combate: se cargan al salir

function A.Registrar(nombre, modulo)
	A.modulos[nombre] = modulo
end

local function cargarAddon(addon)
	local C = C_AddOns
	if C and C.IsAddOnLoaded and C.IsAddOnLoaded(addon) then return true end
	local cargar = (C and C.LoadAddOn) or LoadAddOn
	if not cargar then return false, "sin_api" end
	local ok, cargado, motivo = pcall(cargar, addon)
	if not ok then return false, "error" end
	if not cargado then return false, motivo or "no_cargo" end
	return true
end

-- Carga un módulo (carpeta Asistente_<x>). Devuelve true si quedó cargado.
-- En combate no carga: lo deja pendiente y lo carga al salir del combate.
function A.Cargar(addon, alCargar)
	local C = C_AddOns
	if C and C.IsAddOnLoaded and C.IsAddOnLoaded(addon) then
		if alCargar then alCargar() end
		return true
	end
	if A.EnCombate() then
		pendientes[#pendientes + 1] = { addon = addon, fn = alCargar }
		return false, "combate"
	end
	local ok, motivo = cargarAddon(addon)
	if ok and alCargar then alCargar() end
	if not ok and motivo ~= "combate" then
		A.Decir("no se pudo cargar " .. addon .. " (" .. tostring(motivo) .. "). ¿Está en la carpeta AddOns y activado?")
	end
	return ok, motivo
end

---------------------------------------------------------------- ciudades
local ultimaCiudad -- para avisar una sola vez por entrada

function A.MapaActual()
	if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
	local ok, m = pcall(C_Map.GetBestMapForUnit, "player")
	if ok and type(m) == "number" then return m end
	return nil
end

function A.RevisarCiudad()
	local m = A.MapaActual()
	if not (m and A.CIUDADES[m]) then
		ultimaCiudad = nil
		return
	end
	if m == ultimaCiudad then return end
	ultimaCiudad = m
	A.Cargar("Asistente_Servicios", function()
		local S = A.modulos.servicios
		if S and S.AlEntrar then S.AlEntrar(m) end
	end)
end

---------------------------------------------------------------- eventos
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, evento, arg1)
	if evento == "ADDON_LOADED" and arg1 == NOMBRE then
		A.PrepararDB()
	elseif evento == "PLAYER_ENTERING_WORLD" or evento == "ZONE_CHANGED_NEW_AREA" then
		A.RevisarCiudad()
	elseif evento == "PLAYER_REGEN_ENABLED" then
		local lista = pendientes
		pendientes = {}
		for _, p in ipairs(lista) do A.Cargar(p.addon, p.fn) end
	end
end)
A._marco = f
