-- Mamba_Barras: las teclas. Tus teclas de siempre siguen andando sin hacer nada:
--  * las de las barras del juego (ACTIONBUTTON1, MULTIACTIONBAR3BUTTON5...) apuntan al botón de Mamba de
--    la misma casilla;
--  * las que tenías en Bartender4 (CLICK BT4Button13...) también.
-- Es un "atajo encima" (SetOverrideBindingClick): no borra ni cambia tus teclas guardadas; si apagas
-- Mamba, vuelven a hacer lo de antes. Se arma fuera de combate.
-- El modo "Asignar teclas": pasas el ratón por un botón y aprietas la tecla. Licencia: GPL-3.0-only.
local _, M = ...

local dueno = CreateFrame("Frame")

local function claves(cmd)
	if not GetBindingKey then return {} end
	return { GetBindingKey(cmd) }
end

function M.AplicarTeclas()
	if InCombatLockdown() then return M.FueraDeCombate("teclas", M.AplicarTeclas) end
	if not M.listo and not next(M.marcos) then return end
	ClearOverrideBindings(dueno)
	local n = 0
	-- barras del juego -> Mamba
	for _, d in ipairs(M.BARRAS) do
		if d.comando and M.marcos[d.id] then
			for i = 1, 12 do
				for _, k in ipairs(claves(d.comando .. i)) do
					SetOverrideBindingClick(dueno, false, k, "MambaBoton" .. (d.inicio + i - 1), "LeftButton")
					n = n + 1
				end
			end
		end
	end
	for _, esp in ipairs(M.ESPECIALES) do
		if M.marcos[esp.id] then
			local pre = esp.id == "formas" and "MambaForma" or "MambaMascota"
			for i = 1, esp.max do
				for _, k in ipairs(claves(esp.comando .. i)) do
					SetOverrideBindingClick(dueno, false, k, pre .. i, "LeftButton")
					n = n + 1
				end
			end
		end
	end
	-- teclas de Bartender4 -> Mamba
	local bt = 0
	if GetNumBindings and GetBinding then
		for j = 1, GetNumBindings() do
			local cmd, _, k1, k2 = GetBinding(j)
			local casilla = M.BotonDeBT(cmd)
			if casilla and M.botones[casilla] then
				for _, k in ipairs({ k1, k2 }) do
					if k then
						SetOverrideBindingClick(dueno, false, k, "MambaBoton" .. casilla, "LeftButton")
						bt = bt + 1
					end
				end
			end
		end
	end
	M.Anotar("teclas", { juego = n, bartender = bt })
	-- que cada botón muestre su tecla
	for _, b in pairs(M.botones) do
		if b.UpdateConfig and b.config then b:UpdateConfig(b.config) end
	end
end

local ev = CreateFrame("Frame")
M.Escuchar(ev, "UPDATE_BINDINGS")
ev:SetScript("OnEvent", function()
	if M.listo and not M.asignando then M.FueraDeCombate("teclas", M.AplicarTeclas) end
end)

---------------------------------------------------------------- modo "Asignar teclas"
-- Un marco invisible que toma el teclado mientras el ratón está sobre un botón de Mamba.
local captura = CreateFrame("Frame", "MambaBarrasCaptura", UIParent)
captura:SetFrameStrata("TOOLTIP")
captura:EnableKeyboard(false)
captura:Hide()
M.captura = captura

local IGNORAR = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true, UNKNOWN = true }
local RATON = { LeftButton = "BUTTON1", RightButton = "BUTTON2", MiddleButton = "BUTTON3",
	Button4 = "BUTTON4", Button5 = "BUTTON5" }

local function conModificadores(k)
	local s = ""
	if IsAltKeyDown() then s = s .. "ALT-" end
	if IsControlKeyDown() then s = s .. "CTRL-" end
	if IsShiftKeyDown() then s = s .. "SHIFT-" end
	return s .. k
end

-- La acción guardada para un botón: la del juego (si la barra la tiene) o el clic a su nombre.
local function accionDe(b)
	if b.config and b.config.keyBoundTarget then return b.config.keyBoundTarget end
	local nombre = b:GetName() or ""
	if nombre:match("^MambaForma(%d+)") then return "SHAPESHIFTBUTTON" .. nombre:match("(%d+)$") end
	if nombre:match("^MambaMascota(%d+)") then return "BONUSACTIONBUTTON" .. nombre:match("(%d+)$") end
	return "CLICK " .. nombre .. ":LeftButton"
end
M.AccionDe = accionDe

function M.TeclasDe(b)
	local t = {}
	for _, k in ipairs(claves(accionDe(b))) do t[#t + 1] = GetBindingText and GetBindingText(k, 1) or k end
	return table.concat(t, ", ")
end

local function asignar(k)
	local b = M.bajoRaton
	if not b then return end
	if k == "ESCAPE" then return M.TerminarTeclas() end
	if k == "BACKSPACE" or k == "DELETE" then
		local a = accionDe(b)
		while GetBindingKey(a) do SetBinding(GetBindingKey(a), nil) end
	else
		SetBinding(conModificadores(k), accionDe(b))
	end
	SaveBindings(GetCurrentBindingSet())
	M.AplicarTeclas()
	if M.AlCambiarTecla then M.AlCambiarTecla(b) end
end

captura:SetScript("OnKeyDown", function(_, k)
	if IGNORAR[k] then return end
	asignar(k)
end)
captura:SetScript("OnMouseWheel", function(_, d) asignar(d > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
captura:SetScript("OnMouseDown", function(_, boton)
	if boton == "LeftButton" or boton == "RightButton" then return end -- esos son para apuntar
	asignar(RATON[boton] or boton)
end)

local function seguir()
	if not M.asignando then return end
	local foco = GetMouseFoci and GetMouseFoci()[1] or (GetMouseFocus and GetMouseFocus())
	local b
	for _, x in pairs(M.botones) do if x == foco then b = x end end
	for _, id in ipairs({ "formas", "mascota" }) do
		local h = M.marcos[id]
		if h then for _, x in ipairs(h.botones) do if x == foco then b = x end end end
	end
	M.bajoRaton = b
	if b then
		captura:ClearAllPoints()
		captura:SetAllPoints(b)
		captura:EnableKeyboard(true)
		captura:EnableMouseWheel(true)
		captura:Show()
		if M.AlApuntarTecla then M.AlApuntarTecla(b) end
	elseif not captura:IsMouseOver() then
		captura:Hide()
		captura:EnableKeyboard(false)
	end
end
local reloj = CreateFrame("Frame")
reloj:SetScript("OnUpdate", function() if M.asignando then seguir() end end)

function M.EmpezarTeclas()
	if InCombatLockdown() then return false end
	M.asignando = true
	M.MostrarVacios(true)
	return true
end

function M.TerminarTeclas()
	M.asignando = false
	M.bajoRaton = nil
	captura:Hide()
	captura:EnableKeyboard(false)
	if not M.moviendoBarras then M.MostrarVacios(false) end
	M.AplicarTeclas()
	if M.AlTerminarTeclas then M.AlTerminarTeclas() end
end
