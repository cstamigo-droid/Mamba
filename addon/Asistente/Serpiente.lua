-- Asistente/Serpiente.lua: la mamba negra del encabezado (fila K63 de MAMBA_ACEPTACION.md).
-- Cristian, 18-11: "una mamba negra que esté en movimiento bordeando el POLESTAR… cuida la estética".
-- Una serpiente fina (gris pizarra casi negro, reflejo oliva y filos acerados) da una vuelta al logotipo
-- POLESTAR de la ventana de Mamba, baja por la derecha y se acuesta en una S suave junto a la palabra "Mamba"
-- (f.MambaMarca, parche P12-encabezado), donde saca la lengua y se desvanece. Un ciclo dura 11,8 s.
--   * Texturas PROPIAS dibujadas con fórmulas: tools/asistente/serpiente_texturas.py -> Media/serpiente-*.tga.
--   * El cuerpo son discos que se adelgazan hacia la cola, rotados según la tangente; la huella ondula fija en
--     el espacio, así el cuerpo pasa por donde pasó la cabeza (como una serpiente de verdad).
--   * Corre solo con la ventana abierta (el OnUpdate vive en su barra lateral), se queda quieta en combate y,
--     con "Reducir movimiento" de Polestar, queda acostada junto a "Mamba" sin moverse.
--   * Interruptor: Ajustes › Mamba › Ventanas › "Serpiente animada".
-- La maqueta y la revisión de dirección de arte: WOW_FOREVER/K63_SERPIENTE.md. Licencia: GPL-3.0-only.
local A = _G.Asistente
local S = {}
A.Serpiente = S

local MEDIA = "Interface\\AddOns\\Asistente\\Media\\"

-- Medidas en píxeles de la barra lateral (la ventana se escala entera con ui.menuScale).
local C = {
	padL = 7, padT = 8, padB = 3.5, padR = 8, -- holgura del contorno alrededor de la tinta de POLESTAR
	radio = 7, radio2 = 6, -- esquinas del contorno y la curva que entra al carril de "Mamba"
	-- ondulado: amplitud y largo de onda por tramo (casi nada en el hueco de 8 px bajo POLESTAR; una S suave
	-- en el carril de "Mamba", donde descansa)
	lambda = 26, amp = 1.1, ampHueco = 0.2, ampCurva = 0.6, ampCarril = 1.3, lambdaCarril = 20, aplanar = 6,
	largoCabeza = 9, largoCuerpo = 46, grueso = 4.0, cuello = 2.9,
	tMover = 9.0, tEntra = 0.7, tReposo = 2.0, tSale = 0.6, tVacio = 0.2, aceleracion = 0.35,
	lenguas = { { 0.5, 0.68 }, { 0.85, 1.03 }, { 1.5, 1.68 } }, -- en el reposo, desde que llega
}
C.ciclo = C.tMover + C.tReposo + C.tSale + C.tVacio
S.C = C

-- La tinta del logotipo dentro de su textura (Media/UI/wordmark-small.tga, 256x32 dibujada 1:1).
local INK_L, INK_R, INK_T, INK_B = 2, 127, 7, 24

A.Defaults("serpiente", { animada = true })
function S.Encendida() return A.Ajuste("serpiente", "animada") ~= false end

local function reducir()
	local P = _G.Polestar
	return P and P.Get and P.Get("ui.reduceMotion") and true or false
end

