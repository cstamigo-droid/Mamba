-- Mamba_Profesiones: la sección "Profesiones" del menú de Polestar (lugar 260 del riel). Partes:
-- Tus profesiones · Lista de compra (K60) · Instructores y recetas (F6) · Ganar oro (F7) · Farmeo (O7/O8).
-- Cada fila trae su número, su cómo y su botón (R0, K61) y van de más a menos conveniente (K62).
-- Licencia: GPL-3.0-only.
local _, M = ...
local C = M.C
local KEY = "MambaProfesiones"
local vista, profElegida, objetivo, filtro = "tuyas", nil, "tela", "todo"
local L

M.VISTAS = {
	{ key = "tuyas", label = "Tus profesiones", icon = "icon-craft" },
	{ key = "compra", label = "Lista de compra", icon = "icon-buy" },
	{ key = "instructores", label = "Instructores y recetas", icon = "icon-goto" },
	{ key = "ganar", label = "Ganar oro", icon = "icon-buy" },
	{ key = "farmeo", label = "Farmeo", icon = "icon-collect" },
}

M.Vital = function(id) return C.Vital(id) end
function M.CentroNodos(obj, mapa)
	local Mp = _G.MambaMapa
	if Mp and Mp.CentroNodos then return Mp.CentroNodos(obj, mapa) end
end

local function api() return _G.SkillUpForever and _G.SkillUpForever.API end
local function ir(v) vista = v; M.Refrescar() end

local function abrirSubasta()
	local a = _G.MambaAPI
	if a and a.Abrir then pcall(a.Abrir, "MambaSubasta", "comprar") end
end

local function valorTexto(lc)
	return (lc.valorMedido and "tu hora vale " or "tu hora vale ≈ ") .. M.Dinero(lc.valorHora)
		.. (lc.valorMedido and " (medido)" or " (sin medir: juega con el Medidor encendido y se corrige solo)")
end

