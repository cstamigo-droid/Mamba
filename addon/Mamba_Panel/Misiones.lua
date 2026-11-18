-- Mamba_Panel/Misiones.lua: Calabozos › Misiones con el ESTADO REAL y lo que falta (K100). Cristian: "tiene que
-- mostrar si ya está realizada o lo que le falte por hacer y guiar si se necesita".
-- Polestar ya marca cada misión (Hecha, Lista para entregar, En tu registro, Desde el nivel N) y numera la cadena.
-- Mamba agrega, sobre su misma tarjeta (parche P13 en UI/Dungeons.lua, que llama a Polestar.UI.MambaMision):
--   * en la línea de datos: "Falta: Herodes 0/1 · Escudo 0/1" (los objetivos que faltan del registro), o "Falta
--     tomarla: <quién>", o "Lista: entrégala a <quién>";
--   * en cada paso de la cadena: "hecha", "en el registro" o "falta";
--   * un botón «Guíame» al paso pendiente: el primer requisito que falta (Polestar ya lo calcula), la entrada de
--     la mazmorra si lo que falta está adentro, o quien la recibe si está lista. Usa el motor de «Ir a…»
--     (MambaAPI.Llevame, K58) y si no está, la flecha de Polestar.
-- Licencia: GPL-3.0-only.
local _, N = ...
local DOT = "  ·  "
local floor, max, min, format, concat = math.floor, math.max, math.min, string.format, table.concat

local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end

