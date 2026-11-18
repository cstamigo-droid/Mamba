-- Tasador: el comerciante en el juego. Junta los cálculos de Comercio.lua con tus precios, tus bolsas y tus
-- recetas, y los muestra en el chat y en la ventana "Oportunidades" (estilo Polestar, vía Asistente/Estilo.lua).
-- SOLO ACONSEJA: cada compra y cada publicación las haces tú en la ventana de subasta del juego, con tu clic.
-- Este archivo no llama a ninguna función de comprar, pujar, publicar ni cancelar (prueba C12).
-- Licencia: GPL-3.0.
local _, T = ...

local NOVERIF = "NO VERIFICADO en Forever: comisión 5 %, depósito, duraciones, tiempo restante de las subastas, si la subasta es la moderna o la antigua y si se comparte con la Alianza (ajusta con /tasador comision, deposito y duracion)."

---------------------------------------------------------------- colores (regla de estética E3: sin |cff fijo)
local function A() local a = _G.Asistente; return type(a) == "table" and a or nil end
-- En el chat (fondo oscuro siempre). Sin Asistente: sin color.
function T.Col(nombre, texto)
	local a = A()
	if a and a.ColorOscuro then return a.ColorOscuro(nombre, texto) end
	return tostring(texto)
end
local function colV(nombre, texto) -- dentro de la ventana
	local a = A()
	if a and a.Color then return a.Color(nombre, texto) end
	return tostring(texto)
end

---------------------------------------------------------------- datos del juego
local pedidos = {}
local function info(id)
	local f = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
	if not f then return nil end
	local ok, nombre, link, _, _, _, _, _, pila, _, _, vendedor = pcall(f, id)
	if not ok or not T.Leer(nombre) then
		-- se pide una sola vez por objeto y sesión (no miles de pedidos al servidor en cada análisis)
		if not pedidos[id] and C_Item and C_Item.RequestLoadItemDataByID then
			pedidos[id] = true
			pcall(C_Item.RequestLoadItemDataByID, id)
		end
		return nil
	end
	return { link = T.Leer(link) or T.Leer(nombre), pila = T.Leer(pila) or 1, vendedor = T.Leer(vendedor) or 0 }
end
T.InfoComercio = info

local function jugador() return UnitName and T.Leer(UnitName("player")) or nil end

function T.EdadFoto()
	if not (T.db and T.db.foto and T.db.fotoHora and time) then return nil end
	return time() - T.db.fotoHora
end

-- Ajustes del comerciante, con el depósito real del juego si la subasta moderna sabe calcularlo.
local DURACION = { [12] = 1, [24] = 2, [48] = 3 }
function T.AjustesComercio()
	local a = T.Ajustes()
	local C = C_AuctionHouse
	if C and C.CalculateCommodityDeposit and DURACION[a.horasPublicacion] then
		a.depositoReal = function(id, k)
			local v = C.CalculateCommodityDeposit(id, DURACION[a.horasPublicacion], k)
			return T.Leer(v)
		end
	end
	return a
end

-- Precio de hoy o ayer por unidad (percentil 20; si no, el mínimo), o lo que cobra el vendedor si es menor.
function T.PrecioMercado(id, hoyDia)
	local e = T.db and T.db.precios and T.db.precios[tostring(id)]
	local p
	if type(e) == "table" and hoyDia then
		for _, d in ipairs({ hoyDia, hoyDia - 1 }) do
			local k = tostring(d)
			p = (e.p and e.p[k]) or (e.l and e.l[k])
			if p then break end
		end
	end
	local pnj = T.db and T.db.precioPNJ and T.db.precioPNJ[tostring(id)]
	if pnj and (not p or pnj < p) then return pnj, "vendedor" end
	return p, p and "subasta" or nil
end

---------------------------------------------------------------- análisis de toda la foto, en tandas
local POR_TANDA = 300
local ocupado = false
T.oportunidades = nil

