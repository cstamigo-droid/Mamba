-- mock_polestar_nav.lua: lo mínimo de Polestar para cargar su planificador REAL (Nav/Travel.lua y Nav/TravelData.lua)
-- fuera del juego, y así probar el motor de «Llévame» (Asistente/Llevame.lua) con rutas de verdad.
-- El mundo <-> mapa (Compat.MapToWorld) usa los marcos de zona de TravelData (MARCOS[map] = { c, top, bottom, left, right }),
-- como Asistente_Servicios: x% = (wy - left) / (right - left) * 100, y% = (wx - top) / (bottom - top) * 100.
-- Licencia: GPL-3.0-only.
local ns = { Nav = {}, Maps = {} }
NS_POLESTAR = ns
ns.L = setmetatable({}, { __index = function(_, k) return k end })
local defaults = {}
function ns.RegisterDefaults(grupo, t) for k, v in pairs(t) do defaults[grupo .. "." .. k] = v end end
function ns.Get(k) if AJUSTE_NAV and AJUSTE_NAV[k] ~= nil then return AJUSTE_NAV[k] end return defaults[k] end
function ns.On() end
function ns.RegisterEvent() end
function ns.OnLogin() end
function ns.RegisterCommand() end
function ns.Print() end
function ns.Fire() end
function ns.SafeCall(f, ...) return pcall(f, ...) end
function ns.NewTicker() return { Cancel = function() end } end
CHAR = { flags = { fp = {} }, flightTimes = {} }
function ns.CharState() return CHAR end
function ns.Maps.CharTable(k) CHAR[k] = CHAR[k] or {} return CHAR[k] end
function ns.Maps.LearnedFlight(a, b)
	local t = CHAR.flightTimes[tostring(a) .. ">" .. tostring(b)]
	return type(t) == "number" and t or nil
end
function ns.Nav.RegisterModule() end
function ns.Nav.HandedOff() return false end
function ns.Nav.GetTarget() return nil end

MARCOS = MARCOS or {}
JUGADOR = JUGADOR or { c = 1, wx = 0, wy = 0 }
local C = {}
ns.Compat = C
function C.GetPlayerInfo() return { faction = FACCION or "Horde", class = CLASE or "DRUID" } end
function C.GetPlayerWorldPosition() return JUGADOR.c, JUGADOR.wx, JUGADOR.wy end
function C.MapToWorld(map, x, y)
	local m = MARCOS[map]
	if not (m and x and y) then return nil end
	return m.c, m.top + y / 100 * (m.bottom - m.top), m.left + x / 100 * (m.right - m.left)
end
function C.WorldToMap(c, wx, wy, map)
	local m = MARCOS[map]
	if not m or m.c ~= c then return nil end
	return (wy - m.left) / (m.right - m.left) * 100, (wx - m.top) / (m.bottom - m.top) * 100
end
function C.GetMapName(map) return "Mapa " .. tostring(map) end
function C.GetItemCount(id) if id == 6948 then return PIEDRA and 1 or 0 end return 0 end
function C.GetBindLocation() return PIEDRA end
function C.GetAreaName() return nil end
function C.GetItemBaseCooldown() return 3600000 end
function GetItemCooldown(id) if id == 6948 and PIEDRA_ESPERA then return GetTime() - (3600 - PIEDRA_ESPERA), 3600 end return 0, 0 end
C_Container = nil
C_Item = nil
debugprofilestop = nil
GetServerTime = GetServerTime or function() return 1700000000 end
GetTime = GetTime or function() return RELOJ or 1000 end
