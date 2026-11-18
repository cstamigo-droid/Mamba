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
function V.Fijar(si) A.PrepararDB(); AsistenteDB.ventanasFijas = si and true or false end

local function guardar(nombre, f)
	if not (f and f.GetLeft and f:GetLeft()) then return end
	local P = _G.Polestar
	local x, y
	if P and P.PointOffsets then x, y = P.PointOffsets(f, "CENTER") else
		x = f:GetLeft() + f:GetWidth() / 2 - UIParent:GetWidth() / 2
		y = f:GetBottom() + f:GetHeight() / 2 - UIParent:GetHeight() / 2
	end
	db()[nombre] = { x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
end

local function reponer(nombre, f)
	local l = db()[nombre]
	if not l then return false end
	f:ClearAllPoints()
	f:SetPoint("CENTER", UIParent, "CENTER", l.x, l.y)
	return true
end

-- marco: la ventana; nombre: único y estable; asa: de dónde se arrastra (nil: la ventana entera).
-- opciones.yaArrastra = true cuando la ventana ya se arrastra sola (Polestar): solo se guarda y repone.
function V.Movible(marco, nombre, asa, opciones)
	if not (marco and nombre) then return false end
	opciones = opciones or {}
	marco:SetClampedToScreen(true)
	marco:SetMovable(true)
	local reg = { marco = marco, nombre = nombre, original = nil }
	if marco.GetNumPoints and (marco:GetNumPoints() or 0) > 0 and marco:GetPoint(1) then reg.original = { marco:GetPoint(1) } end
	V.marcos[nombre] = reg
	if not opciones.yaArrastra then
		asa = asa or marco
		local P = _G.Polestar
		if P and P.DragWindow then
			P.DragWindow(asa, marco, { locked = V.Fijas, onStop = function(f) guardar(nombre, f) end })
		else
			asa:EnableMouse(true)
			asa:RegisterForDrag("LeftButton")
			asa:SetScript("OnDragStart", function() if not V.Fijas() then marco:StartMoving() end end)
			asa:SetScript("OnDragStop", function() marco:StopMovingOrSizing(); guardar(nombre, marco) end)
		end
	end
	marco:HookScript("OnShow", function(f) reponer(nombre, f) end)
	if opciones.yaArrastra then marco:HookScript("OnHide", function(f) guardar(nombre, f) end) end
	if marco:IsShown() then reponer(nombre, marco) end
	return true
end

-- Vuelve a poner cada ventana en su lugar de siempre y borra lo guardado de este personaje.
function V.Restablecer()
	A.PrepararDB()
	if AsistenteDB.lugares then AsistenteDB.lugares[pj()] = {} end
	if AsistenteDB.ventanas then AsistenteDB.ventanas = {} end -- los lugares viejos de A.CrearVentana
	for _, r in pairs(V.marcos) do
		local f = r.marco
		f:ClearAllPoints()
		if r.original then f:SetPoint(unpack(r.original)) else f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
	end
	for _, fn in ipairs(V.alRestablecer or {}) do pcall(fn) end
end

-- Otros módulos que guardan sus lugares por su cuenta (barras) se enteran del "Restablecer" aquí.
function V.AlRestablecer(fn) V.alRestablecer = V.alRestablecer or {}; table.insert(V.alRestablecer, fn) end

-- El candado también vale para la ventana de Mamba (Polestar): sus asas llaman a ns.StartDrag.
local function candadoPolestar()
	local P = _G.Polestar
	if not (P and P.StartDrag) or V.psCandado then return end
	local orig = P.StartDrag
	P.StartDrag = function(handle, frame, opts)
		for _, r in pairs(V.marcos) do
			if r.marco == frame and V.Fijas() then return end
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
	{ kind = "button", label = "Restablecer posiciones", onClick = function() V.Restablecer() end },
})
