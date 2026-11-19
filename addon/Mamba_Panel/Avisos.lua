-- Mamba_Panel/Avisos.lua: AVISOS DE OPORTUNIDAD según el lugar (K103). Igual que Polestar avisa del rango nuevo
-- de un hechizo, Mamba avisa EN EL MOMENTO y con un botón. Cada aviso es una línea más del panel de la guía (K56),
-- ordenada con las demás por impacto ÷ minutos (K62), y se silencia por tipo (clic derecho › No avisar más de esto).
--   "lugar"  : una línea del plan cuyo lugar está en tu mapa ("Ya que estás en Cima del Trueno: aprende Oficial…");
--   "subasta": con la subasta abierta, lo que el Tasador dice que conviene subastar ("vende X a N"), con
--              «Publicar» (deja la subasta lista con el precio; el clic final es del jugador);
--   "espacio": con las bolsas casi llenas, lo que menos vale y se puede vender ("vende X para hacer espacio");
--   "botin"  : al saquear, un material que tu plan necesita o que se vende caro ("<bicho> da X: …").
-- Los datos son del Tasador (MambaAPI.Bolsas, MambaAPI.PrecioObjeto) y de Mi plan (MambaPlan.MaterialDelPlan):
-- sin esos datos, no hay aviso (nada se inventa). Licencia: GPL-3.0-only.
local _, N = ...
local floor, min, max, format = math.floor, math.min, math.max, string.format

N.TIPOS_AVISO = { lugar = "Ya que estás aquí", subasta = "En la subasta", espacio = "Bolsas llenas", botin = "Botín útil" }
N.estado = { subasta = false, vendedor = false }
N.botin = {} -- [itemID] = { t, bicho, item, nombre, motivo, precio }
local BOTIN_VIVE = 15 * 60

