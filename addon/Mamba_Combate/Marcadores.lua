-- Mamba_Combate: barra de marcadores de banda (calavera, cruz, luna…) para marcar a quién matar primero o a quién
-- controlar. Un clic en un ícono marca a tu OBJETIVO (otro clic en el mismo, lo quita) con la función del juego
-- SetRaidTarget, la misma del menú del objetivo: el clic es del jugador, Mamba no marca nada sola.
-- Se ve en grupo, siempre o nunca (Combate › Avisos y barras). Las marcas salen también en las placas de Mamba.
-- Licencia: GPL-3.0-only.
local _, M = ...
local Mk = {}
M.Marcadores = Mk

local TEX = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
Mk.NOMBRES = { "Estrella", "Círculo", "Diamante", "Triángulo", "Luna", "Cuadrado", "Cruz", "Calavera" }
Mk.USO = { [8] = "matar primero", [7] = "matar segundo", [5] = "controlar (oveja, raíces…)", [6] = "controlar (trampa, sueño…)" }

function Mk.Nombre(i)
	local g = _G["RAID_TARGET_" .. i]
	if type(g) == "string" and g ~= "" then return g end
	return Mk.NOMBRES[i] or tostring(i)
end

local barra
-- ¿Hay que mostrarla? «siempre», «grupo» (en grupo o banda) o «nunca».
function Mk.Toca()
	local d = M.DB()
	local m = d.marcadores or "siempre"
	if m == "nunca" then return false end
	if m == "grupo" then return (IsInGroup and IsInGroup()) and true or false end
	return true
end

-- Marca al objetivo (o quita la marca si ya tenía esa). -> true | false, motivo
function Mk.Marcar(i)
	if not (UnitExists and UnitExists("target")) then return false, "sin objetivo" end
	if not SetRaidTarget then return false, "el juego no lo permite" end
	local actual = GetRaidTargetIndex and M.Num(GetRaidTargetIndex("target"))
	local ok = pcall(SetRaidTarget, "target", (actual == i) and 0 or i)
	if not ok then return false, "el juego no lo permitió" end
	return true
end

function Mk.Crear()
	if barra then return end
	barra = CreateFrame("Frame", "MambaMarcadores", UIParent)
	barra:SetSize(9 * 22 + 2, 22)
	barra:SetPoint("TOP", UIParent, "TOP", 0, -120)
	barra:Hide()
	M.Movible(barra, "MambaMarcadores", "Marcadores de banda")
	barra.botones = {}
	for k = 1, 9 do
		local i = (k <= 8) and (9 - k) or 0 -- calavera primero; el último quita la marca
		local b = CreateFrame("Button", nil, barra)
		b:SetSize(20, 20)
		b:SetPoint("LEFT", barra, "LEFT", 1 + (k - 1) * 22, 0)
		b.icono = b:CreateTexture(nil, "ARTWORK")
		b.icono:SetAllPoints(b)
		if i > 0 then
			b.icono:SetTexture(TEX)
			b.icono:SetTexCoord(M.Placas.CoordsBanda(i))
		else
			b.x = M.Piezas.Texto(b, "body", "textDim")
			b.x:SetPoint("CENTER", b, "CENTER", 0, 0)
			b.x:SetText("×")
		end
		b.indice = i
		b:SetScript("OnClick", function()
			local ok, motivo = Mk.Marcar(i)
			if not ok and M.Avisos then M.Avisos.Mostrar("Marcadores: " .. motivo .. ". Elige un objetivo primero.") end
		end)
		b:SetScript("OnEnter", function(s)
			if not GameTooltip then return end
			GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
			if i > 0 then
				GameTooltip:SetText(Mk.Nombre(i))
				if Mk.USO[i] then GameTooltip:AddLine("Uso común: " .. Mk.USO[i], 1, 1, 1) end
				GameTooltip:AddLine("Clic: marca a tu objetivo. Otra vez: la quita.", 0.8, 0.8, 0.8)
			else
				GameTooltip:SetText("Quitar la marca de tu objetivo")
			end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
		barra.botones[k] = b
	end
end
M.Precrear(function() Mk.Crear() end)
M.AlModoMover(function(activo)
	Mk.Crear()
	if activo then
		if not barra:IsShown() then barra.ejemplo = true; barra:Show() end
	elseif barra.ejemplo then
		barra.ejemplo = nil
		Mk.Dibujar()
	end
end)

function Mk.Dibujar()
	if not barra then Mk.Crear() end
	if barra.ejemplo then return end
	if Mk.Toca() then barra:Show() else barra:Hide() end
end
function Mk.Barra() return barra end

local f = CreateFrame("Frame")
M.Escuchar(f, "GROUP_ROSTER_UPDATE")
M.Escuchar(f, "PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function() M.Proteger("marcadores", Mk.Dibujar) end)
M.AlCambiar(function() M.Proteger("marcadores", Mk.Dibujar) end)
