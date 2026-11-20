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
-- hooksecurefunc sobre ScriptErrorsFrame:OnError, que corre DESPUÉS de Blizzard y no mancha a quien llama.
local enganchado = false
local conBugGrabber = false -- se pone en true cuando BugGrabber nos avisa (engancharBugGrabber)
local function engancharErrores()
	if enganchado then return true end
	local sef = _G.ScriptErrorsFrame
	if not (sef and type(sef.OnError) == "function" and hooksecurefunc) then return false end
	hooksecurefunc(sef, "OnError", function(_, msg)
		if conBugGrabber then return end -- ya llega por BugGrabber: no contarlo dos veces (revisor t5)
		local ok, pila = pcall(debugstack, 4, 12, 0)
		pcall(anotar, msg, ok and pila or nil, "lua")
	end)
	enganchado = true
	if db and db.diag then db.diag.enganchado = true end
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
f:SetScript("OnEvent", function(_, evento, a, b)
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
		db.diag = { sesion = db.sesion, enganchado = enganchado, bugGrabber = conBugGrabber, anotados = 0,
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
