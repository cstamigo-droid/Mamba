-- Mamba_Combate: «estilo Gladius» para el mundo abierto y los campos de batalla (C4; Forever no tiene arenas).
--   1) Ficha del enemigo: al poner de objetivo a un JUGADOR enemigo, un recuadro con su clase y nivel, sus
--      controles y sus defensas (íconos), y qué tienes TÚ para responder (solo lo que sabes, con su tecla),
--      más un consejo corto.
--   2) Enfriamientos del enemigo (idea de OmniCD y BigDebuffs, código propio): cuando un jugador enemigo
--      visible (objetivo, foco o placa) termina de lanzar un hechizo importante, se anota cuándo vuelve a
--      tenerlo. En la ficha ese ícono se apaga con los segundos que le faltan, y en su placa sale arriba.
--      La lectura es UNIT_SPELLCAST_SUCCEEDED (Forever no da el registro de combate). Si el juego esconde el
--      hechizo o el GUID (valores secretos), no se anota: el diagnóstico lo cuenta en diag.gladius.
--   3) Aviso de defensas: «X usó Escudo divino». Los controles («X usó Aturdir») los avisa Avisos.lua (C4b).
-- Duraciones: las de Classic sin talentos (NO VERIFICADO que Forever no las cambie; un talento o un objeto
-- puede acortarlas). Solo MUESTRA: nada se lanza por el jugador. Licencia: GPL-3.0-only.
local _, M = ...
local G = {}
M.Gladius = G

-- Hechizo importante (id de rango 1) -> { segundos de enfriamiento, tipo }. Se reconocen por NOMBRE (cada rango
-- tiene otro id). tipo: "control" | "defensa" | "cortar" | "escape" | "daño".
G.CDS = {
	-- guerrero
	[100] = { 15, "escape" }, [20252] = { 30, "escape" }, [5246] = { 180, "control" }, [6552] = { 10, "cortar" },
	[72] = { 12, "cortar" }, [676] = { 60, "control" }, [871] = { 1800, "defensa" }, [20230] = { 1800, "defensa" },
	[1719] = { 1800, "daño" }, [18499] = { 30, "defensa" }, [12809] = { 45, "control" },
	-- paladín
	[853] = { 60, "control" }, [642] = { 300, "defensa" }, [1022] = { 300, "defensa" }, [1044] = { 20, "defensa" },
	[633] = { 3600, "defensa" }, [498] = { 300, "defensa" }, [20066] = { 60, "control" },
	-- cazador
	[1499] = { 15, "control" }, [19503] = { 30, "control" }, [19386] = { 120, "control" }, [19263] = { 300, "defensa" },
	[5384] = { 30, "defensa" }, [19577] = { 60, "control" }, [19574] = { 120, "daño" }, [781] = { 5, "amenaza" },
	[3045] = { 300, "daño" },
	-- pícaro
	[408] = { 20, "control" }, [1776] = { 10, "control" }, [2094] = { 300, "control" }, [1766] = { 10, "cortar" },
	[1856] = { 300, "escape" }, [5277] = { 300, "defensa" }, [2983] = { 300, "escape" }, [14177] = { 180, "daño" },
	[14185] = { 600, "daño" }, [13750] = { 300, "daño" },
	-- sacerdote
	[8122] = { 30, "control" }, [15487] = { 45, "cortar" }, [6346] = { 30, "defensa" }, [14751] = { 180, "daño" },
	[10060] = { 180, "daño" }, [13908] = { 600, "defensa" },
	-- mago
	[122] = { 25, "control" }, [2139] = { 30, "cortar" }, [1953] = { 15, "escape" }, [11958] = { 300, "defensa" },
	[12472] = { 600, "defensa" }, [11426] = { 30, "defensa" }, [12043] = { 180, "daño" }, [12042] = { 180, "daño" },
	[11129] = { 180, "daño" }, [12051] = { 480, "defensa" },
	-- brujo
	[5484] = { 40, "control" }, [6789] = { 120, "control" }, [19244] = { 24, "cortar" }, [17877] = { 15, "daño" },
	-- druida
	[5211] = { 60, "control" }, [22812] = { 60, "defensa" }, [17116] = { 180, "defensa" }, [29166] = { 360, "defensa" },
	[22842] = { 180, "defensa" }, [16979] = { 15, "escape" },
	-- chamán
	[8042] = { 6, "cortar" }, [8177] = { 15, "defensa" }, [16188] = { 180, "defensa" }, [16190] = { 300, "defensa" },
	-- razas
	[7744] = { 120, "defensa" }, [20549] = { 120, "control" }, [20589] = { 60, "escape" }, [20594] = { 180, "defensa" },
	[20580] = { 10, "escape" }, [20600] = { 180, "daño" }, [20572] = { 120, "daño" }, [20554] = { 180, "daño" },
}

