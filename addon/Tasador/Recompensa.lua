-- Tasador/Recompensa.lua (K101, pedido de Cristian, 18-11): al entregar una misión con recompensa a elegir, en la
-- ventana del PNJ se resalta LA que más le conviene y se dice por qué, en una línea. NO elige por el jugador: el
-- clic es suyo (la elección automática de Polestar, qol.rewardAutoPick, sigue apagada salvo que él la encienda).
--   1. Si alguna mejora su equipo para sus builds de «Mi plan» (K59): la de mayor mejora, con los mismos números
--      del cuadro del objeto (E8, T.MejorasDeBuilds de Cuadro.lua).
--   2. Si ninguna mejora: la que más vale, en la subasta (precio del Tasador, menos la comisión) o con el vendedor.
-- El resaltado es el marco de «la mejor» de Polestar (QoL/Rewards.lua): Mamba solo le dice cuál es, cambiando su
-- orden (Rewards.Rank). La línea del motivo va en una franja pegada bajo la ventana de la misión, solo cuando
-- Polestar dibujó ese marco.
-- DECIDIDO (revisor t5, MEDIA): si el jugador enciende la elección automática de Polestar (qol.rewardAutoPick,
-- apagada por defecto), toma la que dice Mamba, la misma del marco. Que la toma automática y el marco digan dos cosas
-- distintas sería peor, y la R0 pide la de mayor mejora. Mamba no toma nada: la toma la opción que encendió el
-- jugador (Shift la detiene). Lo prueba test_recompensa («elección automática»).
-- Licencia: GPL-3.0-only.
local _, T = ...

local SAME = 0.5 -- % por debajo del cual «es igual que lo tuyo» (el mismo umbral del cuadro)

-- Ranura del juego -> cómo se nombra en la frase: { "tu cuello", "cuello" }
local RANURA = {
	[1] = { "tu cabeza", "cabeza" }, [2] = { "tu cuello", "cuello" }, [3] = { "tus hombros", "hombros" },
	[5] = { "tu pecho", "pecho" }, [6] = { "tu cintura", "cintura" }, [7] = { "tus piernas", "piernas" },
	[8] = { "tus pies", "pies" }, [9] = { "tus muñecas", "muñecas" }, [10] = { "tus manos", "manos" },
	[11] = { "tu anillo", "anillo" }, [12] = { "tu anillo", "anillo" }, [13] = { "tu abalorio", "abalorio" },
	[14] = { "tu abalorio", "abalorio" }, [15] = { "tu capa", "capa" }, [16] = { "tu arma", "arma" },
	[17] = { "tu mano izquierda", "mano izquierda" }, [18] = { "tu reliquia o arma a distancia", "reliquia" },
}
T.RANURA_FRASE = RANURA

local function cuanto(pct)
	-- sobre +200 % el porcentaje se lee raro: «5,4 veces» (la misma regla del Equipo, K61)
	if pct >= 200 then return (string.format("%.1f", 1 + pct / 100):gsub("%.0$", ""):gsub("%.", ",")) .. " veces" end
	return string.format("+%d %%", math.floor(pct + 0.5))
end

-- La mejor mejora de una opción: { nombre, pct, vacia, ranura } con vacia primero y después el mayor %.
local function mejorDe(o)
	local mejor
	for _, m in ipairs(o.mejoras or {}) do
		if not m.despues and (m.vacia or (m.pct and m.pct >= SAME)) then
			local v = m.vacia and math.huge or m.pct
			if not mejor or v > mejor.v then mejor = { v = v, m = m } end
		end
	end
	return mejor
end

-- Lo que vale una opción para el jugador: el mayor entre la subasta (neto de comisión) y el vendedor, por la pila.
local function valorDe(o, comision)
	local n = (o.cantidad and o.cantidad > 0) and o.cantidad or 1
	local sub = o.subasta and o.subasta > 0 and math.floor(o.subasta * (1 - (comision or 0))) * n or nil
	local ven = (o.vendedor or 0) * n
	if sub and sub >= ven then return sub, "en la subasta" end
	if ven > 0 then return ven, "con el vendedor" end
	return 0, nil
end
T.ValorRecompensa = valorDe

