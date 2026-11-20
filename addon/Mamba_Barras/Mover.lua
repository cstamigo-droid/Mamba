-- Mamba_Barras: el modo "Mover barras". Cada barra muestra un recuadro con su nombre que se arrastra con
-- el ratón; clic derecho en el recuadro abre sus opciones. Solo fuera de combate (las barras son marcos
-- protegidos): si entras en combate, el modo se cierra solo. Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas

local recuadros = {}
local panel, rejilla
local PASO = 16

local function nombreDe(id)
	local d = M.Def(id)
	return d and d.nombre or tostring(id)
end

local function guardarLugar(id, h)
	local esc = h:GetScale()
	local x, y = (h:GetLeft() or 0) * esc, (h:GetBottom() or 0) * esc
	if M.PJ().rejilla ~= false then
		x = math.floor(x / PASO + 0.5) * PASO
		y = math.floor(y / PASO + 0.5) * PASO
	end
	local c = M.Config(id)
	c.punto, c.x, c.y = "BOTTOMLEFT", x, y
	M.Colocar(h, c)
end

local function recuadro(id)
	local h = M.marcos[id]
	if not h then return end
	local r = recuadros[id]
	if not r then
		r = CreateFrame("Button", nil, UIParent)
		r:SetFrameStrata("DIALOG")
		r:EnableMouse(true)
		r:RegisterForDrag("LeftButton")
		r:RegisterForClicks("RightButtonUp")
		r.fondo = P.Relleno(r, "chipAccent")
		r.texto = P.Texto(r, "label", "accent")
		r.texto:SetPoint("BOTTOMLEFT", r, "TOPLEFT", 0, 2)
		r:SetScript("OnDragStart", function()
			if InCombatLockdown() then return end
			h:StartMoving()
		end)
		r:SetScript("OnDragStop", function()
			h:StopMovingOrSizing()
			if not InCombatLockdown() then guardarLugar(id, h) end
		end)
		r:SetScript("OnClick", function() if M.AbrirOpciones then M.AbrirOpciones(id) end end)
		recuadros[id] = r
	end
	r:ClearAllPoints()
	r:SetAllPoints(h)
	local c = M.Config(id)
	r.texto:SetText(nombreDe(id) .. (c.mostrar and "" or "  (oculta)"))
	r:SetAlpha(c.mostrar and 1 or 0.5)
	r:Show()
end

local function dibujarRejilla()
	if not rejilla then
		rejilla = CreateFrame("Frame", nil, UIParent)
		rejilla:SetAllPoints(UIParent)
		rejilla:SetFrameStrata("BACKGROUND")
		local w, hh = UIParent:GetWidth(), UIParent:GetHeight()
		for x = 0, w, PASO * 4 do
			local l = P.Linea(rejilla, true)
			l:SetPoint("TOPLEFT", rejilla, "TOPLEFT", x, 0)
			l:SetPoint("BOTTOMLEFT", rejilla, "BOTTOMLEFT", x, 0)
		end
		for y = 0, hh, PASO * 4 do
			local l = P.Linea(rejilla, false)
			l:SetPoint("BOTTOMLEFT", rejilla, "BOTTOMLEFT", 0, y)
			l:SetPoint("BOTTOMRIGHT", rejilla, "BOTTOMRIGHT", 0, y)
		end
	end
	if M.PJ().rejilla ~= false then rejilla:Show() else rejilla:Hide() end
end

local function crearPanel()
	panel = P.Ventana("MambaBarrasMover", "Mover barras", 380, 150)
	panel:ClearAllPoints()
	panel:SetPoint("TOP", UIParent, "TOP", 0, -80)
	local m, top = panel.margen or 16, (panel.cuerpo or 26) + 4
	local t = P.Texto(panel, "body", "textDim")
	t:SetPoint("TOPLEFT", panel, "TOPLEFT", m, -top)
	t:SetPoint("RIGHT", panel, "RIGHT", -m, 0)
	t:SetText("Arrastra las barras. Clic derecho en una: sus opciones.")
	local reg = P.Interruptor(panel, "Rejilla", "Las barras se acomodan a una rejilla al soltarlas.",
		function() return M.PJ().rejilla ~= false end,
		function(v) M.PJ().rejilla = v and true or false; dibujarRejilla() end)
	reg:SetPoint("TOPLEFT", t, "BOTTOMLEFT", -12, -6)
	P.Acomodar(reg, 200)
	local listo = P.Boton(panel, "Listo", function() M.TerminarMover() end, true)
	listo:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -m, 14)
	-- Pedido de Cristian (19-11): asignar teclas desde el modo edición, como en Bartender: el ratón sobre el
	-- botón y se aprieta la tecla. Aparece también en el modo «Mover» global de Mamba (este panel sale ahí).
	local teclas = P.Boton(panel, "Asignar teclas", function()
		M.TerminarMover()
		if M.EmpezarTeclas() and M.AbrirAyudaTeclas then M.AbrirAyudaTeclas() end
	end)
	teclas:SetPoint("RIGHT", listo, "LEFT", -8, 0)
	panel.botonTeclas = teclas
	panel:SetScript("OnHide", function() if M.moviendoBarras then M.TerminarMover() end end)
end

function M.EmpezarMover()
	if InCombatLockdown() or not M.listo or M.PJ().apagado then return false end -- apagadas: no hay nada que mover
	M.moviendoBarras = true
	M.MostrarVacios(true)
	for id in pairs(M.marcos) do recuadro(id) end
	dibujarRejilla()
	if not panel then crearPanel() end
	panel:Show()
	return true
end

function M.TerminarMover()
	if not M.moviendoBarras then return end
	M.moviendoBarras = false
	for _, r in pairs(recuadros) do r:Hide() end
	if rejilla then rejilla:Hide() end
	if panel and panel:IsShown() then panel:Hide() end
	if not M.asignando then M.MostrarVacios(false) end
	M.FueraDeCombate("disponer", M.DisponerTodo)
end

-- Después de cambiar una opción, el recuadro sigue a su barra.
local previo = M.AlDisponer
function M.AlDisponer(id)
	if previo then previo(id) end
	if M.moviendoBarras then recuadro(id) end
end

local ev = CreateFrame("Frame")
M.Escuchar(ev, "PLAYER_REGEN_DISABLED")
ev:SetScript("OnEvent", function()
	if M.moviendoBarras then M.TerminarMover() end
	if M.asignando then M.TerminarTeclas() end
end)

-- K55 ampliado (18-11): el modo «Mover elementos» de Mamba también pone las barras en su modo de mover.
local enlace = CreateFrame("Frame")
M.Escuchar(enlace, "PLAYER_LOGIN")
enlace:SetScript("OnEvent", function()
	local api = _G.MambaAPI
	if not (api and api.AlModoMover) then return end
	pcall(api.AlModoMover, function(activo)
		if activo then M.EmpezarMover() else M.TerminarMover() end
	end)
end)
