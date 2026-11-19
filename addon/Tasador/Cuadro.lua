-- Tasador/Cuadro.lua: UN solo bloque «Mamba» en el cuadro de cada objeto (pedido de Cristian, 18-11, fila E8),
-- en vez de «Polestar +12 %…» y «Tasador: …» por separado. En orden:
--   1. Mamba
--   2. el veredicto de equipo por cada objetivo del plan (Mazmorras / otro rol / contra jugadores), en color
--   3. lo que dice «Mi plan» (VITAL o lo pide el plan), si Mamba_Plan lo sabe
--   4. cuánto vale: vendedor y subasta, y «CARO: se vende a X» cuando conviene subastarlo
--   5. UNA acción al final, coherente con lo que marcaste (Alt + clic derecho) y con la venta automática de basura
-- Reemplaza a T.AgregarLineas (Tooltip.lua la llama en cada cuadro) y apaga la línea propia de Polestar.
-- Licencia: GPL-3.0-only.
local _, T = ...

local ORO = { 0.90, 0.73, 0.40 }
local BIEN, MAL, GRIS, TEXTO = { 0.42, 0.85, 0.60 }, { 0.96, 0.45, 0.45 }, { 0.61, 0.64, 0.73 }, { 0.85, 0.87, 0.92 }
local VITAL, PLAN = { 1, 0.50, 0.25 }, { 1, 0.84, 0.45 }

local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end
local function G() local p = PS(); return p and p.Gear end

local function hex(c) return string.format("|cff%02x%02x%02x", math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255)) end

-- Los objetivos que eligió el jugador en el asistente de «Mi plan» (MambaPlanPJ.respuestas).
local NOMBRE_ROL = { balance = "Equilibrio", feral = "Feral", feraltank = "Feral (tanque)", restoration = "Restauración" }
-- MambaPlanPJ.respuestas guarda el ROL ("sanar" | "tanque" | "danio") y el ÁRBOL (1..3, orden del juego);
-- aquí se traducen a la clave de pesos de Polestar (Gear.CLASSES[clase].specs: "(healer)" / "(tank)" en su etiqueta).
local function claveDe(rol, arbol)
	local g = G()
	local p = g and g.GetPlayer and g.GetPlayer()
	local c = p and p.class and g.CLASSES and g.CLASSES[p.class]
	if not (c and rol) then return nil end
	local mejor, dist
	for i, s in ipairs(c.specs or {}) do
		local et = tostring(s.label or ""):lower()
		local tipo = et:find("healer") and "sanar" or (et:find("tank") and "tanque" or "danio")
		if tipo == rol then
			local d = arbol and math.abs(i - arbol) or (s.key == c.default and -1 or i)
			if not dist or d < dist then mejor, dist = s.key, d end
		end
	end
	if not mejor and rol == "tanque" then return claveDe("danio", arbol) end -- druida: el tanque es Feral
	return mejor
end
T.ClaveDeRol = claveDe

local function objetivos()
	local r = type(_G.MambaPlanPJ) == "table" and _G.MambaPlanPJ.respuestas or nil
	local est = r and r.estilos or {}
	return { rol = r and claveDe(r.rol, r.arbol), rol2 = r and r.rol2 and claveDe(r.rol2, nil), jcj = est.jcj, jce = est.jce }
end

-- Veredicto contra lo puesto con los pesos de OTRO rol: «+8 %» / «-3 %» / nil
local function veredictoConRol(link, rol)
	local g = G()
	if not (g and g.WeightsFor and g.GetItemInfo and g.ScoreWith and g.CompareToEquipped) then return nil end
	local p = g.GetPlayer and g.GetPlayer()
	if not (p and p.class) then return nil end
	local w = g.WeightsFor(p.class, rol, p.level)
	local r = g.CompareToEquipped(link)
	if not (w and r and r.usable and r.slot and not r.equipped) then return nil end
	local nuevo = g.GetItemInfo(link)
	local puesto = GetInventoryItemLink and GetInventoryItemLink("player", r.slot)
	local viejo = puesto and g.GetItemInfo(puesto)
	if not nuevo then return nil end
	local a = g.ScoreWith(nuevo, w, r.slot == 17)
	local b = viejo and g.ScoreWith(viejo, w, r.slot == 17) or 0
	if b <= 0 then return a > 0 and "llena una ranura vacía" or nil, a > 0 end
	local pct = (a - b) / b * 100
	if math.abs(pct) < 0.5 then return "igual que lo tuyo", nil end
	return string.format("%+d %%", math.floor(pct + (pct > 0 and 0.5 or -0.5))), pct > 0
