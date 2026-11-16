-- Medidor: cálculos puros (sin llamar al juego). Así se pueden probar fuera del juego.
-- Licencia GPL-3.0-only.
local _, M = ...

M.VERSION = 1
M.MIN_SEG = 300      -- con menos de 5 minutos medidos, las cifras "por hora" no son confiables
M.MAX_PASO = 5       -- un cuadro nunca suma más de 5 s (pantallas de carga, ventana minimizada)
M.COMISION = 0.05    -- lo que se queda la casa de subastas al vender
M.ACTIVIDADES = { misiones = true, farmeo = true, fabricar = true, subasta = true, mazmorra = true, jcj = true, otra = true }

-- Dinero en cobre -> "1o 23p 45c" (con signo si es negativo)
function M.Dinero(c)
	c = math.floor((c or 0) + 0.5)
	local signo = c < 0 and "-" or ""
	c = math.abs(c)
	local o, p, k = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
	local t = {}
	if o > 0 then t[#t + 1] = o .. "o" end
	if p > 0 then t[#t + 1] = p .. "p" end
	if k > 0 or #t == 0 then t[#t + 1] = k .. "c" end
	return signo .. table.concat(t, " ")
end

-- Número con punto de miles: 12300 -> "12.300"
function M.Miles(n)
	local s = tostring(math.floor((n or 0) + 0.5))
	local signo = s:sub(1, 1) == "-" and "-" or ""
	s = s:gsub("^-", "")
	s = s:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
	return signo .. s
end

function M.Clave(zona, act, nivel) return zona .. "|" .. act .. "|" .. nivel end

function M.NuevoCubo(zona, act, nivel)
	return { zona = zona, act = act, nivel = nivel, seg = 0, xp = 0, ganado = 0, gastado = 0, valor = 0, pasadas = 0, prof = {} }
end

-- Actividad que corresponde: dentro de una mazmorra o campo de batalla se decide sola;
-- afuera manda la que eligió el jugador.
function M.Actividad(enInstancia, tipo, elegida)
	if enInstancia then
		if tipo == "party" or tipo == "raid" then return "mazmorra" end
		if tipo == "pvp" or tipo == "arena" then return "jcj" end
	end
	return elegida or "misiones"
end

-- Experiencia ganada entre dos lecturas. Si bajó, es que subió de nivel:
-- lo que faltaba para el nivel anterior + lo que lleva del nuevo.
function M.DeltaXP(antXP, antMax, xp, max)
	if antXP == nil or xp == nil then return 0 end
	if xp >= antXP then return xp - antXP end
	return math.max(0, (antMax or 0) - antXP) + xp
end

-- Compara el inventario anterior con el actual (tablas id -> cantidad) y devuelve el valor ganado
-- o perdido en cobre. precio(id) devuelve el valor de una unidad, o nil si el juego aún no lo sabe.
-- "previo" se actualiza aquí mismo. Si un objeto no tiene precio todavía, su cantidad vieja se deja
-- igual para volver a intentarlo en la próxima lectura (así no se cuenta a 0 al entrar y a precio
-- completo al salir).
function M.DiffValor(previo, actual, precio)
	local ids, total = {}, 0
	for id in pairs(previo) do ids[id] = true end
	for id in pairs(actual) do ids[id] = true end
	for id in pairs(ids) do
		local d = (actual[id] or 0) - (previo[id] or 0)
		if d ~= 0 then
			local p = precio(id)
			if p then
				total = total + d * p
				previo[id] = actual[id]
			end
		end
	end
	return total
end

-- Puntos de profesión ganados: previo y actual son tablas id -> {nombre, rango}.
-- Una profesión recién aprendida no suma (no hay punto de partida). "previo" se actualiza aquí.
function M.DiffProf(previo, actual)
	local subidas = {}
	for id, a in pairs(actual) do
		local p = previo[id]
		if p and a.rango > p.rango then subidas[a.nombre] = a.rango - p.rango end
		previo[id] = { nombre = a.nombre, rango = a.rango }
	end
	return subidas
end

-- Valor de una unidad: el mayor entre lo que paga el vendedor y lo que deja la subasta tras la
-- comisión. Los objetos que se ligan al recogerlo (liga == 1) solo valen lo del vendedor.
-- info(id) -> precioVendedor, liga (nil si el juego no lo tiene cargado). subasta(id) -> cobre o nil.
function M.PrecioUnidad(id, info, subasta)
	local vendedor, liga = info(id)
	if vendedor == nil then return nil end
	local s = (liga ~= 1) and subasta(id) or nil
	local neto = s and s * (1 - M.COMISION) or 0
	return math.max(vendedor, neto)
end

function M.PorHora(valor, seg)
	if not seg or seg <= 0 then return 0 end
	return valor * 3600 / seg
end

-- Suma cubos (de todos los niveles) por "zona|actividad". Devuelve una lista ordenada por tiempo.
function M.Agrupar(cubos)
	local g, lista = {}, {}
	for _, c in pairs(cubos) do
		local k = c.zona .. "|" .. c.act
		local a = g[k]
		if not a then
			a = M.NuevoCubo(c.zona, c.act, c.nivel)
			a.nivelMin, a.nivelMax = c.nivel, c.nivel
			g[k] = a
			lista[#lista + 1] = a
		end
		a.seg, a.xp, a.valor = a.seg + c.seg, a.xp + c.xp, a.valor + c.valor
		a.ganado, a.gastado = a.ganado + c.ganado, a.gastado + c.gastado
		a.pasadas = a.pasadas + (c.pasadas or 0)
		a.nivelMin, a.nivelMax = math.min(a.nivelMin, c.nivel), math.max(a.nivelMax, c.nivel)
		for n, v in pairs(c.prof) do a.prof[n] = (a.prof[n] or 0) + v end
	end
	table.sort(lista, function(x, y) return x.seg > y.seg end)
	return lista
end

-- Una línea de informe para un cubo.
function M.Linea(c)
	local niv = c.nivelMin and (c.nivelMin == c.nivelMax and ("nv " .. c.nivelMin) or ("nv " .. c.nivelMin .. "-" .. c.nivelMax))
		or ("nv " .. c.nivel)
	local min = math.floor(c.seg / 60)
	local t = { c.zona .. " · " .. c.act .. " (" .. niv .. "): " .. min .. " min" }
	local neto = c.ganado - c.gastado
	if c.seg < M.MIN_SEG then
		t[#t + 1] = "poco tiempo, cifras totales: " .. M.Miles(c.xp) .. " exp · dinero " .. M.Dinero(neto)
			.. " · botín " .. M.Dinero(c.valor)
	else
		local h = function(v) return M.PorHora(v, c.seg) end
		t[#t + 1] = M.Miles(h(c.xp)) .. " exp/h"
		t[#t + 1] = "dinero " .. M.Dinero(h(neto)) .. "/h"
		t[#t + 1] = "botín " .. M.Dinero(h(c.valor)) .. "/h"
		t[#t + 1] = "total " .. M.Dinero(h(neto + c.valor)) .. "/h"
	end
	if (c.pasadas or 0) > 0 then
		t[#t + 1] = c.pasadas .. (c.pasadas == 1 and " pasada" or " pasadas") .. ", total "
			.. M.Dinero((neto + c.valor) / c.pasadas) .. " por pasada"
	end
	local nombres = {}
	for n in pairs(c.prof) do nombres[#nombres + 1] = n end
	table.sort(nombres)
	for _, n in ipairs(nombres) do
		if c.seg < M.MIN_SEG then
			t[#t + 1] = n .. " +" .. c.prof[n]
		else
			t[#t + 1] = n .. " +" .. string.format("%.1f", M.PorHora(c.prof[n], c.seg)) .. "/h"
		end
	end
	return table.concat(t, " · ")
end

-- Lo que más oro deja por hora de juego activo: solo zona+actividad con 5 min o más, de mayor a menor
-- según el total (dinero + botín) por hora.
function M.Ranking(cubos)
	local r = {}
	for _, c in ipairs(M.Agrupar(cubos)) do
		if c.seg >= M.MIN_SEG then
			c.totalHora = M.PorHora(c.ganado - c.gastado + c.valor, c.seg)
			r[#r + 1] = c
		end
	end
	table.sort(r, function(x, y) return x.totalHora > y.totalHora end)
	return r
end
