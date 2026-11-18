-- Tasador: escaneo PROPIO de la casa de subastas (Auctionator tiene licencia cerrada y no se puede incluir).
-- Solo LEE precios cuando TÚ apretas el botón "Escanear (Tasador)". No compra, no vende, no publica.
-- Guarda, por objeto y por día, el precio más bajo por unidad y cuántos había a la venta, con la
-- MISMA forma que Auctionator ({h, l, a} por día), así T.Historial y /tasador baratos sirven igual.
-- Licencia: GPL-3.0.
local _, T = ...
T = T or Tasador or {}
Tasador = T

T.DIAS_GUARDADOS = 14
local POR_TANDA = 500 -- subastas leídas por cuadro de imagen: no congela el juego

---------------------------------------------------------------- parte pura (se prueba fuera del juego)
-- Junta una subasta en el escaneo en curso. buffer[id] = { min = precio por unidad, cant = cantidad,
-- n = subastas distintas, lista = { {precio, unidades}, ... }, foto = { [vendedor] = { [precio] = { [tramo] = u } } } }
-- vendedor y tramo (1-4 del tiempo restante; 0 = no se sabe) son opcionales: sirven para estimar ventas (Comercio.lua).
function T.SumarSubasta(buffer, id, cantidad, compraYa, vendedor, tramo)
	if type(id) ~= "number" or type(cantidad) ~= "number" or cantidad < 1 then return end
	if type(compraYa) ~= "number" or compraYa <= 0 then return end -- solo puja, sin "comprar ya": no da precio
	local unidad = compraYa / cantidad
	local b = buffer[id]
	if not b then
		b = { min = unidad, cant = 0, n = 0, lista = {}, foto = {} }
		buffer[id] = b
	end
	if unidad < b.min then b.min = unidad end
	b.cant = b.cant + cantidad
	b.n = (b.n or 0) + 1
	local precio = math.floor(unidad + 0.5)
	if b.lista then b.lista[#b.lista + 1] = { precio, cantidad } end
	if b.foto then
		local quien = type(vendedor) == "string" and vendedor ~= "" and vendedor or "?"
		local tr = (type(tramo) == "number" and tramo >= 1 and tramo <= 4) and tramo or 0
		local v = b.foto[quien] or {}
		b.foto[quien] = v
		local t = v[precio] or {}
		v[precio] = t
		t[tr] = (t[tr] or 0) + cantidad
	end
end

-- Percentil por UNIDADES: el precio al que se compra la fracción q más barata. lista = { {precio, u}, ... }
function T.Percentil(lista, q)
	if type(lista) ~= "table" or #lista == 0 then return nil end
	table.sort(lista, function(a, b) return a[1] < b[1] end)
	local total = 0
	for _, x in ipairs(lista) do total = total + x[2] end
	local meta, acum = total * q, 0
	for _, x in ipairs(lista) do
		acum = acum + x[2]
		if acum >= meta then return x[1] end
	end
	return lista[#lista][1]
end

-- La foto del escaneo: foto[id][vendedor][precio] = { [tramo] = unidades } (para CompararFotos).
function T.FotoDe(buffer)
	local foto = {}
	for id, b in pairs(buffer) do if b.foto then foto[id] = b.foto end end
	return foto
end

-- Pasa el escaneo terminado a la tabla guardada. precios[tostring(id)] = { h = {}, l = {}, a = {} }
-- (claves de día como texto, igual que Auctionator), más p = percentil 20 por unidad y n = subastas distintas.
-- categoria(id) -> "hierba" | "consumible" | "control" | nil: esos guardan su precio 60 días (eventos).
-- Borra lo de más de 14 días atrás. Devuelve cuántos objetos distintos se guardaron.
T.DIAS_EVENTO = 60
function T.GuardarEscaneo(precios, buffer, dia, categoria)
	local n = 0
	local diaTxt = tostring(dia)
	for id, b in pairs(buffer) do
		local clave = tostring(id)
		local e = precios[clave]
		if type(e) ~= "table" then e = { h = {}, l = {}, a = {} }; precios[clave] = e end
		e.h, e.l, e.a = e.h or {}, e.l or {}, e.a or {}
		local p = math.floor(b.min + 0.5)
		-- dos escaneos el mismo día: queda el más bajo; la cantidad es la del último escaneo
		if e.l[diaTxt] == nil or p < e.l[diaTxt] then e.l[diaTxt] = p end
		if e.h[diaTxt] == nil or p > e.h[diaTxt] then e.h[diaTxt] = p end
		e.a[diaTxt] = b.cant
		-- percentil 20 y subastas distintas: los del último escaneo del día (como un "cierre")
		local p20 = T.Percentil(b.lista, 0.2)
		if p20 then e.p = e.p or {}; e.p[diaTxt] = p20 end
		if b.n then e.n = e.n or {}; e.n[diaTxt] = b.n end
		if categoria and not e.k then
			local ok, k = pcall(categoria, id)
			if ok and k then e.k = k end
		end
		n = n + 1
	end
	for _, e in pairs(precios) do
		for _, campo in ipairs({ "h", "l", "a", "p", "n", "v", "vc", "o" }) do
			local guarda = (e.k and campo == "p") and T.DIAS_EVENTO or T.DIAS_GUARDADOS
			for d in pairs(e[campo] or {}) do
				if tonumber(d) and tonumber(d) < dia - guarda then e[campo][d] = nil end
			end
		end
	end
	return n
end

-- Precio propio de un objeto: precio por unidad del último día escaneado y hace cuántos días fue.
function T.PrecioPropio(itemID, hoyDia)
	local db = T.db and T.db.precios
	local e = db and db[tostring(itemID)]
	if type(e) ~= "table" or type(e.l) ~= "table" then return nil end
	local ultimo
	for d in pairs(e.l) do
		local n = tonumber(d)
		if n and (not ultimo or n > ultimo) then ultimo = n end
	end
	if not ultimo then return nil end
	return e.l[tostring(ultimo)], hoyDia and (hoyDia - ultimo) or nil
end

-- La base de precios que usa /tasador baratos y /tasador hierbas. REGLA ÚNICA (ARQUITECTURA §7): la más
-- reciente. Auctionator no dice de qué día es su último escaneo sin recorrer toda su tabla, así que:
-- el escaneo propio gana si es de hoy o de ayer; si no, Auctionator (si tiene algo); si no, el propio.
function T.BasePrecios(hoyDia)
	local adb = Auctionator and Auctionator.Database and Auctionator.Database.db
	if type(adb) ~= "table" or next(adb) == nil then adb = nil end -- instalado pero sin escanear = no hay
	local propio = T.db and type(T.db.precios) == "table" and next(T.db.precios) and T.db.precios or nil
	local ultimo = T.db and T.db.ultimoEscaneo
	hoyDia = hoyDia or (T.DiaHoy and T.DiaHoy())
	if propio and ultimo and hoyDia and ultimo >= hoyDia - 1 then return propio, "propio" end
	if adb then return adb, "Auctionator" end
	if propio then return propio, "propio" end
	return nil
end

---------------------------------------------------------------- parte del juego
-- Las dos subastas posibles: la moderna (C_AuctionHouse.ReplicateItems) y la antigua (QueryAuctionItems
-- con getAll). NO VERIFICADO cuál trae Forever: se usa la que exista. Las dos devuelven los mismos
-- campos en el mismo orden: 3 = cantidad, 10 = "comprar ya" total, 17 = id del objeto.
local estado = { activo = false }
T.escaneo = estado

local function moderna()
	return C_AuctionHouse and C_AuctionHouse.ReplicateItems and C_AuctionHouse.GetNumReplicateItems
		and C_AuctionHouse.GetReplicateItemInfo and true or false
end
local function antigua()
	return QueryAuctionItems and GetNumAuctionItems and GetAuctionItemInfo and true or false
end

local function leer(i)
	if estado.tipo == "moderna" then return C_AuctionHouse.GetReplicateItemInfo(i - 1) end -- empieza en 0
	return GetAuctionItemInfo("list", i)
end

-- Tramo de tiempo restante, normalizado a 1 corto .. 4 muy largo (0 = no se sabe).
-- Moderna: Enum.AuctionHouseTimeLeft empieza en 0. Antigua: GetAuctionItemTimeLeft da 1-4.
local function tramo(i)
	local ok, t
	if estado.tipo == "moderna" then
		if not C_AuctionHouse.GetReplicateItemTimeLeft then return 0 end
		ok, t = pcall(C_AuctionHouse.GetReplicateItemTimeLeft, i - 1)
		t = ok and T.Leer(t)
		return type(t) == "number" and t + 1 or 0
	end
	if not GetAuctionItemTimeLeft then return 0 end
	ok, t = pcall(GetAuctionItemTimeLeft, "list", i)
	t = ok and T.Leer(t)
	return type(t) == "number" and t or 0
end

local function categoria(id)
	local _, _, clase, sub = T.InfoRapida(id)
	return T.CategoriaEvento(clase, sub)
end

local function terminar(buffer)
	estado.activo, estado.leyendo = false, false
	T.db = T.db or TasadorDB or {}
	T.db.precios = T.db.precios or {}
	local dia = T.DiaHoy() or 0
	local n = T.GuardarEscaneo(T.db.precios, buffer, dia, categoria)
	if n == 0 then
		T.Decir("La subasta mandó una lista vacía: no se guardó nada. Prueba de nuevo en 15 minutos.")
		return
	end
	-- Ventas entre la foto anterior y esta (Comercio.lua). La foto anterior se reemplaza siempre.
	local ahora = time and time() or 0
	local segundos = T.db.fotoHora and (ahora - T.db.fotoHora) or nil
	local nueva = T.FotoDe(buffer)
	local ventas = T.CompararFotos(T.db.foto, nueva, segundos)
	if ventas then T.AnotarVentas(T.db.precios, ventas, dia, segundos) end
	T.db.foto, T.db.fotoHora = nueva, ahora
	T.db.ultimoEscaneo = dia
	T.db.diasEscaneados = T.db.diasEscaneados or {}
	T.db.diasEscaneados[tostring(dia)] = true
	local dias = 0
	for d in pairs(T.db.diasEscaneados) do if tonumber(d) and tonumber(d) >= dia - T.DIAS_GUARDADOS then dias = dias + 1 end end
	if dias >= 3 then
		T.Decir(string.format("Escaneo listo: %d objetos con precio. Ya puedes usar /tasador baratos y /tasador hierbas.", n))
	else
		T.Decir(string.format("Escaneo listo: %d objetos con precio (el cuadro de cada objeto ya los muestra). Para /tasador baratos y hierbas hacen falta 3 días distintos de escaneo: llevas %d.", n, dias))
	end
	if ventas then
		T.Decir("Comparé con tu escaneo de hace " .. T.Horas(segundos) .. ": ventas anotadas. /tasador op muestra las oportunidades.")
	elseif segundos and segundos > T.VENTANA_MAX then
		T.Decir("Tu escaneo anterior es de hace más de 48 horas: no puedo saber qué se vendió. Escanea cada pocas horas.")
	else
		T.Decir("Foto guardada. Vuelve a escanear en 1 a 4 horas: así sé qué se vendió.")
	end
	if T.AlTerminarEscaneo then pcall(T.AlTerminarEscaneo) end
end

-- Lee la lista que mandó el servidor en tandas (C_Timer), sin congelar el juego.
local function procesar(total)
	local buffer, i = {}, 1
	estado.leyendo = true
	local function tanda()
		if not estado.activo then estado.leyendo = false return end -- cerraste la subasta a medias
		local fin = math.min(total, i + POR_TANDA - 1)
		local bien = pcall(function()
			for k = i, fin do
				-- 14 = vendedor, 17 = id (mismos campos en la moderna y la antigua)
				local ok, _, _, cantidad, _, _, _, _, _, _, compraYa, _, _, _, vendedor, _, _, id = pcall(leer, k)
				-- T.Leer: un valor secreto de Forever no se compara (daría error); se salta
				if ok then
					T.SumarSubasta(buffer, T.Leer(id), T.Leer(cantidad), T.Leer(compraYa), T.Leer(vendedor), tramo(k))
				end
			end
		end)
		if not bien then
			estado.activo, estado.leyendo = false, false
			T.Decir("Error leyendo la lista de la subasta: no se guardó nada.")
			return
		end
		i = fin + 1
		if i <= total then
			C_Timer.After(0, tanda)
		else
			terminar(buffer)
		end
	end
	tanda()
end

-- Lo llama el botón (clic del jugador). Devuelve true si pidió la lista.
function T.Escanear()
	if estado.activo then T.Decir("Ya estoy escaneando: espera unos segundos.") return false end
	if moderna() then
		estado.tipo = "moderna"
	elseif antigua() then
		estado.tipo = "antigua"
		if CanSendAuctionQuery then
			local _, todo = CanSendAuctionQuery()
			if not todo then
				T.Decir("El juego permite un escaneo completo cada 15 minutos. Prueba más tarde.")
				return false
			end
		end
	else
		T.Decir("No encuentro la subasta del juego. Abre la casa de subastas primero.")
		return false
	end
	estado.activo = true
	estado.desde = GetTime and GetTime() or 0
	-- si el servidor no contesta en 60 s (espera de 15 min, o esta subasta no existe en Forever), se suelta
	local yo = estado.desde
	if C_Timer and C_Timer.After then
		C_Timer.After(60, function()
			if estado.activo and not estado.leyendo and estado.desde == yo then
				estado.activo = false
				T.Decir("La subasta no mandó la lista en 60 segundos. Prueba de nuevo en 15 minutos.")
			end
		end)
	end
	if estado.tipo == "moderna" then
		C_AuctionHouse.ReplicateItems()
	else
		QueryAuctionItems("", nil, nil, 0, nil, nil, true)
	end
	T.Decir("Escaneando la subasta... (solo leo precios, no compro ni vendo nada)")
	return true
end

local function alLlegarLista(evento)
	if not estado.activo or estado.leyendo then return end -- el evento puede llegar varias veces
	if evento == "REPLICATE_ITEM_LIST_UPDATE" and estado.tipo == "moderna" then
		procesar(C_AuctionHouse.GetNumReplicateItems())
	elseif evento == "AUCTION_ITEM_LIST_UPDATE" and estado.tipo == "antigua" then
		procesar(GetNumAuctionItems("list") or 0) -- con getAll llega todo en una sola lista
	end
end
T._AlLlegarLista = alLlegarLista

-- Botón en la ventana de subasta (la moderna o la antigua).
local boton
local function ponerBoton()
	if boton then boton:Show() return end
	local padre = AuctionHouseFrame or AuctionFrame
	if not padre then return end
	-- sin padre y después SetParent: la interfaz de mando intercepta CreateFrame con padre (ARQUITECTURA §4)
	boton = CreateFrame("Button", "TasadorBotonEscanear", nil, "UIPanelButtonTemplate")
	if boton.SetParent then boton:SetParent(padre) end
	boton:SetSize(150, 22)
	boton:SetPoint("TOPRIGHT", padre, "TOPRIGHT", -60, -2)
	boton:SetText("Escanear (Tasador)")
	boton:SetScript("OnClick", function() T.Escanear() end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("AUCTION_HOUSE_CLOSED")
f:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
f:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
f:SetScript("OnEvent", function(_, evento)
	if evento == "AUCTION_HOUSE_SHOW" then
		ponerBoton()
	elseif evento == "AUCTION_HOUSE_CLOSED" then
		if estado.activo then T.Decir("Cerraste la subasta antes de terminar: el escaneo quedó a medias, no se guardó.") end
		estado.activo = false
	else
		alLlegarLista(evento)
	end
end)
