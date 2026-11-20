-- Generado por tools/asistente/generador/calabozos.py. NO editar a mano: volver a generar.
-- Licencia: GPL-3.0-only. Datos: tablas del cliente WoW Forever (Blizzard) vía wago.tools, build 1.60.1.70959 (GroupFinderActivity, AreaTable, enUS y esMX);
-- entradas: data/codex/entrances.json de Polestar (grabaciones de jugadores) o un punto de paso de Polestar_Nav (aprox.);
-- zonas en español: Asistente_Equipo/Datos_Mazmorras.lua.
-- Las mazmorras y bandas de Forever que el Codex de Polestar no trae (K122). Mamba_Panel/Calabozos.lua las registra.
-- De temporada, fuera (todas sus filas con PlayerCondition, sin Codex): mapas 2784, 2789, 2791, 2804, 2832, 2856, 2875.
local _, N = ...
N.CALABOZOS = {
	{ key = "the-drowned-city", name = "La Ciudad Anegada", en = "The Drowned City", map = 2970, kind = "dungeon", forever = true, minLevel = 35, maxLevel = 42, players = 5, floor = 35, entrance = { map = 1434, x = 21.6, y = 27.7 }, zone = 1434, zoneName = "Vega de Tuercespina", entradaFuente = "grabaciones de jugadores (Polestar, data/codex/entrances.json)", misiones = 6 },
	{ key = "blackmaw-hold", name = "Bastión Faucenegra", en = "Blackmaw Hold", map = 2974, kind = "dungeon", forever = true, minLevel = 55, maxLevel = 60, players = 5, floor = 55, entrance = { map = 1447, x = 38.6, y = 33.0 }, zone = 1447, zoneName = "Azshara", entradaFuente = "aprox.: el punto de paso de Polestar en Bastión Faucenegra (Polestar_Nav)", misiones = 2 },
	{ key = "alcaz-prison", name = "Prisión de Alcaz", en = "Alcaz Prison", map = 2994, kind = "dungeon", forever = true, minLevel = 48, maxLevel = 55, players = 5, floor = 48, entrance = { map = 1445, x = 75.4, y = 13.9 }, zone = 1445, zoneName = "Marjal Revolcafango", entradaFuente = "grabaciones de jugadores (Polestar, data/codex/entrances.json)", misiones = 13 },
	{ key = "the-shapers-terrace", name = "El Bancal del Creador", en = "The Shaper's Terrace", map = 3001, kind = "dungeon", forever = true, minLevel = 58, maxLevel = 60, players = 5, floor = 58, zone = 1449, zoneName = "Cráter de Un'Goro", misiones = 0 },
	{ key = "kroldok-stronghold", name = "Bastión de Krol'dok", en = "Krol'dok Stronghold", map = 3039, kind = "dungeon", forever = true, minLevel = 40, maxLevel = 47, players = 5, floor = 43, entrance = { map = 2548, x = 37.5, y = 38.2 }, zone = 2548, zoneName = "Claros del Río", entradaFuente = "grabaciones de jugadores (Polestar, data/codex/entrances.json)", misiones = 5 },
}
-- Las del Codex sin zona o sin entrada: Mamba completa la zona y dice "entrada: datos en camino".
N.CALABOZOS_HUECOS = {
	{ key = "naxxramas", sinEntrada = true },
	{ key = "city-of-dalaran", zone = 1416, zoneName = "Montañas de Alterac", sinEntrada = true },
	{ key = "excavation-site-wetlands", sinEntrada = true },
}
