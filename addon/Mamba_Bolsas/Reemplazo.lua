-- Mamba_Bolsas: la ventana de Mamba en lugar de las bolsas y el banco del juego.
--  * Bolsas: las ventanas del juego se cuelgan de un marco escondido (siguen existiendo, no se tocan sus
--    funciones) y cada vez que el juego quiere abrir, cerrar o alternar bolsas (tecla B, botón de la mochila,
--    vendedor, correo, banco) la ventana de Mamba hace lo mismo. Las peticiones de un mismo cuadro se juntan:
--    si hubo un "alternar", alterna una vez; si no, manda el último "abrir" o "cerrar".
--  * Banco: la ventana del banquero del juego queda abierta pero diminuta e invisible (si se escondiera, el juego
--    cerraría el banco) y se muestra la de Mamba. Al cerrar la de Mamba se cierra el banco.
--  * Con la opción "Usar la ventana de Mamba" apagada, todo vuelve a ser del juego (con la ventana unida).
--  * Si Bagnon está encendido, una sola vez: "¿Usar las bolsas de Mamba?", con un botón que apaga Bagnon y recarga.
-- Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas

local oculto = CreateFrame("Frame")
oculto:Hide()
local diminuto = CreateFrame("Frame", nil, UIParent)
diminuto:SetScale(0.001)
diminuto:SetAlpha(0)
diminuto:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1000, 1000)
diminuto:SetSize(1, 1)

function M.EsconderBancoDelJuego()
	local B = _G.BankFrame
	if B and M.Activa() and M.bancoAbierto then B:SetParent(diminuto) end
end

M.OTROS = { "Bagnon", "BagBrother", "Baganator", "AdiBags", "ArkInventory", "BetterBags", "Combuctor" }

local function otroCargado()
	local C = C_AddOns
	for _, n in ipairs(M.OTROS) do
		if C and C.IsAddOnLoaded and C.IsAddOnLoaded(n) then return n end
	end
end
M.OtroCargado = otroCargado

function M.Activa()
	return M.Op("propia") and not otroCargado()
end

---------------------------------------------------------------- abrir y cerrar
-- porJuego: la abrió el juego (vendedor, banco, correo); entonces el juego también la cierra. La que abriste tú
-- (tecla B, mochila) queda abierta cuando cierras al vendedor, como en el juego.
function M.AbrirInventario(si, porJuego)
	if not M.Activa() then return end
	local f = M.Ventana("inventario")
	if si == nil then si = not f:IsShown() end
	if si then
		if not f:IsShown() then f.porJuego = porJuego and true or false end
		f.dueno = M.Clave()
		f:Show()
	else f:Hide() end
end

-- El banco: el del banquero si está abierto, si no lo guardado de ese personaje.
function M.AbrirBanco(dueno)
	local f = M.Ventana("banco")
	f.dueno = dueno or M.Clave()
	f.sola = nil
	if f:IsShown() then M.Dibujar(f) else f:Show() end
end

local juntas = nil
local function pedir(que)
	if not M.Activa() then return end
	if juntas then
		if que == "alternar" then juntas.alternar = true else juntas.ultimo = que end
		return
	end
	juntas = { alternar = que == "alternar", ultimo = que ~= "alternar" and que or nil }
	local function resolver()
		local j = juntas
		juntas = nil
		local f = M.ventanas.inventario
		if j.alternar then M.AbrirInventario(nil)
		elseif j.ultimo == "abrir" then M.AbrirInventario(true, true)
		elseif j.ultimo == "cerrar" and f and f.porJuego then M.AbrirInventario(false) end
	end
	if C_Timer and C_Timer.After then C_Timer.After(0, resolver) else resolver() end
end
M.Pedir = pedir

