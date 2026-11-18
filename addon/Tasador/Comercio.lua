-- Tasador: el "comerciante". Cálculos PUROS (sin llamadas al juego): ventas estimadas entre escaneos,
-- liquidez, tendencia, reventa, reventa al vendedor, precio sugerido para vender, fabricar o no y eventos.
-- Regla: nunca inventa un precio. Sin datos devuelve nil y un motivo ("escanea").
-- Solo ACONSEJA: nada aquí compra, vende ni publica (prueba C12 en test_comercio.py).
-- Criterios: WOW_FOREVER/addon/TASADOR_0.4_CRITERIOS.md. Licencia: GPL-3.0.
local _, T = ...
T = T or Tasador or {}
Tasador = T

local floor, max, min = math.floor, math.max, math.min

-- "3 h 20 min" a partir de segundos.
function T.Horas(seg)
	seg = math.floor((seg or 0) / 60 + 0.5)
	local h, m = math.floor(seg / 60), seg % 60
	if h == 0 then return m .. " min" end
	if m == 0 then return h .. " h" end
	return h .. " h " .. m .. " min"
end

---------------------------------------------------------------- tiempo restante de una subasta
-- Tramos del juego: 1 corto, 2 medio, 3 largo, 4 muy largo (0 = no se sabe). Segundos MÍNIMOS que le
-- quedaban a una subasta de ese tramo. NO VERIFICADO para Forever: se usa el límite inferior más bajo
-- conocido (clásico: largo 2-8 h, muy largo 8 h o más; moderno: largo 2-12 h, muy largo 12-48 h).
T.TRAMO_MIN = { [0] = 0, [1] = 0, [2] = 1800, [3] = 7200, [4] = 28800 }
T.VENTANA_MAX = 48 * 3600 -- con más tiempo entre escaneos todo pudo vencer: no se estima nada

local function suma(tramos)
	local u = 0
	if type(tramos) == "table" then for _, n in pairs(tramos) do u = u + n end end
	return u
end

---------------------------------------------------------------- C3: ventas entre dos fotos
-- foto[id][vendedor][precioUnidad] = { [tramo] = unidades }. segundos = tiempo real entre las dos fotos.
-- Unidades que desaparecieron y que NO pudieron vencer = vendidas (mínimo). Dos topes conservadores:
--   por precio: perdidas - las que pudieron vencer;
--   por vendedor: si el mismo vendedor tiene ahora tantas como antes (republicó a otro precio), 0.
-- Devuelve ventas[id] = { u = unidades, c = cobre }, una entrada por cada objeto observado (u puede ser 0),
-- o nil si no se puede estimar (primera foto, tiempo raro o más de 48 h).
function T.CompararFotos(vieja, nueva, segundos)
	if type(vieja) ~= "table" or type(nueva) ~= "table" then return nil end
	if type(segundos) ~= "number" or segundos <= 0 or segundos > T.VENTANA_MAX then return nil end
	local ventas = {}
	for id, vendedores in pairs(vieja) do
		local ahoraItem = nueva[id] or {}
		local u, c = 0, 0
		for quien, precios in pairs(vendedores) do
			local ahora = ahoraItem[quien] or {}
			local porPrecio, cobre, antesTot, vencibleTot, ahoraTot = 0, 0, 0, 0, 0
			for precio, tramos in pairs(precios) do
				local antes, vencible = 0, 0
				for tr, n in pairs(tramos) do
					antes = antes + n
					if (T.TRAMO_MIN[tr] or 0) <= segundos then vencible = vencible + n end
				end
				local perdidas = max(0, antes - suma(ahora[precio]) - vencible)
				porPrecio, cobre = porPrecio + perdidas, cobre + perdidas * precio
				antesTot, vencibleTot = antesTot + antes, vencibleTot + vencible
			end
			for _, tramos in pairs(ahora) do ahoraTot = ahoraTot + suma(tramos) end
			local vendidas = min(porPrecio, max(0, antesTot - ahoraTot - vencibleTot))
			if vendidas > 0 then
				u = u + vendidas
				c = c + cobre * vendidas / porPrecio -- precio promedio de lo perdido a cada precio
			end
		end
		ventas[id] = { u = u, c = c }
	end
	return ventas
end

