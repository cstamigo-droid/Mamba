-- Mamba_Bolsas: el banco cuenta (fila K102).
--  1) Lo que tienes, contando el banco y tus otros personajes, para Tasador, Mi plan (K60 "lo que ya tienes"),
--     Dinero y quien lo pida (solo lectura; el banco se guarda al abrirlo, Bolsas.lua):
--       MambaBolsas.Tengo(itemID) -> { bolsas = n, banco = n, otros = n, total = n, bancoVisto = "dd-mm-aaaa" | nil }
--       MambaBolsas.Banco(clave?) -> { [itemID] = n } del banco guardado (tuyo por defecto), o nil si nunca se vio
--  2) Agrandar el banco: cuánto cuesta la próxima pestaña, si conviene AHORA (R0, con números) y un botón que muestra
--     la compra del propio juego. El clic que paga lo das tú, en el botón del juego.
-- Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas
local PIE_COMPRA = 30 -- la línea de la compra va justo sobre el pie

function M.Tengo(id)
	local yo = M.Clave()
	local out = { bolsas = 0, banco = 0, otros = 0, total = 0 }
	if not id then return out end
	for k, p in pairs(M.DB().personajes) do
		local b = p.bolsas and p.bolsas[id] or 0
		local n = p.banco and p.banco[id] or 0
		if k == yo then
			out.bolsas, out.banco, out.bancoVisto = b, n, p.fechaBanco
		else out.otros = out.otros + b + n end
	end
	out.total = out.bolsas + out.banco + out.otros
	return out
end

function M.Banco(clave)
	local p = M.DB().personajes[clave or M.Clave()]
	return p and p.banco or nil
end

---------------------------------------------------------------- agrandar el banco
local function tipo() return Enum and Enum.BankType and Enum.BankType.Character or 0 end

-- Costo (cobre) de la próxima pestaña del banco, o nil si no se puede comprar más (o el cliente no lo dice).
function M.CostoPestana()
	local B = C_Bank
	if B and B.CanPurchaseBankTab then
		local ok, puede = pcall(B.CanPurchaseBankTab, tipo())
		if ok and not puede then return nil end
	end
	if B and B.FetchNextPurchasableBankTabData then
		local ok, d = pcall(B.FetchNextPurchasableBankTabData, tipo())
		if ok and type(d) == "table" and d.tabCost then return d.tabCost end
	end
	if GetBankSlotCost and GetNumBankSlots then -- el banco de antes: casillas para bolsas
		local ok, n = pcall(GetNumBankSlots)
		local okC, c = pcall(GetBankSlotCost, ok and n or 0)
		if okC and c and c > 0 then return c end
	end
	return nil
end

-- ¿Conviene comprar la pestaña ahora? R0: con números y la meta que primero se atrasa.
-- -> { conviene = bool, texto = "...", costo, libres, oro }
function M.ConsejoPestana(libresBanco)
	local costo = M.CostoPestana()
	if not costo then return nil end
	local oro = GetMoney and GetMoney() or 0
	local dinero = M.Dinero
	local r = { costo = costo, libres = libresBanco, oro = oro }
	if oro < costo then
		r.conviene = false
		r.texto = ("Cuesta %s y tienes %s: te faltan %s."):format(dinero(costo), dinero(oro), dinero(costo - oro))
		return r
	end
	local plan = _G.MambaPlan
	if plan and plan.Estado and plan.RetrasaMontura then
		local okE, e = pcall(plan.Estado)
		if okE and e then
			local ok, retrasa, falta = pcall(plan.RetrasaMontura, e, costo)
			if ok and retrasa then
				r.conviene = false
				r.texto = ("Espera: %s te atrasa la montura (después te faltarían %s). Tienes %d casillas libres en el banco."):format(dinero(costo), dinero(falta or 0), libresBanco)
				return r
			end
		end
	end
	local pct = math.floor(costo / math.max(1, oro) * 100 + 0.5)
	if libresBanco <= 4 then
		r.conviene = true
		r.texto = ("Conviene: te quedan %d casillas libres en el banco. Cuesta %s (%d %% de tu oro) y no atrasa tus metas."):format(libresBanco, dinero(costo), pct)
	else
		r.conviene = false
		r.texto = ("Todavía no hace falta: tienes %d casillas libres en el banco. Cuando queden 4 o menos, %s (%d %% de tu oro hoy)."):format(libresBanco, dinero(costo), pct)
	end
	return r
end

-- La compra del propio juego: se muestra la ventana del banquero del juego, donde está su botón de comprar.
function M.MostrarCompraDelJuego()
	local B = _G.BankFrame
	if not (B and M.bancoAbierto) then return false end
	M.pestanasAntes = #M.BolsasBanco()
	B:SetParent(UIParent)
	M.compraVisible = true
	return true
end

-- En la ventana del banco (en vivo): una línea con el consejo y el botón. Devuelve el alto que ocupa.
function M.DibujarCompra(f)
	if f.tipo ~= "banco" then return 0 end
	if not f.compra then
		f.compra = CreateFrame("Frame", nil, f)
		f.compra:SetHeight(28)
		f.compra.boton = P.Boton(f.compra, "Comprar pestaña", function()
			if M.MostrarCompraDelJuego() and f.compra.nota then
				f.compra.nota:SetText("Aprieta el botón de comprar en la ventana del banquero del juego.")
			end
		end)
		f.compra.boton:SetPoint("RIGHT", f.compra, "RIGHT", 0, 0)
		f.compra.nota = P.Texto(f.compra, "note", "textDim")
		f.compra.nota:SetPoint("LEFT", f.compra, "LEFT", 0, 0)
		f.compra.nota:SetPoint("RIGHT", f.compra.boton, "LEFT", -8, 0)
		if f.compra.nota.SetWordWrap then f.compra.nota:SetWordWrap(true) end
	end
	local c = M.EsVivo(f) and M.ConsejoPestana(f.libresT or 0) or nil
	f.consejo = c
	if not c then f.compra:Hide(); return 0 end
	f.compra:ClearAllPoints()
	f.compra:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", f.margen, PIE_COMPRA)
	f.compra:SetPoint("RIGHT", f, "RIGHT", -f.margen, 0)
	f.compra.nota:SetText(c.texto)
	f.compra.boton.texto = "Comprar pestaña · " .. M.Dinero(c.costo)
	if f.compra.boton.Label and f.compra.boton.Label.SetText then f.compra.boton.Label:SetText(f.compra.boton.texto)
	elseif f.compra.boton.SetText then f.compra.boton:SetText(f.compra.boton.texto) end
	if f.compra.boton.SetEnabled then f.compra.boton:SetEnabled(c.oro >= c.costo) end
	f.compra:Show()
	return 34
end

-- Comprada la pestaña (hay una más), la ventana del banquero del juego vuelve a esconderse.
table.insert(M.alCambiar, function(motivo)
	if not M.compraVisible then return end
	if motivo == "banco-cerrado" then M.compraVisible = false; return end
	if motivo ~= "bolsas" then return end
	if #M.BolsasBanco() > (M.pestanasAntes or 0) then
		M.compraVisible = false
		if M.EsconderBancoDelJuego then M.EsconderBancoDelJuego() end
	end
end)