-- Lógica pura (sin el juego). opciones[i] = { index, nombre, cantidad, subasta (cobre por unidad o nil),
-- vendedor (cobre por unidad), mejoras = T.MejorasDeBuilds(link) }.
-- -> { index, tipo = "mejora" | "valor" | "nada", texto } (index nil con "nada").
function T.ElegirRecompensa(opciones, comision)
	if type(opciones) ~= "table" or #opciones == 0 then return nil end
	-- 1) mejora
	local gana, segunda
	for _, o in ipairs(opciones) do
		local m = mejorDe(o)
		if m then
			local val = valorDe(o, comision)
			if not gana or m.v > gana.m.v or (m.v == gana.m.v and val > gana.val) then
				segunda = gana
				gana = { o = o, m = m, val = val }
			elseif not segunda or m.v > segunda.m.v then
				segunda = { o = o, m = m, val = val }
			end
		end
	end
	if gana then
		local m = gana.m.m
		local r = RANURA[m.ranura] or { "tu equipo", "equipo" }
		local para = m.nombre and (" para " .. m.nombre) or ""
		local texto
		if m.vacia then
			texto = "Llena tu ranura vacía de " .. r[2] .. para
		else
			texto = "Mejora " .. r[1] .. " " .. cuanto(m.pct) .. para
		end
		-- la otra build, si también mejora con esta misma pieza
		for _, x in ipairs(gana.o.mejoras or {}) do
			if x ~= m and x.nombre and not x.despues and x.pct and x.pct >= SAME then
				texto = texto .. " y " .. cuanto(x.pct) .. " para " .. x.nombre
				break
			end
		end
		-- R0: la ganadora con su número y la que sigue
		if segunda and segunda.m.v ~= math.huge and not segunda.m.m.vacia then
			texto = texto .. "; la siguiente, " .. cuanto(segunda.m.m.pct)
		end
		return { index = gana.o.index, tipo = "mejora", texto = texto }
	end
	-- 2) la que más vale
	local mejor, sinSubasta = nil, 0
	for _, o in ipairs(opciones) do
		local v, donde = valorDe(o, comision)
		if not o.subasta then sinSubasta = sinSubasta + 1 end
		if donde and (not mejor or v > mejor.v) then mejor = { o = o, v = v, donde = donde } end
	end
	if not mejor then
		return { tipo = "nada", texto = "Ninguna te mejora ni tiene precio: elige la que más te guste" }
	end
	local texto = "Ninguna te mejora: esta vale " .. T.Dinero(mejor.v) .. " " .. mejor.donde
	if sinSubasta > 0 then
		texto = texto .. (sinSubasta == 1 and " (1 sin precio de subasta aún)" or (" (" .. sinSubasta .. " sin precio de subasta aún)"))
	end
	return { index = mejor.o.index, tipo = "valor", texto = texto }
end

---------------------------------------------------------------- el juego
local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end

