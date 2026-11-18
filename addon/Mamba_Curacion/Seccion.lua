-- Mamba_Curacion: su parte en Interfaz (menú de Polestar): "Marcos de grupo" y "Qué hace cada clic".
-- El perfil de clics es por clase y por especialización (cambia solo con la doble especialización, K18).
-- Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas
local sub = "marcos"
local paneles = {}

local function db() return M.DB() end

local function opcionesClic()
	local o = { { value = "nada", text = "Nada" }, { value = "target", text = "Elegir de objetivo" }, { value = "menu", text = "Menú del jugador" } }
	for _, id in ipairs(M.CURAS[M.Clase()] or {}) do
		if M.Conoce(id) then o[#o + 1] = { value = id, text = M.NombreAccion(id) } end
	end
	return o
end

local function colocar(p, filas, ancho, y)
	for _, f in ipairs(filas) do
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", p, "TOPLEFT", 16, y)
		y = y - P.Acomodar(f, ancho - 40) - 4
	end
	return y
end

local function titulo(p, t, sub2)
	local a = P.Texto(p, "title", "text")
	a:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -12)
	a:SetText(t)
	local b = P.Texto(p, "note", "textDim")
	b:SetPoint("TOPLEFT", a, "BOTTOMLEFT", 0, -6)
	b:SetText(sub2 or "")
	return -54
end

local function dibujarMarcos(p, ancho)
	local d = db()
	local y = titulo(p, "Marcos de grupo con clic para curar", "Un clic sobre un compañero lanza el hechizo sobre él, sin cambiar tu objetivo. Se mueven arrastrando su borde.")
	local function I(et, ay, k) return P.Interruptor(p, et, ay, function() return d[k] end, function(v) d[k] = v; M.Cambio() end) end
	local function S(et, ay, a, b, paso, fmt, k) return P.Deslizador(p, et, ay, a, b, paso, fmt, function() return d[k] end, function(v) d[k] = v; M.Cambio() end) end
	colocar(p, {
		P.Desplegable(p, "Mostrar", "Solo en grupo, siempre o nunca. Los modos de pelea también los muestran u ocultan.",
			{ { value = "grupo", text = "Solo en grupo" }, { value = "siempre", text = "Siempre" }, { value = "nunca", text = "Nunca" } },
			function() return d.mostrar end, function(v) d.mostrar = v; M.Cambio() end),
		I("Mover marcos", "Muestra un asa arriba de los marcos para arrastrarlos (solo fuera de combate). Apágalo al terminar.", "mover"),
		I("Incluirme a mí cuando juego solo", nil, "solo"),
		I("Mis efectos de curación en el tiempo, con su cuenta regresiva", "Hasta 3 por compañero.", "hots"),
		I("Marcar lo que puedo limpiar", "Solo lo que tu clase limpia (veneno, maldición, magia o enfermedad).", "limpiar"),
		I("Atenuar a quien está fuera de alcance", "Del hechizo de tu clic izquierdo.", "rango"),
		S("Ancho", nil, 60, 160, 2, "%d", "ancho"), S("Alto", nil, 24, 70, 2, "%d", "alto"),
		S("Tamaño", nil, 0.6, 1.6, 0.05, "%.2f", "escala"),
	}, ancho, y)
end

local function dibujarClics(p, ancho)
	local spec = M.Spec()
	local y = titulo(p, "Qué hace cada clic", ("Perfil de tu especialización %d: si cambias de especialización, cambia solo. La rueda funciona con el ratón encima del compañero."):format(spec))
	local filas = {}
	for _, c in ipairs(M.CLICS) do
		local clave = c[1]
		filas[#filas + 1] = P.Desplegable(p, c[2], nil, opcionesClic(),
			function() return M.Perfil()[clave] or "nada" end,
			function(v) M.Perfil()[clave] = (v ~= "nada") and v or nil; M.Cambio() end)
	end
	y = colocar(p, filas, ancho, y)
	local b = P.Boton(p, "Volver al perfil sugerido", function()
		local d = db()
		d.perfiles[M.Clase()][M.Spec()] = nil
		M.Perfil()
		M.Cambio()
	end)
	b:SetPoint("TOPLEFT", p, "TOPLEFT", 16, y - 6)
end

local function dibujar(parent, ancho)
	for k, fn in pairs({ marcos = dibujarMarcos, clics = dibujarClics }) do
		paneles[k] = CreateFrame("Frame", nil, parent)
		paneles[k]:SetAllPoints(parent)
		fn(paneles[k], ancho)
	end
end

local function refrescar()
	for k, p in pairs(paneles) do if k == sub then p:Show() else p:Hide() end end
end

local reg = CreateFrame("Frame")
M.Escuchar(reg, "PLAYER_LOGIN")
reg:SetScript("OnEvent", function()
	local I = _G.MambaInterfaz
	if not (I and I.Agregar) then return end
	M.Proteger("interfaz", I.Agregar, {
		clave = "curacion", titulo = "Curación", orden = 3,
		items = function()
			return { { key = "marcos", label = "Marcos de grupo", icon = "icon-group" }, { key = "clics", label = "Qué hace cada clic", icon = "compact" } }
		end,
		activo = function() return sub end,
		elegir = function(k) if paneles[k] or k == "marcos" or k == "clics" then sub = k end end,
		dibujar = dibujar, refrescar = refrescar,
	})
end)
