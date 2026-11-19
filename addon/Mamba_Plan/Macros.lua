-- Mamba_Plan: crear macros con un clic. Mamba arma el texto con los nombres que da el juego, la guarda como
-- macro de tu personaje y te la pone en el cursor para que la sueltes en tu barra. Solo fuera de combate (el
-- juego no deja crear macros en combate). La macro la usas tú: Mamba no la aprieta nunca.
-- Prueba en el juego (A7): al crearla, Mamba le pregunta al juego qué hechizo usaría la macro
-- (GetMacroSpell). Si el juego no reconoce ninguno, la macro no funciona en Forever: se borra, queda anotada
-- en diag.macrosMal y no se vuelve a ofrecer. Las que el juego entiende quedan en diag.macrosBien.
-- Licencia: GPL-3.0-only.
local _, M = ...

local function diag()
	local pj = M.PJ()
	pj.diag = pj.diag or {}
	pj.diag.macrosBien = pj.diag.macrosBien or {}
	pj.diag.macrosMal = pj.diag.macrosMal or {}
	return pj.diag
end
M.DiagMacros = diag

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

-- ¿El juego entiende la macro? Pregunta qué hechizo usaría (nil = ninguno). -> true | false | nil (no se pudo saber)
function M.MacroFunciona(idx)
	if not GetMacroSpell then return nil end
	local ok, id = pcall(GetMacroSpell, idx)
	if not ok then return nil end
	if id == nil then return false end
	return true
end

-- Las de tu clase que puedes usar (conoces todos sus hechizos), de tu rol primero, y que todavía no creaste.
-- Las que el juego ya rechazó no se ofrecen.
function M.MacrosSugeridas(e, max)
	local r = M.PJ().respuestas or {}
	local mal = diag().macrosMal
	local out = {}
	for _, m in ipairs(M.MACROS[e.clase] or {}) do
		local sabe = not mal[m.clave]
		for _, id in ipairs(m.usa) do if not M.Conoce(id) then sabe = false end end
		if sabe and not existe(nombreMacro(m)) and (not m.rol or not r.rol or m.rol == r.rol or m.rol == r.rol2) then
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
		local dg = diag()
		out[#out + 1] = { m = m, sabe = sabe, creada = existe(nombreMacro(m)), bien = dg.macrosBien[m.clave] and true or nil,
			mal = dg.macrosMal[m.clave] }
	end
	return out
end

-- Crea la macro (o usa la que ya existe), la prueba con el juego y la pone en el cursor (sinCursor: no).
-- -> true | false, motivo
function M.CrearMacro(clave, sinCursor)
	if InCombatLockdown and InCombatLockdown() then return false, "en combate no se puede" end
	local _, clase = UnitClass("player")
	local m
	for _, x in ipairs(M.MACROS[clase] or {}) do if x.clave == clave then m = x end end
	if not m then return false, "no existe" end
	local nombre = nombreMacro(m)
	local idx = GetMacroIndexByName and GetMacroIndexByName(nombre) or 0
	local nueva = false
	if not idx or idx == 0 then
		local txt, completo = cuerpo(m)
		if not completo then return false, "no conoces todos sus hechizos" end
		local ok, r = pcall(CreateMacro, nombre, "INV_MISC_QUESTIONMARK", txt, true)
		if not ok or not r then return false, "el juego no dejó crearla (¿lugares de macros llenos?)", "llenas" end
		idx, nueva = r, true
	end
	local dg = diag()
	local funciona = M.MacroFunciona(idx)
	-- solo se saca la que Mamba acaba de crear: una que ya existía (quizá editada por el jugador) no se toca
	if funciona == false and nueva then
		-- el juego no reconoce ningún hechizo en ella: no sirve en Forever, se saca
		if DeleteMacro then pcall(DeleteMacro, idx) end
		dg.macrosMal[clave] = (date and date("%d-%m %H:%M") or "") .. " el juego no reconoce su hechizo"
		dg.macrosBien[clave] = nil
		M.Cambio()
		return false, "el juego no la entiende en Forever: la saqué", "mal"
	end
	if funciona then dg.macrosBien[clave] = date and date("%d-%m %H:%M") or true end
	if PickupMacro and not sinCursor then pcall(PickupMacro, idx) end
	M.PJ().hechos["macro:" .. clave] = true
	M.Cambio()
	return true, "ok"
end

-- Todas las que te sirven, de una vez y sin cursor (A7: "creadas con un clic"). -> creadas, sacadas, motivo
function M.CrearTodasLasMacros(e)
	if InCombatLockdown and InCombatLockdown() then return 0, 0, "en combate no se puede" end
	local creadas, sacadas, llenas = 0, 0, 0
	for _, x in ipairs(M.TodasLasMacros(e)) do
		if x.sabe and not x.mal and not x.creada then
			local ok, _, por = M.CrearMacro(x.m.clave, true)
			if ok then creadas = creadas + 1
			elseif por == "llenas" then llenas = llenas + 1
			elseif por == "mal" then sacadas = sacadas + 1 end
		end
	end
	if llenas > 0 then return creadas, sacadas, ("Creadas: %d · sacadas: %d · %d no entraron: tus lugares de macros están llenos (Esc › Macros)"):format(creadas, sacadas, llenas) end
	return creadas, sacadas
end

-- «Probar de nuevo»: olvida las rechazadas (por si el juego se actualizó o fue un falso negativo).
function M.ReintentarMacros()
	local dg = diag()
	dg.macrosMal = {}
	M.Cambio()
end