-- Ficha por clase del enemigo. {id} se cambia por el nombre del hechizo en tu idioma.
G.CLASES = {
	WARRIOR = { estilo = "Cuerpo a cuerpo", controles = { 100, 5246, 676, 12809 }, defensas = { 871, 20230, 18499 },
		guarda = { "control", "escapar" },
		consejo = "Te persigue con {100} y te frena. Mantén la distancia: contrólalo y aléjate. Guarda una salida para {5246} (miedo)." },
	PALADIN = { estilo = "Cuerpo a cuerpo, se cura", controles = { 853, 20066 }, defensas = { 642, 1022, 1044, 498 },
		guarda = { "interrumpir", "control" },
		consejo = "Con {642} es inmune un rato: no gastes nada fuerte ahí. Corta sus curaciones; {853} te aturde 6 s." },
	HUNTER = { estilo = "A distancia, con mascota", controles = { 1499, 19503, 19386, 19577 }, defensas = { 19263, 5384 },
		guarda = { "escapar", "control" },
		consejo = "Pégate a él: de cerca no dispara. Cuidado con la trampa en el suelo ({1499}) y con {19503}." },
	ROGUE = { estilo = "Cuerpo a cuerpo, sale del sigilo", controles = { 408, 1776, 2094, 1766 }, defensas = { 5277, 1856, 2983 },
		guarda = { "escapar", "defensa" },
		consejo = "Abre desde el sigilo y te aturde. Guarda tu escape para cuando use {2094} o {408}. Tras {1856} no lo persigas a ciegas." },
	PRIEST = { estilo = "A distancia, se cura", controles = { 8122, 15487 }, defensas = { 6346, 13908 },
		guarda = { "interrumpir", "escapar" },
		consejo = "{8122} asusta a todos los de cerca: no te le pegues sin una salida del miedo. Corta sus curaciones largas." },
	MAGE = { estilo = "A distancia, congela y se aleja", controles = { 122, 2139, 118 }, defensas = { 11958, 1953, 11426 },
		guarda = { "interrumpir", "escapar" },
		consejo = "Te congela ({122}) y se aleja con {1953}. Guarda tu interrupción para {118}. Con {11958} espera: es inmune 10 s." },
	WARLOCK = { estilo = "A distancia, con demonio", controles = { 5782, 6789, 5484, 19244 }, defensas = {},
		guarda = { "interrumpir", "escapar" },
		consejo = "Guarda tu interrupción para {5782} (miedo). {6789} asusta al instante. Su demonio también corta y controla." },
	DRUID = { estilo = "Cambia de forma", controles = { 5211, 339, 2637 }, defensas = { 22812, 17116, 22842 },
		guarda = { "interrumpir", "control" },
		consejo = "Sale de raíces y lentitud cambiando de forma. Corta su curación ({5185}) y contrólalo cuando esté fuera de forma." },
	SHAMAN = { estilo = "Cerca o lejos, con tótems", controles = { 8042 }, defensas = { 8177, 16188 },
		guarda = { "interrumpir", "control" },
		consejo = "{8042} te corta el hechizo. {8177} se traga uno tuyo: rompe el tótem o espera 15 s." },
}

-- Lo tuyo para responder, por tu clase (ids de rango 1; solo se muestra lo que sabes).
G.MIOS = {
	DRUID = { interrumpir = { 5211 }, control = { 339, 2637 }, defensa = { 22812, 22842 }, escapar = { 783, 768 } },
	HUNTER = { interrumpir = { 19503 }, control = { 1499, 5116, 19386 }, defensa = { 19263, 5384 }, escapar = { 2974, 5116, 19503 } }, -- Desconexión no te mueve en Classic; el guepardo te aturde si te pegan
	WARRIOR = { interrumpir = { 6552, 72 }, control = { 5246, 1715, 12809 }, defensa = { 871, 20230 }, escapar = { 18499, 20252 } },
	ROGUE = { interrumpir = { 1766 }, control = { 408, 1833, 1776, 2094 }, defensa = { 5277 }, escapar = { 2983, 1856 } },
	MAGE = { interrumpir = { 2139 }, control = { 118, 122 }, defensa = { 11958, 11426, 1463 }, escapar = { 1953 } },
	PRIEST = { interrumpir = { 15487 }, control = { 8122 }, defensa = { 17, 13908 }, escapar = { 8122 } },
	WARLOCK = { interrumpir = { 19244 }, control = { 5782, 6789, 5484 }, defensa = { 6789 }, escapar = { 5782 } },
	PALADIN = { interrumpir = { 853 }, control = { 853, 20066 }, defensa = { 642, 498, 1022 }, escapar = { 1044 } },
	SHAMAN = { interrumpir = { 8042 }, control = { 2484, 8056 }, defensa = { 8177 }, escapar = { 2645 } },
}
G.NOMBRE_GUARDA = { interrumpir = "cortar", control = "controlar", defensa = "aguantar", escapar = "escapar" }

