-- Mamba_Comodidades: sus dos partes en Interfaz (la ventana de Mamba, menú de Polestar):
--   "Raros y tesoros": la ruta de la zona, el macro de apuntado y sus opciones (K70);
--   "Comodidades": un interruptor por comodidad y los sonidos que se pueden silenciar (K71, K83).
-- Todo con botones, sin comandos. Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas
local R, C = M.Raros, M.Comodidades

local format = string.format
local elegidoR, elegidoC = "ruta", "interruptores"
local paneles = {}

---------------------------------------------------------------- piezas comunes
local function lista(padre)
	local _, _, W = P.Polestar()
	local sf, hijo
	if W and W.Scroll then sf = W.Scroll(padre); hijo = sf.Child
	else
		sf = CreateFrame("ScrollFrame", nil, padre)
		hijo = CreateFrame("Frame", nil, sf)
		sf:SetScrollChild(hijo)
		sf:EnableMouseWheel(true)
		sf:SetScript("OnMouseWheel", function(self, d) self:SetVerticalScroll(math.max(0, self:GetVerticalScroll() - d * 48)) end)
	end
	return sf, hijo
end

local function alto(sf, h)
	local _, _, W = P.Polestar()
	if W and W.SetScrollContent then W.SetScrollContent(sf, h + 8, sf:GetHeight()) end
end

local function ayuda(f, titulo, texto)
	f:SetScript("OnEnter", function(self)
		local A = _G.Asistente
		if A and A.CuadroAyuda then A.CuadroAyuda(self, titulo, { texto }) end
	end)
	f:SetScript("OnLeave", function()
		local A = _G.Asistente
		if A and A.OcultarAyuda then A.OcultarAyuda() end
	end)
end

-- Una página de interruptores (filas de Polestar) dentro de `padre`. Devuelve el alto usado.
local function interruptores(padre, items, ancho, y)
	for _, it in ipairs(items) do
		local fila = P.Interruptor(padre, it.titulo, it.ayuda,
			function() return C.Valor(it) and true or false end,
			function(v) C.Poner(it, v); if M.RefrescarPanel then pcall(M.RefrescarPanel) end end)
		fila:SetPoint("TOPLEFT", padre, "TOPLEFT", 0, -y)
		y = y + P.Acomodar(fila, ancho) + 4
		if not C.Disponible(it) then
			local n = P.Texto(padre, "note", "textMuted")
			n:SetPoint("TOPLEFT", padre, "TOPLEFT", 12, -y)
			n:SetText(it.tipo == "brillo" and "Falta el brillo de ForeverLootSparkles: actívalo en la lista de complementos."
				or "No disponible: falta Polestar.")
			y = y + 18
		end
	end
	return y
end

---------------------------------------------------------------- Raros y tesoros
local raros = {}

local function filaRaro(i, ancho)
	local f = raros.filas[i]
	if not f then
		f = P.Fila(raros.hijo, ancho, 24)
		f.num = P.Texto(f, "number", "textDim")
		f.num:SetPoint("LEFT", f, "LEFT", 10, 0)
		f.der = P.Texto(f, "small", "textDim")
		f.der:SetPoint("RIGHT", f, "RIGHT", -10, 0)
		f.izq = P.Texto(f, "body", "text")
		f.izq:SetPoint("LEFT", f, "LEFT", 38, 0)
		f.izq:SetPoint("RIGHT", f.der, "LEFT", -8, 0)
		if f.izq.SetWordWrap then f.izq:SetWordWrap(false) end
		f:SetScript("OnClick", function(self)
			if self.punto then
				R.Llevame(self.punto)
				R.Decir("flecha a " .. self.punto.rec.name .. ".")
			end
		end)
		ayuda(f, "Llévame", "Clic: la flecha de Polestar te lleva a este raro.")
		raros.filas[i] = f
	end
	f:SetWidth(ancho)
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", raros.hijo, "TOPLEFT", 0, -(i - 1) * 26)
	f:Show()
	return f
end

local function nivelTexto(rec)
	if rec.kind == "treasure" then return "tesoro" end
	local lo, hi = rec.level, rec.levelMax
	local t = lo and ("nivel " .. lo .. ((hi and hi ~= lo) and ("-" .. hi) or "")) or "raro"
	return t .. (rec.elite and " élite" or "")
end

