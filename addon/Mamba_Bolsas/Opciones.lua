-- Mamba_Bolsas: su parte en Interfaz (menú de Polestar): buscar en todos tus personajes, ver qué lleva cada
-- uno y las opciones de la ventana de bolsas. Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas

local elegido = "buscar"
local panel, buscador, opciones, filas, hijo, sf, sfOp = nil, nil, nil, {}, nil, nil, nil
local texto = ""

local function abrirBolsas()
	if M.Activa and M.Activa() then M.AbrirInventario(nil)
	elseif ToggleAllBags then ToggleAllBags() elseif OpenAllBags then OpenAllBags() end
end

local function fila(i, ancho)
	local f = filas[i]
	if not f then
		f = P.Fila(hijo, ancho, 22)
		f.izq = P.Texto(f, "body", "text")
		f.izq:SetPoint("LEFT", f, "LEFT", 10, 0)
		f.der = P.Texto(f, "small", "textDim")
		f.der:SetPoint("RIGHT", f, "RIGHT", -10, 0)
		f:SetScript("OnEnter", function(self)
			if self.item and GameTooltip and GameTooltip.SetItemByID then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetItemByID(self.item)
				GameTooltip:Show()
			end
		end)
		f:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
		filas[i] = f
	end
	f:SetWidth(ancho)
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", hijo, "TOPLEFT", 0, -(i - 1) * 24)
	f:Show()
	return f
end