local function ahora() return GetTime and GetTime() or 0 end
local function dinero(c)
	local M = _G.MambaPlan
	if M and M.Dinero then return M.Dinero(c) end
	-- el mismo formato que Mi plan: "1 o 20 p 5 c", sin ceros de más
	c = floor(c or 0)
	local t = {}
	local o, pl, co = floor(c / 10000), floor(c / 100) % 100, c % 100
	if o > 0 then t[#t + 1] = o .. " o" end
	if pl > 0 then t[#t + 1] = pl .. " p" end
	if co > 0 or #t == 0 then t[#t + 1] = co .. " c" end
	return table.concat(t, " ")
end

function N.Silenciado(tipo)
	local s = N.PJ().silencio
	return s and s[tipo] and true or false
end

function N.Silenciar(tipo, si)
	local pj = N.PJ()
	pj.silencio = pj.silencio or {}
	pj.silencio[tipo] = si ~= false or nil
end

local function mapaJugador()
	return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") or nil
end

local function zonaJugador()
	return (GetRealZoneText and GetRealZoneText()) or (GetZoneText and GetZoneText()) or nil
end

---------------------------------------------------------------- "lugar"
local function avisosDeLugar(lineas)
	if N.Silenciado("lugar") then return end
	local mapa = mapaJugador()
	if not mapa then return end
	local zona = zonaJugador()
	for _, l in ipairs(lineas) do
		if l.lugar and l.lugar.mapa == mapa and l.puedeYa and not l.aviso then
			l.aviso = "lugar"
			l.titulo = format("Ya que estás en %s: %s", zona or l.lugar.zona or "esta zona", l.titulo or "")
			l.impacto = min(5, (l.impacto or 1) + 1)
			l.porque = (l.porque or "") .. (l.porque and "; " or "") .. "lo tienes aquí, sin viaje"
		end
	end
end

---------------------------------------------------------------- "subasta" y "espacio" (Tasador)
local function bolsas()
	local A = _G.MambaAPI
	if not (A and A.Bolsas) then return nil end
	local ok, l = pcall(A.Bolsas)
	return ok and type(l) == "table" and l or nil
end

local function nombreDe(o)
	local n = o.link and tostring(o.link):match("%[(.-)%]")
	if not n and o.id and C_Item and C_Item.GetItemNameByID then n = C_Item.GetItemNameByID(o.id) end
	return n or ("objeto " .. tostring(o.id))
end

-- Deja la subasta lista con el precio (MambaAPI.PonerEnSubasta, de la ventana de Mamba); sin esa función,
-- abre «Vender lo mío», que tiene el mismo botón.
function N.Publicar(o)
	local A = _G.MambaAPI
	if A and A.PonerEnSubasta then
		local ok, hecho = pcall(A.PonerEnSubasta, o.id, o.precio)
		if ok and hecho then return true end
	end
	if A and A.Abrir then pcall(A.Abrir, "MambaSubasta") end
	return false
end

local function avisosDeSubasta(out, lista)
	if not N.estado.subasta or N.Silenciado("subasta") or not lista then return end
	local cand = {}
	for _, o in ipairs(lista) do
		if o.sug == "subastar" and not o.elegido and tonumber(o.precio) and o.precio > 0 then cand[#cand + 1] = o end
	end
	table.sort(cand, function(a, b) return a.precio * (a.cantidad or 1) > b.precio * (b.cantidad or 1) end)
	for i = 1, min(2, #cand) do
		local o = cand[i]
		local total = o.precio * (o.cantidad or 1)
		out[#out + 1] = { clave = "aviso:subasta:" .. o.id, aviso = "subasta", tipo = "aviso", verbo = "vendor", puedeYa = true,
			titulo = format("Ya que estás en la subasta: vende %s a %s", nombreDe(o), dinero(o.precio)),
			como = (o.motivo and (o.motivo .. ". ") or "") .. "«Publicar» la deja lista con ese precio; el clic final es tuyo.",
			impacto = total >= 10000 and 3 or total >= 2000 and 2 or 1, porque = "oro: " .. dinero(total), minutos = 1,
			accion = { "Publicar", function() N.Publicar(o) end } }
	end
end

local function avisoDeEspacio(out, lista, e)
	local b = e and e.bolsas
	if N.Silenciado("espacio") or not (b and b.total and b.total > 0 and b.libres and b.libres <= 2) or not lista then return false end
	local mejor
	for _, o in ipairs(lista) do
		if o.sug == "basura" or o.sug == "vendedor" then
			local valor = (o.vendedor or 0) * (o.cantidad or 1)
			if not mejor or valor < mejor.valor then mejor = { o = o, valor = valor } end
		end
	end
	if not mejor then return false end
	local o = mejor.o
	out[#out + 1] = { clave = "aviso:espacio", aviso = "espacio", tipo = "aviso", verbo = "vendor", puedeYa = true,
		titulo = format("Vende %s (%s) para hacer espacio", nombreDe(o), dinero(mejor.valor)),
		como = b.libres == 0 and "Tus bolsas están llenas: lo siguiente que saquees se pierde." or format("Te quedan %d casillas.", b.libres),
		impacto = 3, porque = "con las bolsas llenas pierdes el botín", minutos = 2, destino = "reparar", ver = "vender" }
	return true
end

---------------------------------------------------------------- "botin"
-- Al saquear: un objeto que tu plan necesita (Mi plan) o que se vende por 50 p o más (Tasador).
local CARO = 5000
function N.Saqueo()
	if N.Silenciado("botin") or not (GetNumLootItems and GetLootSlotLink) then return end
	-- el bicho se nombra solo si el botín es de verdad del objetivo (GetLootSourceInfo); si no, no se nombra
	local bicho
	local guid = UnitGUID and UnitGUID("target")
	if guid and GetLootSourceInfo and UnitIsDead and UnitIsDead("target") then
		for i = 1, GetNumLootItems() do
			local ok, fuente = pcall(GetLootSourceInfo, i)
			if ok and fuente == guid then bicho = UnitName("target"); break end
		end
	end
	local M, A = _G.MambaPlan, _G.MambaAPI
	for i = 1, GetNumLootItems() do
		local link = GetLootSlotLink(i)
		local id = link and tonumber(tostring(link):match("item:(%d+)"))
		if id then
			local motivo, precio
			if M and M.MaterialDelPlan then
				local ok, m = pcall(M.MaterialDelPlan, id)
				if ok and type(m) == "table" and m.texto then motivo = m.texto end
			end
			if A and A.PrecioObjeto then
				local ok, p, fuente = pcall(A.PrecioObjeto, id)
				if ok and tonumber(p) and fuente == "subasta" then precio = p end
			end
			if motivo or (precio and precio >= CARO) then
				N.botin[id] = { t = ahora(), bicho = bicho, nombre = tostring(link):match("%[(.-)%]") or ("objeto " .. id),
					motivo = motivo, precio = precio, mapa = mapaJugador(), zona = zonaJugador() }
			end
		end
	end
end

local function avisosDeBotin(out)
	if N.Silenciado("botin") then return end
	local t = ahora()
	for id, b in pairs(N.botin) do
		if t - b.t > BOTIN_VIVE then
			N.botin[id] = nil
		else
			local por = b.motivo or ("se vende a " .. dinero(b.precio) .. " en la subasta")
			out[#out + 1] = { clave = "aviso:botin:" .. id, aviso = "botin", tipo = "aviso", verbo = "collect", puedeYa = true,
				titulo = format("%s da %s: %s", b.bicho or "Lo que matas aquí", b.nombre, por),
				como = format("Sigue matando %s en %s mientras te sirva.", b.bicho or "lo mismo", b.zona or "esta zona"),
				impacto = b.motivo and 3 or 2, porque = b.motivo and "lo pide tu plan" or "oro", minutos = 5,
				ver = b.motivo and "farmeo" or "subasta" }
		end
	end
end

---------------------------------------------------------------- todo junto
-- Marca los avisos de lugar sobre las líneas del plan y agrega los demás. La línea "llenas" de siempre se va
-- cuando el aviso de espacio dice QUÉ vender.
function N.AplicarAvisos(out, e)
	avisosDeLugar(out)
	local lista = (N.estado.subasta or (e and e.bolsas and e.bolsas.libres and e.bolsas.libres <= 2)) and bolsas() or nil
	avisosDeSubasta(out, lista)
	if avisoDeEspacio(out, lista, e) then
		for i = #out, 1, -1 do if out[i].clave == "llenas" then table.remove(out, i) end end
	end
	avisosDeBotin(out)
end
