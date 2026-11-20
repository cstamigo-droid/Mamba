-- Mamba_Profesiones: lo que se MIDE jugando (R0, punto 2: lo estimado se corrige con lo medido).
--   - Farmeo: al apretar "Llévame" en una fila de farmeo empieza una medición de ese objeto en ese mapa; mientras
--     estás en el mapa se suman los segundos y lo que entra a tus bolsas. Desde 5 minutos medidos, la lista usa
--     tus unidades por hora en vez del "≈".
--   - Recetas: al abrir tu ventana de profesión se leen tus recetas y sus materiales (para "Ganar oro").
-- Licencia: GPL-3.0-only.
local _, M = ...
local Med = {}
M.Medir = Med

local actual -- { id, mapa, cuenta, t }

local function mapaActual()
	return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
end
local function cuenta(id) return GetItemCount and GetItemCount(id) or 0 end
local function ahora() return GetTime and GetTime() or 0 end

function Med.Empezar(id, mapa)
	if M.DB().sin_medir then actual = nil; return end -- K124: medir apagado en Opciones
	actual = { id = id, mapa = mapa, cuenta = cuenta(id), t = ahora() }
end
function Med.Parar() actual = nil end
function Med.Actual() return actual end

-- Suma lo medido desde la última vez (solo si sigues en el mapa y no pasó más de 10 min sin novedades).
function Med.Tick()
	if not actual then return end
	local t = ahora()
	local dt = t - actual.t
	local n = cuenta(actual.id)
	if mapaActual() == actual.mapa and dt > 0 and dt < 600 then
		local k = actual.id .. ":" .. actual.mapa
		local m = M.DB().medido[k] or { 0, 0 }
		m[1] = m[1] + math.max(0, n - actual.cuenta)
		m[2] = m[2] + dt
		M.DB().medido[k] = m
	end
	actual.t, actual.cuenta = t, n
end

-- Lee la ventana de profesión abierta con C_TradeSkillUI (la API que trae Forever; la usa SkillUp Forever).
function Med.LeerRecetas()
	if M.DB().sin_recetas then return 0 end -- K124: apagado en Opciones
	local T = C_TradeSkillUI
	if not (T and T.GetAllRecipeIDs and T.GetRecipeInfo and T.GetRecipeSchematic) then return 0 end
	if (T.IsTradeSkillLinked and T.IsTradeSkillLinked()) or (T.IsTradeSkillGuild and T.IsTradeSkillGuild()) then return 0 end
	local base = T.GetBaseProfessionInfo and T.GetBaseProfessionInfo()
	local prof = base and base.professionName
	if not prof then return 0 end
	local lista = {}
	for _, rid in ipairs(T.GetAllRecipeIDs() or {}) do
		local info = T.GetRecipeInfo(rid)
		if info and info.learned then
			local s = T.GetRecipeSchematic(rid, false)
			if s and s.outputItemID then
				local r = { nombre = info.name or s.name, id = s.outputItemID, receta = rid,
					cantidad = ((s.quantityMin or 1) + (s.quantityMax or s.quantityMin or 1)) / 2, reactivos = {} }
				for _, slot in ipairs(s.reagentSlotSchematics or {}) do
					local first = slot.reagents and slot.reagents[1]
					if first and first.itemID and (slot.quantityRequired or 0) > 0 then
						r.reactivos[#r.reactivos + 1] = { first.itemID, slot.quantityRequired }
					end
				end
				lista[#lista + 1] = r
			end
		end
	end
	local quien = UnitName and UnitName("player") or "?"
	local db = M.DB().recetas
	db[quien] = db[quien] or {}
	db[quien][prof] = lista
	return #lista
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "BAG_UPDATE_DELAYED", "ZONE_CHANGED_NEW_AREA", "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE" }) do M.Escuchar(ev, e) end
ev:SetScript("OnEvent", function(_, e)
	if e == "TRADE_SKILL_SHOW" or e == "TRADE_SKILL_LIST_UPDATE" then
		-- las ráfagas de eventos se juntan en una sola lectura (como SkillUp Forever)
		if Med.esperando then return end
		Med.esperando = true
		local leer = function() Med.esperando = false; M.Proteger("recetas", Med.LeerRecetas) end
		if C_Timer and C_Timer.After then C_Timer.After(0.5, leer) else leer() end
	else
		M.Proteger("medir", Med.Tick)
	end
end)
