# -*- coding: utf-8 -*-
"""Carga el módulo Gear REAL de Polestar (Gear/*.lua + Polestar_ItemDB) en Lua 5.1 (lupa), con lo mínimo
de su núcleo simulado. Lo usan las pruebas de Asistente_Equipo y equipo_tablas.py, así el asesor se
prueba contra el mismo código que corre en el juego (no contra una copia).

    ns = cargar_gear(L, addons)    # deja Polestar = ns como global, igual que Core/Init.lua
    ns.Gear.Client.PlayerClass = ...  # Polestar deja reemplazar Gear.Client "so tests can replace it"
"""
import pathlib

ADDONS = pathlib.Path(r"C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns")

NUCLEO = r"""
local ns = {}
Polestar = ns
ns.L = setmetatable({}, { __index = function(_, k) return k end })
ns.Compat = {
  Readable = function(v) if v ~= nil and issecretvalue and issecretvalue(v) then return nil end return v end,
  GetSkillRank = function() return nil end,
  IsSpellKnown = function() return false end,
  IsPlayerSpell = function() return false end,  -- Polestar 0.4.0.1 (Gear.lua:1149)
  AddOnPresent = function() return false end,   -- Polestar 0.4.0.1
  -- Polestar 0.4.0.1 (Core/Compat.lua:345): Gear lee los talentos por aquí. Copia de su rama
  -- C_ClassTalents.GetActiveConfigID (el simulador no tiene C_SpecializationInfo).
  TalentConfigs = function()
    local CT = C_ClassTalents
    if CT and CT.GetActiveConfigID then
      local ok, c = pcall(CT.GetActiveConfigID)
      if ok and type(c) == "number" then return { c }, nil, nil, c end
    end
    return {}, nil, nil, nil
  end,
}
ns.Names = { Item = function() end, Npc = function() end, Area = function() end, Quest = function() end }
ns.AJUSTES = { ["gear.enabled"] = true, ["gear.useBags"] = true, ["gear.minUpgrade"] = 1 }
function ns.RegisterDefaults() end
function ns.Get(path) return ns.AJUSTES[path] end
function ns.Set(path, v) ns.AJUSTES[path] = v end
ns.handlers = {}
function ns.On(ev, fn) ns.handlers[ev] = ns.handlers[ev] or {}; table.insert(ns.handlers[ev], fn) end
function ns.Fire(ev, ...) for _, fn in ipairs(ns.handlers[ev] or {}) do fn(...) end end
function ns.RegisterEvent() end
function ns.OnLogin(fn) ns.alEntrar = fn end
function ns.RegisterCommand() end
function ns.Print() end
function ns.LoadAddOn() return false end
ns.DB = {}
return ns
"""


def cargar_gear(L, addons=ADDONS):
    addons = pathlib.Path(addons)
    ns = L.execute(NUCLEO)
    loader = L.eval('function(src, name, ns) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Polestar", ns) end')
    gear = addons / "Polestar" / "Gear"
    for f in ("ItemDB.lua", "Weights.lua", "SpecData.lua", "PawnStats.lua", "Pawn.lua", "Gear.lua"):
        loader((gear / f).read_text(encoding="utf-8"), f"Polestar/Gear/{f}", ns)
    for f in ("Items.lua", "Forever.lua"):  # el addon de datos que ItemDB.Load carga bajo demanda
        L.execute((addons / "Polestar_ItemDB" / f).read_text(encoding="utf-8"))
    return ns


def fijar_personaje(L, ns, clase, nivel, rol=None, raza=("Tauren", 6, "Horde")):
    """Para las tablas fijas: un personaje de esa clase y nivel, sin nada puesto y con el rol elegido."""
    G = ns.Gear
    C = G.Client
    C.PlayerClass = L.eval(f'function() return "{clase}", 1 end')
    C.PlayerLevel = L.eval(f"function() return {int(nivel)} end")
    if raza:
        C.PlayerRace = L.eval(f'function() return "{raza[0]}", {raza[1]}, "{raza[2]}" end')
    else:  # sin raza: sin rasgos raciales, para tablas que valgan para cualquier raza
        C.PlayerRace = L.eval('function() return nil, nil, "Horde" end')
    C.InventoryLink = L.eval("function() return nil end")
    C.BagSlots = L.eval("function() return 0 end")
    C.TreeColumns = L.eval("function() return nil end")
    ns.AJUSTES[f"gear.spec.{clase}"] = rol or "auto"
    G.RefreshPlayer()
