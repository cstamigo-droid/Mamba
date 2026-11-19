-- Tasador: puente con el juego (lee objetos, bolsas, equipo, talentos y precios de Auctionator).
-- Solo LEE información. No vende, no compra, no equipa: eso lo haces tú.
-- Licencia: GPL-3.0.
local _, T = ...

T.db = nil -- se llena en ADDON_LOADED con TasadorDB

-- Valores secretos: el cliente de Forever puede entregar valores "secretos" que se pueden
-- mostrar pero no comparar ni usar como clave. Se convierten en nil antes de usarlos
-- (mismo criterio que Spy\Forever.lua: issecretvalue).
function T.EsSecreto(v)
	return v ~= nil and issecretvalue ~= nil and issecretvalue(v) == true
end

function T.Leer(v)
	if T.EsSecreto(v) then return nil end
	return v
end

local function GetItemInfo(x)
	if C_Item and C_Item.GetItemInfo then return C_Item.GetItemInfo(x) end
	if _G.GetItemInfo then return _G.GetItemInfo(x) end
end

-- Datos que el cliente sabe sin tener el objeto en caché (rápido).
-- Devuelve id, equipLoc, clase, subclase.
function T.InfoRapida(x)
	local f = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
	if not f then return nil end
	local ok, id, _, _, equipLoc, _, clase, subclase = pcall(f, x)
	if not ok then return nil end
	return T.Leer(id), T.Leer(equipLoc), T.Leer(clase), T.Leer(subclase)
end

local function GetItemStats(link)
	local f = (C_Item and C_Item.GetItemStats) or _G.GetItemStats
	if not f then return nil end
	local ok, t = pcall(f, link)
	if not ok or type(t) ~= "table" then return nil end
	local limpio = {}
	for k, v in pairs(t) do
		if type(v) == "number" and not T.EsSecreto(v) then limpio[k] = v end
	end
	return limpio
end

function T.Ajustes()
	local a = {}
	for k, v in pairs(T.DEFAULTS) do a[k] = v end
	if T.db and T.db.ajustes then
		for k, v in pairs(T.db.ajustes) do a[k] = v end
	end
	return a
end

function T.ItemID(link)
	if type(link) ~= "string" then return nil end
	return tonumber(link:match("item:(%d+)"))
end

-- Sufijo aleatorio ("del Oso", "del Búho"...): 7.º campo después del id en el link.
function T.Sufijo(link)
	if type(link) ~= "string" then return 0 end
	local s = link:match("item:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:(%-?%d+)")
	return tonumber(s) or 0
end

-- Precio de subasta (cobre por unidad), días desde que se vio y un aviso, con la API pública de Auctionator.
-- Objetos con sufijo aleatorio: Auctionator puede devolver el precio de OTRA variante (o del objeto
-- base). Si el precio de esta versión es igual al del id base, no se usa: se avisa en vez de adivinar.
local SUFIJO = "Tiene sufijo aleatorio y no hay precio de esta versión exacta: búscala en la subasta."
local precioAuctionator

-- REGLA ÚNICA (ARQUITECTURA §7): hay dos fuentes, Auctionator y el escaneo propio (Escaneo.lua).
-- Gana la MÁS RECIENTE; si son del mismo día, Auctionator. Con sufijo aleatorio solo sirve Auctionator
-- (el escaneo propio guarda por id y no distingue "del Oso" de "del Búho").
function T.PrecioSubasta(link, itemID)
	local a, ad, aviso = precioAuctionator(link, itemID)
	if T.Sufijo(link) ~= 0 then
		if a then return a, ad end
		return nil, nil, aviso or (T.PrecioPropio and T.PrecioPropio(itemID) and SUFIJO) or nil
	end
	local p, pd, cant
	if T.PrecioPropio then p, pd, cant = T.PrecioPropio(itemID, T.DiaHoy and T.DiaHoy()) end
	-- 4.º valor: cuántas había a la venta (solo lo sabe el escaneo propio; Auctionator no lo dice)
	if p and (not a or (pd and ad and pd < ad)) then return p, pd, nil, cant end -- Auctionator sin edad: gana Auctionator
	return a, ad
end