-- Anota las ventas en la historia diaria: v = unidades, vc = cobre, o = segundos observados.
function T.AnotarVentas(precios, ventas, dia, segundos)
	if type(ventas) ~= "table" then return end
	local d = tostring(dia)
	for id, x in pairs(ventas) do
		local clave = tostring(id)
		local e = precios[clave]
		if type(e) ~= "table" then e = { h = {}, l = {}, a = {} }; precios[clave] = e end
		e.v, e.vc, e.o = e.v or {}, e.vc or {}, e.o or {}
		e.v[d] = (e.v[d] or 0) + x.u
		e.vc[d] = (e.vc[d] or 0) + x.c
		e.o[d] = (e.o[d] or 0) + segundos
	end
end

---------------------------------------------------------------- C4: liquidez
T.HORAS_MIN_LIQUIDEZ = 12
-- Ventas por día de los últimos 7 días (con hoy). Devuelve { ventasDia, realizado, horas, unidades,
-- midiendo } o nil si nunca se observó. ventasDia y realizado son nil si midiendo (menos de 12 h vistas).
function T.Liquidez(e, hoyDia, dias)
	if type(e) ~= "table" or type(e.o) ~= "table" or not hoyDia then return nil end
	local desde = hoyDia - (dias or 7) + 1
	local u, c, s = 0, 0, 0
	for d, seg in pairs(e.o) do
		local n = tonumber(d)
		if n and n >= desde and n <= hoyDia then
			s = s + seg
			u = u + ((e.v and e.v[d]) or 0)
			c = c + ((e.vc and e.vc[d]) or 0)
		end
	end
	if s <= 0 then return nil end
	local r = { horas = s / 3600, unidades = u }
	r.midiendo = r.horas < T.HORAS_MIN_LIQUIDEZ
	if not r.midiendo then r.ventasDia = u / s * 86400 end
	if u > 0 then r.realizado = c / u end
	return r
end

---------------------------------------------------------------- series y precio normal
-- Precio de un día: el percentil 20 (p); si el día es de antes de 0.4 o de Auctionator, el mínimo (l).
local function precioDia(e, d)
	return (type(e.p) == "table" and e.p[d]) or (type(e.l) == "table" and e.l[d]) or (type(e.h) == "table" and e.h[d]) or nil
end

