-- Asistente/Grupos.lua: las entradas de Mamba en el riel de Polestar y la API pública para los otros módulos.
-- Riel (acordado con Mamba_Plan, 18-11): Mi plan = 21 y la Interfaz = 210 (Mamba_*), Equipo = 100,
-- Oro = 110, Ir a… = 115, Ciudad = 120, y Errores al pie, junto a Opciones.
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = A.Hub

Hub.Grupo({ clave = "MambaGrupoEquipo", nombre = "Equipo", icono = "qol-upgrade", orden = 100, partes = { "MambaEquipo", "MambaClase" } })
Hub.Grupo({ clave = "MambaGrupoOro", nombre = "Oro", icono = "qol-coin", orden = 110, partes = { "MambaSubasta", "MambaMedidor" } })
-- «Ir a…» con su propia entrada en el riel, a la vista (K58/K108); Ciudad = Servicios + Capa
Hub.Grupo({ clave = "MambaGrupoIrA", nombre = "Ir a…", icono = "icon-goto", orden = 115, partes = { "MambaIrA" } })
Hub.Grupo({ clave = "MambaGrupoCiudad", nombre = "Ciudad", icono = "icon-talk", orden = 120, partes = { "MambaServicios", "MambaCapa" } })
Hub.Seccion({
	clave = "MambaMover", nombre = "Mover", icono = "resize", orden = 890,
	titulo = function() return "Mover elementos", "Pon cada parte de Mamba donde quieras, con el tamaño que quieras" end,
	dibujar = function(est, V)
		local W = A.Ventanas
		if not W then V:Vacio("Sin datos aún", "Falta el módulo de ventanas.") return end
		local n = 0
		for _ in pairs(W.marcos) do n = n + 1 end
		V:Panel({ titulo = W.moviendo and "Estás moviendo los elementos" or "Mover elementos",
			texto = (W.moviendo and "Arrastra cada recuadro verde a donde quieras; la rueda del ratón cambia su tamaño. Se guarda solo, para este personaje." or
				"Muestra cada parte de Mamba con un recuadro verde: arrástralo a donde quieras y usa la rueda para su tamaño.")
				.. "\n" .. n .. " elementos registrados. En combate no se mueve nada.",
			boton = { W.moviendo and "Terminar" or "Mover elementos", function()
				local ok, motivo = W.ModoMover(not W.moviendo)
				if ok and W.moviendo and _G.PolestarPicker then _G.PolestarPicker:Hide() end
				est.aviso = motivo
			end } })
		if est.aviso then V:Nota("|cfffabf4d" .. est.aviso .. "|r"); est.aviso = nil end
		V:Interruptor("Fijar todo (que nada se mueva)", W.Fijas(), function(v) W.Fijar(v) end)
		V:Botones({ { "Restablecer posiciones", function() W.Restablecer() end } }, "Devuelve cada elemento a su lugar y tamaño de siempre.")
	end,
})
Hub.Grupo({ clave = "MambaGrupoMover", nombre = "Mover", icono = "resize", orden = 890, foot = true, partes = { "MambaMover" } })
Hub.Grupo({ clave = "MambaGrupoErrores", nombre = "Errores", icono = "bug", orden = 900, foot = true, partes = { "MambaErrores" } })

---------------------------------------------------------------- API pública (_G.MambaAPI)
-- Para «Mi plan» (Mamba_Plan) y cualquier otro módulo: solo lectura, y cada función devuelve nil si el dato
-- todavía no está (módulo sin cargar, en combate, sin escaneo). Ninguna escribe en el chat.
local API = {}
_G.MambaAPI = API

local function cargar(addon)
	local C = C_AddOns
	if C and C.IsAddOnLoaded and C.IsAddOnLoaded(addon) then return true end
	if A.EnCombate and A.EnCombate() then return false end
	if C and C.LoadAddOn then pcall(C.LoadAddOn, addon) end
	return C and C.IsAddOnLoaded and C.IsAddOnLoaded(addon) or false
end

-- Abre una parte del hub: "MambaEquipo" | "MambaClase" | "MambaSubasta" | "MambaMedidor" | "MambaIrA" |
-- "MambaServicios" | "MambaCapa" | "MambaErrores"; pestana: la clave de una de sus pestañas (o nil).
function API.Abrir(clave, pestana) return Hub.Abrir(clave, pestana) end

-- La mejor pieza que ya puedes conseguir, por ranura:
-- { [ranura] = { id, nombre, ranura, mazmorra, claveMazmorra, jefe, pct, entradas, mision, nivel, mejoraPct } }
function API.MejorasPorRanura()
	if not cargar("Asistente_Equipo") or not A.EquipoContexto then return nil end
	local ok, c = pcall(A.EquipoContexto)
	if not (ok and c) then return nil end
	local out = {}
	for r, x in pairs(c.ya) do
		local p = x.p
		out[r] = { id = p.id, nombre = p.nombre, ranura = r, mazmorra = x.m.nombre, claveMazmorra = x.m.clave, jefe = p.jefe,
			pct = p.pct, entradas = p.pct and p.pct > 0 and math.ceil(100 / p.pct) or nil, mision = p.mision, nivel = p.nivelMin,
			mejoraPct = not (c.porRanura[r] and c.porRanura[r].ilegible) and p.pctMejora or nil }
	end
	return out