-- Los objetivos del registro que faltan: { "Herodes 0/1", ... }
function N.ObjetivosQueFaltan(questID)
	local P = PS()
	local C = P and P.Compat
	if not (C and C.GetQuestObjectives) then return {} end
	local ok, objs = pcall(C.GetQuestObjectives, questID)
	if not ok or type(objs) ~= "table" then return {} end
	local out = {}
	for _, o in ipairs(objs) do
		if not o.finished then
			local nombre = C.ObjectiveLabel and C.ObjectiveLabel(o.text) or o.text
			if not nombre or nombre == "" then nombre = o.text ~= "" and o.text or "objetivo" end
			out[#out + 1] = (o.numRequired or 1) > 1 and format("%s %d/%d", nombre, o.numFulfilled or 0, o.numRequired) or nombre
		end
	end
	return out
end

-- El estado de una misión en palabras de Mamba.
function N.EstadoMision(questID)
	local P = PS()
	local C = P and P.Compat
	if not (C and questID) then return "falta" end
	if C.IsQuestCompleted and C.IsQuestCompleted(questID) then return "hecha" end
	if C.IsOnQuest and C.IsOnQuest(questID) then
		if C.IsQuestReadyForTurnIn and C.IsQuestReadyForTurnIn(questID) then return "lista" end
		return "en el registro"
	end
	return "falta"
end

local function nombrePunto(p, label)
	if label and label ~= "" then return label end
	return type(p) == "table" and p.name or nil
end

local function valido(p) return type(p) == "table" and p.map and p.x and p.y and true or false end

-- «Guíame»: a un punto de Polestar ({ map, x, y } en %), con el motor de Ir a… o la flecha.
function N.Guiame(p, nombre, key)
	local A = _G.MambaAPI
	if valido(p) and A and A.Llevame then
		local ok, hecho = pcall(A.Llevame, { map = p.map, x = p.x, y = p.y, nombre = nombre })
		if ok and hecho then return true end
	end
	local P = PS()
	local D = P and P.Dungeons
	if valido(p) and D and D.GuideToPoint then
		local ok, hecho = pcall(D.GuideToPoint, p, nombre)
		if ok and hecho then return true end
	end
	if key and D and D.GuideTo then
		local ok, hecho = pcall(D.GuideTo, key)
		return ok and hecho or false
	end
	return false
end

-- A dónde lleva «Guíame» y qué dice la línea de datos. -> punto, nombre, texto, conKey
local function pendiente(q, key, state, target, tlabel, fin)
	local P = PS()
	local D = P and P.Dungeons
	if state == "done" or state == "class" or state == "race" then return nil end
	if state == "ready" then
		local quien = nombrePunto(fin)
		return fin, quien, quien and format("Lista: entrégala a %s", quien) or "Lista para entregar", nil
	end
	if state == "log" then
		local falta = N.ObjetivosQueFaltan(q.id)
		local texto = #falta > 0 and ("Falta: " .. concat(falta, DOT)) or "En tu registro"
		-- lo que falta suele estar adentro: la entrada de la mazmorra
		local d = D and D.Get and key and D.Get(key)
		if d and d.entrance then return d.entrance, d.name, texto, key end
		return nil, nil, texto, key
	end
	-- "open" o "low": tomarla (o el primer requisito que falta, que Polestar ya puso en target)
	local quien = nombrePunto(target, tlabel)
	return target, quien, quien and format("Falta tomarla: %s", quien) or "Falta tomarla", nil
end

local function boton(b)
	local ya = rawget(b, "MambaGuiame")
	if ya then return ya end
	local P = PS()
	local W, Theme = P.Widgets, P.Theme
	local g = CreateFrame("Button", nil, b)
	g:SetSize(64, 18)
	g.Label = W.Text(g, "small", "accent")
	g.Label:SetPoint("RIGHT", g, "RIGHT", 0, 0)
	g.Label:SetText("Guíame")
	g:SetScript("OnClick", function(self) N.Guiame(self.psPunto, self.psNombre, self.psKey) end)
	g:SetScript("OnEnter", function(self)
		W.Color(self.Label, "text")
		local lineas = { { self.psNombre and ("A " .. self.psNombre) or "Al paso que falta", Theme.Color("textDim") } }
		if self.psFalta then lineas[#lineas + 1] = { self.psFalta, Theme.Color("textMuted") } end
		W.Tooltip(self, "ANCHOR_LEFT", "Guíame", lineas)
	end)
	g:SetScript("OnLeave", function(self) W.Color(self.Label, "accent"); W.HideTooltip(self) end)
	b.MambaGuiame = g
	return g
end

local ESTADO_CADENA = { hecha = "hecha", lista = "lista para entregar", ["en el registro"] = "en el registro", falta = "falta" }

-- El gancho (parche P13): Polestar acaba de pintar la tarjeta `b` de la misión `q`.
local function mision(b, q, key, state, target, tlabel, fin)
	local P = PS()
	if not (P and P.Widgets and b and q) then return end
	local punto, nombre, texto, conKey = pendiente(q, key, state, target, tlabel, fin)
	-- la línea de datos
	if texto and b.Meta then
		-- en la misma línea de datos, sin crecer: Polestar ya midió la tarjeta (lo completo, en el cuadro de «Guíame»)
		local antes = b.Meta:GetText() or ""
		if b.Meta.SetWordWrap then b.Meta:SetWordWrap(false) end
		if b.Meta.SetMaxLines then b.Meta:SetMaxLines(1) end
		b.Meta:SetText(antes ~= "" and (antes .. DOT .. texto) or texto)
	end
	-- «Guíame»
	local g = boton(b)
	local puede = valido(punto) or conKey ~= nil
	if puede and state ~= "done" then
		g.psPunto, g.psNombre, g.psKey, g.psFalta = punto, nombre, conKey, texto
		g:ClearAllPoints()
		-- a la altura de la línea de datos (-44), debajo de las marcas de estado de Polestar (línea del título)
		g:SetPoint("TOPRIGHT", b, "TOPRIGHT", -14, -44)
		g:Show()
		if b.Meta then b.Meta:SetWidth(max(80, b:GetWidth() - 28 - 76)) end
	else
		g:Hide()
	end
	-- cada paso de la cadena con su estado
	for _, r in ipairs(b.Chains or {}) do
		local cq = r:IsShown() and r.psQuest
		if cq and cq.id and r.Sub then
			local e = N.EstadoMision(cq.id)
			local t = ESTADO_CADENA[e] or e
			if e == "en el registro" then
				local falta = N.ObjetivosQueFaltan(cq.id)
				if #falta > 0 then t = t .. " (falta " .. falta[1] .. ")" end
			end
			local antes = r.Sub:GetText() or ""
			r.Sub:SetText(antes ~= "" and (antes .. DOT .. t) or t)
			local room = (r:GetWidth() or 300) - 24 - 30 - (r.Title:GetWidth() or 0) - 10
			r.Sub:SetWidth(max(40, min(floor(r.Sub:GetStringWidth() + 1), room)))
		end
	end
end
N.PintarMision = mision

local P = PS()
if P and P.UI then P.UI.MambaMision = mision end
