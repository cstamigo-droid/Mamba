-- Asistente/Grupos.lua: las entradas de Mamba en el riel de Polestar y la API pública para los otros módulos.
-- Riel (acordado con Mamba_Plan, 18-11): Mi plan = 20 y la Interfaz = 210 (Mamba_*), Equipo = 100,
-- Oro = 110, Ciudad = 120, y Errores al pie, junto a Opciones. Así el riel cabe en el alto de la ventana.
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = A.Hub

Hub.Grupo({ clave = "MambaGrupoEquipo", nombre = "Equipo", icono = "qol-upgrade", orden = 100, partes = { "MambaEquipo", "MambaClase" } })
Hub.Grupo({ clave = "MambaGrupoOro", nombre = "Oro", icono = "qol-coin", orden = 110, partes = { "MambaSubasta", "MambaMedidor" } })
Hub.Grupo({ clave = "MambaGrupoCiudad", nombre = "Ciudad", icono = "icon-goto", orden = 120, partes = { "MambaIrA", "MambaServicios", "MambaCapa" } })
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
