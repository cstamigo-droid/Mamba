-- Mamba_Combate: barra «Cerca: N» siempre a la vista (como la barra de Spy; pedido de Cristian, 19-11: "el
-- indicador de enemigos cercanos no está"). Es chica y fija; con cada jugador de la otra facción que detecta la
-- alerta del Tasador crece una fila: nombre en el color de su clase, nivel, clase y gremio. Un clic en el título
-- abre la ventana completa «Enemigos cerca» (con Muertes e Historial). Al llegar uno nuevo: aviso en pantalla
-- (y sonido si están encendidos), salvo con la alerta silenciada.
-- La detección es la del Tasador: placas de nombre de enemigos, ratón encima y objetivo. Con las placas de
-- enemigos apagadas solo detecta lo que señalas: por eso en Avisos y barras hay un interruptor que las enciende.
-- Se ve «siempre», «solo con enemigos» o «nunca» (Combate › Avisos y barras). Licencia: GPL-3.0-only.
local _, M = ...
local B = {}
M.BarraCerca = B
local FILAS, ALTO, ANCHO = 8, 15, 210

local barra
local function Cz() return M.Cercanos end

function B.Modo() return M.DB().cercaBarra or "siempre" end

function B.Crear()
	if barra then return barra end
	barra = CreateFrame("Frame", "MambaCercaBarra", UIParent)
	barra:SetSize(ANCHO, 18 + FILAS * ALTO) -- alto fijo: ver B.Dibujar
	barra:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -230, -220)
	barra:Hide()
	barra.fondo = barra:CreateTexture(nil, "BACKGROUND")
	barra.fondo:SetAllPoints(barra)
	barra.fondo:SetColorTexture(0.05, 0.05, 0.06, 0.8)
	barra.titulo = CreateFrame("Button", nil, barra)
	barra.titulo:SetPoint("TOPLEFT", barra, "TOPLEFT", 0, 0)
	barra.titulo:SetPoint("TOPRIGHT", barra, "TOPRIGHT", 0, 0)
	barra.titulo:SetHeight(18)
	barra.titulo.t = M.Piezas.Texto(barra.titulo, "small", "text")
	barra.titulo.t:SetPoint("LEFT", barra.titulo, "LEFT", 6, 0)
	barra.titulo:SetScript("OnClick", function() if Cz() then Cz().Abrir() end end)
	barra.filas = {}
	for i = 1, FILAS do
		local t = M.Piezas.Texto(barra, "small", "text")
		t:SetPoint("TOPLEFT", barra, "TOPLEFT", 6, -18 - (i - 1) * ALTO)
		t:SetPoint("RIGHT", barra, "RIGHT", -4, 0)
		t:Hide()
		barra.filas[i] = t
	end
	M.Movible(barra, "MambaCercaBarra", "Barra «Cerca»")
	return barra
end
M.Precrear(function() B.Crear() end)
M.AlModoMover(function(activo)
	B.Crear()
	if activo then
		if not barra:IsShown() then barra.ejemplo = true; barra.titulo.t:SetText("Cerca: 0 (ejemplo)"); barra:Show() end
	elseif barra.ejemplo then
		barra.ejemplo = nil
		barra:Hide()
		B.Dibujar()
	end
end)

-- Una fila: «Nombre  40 Guerrero <Gremio>» con el nombre en el color de su clase.
function B.Texto(x)
	local c = Cz()
	local nombre = (c and c.NombreColor) and c.NombreColor(x.nombre, x.claseToken) or x.nombre
	local partes = { nombre, x.nivel and tostring(x.nivel) or "??", x.clase or "" }
	if x.gremio then partes[#partes + 1] = "<" .. x.gremio .. ">" end
	return table.concat(partes, "  ")
end

function B.Dibujar()
	B.Crear()
	if barra.ejemplo then return end
	local modo = B.Modo()
	local c = Cz()
	local lista = (c and c.Recientes and c.Recientes()) or {}
	if modo == "nunca" or (modo == "conEnemigos" and #lista == 0) then barra:Hide(); B.Reloj(false); return end
	barra.titulo.t:SetText(("Cerca: %d"):format(#lista) .. ((c and c.Silenciada and c.Silenciada()) and "  (silenciada)" or ""))
	for i, t in ipairs(barra.filas) do
		local x = lista[i]
		if x then t:SetText(B.Texto(x)); t:Show() else t:Hide() end
	end
	-- el fondo crece hacia abajo con la lista; el marco (lo que se guarda y se mueve) tiene alto fijo
	barra.fondo:ClearAllPoints()
	barra.fondo:SetPoint("TOPLEFT", barra, "TOPLEFT", 0, 0)
	barra.fondo:SetPoint("TOPRIGHT", barra, "TOPRIGHT", 0, 0)
	barra.fondo:SetHeight(18 + math.min(#lista, FILAS) * ALTO)
	barra.altoVisto = 18 + math.min(#lista, FILAS) * ALTO
	barra:Show()
	-- quien deja de estar cerca (2 min) sale solo: un reloj de 5 s, solo mientras haya alguien
	B.Reloj(#lista > 0)
end
function B.Barra() return barra end

function B.Reloj(prender)
	if prender and not B.tic and C_Timer and C_Timer.NewTicker then
		B.tic = C_Timer.NewTicker(5, function() M.Proteger("barraCerca", B.Dibujar) end)
	elseif not prender and B.tic then
		B.tic:Cancel(); B.tic = nil
	end
end

-- Un enemigo NUEVO (no el que se sigue viendo): aviso en pantalla, salvo con la alerta silenciada.
-- K135/D20 (auditoría 20-11): el aviso de un enemigo nuevo lo da UNA vez la alerta del Tasador (el detector, con su
-- freno de 60 s por jugador y de sonido). La barrita no repite el aviso: solo crece. Queda la cuenta para el diag.
function B.Nuevo(x)
	B.nuevos = (B.nuevos or 0) + 1
end

-- Placas de nombre de enemigos (la tecla V del juego): con ellas la alerta detecta antes.
function B.PlacasEnemigas()
	if not GetCVar then return nil end
	local v = GetCVar("nameplateShowEnemies")
	return v == "1" or v == 1 or v == true
end
function B.EncenderPlacas(si)
	if M.EnCombate() or not SetCVar then return false end
	return pcall(SetCVar, "nameplateShowEnemies", si and "1" or "0")
end

-- Engancha la lista de vistos de Cercanos (cargado antes).
local c = M.Cercanos
if c then
	local visto = c.Visto
	function c.Visto(info)
		local nombre = type(info) == "table" and info.nombre
		local legible = type(nombre) == "string" and not M.Secreto(nombre)
		local antes = legible and c.vistos[nombre]
		local reciente = antes and ((GetTime and M.Num(GetTime()) or 0) - (antes.visto or 0) <= 120)
		visto(info)
		local x = legible and c.vistos[nombre]
		if x and not reciente then M.Proteger("barraCerca", B.Nuevo, x) end
		M.Proteger("barraCerca", B.Dibujar)
	end
end
local f = CreateFrame("Frame")
M.Escuchar(f, "PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function() M.Proteger("barraCerca", B.Dibujar) end)
M.AlCambiar(function() M.Proteger("barraCerca", B.Dibujar) end)