local function leer(v) if v == nil or M.Secreto(v) then return nil end return v end
local function ahora() return (GetTime and M.Num(GetTime())) or 0 end
local function diag()
	local d = M.DB().diag
	d.gladius = d.gladius or { anotados = 0, secretos = 0 }
	return d.gladius
end

---------------------------------------------------------------- enfriamientos usados
local porNombre
function G.Entrada(id)
	id = leer(id)
	if not id then return nil end
	if G.CDS[id] then return G.CDS[id], id end
	if not porNombre then
		porNombre = {}
		for i, x in pairs(G.CDS) do
			local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(i)
			if n then porNombre[n] = { x, i } end
		end
	end
	local n = C_Spell and C_Spell.GetSpellName and leer(C_Spell.GetSpellName(id))
	local e = n and porNombre[n]
	if e then return e[1], e[2] end
end

G.usados = {}       -- guid -> { [id base] = { fin, dur, icono, tipo } }
local cuantos = 0

function G.EsJugadorEnemigo(u)
	if not (UnitIsPlayer and UnitCanAttack) then return false end
	return leer(UnitIsPlayer(u)) == true and leer(UnitCanAttack("player", u)) == true
end

local function guidDe(u)
	if not UnitGUID then return nil end
	local ok, g = pcall(UnitGUID, u)
	if not ok then return nil end
	if M.Secreto(g) then diag().secretos = diag().secretos + 1; return nil end
	return g
end

-- Un jugador enemigo terminó un hechizo (UNIT_SPELLCAST_SUCCEEDED). -> true si se anotó.
function G.Lanzado(u, id)
	if M.Secreto(id) then diag().secretos = diag().secretos + 1; return false end
	local e, base = G.Entrada(id)
	if not e then return false end
	if not G.EsJugadorEnemigo(u) then return false end
	local guid = guidDe(u)
	if not guid then return false end
	local t = ahora()
	local x = G.usados[guid]
	if not x then
		cuantos = cuantos + 1
		if cuantos > 80 then G.Limpiar(t) end
		x = {}
		G.usados[guid] = x
	end
	-- el mismo lanzamiento llega por el objetivo, el foco y la placa: se avisa una sola vez
	local previo = x[base]
	local repetido = previo and math.abs(previo.fin - (t + e[1])) < 1.5
	x[base] = { fin = t + e[1], dur = e[1], icono = M.Icono(base), tipo = e[2], id = base }
	local dg = diag()
	dg.anotados = dg.anotados + 1
	dg.ultimo = M.NombreHechizo(base)
	if not repetido and e[2] == "defensa" and M.Avisos and M.Avisos.Mostrar and M.DB().avisoDefensas ~= false then
		local quien = UnitName(u)
		if M.Secreto(quien) or not quien then quien = "Un enemigo" end
		M.Avisos.Mostrar(("%s usó %s"):format(quien, M.NombreHechizo(base)), false)
	end
	G.Dibujar()
	return true
end

-- Se olvida lo vencido (para no juntar memoria en un campo de batalla largo).
function G.Limpiar(t)
	cuantos = 0
	for guid, x in pairs(G.usados) do
		local vivo = false
		for k, c in pairs(x) do if c.fin > t then vivo = true else x[k] = nil end end
		if vivo then cuantos = cuantos + 1 else G.usados[guid] = nil end
	end
end