precioAuctionator = function(link, itemID)
	local api = Auctionator and Auctionator.API and Auctionator.API.v1
	if not api then return nil, nil end
	local function llamar(fn, arg)
		if not fn or arg == nil then return nil end
		local ok, v = pcall(fn, "Tasador", arg)
		if ok and type(v) == "number" then return v end
		return nil
	end
	local precio = llamar(api.GetAuctionPriceByItemLink, link)
	local dias = llamar(api.GetAuctionAgeByItemLink, link)
	if T.Sufijo(link) ~= 0 then
		local base = llamar(api.GetAuctionPriceByItemID, itemID)
		if not precio or precio == base then
			return nil, nil, SUFIJO
		end
		return precio, dias
	end
	if not precio then precio = llamar(api.GetAuctionPriceByItemID, itemID) end
	if dias == nil then dias = llamar(api.GetAuctionAgeByItemID, itemID) end
	return precio, dias
end

---------------------------------------------------------------------------
-- Texto del cuadro del objeto (C_TooltipInfo), con caché. Sirve para leer las
-- bonificaciones "Equipar:" que GetItemStats no trae.
---------------------------------------------------------------------------
local cacheLineas, cuentaCache, TOPE_CACHE = {}, 0, 300

local function TextoDeLinea(l)
	if type(l) ~= "table" then return nil end
	local t = l.leftText
	if t == nil and type(l.args) == "table" then -- clientes viejos: los campos vienen en args
		for _, a in ipairs(l.args) do
			if a.field == "leftText" then t = a.stringVal end
		end
	end
	t = T.Leer(t)
	return type(t) == "string" and t or nil
end

