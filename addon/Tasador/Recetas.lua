-- Tasador: lee TUS recetas y los precios de los vendedores que visitas. Solo LEE.
--   * Recetas: al abrir la ventana de una profesión (Alquimia, Cocina, Primeros auxilios...), se anota lo que
--     el juego muestra: qué fabrica cada receta, cuántos salen y qué materiales lleva. No hay lista inventada:
--     la fuente es tu propia ventana de profesión.
--   * Vendedores: al abrir un vendedor, se anota cuánto cobra por cada cosa que vende por oro (viales, especias),
--     para calcular el costo de fabricar con lo que no está en la subasta.
-- Nunca fabrica ni compra (prueba C12 en test_comercio.py). Licencia: GPL-3.0.
local _, T = ...

local function L(v) return T.Leer(v) end

local function personaje()
	local n = UnitName and L(UnitName("player")) or "?"
	local r = GetRealmName and L(GetRealmName()) or ""
	return tostring(n) .. "-" .. tostring(r)
end
T.Personaje = personaje

-- Ventana antigua (GetTradeSkill*). Devuelve profesión, recetas[producto] = { n, mats = { {id, cant} } }.
local function leerAntigua()
	if not (GetNumTradeSkills and GetTradeSkillInfo and GetTradeSkillItemLink and GetTradeSkillNumReagents
		and GetTradeSkillReagentInfo and GetTradeSkillReagentItemLink) then return nil end
	local prof = GetTradeSkillLine and L((GetTradeSkillLine())) or nil
	local recetas, total = {}, L(GetNumTradeSkills()) or 0
	for i = 1, total do
		local _, tipo = GetTradeSkillInfo(i)
		if L(tipo) ~= "header" then
			local producto = T.ItemID(L(GetTradeSkillItemLink(i)))
			local n = GetTradeSkillNumMade and L((GetTradeSkillNumMade(i))) or 1
			local mats, completa = {}, producto ~= nil
			for r = 1, (L(GetTradeSkillNumReagents(i)) or 0) do
				local _, _, cant = GetTradeSkillReagentInfo(i, r)
				local id = T.ItemID(L(GetTradeSkillReagentItemLink(i, r)))
				cant = L(cant)
				if id and type(cant) == "number" then mats[#mats + 1] = { id, cant } else completa = false end
			end
			if completa and #mats > 0 then recetas[producto] = { n = type(n) == "number" and n or 1, mats = mats } end
		end
	end
	return prof, recetas
end

-- Ventana moderna (C_TradeSkillUI). Solo materiales básicos (los opcionales no son obligatorios).
local function leerModerna()
	local C = C_TradeSkillUI
	if not (C and C.GetAllRecipeIDs and C.GetRecipeSchematic) then return nil end
	local prof
	if C.GetBaseProfessionInfo then
		local ok, info = pcall(C.GetBaseProfessionInfo)
		prof = ok and type(info) == "table" and L(info.professionName) or nil
	end
	local recetas = {}
	for _, rid in ipairs(C.GetAllRecipeIDs() or {}) do
		local info = C.GetRecipeInfo and C.GetRecipeInfo(rid)
		if not (type(info) == "table" and L(info.learned) == false) then
			local ok, s = pcall(C.GetRecipeSchematic, rid, false)
			local producto = ok and type(s) == "table" and L(s.outputItemID)
			if producto then
				local mats, completa = {}, true
				for _, slot in ipairs(s.reagentSlotSchematics or {}) do
					local basico = slot.reagentType == nil or slot.reagentType == 1
					local r = slot.reagents and slot.reagents[1]
					local id, cant = r and L(r.itemID), L(slot.quantityRequired)
					if basico then
						if id and type(cant) == "number" then mats[#mats + 1] = { id, cant } else completa = false end
					end
				end
				if completa and #mats > 0 then recetas[producto] = { n = L(s.quantityMin) or 1, mats = mats } end
			end
		end
	end
	return prof, recetas
end

function T.LeerRecetas()
	local ok, prof, recetas = pcall(leerModerna)
	if not (ok and recetas and next(recetas)) then ok, prof, recetas = pcall(leerAntigua) end
	if not (ok and recetas and next(recetas)) then return 0 end
	T.db.recetas = T.db.recetas or {}
	local mias = T.db.recetas[personaje()] or {}
	T.db.recetas[personaje()] = mias
	local n = 0
	for producto, r in pairs(recetas) do
		r.prof = prof
		mias[producto] = r
		n = n + 1
	end
	return n, prof
end

-- Precios de los vendedores: precio por UNIDAD de lo que se compra con oro (sin otras monedas).
function T.LeerVendedor()
	if not (GetMerchantNumItems and GetMerchantItemInfo and GetMerchantItemLink) then return 0 end
	T.db.precioPNJ = T.db.precioPNJ or {}
	local n = 0
	for i = 1, (L(GetMerchantNumItems()) or 0) do
		local ok, _, _, precio, cantidad, _, _, _, extendido = pcall(GetMerchantItemInfo, i)
		local id = ok and T.ItemID(L(GetMerchantItemLink(i)))
		precio, cantidad, extendido = L(precio), L(cantidad), L(extendido)
		if id and type(precio) == "number" and precio > 0 and not extendido then
			T.db.precioPNJ[tostring(id)] = precio / ((type(cantidad) == "number" and cantidad > 0) and cantidad or 1)
			n = n + 1
		end
	end
	return n
end

local avisado = {}
local f = CreateFrame("Frame")
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
pcall(f.RegisterEvent, f, "TRADE_SKILL_UPDATE") -- evento antiguo; en Forever da error y cortaba el archivo
f:RegisterEvent("MERCHANT_SHOW")
f:SetScript("OnEvent", function(_, evento)
	if not T.db then return end
	if evento == "MERCHANT_SHOW" then
		pcall(T.LeerVendedor)
		return
	end
	local ok, n, prof = pcall(T.LeerRecetas)
	if ok and n and n > 0 and prof and not avisado[prof] then
		avisado[prof] = true
		T.Decir("Anoté " .. n .. " recetas de " .. prof .. ". /tasador fabricar te dice cuáles dejan ganancia hoy.")
	end
end)