end

-- ¿Qué mazmorra conviene repetir? { clave, nombre, min, max, mejoraPorEntradaPct, siguiente = { nombre, pct } } | nil
function API.MazmorraRecomendada()
	if not cargar("Asistente_Equipo") or not A.EquipoContexto then return nil end
	local ok, c = pcall(A.EquipoContexto)
	if not (ok and c and c.rec) then return nil end
	local function pct(x) return c.total > 0 and x.valorLegible / c.total * 100 or nil end
	return { clave = c.rec.m.clave, nombre = c.rec.m.nombre, min = c.rec.m.min, max = c.rec.m.max, mejoraPorEntradaPct = pct(c.rec),
		siguiente = c.seg and { nombre = c.seg.m.nombre, pct = pct(c.seg) } or nil }
end

-- La lógica de clase (Asistente_Clase): builds con su fuente, comparar con tus talentos, profesiones.
--   API.Clase().Builds(clase, rol, uso) · .BuildPorClave(clase, clave) · .LeerTalentos(clase)
--   .Comparar(clase, build, rangos) · .Consejo(nivel, cmp, doble) · .Profesiones(clase, uso, spec) · .BonoRaza(raza)
function API.Clase()
	if not cargar("Asistente_Clase") then return nil end
	local M = A.modulos and A.modulos.clase
	return M and M.C or nil
end

-- Precio de un objeto en la subasta: precio (cobre, por unidad), de dónde ("subasta" | "vendedor"), edad del
-- escaneo en segundos. nil si no hay dato.
function API.PrecioObjeto(id)
	local T = _G.Tasador
	if not (T and T.PrecioMercado and T.DiaHoy) then return nil end
	local ok, p, fuente = pcall(T.PrecioMercado, id, T.DiaHoy())
	if not (ok and p) then return nil end
	return p, fuente, T.EdadFoto and T.EdadFoto() or nil
end

-- El ritmo de oro del Medidor: { actual = cobre/h (esta sesión, nil con menos de 5 min), mejor = { zona, act, cobreHora } }
function API.OroPorHora()
	local M = _G.Medidor
	if not (M and M.pj) then return nil end
	local out = {}
	local ok, r = pcall(M.Ranking, M.sesion or {})
	if ok and r and r[1] then out.actual = r[1].totalHora end
	local ok2, r2 = pcall(M.Ranking, M.pj.cubos or {})
	if ok2 and r2 and r2[1] then out.mejor = { zona = r2[1].zona, act = r2[1].act, cobreHora = r2[1].totalHora } end
	return out
end

-- El menú del objeto (Mamba sugiere / tú eliges: Subastar, Al vendedor, Guardar, Basura), para reusarlo desde
-- otras bolsas (Mamba_Bolsas): API.MenuObjeto(ancla, itemID). nil si el objeto no está en las bolsas.
function API.MenuObjeto(ancla, id)
	if not (A.MenuObjeto and id) then return nil end
	if not cargar("Tasador") then return nil end
	return A.MenuObjeto(ancla, id)
end

-- Qué sugiere Mamba para lo que hay en las bolsas: lista de { id, link, cantidad, calidad, vendedor (cobre),
-- sug = "subastar"|"vendedor"|"guardar"|"basura", motivo, elegido (lo que eligió el jugador o nil), precio }.
function API.Bolsas()
	if not (A.BolsasMamba and cargar("Tasador")) then return nil end
	local ok, l = pcall(A.BolsasMamba)
	return ok and l or nil
end

-- Ventanas que se mueven a donde uno quiera (Ventanas.lua): lugar por personaje, dentro de la pantalla, candado
-- y «Restablecer posiciones» de Ajustes › Mamba › Ventanas.
--   API.Movible(marco, nombre, asa)  -- asa: de dónde se arrastra (nil: el marco entero)
--   API.AlRestablecer(fn)            -- para quien guarda sus lugares por su cuenta (barras)
--   API.VentanasFijas() -> true si el jugador las fijó
function API.Movible(marco, nombre, asa, opciones) return A.Ventanas and A.Ventanas.Movible(marco, nombre, asa, opciones) end
function API.AlRestablecer(fn) if A.Ventanas then A.Ventanas.AlRestablecer(fn) end end
function API.VentanasFijas() return A.Ventanas and A.Ventanas.Fijas() or false end