-- Días con precio, del más viejo al más nuevo: { {dia, precio}, ... }
function T.Serie(e, hasta)
	local s = {}
	if type(e) ~= "table" then return s end
	local vistos = {}
	for _, campo in ipairs({ "p", "l", "h" }) do
		if type(e[campo]) == "table" then
			for d in pairs(e[campo]) do
				local n = tonumber(d)
				if n and not vistos[n] and (not hasta or n <= hasta) then
					vistos[n] = true
					local p = precioDia(e, d)
					if p then s[#s + 1] = { n, p } end
				end
			end
		end
	end
	table.sort(s, function(a, b) return a[1] < b[1] end)
	return s
end

local function mediana(t)
	if #t == 0 then return nil end
	table.sort(t)
	local m = floor((#t + 1) / 2)
	if #t % 2 == 1 then return t[m] end
	return (t[m] + t[m + 1]) / 2
end
T.Mediana = mediana

-- Precio "normal": mediana del precio de los 7 días ANTES de hoy (hoy no cuenta: no se valida con el mismo
-- dato que se quiere juzgar). Pide 2 días o más. Devuelve precio, días usados.
function T.PrecioNormal(e, hoyDia)
	if not hoyDia then return nil end
	local v = {}
	for _, x in ipairs(T.Serie(e, hoyDia - 1)) do
		if x[1] >= hoyDia - 7 then v[#v + 1] = x[2] end
	end
	if #v < 2 then return nil, #v end
	return mediana(v), #v
end

---------------------------------------------------------------- C9: tendencia
-- "bajando": los últimos 4 días escaneados (dentro de 10 días) bajan 3 veces seguidas y en total 10 % o más.
-- "subiendo": lo mismo hacia arriba. "estable": hay datos y ninguna de las dos. nil: menos de 4 días.
function T.Tendencia(e, hoyDia)
	local s = T.Serie(e, hoyDia)
	local u = {}
	for i = #s, 1, -1 do
		if hoyDia and s[i][1] < hoyDia - 9 then break end
		table.insert(u, 1, s[i][2])
		if #u == 4 then break end
	end
	if #u < 4 then return nil end
	local baja, sube = true, true
	for i = 2, 4 do
		if not (u[i] < u[i - 1]) then baja = false end
		if not (u[i] > u[i - 1]) then sube = false end
	end
	if baja and u[4] <= u[1] * 0.9 then return "bajando" end
	if sube and u[4] >= u[1] * 1.1 then return "subiendo" end
	return "estable"
end

---------------------------------------------------------------- escalera de precios de la foto
-- foto de UN objeto -> { {precio, unidades}, ... } de menor a mayor. Sin las subastas del jugador.
function T.Escalera(fotoItem, sinVendedor)
	local porPrecio = {}
	if type(fotoItem) == "table" then
		for quien, precios in pairs(fotoItem) do
			if quien ~= sinVendedor then
				for precio, tramos in pairs(precios) do porPrecio[precio] = (porPrecio[precio] or 0) + suma(tramos) end
			end
		end
	end
	local e = {}
	for p, u in pairs(porPrecio) do if u > 0 then e[#e + 1] = { p, u } end end
	table.sort(e, function(a, b) return a[1] < b[1] end)
	return e
end

---------------------------------------------------------------- depósito y probabilidad de venta
-- Depósito de UNA publicación de k unidades. MODELO, NO VERIFICADO para Forever: % del pago del vendedor
-- (ajustable con /tasador deposito) con un mínimo por publicación. Si el juego sabe calcularlo, el
-- puente del juego pasa ajustes.depositoReal(id, k) y se usa ese.
function T.Deposito(id, vendedor, k, a)
	if type(a.depositoReal) == "function" then
		local ok, v = pcall(a.depositoReal, id, k)
		if ok and type(v) == "number" and v >= 0 then return v end
	end
	return max(a.depositoMin or 0, (vendedor or 0) * (a.depositoPct or 0) * k)
end

-- Probabilidad de vender k unidades en una publicación: lo que se vende en su duración contra lo que hay
-- delante en la fila (más barato o igual) más las k. MODELO (supone ventas parejas en el día).
function T.ProbVenta(ventasDia, delante, k, horas)
	if not ventasDia or ventasDia <= 0 then return nil end
	return min(1, ventasDia * (horas / 24) / (delante + k))
end

-- Pérdida esperada de depósitos hasta vender: publicar hasta que salga (geométrica) => dep * (1 - p) / p.
function T.PerdidaDeposito(dep, p)
	if not p or p <= 0 then return nil end
	return dep * (1 - p) / p
end

---------------------------------------------------------------- C6: comprar para revender
-- e = historia del objeto, fotoItem = su foto, vendedor = lo que paga el PNJ por unidad (o 0),
-- edadFoto = segundos desde la foto, a = ajustes. Devuelve oportunidad o nil, motivo.
function T.Reventa(e, fotoItem, vendedor, hoyDia, edadFoto, a, id, jugador)
	if not fotoItem or not edadFoto or edadFoto > (a.edadFotoMax or 3600) then return nil, "escanea" end
	local normal, nDias = T.PrecioNormal(e, hoyDia)
	if not normal then return nil, "historia corta (" .. (nDias or 0) .. " días antes de hoy; hacen falta 2)" end
	if T.Tendencia(e, hoyDia) == "bajando" then return nil, "el precio viene bajando" end
	local liq = T.Liquidez(e, hoyDia)
	if not liq or liq.midiendo then return nil, "liquidez sin medir (hacen falta 12 h de escaneos)" end
	if liq.ventasDia < (a.minVentasDia or 5) then return nil, "se vende poco" end
	local venta = normal
	if liq.realizado and liq.realizado < venta then venta = liq.realizado end -- lo que de verdad se pagó
	local cobro = venta * (1 - a.comision)
	local escalera = T.Escalera(fotoItem, jugador)
	local tope = floor(liq.ventasDia) -- nunca más de lo que se vende en un día
	local horas = a.horasPublicacion or 24
	-- Comprar escalones mientras cada uno deje el margen mínimo por unidad.
	local compra = {}
	local k = 0
	for _, esc in ipairs(escalera) do
		local p, u = esc[1], esc[2]
		if (cobro - p) / p < (a.minMargen or 0.1) or k >= tope then break end
		local toma = min(u, tope - k)
		compra[#compra + 1] = { p, toma }
		k = k + toma
	end
	-- Si el total no pasa (depósito incluido), se quita el escalón más caro y se vuelve a probar.
	while #compra > 0 do
		local costo, n, hasta = 0, 0, 0
		for _, c in ipairs(compra) do costo, n, hasta = costo + c[1] * c[2], n + c[2], c[1] end
		local delante = 0
		for _, esc in ipairs(escalera) do
			if esc[1] <= venta then delante = delante + esc[2] end
		end
		delante = max(0, delante - n) -- lo que compras ya no está delante
		local p = T.ProbVenta(liq.ventasDia, delante, n, horas)
		local dep = T.Deposito(id, vendedor, n, a)
		local perdida = T.PerdidaDeposito(dep, p)
		if perdida and p >= (a.probMin or 0.2) then
			local ganancia = cobro * n - costo - perdida
			local pct = ganancia / costo
			if ganancia > 0 and pct >= (a.minMargen or 0.1) and ganancia >= (a.minGanancia or 10000) then
				return {
					tipo = "reventa", id = id, comprarHasta = hasta, unidades = n, costo = costo, venta = venta,
					ganancia = ganancia, pct = pct, ventasDia = liq.ventasDia, prob = p, deposito = dep,
					perdidaDeposito = perdida, diasVender = (delante + n) / liq.ventasDia, normal = normal,
				}
			end
		end
		table.remove(compra)
	end
	return nil, "no hay margen"
end

---------------------------------------------------------------- C7: reventa al vendedor (PNJ)
function T.ReventaVendedor(fotoItem, vendedor, edadFoto, a, id, jugador)
	if not vendedor or vendedor <= 0 then return nil end
	if not fotoItem or not edadFoto or edadFoto > (a.edadFotoMax or 3600) then return nil, "escanea" end
	local u, costo, ganancia, hasta = 0, 0, 0, 0
	for _, esc in ipairs(T.Escalera(fotoItem, jugador)) do
		if esc[1] >= vendedor then break end
		u, costo, hasta = u + esc[2], costo + esc[1] * esc[2], esc[1]
		ganancia = ganancia + (vendedor - esc[1]) * esc[2]
	end
	if u == 0 or ganancia < (a.minVendedor or 100) then return nil end
	return { tipo = "vendedor", id = id, comprarHasta = hasta, unidades = u, costo = costo, venta = vendedor,
		ganancia = ganancia, pct = ganancia / costo }
end

---------------------------------------------------------------- C8 y C9: ¿a cuánto vendo y cuándo?
-- Devuelve { accion = "vende ya" | "vende" | "espera" | "vendedor", precio, cuantas, motivo }
-- o nil, "escanea" si no hay foto reciente.
function T.ConsejoVenta(e, fotoItem, vendedor, hoyDia, edadFoto, a, jugador)
	if not fotoItem or not edadFoto or edadFoto > (a.edadFotoVenta or 6 * 3600) then return nil, "escanea" end
	local escalera = T.Escalera(fotoItem, jugador)
	local r = {}
	local tendencia = T.Tendencia(e, hoyDia)
	local normal = T.PrecioNormal(e, hoyDia)
	local liq = T.Liquidez(e, hoyDia)
	if liq and liq.ventasDia then r.cuantas = math.max(1, floor(liq.ventasDia * (a.horasPublicacion or 24) / 24)) end
	r.tendencia, r.normal = tendencia, normal
	if #escalera == 0 then
		if not normal then return nil, "nadie lo vende hoy y no tengo su precio normal" end
		r.accion, r.precio = "vende", normal
		r.motivo = "Nadie lo vende hoy: publica a su precio normal."
	else
		local minimo = escalera[1][1]
		r.precio = minimo
		if tendencia == "bajando" then
			r.accion, r.motivo = "vende ya", "El precio bajó 3 días seguidos: vende hoy, al más barato."
		elseif normal and minimo < normal * 0.8 then
			r.accion, r.precio = "espera", normal
			r.motivo = "Hoy alguien vende muy barato (" .. T.Dinero(minimo) .. "); lo normal es " .. T.Dinero(normal) .. "."
		else
			r.accion, r.motivo = "vende", "Publica igual al más barato de hoy."
		end
	end
	local neto = r.precio * (1 - a.comision)
	r.neto = neto
	if vendedor and vendedor > 0 and neto <= vendedor then
		r.accion, r.precio, r.motivo = "vendedor", vendedor, "El vendedor paga igual o más que la subasta."
	end
	return r
end

---------------------------------------------------------------- C10: fabricar o no
-- receta = { producto = id, n = unidades que salen, mats = { {id, cantidad}, ... } }
-- precioDe(id) -> precio por unidad o nil. liqDe(id) -> tabla de T.Liquidez o nil.
function T.Fabricar(receta, precioDe, a, vendedorDe, liqDe)
	local costo, falta = 0, {}
	for _, m in ipairs(receta.mats or {}) do
		local p = precioDe(m[1])
		if not p then falta[#falta + 1] = m[1] else costo = costo + p * m[2] end
	end
	local pv = precioDe(receta.producto)
	if not pv then falta[#falta + 1] = receta.producto end
	if #falta > 0 then return { producto = receta.producto, falta = falta } end
	local n = receta.n or 1
	local liq = liqDe and liqDe(receta.producto)
	local p = liq and liq.ventasDia and T.ProbVenta(liq.ventasDia, 0, n, a.horasPublicacion or 24) or nil
	local dep = T.Deposito(receta.producto, vendedorDe and vendedorDe(receta.producto) or 0, n, a)
	-- sin liquidez medida se supone 1 de cada 2 publicaciones vendida (pérdida = 1 depósito) y se avisa
	local perdida = T.PerdidaDeposito(dep, p or 0.5)
	local venta = pv * n * (1 - a.comision) - perdida
	return { producto = receta.producto, costo = costo, venta = venta, ganancia = venta - costo,
		pct = costo > 0 and (venta - costo) / costo or nil, sinLiquidez = p == nil, n = n }
end

---------------------------------------------------------------- C11: eventos (medir, no suponer)
T.EVENTOS = {
	{ nombre = "Primeras bandas (Barrow Deeps, Hyjal, Onyxia)", fecha = { year = 2026, month = 12, day = 9 },
		fuente = "Blizzard, 20-10-2026 (CAMBIOS_FOREVER.md)" },
}
T.GRUPOS_EVENTO = { hierba = "Hierbas", consumible = "Consumibles", control = "Control (otros materiales)" }

-- Cambio del precio mediano de cada grupo: 7 días antes contra 7 días desde el evento.
-- Devuelve { grupos = { k = { n, cambio } }, efecto = { hierba, consumible } (cambio - control) }.
function T.MedirEvento(precios, diaEvento, ventana)
	ventana = ventana or 7
	local cambios = { hierba = {}, consumible = {}, control = {} }
	local antesN = { hierba = 0, consumible = 0, control = 0 }
	for _, e in pairs(precios or {}) do
		local k = type(e) == "table" and e.k
		if k and cambios[k] then
			local antes, despues = {}, {}
			for _, x in ipairs(T.Serie(e)) do
				if x[1] >= diaEvento - ventana and x[1] < diaEvento then antes[#antes + 1] = x[2]
				elseif x[1] >= diaEvento and x[1] < diaEvento + ventana then despues[#despues + 1] = x[2] end
			end
			if #antes >= 2 then antesN[k] = antesN[k] + 1 end
			if #antes >= 2 and #despues >= 2 then
				local a, d = mediana(antes), mediana(despues)
				if a and a > 0 then cambios[k][#cambios[k] + 1] = d / a - 1 end
			end
		end
	end
	local r = { grupos = {}, antes = antesN, efecto = {} }
	for k, lista in pairs(cambios) do r.grupos[k] = { n = #lista, cambio = #lista >= 5 and mediana(lista) or nil } end
	local ctl = r.grupos.control.cambio
	for _, k in ipairs({ "hierba", "consumible" }) do
		if r.grupos[k].cambio and ctl then r.efecto[k] = r.grupos[k].cambio - ctl end
	end
	return r
end

-- Categoría que se guarda 60 días (para medir eventos): clase 7 subclase 9 = hierba; clase 0 = consumible;
-- otros materiales (clase 7) = control.
function T.CategoriaEvento(clase, subclase)
	if clase == 7 and subclase == 9 then return "hierba" end
	if clase == 0 then return "consumible" end
	if clase == 7 then return "control" end
	return nil
end