-- Lo que un jugador tiene en enfriamiento ahora: { { id, icono, resta, tipo } }, el más importante primero.
local ORDEN_TIPO = { defensa = 1, control = 2, cortar = 3, escape = 4, ["daño"] = 5 }
function G.ActivosDe(u)
	if not u or not G.EsJugadorEnemigo(u) then return {} end
	local guid = guidDe(u)
	local x = guid and G.usados[guid]
	if not x then return {} end
	local t, out = ahora(), {}
	for _, c in pairs(x) do
		if c.fin > t then out[#out + 1] = { id = c.id, icono = c.icono, resta = c.fin - t, tipo = c.tipo } end
	end
	table.sort(out, function(a, b)
		local oa, ob = ORDEN_TIPO[a.tipo] or 9, ORDEN_TIPO[b.tipo] or 9
		if oa ~= ob then return oa < ob end
		return a.resta < b.resta
	end)
	return out
end

-- Segundos que le faltan a ese jugador para volver a tener ese hechizo (nil si lo tiene).
function G.Resta(u, id)
	local guid = guidDe(u)
	local x = guid and G.usados[guid]
	local c = x and x[id]
	if not c then return nil end
	local r = c.fin - ahora()
	return r > 0 and r or nil
end

---------------------------------------------------------------- la ficha
local ficha
local function fila(padre, y, etiqueta, n)
	local r = { iconos = {} }
	r.et = M.Piezas.Texto(padre, "small", "textDim")
	r.et:SetPoint("TOPLEFT", padre, "TOPLEFT", 8, y)
	r.et:SetText(etiqueta)
	for i = 1, n do
		local f = CreateFrame("Frame", nil, padre)
		f:SetSize(20, 20)
		f:SetPoint("TOPLEFT", padre, "TOPLEFT", 78 + (i - 1) * 23, y + 3)
		f.icono = f:CreateTexture(nil, "ARTWORK")
		f.icono:SetAllPoints(f)
		f.velo = f:CreateTexture(nil, "OVERLAY")
		f.velo:SetAllPoints(f)
		f.velo:SetColorTexture(0, 0, 0, 0.6)
		f.velo:Hide()
		f.t = M.Piezas.Texto(f, "small", "text")
		f.t:SetPoint("CENTER", f, "CENTER", 0, 0)
		f:Hide()
		r.iconos[i] = f
	end
	return r
end

function G.CrearFicha()
	if ficha then return end
	ficha = CreateFrame("Frame", "MambaFicha", UIParent)
	ficha:SetSize(240, 150)
	ficha:SetPoint("TOPLEFT", UIParent, "CENTER", 220, 120)
	ficha:Hide()
	M.Movible(ficha, "MambaFicha", "Ficha del enemigo")
	ficha.fondo = ficha:CreateTexture(nil, "BACKGROUND")
	ficha.fondo:SetAllPoints(ficha)
	ficha.fondo:SetColorTexture(0.05, 0.05, 0.06, 0.85)
	ficha.nombre = M.Piezas.Texto(ficha, "heading", "text")
	ficha.nombre:SetPoint("TOPLEFT", ficha, "TOPLEFT", 8, -6)
	ficha.nombre:SetPoint("RIGHT", ficha, "RIGHT", -8, 0)
	ficha.estilo = M.Piezas.Texto(ficha, "small", "textDim")
	ficha.estilo:SetPoint("TOPLEFT", ficha.nombre, "BOTTOMLEFT", 0, -2)
	ficha.controles = fila(ficha, -42, "Controla", 6)
	ficha.defensas = fila(ficha, -66, "Defensas", 6)
	ficha.guarda = fila(ficha, -90, "Tú guarda", 6)
	ficha.consejo = M.Piezas.Texto(ficha, "small", "text")
	ficha.consejo:SetPoint("TOPLEFT", ficha, "TOPLEFT", 8, -114)
	ficha.consejo:SetWidth(224)
	if ficha.consejo.SetWordWrap then ficha.consejo:SetWordWrap(true) end
end
M.Precrear(function() G.CrearFicha() end)
M.AlModoMover(function(activo)
	G.CrearFicha()
	if activo then
		if not ficha:IsShown() then
			ficha.ejemplo = true
			ficha.nombre:SetText("Ficha del enemigo (ejemplo)")
			ficha.estilo:SetText("")
			ficha.consejo:SetText("")
			ficha:Show()
		end
	elseif ficha.ejemplo then
		ficha.ejemplo = nil
		ficha:Hide()
		G.Dibujar()
	end
end)

local function llenar(r, ids, unidad, mios)
	local n = 0
	for _, id in ipairs(ids or {}) do
		if n >= #r.iconos then break end
		if not mios or M.Conoce(id) then
			n = n + 1
			local f = r.iconos[n]
			f.icono:SetTexture(M.Icono(id))
			f.id = id
			local resta
			if mios then
				local R = M.Rotacion
				local listo, _, falta = R and R.Listo(id)
				resta = (listo == false) and falta or nil
				local tecla = R and R.Tecla(id)
				f.t:SetText(resta and tostring(math.ceil(resta)) or (tecla or ""))
			else
				resta = G.Resta(unidad, id)
				f.t:SetText(resta and tostring(math.ceil(resta)) or "")
			end
			if resta then f.velo:Show() else f.velo:Hide() end
			f:Show()
		end
	end
	for i = n + 1, #r.iconos do r.iconos[i]:Hide() end
	return n
end

-- Lo tuyo para responder a esa clase (en el orden de sus categorías, sin repetir).
function G.Guarda(token)
	local c = G.CLASES[token]
	local mios = G.MIOS[M.Clase()] or {}
	local out, visto = {}, {}
	for _, cat in ipairs(c and c.guarda or {}) do
		for _, id in ipairs(mios[cat] or {}) do
			if not visto[id] and M.Conoce(id) then visto[id] = true; out[#out + 1] = id end
		end
	end
	return out
end

-- Datos de la ficha del objetivo (o nil si no es un jugador enemigo, o si el juego esconde su clase).
function G.Ficha(u)
	u = u or "target"
	if not (UnitExists and UnitExists(u)) or not G.EsJugadorEnemigo(u) then return nil end
	local nombreClase, token = UnitClass(u)
	token = leer(token)
	local c = token and G.CLASES[token]
	if not c then return nil end
	return { token = token, clase = leer(nombreClase) or token, datos = c, nivel = UnitLevel and M.Num(UnitLevel(u)),
		nombre = UnitName(u), guarda = G.Guarda(token) }
end

function G.Dibujar()
	if ficha and ficha.ejemplo then return end
	if not M.DB().ficha then if ficha then ficha:Hide() end return end
	local x = G.Ficha("target")
	if not x then if ficha then ficha:Hide() end return end
	G.CrearFicha()
	local col = RAID_CLASS_COLORS and RAID_CLASS_COLORS[x.token]
	local hex = col and col.colorStr
	-- nombre en el color de su clase (dato del juego); si el juego lo esconde, tal cual y sin color
	if M.Secreto(x.nombre) then ficha.nombre:SetText(x.nombre)
	elseif type(hex) == "string" and #hex == 8 then ficha.nombre:SetText("|c" .. hex .. (x.nombre or "") .. "|r")
	else ficha.nombre:SetText(x.nombre or "") end
	ficha.estilo:SetText(((x.nivel and x.nivel > 0) and ("nivel " .. x.nivel .. " · ") or (x.nivel == -1 and "nivel ?? · " or ""))
		.. x.clase .. " · " .. x.datos.estilo)
	ficha.hex = hex
	llenar(ficha.controles, x.datos.controles, "target")
	llenar(ficha.defensas, x.datos.defensas, "target")
	local n = llenar(ficha.guarda, x.guarda, "target", true)
	if n == 0 then ficha.guarda.et:SetText("Tú guarda: —") else ficha.guarda.et:SetText("Tú guarda") end
	ficha.consejo:SetText(M.Texto(x.datos.consejo))
	ficha:Show()
end
function G.FichaMarco() return ficha end

local f = CreateFrame("Frame")
M.Escuchar(f, "UNIT_SPELLCAST_SUCCEEDED")
M.Escuchar(f, "PLAYER_TARGET_CHANGED")
M.Escuchar(f, "UNIT_FACTION")
f:SetScript("OnEvent", function(_, e, u, _, id)
	if e == "UNIT_SPELLCAST_SUCCEEDED" then
		if type(u) == "string" and (u == "target" or u == "focus" or u:find("^nameplate")) then M.Proteger("gladius", G.Lanzado, u, id) end
	else M.Proteger("ficha", G.Dibujar) end
end)
local acum = 0
f:SetScript("OnUpdate", function(_, dt)
	acum = acum + (dt or 0)
	if acum < 0.5 then return end
	acum = 0
	if ficha and ficha:IsShown() and not ficha.ejemplo then M.Proteger("ficha", G.Dibujar) end
end)
M.AlCambiar(function() M.Proteger("ficha", G.Dibujar) end)
