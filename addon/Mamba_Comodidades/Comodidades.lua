-- Mamba_Comodidades: las comodidades de Leatrix Plus que se usan de verdad (filas K71 y K87), cada una con
-- su interruptor en Interfaz › Comodidades. Regla 0 (no construir lo que ya existe): Polestar ya hace casi
-- todas (QoL/Toggles.lua, QoL/Social.lua, Maps/FlightTimer.lua); Mamba solo les pone el interruptor en
-- español y lee y escribe el MISMO ajuste de Polestar, así no hay dos addons peleando por lo mismo.
-- Lo nuevo de Mamba: silenciar sonidos molestos y el interruptor del brillo de ForeverLootSparkles (K83).
-- Código escrito de cero: Leatrix Plus no declara licencia (todos los derechos reservados). Los números
-- de los sonidos son identificadores de archivos del juego (un dato del cliente, no código).
-- Licencia: GPL-3.0-only.
local _, M = ...
local C = {}
M.Comodidades = C

local function PS() local p = _G.Polestar; return type(p) == "table" and p.Get and p.Set and p or nil end

-- Los interruptores, en el orden del panel. tipo: "polestar" (un ajuste de Polestar), "cvar" (del juego),
-- "brillo" (ForeverLootSparkles) o "sonido" (grupo de sonidos de Mamba).
C.LISTA = {
	{ clave = "qol.autoReleasePvP", tipo = "polestar", titulo = "Liberar el espíritu solo en campos de batalla",
		ayuda = "Al morir en un campo de batalla vuelves al cementerio sin apretar nada. Fuera de ellos no cambia nada. Mantén Mayús para quedarte." },
	{ clave = "qol.acceptSummon", tipo = "polestar", titulo = "Aceptar invocaciones",
		ayuda = "Acepta cuando alguien te invoca, salvo en combate. Mantén Mayús para que te pregunte." },
	{ clave = "qol.acceptResurrect", tipo = "polestar", titulo = "Aceptar resurrecciones",
		ayuda = "Acepta cuando alguien te resucita, salvo si está en combate (ese momento lo eliges tú). Mantén Mayús para que te pregunte." },
	{ clave = "autoLootDefault", tipo = "cvar", titulo = "Botín automático",
		ayuda = "Al abrir un cuerpo o un cofre, todo pasa a tus bolsas sin hacer clic en cada cosa." },
	{ clave = "qol.fastLoot", tipo = "polestar", titulo = "Botín rápido",
		ayuda = "Con el botín automático encendido, recoge todo de una vez y la ventana de botín casi no aparece." },
	{ clave = "maps.flightTimer", tipo = "polestar", titulo = "Tiempo de vuelo restante",
		ayuda = "En el grifo o el murciélago: a dónde vas y cuánto falta. Aprende el tiempo real de cada vuelo; lo estimado se marca como aproximado." },
	{ clave = "qol.hideErrors", tipo = "polestar", titulo = "Ocultar los errores rojos de combate",
		ayuda = "Esconde los avisos rojos repetidos como \"No tienes suficiente ira\" o \"Fuera de alcance\". Los demás siguen saliendo." },
	{ clave = "brillo", tipo = "brillo", titulo = "Brillo en los objetos de misión",
		ayuda = "Los objetos de misión que se pueden recoger brillan, aunque un ajuste de gráficos lo apague (ForeverLootSparkles). Apagarlo se nota al reiniciar el juego." },
}

-- Grupos de sonidos que se pueden silenciar. Los números son archivos de sonido del cliente.
C.SONIDOS = {
	{ clave = "trenes", titulo = "Sonido de tren",
		ayuda = "El ruido de tren que hacen los jugadores con el gesto del tren, de todas las razas.",
		ids = { 539802, 539881, 540271, 540275, 540535, 540734, 540870, 540947, 1316209, 1304872, 541157, 541239,
			542818, 542896, 543085, 543093, 542526, 542600, 7744921, 7744513 } },
	{ clave = "fallido", titulo = "Hechizo fallido",
		ayuda = "El chasquido de cuando un hechizo se corta o falla.",
		ids = { 569773, 569775, 569772, 569774, 569776, 569763 } },
	{ clave = "bostezo", titulo = "Bostezo de los felinos",
		ayuda = "El bostezo del gato cuando te quedas quieto, también en la forma felina del druida.",
		ids = { 562388 } },
}

local function db()
	local d = M.DB()
	d.sonidos = d.sonidos or {}
	return d
end

---------------------------------------------------------------- leer y escribir cada interruptor
local function brilloSetting()
	local S = _G.Settings
	if S and S.GetSetting then
		local ok, s = pcall(S.GetSetting, "FOREVER_LOOT_SPARKLES_ENABLED")
		if ok and s then return s end
	end
end

-- true | false | nil (no se puede: falta Polestar o el addon de ese ajuste)
function C.Valor(it)
	if it.tipo == "polestar" then
		local p = PS()
		return p and (p.Get(it.clave) and true or false) or nil
	elseif it.tipo == "cvar" then
		local v = C_CVar and C_CVar.GetCVar and C_CVar.GetCVar(it.clave)
		if v == nil then return nil end
		return v == "1"
	elseif it.tipo == "brillo" then
		local s = brilloSetting()
		if s and s.GetValue then return s:GetValue() and true or false end
		local d = _G.ForeverLootSparklesDB
		if type(d) ~= "table" then return nil end
		return d.enabled ~= false
	elseif it.tipo == "sonido" then
		return db().sonidos[it.clave] and true or false
	end
end

function C.Poner(it, v)
	v = v and true or false
	if it.tipo == "polestar" then
		local p = PS()
		if p then p.Set(it.clave, v) end
	elseif it.tipo == "cvar" then
		if C_CVar and C_CVar.SetCVar then pcall(C_CVar.SetCVar, it.clave, v and "1" or "0") end
	elseif it.tipo == "brillo" then
		local s = brilloSetting()
		if s and s.SetValue then pcall(s.SetValue, s, v) -- su propio aviso de reinicio sale en el chat
		elseif type(_G.ForeverLootSparklesDB) == "table" then _G.ForeverLootSparklesDB.enabled = v end
	elseif it.tipo == "sonido" then
		db().sonidos[it.clave] = v
		C.AplicarSonido(it, v)
	end
end

function C.Disponible(it) return C.Valor(it) ~= nil end

---------------------------------------------------------------- sonidos
local function grupo(clave)
	for _, g in ipairs(C.SONIDOS) do if g.clave == clave then return g end end
end

function C.AplicarSonido(it, v)
	local g = grupo(it.clave)
	local f = v and _G.MuteSoundFile or _G.UnmuteSoundFile
	if not (g and f) then return false end
	for _, id in ipairs(g.ids) do pcall(f, id) end
	return true
end

function C.Sonidos()
	local out = {}
	for _, g in ipairs(C.SONIDOS) do out[#out + 1] = { clave = g.clave, tipo = "sonido", titulo = g.titulo, ayuda = g.ayuda } end
	return out
end

function C.Iniciar()
	-- el silencio no se guarda en el juego: se vuelve a poner en cada entrada
	for _, it in ipairs(C.Sonidos()) do
		if db().sonidos[it.clave] then C.AplicarSonido(it, true) end
	end
end