local function lista(datos)
	local ancho = math.max(300, (sf:GetWidth() or 600) - 14)
	for i, d in ipairs(datos) do
		local f = fila(i, ancho)
		f.izq:SetText(d[1])
		f.der:SetText(d[2] or "")
		f.item = d[3]
	end
	for i = #datos + 1, #filas do filas[i]:Hide() end
	hijo:SetHeight(math.max(1, #datos * 24))
	local _, _, W = P.Polestar()
	if W and W.SetScrollContent then W.SetScrollContent(sf, #datos * 24 + 8, sf:GetHeight()) end
end

function M.RefrescarPanel()
	if not panel then return end
	buscador:SetShown(elegido == "buscar")
	sfOp:SetShown(elegido == "opciones")
	sf:SetShown(elegido ~= "opciones")
	if elegido == "buscar" then
		local datos = {}
		for i, r in ipairs(M.Buscar(texto)) do
			if i > 200 then break end
			local d = {}
			for _, x in ipairs(r.donde) do d[#d + 1] = x.nombre .. " " .. (x.bolsas + x.banco) end
			datos[#datos + 1] = { r.nombre, r.total .. " · " .. table.concat(d, ", "), r.id }
		end
		lista(datos)
	elseif elegido ~= "opciones" then
		local p = M.DB().personajes[elegido]
		local datos = {}
		if p then
			local ids = {}
			for id, n in pairs(p.bolsas or {}) do ids[id] = (ids[id] or 0) + n end
			for id, n in pairs(p.banco or {}) do ids[id] = (ids[id] or 0) + n end
			for id, n in pairs(ids) do
				local nombre = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or ("objeto " .. id)
				local enBanco = p.banco and p.banco[id]
				datos[#datos + 1] = { nombre, n .. (enBanco and (" (banco " .. enBanco .. ")") or ""), id }
			end
			table.sort(datos, function(a, b) return a[1] < b[1] end)
			table.insert(datos, 1, { "Oro: " .. (M.Dinero and M.Dinero(p.oro) or tostring(p.oro)),
				"bolsas vistas el " .. (p.fecha or "?") .. (p.fechaBanco and (" · banco el " .. p.fechaBanco) or " · banco: ábrelo una vez") })
		end
		lista(datos)
	end
end

function M.Dinero(c)
	c = math.floor(c or 0)
	return ("%d o %d p"):format(math.floor(c / 10000), math.floor(c / 100) % 100)
end

local function dibujar(p, ancho, alto)
	panel = p
	local t = P.Texto(p, "heading", "accent")
	t:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -8)
	t:SetText("Bolsas")
	local abrir = P.Boton(p, "Abrir mis bolsas", abrirBolsas, true)
	abrir:SetPoint("TOPRIGHT", p, "TOPRIGHT", -12, -4)
	local banco = P.Boton(p, "Ver mi banco", function() if M.AbrirBanco then M.AbrirBanco(M.Clave()) end end)
	banco:SetPoint("RIGHT", abrir, "LEFT", -8, 0)
	local A = _G.Asistente
	if A and A.Buscador then
		buscador = A.Buscador(p, "Buscar en todos mis personajes", function(x) texto = x; M.RefrescarPanel() end)
	else
		buscador = CreateFrame("EditBox", nil, p)
		buscador:SetAutoFocus(false)
		buscador:SetScript("OnTextChanged", function(self) texto = self:GetText() or ""; M.RefrescarPanel() end)
	end
	buscador:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -10)
	buscador:SetSize(ancho - 40, 24)
	local _, _, W = P.Polestar()
	if W and W.Scroll then sf = W.Scroll(p); hijo = sf.Child
	else
		sf = CreateFrame("ScrollFrame", nil, p)
		hijo = CreateFrame("Frame", nil, sf)
		sf:SetScrollChild(hijo)
		sf:EnableMouseWheel(true)
		sf:SetScript("OnMouseWheel", function(self, d) self:SetVerticalScroll(math.max(0, self:GetVerticalScroll() - d * 48)) end)
	end
	sf:SetPoint("TOPLEFT", t, "BOTTOMLEFT", -12, -44)
	sf:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -8, 8)
	hijo:SetWidth(ancho - 30)
	-- las opciones en su propio desplazamiento: son más de las que caben en el alto del menú
	if W and W.Scroll then sfOp = W.Scroll(p); opciones = sfOp.Child
	else
		sfOp = CreateFrame("ScrollFrame", nil, p)
		opciones = CreateFrame("Frame", nil, sfOp)
		sfOp:SetScrollChild(opciones)
		sfOp:EnableMouseWheel(true)
		sfOp:SetScript("OnMouseWheel", function(self, dl) self:SetVerticalScroll(math.max(0, self:GetVerticalScroll() - dl * 48)) end)
	end
	sfOp:SetPoint("TOPLEFT", t, "BOTTOMLEFT", -12, -10)
	sfOp:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -8, 8)
	opciones:SetWidth(ancho - 30)
	local d = M.DB().opciones
	local anterior
	local altoOp = 0
	local function poner(fila)
		if anterior then fila:SetPoint("TOPLEFT", anterior, "BOTTOMLEFT", 0, -4) else fila:SetPoint("TOPLEFT", opciones, "TOPLEFT", 0, 0) end
		altoOp = altoOp + (P.Acomodar(fila, ancho - 40) or 30) + 4
		anterior = fila
	end
	local function redibujar() if M.Redibujar then M.Redibujar() end end
	local function interruptor(etiqueta, ayuda, k, despues)
		poner(P.Interruptor(opciones, etiqueta, ayuda, function() return d[k] end,
			function(v) d[k] = v and true or false; if despues then pcall(despues) end; redibujar() end))
	end
	local function deslizador(etiqueta, ayuda, k, min, max, paso, formato)
		poner(P.Deslizador(opciones, etiqueta, ayuda, min, max, paso, formato, function() return d[k] end,
			function(v) d[k] = v; redibujar() end))
	end
	interruptor("Usar la ventana de bolsas de Mamba", "Todas tus bolsas y el banco en la ventana de Mamba: barra de bolsas, filtros, buscador, ordenar y los otros personajes. Apagado: las bolsas del juego.", "propia", function()
		if M.AplicarReemplazo then M.AplicarReemplazo() end
	end)
	deslizador("Columnas de las bolsas", nil, "columnas", 6, 24, 1, "%d")
	deslizador("Columnas del banco", nil, "columnasBanco", 6, 24, 1, "%d")
	deslizador("Tamaño de las casillas", nil, "tamano", 26, 48, 1, "%d")
	deslizador("Escala de la ventana", nil, "escala", 0.6, 1.5, 0.05, "%.2f")
	deslizador("Transparencia", "Qué tanto se ve la ventana (1 = nada transparente).", "fondo", 0.3, 1, 0.05, "%.2f")
	interruptor("Bloquear la posición", "La ventana de bolsas y la del banco no se arrastran. El candado de Ajustes › Mamba › Ventanas también las fija.", "fija", function()
		if M.AplicarFija then M.AplicarFija() end
	end)
	interruptor("Mostrar la fila de bolsas", "Arriba de las casillas: cada bolsa con sus casillas libres. Clic en una: verla sola.", "verBolsas")
	interruptor("Separar las bolsas", "Con todas juntas, cada bolsa empieza en una fila nueva.", "separar")
	interruptor("Bolsas al revés", "La mochila al final, como en la barra del juego.", "reves")
	interruptor("Marcas sobre los objetos", "Basura, para vender, subastar o guardar (lo que marcas con Alt + clic derecho o Ctrl + Alt + clic) y los objetos de misión.", "marcas")
	interruptor("Brillo de las mejoras", "Flecha y brillo verde en el equipo que es mejor que el tuyo.", "mejora")
	interruptor("Resaltar lo nuevo", "Lo que acaba de entrar a tus bolsas brilla hasta que pasas el ratón.", "nuevo")
	interruptor("Decir en el cuadro del objeto cuántos tienes y dónde", nil, "cuadro")
	interruptor("Sin la ventana de Mamba: la ventana unida del juego", "Solo cuenta con la de Mamba apagada.", "unir", function() if not d.propia then M.AplicarUnir() end end)
	if M.OtroCargado and M.OtroCargado() then
		local n = P.Texto(opciones, "note", "warning")
		n:SetPoint("TOPLEFT", anterior, "BOTTOMLEFT", 12, -8)
		n:SetText(M.OtroCargado() .. " está encendido: mientras lo esté, se usan sus bolsas.")
	end
	M.RefrescarPanel()
end

function M.Registrar()
	local I = _G.MambaInterfaz
	if not I then return end
	I.Agregar({
		clave = "bolsas", titulo = "Bolsas", orden = 2,
		items = function()
			local it = { { key = "buscar", label = "Buscar en todos" } }
			local ks = {}
			for k in pairs(M.DB().personajes) do ks[#ks + 1] = k end
			table.sort(ks)
			for _, k in ipairs(ks) do it[#it + 1] = { key = k, label = k:match("^(.-) %-") or k } end
			it[#it + 1] = { key = "opciones", label = "Opciones" }
			return it
		end,
		activo = function() return elegido end,
		elegir = function(k) elegido = k end,
		dibujar = dibujar,
		refrescar = function() M.RefrescarPanel() end,
	})
end
