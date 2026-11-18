-- Mamba_Bolsas: ordenar y apilar con un botón.
--  * Ordenar: el ordenado del propio juego (C_Container.SortBags; en el banco C_Container.SortBank o
--    SortBankBags), que además junta los montones. Es el mismo que el botón de la ventana del juego.
--  * Apilar (sin ordenar): junta los montones a medias del mismo objeto, de a un movimiento y esperando que el
--    juego suelte cada casilla. Solo fuera de combate; se corta si entras en combate o algo no se mueve.
-- Licencia: GPL-3.0-only.
local _, M = ...

function M.PuedeOrdenar(banco)
	local c = C_Container
	if not c then return false end
	if banco then return (c.SortBank or c.SortBankBags) and true or false end
	return c.SortBags and true or false
end

function M.Ordenar(banco)
	if InCombatLockdown and InCombatLockdown() then return false, "En combate no se puede ordenar." end
	local c = C_Container
	if banco then
		if not M.bancoAbierto then return false, "Habla con el banquero para ordenar el banco." end
		local tipo = Enum and Enum.BankType and Enum.BankType.Character or 0
		if c and c.SortBank then pcall(c.SortBank, tipo); return true end
		if c and c.SortBankBags then pcall(c.SortBankBags); return true end
		return M.Apilar(M.BolsasBanco())
	end
	if c and c.SortBags then pcall(c.SortBags); return true end
	return M.Apilar(M.BolsasInventario())
end

-- Movimientos que juntan montones a medias: { { desdeBolsa, desdeCasilla, haciaBolsa, haciaCasilla } }.
-- Se calcula sobre una foto: { [i] = { bolsa, casilla, id, n, max } } en el orden de las bolsas.
function M.PlanApilar(foto)
	local plan, porId = {}, {}
	for _, x in ipairs(foto) do
		if x.id and x.max and x.max > 1 and x.n < x.max then
			porId[x.id] = porId[x.id] or {}
			table.insert(porId[x.id], { bolsa = x.bolsa, casilla = x.casilla, n = x.n, max = x.max })
		end
	end
	for _, lista in pairs(porId) do
		local i, j = 1, #lista
		while i < j do
			local a, b = lista[i], lista[j]
			local cabe = a.max - a.n
			if cabe <= 0 then i = i + 1
			elseif b.n <= 0 then j = j - 1
			else
				plan[#plan + 1] = { b.bolsa, b.casilla, a.bolsa, a.casilla }
				local mueve = math.min(cabe, b.n)
				a.n, b.n = a.n + mueve, b.n - mueve
			end
		end
	end
	return plan
end

local function foto(bolsas)
	local t = {}
	for _, b in ipairs(bolsas) do
		for s = 1, M.Casillas(b) do
			local info = M.Info(b, s)
			if info then
				local max
				local f = (C_Item and C_Item.GetItemMaxStackSizeByID)
				if f then max = f(info.itemID) end
				if not max and GetItemInfo then max = select(8, GetItemInfo(info.itemID)) end
				t[#t + 1] = { bolsa = b, casilla = s, id = info.itemID, n = info.stackCount or 1, max = max, bloqueado = info.isLocked }
			end
		end
	end
	return t
end

local apilando = false
function M.Apilar(bolsas)
	if apilando then return false, "Ya estoy apilando." end
	if InCombatLockdown and InCombatLockdown() then return false, "En combate no se puede apilar." end
	local c = C_Container
	if not (c and c.PickupContainerItem and C_Timer and C_Timer.After) then return false, "Este cliente no deja mover objetos." end
	local plan = M.PlanApilar(foto(bolsas))
	if #plan == 0 then return true, "No hay montones para juntar." end
	apilando = true
	local i, vueltas = 1, 0
	local function paso()
		if i > #plan or vueltas > 200 or (InCombatLockdown and InCombatLockdown()) then
			apilando = false
			if ClearCursor then ClearCursor() end
			M.Avisar("bolsas", {})
			return
		end
		vueltas = vueltas + 1
		local m = plan[i]
		local a, b = M.Info(m[1], m[2]), M.Info(m[3], m[4])
		if (a and a.isLocked) or (b and b.isLocked) or (CursorHasItem and CursorHasItem()) then
			C_Timer.After(0.1, paso) -- el juego todavía no suelta las casillas
			return
		end
		if a then
			pcall(c.PickupContainerItem, m[1], m[2])
			pcall(c.PickupContainerItem, m[3], m[4])
			if CursorHasItem and CursorHasItem() and ClearCursor then ClearCursor() end
		end
		i = i + 1
		C_Timer.After(0.15, paso)
	end
	paso()
	return true
end
