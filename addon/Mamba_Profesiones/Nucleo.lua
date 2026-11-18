-- Mamba_Profesiones: núcleo. Datos guardados, fallas al diagnóstico (nunca al chat), eventos que quizá este
-- cliente no tenga, dinero en texto y la flecha de Polestar. Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaProfesiones = M

function M.DB()
	MambaProfDB = MambaProfDB or {}
	local d = MambaProfDB
	d.medido = d.medido or {}   -- [item..":"..mapa] = { unidades, segundos } medidos farmeando
	d.recetas = d.recetas or {} -- [personaje] = { [profesión] = { { nombre, link, id, cantidad, reactivos = { {id, n} } } } }
	d.diag = d.diag or {}
	return d
end

function M.Falla(donde, err)
	local d = M.DB().diag
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
		local d = M.DB().diag
		d.eventosNo = d.eventosNo or {}
		d.eventosNo[ev] = true
	end
	return ok
end

function M.Dinero(c)
	c = math.floor((c or 0) + 0.5)
	local neg = c < 0
	c = math.abs(c)
	local o, p, co = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
	local t = {}
	if o > 0 then t[#t + 1] = o .. " o" end
	if p > 0 then t[#t + 1] = p .. " p" end
	if co > 0 or #t == 0 then t[#t + 1] = co .. " c" end
	return (neg and "-" or "") .. table.concat(t, " ")
end

function M.Minutos(m)
	if not m then return "sin datos aún" end
	m = math.floor(m + 0.5)
	if m < 60 then return m .. " min" end
	return math.floor(m / 60) .. " h " .. (m % 60) .. " min"
end

-- Nombre de un mapa en el idioma del juego.
function M.Zona(mapa)
	local i = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapa)
	return i and i.name or ("mapa " .. tostring(mapa))
end

function M.NombreObjeto(id)
	local n = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
	if not n and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
	return n or ("objeto " .. id)
end

-- La flecha de Polestar a un punto (x, y en %). Es el "Llévame" de toda fila (K61).
function M.Llevame(mapa, x, y, etiqueta)
	local PS = _G.Polestar
	local N = PS and PS.Nav and PS.Nav.API
	if N and N.Navigate and mapa and x and y then
		local ok, hecho = pcall(N.Navigate, "MambaProfesiones", mapa, x / 100, y / 100, etiqueta or "Mamba")
		return ok and hecho
	end
	return false
end

-- Minutos de viaje hasta un punto, con el motor de Ir a… de Polestar (nil si no sabe). K62: el costo incluye el viaje.
function M.MinutosViaje(mapa, x, y)
	local PS = _G.Polestar
	local N = PS and PS.Nav and PS.Nav.API
	if not (N and N.Estimate and mapa and x and y) then return nil end
	local ok, s = pcall(N.Estimate, nil, nil, nil, mapa, x / 100, y / 100)
	if ok and type(s) == "number" then return s / 60 end
end

local oyentes = {}
function M.AlCambiar(fn) oyentes[#oyentes + 1] = fn end
function M.Cambio() for _, fn in ipairs(oyentes) do pcall(fn) end end
