-- Mamba_Barras: la barra de formas y actitudes (oso, felina, viaje...; actitudes del guerrero; aura del
-- paladín). Botones seguros de hechizo: el clic lanza la forma, como en la barra del juego.
-- Licencia: GPL-3.0-only.
local _, M = ...
local LAB = LibStub("LibActionButton-1.0")

local def = M.Def("formas")

local function infoForma(i)
	if not GetShapeshiftFormInfo then return end
	local ok, icono, activa, usable, hechizo = pcall(GetShapeshiftFormInfo, i)
	if ok then return icono, activa, usable, hechizo end
end

local function cuantas()
	return GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
end

-- La forma activa se marca. Va después de que la librería pinte el botón (ella lo desmarca).
local function marcar()
	local h = M.marcos.formas
	if not h then return end
	for i, b in ipairs(h.botones) do
		local _, activa = infoForma(i)
		if b.SetChecked then b:SetChecked(activa and true or false) end
	end
end

local function nombreHechizo(id)
	if C_Spell and C_Spell.GetSpellName then
		local ok, n = pcall(C_Spell.GetSpellName, id)
		if ok and type(n) == "string" and n ~= "" then return n end
	end
	if GetSpellInfo then
		local ok, n = pcall(GetSpellInfo, id)
		if ok and type(n) == "string" and n ~= "" then return n end
	end
end

-- A3: el clic (ratón o tecla, que llega como LeftButton) usa "*type1"/"*macrotext1" (el * = con cualquier
-- modificador: las teclas de forma del juego son CTRL-F1...), que el botón seguro mira antes que "type"; la
-- librería solo reescribe "type", así el ícono y el cuadro siguen siendo los suyos.
-- Revisor t13: solo el druida (y el Lobo fantasma del chamán). El Sigilo del pícaro y la Forma de las
-- Sombras se quitan volviendo a lanzar el hechizo, y /cancelform no los quita: para ellos queda el "spell".
local CLASES_FORMA = { DRUID = true, SHAMAN = true }
local function salidaDeForma(b, i, hechizo)
	local _, clase = UnitClass("player")
	local texto = CLASES_FORMA[clase] and hechizo and M.MacroForma(i, nombreHechizo(hechizo)) or nil
	b:SetAttribute("*type1", texto and "macro" or nil)
	b:SetAttribute("*macrotext1", texto)
end

-- Pone en cada botón la forma que corresponde (fuera de combate: cambia atributos seguros).
function M.LlenarFormas()
	local h = M.marcos.formas
	if not h then return end
	local n = cuantas()
	for i, b in ipairs(h.botones) do
		local _, _, _, hechizo = infoForma(i)
		if i <= n and hechizo then
			b:SetState(0, "spell", hechizo)
			salidaDeForma(b, i, hechizo)
		else
			b:SetState(0, "empty")
			salidaDeForma(b, i, nil)
		end
	end
	local c = M.Config("formas")
	c.hay = n
	M.Disponer("formas")
	C_Timer.After(0, marcar)
end

function M.CrearFormas()
	local h = CreateFrame("Frame", "MambaBarraFormas", UIParent, "SecureHandlerStateTemplate")
	h.def = def
	h:SetFrameStrata("MEDIUM")
	h:SetMovable(true)
	h:SetClampedToScreen(true)
	h.botones = {}
	for i = 1, def.max do
		local b = LAB:CreateButton(i, "MambaForma" .. i, h, {
			tooltip = "enabled", showGrid = false, keyBoundTarget = def.comando .. i,
		})
		h.botones[i] = b
	end
	-- Una clase sin formas no ve la barra.
	h.condicionVer = "[petbattle]hide;show"
	M.marcos.formas = h
	M.LlenarFormas()
end

-- Cuántos botones se ven: los que tienen forma, sin pasar el máximo elegido.
local disponerBase = M.Disponer
function M.Disponer(id)
	if id == "formas" then
		local h = M.marcos.formas
		if not h then return end
		local c = M.Config("formas")
		local hay = math.min(cuantas(), c.botones or def.max)
		local copia = {}
		for k, v in pairs(c) do copia[k] = v end
		copia.botones = math.max(1, hay)
		if hay == 0 then copia.mostrar = false end
		M.Rejillar(h, h.botones, copia)
		M.Colocar(h, copia)
		M.VerBarra(h, copia)
		if M.AlDisponer then M.AlDisponer(id) end
		return
	end
	return disponerBase(id)
end

local ev = CreateFrame("Frame")
M.Escuchar(ev, "UPDATE_SHAPESHIFT_FORMS")
M.Escuchar(ev, "UPDATE_SHAPESHIFT_FORM")
M.Escuchar(ev, "UPDATE_SHAPESHIFT_USABLE")
M.Escuchar(ev, "SPELLS_CHANGED")
ev:SetScript("OnEvent", function(_, e)
	if not M.marcos.formas then return end
	if e == "UPDATE_SHAPESHIFT_FORMS" or e == "SPELLS_CHANGED" then
		M.FueraDeCombate("llenarFormas", M.LlenarFormas)
	else
		C_Timer.After(0, marcar)
	end
end)
