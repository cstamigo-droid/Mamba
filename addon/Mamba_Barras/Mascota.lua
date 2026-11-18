-- Mamba_Barras: la barra de la mascota (cazador, brujo). Botones seguros del tipo "pet": clic izquierdo
-- usa la orden o la habilidad; clic derecho prende o apaga el uso automático (/petautocasttoggle, la
-- orden del juego). Se ve solo cuando tienes mascota. Licencia: GPL-3.0-only.
local _, M = ...

local def = M.Def("mascota")
local N = def.max

local function info(i)
	if not GetPetActionInfo then return end
	local ok, nombre, textura, esToken, activa, autoPermitido, autoPrendido, hechizo = pcall(GetPetActionInfo, i)
	if not ok then return end
	if esToken then
		textura = _G[textura] or textura
		nombre = _G[nombre] or nombre
	end
	return nombre, textura, activa, autoPermitido, autoPrendido, hechizo
end

-- Lo que se ve (no protegido: se puede en combate).
local function pintar()
	local h = M.marcos.mascota
	if not h then return end
	for i, b in ipairs(h.botones) do
		local nombre, textura, activa, autoPermitido, autoPrendido = info(i)
		b.icon:SetTexture(textura)
		if textura then b.icon:Show() else b.icon:Hide() end
		b:SetChecked(activa and true or false)
		if b.auto then
			if autoPrendido then b.auto:Show() else b.auto:Hide() end
		end
		b.nombreAccion = nombre
		if b.cooldown and GetPetActionCooldown and CooldownFrame_Set then
			local ok, ini, dur, on = pcall(GetPetActionCooldown, i)
			if ok and not (issecretvalue and (issecretvalue(ini) or issecretvalue(dur))) then
				pcall(CooldownFrame_Set, b.cooldown, ini, dur, on)
			end
		end
	end
end

-- El clic derecho necesita el nombre de la habilidad: atributo seguro, fuera de combate.
local function nombres()
	local h = M.marcos.mascota
	if not h then return end
	for i, b in ipairs(h.botones) do
		local nombre, _, _, autoPermitido = info(i)
		if nombre and autoPermitido then
			b:SetAttribute("type2", "macro")
			b:SetAttribute("macrotext2", "/petautocasttoggle " .. nombre)
		else
			b:SetAttribute("type2", nil)
			b:SetAttribute("macrotext2", nil)
		end
	end
end

function M.CrearMascota()
	local h = CreateFrame("Frame", "MambaBarraMascota", UIParent, "SecureHandlerStateTemplate")
	h.def = def
	h:SetFrameStrata("LOW")
	h:SetMovable(true)
	h:SetClampedToScreen(true)
	h.botones = {}
	h.condicionVer = "[petbattle]hide;[nopet]hide;[vehicleui]hide;show"
	for i = 1, N do
		local b = CreateFrame("CheckButton", "MambaMascota" .. i, h, "ActionButtonTemplate, SecureActionButtonTemplate")
		b:RegisterForClicks("AnyUp", "AnyDown")
		b:SetAttribute("type", "pet")
		b:SetAttribute("action", i)
		b:SetScript("OnEnter", function(self)
			if GameTooltip.SetPetAction then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetPetAction(i)
				GameTooltip:Show()
			end
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
		-- marca de "uso automático prendido": la textura del juego para eso
		local auto = b:CreateTexture(nil, "OVERLAY")
		auto:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
		auto:SetPoint("TOPLEFT", b, "TOPLEFT", -12, 12)
		auto:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 12, -12)
		auto:Hide()
		b.auto = auto
		local tecla = b.HotKey
		if tecla then
			local k = GetBindingKey and GetBindingKey(def.comando .. i)
			tecla:SetText(k and (GetBindingText and GetBindingText(k, 1) or k) or "")
		end
		h.botones[i] = b
	end
	M.marcos.mascota = h
	pintar()
	nombres()
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PET_BAR_UPDATE", "UNIT_PET", "PET_BAR_UPDATE_COOLDOWN", "PET_UI_UPDATE",
	"PLAYER_CONTROL_LOST", "PLAYER_CONTROL_GAINED", "UNIT_FLAGS", "PET_BAR_UPDATE_USABLE" }) do
	M.Escuchar(ev, e)
end
ev:SetScript("OnEvent", function(_, e, unidad)
	if not M.marcos.mascota then return end
	if (e == "UNIT_PET" and unidad ~= "player") or (e == "UNIT_FLAGS" and unidad ~= "pet") then return end
	pintar()
	if e ~= "PET_BAR_UPDATE_COOLDOWN" then M.FueraDeCombate("nombresMascota", nombres) end
end)
