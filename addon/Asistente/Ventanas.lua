-- Asistente/Ventanas.lua: TODAS las ventanas de Mamba se mueven a donde uno quiera (Cristian, 18-11: "las
-- ventanas por favor tienen que poder moverse para donde uno quiera").
--   * se arrastran por su barra de título (o por donde diga cada una);
--   * guardan su lugar POR PERSONAJE (AsistenteDB.lugares["Nombre-Reino"][ventana]) y lo reponen al entrar;
--   * nunca salen de la pantalla (SetClampedToScreen);
--   * un candado las fija (Ajustes › Mamba › Ventanas: "Fijar las ventanas");
--   * "Restablecer posiciones" las devuelve a su lugar de siempre.
-- La ventana de Mamba (el hub de Polestar, PolestarPicker) entra sola. Las de otros módulos (mochila, banco,
-- asistente de inicio, barras, paneles) se suman con MambaAPI.Movible(marco, nombre, asa).
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local V = { marcos = {} }
A.Ventanas = V

local function pj()
	local n = UnitName and UnitName("player") or "?"
	n = n or "?"
	local r = GetRealmName and GetRealmName() or ""
	return n .. "-" .. r
end

V.Personaje = function() return pj() end

local function db()
	A.PrepararDB()
	AsistenteDB.lugares = AsistenteDB.lugares or {}
	local k = pj()
	AsistenteDB.lugares[k] = AsistenteDB.lugares[k] or {}
	return AsistenteDB.lugares[k]
end

function V.Fijas() return AsistenteDB and AsistenteDB.ventanasFijas == true or false end
-- En combate no se mueve nada: un marco que ancla marcos seguros (Curación) queda protegido y SetPoint se bloquea.
local function enCombate() return InCombatLockdown and InCombatLockdown() or false end
local function noSeMueve() return V.Fijas() or enCombate() end
function V.Fijar(si) A.PrepararDB(); AsistenteDB.ventanasFijas = si and true or false end

local function guardar(nombre, f)
	if not (f and f.GetLeft and f:GetLeft()) then return end
	local P = _G.Polestar
	local x, y
	if P and P.PointOffsets then x, y = P.PointOffsets(f, "CENTER") else
		x = f:GetLeft() + f:GetWidth() / 2 - UIParent:GetWidth() / 2
		y = f:GetBottom() + f:GetHeight() / 2 - UIParent:GetHeight() / 2
	end
	local viejo = db()[nombre]
	db()[nombre] = { x = math.floor(x + 0.5), y = math.floor(y + 0.5), escala = viejo and viejo.escala or nil }
end

local function reponer(nombre, f)
	local l = db()[nombre]
	if not l then return false end
	if l.escala and f.SetScale then f:SetScale(l.escala) end
	if not (l.x and l.y) then return false end -- solo el tamaño guardado
	f:ClearAllPoints()
	f:SetPoint("CENTER", UIParent, "CENTER", l.x, l.y)
	return true
end

-- marco: la ventana; nombre: único y estable; asa: de dónde se arrastra (nil: la ventana entera).
-- opciones.yaArrastra = true cuando la ventana ya se arrastra sola (Polestar): solo se guarda y repone.
-- También vale V.Movible(marco, nombre, opciones). opciones.etiqueta: el nombre que se ve en el modo Mover;
-- opciones.sinAsa = true: un marco que no es ventana (sin título): solo se mueve en el modo «Mover elementos».
function V.Movible(marco, nombre, asa, opciones)
	if not (marco and nombre) then return false end
	if type(asa) == "table" and not asa.GetObjectType then asa, opciones = nil, asa end
	opciones = opciones or {}
	marco:SetClampedToScreen(true)
	marco:SetMovable(true)
	local reg = { marco = marco, nombre = nombre, original = nil, etiqueta = opciones.etiqueta or opciones.titulo or nombre } -- titulo: sinónimo de etiqueta
	if marco.GetNumPoints and (marco:GetNumPoints() or 0) > 0 and marco:GetPoint(1) then reg.original = { marco:GetPoint(1) } end
	V.marcos[nombre] = reg
	if not opciones.yaArrastra and not opciones.sinAsa then
		asa = asa or marco
		local P = _G.Polestar
		if P and P.DragWindow then
			P.DragWindow(asa, marco, { locked = noSeMueve, onStop = function(f) guardar(nombre, f) end })
		else
			asa:EnableMouse(true)
			asa:RegisterForDrag("LeftButton")
			asa:SetScript("OnDragStart", function() if not noSeMueve() then marco:StartMoving() end end)
			asa:SetScript("OnDragStop", function() marco:StopMovingOrSizing(); guardar(nombre, marco) end)
		end
	end
	marco:HookScript("OnShow", function(f) reponer(nombre, f) end)
	if opciones.yaArrastra or opciones.sinAsa then marco:HookScript("OnHide", function(f) guardar(nombre, f) end) end
	if marco:IsShown() then reponer(nombre, marco) end
	return true
end

-- Vuelve a poner cada ventana en su lugar de siempre y borra lo guardado de este personaje.
function V.Restablecer()
	if enCombate() then
		-- se hace solo al salir del combate
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_REGEN_ENABLED")
		f:SetScript("OnEvent", function(self) self:UnregisterAllEvents(); V.Restablecer() end)
		return
	end
	A.PrepararDB()
	if AsistenteDB.lugares then AsistenteDB.lugares[pj()] = {} end
	if AsistenteDB.ventanas then AsistenteDB.ventanas = {} end -- los lugares viejos de A.CrearVentana
	for _, r in pairs(V.marcos) do
		local f = r.marco
		if f.SetScale then f:SetScale(1) end
		f:ClearAllPoints()
		if r.original then f:SetPoint(unpack(r.original)) else f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
	end
	for _, fn in ipairs(V.alRestablecer or {}) do pcall(fn) end
end

-- Otros módulos que guardan sus lugares por su cuenta (barras) se enteran del "Restablecer" aquí.
function V.AlRestablecer(fn) V.alRestablecer = V.alRestablecer or {}; table.insert(V.alRestablecer, fn) end

---------------------------------------------------------------- modo «Mover elementos» (como el modo de edición)
-- Cada elemento registrado se muestra con un borde y su nombre: se arrastra, la rueda cambia su tamaño
-- (de 0,5 a 2) y todo queda guardado por personaje. En combate no se entra, y si empieza un combate se sale solo.
V.moviendo = false
local capas = {}

local function capa(r)
	local c = capas[r.nombre]
	if c then return c end
	c = CreateFrame("Frame", nil, UIParent)
	c:SetFrameStrata("DIALOG")
	c:EnableMouse(true)
	c:EnableMouseWheel(true)
	c.fondo = c:CreateTexture(nil, "BACKGROUND")
	c.fondo:SetAllPoints(c)
	c.fondo:SetColorTexture(0.42, 0.85, 0.60, 0.18)
	c.borde = {}
	for i, p in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
		local t = c:CreateTexture(nil, "BORDER")
		t:SetColorTexture(0.42, 0.85, 0.60, 0.9)
		t:SetPoint(p[1], c, p[1]); t:SetPoint(p[2], c, p[2])
		if i <= 2 then t:SetHeight(1) else t:SetWidth(1) end
		c.borde[i] = t
	end
	c.nombre = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	c.nombre:SetPoint("CENTER", c, "CENTER", 0, 0)
	c:SetScript("OnMouseDown", function(self, boton)
		if boton ~= "LeftButton" or enCombate() or V.Fijas() then return end
		local f = r.marco
		local s = f:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		local x0, y0 = f:GetCenter()
		self.arrastre = { cx = cx / s, cy = cy / s, x0 = x0, y0 = y0 }
		self:SetScript("OnUpdate", function(me)
			if enCombate() then me:SetScript("OnUpdate", nil); me.arrastre = nil; return end
			local a = me.arrastre
			local nx, ny = GetCursorPosition()
			nx, ny = nx / s, ny / s
			local pw, ph = UIParent:GetWidth() / 2 / f:GetScale() * UIParent:GetScale(), UIParent:GetHeight() / 2 / f:GetScale() * UIParent:GetScale()
			f:ClearAllPoints()
			f:SetPoint("CENTER", UIParent, "CENTER", (a.x0 + nx - a.cx) - pw, (a.y0 + ny - a.cy) - ph)
		end)
	end)
	c:SetScript("OnMouseUp", function(self)
		if not self.arrastre then return end
		self:SetScript("OnUpdate", nil)
		self.arrastre = nil
		guardar(r.nombre, r.marco)
	end)
	c:SetScript("OnMouseWheel", function(_, delta)
		if enCombate() or V.Fijas() or not r.marco.SetScale then return end
		local e = math.max(0.5, math.min(2, (r.marco:GetScale() or 1) + delta * 0.05))
		r.marco:SetScale(e)
		guardar(r.nombre, r.marco)
		local l = db()[r.nombre]
		if l then l.escala = e else db()[r.nombre] = { escala = e } end
	end)
	capas[r.nombre] = c
	return c
end

function V.ModoMover(si)
	if si and enCombate() then return false, "Estás en combate: el modo «Mover elementos» se abre fuera de combate." end
	V.moviendo = si and true or false
	for _, r in pairs(V.marcos) do
		local c = capa(r)
		if V.moviendo then
			c:ClearAllPoints()
			c:SetAllPoints(r.marco)
			c.nombre:SetText(r.etiqueta .. "\n|cff9ba2b9arrastra · rueda: tamaño|r")
			c:Show()
		else
			c:SetScript("OnUpdate", nil)
			c:Hide()
		end
	end
	for _, fn in ipairs(V.alMover or {}) do pcall(fn, V.moviendo) end
	return true
end

-- Para los módulos que muestran algo escondido solo mientras se mueve (el medidor, los avisos...).
function V.AlModoMover(fn) V.alMover = V.alMover or {}; table.insert(V.alMover, fn) end

local salir = CreateFrame("Frame")
salir:RegisterEvent("PLAYER_REGEN_DISABLED")
salir:SetScript("OnEvent", function() if V.moviendo then V.ModoMover(false) end end)

-- El candado también vale para la ventana de Mamba (Polestar): sus asas llaman a ns.StartDrag.
local function candadoPolestar()
	local P = _G.Polestar
	if not (P and P.StartDrag) or V.psCandado then return end
	local orig = P.StartDrag
	P.StartDrag = function(handle, frame, opts)
		for _, r in pairs(V.marcos) do
			if r.marco == frame and noSeMueve() then return end
		end
		return orig(handle, frame, opts)
	end
	V.psCandado = true
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
	candadoPolestar()
	local hub = _G.PolestarPicker
	if hub then V.Movible(hub, "hub", nil, { yaArrastra = true }) end
	local P = _G.Polestar
	if P and P.UI and P.UI.ShowPicker and not hub then
		-- el hub se arma la primera vez que se abre
		hooksecurefunc(P.UI, "ShowPicker", function()
			if _G.PolestarPicker and not V.marcos.hub then V.Movible(_G.PolestarPicker, "hub", nil, { yaArrastra = true }) end
		end)
	end
end)

A.Opciones("Ventanas", "Ventanas de Mamba", {
	{ kind = "toggle", label = "Fijar las ventanas (que no se muevan)",
		help = "Con esto encendido, las ventanas de Mamba no se mueven al arrastrarlas.",
		get = function() return V.Fijas() end, set = function(v) V.Fijar(v) end },
	{ kind = "button", label = "Mover elementos", onClick = function() V.ModoMover(not V.moviendo) end },
	{ kind = "button", label = "Restablecer posiciones", onClick = function() V.Restablecer() end },
})
