-- Mamba_Plan: lo que el plan lee de los demás módulos, por sus funciones públicas. Si un módulo no está,
-- la función devuelve nil y el plan sigue sin esa parte (nunca inventa).
--   Tasador.PrecioSubasta(link, id)                 -> precio por unidad, días de antigüedad
--   Asistente_Equipo (E.Gear, E.MejorasMazmorras)    -> qué mazmorra conviene repetir y qué pieza
--   AsistenteClase (la ventana de Clase, si la expone) -> builds de la clase y el próximo talento
-- Licencia: GPL-3.0-only.
local _, M = ...
local F = {}
M.Fuentes = F

function F.Precio(itemID)
	local api = _G.MambaAPI
	if api and api.PrecioObjeto and itemID then
		local ok, p, _, edad = pcall(api.PrecioObjeto, itemID)
		if ok and type(p) == "number" and p > 0 then return p, edad end
	end
	local T = _G.Tasador
	if not (T and T.PrecioSubasta and itemID) then return nil end
	local ok, p, dias = pcall(T.PrecioSubasta, "item:" .. itemID, itemID)
	if ok and type(p) == "number" and p > 0 then return p, dias end
end

-- Mazmorras que te mejoran: { { nombre, min, max, valor, pieza = { id, nombre, pct, pctMejora, ranura } } }
function F.Mazmorras(nivel)
	local E = _G.Asistente_Equipo
	if not (E and E.Gear and E.MejorasMazmorras) then return nil end
	local G = E.Gear()
	if not G then return nil end
	local mision = E.MisionHecha and function(q) return E.MisionHecha(q) end
	local ok, con = pcall(E.MejorasMazmorras, G, nivel, "H", mision)
	if not ok or type(con) ~= "table" then return nil end
	local out = {}
	for _, x in ipairs(con) do
		local p = x.piezas and x.piezas[1]
		out[#out + 1] = { nombre = x.m.nombre or x.m.clave, clave = x.m.clave, min = x.m.min, max = x.m.max,
			valor = x.valor, pieza = p }
	end
	return out
end

-- El próximo paso de la guía de Polestar: "Entrega 2 misiones en Orgrimmar → vuela a Molino Tarren → ...".
-- Usa piezas internas de Polestar (Engine.GetGuide, GetLiveStep, UI.PlainGoalText); si cambian, devuelve nil y
-- "Ahora" sigue sin esa línea (lo vigila polestar_al_dia.py: INTERNAS). -> { guia, paso, total, metas = { textos } }
function F.ProximoPaso(max)
	local P = _G.Polestar
	local E, UI = P and P.Engine, P and P.UI
	if not (E and E.GetGuide and E.GetLiveStep and UI and (UI.PlainGoalText or UI.GoalText)) then return nil end
	local ok, g = pcall(E.GetGuide)
	local ok2, i = pcall(E.GetLiveStep)
	if not (ok and ok2 and type(g) == "table" and type(g.steps) == "table" and type(i) == "number") then return nil end
	local texto = UI.PlainGoalText or UI.GoalText
	local metas = {}
	max = max or 4
	for s = i, math.min(#g.steps, i + 3) do
		local paso = g.steps[s]
		for _, goal in ipairs(paso and paso.goals or {}) do
			if goal.status ~= "done" and #metas < max then
				local okT, t = pcall(texto, goal)
				if okT and type(t) == "string" and t ~= "" then
					t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
					metas[#metas + 1] = t
				end
			end
		end
		if #metas >= max then break end
	end
	local numero = E.StepNumber and select(2, pcall(E.StepNumber, i)) or i
	local total = E.StepTotal and select(2, pcall(E.StepTotal)) or #g.steps
	return { guia = g.title, paso = numero, total = total, metas = metas }
end

function F.PasadasPara(pct)
	local E = _G.Asistente_Equipo
	if E and E.Pasadas then return E.Pasadas(pct) end
end

function F.Clase()
	local api = _G.MambaAPI
	if api and api.Clase then
		local ok, C = pcall(api.Clase)
		if ok and type(C) == "table" then return C end
	end
	local C = _G.AsistenteClase
	if type(C) == "table" then return C end
end

-- Partes de la ventana de Mamba (Asistente/Grupos.lua): MambaAPI.Abrir(parte, pestaña).
local PARTES = {
	Equipo = { "MambaEquipo", "mejorar" }, Clase = { "MambaClase", "talentos" },
	Subasta = { "MambaSubasta", "vender" }, Medidor = { "MambaMedidor" },
}

-- ¿Qué sección de otra sesión abrir? (botones "Ver en Equipo", etc.). Devuelve false si no existe.
function F.AbrirSeccion(clave, pestana)
	local api = _G.MambaAPI
	local p = PARTES[clave]
	if api and api.Abrir and p then
		local ok, r = pcall(api.Abrir, p[1], pestana or p[2])
		if ok and r ~= false then return true end
	end
	local P = _G.Polestar
	local UI = P and P.UI
	if not (UI and UI.ShowPicker and UI.Picker and UI.Picker.ShowSection) then return false end
	UI.ShowPicker()
	UI.Picker.ShowSection(clave)
	return true
end
