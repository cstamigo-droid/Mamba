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