---------------------------------------------------------------- filas de cada parte
local function filasTuyas()
	local lista, motivo = C.Profesiones()
	if not lista then return {}, { titulo = "Tus profesiones", linea1 = motivo } end
	local out = {}
	for _, e in ipairs(lista) do
		local lc = C.ListaCompra(e.skillLineID)
		local t = lc and lc.total
		local puntos = math.max(0, (e.maxRank or 0) - (e.rank or 0))
		local costoMin = t and (t.mixtoMin + t.mixtoOro / math.max(1, lc.valorHora) * 60) or nil
		local s = e.steps and e.steps[1]
		local det = s and (s.text .. (s.detail and (" · " .. s.detail) or "")) or "Llegaste al tope de tu rango: entrena el siguiente."
		local conf = t and (("Comprar todo ≈ %s · farmear todo ≈ %s · lo recomendado: %s y %s"):format(
			t.sinPrecio > 0 and (M.Dinero(t.comprar) .. " (+" .. t.sinPrecio .. " sin precio)") or M.Dinero(t.comprar),
			M.Minutos(t.farmMin), M.Dinero(t.mixtoOro), M.Minutos(t.mixtoMin))) or nil
		local acc = {}
		if s and s.nav then acc[#acc + 1] = { "Llévame", function() api().Navigate(e.skillLineID, 1) end } end
		acc[#acc + 1] = { "Lista de compra", function() profElegida = e.skillLineID; ir("compra") end }
		acc[#acc + 1] = { "Abrir recetas", function() api().OpenRecipes(e.skillLineID) end }
		out[#out + 1] = { tipo = M.Lista.Estrellas(costoMin and puntos / math.max(1, costoMin) * 2 or nil) .. "\n" .. e.name,
			titulo = ("%s %d de %d · te faltan %d puntos para %s"):format(e.name, e.rank or 0, e.maxRank or 0, puntos, e.title or "el tope"),
			detalle = "Ahora: " .. det, conf = conf, acciones = acc, orden = costoMin and puntos / math.max(1, costoMin) or 0 }
	end
	table.sort(out, function(a, b) return a.orden > b.orden end)
	return out, { titulo = "Tus profesiones", linea1 = "El camino más barato de cada una (SkillUp Forever) con lo que cuesta en oro y en tiempo.",
		linea2 = "★ = puntos de habilidad por minuto de esfuerzo (más estrellas, más conviene ahora)." }
end

local function filasCompra()
	local lista, motivo = C.Profesiones()
	if not lista then return {}, { titulo = "Lista de compra", linea1 = motivo } end
	if not profElegida and lista[1] then profElegida = lista[1].skillLineID end
	local lc, m2 = C.ListaCompra(profElegida)
	local filtros = {}
	for _, e in ipairs(lista) do filtros[#filtros + 1] = { "p" .. e.skillLineID, e.name, e.skillLineID == profElegida } end
	filtros[#filtros + 1] = { "todo", "Todo", filtro == "todo" }
	filtros[#filtros + 1] = { "15", "Tengo 15 min", filtro == "15" }
	local cab = { titulo = "Lista de compra y farmeo", filtros = filtros,
		alFiltro = function(k)
			local n = tonumber((k or ""):match("^p(%d+)$"))
			if n then profElegida = n else filtro = k end
			M.Refrescar()
		end }
	if not lc then cab.linea1 = m2; return {}, cab end
	local t = lc.total
	cab.linea1 = ("%s hasta %d: comprar todo ≈ %s · farmear todo ≈ %s · RECOMENDADO: %s + %s farmeando"):format(
		lc.prof.name, lc.prof.maxRank or 0, M.Dinero(t.comprar), M.Minutos(t.farmMin), M.Dinero(t.mixtoOro), M.Minutos(t.mixtoMin))
	cab.linea2 = "Mamba elige por oro + tiempo: " .. valorTexto(lc) .. ". Cuenta lo que tienes en bolsas, banco y otros personajes."
	local out = {}
	for _, f in ipairs(lc) do
		if f.falta > 0 and (filtro ~= "15" or (f.elige == "comprar") or (f.farmear and f.farmear.minutos <= 15)) then
			local partes = {}
			if f.comprar then
				partes[#partes + 1] = ("Comprar: %d × %s = %s%s"):format(f.falta, M.Dinero(f.comprar.unidad), M.Dinero(f.comprar.total),
					f.comprar.de == "vendedor" and " (vendedor)" or " (subasta)")
			else
				partes[#partes + 1] = "Comprar: sin precio aún (escanea la subasta)"
			end
			local fa = f.farmear
			if fa then
				local fo = fa.forma
				local como = fo.tipo == "nodo" and ("recolecta " .. fo.nombre) or (fo.tipo == "piel" and ("desuella " .. fo.nombre) or ("mata " .. fo.nombre .. " (nivel " .. fo.nivel[1] .. "-" .. fo.nivel[2] .. ")"))
				partes[#partes + 1] = ("Farmear: %s%s en %s, %s %s %% · %s%d por hora"):format(fo.medido and "" or "≈ ", M.Minutos(fa.minutos),
					M.Zona(fo.mapa), como, tostring(fo.pct), fo.medido and "" or "≈ ", math.floor(fo.porHora + 0.5))
				if fa.viaje then partes[#partes] = partes[#partes] .. " · viaje " .. M.Minutos(fa.viaje) end
			else
				partes[#partes + 1] = "Farmear: sin un lugar a tu alcance"
			end
			local elige = f.elige == "comprar" and "COMPRAR" or (f.elige == "farmear" and "FARMEAR" or "sin datos aún")
			local acc = {}
			if fa then acc[#acc + 1] = { "Llévame", function()
				M.Medir.Empezar(f.id, fa.forma.mapa)
				M.Llevame(fa.forma.mapa, fa.forma.x, fa.forma.y, M.NombreObjeto(f.id))
			end } end
			if f.comprar then acc[#acc + 1] = { "Ir a la subasta", abrirSubasta } end
			if fa and fa.forma.tipo == "nodo" and _G.MambaMapa then acc[#acc + 1] = { "Ver ruta", function() _G.MambaMapa.MostrarRuta(fa.forma.mapa, f.id) end } end
			out[#out + 1] = { tipo = elige, titulo = ("%s: te faltan %d (tienes %d de %d)"):format(f.nombre, f.falta, f.tiene or 0, f.necesita or 0),
				detalle = table.concat(partes, "\n"),
				conf = f.ahorro and ("Elegido por " .. M.Dinero(f.ahorro) .. " de diferencia contra la otra forma") or nil, acciones = acc }
		end
	end
	cab.vacio = "No te falta nada para tu rango actual."
	return out, cab
end

local function filasInstructores()
	local lista, motivo = C.Profesiones()
	if not lista then return {}, { titulo = "Instructores y recetas", linea1 = motivo } end
	local out = {}
	for _, e in ipairs(lista) do
		for i, s in ipairs(e.steps or {}) do
			if s.kind == "train" then
				out[#out + 1] = { tipo = e.name, titulo = s.text, detalle = s.detail,
					conf = s.cost and ("Cuesta " .. M.Dinero(s.cost)) or nil,
					acciones = s.nav and { { "Llévame", function() api().Navigate(e.skillLineID, i) end } } or nil }
			end
		end
	end
	return out, { titulo = "Instructores y recetas", linea1 = "Qué aprender, con quién, dónde y cuánto cuesta (el más cercano en tiempo).",
		vacio = "Por ahora no te toca entrenar nada nuevo." }
end

local function filasGanar()
	local res, leidas = C.Fabricar()
	local out = {}
	for i, r in ipairs(res) do
		if i > 25 then break end
		local siguiente = res[i + 1]
		out[#out + 1] = { tipo = r.ganancia > 0 and ("+" .. M.Dinero(r.ganancia)) or "pierde", titulo = r.nombre .. " (" .. r.prof .. ")",
			detalle = ("Se vende ≈ %s neto · materiales %s"):format(M.Dinero(r.venta or 0), M.Dinero(r.costo or 0)),
			conf = (r.noSeVende and "Casi no se vende: no lo fabriques para vender. " or (r.sinLiquidez and "Ventas sin medir aún. " or ""))
				.. (siguiente and i == 1 and ("La siguiente deja " .. M.Dinero(siguiente.ganancia)) or ""),
			acciones = { { "Ir a la subasta", abrirSubasta } } }
	end
	local cab = { titulo = "Ganar oro fabricando", linea1 = "Ganancia NETA de cada receta que sabes: lo que paga la subasta menos la comisión, el depósito y los materiales.",
		linea2 = "Los precios son los del Tasador (escanea la subasta para tenerlos al día)." }
	if leidas == 0 then
		cab.vacio = "Abre una vez la ventana de cada profesión tuya para que Mamba lea tus recetas."
		local lista = C.Profesiones()
		if lista then
			for _, e in ipairs(lista) do
				out[#out + 1] = { tipo = e.name, titulo = "Abrir " .. e.name, acciones = { { "Abrir recetas", function() api().OpenRecipes(e.skillLineID) end } } }
			end
		end
	end
	return out, cab
end

local function filasFarmeo()
	local filtros = {}
	for _, o in ipairs(C.OBJETIVOS) do filtros[#filtros + 1] = { o[1], o[2], o[1] == objetivo } end
	local cab = { titulo = "Farmeo: el mejor lugar para tu nivel", filtros = filtros, alFiltro = function(k) objetivo = k; M.Refrescar() end }
	local lugares, motivo = C.Lugares(objetivo)
	if motivo then cab.linea1 = motivo; return {}, cab end
	cab.linea1 = "Ordenados por oro por hora (precio del Tasador × lo que se junta). ≈ = estimado; al farmear con \"Llévame\" se mide."
	local out = {}
	for i, l in ipairs(lugares) do
		local sig = lugares[i + 1]
		local quien = (l.nombre ~= "" and (l.nombre .. " (nivel " .. l.nivel[1] .. "-" .. l.nivel[2] .. ")")) or "los nodos de la zona"
		out[#out + 1] = { tipo = i == 1 and "MEJOR" or ("#" .. i), titulo = M.Zona(l.mapa) .. ": " .. quien,
			detalle = ("%s%d de %s por hora · %s"):format(l.medido and "" or "≈ ", math.floor(l.porHora + 0.5), M.NombreObjeto(l.item),
				l.oroHora and ((l.medido and "" or "≈ ") .. M.Dinero(l.oroHora) .. " por hora") or "sin precio aún"),
			conf = (i == 1 and sig and sig.oroHora and l.oroHora) and ("La siguiente: " .. M.Zona(sig.mapa) .. ", ≈ " .. M.Dinero(sig.oroHora) .. " por hora") or nil,
			acciones = {
				{ "Llévame", function() M.Medir.Empezar(l.item, l.mapa); M.Llevame(l.mapa, l.x, l.y, M.Zona(l.mapa)) end },
				_G.MambaMapa and { "Ver ruta", function() _G.MambaMapa.MostrarRuta(l.mapa, nil, objetivo) end } or nil,
			} }
	end
	cab.vacio = "Sin lugares para tu nivel en los datos."
	return out, cab
end


-- K61/K62 para "Mi plan › Ahora" y el panel de la guía: recomendaciones de profesiones con su número, su cómo y
-- su "Llévame", ordenadas por impacto ÷ costo. filtro = { solo = true, minutos = n }.
-- -> { { texto, como, impacto (texto), puntos, minutos, oro, solo = true, estrellas, llevame = fn } }
function M.Recomendaciones(filtro)
	filtro = filtro or {}
	local lista = C.Profesiones()
	if not lista then return {} end
	local out = {}
	for _, e in ipairs(lista) do
		local lc = C.ListaCompra(e.skillLineID)
		local t = lc and lc.total
		local puntos = math.max(0, (e.maxRank or 0) - (e.rank or 0))
		if t and puntos > 0 then
			local minutos = t.mixtoMin
			local s = e.steps and e.steps[1]
			local primero
			for _, f in ipairs(lc) do if f.falta > 0 and f.farmear and f.elige == "farmear" then primero = f; break end end
			local costoMin = minutos + t.mixtoOro / math.max(1, lc.valorHora) * 60
			local razon = puntos / math.max(1, costoMin) * 2
			local r = { texto = ("Sube %s de %d a %d"):format(e.name, e.rank or 0, e.maxRank or 0),
				como = s and (s.text .. (s.detail and (" · " .. s.detail) or "")) or "Abre tus recetas",
				impacto = ("+%d puntos de %s"):format(puntos, e.name), puntos = puntos, minutos = minutos, oro = t.mixtoOro,
				solo = true, estrellas = M.Lista.Estrellas(razon), razon = razon,
				llevame = primero and function()
					M.Medir.Empezar(primero.id, primero.farmear.forma.mapa)
					M.Llevame(primero.farmear.forma.mapa, primero.farmear.forma.x, primero.farmear.forma.y, primero.nombre)
				end or (s and s.nav and function() api().Navigate(e.skillLineID, 1) end) or nil,
				abrir = function() profElegida = e.skillLineID; M.Abrir("compra") end }
			if (not filtro.minutos or minutos <= filtro.minutos) then out[#out + 1] = r end
		end
	end
	table.sort(out, function(a, b) return a.razon > b.razon end)
	return out
end

local FILAS = { tuyas = filasTuyas, compra = filasCompra, instructores = filasInstructores, ganar = filasGanar, farmeo = filasFarmeo }

function M.Refrescar()
	if not (L and L.lista and L.lista:IsVisible()) then return end
	local filas, cab = M.Proteger("filas:" .. vista, FILAS[vista])
	L:Dibujar(cab or {}, filas or {})
end
M.AlCambiar(function() M.Refrescar() end)

local registrada = false
local function registrar()
	local UI = _G.Polestar and _G.Polestar.UI
	if registrada or not (UI and UI.RegisterSection) then return registrada end
	registrada = UI.RegisterSection({
		key = KEY, label = "Profesiones", icon = "icon-craft", order = 260,
		build = function(parent) L = M.Lista.Nueva(parent) end,
		render = function()
			M.Proteger("refrescar", M.Refrescar)
			if C_Timer then C_Timer.After(0, function() M.Proteger("refrescar", M.Refrescar) end) end
		end,
		nav = function()
			local items = {}
			for _, x in ipairs(M.VISTAS) do items[#items + 1] = { key = x.key, label = x.label, icon = x.icon } end
			return items, vista
		end,
		onNav = function(k)
			vista = k
			if UI.Picker and UI.Picker.Render then UI.Picker.Render() end
		end,
	}) and true or false
	return registrada
end

function M.Abrir(v)
	if v then vista = v end
	local UI = _G.Polestar and _G.Polestar.UI
	if registrar() and UI.ShowPicker and UI.Picker and UI.Picker.ShowSection then
		UI.ShowPicker()
		UI.Picker.ShowSection(KEY)
		return true
	end
	return false
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "SKILL_LINES_CHANGED", "BAG_UPDATE_DELAYED" }) do M.Escuchar(ev, e) end
ev:SetScript("OnEvent", function(_, e)
	if e == "PLAYER_LOGIN" then
		M.Proteger("registrar", registrar)
		local S = _G.SkillUpForever and _G.SkillUpForever.API
		if S and S.Subscribe then pcall(S.Subscribe, function() C.Olvidar(); M.Refrescar() end) end
	else
		C.Olvidar()
		M.Refrescar()
	end
end)
