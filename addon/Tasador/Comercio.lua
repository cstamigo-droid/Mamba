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
-- Con más de 8 h entre escaneos todo lo de tramo "muy largo" pudo vencer: no se mide nada (y esas horas no
-- cuentan como observadas, para no "medir" 0 ventas por construcción).
T.VENTANA_MAX = 8 * 3600

local function suma(tramos)
	local u = 0
	if type(tramos) == "table" then for _, n in pairs(tramos) do u = u + n end end
	return u
end

-- La foto de cada objeto se guarda COMPACTA (un texto) para no inflar TasadorDB:
-- "vendedor\tprecio\ttramo\tunidades;..." <-> { [vendedor] = { [precio] = { [tramo] = unidades } } }
function T.FotoTexto(t)
	if type(t) ~= "table" then return t end
	local partes = {}
	for quien, precios in pairs(t) do
		for precio, tramos in pairs(precios) do
			for tr, u in pairs(tramos) do partes[#partes + 1] = quien .. "\t" .. precio .. "\t" .. tr .. "\t" .. u end
		end
	end
	return table.concat(partes, ";")
end
function T.FotoTabla(x)
	if type(x) ~= "string" then return x end
	local t = {}
	for quien, precio, tr, u in x:gmatch("([^\t;]*)\t(%d+)\t(%d+)\t(%d+)") do
		precio, tr, u = tonumber(precio), tonumber(tr), tonumber(u)
		t[quien] = t[quien] or {}
		t[quien][precio] = t[quien][precio] or {}
		t[quien][precio][tr] = (t[quien][precio][tr] or 0) + u
	end
	return t
end

-- Si en alguna de las dos fotos un objeto tiene subastas sin dueño conocido ("?"), no se puede seguir a cada
-- vendedor: todo el objeto se junta en uno solo (tope del objeto entero). Si no, "Ana" en una foto y "?" en
-- la otra parecería que Ana vendió todo.
local function juntar(t)
	local uno = {}
	for _, precios in pairs(t) do
		for precio, tramos in pairs(precios) do
			uno[precio] = uno[precio] or {}
			for tr, u in pairs(tramos) do uno[precio][tr] = (uno[precio][tr] or 0) + u end
		end
	end
	return { ["*"] = uno }
end

---------------------------------------------------------------- C3: unidades desaparecidas entre dos fotos
-- foto[id][vendedor][precioUnidad] = { [tramo] = unidades }. segundos = tiempo real entre las dos fotos.
-- Cuenta como "desaparecida antes de vencer" (casi siempre una venta) lo que cumple TODO:
--   * no pudo vencer en ese tiempo (por su tramo de tiempo restante);
--   * su precio es igual o menor que el más barato que quedó: quien compra materiales se lleva primero lo más
--     barato, así que lo que desaparece MÁS CARO que algo que sigue ahí fue casi siempre una cancelación;
--   * el mismo vendedor no tiene ahora tantas como antes (si republicó a otro precio, no es venta);
--   * no es del jugador (tus subastas no miden al mercado).
-- Puede incluir cancelaciones de lo más barato: por eso se llama "desaparecidas", no "vendidas seguro".
-- Devuelve ventas[id] = { u = unidades, c = cobre }, una entrada por cada objeto observado (u puede ser 0),
-- o nil si no se puede estimar (primera foto, tiempo raro o más de 48 h).
function T.CompararFotos(vieja, nueva, segundos, jugador)
	if type(vieja) ~= "table" or type(nueva) ~= "table" then return nil end
	if type(segundos) ~= "number" or segundos <= 0 or segundos > T.VENTANA_MAX then return nil end
	local ventas = {}
	for id, vendedores in pairs(vieja) do
		vendedores = T.FotoTabla(vendedores)
		local ahoraItem = T.FotoTabla(nueva[id]) or {}
		if jugador then vendedores[jugador], ahoraItem[jugador] = nil, nil end
		if vendedores["?"] or ahoraItem["?"] then vendedores, ahoraItem = juntar(vendedores), juntar(ahoraItem) end
		local minNuevo
		for quien, precios in pairs(ahoraItem) do
			if quien ~= jugador then
				for precio, tramos in pairs(precios) do
					if suma(tramos) > 0 and (not minNuevo or precio < minNuevo) then minNuevo = precio end
				end
			end
		end
		local u, c = 0, 0
		for quien, precios in pairs(vendedores) do
			if quien ~= jugador then
				local ahora = ahoraItem[quien] or {}
				local porPrecio, cobre, antesTot, vencibleTot, ahoraTot = 0, 0, 0, 0, 0
				for precio, tramos in pairs(precios) do
					local antes, vencible = 0, 0
					for tr, n in pairs(tramos) do
						antes = antes + n
						if (T.TRAMO_MIN[tr] or 0) <= segundos then vencible = vencible + n end
					end
					local perdidas = max(0, antes - suma(ahora[precio]) - vencible)
					if minNuevo and precio > minNuevo then perdidas = 0 end
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
-- Ventas por día de los últimos 7 días (con hoy). Devuelve { ventasDia, ventasDiaBaja, realizado, horas,
-- unidades, midiendo } o nil si nunca se observó. ventasDiaBaja = límite inferior (90 %, aproximación de
-- Poisson): con pocas ventas vistas el número real puede ser mucho menor, y las decisiones usan este.
-- Ojo: solo se mide en las horas en que escaneas (si escaneas de noche, mide la noche).
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
	if not r.midiendo then
		r.ventasDia = u / s * 86400
		r.ventasDiaBaja = max(0, u - 1.2816 * math.sqrt(u)) / s * 86400
	end
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

-- Precio "normal": mediana del precio de los 7 días ANTES de hoy. Pide 2 días o más. Devuelve precio, días.
function T.PrecioNormal(e, hoyDia)
	if not hoyDia then return nil end
	local v = {}
	for _, x in ipairs(T.Serie(e, hoyDia - 1)) do
		if x[1] >= hoyDia - 7 then v[#v + 1] = x[2] end
	end
	if #v < 2 then return nil, #v end
	return mediana(v), #v
end

---------------------------------------------------------------- C9: tendencia (v2)
-- Pendiente robusta (Theil-Sen: mediana de las pendientes entre cada par de días) de los últimos 7 días
-- escaneados dentro de 10 días, con hoy. Cambio = pendiente × días cubiertos / precio mediano.
-- "bajando" si el cambio es -10 % o peor; "subiendo" si +10 % o más; "estable" si no. nil con menos de 4 días.
-- Un rebote de un día no esconde una caída (la versión 1, "3 bajadas seguidas", sí lo hacía).
function T.Tendencia(e, hoyDia)
	local s = T.Serie(e, hoyDia)
	local u = {}
	for i = #s, 1, -1 do
		if hoyDia and s[i][1] < hoyDia - 9 then break end
		table.insert(u, 1, s[i])
		if #u == 7 then break end
	end
	if #u < 4 then return nil end
	local pend, precios = {}, {}
	for i = 1, #u do
		precios[#precios + 1] = u[i][2]
		for j = i + 1, #u do pend[#pend + 1] = (u[j][2] - u[i][2]) / (u[j][1] - u[i][1]) end
	end
	local nivel = mediana(precios)
	if not nivel or nivel <= 0 then return nil end
	local cambio = mediana(pend) * (u[#u][1] - u[1][1]) / nivel
	if cambio <= -0.10 then return "bajando", cambio end
	if cambio >= 0.10 then return "subiendo", cambio end
	return "estable", cambio
end

---------------------------------------------------------------- escalera de precios de la foto
-- foto de UN objeto -> { {precio, unidades}, ... } de menor a mayor. Sin las subastas del jugador.
function T.Escalera(fotoItem, sinVendedor)
	fotoItem = T.FotoTabla(fotoItem)
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

-- Percentil q de una escalera (por unidades).
local function percentilEscalera(esc, q)
	local total = 0
	for _, x in ipairs(esc) do total = total + x[2] end
	if total <= 0 then return nil end
	local acum = 0
	for _, x in ipairs(esc) do
		acum = acum + x[2]
		if acum >= total * q then return x[1] end
	end
	return esc[#esc][1]
end
T.PercentilEscalera = percentilEscalera

-- Unidades más baratas o iguales a un precio.
local function delanteDe(esc, precio)
	local d = 0
	for _, x in ipairs(esc) do if x[1] <= precio then d = d + x[2] end end
	return d
end
T.Delante = delanteDe

-- Precio sugerido para publicar: con ventas medidas, el escalón donde lo que queda delante pasa de un día de
-- ventas (lo de más abajo se vende antes que tú de todos modos: igualarlo no sirve). Sin ventas medidas, el
-- percentil 20 de hoy: así una unidad suelta a 1 cobre no fija tu precio.
function T.PrecioSugerido(esc, ventasDia)
	if #esc == 0 then return nil end
	if not ventasDia then return percentilEscalera(esc, 0.2) end
	local acum = 0
	for _, x in ipairs(esc) do
		acum = acum + x[2]
		if acum > ventasDia then return x[1] end
	end
	return esc[#esc][1]
end

---------------------------------------------------------------- depósito, probabilidad de venta y riesgo
-- Depósito de UNA publicación de k unidades. MODELO, NO VERIFICADO para Forever: % del pago del vendedor por
-- cada 12 h de publicación (ajustable con /tasador deposito), con un mínimo por publicación. Más horas =
-- más depósito (si no, alargar la publicación parecería gratis). Si el juego sabe calcularlo, el puente del
-- juego pasa a.depositoReal(id, k) y se usa ese.
function T.Deposito(id, vendedor, k, a)
	if type(a.depositoReal) == "function" then
		local ok, v = pcall(a.depositoReal, id, k)
		if ok and type(v) == "number" and v >= 0 then return v end
	end
	return max(a.depositoMin or 0, (vendedor or 0) * (a.depositoPct or 0) * k * (a.horasPublicacion or 12) / 12)
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

---------------------------------------------------------------- C6: comprar para revender (v2)
-- e = historia del objeto, fotoItem = su foto, vendedor = lo que paga el PNJ por unidad (o 0),
-- edadFoto = segundos desde la foto, a = ajustes. Devuelve oportunidad o nil, motivo.
-- Precio de reventa = el MENOR entre el normal (días anteriores), el de lo que desapareció y el percentil 20
-- de lo que queda hoy después de tu compra (los demás publican al precio de hoy, no al de la semana pasada).
-- Ganancia = cobro - costo - depósito que se pierde - riesgo de que el precio baje mientras esperas.
function T.Reventa(e, fotoItem, vendedor, hoyDia, edadFoto, a, id, jugador)
	if not fotoItem or not edadFoto or edadFoto > (a.edadFotoMax or 3600) then return nil, "escanea" end
	local tendencia = T.Tendencia(e, hoyDia)
	if not tendencia then return nil, "historia corta (hacen falta 4 días con escaneo)" end
	if tendencia == "bajando" then return nil, "el precio viene bajando" end
	local normal = T.PrecioNormal(e, hoyDia)
	if not normal then return nil, "historia corta" end
	local liq = T.Liquidez(e, hoyDia)
	if not liq or liq.midiendo then return nil, "liquidez sin medir (hacen falta 12 h de escaneos)" end
	local vd = liq.ventasDiaBaja
	if vd < (a.minVentasDia or 5) then return nil, "se vende poco" end
	local venta0 = normal
	if liq.realizado and liq.realizado < venta0 then venta0 = liq.realizado end
	local escalera = T.Escalera(fotoItem, jugador)
	local tope = floor(vd) -- nunca más de lo que se vende en un día (límite bajo)
	local horas = a.horasPublicacion or 24
	local compra, k = {}, 0
	for _, esc in ipairs(escalera) do
		local p, u = esc[1], esc[2]
		if (venta0 * (1 - a.comision) - p) / p < (a.minMargen or 0.1) or k >= tope then break end
		local toma = min(u, tope - k)
		compra[#compra + 1] = { p, toma }
		k = k + toma
	end
	-- Si el total no pasa, se quita el escalón más caro y se vuelve a probar.
	while #compra > 0 do
		local costo, n, hasta = 0, 0, 0
		local quedan = {}
		for i, esc in ipairs(escalera) do quedan[i] = { esc[1], esc[2] } end
		for i, c in ipairs(compra) do
			costo, n, hasta = costo + c[1] * c[2], n + c[2], c[1]
			quedan[i][2] = quedan[i][2] - c[2]
		end
		local resto = {}
		for _, x in ipairs(quedan) do if x[2] > 0 then resto[#resto + 1] = x end end
		local venta = venta0
		local p20 = percentilEscalera(resto, 0.2)
		if p20 and p20 < venta then venta = p20 end
		local cobro = venta * (1 - a.comision)
		local delante = delanteDe(resto, venta)
		local p = T.ProbVenta(vd, delante, n, horas)
		local dep = T.Deposito(id, vendedor, n, a)
		local perdida = T.PerdidaDeposito(dep, p)
		local dias = (delante + n) / vd
		if perdida and p >= (a.probMin or 0.2) and dias <= (a.maxDiasVender or 2) then
			local riesgo = cobro * n * (a.riesgoDia or 0.05) * dias
			local ganancia = cobro * n - costo - perdida - riesgo
			local pct = ganancia / costo
			if ganancia > 0 and pct >= (a.minMargen or 0.1) and ganancia >= (a.minGanancia or 10000) then
				return {
					tipo = "reventa", id = id, comprarHasta = hasta, unidades = n, costo = costo, venta = venta,
					ganancia = ganancia, pct = pct, ventasDia = vd, prob = p, deposito = dep, riesgo = riesgo,
					perdidaDeposito = perdida, diasVender = dias, normal = normal, horas = liq.horas,
					diasHistoria = #T.Serie(e, hoyDia),
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

---------------------------------------------------------------- C8 y C9: ¿a cuánto vendo y cuándo? (v2)
-- Devuelve { accion = "vende ya" | "vende" | "espera" | "vendedor", precio, cuantas, motivo }
-- o nil, "escanea" si no hay foto reciente. cantidad = cuántas tienes (para el depósito).
-- "espera" solo si hay tendencia medida (4 días) que no baja Y lo barato es poco (el percentil 20 de hoy
-- sigue normal): eso es alguien rematando. Si todo el mercado de hoy está abajo, es el precio nuevo: vende.
function T.ConsejoVenta(e, fotoItem, vendedor, hoyDia, edadFoto, a, jugador, cantidad, id)
	if not fotoItem or not edadFoto or edadFoto > (a.edadFotoVenta or 6 * 3600) then return nil, "escanea" end
	cantidad = cantidad or 1
	local escalera = T.Escalera(fotoItem, jugador)
	local r = {}
	local tendencia = T.Tendencia(e, hoyDia)
	local normal = T.PrecioNormal(e, hoyDia)
	local liq = T.Liquidez(e, hoyDia)
	local vd = liq and liq.ventasDiaBaja
	if vd then r.cuantas = math.max(1, floor(vd * (a.horasPublicacion or 24) / 24)) end
	r.tendencia, r.normal = tendencia, normal
	if #escalera == 0 then
		if not normal then return nil, "nadie lo vende hoy y no tengo su precio normal" end
		r.accion, r.precio = "vende", normal
		r.motivo = "Nadie lo vende hoy: publica a su precio normal."
	else
		local minimo, p20 = escalera[1][1], percentilEscalera(escalera, 0.2)
		r.precio = T.PrecioSugerido(escalera, vd)
		if tendencia == "bajando" then
			r.accion, r.motivo = "vende ya", "El precio viene bajando (10 % o más en los últimos días): vende hoy."
		elseif tendencia and normal and minimo < normal * 0.8 and p20 >= normal * 0.8 then
			r.accion, r.precio = "espera", p20
			r.motivo = "Unos pocos venden muy barato (" .. T.Dinero(minimo) .. "); la mayoría está a " .. T.Dinero(p20) .. "."
		elseif normal and p20 < normal * 0.8 then
			r.accion = "vende"
			r.motivo = "Hoy todo el mercado está más bajo que lo normal (" .. T.Dinero(normal) .. "): es el precio de hoy. No hay datos de que vuelva a subir."
		else
			r.accion, r.motivo = "vende", vd and "Precio donde lo de delante se vende en un día." or "Precio del 20 % más barato de hoy (ventas sin medir)."
		end
	end
	-- ¿La subasta deja más que el vendedor? Con la comisión y el depósito que se pierde si no se vende.
	local delante = delanteDe(escalera, r.precio)
	local p = T.ProbVenta(vd, delante, cantidad, a.horasPublicacion or 24) or 0.5
	local perdida = T.PerdidaDeposito(T.Deposito(id, vendedor, cantidad, a), p) or 0
	r.neto = r.precio * (1 - a.comision) - perdida / cantidad
	if vendedor and vendedor > 0 and r.neto < vendedor * (a.margen or 1.5) then
		r.accion, r.precio, r.motivo = "vendedor", vendedor, "La subasta no deja al menos 1,5 veces lo que paga el vendedor (después de comisión y depósito)."
	end
	return r
end

---------------------------------------------------------------- C10: fabricar o no
-- receta = { producto = id, n = unidades que salen, mats = { {id, cantidad}, ... } }
-- precioDe(id) -> precio por unidad o nil. liqDe(id) -> tabla de T.Liquidez o nil. delanteDe(id, precio) ->
-- unidades publicadas a ese precio o menos (de la foto) o nil.
function T.Fabricar(receta, precioDe, a, vendedorDe, liqDe, delanteDeId)
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
	local vd = liq and liq.ventasDiaBaja
	if liq and not liq.midiendo and (liq.ventasDia or 0) <= 0 then
		return { producto = receta.producto, costo = costo, noSeVende = true, horas = liq.horas, n = n }
	end
	local delante = (delanteDeId and delanteDeId(receta.producto, pv)) or 0
	local p = vd and T.ProbVenta(vd, delante, n, a.horasPublicacion or 24) or nil
	local dep = T.Deposito(receta.producto, vendedorDe and vendedorDe(receta.producto) or 0, n, a)
	-- sin ventas medidas se supone 1 de cada 2 publicaciones vendida (pérdida = 1 depósito) y se avisa
	local perdida = T.PerdidaDeposito(dep, (p and p > 0) and p or 0.5)
	local venta = pv * n * (1 - a.comision) - perdida
	return { producto = receta.producto, costo = costo, venta = venta, ganancia = venta - costo,
		pct = costo > 0 and (venta - costo) / costo or nil, sinLiquidez = vd == nil, n = n, prob = p }
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