function T.TextosDeDatos(datos)
	local out = {}
	if type(datos) == "table" and type(datos.lines) == "table" then
		for _, l in ipairs(datos.lines) do
			local t = TextoDeLinea(l)
			if t then out[#out + 1] = t end
		end
	end
	return out
end

-- Devuelve la lista de textos del cuadro, o nil si el cliente no lo puede dar todavía.
function T.LineasDe(link)
	if type(link) ~= "string" then return nil end
	if cacheLineas[link] then return cacheLineas[link] end
	local get = C_TooltipInfo and C_TooltipInfo.GetHyperlink
	if not get then return nil end
	local ok, datos = pcall(get, link)
	if not ok then return nil end
	local lineas = T.TextosDeDatos(datos)
	if #lineas == 0 or lineas[1] == RETRIEVING_ITEM_INFO then return nil end -- aún cargando: no guardar
	if cuentaCache >= TOPE_CACHE then cacheLineas, cuentaCache = {}, 0 end
	cacheLineas[link] = lineas
	cuentaCache = cuentaCache + 1
	return lineas
end

-- Puntaje completo de un objeto. Devuelve puntaje, sabe (false si hay efectos "Equipar:"
-- que no se pudieron medir o no se pudo leer el cuadro), cargando (true si el cuadro aún no llegó).
function T.PuntajeDe(link, pesos)
	local stats = GetItemStats(link)
	local lineas = T.LineasDe(link)
	if not lineas then return T.Puntaje(stats, pesos), false, true end
	local extra, desconocidas = T.LeerEquipar(lineas, ITEM_SPELL_TRIGGER_ONEQUIP)
	return T.PuntajeTotal(stats, extra, pesos), desconocidas == 0
end

-- ¿El cuadro dice que el objeto ya está ligado a ti?
local LIGADO = { Ligado = true, Soulbound = true }
for _, clave in ipairs({ "ITEM_SOULBOUND", "ITEM_ACCOUNTBOUND", "ITEM_BNETACCOUNTBOUND", "ITEM_BIND_TO_ACCOUNT",
	"ITEM_BIND_TO_BNETACCOUNT", "ITEM_ACCOUNTBOUND_UNTIL_EQUIP" }) do
	local t = _G[clave]
	if type(t) == "string" and t ~= "" then LIGADO[t] = true end
end

function T.LigadoEnTextos(lineas)
	for _, t in ipairs(lineas or {}) do
		if LIGADO[t] then return true end
	end
	return false
end

-- Arma la tabla "info" que usa T.Evaluar. Devuelve nil si el juego aún no cargó el objeto.
-- ligado = true/false si ya se sabe (bolsas: isBound; cuadro: línea "Ligado").
function T.InfoDe(link, ligado)
	local nombre, linkReal, calidad, nivelObj, nivelMin, _, _, pila, equipLoc, _, vendedor, clase, subclase, liga, _, _, reactivo =
		GetItemInfo(link)
	if not nombre then return nil end
	local real = linkReal or link
	-- Para el precio y los sufijos sirve más el link que trae el sufijo (el que se pasó), si lo tiene.
	if T.Sufijo(link) ~= 0 then real = link end
	local id = T.ItemID(real)
	local subasta, dias, avisoPrecio, disponible = T.PrecioSubasta(real, id)
	return {
		id = id, link = real, nombre = nombre,
		calidad = calidad, nivelObj = nivelObj, nivelMin = nivelMin or 0, equipLoc = equipLoc,
		vendedor = vendedor or 0, clase = clase, subclase = subclase, liga = liga,
		pila = pila or 1, ligado = ligado and true or false,
		reactivo = reactivo and true or false,
		herramienta = T.EsHerramienta(id, clase, subclase),
		subasta = subasta, diasSubasta = dias, avisoPrecio = avisoPrecio, disponible = disponible,
	}
end

---------------------------------------------------------------------------
-- Rol para comparar equipo. Orden (igual que Polestar, Gear.lua: DetectSpec):
-- 1) el elegido con /tasador rol; 2) el árbol de talentos de Forever (C_Traits:
-- una columna por rama, con los puntos gastados); 3) las pestañas de
-- C_SpecializationInfo; 4) la especialización principal elegida; 5) la API
-- vieja GetTalentTabInfo; 6) Equilibrio.
---------------------------------------------------------------------------
function T.ColumnasTalentos()
	local CT, TR = C_ClassTalents, C_Traits
	if not (CT and CT.GetActiveConfigID and TR and TR.GetConfigInfo and TR.GetGroupDisplayInfoByTreeID and TR.GetGroupCurrencyInfo) then return nil end
	local ok, config = pcall(CT.GetActiveConfigID)
	config = ok and T.Leer(config)
	if type(config) ~= "number" then return nil end
	local ok2, info = pcall(TR.GetConfigInfo, config)
	local arbol = ok2 and type(info) == "table" and type(info.treeIDs) == "table" and T.Leer(info.treeIDs[1])
	if type(arbol) ~= "number" then return nil end
	local ok3, grupos = pcall(TR.GetGroupDisplayInfoByTreeID, arbol)
	if not (ok3 and type(grupos) == "table" and grupos[1]) then return nil end
	local ids = {}
	for i, g in ipairs(grupos) do ids[i] = T.Leer(g.groupID) end
	local gastado = {}
	local ok4, monedas = pcall(TR.GetGroupCurrencyInfo, config, ids)
	if ok4 and type(monedas) == "table" then
		for _, m in ipairs(monedas) do
			local c = type(m) == "table" and type(m.currencyInfos) == "table" and m.currencyInfos[1]
			local gid = T.Leer(m.traitNodeGroupID)
			if type(c) == "table" and gid ~= nil then gastado[gid] = T.Leer(c.spent) end
		end
	end
	local out = {}
	for i, g in ipairs(grupos) do
		local gid = T.Leer(g.groupID)
		local p = gid ~= nil and gastado[gid] or nil
		out[i] = { name = T.Leer(g.displayName), points = type(p) == "number" and p or 0 }
	end
	return out
end

local function PestanasEspecializacion()
	local S = C_SpecializationInfo
	if not (S and S.GetSpecializationInfo) then return nil end
	local out = {}
	for i = 1, 3 do
		local ok, _, nombre, _, _, _, _, puntos = pcall(S.GetSpecializationInfo, i)
		if ok then out[i] = { name = T.Leer(nombre), points = T.Leer(puntos) } else out[i] = {} end
	end
	return out
end

local function EspecializacionPrincipal()
	local S = C_SpecializationInfo
	if not (S and S.GetSpecialization) then return nil end
	if S.IsSpecSelectionEnabled then
		local ok, activa = pcall(S.IsSpecSelectionEnabled, 11) -- 11 = druida
		if not (ok and T.Leer(activa)) then return nil end
	end
	local ok, i = pcall(S.GetSpecialization)
	i = ok and T.Leer(i)
	if type(i) ~= "number" or i <= 0 then return nil end
	local nombre
	if S.GetSpecializationInfo then
		local ok2, _, n = pcall(S.GetSpecializationInfo, i)
		if ok2 then nombre = T.Leer(n) end
	end
	return T.RolDeNombre(nombre, i)
end