-- Las opciones que Polestar ya leyó (Rewards.ReadChoices: index, link, itemID, count) con lo de Mamba.
local function opcionesDe(choices)
	local out = {}
	for i, c in ipairs(choices or {}) do
		local link = c.link or (c.itemID and ("item:" .. c.itemID)) or nil
		local o = { index = c.index or i, cantidad = c.count or 1, mejoras = {} }
		if link then
			local okI, info = pcall(T.InfoDe, link)
			if okI and info then
				o.nombre, o.subasta, o.vendedor = info.nombre, info.subasta, info.vendedor
			end
			local okM, m = pcall(T.MejorasDeBuilds, link)
			if okM and type(m) == "table" then o.mejoras = m end
		end
		out[#out + 1] = o
	end
	return out
end

function T.RecompensaDe(choices)
	local a = T.Ajustes and T.Ajustes() or {}
	return T.ElegirRecompensa(opcionesDe(choices), a.comision or 0.05)
end

-- La franja del motivo, pegada bajo la ventana de la misión, con la estética de Polestar (marca oliva de Mamba).
local OLIVA = { 0.55, 0.62, 0.42 }
local franja

local function crearFranja()
	if franja then return franja end
	local p = PS()
	local W, Th = p and p.Widgets, p and p.Theme
	local padre = _G.QuestFrame
	if not (padre and W and W.Text) then return nil end
	local f = CreateFrame("Frame", nil, padre)
	f:SetHeight(26)
	f:SetPoint("TOPLEFT", padre, "BOTTOMLEFT", 0, -2)
	f:SetPoint("TOPRIGHT", padre, "BOTTOMRIGHT", 0, -2)
	f:SetFrameLevel((padre:GetFrameLevel() or 1) + 5)
	if W.Fill then f.Fondo = W.Fill(f, "panel") end
	f.Marca = f:CreateTexture(nil, "ARTWORK")
	f.Marca:SetTexture(Th and Th.Media and Th.Media("white") or nil)
	f.Marca:SetVertexColor(OLIVA[1], OLIVA[2], OLIVA[3], 1)
	f.Marca:SetSize(2, 14)
	f.Marca:SetPoint("LEFT", f, "LEFT", 8, 0)
	f.Texto = W.Text(f, "small", "text")
	f.Texto:SetPoint("LEFT", f.Marca, "RIGHT", 6, 0)
	f.Texto:SetPoint("RIGHT", f, "RIGHT", -8, 0)
	f.Texto:SetJustifyH("LEFT")
	if f.Texto.SetWordWrap then f.Texto:SetWordWrap(true) end
	f:Hide()
	franja = f
	return f
end

function T.MostrarFranjaRecompensa(res, nombre)
	local f = crearFranja()
	if not f then return end
	if not (res and res.texto) then f:Hide() return end
	local cab = "|cffe6ba66Mamba:|r "
	if nombre and res.index then cab = cab .. "|cffffffff" .. tostring(nombre) .. "|r · " end
	f.Texto:SetText(cab .. res.texto)
	local alto = f.Texto.GetStringHeight and f.Texto:GetStringHeight() or 0
	f:SetHeight(math.max(26, (type(alto) == "number" and alto or 0) + 12))
	f:Show()
end

function T.OcultarFranjaRecompensa()
	if franja then franja:Hide() end
end

-- El enganche con Polestar: su orden (el marco de «la mejor» va a la de Mamba) y, tras sus marcas, la franja.
local enganchado = false
function T.EngancharRecompensas()
	local p = PS()
	local R = p and p.QoL and p.QoL.Rewards
	if enganchado or not (R and R.Rank and R.Mark and R.ReadChoices) then return enganchado end
	enganchado = true
	local rankPolestar, markPolestar = R.Rank, R.Mark
	R.Rank = function(choices)
		local order, reason = rankPolestar(choices)
		local ok, res = pcall(T.RecompensaDe, choices)
		if not (ok and res and res.index) then return order, reason end
		local nuevo = { res.index }
		for _, i in ipairs(order) do
			if i ~= res.index then nuevo[#nuevo + 1] = i end
		end
		return nuevo, res.tipo == "mejora" and "upgrade" or "value"
	end
	R.Mark = function(...)
		local marcado = markPolestar(...)
		local enLog = _G.QuestInfoFrame and _G.QuestInfoFrame.questLog
		local panel = _G.QuestFrameRewardPanel
		local oculto = p.Hidden and p.Hidden()
		if enLog or oculto or not (panel and panel.IsShown and panel:IsShown()) then
			T.OcultarFranjaRecompensa()
			return marcado
		end
		-- revisor t5 (BAJA): la franja explica el marco; sin marco de Polestar (resaltado apagado, datos del objeto
		-- aún sin cargar) no hay nada que explicar y no sale
		local okC, choices = pcall(R.ReadChoices, false)
		if marcado ~= true or not (okC and type(choices) == "table") or #choices < 2 then
			T.OcultarFranjaRecompensa()
			return marcado
		end
		local ok, res = pcall(T.RecompensaDe, choices)
		local nombre
		if ok and res and res.index and choices[res.index] then
			local okI, info = pcall(T.InfoDe, choices[res.index].link or ("item:" .. tostring(choices[res.index].itemID)))
			nombre = okI and info and info.nombre or nil
		end
		T.MostrarFranjaRecompensa(ok and res and res.index and res or nil, nombre)
		return marcado
	end
	return true
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("QUEST_FINISHED")
ev:SetScript("OnEvent", function(_, e)
	if e == "PLAYER_LOGIN" then T.EngancharRecompensas()
	else T.OcultarFranjaRecompensa() end
end)