-- ¿La piel de la ventana es clara (Vellum)? Ahí el oliva de "Mamba" no llega a 4,5:1 y la serpiente pesa
-- demasiado: la palabra pasa a un oliva hondo (#3f5022, 5,1:1 sobre #d8c8a2) sin sombra y la serpiente al 85 %.
function S.PielClara()
	local T = _G.Polestar and _G.Polestar.Theme
	if not (T and T.Color) then return false end
	local ok, r, g, b = pcall(T.Color, "sidebar")
	if not (ok and r and g and b) then return false end
	return 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.45
end

local function tenirMarca(f, clara)
	local m = rawget(f, "MambaMarca")
	if not m then return end
	if clara then
		m:SetTextColor(0x3F / 255, 0x50 / 255, 0x22 / 255)
		if m.SetShadowColor then m:SetShadowColor(0, 0, 0, 0) end
	else -- los de P12-encabezado
		m:SetTextColor(0.55, 0.62, 0.42)
		if m.SetShadowColor then m:SetShadowColor(0.05, 0.06, 0.05, 1) end
	end
end

-- Dónde está cada pieza del encabezado, en coordenadas de la barra lateral (x a la derecha, y hacia abajo).
-- Primero con la posición REAL en pantalla (GetLeft/GetTop de cada pieza contra la barra): así no importa a
-- qué marco esté anclada cada una. Si la ventana todavía no tiene posición, con las anclas de W.Shell.
local function enPantalla(side, r)
	local sl, st, l, t = side:GetLeft(), side:GetTop(), r:GetLeft(), r:GetTop()
	if not (sl and st and l and t) then return nil end
	if sl == 0 and st == 0 and l == 0 and t == 0 then return nil end -- aún sin posición
	return l - sl, st - t
end

function S.Geometria(f)
	local side, wm, tag, marca = rawget(f, "Sidebar"), rawget(f, "Wordmark"), rawget(f, "Tagline"), rawget(f, "MambaMarca")
	if not (side and wm and tag and marca) then return nil end
	local _, tam = marca:GetFont()
	tam = tam or 12
	local tw, mw = tag:GetStringWidth() or 120, marca:GetStringWidth() or 40
	local wx, wy = enPantalla(side, wm)
	local tx, ty = enPantalla(side, tag)
	local mx, my = enPantalla(side, marca)
	local fuente = "pantalla"
	if not (wx and tx and mx) then
		fuente = "anclas"
		local _, _, _, ax, ay = wm:GetPoint(1)
		local _, _, _, bx, by = tag:GetPoint(1)
		if not (ax and bx) then return nil end
		wx, wy, tx, ty = ax, -ay, bx, -by
		mx, my = tx, ty + 16
	end
	return {
		fuente = fuente,
		ink = { l = wx + INK_L, r = wx + INK_R, t = wy + INK_T, b = wy + INK_B },
		tag = { l = tx, t = ty, r = tx + tw },
		mamba = { l = mx, t = my, r = mx + mw, h = tam },
	}
end

-- La huella: un contorno redondeado alrededor de POLESTAR (sube por la derecha, cruza arriba, baja por la
-- izquierda y vuelve por el hueco entre POLESTAR y "Un proyecto comunitario"), después baja por la derecha y
-- entra al carril de "Mamba". Devuelve puntos cada 0,5 px (P[i] a (i-1)/2 px del comienzo).
function S.Camino(g)
	local xL = g.ink.l - C.padL
	local xR = math.max(g.ink.r, g.tag.r) + C.padR
	local yT, yB = g.ink.t - C.padT, g.ink.b + C.padB
	local r, r2 = C.radio, C.radio2
	local carril = g.mamba.t + g.mamba.h / 2 + 0.5
	local fin = g.mamba.r + 4
	local pi = math.pi
	local A1, L1 = C.amp, C.lambda
	-- { "l", x0, y0, x1, y1, amplitud, onda } o { "a", cx, cy, radio, ángulo0, ángulo1, amplitud, onda }
	local tramos = {
		{ "l", xR, yB - r, xR, yT + r, A1, L1 },
		{ "a", xR - r, yT + r, r, 0, -pi / 2, A1, L1 },
		{ "l", xR - r, yT, xL + r, yT, A1, L1 },
		{ "a", xL + r, yT + r, r, -pi / 2, -pi, A1, L1 },
		{ "l", xL, yT + r, xL, yB - r, A1, L1 },
		{ "a", xL + r, yB - r, r, pi, pi / 2, C.ampHueco, L1 },
		{ "l", xL + r, yB, xR - r, yB, C.ampHueco, L1 },
		{ "a", xR - r, yB + r, r, -pi / 2, 0, C.ampHueco, L1 },
		{ "l", xR, yB + r, xR, carril - r2, A1, L1 },
		{ "a", xR - r2, carril - r2, r2, 0, pi / 2, C.ampCurva, L1 },
		{ "l", xR - r2, carril, fin, carril, C.ampCarril, C.lambdaCarril },
	}
	local pts = {}
	for _, t in ipairs(tramos) do
		local len, am, la
		if t[1] == "l" then len, am, la = math.sqrt((t[4] - t[2]) ^ 2 + (t[5] - t[3]) ^ 2), t[6], t[7]
		else len, am, la = math.abs(t[6] - t[5]) * t[4], t[7], t[8] end
		local n = math.max(2, math.ceil(len * 4))
		for i = (#pts > 0 and 1 or 0), n do
			local u = i / n
			if t[1] == "l" then
				pts[#pts + 1] = { t[2] + (t[4] - t[2]) * u, t[3] + (t[5] - t[3]) * u, am, la }
			else
				local an = t[5] + (t[6] - t[5]) * u
				pts[#pts + 1] = { t[2] + math.cos(an) * t[4], t[3] + math.sin(an) * t[4], am, la }
			end
		end
	end
	local n = #pts
	local largo = { 0 }
	for i = 2, n do
		largo[i] = largo[i - 1] + math.sqrt((pts[i][1] - pts[i - 1][1]) ^ 2 + (pts[i][2] - pts[i - 1][2]) ^ 2)
	end
	local total = largo[n]
	-- amplitud y onda cambian suave entre tramos; el ondulado es fijo en el espacio (la fase se integra a lo
	-- largo de la huella) y se aplana en los últimos px, donde descansa la cabeza
	local ond, fase = {}, 0
	for i = 1, n do
		local a, la, c = 0, 0, 0
		for j = math.max(1, i - 24), math.min(n, i + 24) do a = a + pts[j][3]; la = la + pts[j][4]; c = c + 1 end
		if i > 1 then fase = fase + 2 * pi * (largo[i] - largo[i - 1]) / (la / c) end
		local j, k = math.min(n, i + 1), math.max(1, i - 1)
		local dx, dy = pts[j][1] - pts[k][1], pts[j][2] - pts[k][2]
		local d = math.sqrt(dx * dx + dy * dy)
		if d == 0 then d = 1 end
		dx, dy = dx / d, dy / d
		local o = a / c * math.min(1, (total - largo[i]) / C.aplanar) * math.sin(fase)
		ond[i] = { pts[i][1] - dy * o, pts[i][2] + dx * o }
	end
	-- remuestreo cada 0,5 px
	local out = { { ond[1][1], ond[1][2] } }
	local acc, px, py = 0, ond[1][1], ond[1][2]
	for i = 2, n do
		local qx, qy = ond[i][1], ond[i][2]
		local d = math.sqrt((qx - px) ^ 2 + (qy - py) ^ 2)
		while acc + d >= 0.5 and d > 0 do
			local u = (0.5 - acc) / d
			px, py = px + (qx - px) * u, py + (qy - py) * u
			out[#out + 1] = { px, py }
			d = math.sqrt((qx - px) ^ 2 + (qy - py) ^ 2)
			acc = 0
		end
		acc = acc + d
		px, py = qx, qy
	end
	return out
end

-- Punto y ángulo (radianes, con y hacia abajo) a s px del comienzo de la huella.
function S.En(P, s)
	local n = #P
	local i = math.max(1, math.min(n - 1, math.floor(s * 2) + 1))
	local a, b = P[math.max(1, i - 2)], P[math.min(n, i + 2)]
	return P[i][1], P[i][2], math.atan2(b[2] - a[2], b[1] - a[1])
end

local function suave(x)
	if x <= 0 then return 0 elseif x >= 1 then return 1 end
	return x - math.sin(2 * math.pi * x) / (2 * math.pi) * C.aceleracion
end

-- El momento t del ciclo: largo recorrido por la cabeza, opacidad y si saca la lengua.
function S.Pose(P, t)
	local total = (#P - 1) / 2
	local L0 = C.largoCabeza + C.largoCuerpo
	t = t % C.ciclo
	if t < C.tMover then
		return L0 + (total - L0) * suave(t / C.tMover), math.min(1, t / C.tEntra), false
	end
	local r = t - C.tMover
	local lengua = false
	for _, v in ipairs(C.lenguas) do if r > v[1] and r < v[2] then lengua = true end end
	local alfa = 1
	if r > C.tReposo then alfa = math.max(0, 1 - (r - C.tReposo) / C.tSale) end
	return total, alfa, lengua
end

-- Los discos del cuerpo: distancia detrás del cuello y grosor. El paso es proporcional al grosor: así la
-- cola no se ve punteada.
local DISCOS = {}
do
	local a = 0
	while a <= C.largoCuerpo do
		local u = a / C.largoCuerpo
		local g
		-- el cuello se estrecha detrás de la cabeza y el cuerpo vuelve a su grosor antes de afinarse a la cola
		if u < 0.15 then g = C.cuello + (C.grueso - C.cuello) * (u / 0.15) else g = C.grueso * (1 - 0.8 * ((u - 0.15) / 0.85) ^ 1.5) end
		DISCOS[#DISCOS + 1] = { a, g }
		a = a + math.max(0.45, 0.4 * g)
	end
end
S.DISCOS = DISCOS

-- Diagnóstico para leer fuera del juego (AsistenteDB.diag.serpiente): si se montó, por qué no, la geometría,
-- si cargaron las texturas, si gira, cuántos cuadros dibujó, la última pose y el primer error. La coordinadora
-- (18-11) la abrió en el juego y no la vio: con esto se sabe en qué paso se cae.
local function D()
	if type(AsistenteDB) ~= "table" then return S.diagTemp or {} end
	AsistenteDB.diag = AsistenteDB.diag or {}
	local d = AsistenteDB.diag.serpiente
	if type(d) ~= "table" or d.sesion ~= S.sesion then
		d = { sesion = S.sesion, intentos = 0, cuadros = 0, texturas = {} }
		AsistenteDB.diag.serpiente = d
	end
	return d
end
S.Diag = D
S.sesion = (time and time()) or 0

local function anotarError(donde, err)
	local d = D()
	d.errores = (d.errores or 0) + 1
	if not d.error then
		d.error = donde .. ": " .. tostring(err)
		if geterrorhandler then geterrorhandler()(err) end -- una vez, para /errores
	end
end

local gira = true -- SetRotation; apagado para siempre si falla (como Polestar, Maps/RouteLines.lua)

local function textura(host, archivo, capa, sub)
	local t = host:CreateTexture(nil, capa, nil, sub)
	local ok = t:SetTexture(MEDIA .. archivo)
	D().texturas[archivo] = ok ~= false and (t.GetTexture and t:GetTexture() ~= nil) or false
	if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end -- se mueve en fracciones de píxel sin temblar
	if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
	return t
end

local function colocar(t, host, x, y, tam, ang)
	t:ClearAllPoints()
	t:SetPoint("CENTER", host, "TOPLEFT", x, -y)
	t:SetSize(tam, tam)
	-- SetRotation gira en sentido antihorario con y hacia arriba: el ángulo de la huella va con y hacia abajo
	if gira and t.SetRotation and not pcall(t.SetRotation, t, -ang) then
		gira = false
		D().gira = false
	end
end

local function dibujar(s, t)
	local P = s.P
	if not P then return end
	local h, alfa, lengua = S.Pose(P, t)
	s.host:SetAlpha(alfa * (s.alfaPiel or 1))
	if alfa <= 0 then return end
	for i, d in ipairs(DISCOS) do
		local tex = s.discos[i]
		local x, y, ang = S.En(P, math.max(0, h - C.largoCabeza * 0.8 - d[1]))
		colocar(tex, s.host, x, y, d[2] * 32 / 30, ang)
	end
	local x, y, ang = S.En(P, h - C.largoCabeza * 0.5)
	colocar(s.cabeza, s.host, x, y, C.largoCabeza, ang)
	colocar(s.lengua, s.host, x, y, C.largoCabeza * 24 / 11, ang)
	s.lengua:SetShown(lengua)
	s.h = h
	local dd = D()
	dd.cuadros = (dd.cuadros or 0) + 1
	if dd.cuadros % 120 == 1 then -- de vez en cuando, no en cada cuadro
		dd.pose = { x = x, y = y, alfa = alfa, visible = s.host:IsVisible() or false,
			alfaEfectivo = s.host.GetEffectiveAlpha and s.host:GetEffectiveAlpha() or nil,
			escala = s.host.GetEffectiveScale and s.host:GetEffectiveScale() or nil,
			cabezaVisible = s.cabeza:IsVisible() or false, ancho = s.host:GetWidth(), alto = s.host:GetHeight() }
	end
end

local function rearmar(s)
	local g = S.Geometria(s.f)
	s.P = g and S.Camino(g) or nil
	s.fuente = g and g.fuente
	local d = D()
	d.geometria = g and { fuente = g.fuente, inkL = g.ink.l, inkR = g.ink.r, inkT = g.ink.t, inkB = g.ink.b, tagR = g.tag.r,
		mambaL = g.mamba.l, mambaR = g.mamba.r, mambaT = g.mamba.t } or "sin geometría (Wordmark/Tagline/MambaMarca o GetPoint)"
	d.puntos = s.P and #s.P or 0
	local clara = S.PielClara()
	s.alfaPiel = clara and 0.85 or 1
	tenirMarca(s.f, clara)
end

local function aplicar(s)
	local on = S.Encendida()
	s.host:SetShown(on)
	if not on then return end
	rearmar(s)
	if reducir() then
		s.t = C.tMover + 0.3 -- acostada junto a "Mamba", sin lengua
		dibujar(s, s.t)
	end
end

-- Arma la serpiente sobre la ventana f (PolestarPicker), una sola vez.
function S.Montar(f)
	if S.actual then return S.actual end
	local d = D()
	d.intentos = (d.intentos or 0) + 1
	d.encendida = S.Encendida()
	d.reducir = reducir()
	if not f then d.motivo = "no existe PolestarPicker"; return nil end
	if not rawget(f, "Sidebar") then d.motivo = "la ventana no tiene Sidebar"; return nil end
	if not rawget(f, "MambaMarca") then d.motivo = "la ventana no tiene MambaMarca (falta el parche P12-encabezado)"; return nil end
	local ok, s = pcall(S.Armar, f)
	if not ok then d.motivo = "error al armar"; anotarError("Montar", s); return nil end
	d.montada, d.motivo = true, nil
	return s
end

function S.Armar(f)
	local side = f.Sidebar
	local host = CreateFrame("Frame", nil, side)
	host:SetAllPoints(side)
	host:SetFrameLevel((side:GetFrameLevel() or 1) + 6)
	if host.EnableMouse then host:EnableMouse(false) end
	local s = { f = f, host = host, t = 0, discos = {} }
	local n = #DISCOS
	for i = n, 1, -1 do -- la cola abajo y el cuello encima
		s.discos[i] = textura(host, "serpiente-cuerpo", "ARTWORK", -8 + math.floor((n - i) / n * 14))
	end
	s.cabeza = textura(host, "serpiente-cabeza", "OVERLAY", 2)
	s.lengua = textura(host, "serpiente-lengua", "OVERLAY", 1)
	s.lengua:Hide()
	host:SetScript("OnShow", function() rearmar(s) end)
	host:SetScript("OnUpdate", function(_, dt)
		if s.pausada or s.rota or reducir() then return end
		-- recién abierta la ventana puede no tener posición: se vuelve a medir en pantalla apenas la tenga
		if s.fuente ~= "pantalla" then
			s.remedir = (s.remedir or 0) + (dt or 0)
			if s.remedir > 0.25 then s.remedir = 0; rearmar(s) end
		end
		s.t = (s.t + (dt or 0)) % C.ciclo
		local ok, err = pcall(dibujar, s, s.t)
		if not ok then s.rota = true; anotarError("dibujar", err) end -- un error, no uno por cuadro
	end)
	S.actual = s
	aplicar(s)
	local P = _G.Polestar
	if P and P.Theme and P.Theme.OnChanged then P.Theme.OnChanged(function() if s.host:IsShown() then rearmar(s) end end) end
	return s
end

function S.Fijar(v)
	A.FijarAjuste("serpiente", "animada", v and true or false)
	if S.actual then aplicar(S.actual) end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, e)
	if e == "PLAYER_REGEN_DISABLED" or e == "PLAYER_REGEN_ENABLED" then
		if S.actual then S.actual.pausada = e == "PLAYER_REGEN_DISABLED" end
		return
	end
	local P = _G.Polestar
	local d = D()
	d.hook = (P and P.UI and P.UI.ShowPicker and hooksecurefunc) and true or false
	local function probar()
		local s = S.Montar(_G.PolestarPicker)
		if s then s.pausada = InCombatLockdown and InCombatLockdown() or false end
		return s
	end
	if _G.PolestarPicker then probar() end
	if d.hook then hooksecurefunc(P.UI, "ShowPicker", probar) end
	-- respaldo: si la ventana se abre por otro camino que no pasa por ShowPicker, se monta igual en cuanto existe
	if C_Timer and C_Timer.NewTicker then
		local tic
		tic = C_Timer.NewTicker(1, function()
			if S.actual or probar() then tic:Cancel() end
		end)
	end
end)

-- El interruptor «Serpiente animada» está en Ajustes › Mamba › Qué se muestra (Interruptores.lua, K124): aquí había
-- un segundo control para la misma clave que no se repintaba (revisor t9).