local function PestanasViejas()
	if not GetTalentTabInfo then return nil end
	local out = {}
	for i = 1, 3 do
		local ok, a, b, c, d, e = pcall(GetTalentTabInfo, i)
		local puntos, nombre
		if ok then
			-- El orden de lo que devuelve cambia entre versiones: el primer número razonable (0-61).
			for _, v in ipairs({ T.Leer(c), T.Leer(e), T.Leer(d), T.Leer(b) }) do
				if type(v) == "number" and v >= 0 and v <= 61 then puntos = v break end
			end
			nombre = type(T.Leer(a)) == "string" and a or (type(T.Leer(b)) == "string" and b or nil)
		end
		out[i] = { name = nombre, points = puntos }
	end
	return out
end

function T.RolActual()
	local fijo = T.db and T.db.ajustes and T.db.ajustes.rol
	if fijo and fijo ~= "auto" then return fijo, "elegido" end
	local rol = T.RolDeColumnas(T.ColumnasTalentos())
	if rol then return rol, "talentos" end
	rol = T.RolDeColumnas(PestanasEspecializacion())
	if rol then return rol, "talentos" end
	rol = EspecializacionPrincipal()
	if rol then return rol, "especializacion" end
	rol = T.RolDeColumnas(PestanasViejas())
	if rol then return rol, "talentos" end
	return "equilibrio", "por defecto"
end

---------------------------------------------------------------------------
-- Comparación con lo que llevas puesto.
---------------------------------------------------------------------------
local MANO, IZQ = 16, 17
local IZQUIERDA = { INVTYPE_HOLDABLE = true, INVTYPE_SHIELD = true, INVTYPE_WEAPONOFFHAND = true }

local function LinkPuesto(slot)
	return GetInventoryItemLink and T.Leer(GetInventoryItemLink("player", slot)) or nil
end

-- Devuelve puntaje (false = ranura vacía), sabe, cargando.
local function PuntajePuesto(slot, pesos)
	local link = LinkPuesto(slot)
	if not link then return false, true, false end
	return T.PuntajeDe(link, pesos)
end

local function ManoEsDosManos()
	local link = LinkPuesto(MANO)
	if not link then return false end
	local _, loc = T.InfoRapida(link)
	return loc == "INVTYPE_2HWEAPON"
end

-- ¿Es mejora? Devuelve texto (o nil) y esMejora (true solo si se está seguro).
function T.TextoMejora(info)
	local _, clase = UnitClass("player")
	if T.Leer(clase) ~= "DRUID" then return nil, false end
	if info.herramienta then return nil, false end
	local ranuras = info.equipLoc and T.RANURAS[info.equipLoc]
	if not ranuras then return nil, false end
	if info.equipLoc == "INVTYPE_WEAPONOFFHAND" then
		return "|cff999999No lo puedes usar (el druida no usa armas en la mano izquierda).|r", false
	end
	if info.clase == T.CLASE_ARMADURA and not T.DRUIDA_ARMADURA[info.subclase] then
		return "|cff999999No lo puedes usar (tipo de armadura).|r", false
	end
	if info.clase == T.CLASE_ARMA and not T.DRUIDA_ARMA[info.subclase] then
		return "|cff999999No lo puedes usar (tipo de arma).|r", false
	end
	local nivel = T.Leer(UnitLevel("player")) or 1
	local rol = T.RolActual()
	local pesos = T.PesosPara("DRUID", rol, nivel)
	local rolTxt = T.ROL_NOMBRE[rol] or rol
	local espera = ""
	if (info.nivelMin or 0) > nivel then espera = " (cuando llegues a nivel " .. info.nivelMin .. ")" end

	if IZQUIERDA[info.equipLoc] and ManoEsDosManos() then
		return "|cffffd100Llevas un arma de dos manos: esto solo sirve si la cambias por una de una mano.|r", false
	end

	local nuevo, sabeNuevo, cargando = T.PuntajeDe(info.link, pesos)
	-- Un objeto de mucho más nivel no se marca como mejora para guardar: falta demasiado para usarlo.
	local lejos = (info.nivelMin or 0) > nivel + 3
	local puestos, sabePuesto = {}, true
	local nota = ""
	if info.equipLoc == "INVTYPE_2HWEAPON" then
		local mano, s1, c1 = PuntajePuesto(MANO, pesos)
		local izq, s2, c2 = PuntajePuesto(IZQ, pesos)
		sabePuesto = s1 and s2
		cargando = cargando or c1 or c2
		if mano == false and izq == false then
			puestos[1] = false
		else
			puestos[1] = (mano or 0) + (izq or 0)
		end
	else
		for i, slot in ipairs(ranuras) do
			local p, s, c = PuntajePuesto(slot, pesos)
			puestos[i] = p
			sabePuesto = sabePuesto and s
			cargando = cargando or c
		end
		if (info.equipLoc == "INVTYPE_WEAPON" or info.equipLoc == "INVTYPE_WEAPONMAINHAND") and ManoEsDosManos() then
			nota = " (y te deja la mano izquierda libre)"
		end
	end

	local dif = T.Comparar(nuevo, puestos)
	if cargando then
		return "|cff999999Comparación: aún cargando datos del objeto, vuelve a pasar el ratón.|r", false
	end
	if dif == "vacia" then
		if not sabeNuevo then
			return "|cffffd100Tienes esa ranura vacía, pero tiene efectos \"Equipar:\" que no sé medir: compáralo tú.|r", false
		end
		local util = T.PuntajeDe(info.link, T.SinDesempate(pesos))
		if nuevo <= 0 or util <= 0 then
			return "Tienes esa ranura vacía, pero esto no suma nada para " .. rolTxt, false
		end
		return "|cff00ff00Tienes esa ranura vacía: póntelo|r" .. espera, not lejos
	end
	if not (sabeNuevo and sabePuesto) then
		return "|cffffd100Tiene efectos \"Equipar:\" que no sé medir: compáralo tú.|r", false
	end
	if dif == "sinbase" then
		if nuevo > 0 then
			return string.format("|cff00ff00MEJORA: lo tuyo no suma nada para %s y esto sí|r%s", rolTxt, espera), not lejos
		end
		return "Ni esto ni lo que llevas suman para " .. rolTxt, false
	elseif dif >= 1 then
		return string.format("|cff00ff00MEJORA: %d%% mejor que lo tuyo para %s|r%s%s", math.floor(dif + 0.5), rolTxt, nota, espera), not lejos
	elseif dif <= -1 then
		return string.format("|cffff6666Peor que lo tuyo para %s (%d%%)|r", rolTxt, math.floor(dif - 0.5)), false
	end
	return "Igual a lo que llevas para " .. rolTxt, false