-- alTerminar(lista, sinCargar) o alTerminar(nil, motivo). lista = reventas y reventas al vendedor.
function T.Analizar(alTerminar)
	local edad = T.EdadFoto()
	if not edad then alTerminar(nil, "No tengo escaneo: abre la casa de subastas y aprieta \"Escanear (Tasador)\".") return end
	if ocupado then alTerminar(nil, "Ya estoy calculando: espera unos segundos.") return end
	ocupado = true
	local a, hoy, yo = T.AjustesComercio(), T.DiaHoy(), jugador()
	local ids = {}
	for id in pairs(T.db.foto) do ids[#ids + 1] = id end
	local lista, sinCargar, pos = {}, 0, 1
	local function tanda()
		local ok, err = pcall(function()
			local fin = math.min(#ids, pos + POR_TANDA - 1)
			for i = pos, fin do
				local id = ids[i]
				local fotoItem = T.FotoTabla(T.db.foto[id]) -- se lee el texto una sola vez por objeto
				local x = info(id)
				if not x then
					sinCargar = sinCargar + 1
				else
					local v = T.ReventaVendedor(fotoItem, x.vendedor, edad, a, id, yo)
					if v then v.link = x.link; lista[#lista + 1] = v end
					-- reventa solo de lo que se apila: el equipo con sufijo mezcla precios de versiones distintas
					if x.pila > 1 then
						local r = T.Reventa(T.db.precios[tostring(id)], fotoItem, x.vendedor, hoy, edad, a, id, yo)
						if r then r.link = x.link; lista[#lista + 1] = r end
					end
				end
			end
			pos = fin + 1
		end)
		if not ok then ocupado = false; alTerminar(nil, "Error calculando: " .. tostring(err)) return end
		if pos <= #ids then C_Timer.After(0, tanda) return end
		ocupado = false
		table.sort(lista, function(p, q) return p.ganancia > q.ganancia end)
		T.oportunidades = lista
		alTerminar(lista, sinCargar)
	end
	tanda()
end

-- Tus bolsas: consejo de venta por objeto (lo que se puede subastar).
function T.ConsejosBolsas()
	local a, hoy, edad, yo = T.AjustesComercio(), T.DiaHoy(), T.EdadFoto(), jugador()
	local lista, sinCargar = T.LeerBolsas()
	local por, out = {}, {}
	for _, x in ipairs(lista) do
		local id = T.ItemID(x.info.link)
		local r = T.Evaluar(x.info, a)
		if id and (r.accion == T.ACCION.SUBASTA or r.accion == T.ACCION.REVISAR or T.EsMaterial(x.info))
			and x.info.liga ~= T.LIGA_RECOGER and not x.info.ligado and (x.info.calidad or 0) > 0 then
			por[id] = por[id] or { link = x.info.link, cantidad = 0, vendedor = x.info.vendedor or 0 }
			por[id].cantidad = por[id].cantidad + x.cantidad
		end
	end
	for id, b in pairs(por) do
		local fotoItem = T.db.foto and T.db.foto[id]
		local c, motivo = T.ConsejoVenta(T.db.precios and T.db.precios[tostring(id)], fotoItem, b.vendedor, hoy, edad, a, yo, b.cantidad, id)
		out[#out + 1] = { id = id, link = b.link, cantidad = b.cantidad, c = c, motivo = motivo,
			valor = c and c.precio * b.cantidad or 0 }
	end
	table.sort(out, function(p, q) return p.valor > q.valor end)
	return out, sinCargar
end

-- Tus recetas con los precios de hoy.
function T.ConsejosFabricar()
	local a, hoy = T.AjustesComercio(), T.DiaHoy()
	local mias = T.db.recetas and T.db.recetas[T.Personaje()]
	if not mias or not next(mias) then return nil end
	local out = {}
	local function precioDe(id) return (T.PrecioMercado(id, hoy)) end
	local function vendedorDe(id) local x = info(id); return x and x.vendedor or 0 end
	local function liqDe(id) return T.Liquidez(T.db.precios and T.db.precios[tostring(id)], hoy) end
	local yo = jugador()
	local function delanteDe(id, precio)
		local f = T.db.foto and T.db.foto[id]
		return f and T.Delante(T.Escalera(f, yo), precio) or nil
	end
	for producto, r in pairs(mias) do
		local f = T.Fabricar({ producto = producto, n = r.n, mats = r.mats }, precioDe, a, vendedorDe, liqDe, delanteDe)
		f.prof = r.prof
		out[#out + 1] = f
	end
	table.sort(out, function(p, q)
		if (p.ganancia ~= nil) ~= (q.ganancia ~= nil) then return p.ganancia ~= nil end
		return (p.ganancia or 0) > (q.ganancia or 0)
	end)
	return out
end

local function nombre(id)
	local x = info(id)
	return x and x.link or ("objeto " .. tostring(id))
end

---------------------------------------------------------------- textos (los usan el chat y la ventana)
local function pct(x) return math.floor(x * 100 + 0.5) .. " %" end

function T.TextoOportunidad(o)
	if o.tipo == "vendedor" then
		return string.format("%s  compra %d a %s o menos y véndelas al PNJ por %s c/u", o.link, o.unidades,
			T.Dinero(o.comprarHasta), T.Dinero(o.venta)), "+" .. T.Dinero(o.ganancia)
	end
	return string.format("%s  compra %d hasta %s, revende a %s · %d+ al día · %d días, %d h vistas", o.link, o.unidades,
		T.Dinero(o.comprarHasta), T.Dinero(o.venta), math.floor(o.ventasDia), o.diasHistoria or 0, math.floor(o.horas or 0)),
		"+" .. T.Dinero(o.ganancia) .. " (" .. pct(o.pct) .. ")"
end

function T.DetalleOportunidad(o)
	local l = {}
	if o.tipo == "vendedor" then
		l[#l + 1] = "Subastas más baratas que lo que paga el vendedor (PNJ)."
		l[#l + 1] = "Costo " .. T.Dinero(o.costo) .. " · el PNJ paga " .. T.Dinero(o.venta * o.unidades) .. " · sin comisión ni depósito."
		l[#l + 1] = "Ojo: otro jugador puede comprarlas antes. Revisa el precio al comprar."
	else
		l[#l + 1] = "Precio normal (mediana de los días anteriores): " .. T.Dinero(o.normal) .. "."
		l[#l + 1] = "Costo " .. T.Dinero(o.costo) .. " · cobras " .. T.Dinero(o.venta * o.unidades) .. " menos la comisión."
		l[#l + 1] = "Depósito " .. T.Dinero(o.deposito) .. "; pérdida esperada si no se vende: " .. T.Dinero(o.perdidaDeposito) .. "."
		l[#l + 1] = "Riesgo de que baje mientras esperas (supuesto 8 % por día): " .. T.Dinero(o.riesgo) .. "."
		l[#l + 1] = (o.diasVender < 1 and "Se venderían en menos de un día" or "Se venderían en 1 a 2 días") .. " (MODELO, sin verificar)."
		l[#l + 1] = "Ventas por día: subastas que desaparecieron antes de vencer en tus escaneos. Puede incluir cancelaciones y tus propias compras; se usa el límite bajo."
		l[#l + 1] = "Solo se mide en las horas en que escaneas: escanea a horas distintas para que no sea solo tu horario."
	end
	l[#l + 1] = NOVERIF
	return l
end

function T.TextoConsejo(x)
	if not x.c then return x.link .. "  " .. (x.motivo == "escanea" and "escanea la subasta" or tostring(x.motivo)), "" end
	local c = x.c
	local acc = ({ ["vende ya"] = "VENDE YA", vende = "Vende", espera = "Espera", vendedor = "Al vendedor",
		["no publiques"] = "No lo publiques" })[c.accion]
	local cuantas = c.cuantas and (" · publica hasta " .. c.cuantas .. " por día") or ""
	local precio = c.accion == "no publiques" and "" or (" a " .. T.Dinero(c.precio))
	local neto = (c.accion == "vende" or c.accion == "vende ya") and c.neto and c.neto > 0
		and (" (te quedan ~" .. T.Dinero(c.neto) .. " c/u)") or ""
	return x.link .. (x.cantidad > 1 and (" x" .. x.cantidad) or "") .. "  " .. acc .. precio .. neto .. cuantas, c.motivo or ""
end

function T.TextoFabricar(f)
	if f.noSeVende then
		return nombre(f.producto) .. "  casi no se vende (menos de 1 al día en " .. math.floor(f.horas or 0) .. " h de escaneos): no lo fabriques para vender", ""
	end
	if f.falta then
		local n = {}
		for _, id in ipairs(f.falta) do n[#n + 1] = nombre(id) end
		return nombre(f.producto) .. "  falta precio de " .. table.concat(n, ", ") .. ": escanea", ""
	end
	local signo = f.ganancia >= 0 and "+" or "-"
	local txt = nombre(f.producto) .. (f.n > 1 and (" x" .. f.n) or "") .. "  materiales " .. T.Dinero(f.costo) .. " · vendes " .. T.Dinero(f.venta)
	return txt, signo .. T.Dinero(math.abs(f.ganancia)) .. (f.pct and (" (" .. pct(f.pct) .. ")") or "")
end

---------------------------------------------------------------- chat
local function avisoViejo()
	local edad = T.EdadFoto()
	if not edad then T.Decir("No tengo escaneo: abre la casa de subastas y aprieta \"Escanear (Tasador)\".") return true end
	T.Decir(T.Col("gris", "Escaneo de hace " .. T.Horas(edad) .. ". Para comprar hace falta uno de 60 min o menos."))
end

function T.MostrarReventa(tipo)
	if avisoViejo() then return end
	T.Analizar(function(lista, err)
		if not lista then T.Decir(err) return end
		local titulo = tipo == "vendedor" and "Comprar en la subasta y vender al PNJ" or "Comprar para revender"
		T.Decir(T.Col("titulo", titulo) .. " (ordenado por ganancia neta):")
		local n = 0
		for _, o in ipairs(lista) do
			if o.tipo == tipo and n < 10 then
				local a, b = T.TextoOportunidad(o)
				T.Decir("  " .. a .. "  " .. T.Col("bueno", b))
				n = n + 1
			end
		end
		if n == 0 then
			T.Decir("  Nada que cumpla todas las condiciones ahora. Es normal: el detector pide margen, liquidez medida y precio que no venga bajando.")
		end
		if type(err) == "number" and err > 0 then T.Decir("  (" .. err .. " objetos aún cargando: repite el comando en unos segundos)") end
		T.Decir("  " .. T.Col("gris", "Solo consejos: compras tú, con tu clic. " .. NOVERIF))
	end)
end

function T.MostrarVender()
	local lista = T.ConsejosBolsas()
	T.Decir(T.Col("titulo", "Qué vender de tus bolsas, a cuánto y cuándo") .. ":")
	if #lista == 0 then T.Decir("  No tienes nada para subastar en las bolsas.") end
	for i = 1, math.min(12, #lista) do
		local a, b = T.TextoConsejo(lista[i])
		T.Decir("  " .. a .. (b ~= "" and ("  " .. T.Col("gris", b)) or ""))
	end
	T.Decir("  " .. T.Col("gris", "\"Vende ya\" = el precio bajó 3 días seguidos. Publicas tú, con tu clic. " .. NOVERIF))
end

function T.MostrarFabricar()
	local lista = T.ConsejosFabricar()
	if not lista then
		T.Decir("No conozco tus recetas: abre la ventana de tu profesión (Alquimia, Cocina, Primeros auxilios) una vez y repite /tasador fabricar.")
		return
	end
	T.Decir(T.Col("titulo", "Fabricar o no, con los precios de hoy") .. " (materiales al precio de hoy; si alguno lo vende un PNJ, a su precio):")
	for i = 1, math.min(12, #lista) do
		local a, b = T.TextoFabricar(lista[i])
		local col = lista[i].ganancia and (lista[i].ganancia > 0 and "bueno" or "dudoso") or "gris"
		T.Decir("  " .. a .. "  " .. T.Col(col, b) .. (lista[i].sinLiquidez and T.Col("gris", " (ventas sin medir)") or ""))
	end
	T.Decir("  " .. T.Col("gris", "Ganancia = lo que cobras tras la comisión y el depósito que puedes perder, menos el valor de los materiales en la subasta. Si es negativa, vende los materiales."))
end

-- Día del evento con el mismo calendario que T.DiaHoy.
function T.DiaDe(fecha)
	local cero = Auctionator and Auctionator.Constants and Auctionator.Constants.SCAN_DAY_0
	if type(cero) ~= "number" then cero = time({ year = 2020, month = 1, day = 1, hour = 0 }) end
	local t = {}
	for k, v in pairs(fecha) do t[k] = v end
	t.hour = t.hour or 12
	return math.floor((time(t) - cero) / 86400)
end

function T.MostrarEventos()
	local hoy = T.DiaHoy()
	for _, ev in ipairs(T.EVENTOS) do
		local dia = T.DiaDe(ev.fecha)
		local m = T.MedirEvento(T.db.precios, dia)
		T.Decir(T.Col("titulo", ev.nombre) .. " · " .. ev.fecha.day .. "-" .. ev.fecha.month .. "-" .. ev.fecha.year .. " (" .. ev.fuente .. ")")
		T.Decir("  Hipótesis SIN VERIFICAR: que suban hierbas y consumibles. El addon lo mide; no lo supone.")
		if hoy and hoy < dia then
			T.Decir(string.format("  Faltan %d días. Objetos con 2 días de precio en la semana de antes: hierbas %d, consumibles %d, control %d (hacen falta 5 de cada uno).",
				dia - hoy, m.antes.hierba, m.antes.consumible, m.antes.control))
		else
			for _, k in ipairs({ "hierba", "consumible", "control" }) do
				local g = m.grupos[k]
				if g.cambio then
					T.Decir(string.format("  %s: %+d %% (mediana de %d objetos, semana después contra semana antes)", T.GRUPOS_EVENTO[k], math.floor(g.cambio * 100 + 0.5), g.n))
				else
					T.Decir(string.format("  %s: todavía no se puede medir (%d objetos con datos en las dos semanas; hacen falta 5)", T.GRUPOS_EVENTO[k], g.n))
				end
			end
			for _, k in ipairs({ "hierba", "consumible" }) do
				if m.efecto[k] then
					T.Decir(string.format("  %s contra el control: %+d puntos. MEDIDO en tu servidor, con una sola semana: es una pista, no una regla.",
						T.GRUPOS_EVENTO[k], math.floor(m.efecto[k] * 100 + 0.5)))
				end
			end
		end
	end
end

---------------------------------------------------------------- ventana "Oportunidades" (estilo Polestar)
local FILAS, ALTO_FILA, ANCHO, ALTO = 12, 22, 640, 440
local PESTANAS = { { "todo", "Todo" }, { "reventa", "Reventa" }, { "vendedor", "Al PNJ" }, { "vender", "Vender lo tuyo" }, { "fabricar", "Fabricar" } }
local v, filas, desplaza, pestana = nil, {}, 0, "todo"

-- ¿El Asistente trae las piezas de Polestar? (Estilo.lua con A.Texto y A.Fila; si no, solo chat.)
function T.HayVentana()
	local a = A()
	return a and a.CrearVentana and a.Texto and a.Fila and true or false
end

local function filasDe(cual)
	local out = {}
	if cual == "todo" or cual == "reventa" or cual == "vendedor" then
		for _, o in ipairs(T.oportunidades or {}) do
			if cual == "todo" or o.tipo == cual then
				local a, b = T.TextoOportunidad(o)
				out[#out + 1] = { izq = a, der = colV("bueno", b), ayuda = T.DetalleOportunidad(o), titulo = o.link, valor = o.ganancia }
			end
		end
	end
	if cual == "todo" or cual == "vender" then
		for _, x in ipairs((T.ConsejosBolsas())) do
			if x.c and (cual == "vender" or x.c.accion == "vende ya") then
				local a, b = T.TextoConsejo(x)
				out[#out + 1] = { izq = a, der = colV(x.c.accion == "vende ya" and "dudoso" or "gris", x.c.accion == "vende ya" and "vende ya" or ""),
					ayuda = { b, NOVERIF }, titulo = x.link, valor = cual == "vender" and x.valor or 0 }
			elseif cual == "vender" then
				local a = T.TextoConsejo(x)
				out[#out + 1] = { izq = colV("gris", a), der = "", ayuda = { "Sin escaneo reciente: escanea la subasta." }, titulo = x.link, valor = -1 }
			end
		end
	end
	if cual == "todo" or cual == "fabricar" then
		for _, f in ipairs(T.ConsejosFabricar() or {}) do
			if cual == "fabricar" or (f.ganancia and f.ganancia > 0 and not f.sinLiquidez) then
				local a, b = T.TextoFabricar(f)
				local col = f.ganancia and (f.ganancia > 0 and "bueno" or "dudoso") or "gris"
				out[#out + 1] = { izq = a, der = colV(col, b), titulo = nombre(f.producto), valor = f.ganancia or -1,
					ayuda = { "Fabricar con los materiales al precio de hoy (" .. (f.prof or "profesión") .. ").",
						f.sinLiquidez and "Ventas del producto sin medir: supongo que 1 de cada 2 publicaciones se vende." or "Depósito según las ventas medidas.", NOVERIF } }
			end
		end
	end
	if cual == "todo" then table.sort(out, function(p, q) return (p.valor or 0) > (q.valor or 0) end) end
	return out
end

local vistas = {}
-- recalcular = false: solo repinta (rueda del ratón); las filas se calculan al abrir, al cambiar de pestaña
-- y al terminar un análisis.
function T.RefrescarVentana(recalcular)
	if not v then return end
	if recalcular ~= false then vistas = filasDe(pestana) end
	desplaza = math.max(0, math.min(desplaza, #vistas - FILAS))
	for i = 1, FILAS do
		local fila, d = filas[i], vistas[i + desplaza]
		if d then
			fila.d = d
			fila.izq:SetText(d.izq)
			fila.der:SetText(d.der)
			fila:Show()
		else
			fila.d = nil
			fila:Hide()
		end
	end
	for _, b in ipairs(v.pestanas) do b.texto:SetText(colV(b.clave == pestana and "titulo" or "gris", b.nombre)) end
	local edad = T.EdadFoto()
	local pie
	if not edad then pie = "Sin escaneo: abre la subasta y aprieta \"Escanear (Tasador)\"."
	elseif #vistas == 0 then pie = "Nada aquí ahora (escaneo de hace " .. T.Horas(edad) .. "). Es normal: los filtros piden margen y ventas medidas."
	else pie = #vistas .. " filas · escaneo de hace " .. T.Horas(edad) .. " · solo consejos: compras y publicas tú, con tu clic." end
	v.pie:SetText(colV("gris", pie))
	return vistas
end

local function crearVentana()
	local a = A()
	v = a.CrearVentana("TasadorOportunidades", "Oportunidades de la subasta", ANCHO, ALTO)
	local m, arriba = v.margen or 16, -(v.cuerpo or 26) - 6
	v.pestanas = {}
	local x = m
	for _, p in ipairs(PESTANAS) do
		local ancho = 24 + #p[2] * 7
		local b = a.Fila(v, ancho, 20)
		b:SetPoint("TOPLEFT", v, "TOPLEFT", x, arriba)
		b.texto = a.Texto(b, "label", "text")
		b.texto:SetPoint("CENTER", b, "CENTER", 0, 0)
		b.clave, b.nombre = p[1], p[2]
		b:SetScript("OnClick", function() pestana, desplaza = p[1], 0; T.RefrescarVentana() end)
		v.pestanas[#v.pestanas + 1] = b
		x = x + ancho + 6
	end
	for i = 1, FILAS do
		local f = a.Fila(v, ANCHO - 2 * m, ALTO_FILA)
		f:SetPoint("TOPLEFT", v, "TOPLEFT", m, arriba - 28 - (i - 1) * ALTO_FILA)
		f.izq = a.Texto(f, "body", "text")
		f.izq:SetPoint("LEFT", f, "LEFT", 4, 0)
		f.izq:SetPoint("RIGHT", f, "RIGHT", -150, 0)
		f.der = a.Texto(f, "number", "text")
		f.der:SetPoint("RIGHT", f, "RIGHT", -4, 0)
		f:SetScript("OnEnter", function(self)
			if self.d and a.CuadroAyuda then a.CuadroAyuda(self, self.d.titulo, self.d.ayuda) end
		end)
		f:SetScript("OnLeave", function() if a.OcultarAyuda then a.OcultarAyuda() end end)
		filas[i] = f
	end
	v.pie = a.Texto(v, "note", "textMuted")
	v.pie:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", m, 14)
	v.pie:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -m, 14)
	if v.EnableMouseWheel then v:EnableMouseWheel(true) end
	v:SetScript("OnMouseWheel", function(_, delta)
		desplaza = math.max(0, desplaza - delta)
		T.RefrescarVentana(false)
	end)
	if a.AlCambiarApariencia then a.AlCambiarApariencia(function() if v and v:IsShown() then T.RefrescarVentana(false) end end) end
end

function T.AbrirOportunidades()
	if not T.HayVentana() then
		T.Decir("La ventana necesita el addon Asistente de Mamba con la estética de Polestar. Te lo muestro en el chat:")
		T.MostrarReventa("reventa")
		return
	end
	if not v then crearVentana() end
	v:Show()
	T.RefrescarVentana()
	if T.EdadFoto() then
		T.Analizar(function(lista, err)
			if not lista then T.Decir(err) end
			T.RefrescarVentana()
		end)
	end
end
T._Ventana = function() return v end

-- Después de cada escaneo: si hay oportunidades, avisarlo en una línea.
function T.AlTerminarEscaneo()
	T.Analizar(function(lista)
		if not lista then return end
		local r, p = 0, 0
		for _, o in ipairs(lista) do if o.tipo == "reventa" then r = r + 1 else p = p + 1 end end
		if r + p > 0 then
			T.Decir(string.format("%d para revender y %d para vender al PNJ. Míralas con /tasador op.", r, p))
		end
		if v and v:IsShown() then T.RefrescarVentana() end
	end)
end
