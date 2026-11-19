-- Mamba_Mapa: núcleo. Ajustes por cuenta, fallas al diagnóstico y cuentas de geometría (se prueban fuera del
-- juego): mapa → mundo, distancia, y la ruta corta por varios nodos (vecino más cercano + 2-opt). Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaMapa = M

M.DEFECTO = { coords = true, coordsMapa = true, escalaMapa = 1, ocultarBotones = false, ruedaZoom = true,
	nodos = true, nodosMinimapa = true, soloMios = true, verHierbas = true, verVetas = true }

function M.DB()
	MambaMapaDB = MambaMapaDB or {}
	local d = MambaMapaDB
	for k, v in pairs(M.DEFECTO) do if d[k] == nil then d[k] = v end end
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

---------------------------------------------------------------- nodos
-- Nodos de un mapa: lista de { x, y (en %), nombre, tipo "h"|"v", habilidad, clave } según el filtro.
-- filtro = { hierbas = bool, vetas = bool, habH = n|nil, habV = n|nil, nombre = "esMX"|nil }
local cacheP = {}
function M.NodosDe(mapa, filtro)
	filtro = filtro or {}
	local out = {}
	for clave, n in pairs(M.NODOS or {}) do
		local tipo, hab, nombre, porMapa = n[1], n[2], n[3], n[4]
		local quiere = (tipo == "h" and filtro.hierbas ~= false) or (tipo == "v" and filtro.vetas ~= false)
		if filtro.nombre then quiere = (nombre == filtro.nombre or clave == filtro.nombre) end
		if quiere and tipo == "h" and filtro.habH and hab > filtro.habH then quiere = false end
		if quiere and tipo == "v" and filtro.habV and hab > filtro.habV then quiere = false end
		local s = quiere and porMapa[mapa]
		if s then
			local k = clave .. "@" .. mapa
			local pts = cacheP[k]
			if not pts then
				pts = {}
				for x, y in s:gmatch("([%d%.]+),([%d%.]+)") do pts[#pts + 1] = { tonumber(x), tonumber(y) } end
				cacheP[k] = pts
			end
			for _, p in ipairs(pts) do out[#out + 1] = { x = p[1], y = p[2], nombre = nombre, tipo = tipo, habilidad = hab, clave = clave } end
		end
	end
	return out
end

-- Centro de los nodos de un objetivo ("hierbas" | "minerales") en un mapa: donde apunta "Llévame".
function M.CentroNodos(objetivo, mapa)
	local f = { hierbas = objetivo == "hierbas", vetas = objetivo == "minerales" }
	local l = M.NodosDe(mapa, f)
	if #l == 0 then return nil end
	local sx, sy = 0, 0
	for _, p in ipairs(l) do sx, sy = sx + p.x, sy + p.y end
	-- el nodo real más cercano al centro (el centro puede caer en un lago)
	local cx, cy = sx / #l, sy / #l
	local mejor, d = l[1], math.huge
	for _, p in ipairs(l) do
		local dd = (p.x - cx) ^ 2 + (p.y - cy) ^ 2
		if dd < d then mejor, d = p, dd end
	end
	return mejor.x, mejor.y
end

---------------------------------------------------------------- ruta (O8/K94)
-- tamaño del mapa en yardas (para minutos de la ruta); nil si el juego no lo da
function M.Yardas(mapa)
	if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
	local ok, _, a = pcall(C_Map.GetWorldPosFromMapPos, mapa, CreateVector2D(0, 0))
	local ok2, _, b = pcall(C_Map.GetWorldPosFromMapPos, mapa, CreateVector2D(1, 1))
	if not (ok and ok2 and a and b) then return nil end
	local ax, ay = a:GetXY()
	local bx, by = b:GetXY()
	return math.abs(ay - by), math.abs(ax - bx) -- ancho (oeste-este), alto (norte-sur)
end

local function dist(a, b, w, h)
	return math.sqrt(((a.x - b.x) * w / 100) ^ 2 + ((a.y - b.y) * h / 100) ^ 2)
end

-- Si hay muchos nodos, uno por celda de rejilla (los puntos de aparición vecinos son el mismo lugar).
local function agrupar(pts, max)
	if #pts <= max then return pts end
	local celda = 2
	while true do
		local vistos, out = {}, {}
		for _, p in ipairs(pts) do
			local k = math.floor(p.x / celda) .. ":" .. math.floor(p.y / celda)
			if not vistos[k] then vistos[k] = true; out[#out + 1] = p end
		end
		if #out <= max then return out end
		celda = celda * 1.5
	end
end

-- Ruta cerrada corta por los nodos: vecino más cercano y después 2-opt. Devuelve la lista ordenada y el largo
-- en yardas (o en "% de mapa" si no se sabe el tamaño).
function M.Ruta(pts, w, h, desde)
	w, h = w or 100, h or 100
	pts = agrupar(pts, 120)
	local n = #pts
	if n == 0 then return {}, 0 end
	local libre, orden = {}, {}
	for i = 1, n do libre[i] = true end
	-- empieza por el nodo más cercano a "desde" (tu posición) o por el primero
	local cur = 1
	if desde then
		local d = math.huge
		for i, p in ipairs(pts) do
			local dd = dist(p, desde, w, h)
			if dd < d then cur, d = i, dd end
		end
	end
	for _ = 1, n do
		orden[#orden + 1] = pts[cur]
		libre[cur] = false
		local sig, d = nil, math.huge
		for i = 1, n do
			if libre[i] then
				local dd = dist(pts[cur], pts[i], w, h)
				if dd < d then sig, d = i, dd end
			end
		end
		if not sig then break end
		cur = sig
	end
	-- 2-opt (con un tope de vueltas para no trabar el cuadro)
	local mejoro, vueltas = true, 0
	while mejoro and vueltas < 20 do
		mejoro, vueltas = false, vueltas + 1
		for i = 1, n - 2 do
			for j = i + 2, n do
				local a, b = orden[i], orden[i + 1]
				local c, d = orden[j], orden[j % n + 1]
				if dist(a, c, w, h) + dist(b, d, w, h) < dist(a, b, w, h) + dist(c, d, w, h) - 0.01 then
					local x, y = i + 1, j
					while x < y do orden[x], orden[y] = orden[y], orden[x]; x, y = x + 1, y - 1 end
					mejoro = true
				end
			end
		end
	end
	local largo = 0
	for i = 1, #orden do largo = largo + dist(orden[i], orden[i % #orden + 1], w, h) end
	return orden, largo
end

-- Minutos de una vuelta: corriendo a 7 yd/s (montura: 10,5) y ≈ 4 s por nodo. ≈ hasta que se mida.
function M.MinutosVuelta(largo, nodos, montura)
	return (largo / (montura and 10.5 or 7) + nodos * 4) / 60
end

-- K110: posición o ángulo que Forever puede esconder (valor secreto): nil, como si no se supiera
function M.Claro(v)
	if issecretvalue and issecretvalue(v) then return nil end
	return v
end
-- x, y de un vector del juego, o nil si alguno es secreto
function M.XY(v)
	if not (v and v.GetXY) then return nil end
	local x, y = v:GetXY()
	x, y = M.Claro(x), M.Claro(y)
	if type(x) ~= "number" or type(y) ~= "number" then return nil end
	return x, y
end

local oyentes = {}
function M.AlCambiar(fn) oyentes[#oyentes + 1] = fn end
function M.Cambio() for _, fn in ipairs(oyentes) do pcall(fn) end end
