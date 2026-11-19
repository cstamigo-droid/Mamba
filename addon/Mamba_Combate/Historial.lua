-- Mamba_Combate: historial de enemigos (C5, K96; como Spy, código propio). Cada jugador de la otra facción que
-- detecta la alerta del Tasador queda anotado por personaje: clase, nivel, gremio, cuántas veces lo viste,
-- dónde y cuándo fue la última, cuántas veces lo mataste y cuántas te mató. Desde la pestaña «Historial» de
-- «Enemigos cerca», sin escribir nada:
--   - clic en una fila: lo pones (o sacas) de tu lista «Matar»; cuando vuelve a aparecer, aviso fuerte;
--   - clic derecho: una nota corta que va rotando (Peligroso, Fácil, Me caza, Sanador, sin nota).
-- Se guardan los 300 más recientes. Licencia: GPL-3.0-only.
local _, M = ...
local H = {}
M.Historial = H
local TOPE = 300
H.NOTAS = { "Peligroso", "Fácil", "Me caza", "Sanador" }

local function db()
	local d = M.DB()
	d.historial = d.historial or {}
	return d.historial
end
local function reloj() return (time and M.Num(time())) or 0 end
local function zona()
	local z = GetRealZoneText and GetRealZoneText()
	if z == nil or M.Secreto(z) or z == "" then return nil end
	return z
end

function H.Contar()
	local n = 0
	for _ in pairs(db()) do n = n + 1 end
	return n
end

-- Olvida al más viejo cuando hay demasiados (nunca a los de la lista «Matar»).
local function recortar(h)
	if H.Contar() <= TOPE then return end
	local viejo, cuando
	for k, x in pairs(h) do
		if not x.matar and (not cuando or (x.u or 0) < cuando) then viejo, cuando = k, x.u or 0 end
	end
	if viejo then h[viejo] = nil end
end

-- Lo llama la lista de vistos (Cercanos.Visto). nuevo = recién llegado (no cada vez que se le vuelve a ver).
function H.Anotar(x, nuevo)
	if type(x) ~= "table" or type(x.nombre) ~= "string" then return end
	local h = db()
	local e = h[x.nombre]
	if not e then
		e = { p = reloj(), v = 0, m = 0, t = 0 }
		h[x.nombre] = e
		nuevo = true
		recortar(h)
	end
	e.c, e.cl = x.claseToken or e.c, x.clase or e.cl
	e.n = x.nivel or e.n
	e.g = x.gremio or e.g
	e.u = reloj()
	e.z = zona() or e.z
	if nuevo then
		e.v = (e.v or 0) + 1
		if e.matar and M.Avisos and M.Avisos.Mostrar then
			M.Avisos.Mostrar(("¡%s está cerca! Está en tu lista «Matar»"):format(x.nombre), true, true)
		end
	end
end

function H.Muerte(tipo, nombre)
	if type(nombre) ~= "string" then return end
	local e = db()[nombre]
	if not e then return end
	if tipo == "temato" then e.t = (e.t or 0) + 1 elseif tipo == "mataste" then e.m = (e.m or 0) + 1 end
end

function H.Matar(nombre)
	local e = db()[nombre]
	if not e then return false end
	e.matar = not e.matar or nil
	return e.matar and true or false
end
function H.Nota(nombre)
	local e = db()[nombre]
	if not e then return nil end
	local i = 0
	for k, n in ipairs(H.NOTAS) do if n == e.nota then i = k end end
	e.nota = H.NOTAS[i + 1] -- después de la última: sin nota
	return e.nota
end

-- Los más recientes primero; los de la lista «Matar» arriba.
function H.Lista()
	local out = {}
	for nombre, e in pairs(db()) do out[#out + 1] = { nombre = nombre, e = e } end
	table.sort(out, function(a, b)
		if (a.e.matar and 1 or 0) ~= (b.e.matar and 1 or 0) then return a.e.matar and true or false end
		return (a.e.u or 0) > (b.e.u or 0)
	end)
	return out
end

-- Filas para la ventana «Enemigos cerca» (Cercanos.lua): { arriba, abajo, cuando, nombre }
function H.Filas(nombreColor, cuandoFue)
	local P = M.Piezas
	local out = {}
	for _, x in ipairs(H.Lista()) do
		local e = x.e
		local arriba = (e.matar and (P.Color("dudoso", "MATAR") .. "  ") or "") .. nombreColor(x.nombre, e.c)
			.. (e.nota and ("  " .. P.Color("titulo", e.nota)) or "")
		local partes = { e.n and ("nivel " .. e.n) or "nivel ??", e.cl or "clase desconocida" }
		if e.g then partes[#partes + 1] = "<" .. e.g .. ">" end
		partes[#partes + 1] = ("visto %d %s"):format(e.v or 1, (e.v or 1) == 1 and "vez" or "veces")
		if (e.m or 0) > 0 or (e.t or 0) > 0 then partes[#partes + 1] = ("lo mataste %d · te mató %d"):format(e.m or 0, e.t or 0) end
		if e.z then partes[#partes + 1] = e.z end
		out[#out + 1] = { arriba = arriba, abajo = table.concat(partes, " · "), cuando = cuandoFue(e.u), nombre = x.nombre }
	end
	return out
end

-- Engancha la lista de vistos y las muertes de Cercanos (se carga antes que este archivo).
local Cz = M.Cercanos
if Cz then
	local visto, muerte = Cz.Visto, Cz.Muerte
	function Cz.Visto(info)
		local nombre = type(info) == "table" and info.nombre
		local antes = type(nombre) == "string" and not M.Secreto(nombre) and Cz.vistos[nombre]
		local t0 = antes and antes.visto
		visto(info)
		local x = type(nombre) == "string" and not M.Secreto(nombre) and Cz.vistos[nombre]
		if x then M.Proteger("historial", H.Anotar, x, (not t0) or ((x.visto or 0) - t0 > 120)) end
	end
	function Cz.Muerte(tipo, nombre)
		local r = muerte(tipo, nombre)
		if r and type(nombre) == "string" then M.Proteger("historial", H.Muerte, tipo, nombre) end
		return r
	end
end