local function pintarRuta()
	local r = R.ruta
	if not r.orden or (#r.orden == 0 and not r.motivo) then r = R.Calcular() end
	local zona = R.NombreZona(r.zona or R.Zona())
	raros.titulo:SetText("Raros de " .. zona)
	if #r.orden == 0 then
		raros.resumen:SetText(r.motivo or "No hay raros conocidos en esta zona para tu nivel.")
		raros.alt:SetText("")
	else
		-- R0: la ganadora con su número y la que sigue
		raros.resumen:SetText(format("Ruta corta: %d %s · %s · %s a pie, %s con montura",
			#r.orden, #r.orden == 1 and "raro" or "raros", R.MetrosTexto(r.total),
			R.Minutos(r.total, R.A_PIE), R.Minutos(r.total, R.MONTADO)))
		local ahorro = (r.ingenuo or 0) - r.total
		raros.alt:SetText(ahorro > 50 and format("Yendo siempre al más cercano serían %s: esta ruta ahorra %s.",
			R.MetrosTexto(r.ingenuo), R.MetrosTexto(ahorro))
			or "Ir siempre al más cercano da lo mismo en esta zona.")
	end
	raros.empezar:SetShown(not r.activa and #r.orden > 0)
	raros.siguiente:SetShown(r.activa and true or false)
	raros.detener:SetShown(r.activa and true or false)
	local ancho = math.max(300, (raros.sf:GetWidth() or 600) - 14)
	local yo = R.Aqui()
	for i, p in ipairs(r.orden) do
		local f = filaRaro(i, ancho)
		f.punto = p
		local actual = r.activa and r.i == i
		f.num:SetText(i)
		f.izq:SetText(actual and P.Color("titulo", p.rec.name) or p.rec.name)
		local d = yo and R.Metros(yo, p.spawn)
		f.der:SetText((actual and "vas aquí · " or "") .. nivelTexto(p.rec) .. (d and (" · " .. R.MetrosTexto(d)) or ""))
	end
	for i = #r.orden + 1, #raros.filas do raros.filas[i]:Hide() end
	raros.hijo:SetHeight(math.max(1, #r.orden * 26))
	alto(raros.sf, #r.orden * 26)
end

local function pintarMacro()
	local u = R.ultimo
	if not u.texto and R.Opciones().macro then R.ActualizarMacro() end
	u = R.ultimo
	if u.texto then
		raros.mEstado:SetText(format("El macro %s apunta a %d de los %d raros de %s, el más cercano primero.",
			R.MACRO, u.cuantos, u.total, R.NombreZona(u.zona)) .. (u.cuantos < u.total and " Los demás no caben: un macro tiene 255 letras." or ""))
		raros.mTexto:SetText(u.texto)
	elseif not R.Opciones().macro then
		raros.mEstado:SetText("El macro automático está apagado. Enciéndelo arriba o aprieta \"Actualizar ahora\".")
		raros.mTexto:SetText("")
	else
		raros.mEstado:SetText(u.motivo or "Sin datos aún: entra a una zona con raros, fuera de combate.")
		raros.mTexto:SetText("")
	end
end

local function dibujarRaros(p, ancho, alto_)
	raros.filas = {}
	raros.titulo = P.Texto(p, "heading", "accent")
	raros.titulo:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -8)
	-- página Ruta
	raros.ruta = CreateFrame("Frame", nil, p)
	raros.ruta:SetPoint("TOPLEFT", raros.titulo, "BOTTOMLEFT", -12, -6)
	raros.ruta:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
	raros.resumen = P.Texto(raros.ruta, "body", "text")
	raros.resumen:SetPoint("TOPLEFT", raros.ruta, "TOPLEFT", 12, 0)
	raros.resumen:SetWidth(ancho - 40)
	raros.alt = P.Texto(raros.ruta, "note", "textMuted")
	raros.alt:SetPoint("TOPLEFT", raros.resumen, "BOTTOMLEFT", 0, -4)
	raros.alt:SetWidth(ancho - 40)
	raros.empezar = P.Boton(raros.ruta, "Empezar ruta", function() R.Empezar() end, true)
	raros.empezar:SetPoint("TOPLEFT", raros.alt, "BOTTOMLEFT", 0, -10)
	raros.siguiente = P.Boton(raros.ruta, "Siguiente raro", function() R.Siguiente() end, true)
	raros.siguiente:SetPoint("TOPLEFT", raros.alt, "BOTTOMLEFT", 0, -10)
	raros.detener = P.Boton(raros.ruta, "Detener", function() R.Detener() end)
	raros.detener:SetPoint("LEFT", raros.siguiente, "RIGHT", 8, 0)
	local recalcular = P.Boton(raros.ruta, "Recalcular desde aquí", function() R.Calcular(); M.RefrescarPanel() end)
	recalcular:SetPoint("TOP", raros.empezar, "TOP", 0, 0)
	recalcular:SetPoint("RIGHT", raros.ruta, "RIGHT", -12, 0)
	raros.sf, raros.hijo = lista(raros.ruta)
	raros.sf:SetPoint("TOPLEFT", raros.empezar, "BOTTOMLEFT", -12, -10)
	raros.sf:SetPoint("BOTTOMRIGHT", raros.ruta, "BOTTOMRIGHT", -8, 8)
	raros.hijo:SetWidth(ancho - 30)
	-- página Macro
	raros.macro = CreateFrame("Frame", nil, p)
	raros.macro:SetPoint("TOPLEFT", raros.titulo, "BOTTOMLEFT", -12, -6)
	raros.macro:SetSize(ancho - 20, 360)
	local o = R.Opciones()
	local auto = P.Interruptor(raros.macro, "Mantener el macro al día solo",
		"Al cambiar de zona y al ver un raro, Mamba reescribe el macro MambaRaros con los raros de la zona.",
		function() return o.macro end, function(v) o.macro = v and true or false; if v then R.ActualizarMacro() end; M.RefrescarPanel() end)
	auto:SetPoint("TOPLEFT", raros.macro, "TOPLEFT", 0, 0)
	local y = P.Acomodar(auto, ancho - 30) + 8
	raros.mEstado = P.Texto(raros.macro, "body", "text")
	raros.mEstado:SetPoint("TOPLEFT", raros.macro, "TOPLEFT", 12, -y)
	raros.mEstado:SetWidth(ancho - 50)
	local poner = P.Boton(raros.macro, "Ponerlo en mi barra", function()
		local ok, motivo = R.AlCursor()
		R.Decir(ok and "suelta el macro en un botón de tu barra." or motivo)
	end, true)
	poner:SetPoint("TOPLEFT", raros.mEstado, "BOTTOMLEFT", 0, -10)
	ayuda(poner, "Ponerlo en mi barra", "Toma el macro con el ratón: suéltalo en cualquier botón de tus barras.")
	local ya = P.Boton(raros.macro, "Actualizar ahora", function()
		local ok, motivo = R.ActualizarMacro(true)
		if not ok and motivo then R.Decir(motivo) end
		M.RefrescarPanel()
	end)
	ya:SetPoint("LEFT", poner, "RIGHT", 8, 0)
	raros.mTexto = P.Texto(raros.macro, "small", "textDim")
	raros.mTexto:SetPoint("TOPLEFT", poner, "BOTTOMLEFT", 0, -12)
	raros.mTexto:SetWidth(ancho - 50)
	-- página Opciones
	raros.opciones = CreateFrame("Frame", nil, p)
	raros.opciones:SetPoint("TOPLEFT", raros.titulo, "BOTTOMLEFT", -12, -6)
	raros.opciones:SetSize(ancho - 20, 300)
	local items = {
		{ "miniatura", "La cara del raro en el aviso", "Cuando Polestar avisa de un raro, su cara sale a la izquierda del aviso." },
		{ "tesoros", "Sumar los tesoros a la ruta", "La ruta también pasa por los cofres y tesoros de la zona." },
		{ "grises", "Incluir los que ya no dan experiencia", "Raros de nivel gris para ti: su botín igual puede servir." },
	}
	local yy = 0
	for _, it in ipairs(items) do
		local f = P.Interruptor(raros.opciones, it[2], it[3], function() return o[it[1]] end,
			function(v) o[it[1]] = v and true or false; R.Calcular(); M.RefrescarPanel() end)
		f:SetPoint("TOPLEFT", raros.opciones, "TOPLEFT", 0, -yy)
		yy = yy + P.Acomodar(f, ancho - 30) + 4
	end
	local muestra = P.Boton(raros.opciones, "Ver un aviso de prueba", function()
		local Ra = _G.Polestar and _G.Polestar.Rares
		if Ra and Ra.ShowSample then Ra.ShowSample() end
	end)
	muestra:SetPoint("TOPLEFT", raros.opciones, "TOPLEFT", 12, -(yy + 8))
	local polestar = P.Boton(raros.opciones, "Abrir Raros de Polestar", function()
		local Ra = _G.Polestar and _G.Polestar.Rares
		if Ra and Ra.Show then Ra.Show() end
	end)
	polestar:SetPoint("LEFT", muestra, "RIGHT", 8, 0)
	ayuda(polestar, "Raros de Polestar", "Su botín, dónde aparecen y cuándo los viste.")
	M.RefrescarPanel()
end

local function refrescarRaros()
	if not raros.titulo then return end
	raros.ruta:SetShown(elegidoR == "ruta")
	raros.macro:SetShown(elegidoR == "macro")
	raros.opciones:SetShown(elegidoR == "opciones")
	if elegidoR == "ruta" then pintarRuta()
	elseif elegidoR == "macro" then raros.titulo:SetText("Macro de apuntado"); pintarMacro()
	else raros.titulo:SetText("Opciones de raros") end
end

---------------------------------------------------------------- Comodidades
local como = {}

local function dibujarComo(p, ancho)
	como.titulo = P.Texto(p, "heading", "accent")
	como.titulo:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -8)
	como.sub = P.Texto(p, "note", "textMuted")
	como.sub:SetPoint("TOPLEFT", como.titulo, "BOTTOMLEFT", 0, -4)
	como.sub:SetWidth(ancho - 40)
	como.inter = CreateFrame("Frame", nil, p)
	como.inter:SetPoint("TOPLEFT", como.sub, "BOTTOMLEFT", -12, -10)
	como.inter:SetSize(ancho - 20, 420)
	como.inter:SetHeight(interruptores(como.inter, C.LISTA, ancho - 30, 0))
	como.son = CreateFrame("Frame", nil, p)
	como.son:SetPoint("TOPLEFT", como.sub, "BOTTOMLEFT", -12, -10)
	como.son:SetSize(ancho - 20, 300)
	local y = interruptores(como.son, C.Sonidos(), ancho - 30, 0)
	if not _G.MuteSoundFile then
		local n = P.Texto(como.son, "note", "warning")
		n:SetPoint("TOPLEFT", como.son, "TOPLEFT", 12, -(y + 6))
		n:SetText("Tu juego no permite silenciar sonidos: estos interruptores no hacen nada.")
	end
end

local function refrescarComo()
	if not como.titulo then return end
	como.inter:SetShown(elegidoC == "interruptores")
	como.son:SetShown(elegidoC == "sonidos")
	if elegidoC == "sonidos" then
		como.titulo:SetText("Silenciar sonidos")
		como.sub:SetText("Cada grupo se calla al instante y vuelve a sonar al apagarlo.")
	else
		como.titulo:SetText("Comodidades")
		como.sub:SetText("Cada una se enciende y se apaga sola. Son los mismos ajustes de Polestar, en un solo lugar.")
	end
	for _, f in ipairs({ como.inter, como.son }) do
		for _, h in ipairs({ f:GetChildren() }) do if h.Refresh then pcall(h.Refresh, h) end end
	end
end

---------------------------------------------------------------- registro
function M.RefrescarPanel()
	pcall(refrescarRaros)
	pcall(refrescarComo)
end

function M.Registrar()
	local I = _G.MambaInterfaz
	if not I then return false end
	-- el color del raro actual va dentro del texto: se vuelve a escribir al cambiar de apariencia (E3)
	local A = _G.Asistente
	if A and A.AlCambiarApariencia then pcall(A.AlCambiarApariencia, function() pcall(M.RefrescarPanel) end) end
	I.Agregar({
		clave = "raros", titulo = "Raros y tesoros", orden = 5,
		items = function()
			local n = R.ruta and R.ruta.orden and #R.ruta.orden or 0
			return { { key = "ruta", label = "Ruta de la zona", count = n > 0 and n or nil },
				{ key = "macro", label = "Macro de apuntado" }, { key = "opciones", label = "Opciones" } }
		end,
		activo = function() return elegidoR end,
		elegir = function(k) elegidoR = k end,
		dibujar = dibujarRaros,
		refrescar = refrescarRaros,
	})
	I.Agregar({
		clave = "comodidades", titulo = "Comodidades", orden = 6,
		items = function() return { { key = "interruptores", label = "Interruptores" }, { key = "sonidos", label = "Silenciar sonidos" } } end,
		activo = function() return elegidoC end,
		elegir = function(k) elegidoC = k end,
		dibujar = dibujarComo,
		refrescar = refrescarComo,
	})
	return true
end
