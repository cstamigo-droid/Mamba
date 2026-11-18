-- Mamba_Plan: el asistente de inicio. Una ventana de Mamba (con el marco de Polestar) que sale la primera vez
-- que el personaje entra con Mamba, aunque ya juegue, y desde "Mi plan › Cambiar mis respuestas". Tres pasos:
--   1. Rol (si la clase tiene más de uno) y para qué juegas (mazmorras, JcJ, oro).
--   2. Build: la recomendada para ese rol y las de autores conocidos, con su fuente al pasar el ratón.
--   3. Profesiones: Mamba recomienda y dice por qué (clase, rol, raza, objetivo) y lo que cuestan; tú eliges.
-- La clase y la raza las lee del juego. Lo que elijas se guarda por personaje y arma "Mi plan".
-- Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas

local ROLES_CLASE = {
	DRUID = { "sanar", "tanque", "danio" }, PALADIN = { "sanar", "tanque", "danio" }, PRIEST = { "sanar", "danio" },
	SHAMAN = { "sanar", "danio" }, WARRIOR = { "tanque", "danio" }, HUNTER = { "danio" }, MAGE = { "danio" },
	WARLOCK = { "danio" }, ROGUE = { "danio" },
}
M.ROLES_CLASE = ROLES_CLASE
local ROL = {
	sanar = { "Sanar", "Te buscan para mazmorras." },
	tanque = { "Tanque", "Grupos rápidos; pide más equipo." },
	danio = { "Daño", "El más cómodo para subir solo." },
}
local ESTILO = {
	{ "jce", "Mazmorras", "Equipo de mazmorra y bandas al 60." },
	{ "jcj", "JcJ", "Campos de batalla y mundo abierto." },
	{ "oro", "Oro", "Farmear y vender. La montura antes." },
}
local ANCHO, ALTO = 620, 520

local v, pagina, borrador = nil, 1, nil
local filas = {}

local function limpiar()
	for _, f in ipairs(filas) do f:Hide() end
	filas = {}
end

