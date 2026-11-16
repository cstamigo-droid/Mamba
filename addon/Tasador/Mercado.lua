-- Tasador: lectura del mercado con el historial que guarda Auctionator cuando escaneas la subasta.
-- Usa la tabla interna de Auctionator (Auctionator.Database.db). No es su API pública:
-- si Auctionator cambia, esta parte avisa y no rompe el resto.
-- Licencia: GPL-3.0.
local _, T = ...
T = T or Tasador or {}
Tasador = T

-- Parte pura (se prueba fuera del juego).
-- entrada = { h = { [dia] = precioMax }, l = { [dia] = precioMin }, a = { [dia] = cantidad } }
-- (días como texto, igual que Auctionator). hoyDia = número de día de HOY según Auctionator.
-- Devuelve { hoy, media, dias, ultimoDia, esHoy, disponible } o nil si hay poca historia.
function T.Historial(entrada, maxDias, hoyDia)
	if type(entrada) ~= "table" or type(entrada.h) ~= "table" then return nil end
	local dias = {}
	for d in pairs(entrada.h) do
		local n = tonumber(d)
		if n then dias[#dias + 1] = n end
	end
	if #dias < 3 then return nil end
	table.sort(dias, function(a, b) return a > b end)
	local function precio(n)
		local k = tostring(n)
		return (entrada.l and entrada.l[k]) or entrada.h[k]
	end
	local hoy = precio(dias[1])
	local suma, cuenta = 0, 0
	for i = 2, math.min(#dias, (maxDias or 14) + 1) do
		local p = precio(dias[i])
		if p then suma, cuenta = suma + p, cuenta + 1 end
	end
	if cuenta < 2 or not hoy then return nil end
	local disponible = type(entrada.a) == "table" and tonumber(entrada.a[tostring(dias[1])]) or nil
	return {
		hoy = hoy, media = suma / cuenta, dias = cuenta, ultimoDia = dias[1],
		esHoy = hoyDia ~= nil and dias[1] == hoyDia, disponible = disponible,
	}
end

T.MIN_DISPONIBLE = 3 -- una sola subasta barata no es "el mercado": se piden al menos 3 a la venta

-- ¿Está barato hoy? (precio de hoy al 70 % o menos de su media, y con suficientes a la venta)
function T.EsBarato(h, umbral)
	if not h or not (h.media > 0) then return false end
	if h.disponible ~= nil and h.disponible < T.MIN_DISPONIBLE then return false end
	return (h.hoy / h.media) <= (umbral or 0.7)
end

-- Número de día de HOY con el mismo calendario que Auctionator (días desde el 1-1-2020).
function T.DiaHoy()
	local cero = Auctionator and Auctionator.Constants and Auctionator.Constants.SCAN_DAY_0
	if type(cero) ~= "number" and time then cero = time({ year = 2020, month = 1, day = 1, hour = 0 }) end
	if type(cero) ~= "number" or not time then return nil end
	return math.floor((time() - cero) / 86400)
end

-- Parte del juego.
local function BaseAuctionator()
	local db = Auctionator and Auctionator.Database and Auctionator.Database.db
	if type(db) ~= "table" then return nil end
	return db
end

local function Info(id)
	local f = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
	local nombre, link, _, _, _, _, _, _, _, _, vendedor = f(id)
	if not nombre and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
	return nombre, link, vendedor
end

local POR_TANDA = 400 -- entradas revisadas por cuadro de imagen: no congela el juego
local ocupado = false

-- Recorre los precios guardados por Auctionator en tandas (C_Timer), sin congelar el juego.
-- filtro(clase, subclase) -> true para incluir (se filtra primero con GetItemInfoInstant, que es rápido).
-- alTerminar(lista, sinCargar, ultimoDia) o alTerminar(nil, mensajeDeError).
function T.Recorrer(filtro, soloBaratos, alTerminar)
	local db = (T.BasePrecios and T.BasePrecios()) or BaseAuctionator() -- el más reciente de los dos (Escaneo.lua)
	if not db then
		alTerminar(nil, "No tengo precios todavía: abre la casa de subastas y aprieta el botón \"Escanear (Tasador)\".")
		return
	end
	if ocupado then
		alTerminar(nil, "Ya estoy revisando los precios: espera unos segundos.")
		return
	end
	ocupado = true
	local claves = {}
	for clave in pairs(db) do
		local id = tonumber(clave) -- las claves de equipo traen texto extra ("g:..."): se saltan
		if id then claves[#claves + 1] = id end
	end
	local hoyDia = T.DiaHoy()
	local lista, sinCargar, ultimo, pos = {}, 0, 0, 1
	local function tanda()
		local ok, err = pcall(function()
			local fin = math.min(#claves, pos + POR_TANDA - 1)
			for i = pos, fin do
				local id = claves[i]
				local _, _, clase, subclase = T.InfoRapida(id)
				if not filtro or filtro(clase, subclase) then
					local okH, h = pcall(T.Historial, db[tostring(id)], nil, hoyDia)
					if okH and h then
						if h.ultimoDia > ultimo then ultimo = h.ultimoDia end
						if not soloBaratos or T.EsBarato(h) then
							local nombre, link, vendedor = Info(id)
							if not nombre then
								sinCargar = sinCargar + 1
							else
								lista[#lista + 1] = { link = link, h = h, vendedor = vendedor or 0 }
							end
						end
					end
				end
			end
			pos = fin + 1
		end)
		if not ok then
			ocupado = false
			alTerminar(nil, "Error leyendo Auctionator: " .. tostring(err))
			return
		end
		if pos <= #claves then
			C_Timer.After(0, tanda)
			return
		end
		ocupado = false
		-- Solo precios de HOY o de AYER (día real, no "el último escaneo"): lo viejo no sirve para decidir hoy.
		local frescos = {}
		local desde = (hoyDia or ultimo) - 1
		for _, x in ipairs(lista) do
			if x.h.ultimoDia >= desde then frescos[#frescos + 1] = x end
		end
		alTerminar(frescos, sinCargar, ultimo, hoyDia)
	end
	tanda()
end

local CLASE_REACTIVO, CLASE_COMERCIO, SUB_HIERBA = 5, 7, 9

local function AvisoViejo(ultimo, hoyDia)
	if hoyDia and ultimo and ultimo > 0 and ultimo < hoyDia - 1 then
		T.Decir("  Tu último escaneo de la subasta es de hace " .. (hoyDia - ultimo) .. " días: escanea hoy (botón \"Escanear (Tasador)\" en la subasta).")
	end
end

local function Disponible(h)
	if h.disponible then return ", " .. h.disponible .. " a la venta" end
	return ""
end

function T.MostrarBaratos()
	T.Recorrer(function(clase) return clase == CLASE_COMERCIO or clase == CLASE_REACTIVO end, true, function(lista, err, ultimo, hoyDia)
		if not lista then T.Decir(err) return end
		table.sort(lista, function(a, b) return (a.h.hoy / a.h.media) < (b.h.hoy / b.h.media) end)
		T.Decir("|cffffd100Materiales BARATOS hoy|r (precio de hoy contra su media de los últimos días):")
		if #lista == 0 then T.Decir("  Nada claramente barato. Escanea la subasta otra vez mañana para tener más historia.") end
		AvisoViejo(ultimo, hoyDia)
		for i = 1, math.min(10, #lista) do
			local x = lista[i]
			local cuando = x.h.esHoy and "hoy" or "ayer"
			T.Decir(string.format("  %s  %s %s  (media %s, %d%% menos%s)", x.link, cuando, T.Dinero(x.h.hoy), T.Dinero(x.h.media),
				math.floor((1 - x.h.hoy / x.h.media) * 100 + 0.5), Disponible(x.h)))
		end
		if err and err > 0 then T.Decir("  (" .. err .. " objetos aún cargando: repite el comando en unos segundos)") end
		T.Decir("  |cff999999Ojo: barato no es garantía de ganancia. Revisa cuántos hay a la venta antes de comprar para revender.|r")
	end)
end

function T.MostrarHierbas()
	T.Recorrer(function(clase, sub) return clase == CLASE_COMERCIO and sub == SUB_HIERBA end, false, function(lista, err, ultimo, hoyDia)
		if not lista then T.Decir(err) return end
		table.sort(lista, function(a, b) return a.h.hoy > b.h.hoy end)
		local a = T.Ajustes()
		T.Decir("|cffffd100Hierbas que más pagan hoy|r (lo que te queda tras la comisión, por unidad y por montón de 20):")
		AvisoViejo(ultimo, hoyDia)
		for i = 1, math.min(10, #lista) do
			local x = lista[i]
			local neto = x.h.hoy * (1 - a.comision)
			T.Decir(string.format("  %s  %s c/u  ·  %s x20%s", x.link, T.Dinero(neto), T.Dinero(neto * 20), Disponible(x.h)))
		end
		if #lista == 0 then T.Decir("  Sin datos de hierbas de hoy o ayer: escanea la subasta (botón \"Escanear (Tasador)\").") end
		if err and err > 0 then T.Decir("  (" .. err .. " objetos aún cargando: repite el comando en unos segundos)") end
		T.Decir("  |cff999999Elige las que tu nivel de Herboristería ya puede recoger.|r")
	end)
end