local function marcosDelJuego()
	local t = {}
	local lista = ContainerFrameContainer and ContainerFrameContainer.ContainerFrames
	if type(lista) == "table" then for _, f in ipairs(lista) do t[#t + 1] = f end end
	for i = 1, (NUM_CONTAINER_FRAMES or 13) do
		local f = _G["ContainerFrame" .. i]
		if f then t[#t + 1] = f end
	end
	if ContainerFrameCombinedBags then t[#t + 1] = ContainerFrameCombinedBags end
	return t
end

local padresOriginales = {}
function M.AplicarReemplazo()
	local activa = M.Activa()
	for _, f in ipairs(marcosDelJuego()) do
		if activa then
			if not padresOriginales[f] then padresOriginales[f] = f:GetParent() or UIParent end
			f:SetParent(oculto)
		elseif padresOriginales[f] then
			f:SetParent(padresOriginales[f])
		end
	end
	if not activa then
		for _, f in pairs(M.ventanas) do f:Hide() end
		pcall(M.AplicarUnir)
	end
end

local enganchado = false
local function enganchar()
	if enganchado or not hooksecurefunc then return end
	enganchado = true
	local function gancho(nombre, que)
		if type(_G[nombre]) ~= "function" then return end
		hooksecurefunc(nombre, function()
			-- el juego también abre y cierra bolsas por dentro (modo edición, "...Manager"): eso no es del jugador
			if debugstack then
				local ok, pila = pcall(debugstack, 3)
				if ok and type(pila) == "string" and pila:find("Manager") then return end
			end
			pedir(que)
		end)
	end
	gancho("ToggleAllBags", "alternar")
	gancho("ToggleBackpack", "alternar")
	gancho("ToggleBag", "alternar")
	gancho("OpenAllBags", "abrir")
	gancho("OpenBackpack", "abrir")
	gancho("OpenBag", "abrir")
	gancho("CloseAllBags", "cerrar")
	gancho("CloseBackpack", "cerrar")
	-- el banquero
	if type(ShowUIPanel) == "function" then
		hooksecurefunc("ShowUIPanel", function(panel)
			if panel and panel == _G.BankFrame and M.Activa() then
				panel:SetParent(diminuto)
				M.AbrirBanco(M.Clave())
				M.AbrirInventario(true, true)
			end
		end)
	end
end

table.insert(M.alCambiar, function(motivo)
	if motivo == "banco-abierto" and M.Activa() then
		local B = _G.BankFrame
		if B and B.GetParent and B:GetParent() ~= diminuto then B:SetParent(diminuto) end
		M.AbrirBanco(M.Clave())
		M.AbrirInventario(true, true)
	elseif motivo == "banco-cerrado" then
		local B = _G.BankFrame
		local function devolver() if B and B.GetParent and B:GetParent() == diminuto then B:SetParent(UIParent) end end
		if C_Timer and C_Timer.After then C_Timer.After(0, devolver) else devolver() end
		local f = M.ventanas.banco
		if f and f:IsShown() and f.dueno == M.Clave() then f:Hide() end
	end
end)

---------------------------------------------------------------- Bagnon encendido: preguntar una vez
local function preguntar(otro)
	local d = M.DB()
	d.preguntado = d.preguntado or {}
	if d.preguntado[otro] then return end
	d.preguntado[otro] = true
	local f = P.Ventana("MambaBolsasOtro", "Bolsas de Mamba", 440, 210)
	local t = P.Texto(f, "body", "text")
	t:SetPoint("TOPLEFT", f, "TOPLEFT", f.margen, -(f.cuerpo + 10))
	t:SetPoint("RIGHT", f, "RIGHT", -f.margen, 0)
	if t.SetWordWrap then t:SetWordWrap(true) end
	t:SetText(otro .. " está encendido. ¿Usar las bolsas de Mamba en su lugar? Se apaga " .. otro ..
		" (puedes volver a encenderlo en la lista de accesorios) y se recarga la interfaz.")
	local si = P.Boton(f, "Usar las de Mamba", function()
		local C = C_AddOns
		for _, n in ipairs(M.OTROS) do
			if C and C.DisableAddOn and C.IsAddOnLoaded and C.IsAddOnLoaded(n) then pcall(C.DisableAddOn, n) end
		end
		if C and C.DisableAddOn then pcall(C.DisableAddOn, "BagBrother") end
		M.DB().opciones.propia = true
		if ReloadUI then ReloadUI() end
	end, true)
	si:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -f.margen, 16)
	local no = P.Boton(f, "Ahora no", function() f:Hide() end)
	no:SetPoint("RIGHT", si, "LEFT", -8, 0)
	f:Show()
end

function M.Iniciar()
	M.Ventana("inventario")
	M.Ventana("banco")
	enganchar()
	M.AplicarReemplazo()
	local otro = otroCargado()
	if otro and M.Op("propia") then preguntar(otro) end
	local api = _G.MambaAPI
	if api and api.AlRestablecer then
		api.AlRestablecer(function()
			for _, f in pairs(M.ventanas) do if f:IsShown() then M.Dibujar(f) end end
		end)
	end
end