-- La ventana «Servicios de <ciudad>» cuando el jugador quiera (K108). Fuera de una ciudad: la más cercana.
--   API.CiudadMasCercana() -> uiMap de la ciudad con lista de servicios más cercana (la actual si estás en una)
--   API.AbrirServicios(uiMap?) -> true si se abrió
local function continenteDe(m)
	local CM = C_Map
	local tipo = Enum and Enum.UIMapType and Enum.UIMapType.Continent or 2
	for _ = 1, 8 do
		local i = m and CM and CM.GetMapInfo and CM.GetMapInfo(m)
		if not i then return nil end
		if i.mapType == tipo then return m end
		m = i.parentMapID
	end
end

function API.CiudadMasCercana()
	if not cargar("Asistente_Servicios") then return nil end
	local S = A.modulos and A.modulos.servicios
	local ciudades = S and S.datos and S.datos.ciudades
	if not ciudades then return nil end
	local m = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if m and ciudades[m] then return m end
	local cont = continenteDe(m)
	local p = cont and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(cont, "player")
	local px, py
	if p then px, py = p:GetXY() end
	local mejor, dist
	for um in pairs(ciudades) do
		if cont and continenteDe(um) == cont and px and C_Map.GetMapRectOnMap then
			local ok, x1, x2, y1, y2 = pcall(C_Map.GetMapRectOnMap, um, cont)
			if ok and x1 then
				local d = ((x1 + x2) / 2 - px) ^ 2 + ((y1 + y2) / 2 - py) ^ 2
				if not dist or d < dist then mejor, dist = um, d end
			end
		end
	end
	if mejor then return mejor end
	-- en otro continente (o sin posición): la primera ciudad con lista, en orden fijo
	local claves = {}
	for um in pairs(ciudades) do claves[#claves + 1] = um end
	table.sort(claves)
	return claves[1]
end

function API.AbrirServicios(uiMap)
	if not cargar("Asistente_Servicios") then return false end
	local S = A.modulos and A.modulos.servicios
	if not (S and S.Abrir) then return false end
	return S.Abrir(uiMap or API.CiudadMasCercana()) and true or false
end

-- Deja la pestaña Vender de la subasta lista con el objeto y su precio (cobre por unidad, o nil: el de la subasta
-- lo pone el jugador). El último clic, publicar, es del jugador. -> true | false, motivo
-- Solo funciona con el subastador abierto ("Habla con el subastador primero.").
function API.PonerEnSubasta(id, precio)
	if not (A.PonerEnSubasta and cargar("Tasador")) then return false, "Falta el Tasador." end
	local ok, r, motivo = pcall(A.PonerEnSubasta, id, precio)
	if not ok then return false, tostring(r) end
	return r and true or false, motivo
end

-- El modo «Mover elementos» (como el modo de edición): API.ModoMover(true|false) -> ok, motivo;
-- API.AlModoMover(fn(activo)) para mostrar lo que está escondido mientras se mueve.
function API.ModoMover(si) if A.Ventanas then return A.Ventanas.ModoMover(si) end return false end
function API.AlModoMover(fn) if A.Ventanas then A.Ventanas.AlModoMover(fn) end end

-- La usan: la venta de basura de Polestar (QoL/Vendor.lua, parche P16) y Mamba_Bolsas cuando la sume.
-- K115: ¿se puede vender este objeto? -> motivo (texto) si NO, o nil. Una sola entrada para todos los módulos:
-- la lista por id de ForeverTDB del Tasador (Tasador/Mecanicas.lua: saco de dormir, ecos, llaves...), la regla del
-- Tasador (misión, llave, ligado de utilidad, si se pasa el objeto entero) y la de Profesiones (lo VITAL).
function API.NoVender(id)
	id = tonumber(id)
	if not id then return nil end
	local T = _G.Tasador
	if T and T.MECANICAS and T.MECANICAS[id] then return "Lo usas tú (mecánica de Forever): no lo vendas." end
	if T and T.Protegido then
		local f = (C_Item and C_Item.GetItemInfo) or GetItemInfo
		local ok, _, _, _, _, _, _, _, _, _, _, _, clase, _, liga = pcall(f, id)
		if ok and clase then
			local m = T.Protegido({ id = id, clase = clase, liga = liga })
			if m then return m end
		end
	end
	local MP = _G.MambaProfesiones
	if type(MP) == "table" and MP.NoVender then
		local ok, m = pcall(MP.NoVender, id)
		if ok and type(m) == "string" and m ~= "" then return m end
	end
	return nil
end

-- K116: ¿es una mecánica de Forever (saco de dormir, ecos, apuntes, llaves...)? Lista por id de ForeverTDB
-- (Tasador/Mecanicas.lua). -> true | false
function API.EsMecanica(id)
	local T = _G.Tasador
	id = tonumber(id)
	return (id and T and T.MECANICAS and T.MECANICAS[id]) and true or false
end