end

-- ¿Es mejora segura? (para no recomendar venderla). Segundo valor: duda (no se pudo medir).
function T.EsMejora(info)
	if info.clase ~= T.CLASE_ARMA and info.clase ~= T.CLASE_ARMADURA then return false, false end
	local ok, texto, mejora = pcall(T.TextoMejora, info)
	if not ok then return false, false end
	local duda = type(texto) == "string" and (texto:find("no sé medir", 1, true) or texto:find("cargando", 1, true)) and true or false
	return mejora == true, duda
end

-- Recorre tus bolsas (0 a 4). Devuelve lista de { info, cantidad }.
function T.LeerBolsas()
	local lista, sinCargar = {}, 0
	local C = C_Container
	if not (C and C.GetContainerNumSlots and C.GetContainerItemLink) then return lista, 0 end
	for bolsa = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4) do -- incluye la bolsa de componentes (5) de Forever
		local n = T.Leer(C.GetContainerNumSlots(bolsa)) or 0
		for slot = 1, n do
			local link = T.Leer(C.GetContainerItemLink(bolsa, slot))
			if link then
				local cantidad, ligado = 1, false
				local datos = C.GetContainerItemInfo and C.GetContainerItemInfo(bolsa, slot)
				if type(datos) == "table" then
					cantidad = T.Leer(datos.stackCount) or 1
					ligado = T.Leer(datos.isBound) == true
				end
				local info = T.InfoDe(link, ligado)
				if info then
					info.cantidad = cantidad
					-- de misión o inicia una misión (K115): lo dice el juego para cada casilla
					if C.GetContainerItemQuestInfo then
						local ok, q = pcall(C.GetContainerItemQuestInfo, bolsa, slot)
						if ok and type(q) == "table" then
							info.esMision = T.Leer(q.isQuestItem) == true or nil
							info.inicia = T.Leer(q.questID) ~= nil or nil
						end
					end
					info.mejora, info.duda = T.EsMejora(info)
					lista[#lista + 1] = { info = info, cantidad = cantidad }
				else
					sinCargar = sinCargar + 1
					local id = T.ItemID(link)
					if id and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
				end
			end
		end
	end
	return lista, sinCargar
end
