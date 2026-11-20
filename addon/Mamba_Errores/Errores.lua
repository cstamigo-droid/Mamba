-- Mamba Errores: guarda cada error de Lua y cada acción bloqueada en MambaErroresDB (SavedVariables),
-- para leerlos fuera del juego en WTF\Account\<cuenta>\SavedVariables\Mamba_Errores.lua.
-- No reemplaza al manejador del juego: lo llama después de anotar el error.
local MAX = 300

local db
local pendientes = {}

local function anotar(msg, pila, tipo)
	msg = tostring(msg or "?")
	local e = { msg = msg, pila = pila, tipo = tipo, hora = date and date("%Y-%m-%d %H:%M:%S") or "", veces = 1 }
	if not db then
		if #pendientes < 50 then pendientes[#pendientes + 1] = e end
		return
	end
	for i = #db.lista, math.max(1, #db.lista - 20), -1 do
		local o = db.lista[i]
		if o.msg == msg then
			o.veces = (o.veces or 1) + 1
			o.hora = e.hora
			return
		end
	end
	db.lista[#db.lista + 1] = e
	if db.diag then db.diag.anotados = (db.diag.anotados or 0) + 1 end
	while #db.lista > MAX do table.remove(db.lista, 1) end
end

-- K113 (18-11): NO se reemplaza el manejador de errores del juego (seterrorhandler). Con nuestra función en el
-- manejador, cuando la interfaz del gremio de Blizzard fallaba, la ejecución quedaba "manchada" por Mamba_Errores
-- y el juego bloqueaba UpdateGuildLobby(), IsUserOAuthed()... a nombre de Mamba_Errores. Ahora se escucha con
-- hooksecurefunc (corre DESPUÉS de Blizzard y no mancha a quien llama); dónde, más abajo.
local enganchado = false
local conBugGrabber = false -- se pone en true cuando BugGrabber nos avisa (engancharBugGrabber)
-- Dónde escuchar (código de Blizzard, Gethe/wow-ui-source classic_era, Blizzard_ScriptErrors y
-- Blizzard_ScriptErrorsFrame): el manejador del juego (HandleLuaError) pasa cada error a los manejadores
-- registrados con AddLuaErrorHandler (solo código seguro): el de ScriptErrorsFrame llama a
-- ScriptErrorsFrame:DisplayMessageInternal(msg, tipo, pila, locales) SIEMPRE; el CVar scriptErrors solo decide
-- si la ventana se muestra. Sin manejadores, va a ScriptErrors:AddUnhandledError(msg, pila, locales).
-- ScriptErrorsFrame NO tiene OnError en este cliente: ese enganche (19-11) nunca se ponía y Errores quedó mudo.
local via = nil
local function anotarDeBlizzard(msg, pila)
	if conBugGrabber then return end -- ya llega por BugGrabber: no contarlo dos veces (revisor t5)
	pcall(anotar, msg, type(pila) == "string" and pila or nil, "lua")
end
local function engancharErrores()
	if enganchado or not hooksecurefunc then return enganchado end
	local sef = _G.ScriptErrorsFrame
	local se = _G.ScriptErrors
	if sef and type(sef.DisplayMessageInternal) == "function" then
		-- (self, mensaje, tipo, pila, locales): el tipo de advertencia (LUA_WARNING) no es un error de Lua
		hooksecurefunc(sef, "DisplayMessageInternal", function(_, msg, tipo, pila)
			if tipo ~= nil and _G.WarningMessageType ~= nil and tipo == _G.WarningMessageType then return end
			anotarDeBlizzard(msg, pila)
		end)
		via = "ScriptErrorsFrame:DisplayMessageInternal"
	elseif sef and type(sef.OnError) == "function" then -- clientes más viejos
		hooksecurefunc(sef, "OnError", function(_, msg) anotarDeBlizzard(msg, nil) end)
		via = "ScriptErrorsFrame:OnError"
	elseif type(se) == "table" and type(se.AddUnhandledError) == "function" then
		hooksecurefunc(se, "AddUnhandledError", function(_, msg, pila) anotarDeBlizzard(msg, pila) end)
		via = "ScriptErrors:AddUnhandledError"
	else
		return false
	end
	enganchado = true
	if db and db.diag then db.diag.enganchado, db.diag.via, db.diag.mudo = true, via, nil end
	return true
end
-- Respaldo con BugGrabber: si está, el manejador de errores es suyo y nos avisa por su callback (no mancha más
-- de lo que ya mancha BugGrabber). Se cuenta en el diag para ver en el juego si llegan.
local function engancharBugGrabber()
	if conBugGrabber then return end
	local BG = _G.BugGrabber
	if type(BG) == "table" and BG.RegisterCallback then
		local ok = pcall(BG.RegisterCallback, {}, "BugGrabber_BugGrabbed", function(_, err)
			if type(err) == "table" then pcall(anotar, err.message, err.stack, "lua") end
		end)
		conBugGrabber = ok and true or false
	end
end
engancharErrores()

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("ADDON_ACTION_BLOCKED")
f:RegisterEvent("ADDON_ACTION_FORBIDDEN")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, evento, a, b)
	if evento == "PLAYER_LOGIN" then
		-- último intento; si no hay por dónde escuchar, el diag lo dice y la ventana (Errores) lo avisa
		engancharErrores()
		engancharBugGrabber()
		if db and db.diag then
			db.diag.enganchado, db.diag.via, db.diag.bugGrabber = enganchado, via, conBugGrabber
			db.diag.mudo = (not enganchado and not conBugGrabber) or nil
		end
		return
	end
	if evento == "ADDON_LOADED" then
		-- ScriptErrorsFrame puede llegar con un addon de Blizzard que se carga después
		if not enganchado then engancharErrores() end
		engancharBugGrabber()
		if a ~= "Mamba_Errores" then return end
		MambaErroresDB = type(MambaErroresDB) == "table" and MambaErroresDB or {}
		db = MambaErroresDB
		db.lista = type(db.lista) == "table" and db.lista or {}
		db.sesion = (db.sesion or 0) + 1
		-- diag de esta sesión: si el enganche quedó puesto y cuántos errores llegaron (para ver si Errores quedó mudo)
		db.diag = { sesion = db.sesion, enganchado = enganchado, via = via, bugGrabber = conBugGrabber, anotados = 0,
			scriptErrors = GetCVar and GetCVar("scriptErrors") or "?" }
		for _, e in ipairs(pendientes) do anotar(e.msg, e.pila, e.tipo) end
		pendientes = {}
	else
		anotar(tostring(a) .. " intentó " .. tostring(b), nil, evento == "ADDON_ACTION_BLOCKED" and "bloqueada" or "prohibida")
	end
end)

SLASH_MAMBAERRORES1 = "/errores"
SlashCmdList.MAMBAERRORES = function(arg)
	if not db then return end
	if arg == "borrar" then
		db.lista = {}
		print("|cff33ff99Mamba Errores|r: lista borrada.")
		return
	end
	local n = #db.lista
	print(("|cff33ff99Mamba Errores|r: %d errores guardados. Los últimos:"):format(n))
	for i = math.max(1, n - 4), n do
		local e = db.lista[i]
		print(("%s  x%d  %s"):format(e.hora or "", e.veces or 1, (e.msg or ""):sub(1, 180)))
	end
	print("Escribe /errores borrar para vaciar la lista.")
end
