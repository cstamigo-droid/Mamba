-- Mamba_Plan: núcleo. Base de datos del personaje, eventos que quizá este cliente no tenga y "fuera de
-- combate". Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaPlan = M
-- DatosProfesiones.lua es la misma tabla de Asistente_Clase (una sola fuente: la prueba exige que sean
-- iguales); esa tabla cuelga sus funciones de ns.Clase.
M.Clase = M.Clase or {}

function M.PJ()
	MambaPlanPJ = MambaPlanPJ or {}
	local p = MambaPlanPJ
	p.respuestas = p.respuestas or {}
	p.descartados = p.descartados or {}
	p.hechos = p.hechos or {}
	p.diag = p.diag or {}
	return p
end

function M.Falla(donde, err)
	local d = M.PJ().diag
	d.fallas = d.fallas or {}
	if #d.fallas < 30 then d.fallas[#d.fallas + 1] = (date and date("%d-%m %H:%M") or "") .. " " .. donde .. ": " .. tostring(err) end
	if geterrorhandler then geterrorhandler()(err) end
end
function M.Proteger(donde, fn, ...)
	local ok, a, b, c = pcall(fn, ...)
	if not ok then M.Falla(donde, a); return nil end
	return a, b, c
end

function M.Escuchar(f, ev)
	local ok = pcall(f.RegisterEvent, f, ev)
	if not ok then
		local d = M.PJ().diag
		d.eventosNo = d.eventosNo or {}
		d.eventosNo[ev] = true
	end
	return ok
end

-- Dinero en texto: "84 o 12 p 5 c" (sin ceros de más).
function M.Dinero(c)
	c = math.floor(c or 0)
	local neg = c < 0
	c = math.abs(c)
	local o, p, co = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
	local t = {}
	if o > 0 then t[#t + 1] = o .. " o" end
	if p > 0 then t[#t + 1] = p .. " p" end
	if co > 0 or #t == 0 then t[#t + 1] = co .. " c" end
	return (neg and "-" or "") .. table.concat(t, " ")
end

-- Avisar a quien dibuja (la sección) que algo cambió.
local oyentes = {}
function M.AlCambiar(fn) oyentes[#oyentes + 1] = fn end
function M.Cambio()
	for _, fn in ipairs(oyentes) do pcall(fn) end
end
