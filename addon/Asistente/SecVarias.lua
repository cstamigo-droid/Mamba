-- Asistente/SecVarias.lua: las secciones «Clase», «Capa», «Medidor» y «Errores» del hub. Todo con botones:
-- las líneas que antes iban al chat se dibujan aquí, y lo que pedía un comando ahora es un botón.
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = A.Hub
local format, floor = string.format, math.floor

-- Quita los consejos de comandos ("Escribe /clase ...", "Comandos: ..."): en la ventana todo es un botón.
local function sinComandos(t)
	if type(t) ~= "string" then return nil end
	if t:find("/%a") and (t:find("^Escribe") or t:find("Comandos:") or t:find("cámbialo con") or t:find("Mira /")) then
		t = t:gsub("%s*%(?cámbialo con /[^%)]*%)?", ""):gsub("Comandos:.*$", ""):gsub("Escribe /.*$", ""):gsub("Mira /.*$", "")
		if t:match("^%s*$") then return nil end
	end
	return t
end

-- Corre fn con la salida del módulo dirigida a una lista (sin tocar A.Decir ni Tasador.Decir).
local function capturar(M, fn)
	local lineas = {}
	if not (M and M.Salida) then return lineas end
	M.Salida(function(t) lineas[#lineas + 1] = t end)
	local ok, err = pcall(fn)
	M.Salida(nil)
	if not ok then lineas[#lineas + 1] = "|cfff57373Algo falló: " .. tostring(err):sub(1, 160) .. "|r" end
	return lineas
end

---------------------------------------------------------------- Clase
local function Clase() return A.modulos and A.modulos.clase end

local PESTANAS_CLASE = { { key = "resumen", label = "Resumen" }, { key = "talentos", label = "Talentos" }, { key = "prof", label = "Profesiones" } }
local ROLES = { { key = "todos", label = "Todos los talentos" }, { key = "sanar", label = "Sanar" }, { key = "danio", label = "Daño" },
	{ key = "tanque", label = "Tanque" }, { key = "jcj", label = "Contra jugadores" }, { key = "subir", label = "Para subir de nivel" } }

Hub.Seccion({
	clave = "MambaClase", nombre = "Clase", icono = "icon-train", orden = 130, addon = "Asistente_Clase",
	pestanas = PESTANAS_CLASE,
	titulo = function()
		local nombre = UnitClass and UnitClass("player") or ""
		return "Tu clase", tostring(nombre) .. " · nivel " .. (UnitLevel and UnitLevel("player") or "?") .. " · talentos y profesiones que te convienen"
	end,
	nav = function(est)
		if est.pestana ~= "talentos" then return {}, nil end
		return ROLES, est.filtro or "todos"
	end,
	dibujar = function(est, V)
		local M = Clase()
		if not M then V:Vacio("Falta el módulo de clase", "Activa «Asistente_Clase» en la lista de accesorios.") return end
		local C = M.C
		local clase = C and C.MiClase()
		local p = est.pestana or "resumen"
		if p == "talentos" and est.build then
			local b = est.build
			V:Botones({ { "Volver a la lista", function() est.build = nil end }, { "Comparar con mis talentos", function() est.revisar = b end } })
			local lineas = capturar(M, function()
				if est.revisar == b then M.Revisar(clase, b) else M.Build(clase, b) end
			end)
			for i, t in ipairs(lineas) do
				t = sinComandos(t)
				if t then if i == 1 then V:Titulo(t) else V:Nota(t, "text") end end
			end
			return
		end
		if p == "talentos" then
			local rol = est.filtro and est.filtro ~= "todos" and est.filtro or nil
			local lista = C and C.Builds(clase, rol) or {}
			if #lista == 0 then V:Vacio("Sin resultados", "No hay talentos para ese rol en tu clase.") return end
			V:Columnas({ { "Talentos", 380 }, { "Reparto", 220 }, { "", 200 } })
			for _, b in ipairs(lista) do
				local uso = C.USOS and C.USOS[b.uso] or b.uso
				V:Fila({ celdas = { { b.nombre or b.clave, uso }, { b.reparto or "" }, { b.ordenDeLaGuia and "orden de la guía" or "orden armado por Mamba" } },
					ir = function() est.build = b.clave; est.revisar = nil end, irTexto = "Ver" })
			end
			V:Nota("Datos de ForeverDB.net.")
			return
		end
		local lineas = capturar(M, function() if p == "prof" then M.Comando("prof") else M.Resumen(clase) end end)
		for _, t in ipairs(lineas) do
			t = sinComandos(t)
			if t then V:Nota(t, "text") end
		end
		if p == "resumen" then V:Botones({ { "Ver los talentos", function() est.pestana = "talentos" end }, { "Ver las profesiones", function() est.pestana = "prof" end } }) end
	end,
})

---------------------------------------------------------------- Capa
Hub.Seccion({
	clave = "MambaCapa", nombre = "Capa", icono = "layers", orden = 150,
	titulo = function() return "Capa del servidor", "En qué copia del mundo estás: sirve para saber si cambiaste" end,
	dibujar = function(est, V)
		local Capa = A.Capa
		if not Capa then V:Vacio("Sin datos aún", "El lector de capa no está cargado.") return end
		local c = Capa.actual
		if c then
			local seg = floor((GetTime and GetTime() or 0) - (c.cuando or 0))
			V:Panel({ titulo = "Capa " .. tostring(c.zona), texto = "Leída hace " .. (seg < 60 and (seg .. " s") or (floor(seg / 60) .. " min")) .. ". No es el número oficial (el juego no lo da): es un identificador que cambia cuando cambias de capa." })
		else
			V:Vacio("Sin datos aún", "Apunta a cualquier personaje del juego (no a un jugador) o pon el ratón encima: Mamba lee su capa.")
		end
		V:Interruptor("Mostrar el cuadro de la capa en pantalla", A.Ajuste("capa", "mostrar"), function(v) A.FijarAjuste("capa", "mostrar", v); Capa.Pintar() end)
		V:Interruptor("Avisarme cuando cambie de capa", A.Ajuste("capa", "avisar"), function(v) A.FijarAjuste("capa", "avisar", v) end)
		V:Interruptor("Cuadro fijo (que no se mueva)", A.Ajuste("capa", "bloqueado"), function(v) A.FijarAjuste("capa", "bloqueado", v); Capa.Pintar() end)
		V:Botones({ { "Olvidar la capa leída", function() Capa.Olvidar() end } })
	end,
})

---------------------------------------------------------------- Medidor
local ACT = { "misiones", "farmeo", "mazmorra", "fabricar", "subasta", "jcj", "otra" }
local ACT_NOMBRE = { misiones = "Misiones", farmeo = "Farmeo", mazmorra = "Mazmorra", fabricar = "Fabricar", subasta = "Subasta", jcj = "Contra jugadores", otra = "Otra" }

local function filasMedidor(V, M, cubos, ranking)
	local lista = ranking and M.Ranking(cubos) or M.Agrupar(cubos)
	if #lista == 0 then
		V:Vacio("Sin datos aún", ranking and "Todavía no hay nada con 5 minutos o más medidos." or "Todavía no se midió nada en esta sesión.")
		return
	end
	V:Columnas({ { "Dónde y qué", 290 }, { "Tiempo", 100 }, { "Oro por hora", 170 }, { "Experiencia por hora", 170 }, { "Pasadas", 110 } })
	for _, c in ipairs(lista) do
		local corto = c.seg < (M.MIN_SEG or 300)
		local neto = (c.ganado or 0) - (c.gastado or 0) + (c.valor or 0)
		V:Fila({ celdas = {
			{ tostring(c.zona), ACT_NOMBRE[c.act] or tostring(c.act) },
			{ floor(c.seg / 60) .. " min" },
			{ corto and "|cff9ba2b9poco tiempo|r" or A.Monedas(math.max(0, M.PorHora(neto, c.seg))), corto and ("total " .. A.Monedas(math.max(0, neto))) or ("dinero + botín" .. (neto < 0 and " (perdiste)" or "")) },
			{ corto and "—" or (M.Miles(M.PorHora(c.xp or 0, c.seg))) },
			{ (c.pasadas or 0) > 0 and tostring(c.pasadas) or "—", (c.pasadas or 0) > 0 and (A.Monedas(math.max(0, neto / c.pasadas)) .. " c/u") or "" },
		} })
	end
end

Hub.Seccion({
	clave = "MambaMedidor", nombre = "Medidor", icono = "hourglass", orden = 160, addon = "Medidor",
	pestanas = { { key = "sesion", label = "Esta sesión" }, { key = "mejor", label = "Lo que más rinde" }, { key = "todo", label = "Todo lo guardado" } },
	titulo = function() return "Medidor", "Cuánto oro y experiencia te deja cada cosa que haces, por hora" end,
	nav = function(est)
		local M = _G.Medidor
		local items = {}
		for _, k in ipairs(ACT) do items[#items + 1] = { key = k, label = ACT_NOMBRE[k] } end
		return items, M and M.pj and M.pj.act
	end,
	onNav = function(est, key)
		local M = _G.Medidor
		if M and M.pj and M.ACTIVIDADES[key] then M.pj.act = key; if M.ActualizarClave then pcall(M.ActualizarClave) end end
	end,
	dibujar = function(est, V)
		local M = _G.Medidor
		if not (M and M.pj) then V:Vacio("Sin datos aún", "El Medidor todavía está cargando: vuelve en unos segundos.") return end
		local a = M.actual
		V:Panel({ titulo = M.pausa and "Reloj en pausa" or "Midiendo", texto = (a and (tostring(a.zona) .. " · " .. (ACT_NOMBRE[a.act] or a.act) .. " · nivel " .. a.nivel) or "")
			.. "\nLo que estás haciendo ahora se elige en la barra de la izquierda.",
			boton2 = { M.pausa and "Seguir midiendo" or "Pausar el reloj", function() M.pausa = not M.pausa end } })
		local p = est.pestana or "sesion"
		if p == "sesion" then filasMedidor(V, M, M.sesion or {}, false)
		elseif p == "mejor" then filasMedidor(V, M, M.pj.cubos or {}, true)
		else
			filasMedidor(V, M, M.pj.cubos or {}, false)
			if est.borrar then
				V:Botones({ { "Sí, borrar todo de este personaje", function() M.pj.cubos, M.pj.precios, M.sesion = {}, {}, {}; pcall(M.TomarBase); est.borrar = nil end }, { "No", function() est.borrar = nil end } }, "¿Seguro? No se puede deshacer.")
			else
				V:Botones({ { "Borrar lo guardado…", function() est.borrar = true end } })
			end
		end
	end,
})

---------------------------------------------------------------- Errores
Hub.Seccion({
	clave = "MambaErrores", nombre = "Errores", icono = "bug", orden = 170,
	titulo = function()
		local db = _G.MambaErroresDB
		local n = db and db.lista and #db.lista or 0
		return "Errores", n == 0 and "Sin errores guardados" or (n .. (n == 1 and " error guardado" or " errores guardados") .. " · el más nuevo arriba")
	end,
	dibujar = function(est, V)
		local db = _G.MambaErroresDB
		local lista = db and db.lista or {}
		if #lista == 0 then
			V:Vacio("Sin errores", "Ningún addon falló desde que se borró la lista. Si algo se ve raro, vuelve aquí.")
			return
		end
		if est.borrar then
			V:Botones({ { "Sí, vaciar la lista", function() db.lista = {}; est.borrar = nil end }, { "No", function() est.borrar = nil end } }, "¿Seguro?")
		else
			V:Botones({ { "Vaciar la lista", function() est.borrar = true end } }, "Para pedir ayuda, mándale a Cristian una captura de esta pantalla.")
		end
		V:Columnas({ { "Error", 640 }, { "Cuándo", 200 } })
		for i = #lista, math.max(1, #lista - 60), -1 do
			local e = lista[i]
			local msg = tostring(e.msg or "?"):gsub("Interface[\\/]AddOns[\\/]", "")
			V:Fila({ celdas = { { (e.tipo == "lua" and "" or "|cfffabf4dbloqueada:|r ") .. msg:sub(1, 110), msg:sub(111, 220) },
				{ tostring(e.hora or ""), "× " .. (e.veces or 1) } },
				tip = function(self)
					local W = _G.Polestar and _G.Polestar.Widgets
					local l = {}
					for x in tostring(e.pila or ""):gmatch("[^\n]+") do if #l < 10 then l[#l + 1] = x end end
					if W and W.Tooltip then W.Tooltip(self, "ANCHOR_LEFT", msg:sub(1, 200), l) end
				end })
		end
	end,
})
