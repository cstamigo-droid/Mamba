-- Mamba_Plan: crear macros con un clic. Mamba arma el texto con los nombres que da el juego, la guarda como
-- macro de tu personaje y te la pone en el cursor para que la sueltes en tu barra. Solo fuera de combate (el
-- juego no deja crear macros en combate). La macro la usas tú: Mamba no la aprieta nunca.
-- Licencia: GPL-3.0-only.
local _, M = ...

local function cuerpo(m)
	local faltan = {}
	local txt = m.cuerpo:gsub("{(%d+)}", function(id)
		local n = M.NombreHechizo(tonumber(id))
		if not n then faltan[#faltan + 1] = id; return "" end
		return n
	end)
	return txt, #faltan == 0
end
M.CuerpoMacro = cuerpo

local function nombreMacro(m)
	-- el juego deja 16 letras; prefijo "M·" para reconocerlas como de Mamba
	local t = "M·" .. m.clave
	return t:sub(1, 16)
end

local function existe(nombre)
	if not GetMacroIndexByName then return false end
	local ok, i = pcall(GetMacroIndexByName, nombre)
	return ok and i and i > 0
end

-- Las de tu clase que puedes usar (conoces todos sus hechizos), de tu rol primero, y que todavía no creaste.
function M.MacrosSugeridas(e, max)
	local r = M.PJ().respuestas or {}
	local out = {}
	for _, m in ipairs(M.MACROS[e.clase] or {}) do
		local sabe = true
		for _, id in ipairs(m.usa) do if not M.Conoce(id) then sabe = false end end
		if sabe and not existe(nombreMacro(m)) and (not m.rol or not r.rol or m.rol == r.rol) then
			out[#out + 1] = m
		end
	end
	table.sort(out, function(a, b) return (a.rol and 0 or 1) < (b.rol and 0 or 1) end)
	if max then
		while #out > max do table.remove(out) end
	end
	return out
end

function M.TodasLasMacros(e)
	local out = {}
	for _, m in ipairs(M.MACROS[e.clase] or {}) do
		local sabe = true
		for _, id in ipairs(m.usa) do if not M.Conoce(id) then sabe = false end end
		out[#out + 1] = { m = m, sabe = sabe, creada = existe(nombreMacro(m)) }
	end
	return out
end

-- Crea la macro (o usa la que ya existe) y la pone en el cursor. -> true | false, motivo
function M.CrearMacro(clave)
	if InCombatLockdown and InCombatLockdown() then return false, "en combate no se puede" end
	local _, clase = UnitClass("player")
	local m
	for _, x in ipairs(M.MACROS[clase] or {}) do if x.clave == clave then m = x end end
	if not m then return false, "no existe" end
	local nombre = nombreMacro(m)
	local idx = GetMacroIndexByName and GetMacroIndexByName(nombre) or 0
	if not idx or idx == 0 then
		local txt, completo = cuerpo(m)
		if not completo then return false, "no conoces todos sus hechizos" end
		local ok, r = pcall(CreateMacro, nombre, "INV_MISC_QUESTIONMARK", txt, true)
		if not ok or not r then return false, "el juego no dejó crearla (¿lugares de macros llenos?)" end
		idx = r
	end
	if PickupMacro then pcall(PickupMacro, idx) end
	M.PJ().hechos["macro:" .. clave] = true
	M.Cambio()
	return true, "ok"
end