-- Tarjeta para elegir: fila con su título, su línea y una marca si está elegida.
local function tarjeta(padre, ancho, titulo, linea, elegida, alClic, ayuda)
	local f = P.Fila(padre, ancho, 46)
	f.marca = P.Relleno(f, "padSelect")
	if not elegida then f.marca:Hide() end
	local t = P.Texto(f, "body", elegida and "accent" or "text")
	t:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -7)
	t:SetPoint("RIGHT", f, "RIGHT", -12, 0)
	t:SetText(titulo)
	local l = P.Texto(f, "note", "textDim")
	l:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -3)
	l:SetPoint("RIGHT", f, "RIGHT", -12, 0)
	l:SetText(linea or "")
	f:SetScript("OnClick", alClic)
	if ayuda then
		f:SetScript("OnEnter", function(self)
			local A = _G.Asistente
			if A and A.CuadroAyuda then A.CuadroAyuda(self, ayuda[1], ayuda[2]) end
		end)
		f:SetScript("OnLeave", function() local A = _G.Asistente; if A and A.OcultarAyuda then A.OcultarAyuda() end end)
	end
	filas[#filas + 1] = f
	return f
end

local function titulo(padre, texto, y, x)
	local t = P.Texto(padre, "heading", "text")
	t:SetPoint("TOPLEFT", padre, "TOPLEFT", x or 0, -y)
	t:SetText(texto)
	filas[#filas + 1] = t
	return t
end

local dibujar -- adelante

local function buildsDe(e, rol)
	local out = {}
	local C = M.Fuentes.Clase()
	if C and C.Builds then
		local ok, lista = pcall(C.Builds, e.clase, rol)
		for _, b in ipairs(ok and lista or {}) do
			out[#out + 1] = { clave = "clase:" .. tostring(b.clave), nombre = b.nombre or b.clave, linea = b.reparto or "",
				tag = "recomendada", ayuda = { b.nombre or "", { b.fuente or "" } } }
		end
	end
	for i, b in ipairs(M.CONOCIDAS or {}) do
		if b.clase == e.clase then
			out[#out + 1] = { clave = "conocida:" .. i, nombre = b.uso .. " · " .. b.autor, linea = b.reparto .. " · " .. b.destaca,
				tag = "conocida", ayuda = { b.autor, { b.destaca, "Talentos clave: " .. b.clave, b.url, b.fecha } } }
		end
	end
	return out
end
M.BuildsDe = buildsDe

local function paso1(cuerpo, ancho, e)
	local y = 0
	local roles = ROLES_CLASE[e.clase] or { "danio" }
	if #roles > 1 then
		titulo(cuerpo, "Rol", y); y = y + 24
		for _, r in ipairs(roles) do
			local f = tarjeta(cuerpo, ancho, ROL[r][1], ROL[r][2], borrador.rol == r, function() borrador.rol = r; dibujar() end)
			f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
		end
	else
		borrador.rol = roles[1]
	end
	y = y + 8
	titulo(cuerpo, "Para qué juegas", y); y = y + 24
	for _, s in ipairs(ESTILO) do
		local f = tarjeta(cuerpo, ancho, s[2], s[3], borrador.estilo == s[1], function() borrador.estilo = s[1]; dibujar() end)
		f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
	end
end

local function paso2(cuerpo, ancho, e)
	local y = 0
	titulo(cuerpo, "Build", y); y = y + 24
	local lista = buildsDe(e, borrador.rol)
	if #lista == 0 then
		local t = P.Texto(cuerpo, "body", "textDim")
		t:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y)
		t:SetWidth(ancho)
		t:SetText("Todavía no hay builds para tu clase en Mamba. Sigue sin elegir: el plan usa tu rol.")
		filas[#filas + 1] = t
		return
	end
	for i, b in ipairs(lista) do
		if i > 7 then break end
		local f = tarjeta(cuerpo, ancho, b.nombre .. "  ·  " .. b.tag, b.linea, borrador.build == b.clave,
			function() borrador.build = b.clave; dibujar() end, b.ayuda)
		f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
	end
end

local function paso3(cuerpo, ancho, e)
	local y = 0
	local tiene = {}
	for _, p in ipairs(e.profesiones) do
		if M.PRIMARIAS[p.nombre] then tiene[#tiene + 1] = p.nombre .. " " .. p.rango end
	end
	titulo(cuerpo, #tiene > 0 and ("Tienes " .. table.concat(tiene, " y ") .. ". Elige tu pareja:") or "Elige tu pareja de profesiones:", y)
	y = y + 26
	for _, rec in ipairs(M.ProfesionesRecomendadas(e, borrador)) do
		local clave = table.concat(rec.par, " + ")
		local costo = {}
		for _, p in ipairs(rec.par) do
			local c = M.CostoProfesion(e, p)
			if c and c.rangosOro > 0 then costo[#costo + 1] = p .. ": instructores " .. M.Dinero(c.rangosOro) end
		end
		local linea = rec.porque .. (rec.raza and ("  Tu raza: " .. rec.raza) or "")
		local ayuda = { clave, {} }
		for _, fte in ipairs(rec.fuentes) do table.insert(ayuda[2], fte) end
		if #costo > 0 then table.insert(ayuda[2], table.concat(costo, " · ")) end
		if rec.tiene > 0 then table.insert(ayuda[2], "Ya tienes " .. rec.tiene .. " de las dos.") end
		local f = tarjeta(cuerpo, ancho, clave .. (rec.tiene == #rec.par and "  ·  ya las tienes" or ""), linea,
			borrador.profesiones == clave, function() borrador.profesiones = clave; dibujar() end, ayuda)
		f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
	end
	local nota = P.Texto(cuerpo, "note", "textMuted")
	nota:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -(y + 6))
	nota:SetWidth(ancho)
	nota:SetText("Pasa el ratón por una opción: de dónde sale el consejo y lo que cuestan los instructores.")
	filas[#filas + 1] = nota
end

function dibujar()
	if not v then return end
	limpiar()
	local e = M.Estado()
	local ancho = ANCHO - 2 * (v.margen or 16)
	v.titulo:SetText(pagina == 1 and ("¿Qué quieres que sea " .. (e.nombre or "tu personaje") .. "?")
		or pagina == 2 and "Tu build" or "Tus profesiones")
	v.sub:SetText(("%s %s, nivel %d. Mamba arma tu plan con esto; lo cambias cuando quieras."):format(
		(e.claseNombre or ""), (e.razaNombre or ""):lower(), e.nivel))
	if pagina == 1 then paso1(v.cuerpoF, ancho, e)
	elseif pagina == 2 then paso2(v.cuerpoF, ancho, e)
	else paso3(v.cuerpoF, ancho, e) end
	v.paso:SetText(("Paso %d de 3"):format(pagina))
	v.atras:SetShown(pagina > 1)
	if v.siguiente.Label then v.siguiente.Label:SetText(pagina < 3 and "Siguiente" or "Listo")
	elseif v.siguiente.SetText then v.siguiente:SetText(pagina < 3 and "Siguiente" or "Listo") end
end

local function terminar()
	local pj = M.PJ()
	pj.respuestas = borrador
	pj.respondido = true
	v:Hide()
	M.Cambio()
	if M.AbrirPlan then M.AbrirPlan() end
end

local function crear()
	v = P.Ventana("MambaPlanInicio", "Mamba", ANCHO, ALTO)
	local m, top = v.margen or 16, v.cuerpo or 26
	v.sub = P.Texto(v, "body", "textDim")
	v.sub:SetPoint("TOPLEFT", v, "TOPLEFT", m, -(top + 4))
	v.sub:SetPoint("RIGHT", v, "RIGHT", -m, 0)
	v.cuerpoF = CreateFrame("Frame", nil, v)
	v.cuerpoF:SetPoint("TOPLEFT", v, "TOPLEFT", m, -(top + 30))
	v.cuerpoF:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -m, 56)
	v.atras = P.Boton(v, "Atrás", function() pagina = math.max(1, pagina - 1); dibujar() end)
	v.atras:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", m, 14)
	v.siguiente = P.Boton(v, "Siguiente", function()
		if pagina < 3 then pagina = pagina + 1; dibujar() else terminar() end
	end, true)
	v.siguiente:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -m, 14)
	v.paso = P.Texto(v, "note", "textMuted")
	v.paso:SetPoint("BOTTOM", v, "BOTTOM", 0, 20)
end

function M.AbrirInicio()
	if not v then crear() end
	local pj = M.PJ()
	borrador = {}
	for k, x in pairs(pj.respuestas or {}) do borrador[k] = x end
	borrador.estilo = borrador.estilo or "jce"
	pagina = 1
	v:Show()
	dibujar()
end

-- Primera vez con Mamba: se abre sola, fuera de combate, unos segundos después de entrar (no encima del
-- asistente de Polestar si está a la vista).
local ev = CreateFrame("Frame")
M.Escuchar(ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
	if M.PJ().respondido then return end
	local function intentar(n)
		if (InCombatLockdown and InCombatLockdown()) or (_G.PolestarWelcome and _G.PolestarWelcome:IsShown()) then
			if n < 20 then C_Timer.After(15, function() intentar(n + 1) end) end
			return
		end
		M.Proteger("inicio", M.AbrirInicio)
	end
	C_Timer.After(6, function() intentar(0) end)
end)
