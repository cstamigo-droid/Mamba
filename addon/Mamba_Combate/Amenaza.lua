-- Mamba_Combate: amenaza del grupo (K66). Las placas de nombre propias (K67) están en Placas.lua.
--   Amenaza: UnitDetailedThreatSituation (Forever sí la deja leer: ALCANCE.md, comprobado en EllesmereUI). Una
--   ventanita con tu % y el de tu grupo sobre tu objetivo, y aviso "vas a quitarle el objetivo al tanque".
--   Placas: sobre la placa de cada enemigo, un borde del color de su amenaza contigo, una marca de élite o raro y su
--   barra de lanzamiento con "INTERRUMPIBLE" (si el juego lo esconde, no se marca). Solo se cambia el aspecto, que
--   Blizzard permite; nada se hace por el jugador. Licencia: GPL-3.0-only.
local _, M = ...
local A = {}
M.Amenaza = A

---------------------------------------------------------------- amenaza del grupo
function A.Unidades()
	local out = { "player" }
	if IsInRaid and IsInRaid() then
		for i = 1, (GetNumGroupMembers and GetNumGroupMembers() or 0) do out[#out + 1] = "raid" .. i end
	elseif IsInGroup and IsInGroup() then
		for i = 1, 4 do out[#out + 1] = "party" .. i end
	end
	if UnitExists and UnitExists("pet") then out[#out + 1] = "pet" end
	return out
end

-- Lista ordenada { { nombre, pct, tanque, yo } } sobre el objetivo (lo secreto queda fuera).
function A.Lista()
	local out = {}
	if not (UnitExists("target") and UnitDetailedThreatSituation) then return out end
	for _, u in ipairs(A.Unidades()) do
		if UnitExists(u) and not (UnitIsUnit and u ~= "player" and M.Si(UnitIsUnit(u, "player"))) then
			local ok, tanque, _, pct = pcall(UnitDetailedThreatSituation, u, "target")
			pct = ok and M.Num(pct)
			if pct then
				local n = UnitName(u)
				-- K111: el nombre puede venir secreto en una mazmorra (y aquí va a un format): entonces "Tú" o "Compañero"
				if M.Secreto(n) or type(n) ~= "string" then n = (u == "player") and "Tú" or "Compañero" end
				out[#out + 1] = { nombre = n, pct = pct, tanque = (not M.Secreto(tanque)) and tanque or false, yo = u == "player" }
			end
		end
	end
	table.sort(out, function(a, b) return a.pct > b.pct end)
	return out
end

local ventana, filas = nil, {}
local mostrarRol = true
function A.MostrarPorRol(v) mostrarRol = v and true or false; A.Dibujar() end

function A.Crear()
	if ventana then return end
	ventana = CreateFrame("Frame", "MambaAmenaza", UIParent)
	ventana:SetSize(160, 14)
	ventana:SetPoint("RIGHT", UIParent, "RIGHT", -260, 0)
	ventana:Hide()
	M.Movible(ventana, "MambaAmenaza", "Amenaza del grupo")
	ventana.titulo = M.Piezas.Texto(ventana, "small", "text")
	ventana.titulo:SetPoint("BOTTOMLEFT", ventana, "TOPLEFT", 0, 1)
	ventana.titulo:SetText("Amenaza")
end
M.Precrear(function() A.Crear() end)
M.AlModoMover(function(activo)
	A.Crear()
	if activo then
		if not ventana:IsShown() then ventana.ejemplo = true; ventana:SetHeight(6 * 13); ventana:Show() end
	elseif ventana.ejemplo then
		ventana.ejemplo = nil
		ventana:Hide()
		A.Dibujar()
	end
end)

function A.Dibujar()
	if ventana and ventana.ejemplo then return end -- modo «Mover elementos»
	local d = M.DB()
	local lista = A.Lista()
	local ver = d.amenaza and mostrarRol and #lista > 0 and (IsInGroup and IsInGroup() or false)
	if not ventana then
		if not ver then return end
		A.Crear()
	end
	if not ver then ventana:Hide(); return end
	for i = 1, math.max(#lista, #filas) do
		local x = lista[i]
		local b = filas[i]
		if x and i <= 6 then
			if not b then
				b = M.Barra(ventana, 160, 12)
				b:SetPoint("TOP", ventana, "TOP", 0, -(i - 1) * 13)
				b:SetMinMaxValues(0, 100)
				filas[i] = b
			end
			b:SetValue(math.min(100, x.pct))
			if x.tanque then b:SetStatusBarColor(0.8, 0.2, 0.2)
			elseif x.yo then b:SetStatusBarColor(0.9, 0.75, 0.2)
			else b:SetStatusBarColor(0.4, 0.55, 0.85) end
			b.texto:SetText(("%s  %d %%"):format(x.nombre, math.floor(x.pct + 0.5)))
			b:Show()
		elseif b then b:Hide() end
	end
	-- el marco crece con las barras: el recuadro de «Mover elementos» las cubre todas
	-- alto FIJO al máximo: si creciera con las barras, el lugar se guarda por el centro y el título saltaría (revisión limpia, 19-11)
	ventana:SetHeight(6 * 13)
	ventana:Show()
end

-- Aviso: tu amenaza pasa el límite y no eres el tanque.
function A.Peligro()
	if not (UnitExists("target") and UnitDetailedThreatSituation) then return nil end
	local ok, tanque, _, pct = pcall(UnitDetailedThreatSituation, "player", "target")
	pct = ok and M.Num(pct)
	if not pct or M.Secreto(tanque) or tanque then return nil end
	local rol = M.Rotacion and M.Rotacion.Rol and M.Rotacion.Rol()
	if rol == "tanque" then return nil end
	return pct >= (M.DB().avisoAmenaza or 90), pct
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE",
	"PLAYER_TARGET_CHANGED", "GROUP_ROSTER_UPDATE" }) do M.Escuchar(f, e) end
f:SetScript("OnEvent", function(_, e)
	local t = GetTime and GetTime() or 0
	if e:find("THREAT") and t < (A.proxAmenaza or 0) then return end -- como mucho 5 veces por segundo
	A.proxAmenaza = t + 0.2
	M.Proteger("amenaza", A.Dibujar)
end)