end

local ACCION = {
	subastar = "Subastar", vendedor = "Vender al vendedor", guardar = "Guardar", basura = "Es basura: se vende solo al abrir un vendedor",
}

function T.AgregarLineas(tooltip, link, datos)
	local ligado = T.LigadoEnTextos(T.TextosDeDatos(datos))
	local info = T.InfoDe(link, ligado)
	if not info then return end
	-- K115: "Este objeto inicia una misión" en las líneas del cuadro
	local inicia = ITEM_STARTS_QUEST or "Este objeto inicia una misión"
	for _, l in ipairs(T.TextosDeDatos(datos) or {}) do
		if type(l) == "string" and l:find(inicia, 1, true) then info.inicia = true end
	end
	local okM, mejoraTxt, esMejora = pcall(T.TextoMejora, info)
	if not okM then mejoraTxt, esMejora = nil, false end
	info.mejora = esMejora == true
	local r = T.Evaluar(info, T.Ajustes())
	local id = T.ItemID(link)

	tooltip:AddLine(" ")
	tooltip:AddLine("Mamba", ORO[1], ORO[2], ORO[3])

	-- 2) equipo, por objetivo
	local g = G()
	local conVeredicto = false
	if g and g.TooltipLine then
		local ok, _, derecha, cr, cg, cb = pcall(g.TooltipLine, link)
		if ok and derecha then
			conVeredicto = true
			local ob = objetivos()
			local etiqueta = ob.rol and NOMBRE_ROL[ob.rol] and ("Para " .. NOMBRE_ROL[ob.rol]) or "Para tu rol"
			if ob.jce then etiqueta = etiqueta .. " (mazmorras)" end
			tooltip:AddDoubleLine(etiqueta, derecha, TEXTO[1], TEXTO[2], TEXTO[3], cr or 1, cg or 1, cb or 1)
			if ob.rol2 and ob.rol2 ~= ob.rol then
				local okR, txt, bueno = pcall(veredictoConRol, link, ob.rol2)
				if okR and txt then
					local c = bueno == true and BIEN or (bueno == false and MAL or GRIS)
					tooltip:AddDoubleLine("Para " .. (NOMBRE_ROL[ob.rol2] or ob.rol2), txt, TEXTO[1], TEXTO[2], TEXTO[3], c[1], c[2], c[3])
				end
			end
			local A = _G.Asistente
			local E = A and A.modulos and A.modulos.equipo
			if ob.jcj and id and E and E.JCJ_NOMBRES and E.JCJ_NOMBRES[id] then
				tooltip:AddDoubleLine("Contra jugadores", "pieza del conjunto de honor", TEXTO[1], TEXTO[2], TEXTO[3], BIEN[1], BIEN[2], BIEN[3])
			end
		end
	end

	-- sin el veredicto de Polestar, el del propio Tasador (Mejora.lua)
	if not conVeredicto and mejoraTxt then tooltip:AddLine(mejoraTxt, TEXTO[1], TEXTO[2], TEXTO[3], true) end

	-- 3) Mi plan: VITAL o lo pide el plan; si Mi plan no dice nada, Mamba_Profesiones (VITAL para subir una profesión)
	local MP, dicho = _G.MambaPlan, false
	if id and type(MP) == "table" and MP.MaterialDelPlan then
		local ok, x = pcall(MP.MaterialDelPlan, id)
		if ok and type(x) == "table" and x.texto then
			local c = x.clase == "vital" and VITAL or PLAN
			tooltip:AddLine(x.texto, c[1], c[2], c[3], true)
			dicho = true
		end
	end
	local MPr = _G.MambaProfesiones
	if id and not dicho and type(MPr) == "table" and MPr.Vital then
		local ok, txt = pcall(MPr.Vital, id)
		if ok and type(txt) == "string" and txt ~= "" then tooltip:AddLine(txt, VITAL[1], VITAL[2], VITAL[3], true) end
	end

	-- 3b) objeto de misión (K116): de qué misión es, si sigue en el registro, qué falta, o si ya se puede tirar
	local Q = T.QuestDB and T.QuestDB()
	if id and Q then
		local okO, objs = pcall(Q.ObjectivesForItem, id)
		if okO and type(objs) == "table" and #objs > 0 then
			for i = 1, math.min(3, #objs) do
				local o = objs[i]
				local titulo = (o.entry and o.entry.title) or (Q.GetQuestTitle and Q.GetQuestTitle(o.q)) or ("misión " .. tostring(o.q))
				local falta = (o.max or 1) - (o.cur or 0)
				local estado = o.done and "listo" or (falta > 0 and ("faltan " .. falta .. " (" .. (o.cur or 0) .. "/" .. (o.max or 1) .. ")") or "listo")
				tooltip:AddDoubleLine("Para la misión «" .. tostring(titulo) .. "»", estado, PLAN[1], PLAN[2], PLAN[3], TEXTO[1], TEXTO[2], TEXTO[3])
			end
			tooltip:AddLine("Está en tu registro · Alt + clic derecho: ver la misión y Llévame", GRIS[1], GRIS[2], GRIS[3], true)
		elseif Q.ItemAheadList then
			local okA, lista = pcall(Q.ItemAheadList, id)
			if okA and type(lista) == "table" and lista[1] then
				local t = Q.GetQuestTitle and Q.GetQuestTitle(lista[1].q) or tostring(lista[1].q)
				tooltip:AddLine("Lo pide «" .. tostring(t) .. "», una misión de tu guía que todavía no tomaste: guárdalo.", PLAN[1], PLAN[2], PLAN[3], true)
			elseif T.MisionVieja and T.MisionVieja(id) then
				tooltip:AddLine("Su misión ya se entregó: se puede tirar.", GRIS[1], GRIS[2], GRIS[3], true)
			end
		end
	end

	-- 4) cuánto vale
	local vend = (info.vendedor or 0) > 0 and T.Dinero(info.vendedor) or "no lo compra"
	local sub = info.subasta and T.Dinero(info.subasta) or "sin datos aún"
	tooltip:AddDoubleLine("Vendedor: " .. vend, "Subasta: " .. sub, GRIS[1], GRIS[2], GRIS[3], GRIS[1], GRIS[2], GRIS[3])
	if r.nivel == "Caro" and info.subasta then
		tooltip:AddLine("CARO: se vende a " .. T.Dinero(info.subasta) .. " en la subasta", BIEN[1], BIEN[2], BIEN[3])
	end
	if r.aviso then tooltip:AddLine(r.aviso, 1, 0.5, 0.2, true) end

	-- 5) UNA acción, la que vale: lo que marcaste tú, o la sugerencia del Tasador
	local marca = id and type(_G.AsistenteDB) == "table" and _G.AsistenteDB.objetos and _G.AsistenteDB.objetos[id]
	local sug = ({ [T.ACCION.SUBASTA] = "subastar", [T.ACCION.REVISAR] = "subastar", [T.ACCION.VENDEDOR] = "vendedor",
		[T.ACCION.BOTAR] = "basura", [T.ACCION.GUARDAR] = "guardar" })[r.accion] or "guardar"
	local que = marca or sug
	if que == "vendedor" and (info.calidad or 1) == 0 then que = "basura" end
	local p = PS()
	local sola = p and p.Get and p.Get("qol.sellJunk")
	local texto = ACCION[que]
	if not marca and info.mejora then texto = "Equípalo (Guardar: es mejora para ti)" end
	if que == "subastar" and info.subasta then texto = "Subastar a " .. T.Dinero(info.subasta) end
	if que == "basura" and not sola then texto = "Es basura: véndela al vendedor" end
	local motivo = marca and "lo elegiste tú" or r.motivo
	tooltip:AddLine(hex(ORO) .. "Qué hacer:|r " .. texto .. (motivo and motivo ~= "" and ("  |cff9ba2b9(" .. motivo .. ")|r") or ""), TEXTO[1], TEXTO[2], TEXTO[3], true)
	tooltip:Show()
end

-- La línea propia de Polestar («Polestar  +12 % mejora · Cabeza») se apaga: su veredicto ya va en el bloque.
local apagar = CreateFrame("Frame")
apagar:RegisterEvent("PLAYER_LOGIN")
apagar:SetScript("OnEvent", function()
	local g = G()
	if g and g.TooltipLines and not T.lineasPolestar then
		T.lineasPolestar = g.TooltipLines
		g.TooltipLines = function() return {} end
	end
end)
