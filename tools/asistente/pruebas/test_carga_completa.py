# Prueba de CARGA COMPLETA del paquete Mamba (lo que arma tools/asistente/armar_instalar.py), fuera del juego,
# con Lua 5.1 (lupa): TODOS los addons juntos, en el orden de carga del cliente, con las SavedVariables REALES
# del jugador (solo lectura), y los eventos de entrada al mundo.
#
# Informa:
#   - errores de Lua (archivo:línea) al cargar cada archivo, en cada evento, en cada C_Timer y los que los addons
#     mandan a geterrorhandler();
#   - GLOBALES PISADAS: un addon que ESCRIBE una global del juego (aunque sea con el mismo valor: en el juego eso
#     la contamina; así nació el bug de `SlashCmdList = SlashCmdList or {}` que bloqueaba el /run, 18-11).
#     Las globales del juego viven fuera de _G crudo, así TODA escritura pasa por __newindex y queda anotada
#     con su archivo:línea; además se compara rawequal antes/después;
#   - HOOKS DUPLICADOS: hooksecurefunc, SetScript/HookScript sobre objetos del juego (GameTooltip, UIParent…) y
#     TooltipDataProcessor.AddTooltipPostCall: qué addons enganchan lo mismo (aviso, no falla);
#   - CHOQUES DE COMANDOS: dos claves SLASH_* con el mismo texto, una clave de SlashCmdList escrita por dos addons,
#     o un comando que pisa uno del juego;
#   - SECCIONES DEL HUB: claves repetidas en Polestar.UI.RegisterSection y empates de `order` en el riel (aviso).
#   - RIEL SIN «PRÓXIMAMENTE» (K109): se abre cada sección del riel; ninguna puede mostrar «Próximamente» /
#     «Coming soon» ni quedar sin un solo texto a la vista (FALLA).
#   - K124 «TODO SE APAGA DESDE QUÉ SE MUESTRA»: cada addon de Mamba que escucha eventos del juego o cuelga un marco
#     de la pantalla publicó su MambaAPI.Interruptor (o está en tools/asistente/interruptores_pendientes.json con
#     dueño; esa lista solo se achica), cada interruptor cumple get/set y todos están en Ajustes › Mamba (FALLA).
#
# Sale con 1 si hay errores de Lua, globales pisadas, choques de comandos o una sección del riel en «Próximamente» o vacía.
#
# Uso (desde el repositorio Mamba):
#   python -I tools/asistente/pruebas/test_carga_completa.py [carpeta paquete] [--pj REINO/PERSONAJE] [--romper] [--detalle]
#   --romper: control negativo (agrega un addon falso que pisa SlashCmdList, repite /capa, engancha el cuadro dos
#             veces, da un error y suma al riel una sección que dice «Próximamente», un addon que escucha eventos sin
#             interruptor y un interruptor cuyo set no hace nada): la prueba TIENE que fallar y nombrarlo.
#   --detalle: además lista las globales con nombre de API que los addons leyeron y no existían en el simulado.
#
# Lo que el simulado NO hace (NO VERIFICADO aquí): marcos y plantillas definidos en XML (solo se cargan los
# <Script file=...>), OnUpdate, contaminación (taint) real, combate, addons ajenos al paquete que el jugador tenga
# instalados (salvo el Auctionator simulado de mock_wow.lua) y el orden exacto en que el cliente reparte ADDON_LOADED.
import pathlib
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).resolve().parent
args = [a for a in sys.argv[1:] if not a.startswith("--")]
ROMPER = "--romper" in sys.argv
DETALLE = "--detalle" in sys.argv
PJ = "91/Hope-Fé"
for i, a in enumerate(sys.argv):
    if a == "--pj" and i + 1 < len(sys.argv):
        PJ = sys.argv[i + 1]
        args = [x for x in args if x != PJ]
PAQUETE = pathlib.Path(args[0] if args else r"D:\rust\mamba_instalar").resolve()
CUENTA = pathlib.Path(r"C:\Program Files (x86)\World of Warcraft\_forever_\WTF\Account\<cuenta>")
SV_CUENTA = CUENTA / "SavedVariables"
SV_PJ = CUENTA / PJ / "SavedVariables"
TIPO_JUEGO = "camelot"  # el cliente de Forever: [AllowLoadGameType camelot] / [Game] = Camelot
GAME_DIR = "Camelot"

# ---------------------------------------------------------------------------------------------------------------
# 1) Los .toc: dependencias, LoadOnDemand, SavedVariables y archivos (con las condiciones de tipo de juego).
# ---------------------------------------------------------------------------------------------------------------
COND = re.compile(r"\[(AllowLoadGameType|ExcludeLoadGameType)\s+([^\]]+)\]")


def vale(linea):
    """(texto sin condiciones, ¿aplica a este cliente?)"""
    permitir, excluir = None, set()
    for tipo, lista in COND.findall(linea):
        tipos = {t.strip().lower() for t in lista.split(",")}
        if tipo == "AllowLoadGameType":
            permitir = (permitir or set()) | tipos
        else:
            excluir |= tipos
    texto = COND.sub("", linea).strip()
    ok = (permitir is None or TIPO_JUEGO in permitir) and TIPO_JUEGO not in excluir
    return texto, ok


def leer_toc(carpeta):
    toc = carpeta / f"{carpeta.name}.toc"
    meta, archivos = {}, []
    for cruda in toc.read_text(encoding="utf-8-sig").splitlines():
        cruda = cruda.strip()
        if not cruda:
            continue
        if cruda.startswith("##"):
            m = re.match(r"##\s*([^:]+):\s*(.*)", cruda)
            if m:
                texto, ok = vale(m.group(2))
                if ok:
                    meta.setdefault(m.group(1).strip(), texto)
            continue
        if cruda.startswith("#"):
            continue
        texto, ok = vale(cruda)
        if ok:
            archivos.append(texto.replace("[Game]", GAME_DIR).replace("\\", "/"))
    lista = lambda k: [x.strip() for x in meta.get(k, "").split(",") if x.strip()]  # noqa: E731
    deps = []
    for k in meta:
        if k.lower() in ("dependencies", "requireddeps") or re.fullmatch(r"dep\w*", k.lower()):
            deps += lista(k)
    return {
        "nombre": carpeta.name, "meta": meta, "archivos": archivos, "deps": deps, "opt": lista("OptionalDeps"),
        "lod": meta.get("LoadOnDemand", "0").strip() == "1",
        "sv": lista("SavedVariables"), "svpj": lista("SavedVariablesPerCharacter"),
    }


ADDONS = {}
for d in sorted(PAQUETE.iterdir(), key=lambda p: p.name.lower()):
    if d.is_dir() and (d / f"{d.name}.toc").exists():
        ADDONS[d.name] = leer_toc(d)

XML_SCRIPT = re.compile(r"<(Script|Include)\s+[^>]*?file\s*=\s*\"([^\"]+)\"", re.I)
XML_SIN_ARCHIVO = []  # .xml con marcos/plantillas que el simulado no crea


def archivos_lua(base, rel):
    """Expande un .xml del .toc a los .lua que nombra (<Script file=…>, <Include file=…> recursivo)."""
    ruta = base / rel
    if rel.lower().endswith(".lua"):
        return [rel]
    if not rel.lower().endswith(".xml") or not ruta.exists():
        return [rel]
    texto = ruta.read_text(encoding="utf-8-sig", errors="replace")
    if re.search(r"<(Frame|Button|CheckButton|ScrollFrame|StatusBar|Texture|FontString|EditBox|Slider)\b", texto):
        XML_SIN_ARCHIVO.append(rel)
    sub = pathlib.PurePosixPath(rel).parent
    out = []
    for _, f in XML_SCRIPT.findall(texto):
        hijo = str(sub / f.replace("\\", "/"))
        out += archivos_lua(base, hijo)
    return out


# ---------------------------------------------------------------------------------------------------------------
# 2) El runtime: los simulados compartidos (sin tocarlos) + lo que faltó, aquí.
# ---------------------------------------------------------------------------------------------------------------
L = LuaRuntime(unpack_returned_tuples=True)
L.execute((AQUI / "mock_wow.lua").read_text(encoding="utf-8"))
L.execute((AQUI / "mock_ventana.lua").read_text(encoding="utf-8"))
G = L.globals()

# Lo que los addons necesitaron y los simulados compartidos no traían. Cada nombre queda contado en FALTO.
EXTRA = r"""
FALTO = {}
local function falto(n) FALTO[#FALTO + 1] = n end
local M = getmetatable(UIParent)  -- la metatabla de los marcos de mock_ventana.lua

-- Marcos con nombre (GetName) y métodos con valor de vuelta que el juego da y el simulado no.
local nuevoOrig = NuevoMarco
function NuevoMarco(nombre)
	local f = nuevoOrig(nombre)
	rawset(f, "nombre", nombre)
	return f
end
rawset(M, "GetName", function(self) return rawget(self, "nombre") end); falto("Frame:GetName")
rawset(M, "GetObjectType", function(self) return rawget(self, "tipo") or "Frame" end); falto("Frame:GetObjectType")
rawset(M, "IsObjectType", function(self, t) return (rawget(self, "tipo") or "Frame") == t end); falto("Frame:IsObjectType")
rawset(M, "RegisterAllEvents", function(self) rawset(self, "todos", true) end); falto("Frame:RegisterAllEvents")
rawset(M, "RegisterUnitEvent", function(self, e) self.ev[e] = true end); falto("Frame:RegisterUnitEvent")
rawset(M, "UnregisterAllEvents", function(self) self.ev = {}; rawset(self, "todos", nil) end); falto("Frame:UnregisterAllEvents")
rawset(M, "IsEventRegistered", function(self, e) return self.ev[e] == true end); falto("Frame:IsEventRegistered")
rawset(M, "HasScript", function() return true end); falto("Frame:HasScript")
rawset(M, "GetNumPoints", function(self) return self.point and 1 or 0 end); falto("Frame:GetNumPoints")
rawset(M, "GetScale", function() return 1 end); falto("Frame:GetScale")
rawset(M, "GetEffectiveScale", function() return 1 end); falto("Frame:GetEffectiveScale")
rawset(M, "GetAlpha", function() return 1 end); falto("Frame:GetAlpha")
rawset(M, "GetFrameLevel", function() return 1 end); falto("Frame:GetFrameLevel")
rawset(M, "GetFrameStrata", function() return "MEDIUM" end); falto("Frame:GetFrameStrata")
rawset(M, "GetCenter", function() return 100, 100 end); falto("Frame:GetCenter")
rawset(M, "GetLeft", function() return 0 end); falto("Frame:GetLeft")
rawset(M, "GetRight", function() return 100 end); falto("Frame:GetRight")
rawset(M, "GetTop", function() return 100 end); falto("Frame:GetTop")
rawset(M, "GetBottom", function() return 0 end); falto("Frame:GetBottom")
rawset(M, "GetSize", function(self) return self.w or 100, self.h or 300 end); falto("Frame:GetSize")
rawset(M, "GetFont", function() return "Fonts\\FRIZQT__.TTF", 12, "" end); falto("FontString:GetFont")
rawset(M, "GetTextColor", function() return 1, 1, 1, 1 end); falto("FontString:GetTextColor")
rawset(M, "GetChildren", function() return end); falto("Frame:GetChildren")
rawset(M, "GetRegions", function() return end); falto("Frame:GetRegions")
rawset(M, "GetNumChildren", function() return 0 end); falto("Frame:GetNumChildren")
rawset(M, "IsMouseOver", function() return false end); falto("Frame:IsMouseOver")
rawset(M, "IsProtected", function() return false end); falto("Frame:IsProtected")
rawset(M, "IsForbidden", function() return false end); falto("Frame:IsForbidden")
rawset(M, "CanChangeProtectedState", function() return true end); falto("Frame:CanChangeProtectedState")
rawset(M, "NumLines", function() return 0 end); falto("GameTooltip:NumLines")
rawset(M, "IsOwned", function() return false end); falto("GameTooltip:IsOwned")
rawset(M, "GetOwner", function(self) return self.dueno end); falto("GameTooltip:GetOwner")
rawset(M, "GetItem", function() return nil end); falto("GameTooltip:GetItem")
rawset(M, "GetUnit", function() return nil end); falto("GameTooltip:GetUnit")
rawset(M, "GetSpell", function() return nil end); falto("GameTooltip:GetSpell")
rawset(M, "CreateAnimationGroup", function(self) local f = NuevoMarco(); f.padre = self; return f end); falto("Frame:CreateAnimationGroup")
rawset(M, "CreateAnimation", function(self) local f = NuevoMarco(); f.padre = self; return f end); falto("AnimationGroup:CreateAnimation")
rawset(M, "CreateMaskTexture", function(self) local f = NuevoMarco(); f.padre = self; return f end); falto("Frame:CreateMaskTexture")
rawset(M, "CreateLine", function(self) local f = NuevoMarco(); f.padre = self; return f end); falto("Frame:CreateLine")
rawset(M, "GetFontString", function(self) local fs = rawget(self, "fs") or NuevoMarco(); rawset(self, "fs", fs); return fs end); falto("Button:GetFontString")
for _, n in ipairs({ "GetNormalTexture", "GetHighlightTexture", "GetPushedTexture", "GetDisabledTexture", "GetCheckedTexture", "GetStatusBarTexture", "GetScrollChild" }) do
	rawset(M, n, function(self) local k = "_" .. n; local t = rawget(self, k) or NuevoMarco(); t.padre = self; rawset(self, k, t); return t end)
end
falto("Button:Get*Texture")
rawset(M, "GetValue", function(self) return rawget(self, "valor") or 0 end); falto("Slider:GetValue")
rawset(M, "SetValue", function(self, v) rawset(self, "valor", v) end)
rawset(M, "GetMinMaxValues", function() return 0, 1 end); falto("Slider:GetMinMaxValues")
rawset(M, "GetVerticalScrollRange", function() return 0 end); falto("ScrollFrame:GetVerticalScrollRange")
rawset(M, "GetID", function(self) return rawget(self, "id") or 0 end); falto("Frame:GetID")
rawset(M, "SetID", function(self, i) rawset(self, "id", i) end)
rawset(M, "GetAttribute", function(self, k) local a = rawget(self, "attr"); return a and a[k] end); falto("Frame:GetAttribute")
rawset(M, "SetAttribute", function(self, k, v) local a = rawget(self, "attr") or {}; a[k] = v; rawset(self, "attr", a) end)
rawset(M, "GetChecked", function(self) return rawget(self, "marcado") end)
rawset(M, "SetChecked", function(self, v) rawset(self, "marcado", v) end)
rawset(M, "IsEnabled", function(self) return rawget(self, "inactivo") ~= true end)
rawset(M, "GetNumLetters", function(self) return #(self.text or "") end)
rawset(M, "GetCursorPosition", function() return 0 end)
rawset(M, "IsMouseEnabled", function(self) return self.raton end)
rawset(M, "GetDrawLayer", function() return "ARTWORK", 0 end)
rawset(M, "GetPoint", function(self) local p = self.point or {}; return p[1] or "CENTER", p[2], p[3] or "CENTER", p[4] or 0, p[5] or 0 end); falto("Frame:GetPoint")
rawset(M, "GetTexture", function(self) return self.texture end)
rawset(M, "GetTexCoord", function() return 0, 0, 0, 1, 1, 0, 1, 1 end)
rawset(M, "GetVertexColor", function() return 1, 1, 1, 1 end)
rawset(M, "GetBackdrop", function() return nil end)
rawset(M, "GetStringWidth", function(self) return #tostring(self.text or "") * 6 end) -- el juego acepta SetText(número)
rawset(M, "GetUnboundedStringWidth", function(self) return #tostring(self.text or "") * 6 end); falto("FontString:GetUnboundedStringWidth")
rawset(M, "GetNumLines", function(self) return 1 end); falto("FontString:GetNumLines (K109: abrir el hub)")
rawset(M, "GetLineHeight", function() return 14 end)
rawset(M, "IsTruncated", function() return false end)
rawset(M, "GetNumRegions", function() return 0 end)
-- (registrar un evento que el cliente de Forever no conoce da error, como en mock_wow.lua)
rawset(M, "RegisterEvent", function(self, e)
	if EVENTOS_DESCONOCIDOS and EVENTOS_DESCONOCIDOS[e] then
		error('Frame:RegisterEvent(): Attempt to register unknown event "' .. tostring(e) .. '"', 2)
	end
	self.ev[e] = true
end)

-- Objetos y marcos del juego que el simulado no traía.
local function marco(n) local f = NuevoMarco(n); f.tipo = "Frame"; return f end
WorldFrame = marco("WorldFrame"); falto("WorldFrame")
UIParent.nombre = "UIParent"; Minimap.nombre = "Minimap"; GameTooltip.nombre = "GameTooltip"
local chatOrig = DEFAULT_CHAT_FRAME
ChatFrame1 = marco("ChatFrame1"); falto("ChatFrame1")
function ChatFrame1:AddMessage(m) table.insert(chat, m) end
DEFAULT_CHAT_FRAME = ChatFrame1
SELECTED_CHAT_FRAME = ChatFrame1
ItemRefTooltip = marco("ItemRefTooltip"); falto("ItemRefTooltip (marco)")
ShoppingTooltip1 = marco("ShoppingTooltip1"); ShoppingTooltip2 = marco("ShoppingTooltip2")
for _, n in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PartyMemberFrame1", "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight",
	"MultiBarLeft", "MultiBarRight", "MicroButtonAndBagsBar", "BuffFrame", "CharacterFrame", "PaperDollFrame", "ContainerFrame1",
	"MerchantFrame", "QuestFrame", "QuestLogFrame", "GossipFrame", "WorldMapFrame", "SpellBookFrame", "ClassTrainerFrame", "TradeSkillFrame",
	"AuctionHouseFrame", "AuctionFrame", "MailFrame", "BankFrame", "LootFrame", "ObjectiveTrackerFrame", "QuestWatchFrame", "GameMenuFrame",
	"CompactRaidFrameContainer", "CompactPartyFrame", "CastingBarFrame", "PlayerCastingBarFrame", "MinimapCluster", "TimeManagerClockButton",
	"GameTimeFrame", "MiniMapTracking", "MinimapZoneText", "ChatFrameMenuButton", "FriendsFrame", "PVEFrame", "StaticPopup1",
	"ColorPickerFrame", "InterfaceOptionsFrame", "SettingsPanel", "AddonCompartmentFrame", "DropDownList1", "UIErrorsFrame",
	"ZoneTextFrame", "SubZoneTextFrame", "BagsBar", "MainMenuBarBackpackButton", "StatusTrackingBarManager", "EditModeManagerFrame",
	"ChatFrame2", "GeneralDockManager", "WorldMapFrameCloseButton", "PetActionBar", "StanceBar", "ExtraActionBarFrame", "TooltipMoneyFrame" }) do
	if _G[n] == nil then _G[n] = marco(n) end
end
falto("marcos de Blizzard con nombre (PlayerFrame, WorldMapFrame, …)")
WorldMapFrame.ScrollContainer = marco(); WorldMapFrame.ScrollContainer.padre = WorldMapFrame
function WorldMapFrame:GetMapID() return MAPA or 1456 end
ColorPickerFrame.Content = marco()
UIErrorsFrame.AddMessage = function() end
for _, n in ipairs({ "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge", "GameFontHighlight", "GameFontHighlightSmall",
	"GameFontHighlightLarge", "GameFontDisable", "GameFontDisableSmall", "GameFontWhite", "GameFontRed", "GameFontGreen",
	"GameFontNormalHuge", "SystemFont_Med3", "NumberFontNormal", "ChatFontNormal", "GameTooltipText", "GameTooltipHeaderText",
	"Tooltip_Med", "Tooltip_Small", "SystemFont_Shadow_Med1", "QuestFont", "GameFontBlack", "GameFontNormalMed3" }) do
	_G[n] = marco(n)
end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"; UNIT_NAME_FONT = STANDARD_TEXT_FONT; DAMAGE_TEXT_FONT = STANDARD_TEXT_FONT
falto("fuentes del juego (GameFontNormal…)")

-- Cuadro del objeto: los métodos que el simulado no tenía.
function GameTooltip:AddDoubleLine(a, b) table.insert(self.lineas or {}, tostring(a) .. " | " .. tostring(b)) end
function GameTooltip:ClearLines() self.lineas = {} end
falto("GameTooltip:AddDoubleLine/ClearLines")

-- API del juego.
function GetLocale() return "esMX" end; falto("GetLocale")
function GetBuildInfo() return "1.60.1", "70532", "Nov 18 2026", 16001 end; falto("GetBuildInfo")
function GetServerTime() return time() end; falto("GetServerTime")
function IsLoggedIn() return LOGUEADO == true end; falto("IsLoggedIn")
function InCombatLockdown() return false end; falto("InCombatLockdown")
function UnitAffectingCombat() return false end; falto("UnitAffectingCombat")
function UnitGUID(u) if u == "player" then return "Player-91-0000AAAA" end return nil end; falto("UnitGUID")
function UnitRace(u) if u == "player" then return "Tauren", "Tauren", 6 end end; falto("UnitRace")
function UnitSex() return 2 end; falto("UnitSex")
function UnitExists(u) return u == "player" or UNITS[u] ~= nil end; falto("UnitExists")
function UnitIsUnit(a, b) return a == b end; falto("UnitIsUnit")
function UnitIsDeadOrGhost() return false end; falto("UnitIsDeadOrGhost")
function UnitIsDead() return false end
function UnitIsGhost() return false end
function UnitHealth() return 1000 end; function UnitHealthMax() return 1000 end; falto("UnitHealth/Max")
function UnitPower() return 100 end; function UnitPowerMax() return 100 end; function UnitPowerType() return 0, "MANA" end; falto("UnitPower*")
function UnitXP() return 1000 end; function UnitXPMax() return 5000 end; function GetXPExhaustion() return nil end; falto("UnitXP/Max")
function UnitInParty() return false end; function UnitInRaid() return nil end; falto("UnitInParty/Raid")
function IsInGroup() return false end; function IsInRaid() return false end; function GetNumGroupMembers() return 0 end; falto("IsInGroup/Raid")
function UnitOnTaxi() return false end; function IsMounted() return false end; function IsFlying() return false end; function IsResting() return false end
function IsSwimming() return false end; function IsFalling() return false end; function IsIndoors() return false end; function IsOutdoors() return true end
falto("IsMounted/OnTaxi/…")
function UnitPosition() return 0, 0, 0, 1 end; falto("UnitPosition")
function UnitAura() return nil end; function UnitBuff() return nil end; function UnitDebuff() return nil end; falto("UnitAura")
C_UnitAuras = { GetAuraDataByIndex = function() return nil end, GetPlayerAuraBySpellID = function() return nil end, GetBuffDataByIndex = function() return nil end, GetDebuffDataByIndex = function() return nil end }; falto("C_UnitAuras")
function GetRealmName() return "Fé" end; falto("GetRealmName")
function GetNormalizedRealmName() return "Fé" end
function UnitFullName(u) if u == "player" then return "Hope", "Fé" end return UnitName(u) end
local unitNameOrig = UnitName
function UnitName(u) if u == "player" then return "Hope" end return unitNameOrig(u) end
falto("UnitName('player')")
function GetMoney() return 10000 end; falto("GetMoney")
function GetCoinTextureString(c) return tostring(c) .. "c" end; function GetCoinText(c) return tostring(c) .. "c" end; falto("GetCoinTextureString")
function GetZoneText() return "Cima del Trueno" end; function GetRealZoneText() return "Cima del Trueno" end
function GetSubZoneText() return "" end; function GetMinimapZoneText() return "Cima del Trueno" end; falto("GetZoneText")
function GetBindLocation() return "Cima del Trueno" end
function IsInInstance() return false, "none" end
function GetInstanceInfo() return "Kalimdor", "none", 0, "", 0, 0, false, 1 end; falto("GetInstanceInfo")
function GetCursorInfo() return nil end
function IsShiftKeyDown() return false end; function IsControlKeyDown() return false end; function IsAltKeyDown() return false end
function IsModifiedClick() return false end; function IsModifierKeyDown() return false end; falto("Is*KeyDown")
function GetScreenWidth() return 1920 end; function GetScreenHeight() return 1080 end; falto("GetScreenWidth/Height")
function GetFramerate() return 60 end; function GetNetStats() return 0, 0, 30, 30 end; function debugprofilestop() return (NOW or 0) * 1000 end
-- K124: las CVars guardan lo que se les pone (el cliente las guarda en Config.wtf, como una SavedVariable)
CVARS = {}
function GetCVar(n) return CVARS[n] or "0" end; function GetCVarBool(n) return GetCVar(n) == "1" end
function SetCVar(n, v) if v == true then v = "1" elseif v == false then v = "0" end CVARS[n] = v ~= nil and tostring(v) or nil end; falto("GetCVar")
C_CVar = { GetCVar = GetCVar, GetCVarBool = GetCVarBool, SetCVar = SetCVar }; falto("C_CVar")
function GetNumSkillLines() return 0 end; function GetSkillLineInfo() return nil end; falto("GetNumSkillLines")
function GetProfessions() return nil end
function GetNumSpellTabs() return 0 end; function GetSpellTabInfo() return nil end; falto("GetNumSpellTabs")
function GetSpellInfo(id) return nil end; function IsSpellKnown() return false end; function IsPlayerSpell() return false end; falto("GetSpellInfo")
function GetSpellCooldown() return 0, 0, 1 end; function GetSpellTexture() return nil end; function GetSpellLink() return nil end
C_Spell = { GetSpellInfo = function() return nil end, GetSpellName = function() return nil end, GetSpellTexture = function() return nil end,
	GetSpellCooldown = function() return nil end, IsSpellUsable = function() return false end, GetSpellLink = function() return nil end,
	DoesSpellExist = function() return false end, RequestLoadSpellData = function() end, GetSpellCharges = function() return nil end }; falto("C_Spell")
C_SpellBook = { GetNumSpellBookSkillLines = function() return 0 end, IsSpellKnown = function() return false end, GetSpellBookItemInfo = function() return nil end }; falto("C_SpellBook")
function GetNumQuestLogEntries() return 0, 0 end; function GetQuestLogTitle() return nil end; falto("GetNumQuestLogEntries")
function GetQuestLogSelection() return 0 end; function SelectQuestLogEntry() end; function GetQuestsCompleted() return {} end
C_QuestLog = { GetNumQuestLogEntries = function() return 0, 0 end, GetInfo = function() return nil end, IsQuestFlaggedCompleted = function() return false end,
	GetQuestIDForLogIndex = function() return nil end, IsOnQuest = function() return false end, GetQuestObjectives = function() return {} end,
	GetTitleForQuestID = function() return nil end, GetLogIndexForQuestID = function() return nil end, GetAllCompletedQuestIDs = function() return {} end,
	IsComplete = function() return false end, GetQuestWatchType = function() return nil end, GetSelectedQuest = function() return nil end }; falto("C_QuestLog")
function IsQuestFlaggedCompleted() return false end
function GetQuestID() return 0 end
function GetNumTrainerServices() return 0 end; function GetTrainerServiceInfo() return nil end
function GetMerchantNumItems() return 0 end; function GetRepairAllCost() return 0, false end; function CanMerchantRepair() return false end
C_MerchantFrame = { GetNumJunkItems = function() return 0 end, IsSellAllJunkEnabled = function() return false end }
function GetContainerNumSlots(b) return C_Container.GetContainerNumSlots(b) end
function GetInventorySlotInfo(n) return 1, nil end; falto("GetInventorySlotInfo")
function GetInventoryItemID() return nil end; function GetInventoryItemTexture() return nil end; function GetInventoryItemDurability() return nil end
function GetInventoryItemCount() return 0 end; function GetInventoryItemQuality() return nil end
function GetItemCount() return 0 end; function GetItemInfo(x) return C_Item.GetItemInfo(x) end; function GetItemInfoInstant(x) return C_Item.GetItemInfoInstant(x) end
function GetItemQualityColor(q) return 1, 1, 1, "ffffffff" end; function GetItemStats(l) return C_Item.GetItemStats(l) end; falto("GetItemInfo (global)")
C_Item.GetItemCount = function() return 0 end; C_Item.GetItemQualityColor = function() return 1, 1, 1, "ffffffff" end
C_Item.IsEquippableItem = function() return false end; C_Item.GetItemIconByID = function() return nil end; C_Item.GetItemNameByID = function() return nil end
C_Item.DoesItemExistByID = function() return false end; C_Item.GetItemQualityByID = function() return nil end; C_Item.IsItemDataCachedByID = function() return false end
C_Item.GetItemSpell = function() return nil end; C_Item.GetDetailedItemLevelInfo = function() return nil end; C_Item.GetItemLink = function() return nil end
C_Item.GetItemID = function() return nil end; C_Item.GetItemSubClassInfo = function() return nil end; C_Item.GetItemClassInfo = function() return nil end
falto("C_Item.* (GetItemCount, IsEquippableItem, …)")
C_Container.GetContainerItemID = function() return nil end; C_Container.GetContainerNumFreeSlots = function() return 0, 0 end
C_Container.GetBagName = function() return nil end; C_Container.UseContainerItem = function() end; C_Container.GetContainerItemCooldown = function() return 0, 0, 0 end
C_Container.SortBags = function() end; C_Container.GetSortBagsRightToLeft = function() return false end; falto("C_Container.*")
C_Map = {}; falto("C_Map")
C_Map.GetBestMapForUnit = function() return MAPA or 1456 end
C_Map.GetPlayerMapPosition = function() return { GetXY = function() return 0.5, 0.5 end, x = 0.5, y = 0.5 } end
C_Map.GetMapInfo = function(m) return { mapID = m, name = "Mapa " .. tostring(m), mapType = 3, parentMapID = 1414 } end
C_Map.GetWorldPosFromMapPos = function() return 0, { x = 0, y = 0 } end
C_Map.GetMapChildrenInfo = function() return {} end; C_Map.GetMapGroupID = function() return nil end; C_Map.GetMapRectOnMap = function() return 0, 1, 0, 1 end
C_Map.GetAreaInfo = function() return nil end; C_Map.GetMapArtID = function() return nil end; C_Map.GetMapLevels = function() return 1, 60 end
C_Map.GetFallbackWorldMapID = function() return 1414 end; C_Map.CanSetUserWaypointOnMap = function() return false end
C_Map.HasUserWaypoint = function() return false end; C_Map.GetUserWaypoint = function() return nil end; C_Map.SetUserWaypoint = function() end; C_Map.ClearUserWaypoint = function() end
falto("C_Map (completo)")
MAPA = 1456
C_SuperTrack = { SetSuperTrackedUserWaypoint = function() end, IsSuperTrackingUserWaypoint = function() return false end }; falto("C_SuperTrack")
C_TaxiMap = { GetAllTaxiNodes = function() return {} end, GetTaxiNodesForMap = function() return {} end }; falto("C_TaxiMap")
function NumTaxiNodes() return 0 end; function TaxiNodeName() return nil end
C_Minimap = { GetNumTrackingTypes = function() return 0 end }; function GetNumTrackingTypes() return 0 end
C_ChatInfo = { RegisterAddonMessagePrefix = function() return true end, SendAddonMessage = function() end, IsAddonMessagePrefixRegistered = function() return false end }; falto("C_ChatInfo")
function SendChatMessage() end; function ChatFrame_AddMessageEventFilter() end; function ChatFrame_RemoveMessageEventFilter() end
function ChatFrame_OpenChat() end; function ChatEdit_InsertLink() return false end; function ChatEdit_GetActiveWindow() return nil end
function ChatFrame_OnHyperlinkShow() end; function SetItemRef() end; falto("ChatFrame_*")
function SecureCmdOptionParse(s) return s end
StaticPopupDialogs = {}; function StaticPopup_Show() return nil end; function StaticPopup_Hide() end; function StaticPopup_Visible() return nil end; falto("StaticPopup*")
function ShowUIPanel(f) if f and f.Show then f:Show() end end; function HideUIPanel(f) if f and f.Hide then f:Hide() end end
function ToggleFrame(f) if f:IsShown() then f:Hide() else f:Show() end end; function CloseDropDownMenus() end; falto("ShowUIPanel/HideUIPanel")
function InterfaceOptions_AddCategory() end; function InterfaceOptionsFrame_OpenToCategory() end
Settings = { RegisterCanvasLayoutCategory = function(f, n) return { GetID = function() return n end, ID = n } end, RegisterAddOnCategory = function() end,
	OpenToCategory = function() end, RegisterVerticalLayoutCategory = function(n) return { GetID = function() return n end, ID = n } end,
	RegisterCanvasLayoutSubcategory = function(_, f, n) return { GetID = function() return n end, ID = n } end }; falto("Settings")
function Mixin(o, ...) for i = 1, select("#", ...) do for k, v in pairs((select(i, ...))) do o[k] = v end end return o end
function CreateFromMixins(...) return Mixin({}, ...) end; falto("Mixin/CreateFromMixins")
BackdropTemplateMixin = {}
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a or 1, GetRGB = function(s) return s.r, s.g, s.b end,
	GetRGBA = function(s) return s.r, s.g, s.b, s.a end, WrapTextInColorCode = function(s, t) return t end,
	GenerateHexColor = function() return "ffffffff" end } end; falto("CreateColor")
function CopyTable(t) local o = {} for k, v in pairs(t) do o[k] = type(v) == "table" and CopyTable(v) or v end return o end; falto("CopyTable")
function tContains(t, v) for _, x in pairs(t) do if x == v then return true end end return false end
function tInvert(t) local o = {} for k, v in pairs(t) do o[v] = k end return o end
function tDeleteItem(t, v) for i = #t, 1, -1 do if t[i] == v then table.remove(t, i) end end end
function tIndexOf(t, v) for i, x in ipairs(t) do if x == v then return i end end end
function tFilter(t, f) local o = {} for _, v in ipairs(t) do if f(v) then o[#o + 1] = v end end return o end
function tAppendAll(t, s) for _, v in ipairs(s) do t[#t + 1] = v end end
function tUnorderedRemove(t, i) t[i] = t[#t]; t[#t] = nil end
function GetKeysArray(t) local o = {} for k in pairs(t) do o[#o + 1] = k end return o end
falto("tContains/tInvert/…")
function wipe(t) for k in pairs(t) do t[k] = nil end return t end; table.wipe = wipe; falto("wipe")
function strsplit(sep, s, n)
	local out, i = {}, 1
	s = tostring(s)
	while true do
		if n and #out == n - 1 then out[#out + 1] = s:sub(i); break end
		local a, b = s:find(sep, i, true)
		if not a then out[#out + 1] = s:sub(i); break end
		out[#out + 1] = s:sub(i, a - 1); i = b + 1
	end
	return unpack(out)
end
function strjoin(sep, ...) return table.concat({ ... }, sep) end
function strtrim(s, c) c = c or " \t\r\n"; local p = "[" .. c:gsub("%p", "%%%0") .. "]*"; return (tostring(s):gsub("^" .. p, ""):gsub(p .. "$", "")) end
function strsplittable(sep, s) return { strsplit(sep, s) } end
string.split = function(s, sep) return strsplit(sep, s) end; string.trim = strtrim; string.join = strjoin
strmatch, strfind, strsub, strlen, strlower, strupper, strrep, strbyte, strchar, strrev = string.match, string.find, string.sub, string.len, string.lower, string.upper, string.rep, string.byte, string.char, string.reverse
format, gsub, gmatch = string.format, string.gsub, string.gmatch
tinsert, tremove, sort = table.insert, table.remove, table.sort
floor, ceil, abs, min, max, sqrt, random, fmod, mod = math.floor, math.ceil, math.abs, math.min, math.max, math.sqrt, math.random, math.fmod, math.fmod
math.huge = math.huge or 1 / 0
function Round(x) return math.floor(x + 0.5) end; function Clamp(x, a, b) return math.min(math.max(x, a), b) end; function Saturate(x) return Clamp(x, 0, 1) end
function Lerp(a, b, t) return a + (b - a) * t end
falto("strsplit/strjoin/strtrim/tinsert/… (alias de Lua del juego)")
bit = bit or { band = function(a, b) local r, m = 0, 1 while a > 0 and b > 0 do if a % 2 == 1 and b % 2 == 1 then r = r + m end a, b, m = math.floor(a / 2), math.floor(b / 2), m * 2 end return r end,
	bor = function(a, b) local r, m = 0, 1 while a > 0 or b > 0 do if a % 2 == 1 or b % 2 == 1 then r = r + m end a, b, m = math.floor(a / 2), math.floor(b / 2), m * 2 end return r end,
	lshift = function(a, n) return a * 2 ^ n end, rshift = function(a, n) return math.floor(a / 2 ^ n) end,
	bxor = function(a, b) local r, m = 0, 1 while a > 0 or b > 0 do if (a % 2) ~= (b % 2) then r = r + m end a, b, m = math.floor(a / 2), math.floor(b / 2), m * 2 end return r end }
falto("bit")
date = os and os.date or function() return "2026-11-18" end
function securecall(fn, ...) if type(fn) == "string" then fn = _G[fn] end return fn(...) end
function issecure() return false end; function forceinsecure() end
function securecallfunction(fn, ...) return fn(...) end; function secureexecuterange(t, fn, ...) for k, v in pairs(t) do fn(k, v, ...) end end
function scrub(...) return ... end
falto("securecall/issecure")
function GetAddOnMemoryUsage() return 0 end; function UpdateAddOnMemoryUsage() end; function collectgarbage_() end
function PlaySoundFile() end; function StopSound() end
function UIFrameFadeIn() end; function UIFrameFadeOut() end
function GetMouseFocus() return nil end; function GetMouseFoci() return {} end
function FlashClientIcon() end
function RegisterStateDriver() end; function UnregisterStateDriver() end; function RegisterAttributeDriver() end
function SetOverrideBindingClick() end; function ClearOverrideBindings() end; function SetBinding() end; function GetBindingKey() return nil end; function SetOverrideBinding() end
function GetActionInfo() return nil end; function HasAction() return false end; function GetMacroInfo() return nil end
function CursorHasItem() return false end; function ClearCursor() end
function GetTalentInfo() return nil end; function GetNumTalentTabs() return 0 end; function GetTalentTabInfo() return nil end; function GetNumTalents() return 0 end
function GetShapeshiftForm() return 0 end; function GetNumShapeshiftForms() return 0 end
function GetPlayerFacing() return 0 end
function GetGameTime() return 12, 0 end; function GetSessionTime() return 0 end
function GetFactionInfo() return nil end; function GetNumFactions() return 0 end
function GetGuildInfo() return nil end; function IsInGuild() return false end
function GetNumBindings() return 0 end
function UnitClassBase(u) return select(2, UnitClass(u)) end
function GetClassInfo(i) return "Druida", "DRUID", 11 end; function GetNumClasses() return 11 end
function UnitReaction() return 4 end; function UnitIsFriend() return true end; function UnitIsEnemy() return false end
function UnitIsTapDenied() return false end; function UnitClassification() return "normal" end; function UnitCreatureType() return nil end
function UnitIsConnected() return true end; function UnitIsAFK() return false end; function UnitGroupRolesAssigned() return "NONE" end
function UnitThreatSituation() return nil end; function UnitDetailedThreatSituation() return nil end
function UnitCastingInfo() return nil end; function UnitChannelInfo() return nil end
function CheckInteractDistance() return false end; function UnitInRange() return false, false end
function GetTotemInfo() return false end
function GetComboPoints() return 0 end
function GetRaidTargetIndex() return nil end
function C_GetUnitAura() end
falto("varias API de unidad/interfaz (UnitReaction, GetTalentInfo, …)")
C_NamePlate = { GetNamePlateForUnit = function() return nil end, GetNamePlates = function() return {} end }
C_DamageMeter = nil  -- Mamba_Combate lo usa si existe (aquí no: NO VERIFICADO)
C_Covenants = nil
C_Seasons = { HasActiveSeason = function() return false end, GetActiveSeason = function() return nil end }
C_GameRules = { IsHardcoreActive = function() return false end }
C_PlayerInfo = { GetPlayerMythicPlusRatingSummary = function() return nil end, IsPlayerNPERestricted = function() return false end, GetClass = function() return "Druida", "DRUID", 11 end, GetRace = function() return 6 end }
C_CreatureInfo = { GetClassInfo = function() return { className = "Druida", classFile = "DRUID", classID = 11 } end, GetRaceInfo = function() return { raceName = "Tauren", clientFileString = "Tauren", raceID = 6 } end }
C_GossipInfo = { GetOptions = function() return {} end, GetAvailableQuests = function() return {} end, GetActiveQuests = function() return {} end, GetNumOptions = function() return 0 end }
C_TradeSkillUI = { GetTradeSkillLine = function() return nil end, GetAllRecipeIDs = function() return {} end }
C_Reputation = { GetNumFactions = function() return 0 end, GetFactionDataByIndex = function() return nil end, GetWatchedFactionData = function() return nil end }
C_EncodingUtil = nil
C_DateAndTime = { GetCurrentCalendarTime = function() return { year = 2026, month = 11, monthDay = 18, hour = 12, minute = 0, weekday = 4 } end, GetServerTimeLocal = function() return time() end }
C_Calendar = { GetDate = function() return { year = 2026, month = 11, monthDay = 18 } end }
C_PartyInfo = { IsPartyFull = function() return false end }
C_LFGList = {}
C_EquipmentSet = { GetEquipmentSetIDs = function() return {} end }
C_PetJournal = {}
C_MountJournal = { GetNumMounts = function() return 0 end, GetMountIDs = function() return {} end }
C_ToyBox = {}
C_Texture = { GetAtlasInfo = function() return nil end }
C_StableInfo = nil
C_ClassColor = { GetClassColor = function() return CreateColor(1, 1, 1) end }
C_ActionBar = { GetActionTexture = function() return nil end, HasAction = function() return false end }
C_Console = {}
C_UI = { Reload = function() end }
C_Sound = {}
C_XMLUtil = {}
C_CurrencyInfo = { GetCurrencyInfo = function() return nil end }
C_FunctionContainers = { CreateCallback = function(fn) return fn end }
C_EventUtils = { IsEventValid = function(e) return not (EVENTOS_DESCONOCIDOS and EVENTOS_DESCONOCIDOS[e]) end }
C_VoiceChat = { SpeakText = function() end, GetTtsVoices = function() return {} end }
C_TTSSettings = { GetVoiceOptionID = function() return 0 end }
falto("C_Seasons/C_GameRules/C_PlayerInfo/C_CreatureInfo/C_GossipInfo/C_DateAndTime/C_EventUtils/… (namespaces)")
Enum = Enum or {}
Enum.ItemQuality = { Poor = 0, Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Artifact = 6, Heirloom = 7 }
Enum.ItemClass = { Consumable = 0, Container = 1, Weapon = 2, Gem = 3, Armor = 4, Reagent = 5, Projectile = 6, Tradegoods = 7, Recipe = 9, Quiver = 11, Questitem = 12, Key = 13, Miscellaneous = 15 }
Enum.PowerType = { Mana = 0, Rage = 1, Focus = 2, Energy = 3, ComboPoints = 4 }
Enum.TooltipDataType = Enum.TooltipDataType or { Item = 0 }
Enum.TooltipDataType.Unit = 2; Enum.TooltipDataType.Spell = 1
Enum.InventoryType = { IndexNonEquipType = 0 }
Enum.BagIndex = { Backpack = 0, Bank = -1, Keyring = -2 }
Enum.ChatChannelType = {}
Enum.UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4, Micro = 5, Orphan = 6 }
falto("Enum.* (ItemQuality, ItemClass, …)")
LE_ITEM_QUALITY_POOR, LE_ITEM_QUALITY_COMMON, LE_ITEM_QUALITY_UNCOMMON, LE_ITEM_QUALITY_RARE, LE_ITEM_QUALITY_EPIC = 0, 1, 2, 3, 4
ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS or {}
for q = 0, 7 do local c = ITEM_QUALITY_COLORS[q] or {}; c.r, c.g, c.b, c.hex = c.r or 1, c.g or 1, c.b or 1, c.hex or "|cffffffff"; c.color = CreateColor(1, 1, 1); ITEM_QUALITY_COLORS[q] = c end
RAID_CLASS_COLORS = RAID_CLASS_COLORS or {}
for _, k in ipairs({ "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
	local c = RAID_CLASS_COLORS[k] or {}; c.r, c.g, c.b, c.colorStr = 1, 1, 1, c.colorStr or "ffffffff"
	c.GetRGB = function(s) return s.r, s.g, s.b end; c.WrapTextInColorCode = function(_, t) return t end; c.GenerateHexColor = function() return c.colorStr end
	RAID_CLASS_COLORS[k] = c
end
CLASS_SORT_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
LOCALIZED_CLASS_NAMES_MALE = { WARRIOR = "Guerrero", PALADIN = "Paladín", HUNTER = "Cazador", ROGUE = "Pícaro", PRIEST = "Sacerdote", SHAMAN = "Chamán", MAGE = "Mago", WARLOCK = "Brujo", DRUID = "Druida" }
LOCALIZED_CLASS_NAMES_FEMALE = LOCALIZED_CLASS_NAMES_MALE
CLASS_ICON_TCOORDS = setmetatable({}, { __index = function() return { 0, 1, 0, 1 } end })
falto("RAID_CLASS_COLORS completo / LOCALIZED_CLASS_NAMES_* / CLASS_ICON_TCOORDS")
MAX_PLAYER_LEVEL = 60; MAX_PLAYER_LEVEL_TABLE = { [0] = 60 }; NUM_BAG_SLOTS = 4; NUM_BAG_FRAMES = 4; BACKPACK_CONTAINER = 0; BANK_CONTAINER = -1
NUM_CHAT_WINDOWS = 10; COPPER_PER_SILVER = 100; SILVER_PER_GOLD = 100; COPPER_PER_GOLD = 10000
WOW_PROJECT_ID = 2; WOW_PROJECT_CLASSIC = 2; WOW_PROJECT_MAINLINE = 1; WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5; WOW_PROJECT_WRATH_CLASSIC = 11
LE_EXPANSION_LEVEL_CURRENT = 0; LE_EXPANSION_CLASSIC = 0
falto("constantes (MAX_PLAYER_LEVEL, WOW_PROJECT_ID, …)")
INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BODY, INVSLOT_CHEST, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET = 1, 2, 3, 4, 5, 6, 7, 8
INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_FINGER1, INVSLOT_FINGER2, INVSLOT_TRINKET1, INVSLOT_TRINKET2, INVSLOT_BACK = 9, 10, 11, 12, 13, 14, 15
INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED, INVSLOT_TABARD = 16, 17, 18, 19
-- Textos del cliente que los addons leen como globales (los de mock_wow.lua más estos).
EventRegistry = { RegisterCallback = function() end, TriggerEvent = function() end, RegisterFrameEventAndCallback = function() end }; falto("EventRegistry")
Menu = { ModifyMenu = function() end }; MenuUtil = { CreateContextMenu = function() end, CreateButtonMenu = function() end }; falto("Menu/MenuUtil")
UIDropDownMenu_Initialize = function() end; UIDropDownMenu_CreateInfo = function() return {} end; UIDropDownMenu_AddButton = function() end
UIDropDownMenu_SetWidth = function() end; UIDropDownMenu_SetText = function() end; ToggleDropDownMenu = function() end; EasyMenu = function() end
AddonCompartmentFrame.RegisterAddon = function() end
GameTooltip_SetDefaultAnchor = function(t, o) t:SetOwner(o) end; GameTooltip_Hide = function() GameTooltip:Hide() end
GameTooltip_AddBlankLineToTooltip = function() end; GameTooltip_AddNormalLine = function() end; GameTooltip_SetTitle = function() end
falto("GameTooltip_* / UIDropDownMenu_*")
Item = { CreateFromItemID = function(_, id) return { ContinueOnItemLoad = function(_, fn) fn() end, GetItemID = function() return id end, IsItemEmpty = function() return false end, GetItemName = function() return nil end, GetItemLink = function() return nil end, IsItemDataCached = function() return true end } end,
	CreateFromItemLink = function(_, l) return { ContinueOnItemLoad = function(_, fn) fn() end, GetItemLink = function() return l end, IsItemEmpty = function() return false end, GetItemID = function() return nil end } end }
Spell = { CreateFromSpellID = function(_, id) return { ContinueOnSpellLoad = function(_, fn) fn() end, GetSpellID = function() return id end, IsSpellEmpty = function() return false end } end }
falto("Item/Spell (mixins de carga)")
CreateFramePool = function() return { Acquire = function() return CreateFrame("Frame") end, ReleaseAll = function() end, Release = function() end, EnumerateActive = function() return function() end end } end
CreateObjectPool = CreateFramePool; CreateTexturePool = CreateFramePool; CreateFontStringPool = CreateFramePool
CreateFramePoolCollection = function() return { CreatePool = function() return CreateFramePool() end, Acquire = function() return CreateFrame("Frame") end,
	ReleaseAll = function() end, EnumerateActive = function() return function() end end, GetOrCreatePool = function() return CreateFramePool() end } end
falto("CreateFramePool/CreateFramePoolCollection")
EventUtil = { ContinueOnAddOnLoaded = function(_, fn) fn() end, ContinueAfterAllEvents = function() end, RegisterOnceFrameEventAndCallback = function() end,
	RegisterForLogin = function() end, ContinueOnPlayerLogin = function(fn) if fn then fn() end end }
falto("EventUtil")
Settings.VarType = { Boolean = "boolean", Number = "number", String = "string" }
Settings.Default = { True = true, False = false }
local function ajuste() return { SetValueChangedCallback = function() end, GetValue = function() return nil end, SetValue = function() end } end
Settings.RegisterAddOnSetting = function() return ajuste() end; Settings.RegisterProxySetting = function() return ajuste() end
Settings.CreateCheckbox = function() end; Settings.CreateSlider = function() end; Settings.CreateDropdown = function() end
Settings.CreateSliderOptions = function() return { SetLabelFormatter = function() end } end; Settings.CreateControlTextContainer = function() return { Add = function() end, GetData = function() return {} end } end
falto("Settings.VarType/RegisterAddOnSetting/…")
Enum.TradeskillRelativeDifficulty = { Optimal = 0, Medium = 1, Easy = 2, Trivial = 3 }
falto("Enum.TradeskillRelativeDifficulty")
for n, c in pairs({ GREEN = { 0.1, 1, 0.1 }, RED = { 1, 0.1, 0.1 }, NORMAL = { 1, 0.82, 0 }, HIGHLIGHT = { 1, 1, 1 }, GRAY = { 0.5, 0.5, 0.5 },
	YELLOW = { 1, 1, 0 }, ORANGE = { 1, 0.5, 0.25 }, WHITE = { 1, 1, 1 }, DISABLED = { 0.5, 0.5, 0.5 }, LIGHTGRAY = { 0.75, 0.75, 0.75 },
	DIM_GREEN = { 0.1, 0.6, 0.1 }, BLUE = { 0, 0.5, 1 }, LIGHTBLUE = { 0.5, 0.8, 1 }, PASSIVE_SPELL = { 0.8, 0.8, 0.8 }, EPIC_PURPLE = { 0.64, 0.21, 0.93 }, QUEST_OBJECTIVE = { 0.8, 0.8, 0.8 } }) do
	_G[n .. "_FONT_COLOR"] = CreateColor(c[1], c[2], c[3])
	_G[n .. "_FONT_COLOR_CODE"] = "|cffffffff"
end
FONT_COLOR_CODE_CLOSE = "|r"
falto("*_FONT_COLOR / *_FONT_COLOR_CODE / FONT_COLOR_CODE_CLOSE")
function GetFileIDFromPath() return nil end; falto("GetFileIDFromPath")
C_Spell.IsSpellDataCached = function() return true end; falto("C_Spell.IsSpellDataCached")
function GetBindingText(k) return k end
-- Campos de marco con mayúscula (plantillas del juego: b.HotKey, b.SpellCastAnimFrame…): mock_ventana.lua devuelve
-- una FUNCIÓN para cualquier clave con mayúscula, y un campo-función rompe `b.HotKey:SetText()`. Aquí devuelve un
-- objeto comodín que se puede llamar e indexar (como función sigue sin hacer nada y da nil).
COMODIN = setmetatable({}, { __call = function() return nil end, __index = function() return COMODIN end, __newindex = function() end })
M.__index = function(_, k)
	local v = rawget(M, k)
	if v ~= nil then return v end
	if type(k) == "string" and k:match("^%u") then return COMODIN end
	return nil
end
falto("campos de plantilla (b.HotKey, …) como objeto comodín")
rawset(M, "GetTextWidth", function(self) return #(self.text or "") * 6 end); falto("Button:GetTextWidth")
function RunNextFrame(fn) C_Timer.After(0, fn) end; falto("RunNextFrame")
-- Hijos que crean las plantillas de botón de acción del juego (XML de Blizzard que el simulado no tiene).
local crearPlantilla = CreateFrame
function CreateFrame(tipo, nombre, padre, plantilla, ...)
	local f = crearPlantilla(tipo, nombre, padre, plantilla, ...)
	if type(plantilla) == "string" and plantilla:find("ActionButtonTemplate") then
		for _, k in ipairs({ "icon", "cooldown", "Count", "HotKey", "Name", "Border", "Flash", "NormalTexture", "AutoCastable", "AutoCastShine", "SpellHighlightTexture", "CheckedTexture" }) do
			local h = NuevoMarco(nombre and (nombre .. (k == "icon" and "Icon" or k)) or nil); h.padre = f; rawset(f, k, h)
		end
	end
	return f
end
falto("hijos de ActionButtonTemplate/PetActionButtonTemplate (icon, cooldown, HotKey…)")
GamepadMode = { AddGamepadIconToButton = function() return NuevoMarco() end, SetGamepadIconShown = function() end }; falto("GamepadMode (Forever)")
InputUtil = { IsGamepadUIEnabled = function() return false end, GetCursorPosition = function() return 0, 0 end }; falto("InputUtil")
ProfessionsFrame = marco("ProfessionsFrame"); falto("ProfessionsFrame")
for _, n in ipairs({ "NumberFontNormalSmallGray", "NumberFontNormalSmall", "NumberFontNormalLarge", "NumberFont_Outline_Med", "GameFontHighlightSmallOutline",
	"GameFontNormalOutline", "GameFontHighlightOutline", "GameFontHighlightMedium", "GameFontNormalMed1", "GameFontNormalMed2", "GameFontHighlightMed2",
	"SystemFont_Small", "SystemFont_Med1", "SystemFont_Large", "SystemFont_Outline_Small", "Game12Font", "Game13Font", "Game15Font", "Game18Font",
	"GameFontDisableLarge", "GameFontHighlightLeft", "GameFontNormalLeft", "QuestFontNormalSmall", "ChatFontSmall", "SubZoneTextFont", "ZoneTextFont" }) do
	if _G[n] == nil then _G[n] = marco(n) end
end
falto("más fuentes (NumberFontNormalSmallGray…)")
Spell.CreateFromSpellID = function(_, id) return { ContinueOnSpellLoad = function(_, fn) fn() end, GetSpellID = function() return id end, IsSpellEmpty = function() return false end,
	GetSpellName = function() return "Hechizo " .. tostring(id) end, GetSpellSubtext = function() return "" end, GetSpellDescription = function() return "" end,
	GetSpellTexture = function() return nil end, IsSpellDataCached = function() return true end } end
falto("Spell:GetSpellName/GetSpellSubtext")
ProfessionsFrame.rightProfessionTabs = {}; ProfessionsFrame.leftProfessionTabs = {}
-- La ventana de profesiones del cliente es un árbol de plantillas XML (BookPage, CraftingPage.RankBar…) que el
-- simulado no tiene: sin pestaña de resumen, WhatsTraining/Crafting/Crafting.lua (attach) sale en su línea 70.
-- Con ella daba "Crafting.lua:153: arithmetic on a nil value" por los marcos comodín: NO VERIFICADO aquí.
ProfessionsFrame.ProfessionsOverviewTab = false
falto("ProfessionsFrame sin ProfessionsOverviewTab (WhatsTraining/Crafting.lua attach NO VERIFICADO)")
PlayerSpellsFrame = marco("PlayerSpellsFrame"); PlayerSpellsFrame.SpellBookFrame = marco(); PlayerSpellsFrame.SpellBookFrame.padre = PlayerSpellsFrame
falto("ProfessionsFrame.rightProfessionTabs / PlayerSpellsFrame")
C_ActionBar.RegisterActionUIButton = function() end; C_ActionBar.UnregisterActionUIButton = function() end
C_ActionBar.IsAutoCastPetAction = function() return false end; C_ActionBar.EnableActionRangeCheck = function() end
falto("C_ActionBar.RegisterActionUIButton/…")
C_CurrencyInfo.GetCoinTextureString = function(c) return tostring(c) .. "c" end; falto("C_CurrencyInfo.GetCoinTextureString")
for _, n in ipairs({ "IsEquippedAction", "IsCurrentAction", "IsAutoRepeatAction", "IsAttackAction", "IsConsumableAction", "IsStackableAction",
	"IsItemAction", "IsAssistedCombatAction", "ActionHasRange", "IsActionInRange", "GetActionText", "GetActionTexture", "PetHasActionBar",
	"GetPetActionInfo", "GetPetActionsUsable", "GetActionLossOfControlCooldown" }) do
	_G[n] = function() return nil end
end
function IsUsableAction() return false, false end; function GetActionCount() return 0 end; function GetActionCooldown() return 0, 0, 1 end
function GetActionCharges() return 0, 0, 0, 0 end; function GetPetActionCooldown() return 0, 0, 1 end
falto("API de acción (IsEquippedAction, IsUsableAction, GetActionCooldown, …)")
Enum.SpellBookSpellBank = { Player = 0, Pet = 1 }; Enum.SpellBookItemType = { None = 0, Spell = 1, FutureSpell = 2, PetAction = 3, Flyout = 4 }
falto("Enum.SpellBookSpellBank/SpellBookItemType")
C_LevelLink = { IsActionLocked = function() return false end, IsSpellLocked = function() return false end }; falto("C_LevelLink")
C_SpellBook.IsSpellInSpellBook = function() return false end; C_SpellBook.IsSpellKnown = function() return false end; falto("C_SpellBook.IsSpellInSpellBook")
function GetQuestDifficultyColor() return { r = 1, g = 1, b = 0, font = GameFontNormal } end
function GetCreatureDifficultyColor() return { r = 1, g = 1, b = 0 } end; falto("GetQuestDifficultyColor")
-- Bolsas y barras del juego (Mamba_Bolsas las engancha, Mamba_Barras las esconde): sin ellas ese código no corre.
for _, n in ipairs({ "ToggleAllBags", "ToggleBackpack", "ToggleBag", "OpenAllBags", "OpenBackpack", "OpenBag", "CloseAllBags", "CloseBackpack",
	"CloseBag", "BankFrame_Open", "CooldownFrame_Set", "CooldownFrame_Clear", "ActionButton_ShowGrid", "ActionButton_HideGrid", "MultiActionBar_Update",
	"ToggleCharacter", "ToggleSpellBook", "ToggleWorldMap", "ToggleGameMenu", "ToggleQuestLog" }) do
	_G[n] = function() end
end
NUM_CONTAINER_FRAMES = 13
for i = 1, 13 do if _G["ContainerFrame" .. i] == nil then _G["ContainerFrame" .. i] = marco("ContainerFrame" .. i) end end
ContainerFrameCombinedBags = marco("ContainerFrameCombinedBags")
ContainerFrameContainer = marco("ContainerFrameContainer"); ContainerFrameContainer.ContainerFrames = {}
for i = 1, 13 do ContainerFrameContainer.ContainerFrames[i] = _G["ContainerFrame" .. i] end
for _, n in ipairs({ "MainActionBar", "MultiBar5", "MultiBar6", "MultiBar7", "PossessActionBar", "OverrideActionBar", "VehicleSeatIndicator" }) do
	if _G[n] == nil then _G[n] = marco(n) end
end
for _, pre in ipairs({ "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton",
	"MultiBar5Button", "MultiBar6Button", "MultiBar7Button", "PetActionButton", "StanceButton" }) do
	for i = 1, 12 do if _G[pre .. i] == nil then _G[pre .. i] = marco(pre .. i) end end
end
falto("bolsas y barras del juego (ToggleAllBags…, ContainerFrame1-13, ActionButton1-12, MultiBar*Button1-12, MainActionBar…)")
function GetShapeshiftFormInfo() return nil end; function GetBinding() return nil end; function GetMacroIndexByName() return 0 end
function GetOverrideBarIndex() return 14 end; function GetVehicleBarIndex() return 12 end; function GetActiveTalentGroup() return 1 end
function GetSpellCount() return 0 end; function IsSpellInRange() return nil end; function IsCurrentSpell() return false end
function IsAutoRepeatSpell() return false end; function IsAttackSpell() return false end; function IsConsumableSpell() return false end
function debugstack() return "" end
ITEM_ACCOUNTBOUND = "Ligado a la cuenta"; ITEM_BIND_TO_ACCOUNT = "Se liga a la cuenta"; ITEM_BNETACCOUNTBOUND = "Ligado a Battle.net"
ITEM_BIND_TO_BNETACCOUNT = "Se liga a Battle.net"; ITEM_ACCOUNTBOUND_UNTIL_EQUIP = "Ligado a la cuenta hasta equiparlo"
RANGE_INDICATOR = "●"
falto("GetShapeshiftFormInfo/GetBinding/GetMacroIndexByName/GetOverrideBarIndex/GetActiveTalentGroup/debugstack/ITEM_*BOUND*")
PARENS_TEMPLATE = "(%s)"; CANCEL = "Cancelar"; ACCEPT = "Aceptar"; OKAY = "Aceptar"; YES = "Sí"; NO = "No"; CLOSE = "Cerrar"
"""
L.execute(EXTRA)

# ---------------------------------------------------------------------------------------------------------------
# 3) El arnés: dueño de cada cosa, errores con archivo:línea, trampa de globales del juego, hooks y comandos.
# ---------------------------------------------------------------------------------------------------------------
ARNES = r"""
H = { errores = {}, pisadas = {}, hooks = {}, slash = {}, slashkeys = {}, secciones = {}, nil_leidas = {}, actual = "(prueba)",
	reloj = 0, cola = {}, trampa = false }
local function donde(desde)
	for i = desde or 2, 40 do
		local info = debug.getinfo(i, "Sl")
		if not info then break end
		local s = info.source or ""
		if s:sub(1, 1) == "@" then return s:sub(2) .. ":" .. tostring(info.currentline or 0) end
	end
	return "?"
end
H.donde = donde
local function traza(e)
	local msg = tostring(e)
	local tb = debug.traceback("", 2)
	local primero
	for linea in tb:gmatch("[^\n]+") do
		local f = linea:match("^%s*([%w_%-]+/[^:]+%.lua:%d+):")
		if f and not primero then primero = f end
	end
	-- (un mensaje con la ruta recortada, "...ras/libs/x.lua:12:", toma la del primer cuadro de la traza)
	return { msg = msg, lugar = (msg:sub(1, 3) ~= "..." and msg:match("^([%w_%-]+/[^:]+%.lua:%d+):")) or primero or "?", tb = tb }
end
function H.anotarError(contexto, err)
	if type(err) ~= "table" then err = { msg = tostring(err), lugar = tostring(err):match("^([^:]+%.lua:%d+):") or "?" } end
	table.insert(H.errores, { addon = H.actual, contexto = contexto, msg = err.msg, lugar = err.lugar, tb = err.tb })
end
function H.correr(contexto, fn, ...)
	local n, a = select("#", ...), { ... }
	local ok, err = xpcall(function() return fn(unpack(a, 1, n)) end, traza)
	if not ok then H.anotarError(contexto, err) end
	return ok
end

-- Errores que los addons mandan al manejador del juego (los atrapan y los reportan): también cuentan.
local manejador = function(e) H.anotarError("geterrorhandler()", { msg = tostring(e), lugar = tostring(e):match("([%w_%-]+/[^:]+%.lua:%d+)") or donde(3) }) end
function geterrorhandler() return manejador end
function seterrorhandler(fn) H.seterrorhandler = (H.seterrorhandler or 0) + 1 end

-- Cargar un archivo de un addon como el cliente: loadstring(src, "@ruta") y llamado con (nombre, ns).
function H.cargarArchivo(src, ruta, addon, ns)
	local antes = H.actual
	H.actual = addon
	local f, e = loadstring(src, "@" .. ruta)
	local ok
	if not f then
		H.anotarError("compilar " .. ruta, { msg = e, lugar = tostring(e):match("^([^:]+%.lua:%d+):") or ruta })
		ok = false
	else
		ok = H.correr("cargar " .. ruta, f, addon, ns)
	end
	H.actual = antes
	return ok
end
function H.cargarSV(src, ruta)
	local f, e = loadstring(src, "=" .. ruta)
	if not f then return false, e end
	local ok, err = pcall(f)
	return ok, err
end

-- Eventos: a cada marco con OnEvent y el evento registrado, con su dueño como addon activo.
function H.disparar(e, ...)
	local lista = {}
	for _, f in ipairs(TODOS) do
		local sc = rawget(f, "scripts")
		if sc and sc.OnEvent and (f.ev[e] or rawget(f, "todos")) then lista[#lista + 1] = f end
	end
	for _, f in ipairs(lista) do
		local antes = H.actual
		H.actual = rawget(f, "__dueno") or "?"
		H.correr("evento " .. e, f.scripts.OnEvent, f, e, ...)
		H.actual = antes
	end
	return #lista
end

-- C_Timer con reloj: After / NewTimer / NewTicker, cada callback con el addon que lo pidió.
local function programar(d, fn, extra)
	local t = { t = H.reloj + (tonumber(d) or 0), fn = fn, dueno = H.actual }
	for k, v in pairs(extra or {}) do t[k] = v end
	table.insert(H.cola, t)
	return t
end
C_Timer = {
	After = function(d, fn) programar(d, fn) end,
	NewTimer = function(d, fn)
		local o = { cancelado = false }
		function o:Cancel() self.cancelado = true end
		function o:IsCancelled() return self.cancelado end
		programar(d, function() fn(o) end, { obj = o })
		return o
	end,
	NewTicker = function(d, fn, veces)
		local o = { cancelado = false, quedan = veces }
		function o:Cancel() self.cancelado = true end
		function o:IsCancelled() return self.cancelado end
		programar(d, function() fn(o) end, { obj = o, cada = tonumber(d) or 0.1 })
		return o
	end,
}
function H.tic(seg)
	H.reloj = H.reloj + seg
	NOW = 1000 + H.reloj
	local corridos = 0
	while corridos < 5000 do
		local idx
		for i, t in ipairs(H.cola) do if t.t <= H.reloj then idx = i break end end
		if not idx then break end
		local t = table.remove(H.cola, idx)
		if not (t.obj and t.obj.cancelado) then
			local antes = H.actual
			H.actual = t.dueno
			H.correr("C_Timer", t.fn)
			H.actual = antes
			if t.cada and not t.obj.cancelado then
				if t.obj.quedan then t.obj.quedan = t.obj.quedan - 1 end
				if not t.obj.quedan or t.obj.quedan > 0 then
					t.t = H.reloj + math.max(t.cada, 0.01); table.insert(H.cola, t)
				end
			end
		end
		corridos = corridos + 1
	end
	return corridos
end
NOW = 1000

-- Dueño de cada marco (para repartir eventos y hooks).
local crearOrig = CreateFrame
function CreateFrame(...)
	local f = crearOrig(...)
	rawset(f, "__dueno", H.actual)
	local nombre = select(2, ...)
	if type(nombre) == "string" then rawset(f, "nombre", nombre) end
	return f
end

-- Hooks sobre lo del juego.
H.NOMBRE_DE = {}
local function anotarHook(tipo, objetivo, extra)
	if H.actual == "(prueba)" then return end
	table.insert(H.hooks, { tipo = tipo, objetivo = objetivo, addon = H.actual, donde = donde(3), extra = extra })
end
function hooksecurefunc(a, b, c)
	local tabla, nombre, fn
	if type(a) == "string" then tabla, nombre, fn = _G, a, b else tabla, nombre, fn = a, b, c end
	local delJuego = tabla == _G or H.NOMBRE_DE[tabla] ~= nil
	local etiqueta = (tabla == _G) and nombre or ((H.NOMBRE_DE[tabla] or "(tabla de addon)") .. ":" .. tostring(nombre))
	local orig = tabla[nombre]
	-- (un método de marco que el simulado no define llega como COMODIN: se puede llamar, cuenta como función)
	if type(orig) ~= "function" and orig ~= COMODIN then
		if delJuego then anotarHook("hooksecurefunc", etiqueta, "función ausente en el simulado") end
		return
	end
	if orig == COMODIN and delJuego and tabla ~= _G then anotarHook("hooksecurefunc", etiqueta, "método no simulado (comodín)") end
	if delJuego then anotarHook("hooksecurefunc", etiqueta) end
	local nuevo = function(...)
		local r = { orig(...) }
		fn(...)
		return unpack(r)
	end
	if tabla == _G then H.escribirJuego(nombre, nuevo) else rawset(tabla, nombre, nuevo) end
end
local M = getmetatable(UIParent)
local ss, hs = rawget(M, "SetScript"), rawget(M, "HookScript")
rawset(M, "SetScript", function(self, n, fn)
	if H.NOMBRE_DE[self] and fn ~= nil then anotarHook("SetScript", H.NOMBRE_DE[self] .. ":" .. tostring(n)) end
	return ss(self, n, fn)
end)
rawset(M, "HookScript", function(self, n, fn)
	if H.NOMBRE_DE[self] then anotarHook("HookScript", H.NOMBRE_DE[self] .. ":" .. tostring(n)) end
	return hs(self, n, fn)
end)
local addPost = TooltipDataProcessor.AddTooltipPostCall
TooltipDataProcessor.AddTooltipPostCall = function(tipo, fn)
	anotarHook("TooltipDataProcessor.AddTooltipPostCall", "TooltipDataType " .. tostring(tipo))
	return addPost(tipo, fn)
end
TooltipDataProcessor.AddLinePreCall = function(tipo) anotarHook("TooltipDataProcessor.AddLinePreCall", "TooltipDataType " .. tostring(tipo)) end
TooltipDataProcessor.AddLinePostCall = function(tipo) anotarHook("TooltipDataProcessor.AddLinePostCall", "TooltipDataType " .. tostring(tipo)) end

-- Trampa: las globales del juego salen de _G crudo; leerlas pasa por __index y escribirlas por __newindex.
-- SLASH_* y las claves de SlashCmdList también viven aparte, así se ve CADA escritura (no solo la primera).
local JUEGO, NOMBRES, SLASHG, ANTES = {}, {}, {}, {}
H.JUEGO, H.ANTES = JUEGO, ANTES
function H.escribirJuego(k, v) JUEGO[k] = v end
local type, pairs, ipairs, rawget, rawset, rawequal, setmetatable, tostring, select = type, pairs, ipairs, rawget, rawset, rawequal, setmetatable, tostring, select
local table, debug = table, debug
function H.instalarTrampa(lista)
	for _, k in ipairs(lista) do
		local v = rawget(_G, k)
		if v ~= nil then
			NOMBRES[k] = true; JUEGO[k] = v; ANTES[k] = v; rawset(_G, k, nil)
			if type(v) == "table" or type(v) == "userdata" then H.NOMBRE_DE[v] = k end
		else
			H.sinDefinir = H.sinDefinir or {}
			table.insert(H.sinDefinir, k)
		end
	end
	-- SlashCmdList: tabla del juego cuyas claves se anotan en cada escritura
	local guardado = {}
	for k, v in pairs(JUEGO.SlashCmdList) do guardado[k] = v end
	local proxy = setmetatable({}, {
		__index = guardado,
		__newindex = function(_, k, v)
			table.insert(H.slashkeys, { clave = k, addon = H.actual, donde = donde(2), habia = guardado[k] ~= nil, borrar = v == nil })
			guardado[k] = v
		end,
	})
	H.SLASHCMDS = guardado
	JUEGO.SlashCmdList = proxy; ANTES.SlashCmdList = proxy; H.NOMBRE_DE[proxy] = "SlashCmdList"
	setmetatable(_G, {
		__index = function(_, k)
			local v = JUEGO[k]
			if v ~= nil then return v end
			v = SLASHG[k]
			if v ~= nil then return v end
			if H.trampa and type(k) == "string" and (k:match("^%u") or k:match("^C_")) then
				local d = donde(2)
				if d ~= "?" and not H.nil_leidas[k] then H.nil_leidas[k] = d end
			end
			return nil
		end,
		__newindex = function(t, k, v)
			if NOMBRES[k] then
				table.insert(H.pisadas, { nombre = k, addon = H.actual, donde = donde(2), mismo = rawequal(v, JUEGO[k]) })
				JUEGO[k] = v
				return
			end
			if type(k) == "string" and k:match("^SLASH_") then
				table.insert(H.slash, { nombre = k, valor = v, addon = H.actual, donde = donde(2), habia = SLASHG[k] ~= nil })
				SLASHG[k] = v
				return
			end
			rawset(t, k, v)
		end,
	})
	H.SLASHG = SLASHG
	H.trampa = true
end
function H.slashActual() return SLASHG end

-- Riel de Polestar: se envuelve RegisterSection (el real si cargó; si no, el de mock_hub.lua).
function H.envolverRegistro(UI)
	if not (UI and UI.RegisterSection) or H.registroEnvuelto then return false end
	local orig = UI.RegisterSection
	-- las secciones que Polestar ya registró al cargarse (antes de poder envolver): cuentan para los choques
	if UI.Picker and UI.Picker.Sections then
		for _, s in ipairs(UI.Picker.Sections() or {}) do
			table.insert(H.secciones, { clave = s.key, orden = s.order, etiqueta = s.label, pie = s.foot, addon = "Polestar", donde = "(registrada al cargar Polestar)", ok = true })
		end
	end
	UI.RegisterSection = function(spec)
		local r = orig(spec)
		table.insert(H.secciones, { clave = type(spec) == "table" and spec.key, orden = type(spec) == "table" and spec.order,
			etiqueta = type(spec) == "table" and spec.label, pie = type(spec) == "table" and spec.foot, addon = H.actual, donde = donde(2), ok = r })
		return r
	end
	H.registroEnvuelto = true
	return true
end
"""
L.execute(ARNES)
H = G.H

# Globales "del juego" que la trampa vigila (todas existen en el simulado antes de cargar; si no, se avisa).
JUEGO = """
SlashCmdList GameTooltip ItemRefTooltip ShoppingTooltip1 ShoppingTooltip2 UIParent WorldFrame Minimap MinimapCluster ChatFrame1 ChatFrame2
DEFAULT_CHAT_FRAME SELECTED_CHAT_FRAME StaticPopupDialogs UISpecialFrames UIErrorsFrame CreateFrame hooksecurefunc geterrorhandler
seterrorhandler print string table math coroutine bit pairs ipairs next type tostring tonumber select unpack error pcall xpcall assert
setmetatable getmetatable rawget rawset rawequal loadstring date time strsplit strjoin strtrim strmatch strfind strsub strlen strlower
strupper format gsub tinsert tremove wipe sort floor ceil abs min max random
C_Timer C_AddOns C_Item C_Container C_Map C_TooltipInfo C_QuestLog C_Spell C_CVar C_ChatInfo Enum TooltipDataProcessor Settings
GetTime GetLocale InCombatLockdown UnitClass UnitLevel UnitName UnitRace UnitGUID UnitFactionGroup GetRealmName PlaySound SOUNDKIT
RAID_CLASS_COLORS ITEM_QUALITY_COLORS LOCALIZED_CLASS_NAMES_MALE StaticPopup_Show StaticPopup_Hide InterfaceOptions_AddCategory
ChatFrame_AddMessageEventFilter ChatFrame_OpenChat ChatEdit_InsertLink ChatFrame_OnHyperlinkShow SetItemRef SendChatMessage
GetCursorPosition issecretvalue RaidNotice_AddMessage RaidWarningFrame GameFontNormal GameFontHighlight GameFontNormalSmall
GameTooltip_SetDefaultAnchor ShowUIPanel HideUIPanel ToggleFrame CloseDropDownMenus Mixin CreateFromMixins CreateColor CopyTable
GetMoney GetCoinTextureString EventRegistry Menu MenuUtil Item Spell PlayerFrame TargetFrame MainMenuBar CharacterFrame ContainerFrame1
MerchantFrame QuestFrame WorldMapFrame SpellBookFrame ClassTrainerFrame ObjectiveTrackerFrame QuestWatchFrame BuffFrame CastingBarFrame
GameMenuFrame AddonCompartmentFrame ColorPickerFrame STANDARD_TEXT_FONT MAX_PLAYER_LEVEL WOW_PROJECT_ID securecall issecure
ToggleAllBags ToggleBackpack ToggleBag OpenAllBags OpenBackpack OpenBag CloseAllBags CloseBackpack CloseBag CooldownFrame_Set
ContainerFrameCombinedBags ContainerFrameContainer MainActionBar MultiBar5 MultiBar6 MultiBar7 PossessActionBar ProfessionsFrame
PlayerSpellsFrame GameTooltip_Hide SetItemRef ChatFrame_RemoveMessageEventFilter UIDropDownMenu_Initialize ToggleDropDownMenu
""".split() + [f"ContainerFrame{i}" for i in range(1, 14)] + [f"{p}{i}" for p in (
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton")
    for i in range(1, 13)]

# ---------------------------------------------------------------------------------------------------------------
# 4) SavedVariables REALES (solo lectura) de los addons del paquete: cuenta y personaje.
# ---------------------------------------------------------------------------------------------------------------
SV_CARGADAS, SV_ERRORES, SV_FUERA = [], [], []


def leer_bytes(p):
    b = p.read_bytes()
    return b[3:] if b.startswith(b"\xef\xbb\xbf") else b


def cargar_svs():
    for carpeta, clave in ((SV_CUENTA, "sv"), (SV_PJ, "svpj")):
        if not carpeta.exists():
            SV_ERRORES.append(f"no existe {carpeta}")
            continue
        for a in ADDONS.values():
            p = carpeta / f"{a['nombre']}.lua"
            if p.exists():
                ok, err = H.cargarSV(leer_bytes(p), f"SV/{carpeta.parent.name if clave == 'svpj' else 'Cuenta'}/{p.name}")
                (SV_CARGADAS if ok else SV_ERRORES).append(f"{p.name} ({'pj' if clave == 'svpj' else 'cuenta'}, {p.stat().st_size} B)" if ok else f"{p}: {err}")
        nombres = {f"{a}.lua" for a in ADDONS}
        SV_FUERA.extend(sorted(p.name for p in carpeta.glob("*.lua") if p.name not in nombres))


cargar_svs()
# SavedVariables declaradas que el .toc pide y el jugador no tiene guardadas: quedan nil, como en el juego.

# ---------------------------------------------------------------------------------------------------------------
# 5) C_AddOns con los .toc reales; LoadAddOn carga de verdad (con ADDON_LOADED) un addon del paquete.
# ---------------------------------------------------------------------------------------------------------------
CARGADOS, NS, ORDEN, FALTA_ARCHIVO = {}, {}, [], []
EN_CURSO = set()


def cargar_addon(nombre, motivo="lista"):
    """Carga un addon (y antes sus dependencias) como el cliente. Devuelve True si quedó cargado."""
    if nombre in CARGADOS:
        return True
    a = ADDONS.get(nombre)
    if a is None or nombre in EN_CURSO:
        return False
    EN_CURSO.add(nombre)
    for d in a["deps"]:  # obligatorias: si son LoD, se cargan igual (el cliente lo hace)
        if d in ADDONS:
            cargar_addon(d, "dependencia de " + nombre)
    for d in a["opt"]:  # opcionales: solo si no son LoD
        if d in ADDONS and not ADDONS[d]["lod"]:
            cargar_addon(d, "opcional de " + nombre)
    # (una dependencia que se está cargando cuenta: Polestar pide su idioma con LoadAddOn desde Core/Locale.lua)
    falta_dep = [d for d in a["deps"] if d not in CARGADOS and d not in EN_CURSO]
    if falta_dep:
        H.anotarError(f"dependencia {nombre}", L.eval("function(m) return {msg=m, lugar='" + nombre + ".toc'} end")(
            f"{nombre}: dependencia obligatoria ausente o sin cargar: {', '.join(falta_dep)}"))
    ns = L.table()
    NS[nombre] = ns
    base = PAQUETE / nombre
    for rel in a["archivos"]:
        for lua in archivos_lua(base, rel):
            p = base / lua
            if not p.exists():
                FALTA_ARCHIVO.append(f"{nombre}/{lua}")
                continue
            H.cargarArchivo(leer_bytes(p), f"{nombre}/{lua}", nombre, ns)
    CARGADOS[nombre] = True
    EN_CURSO.discard(nombre)
    ORDEN.append((nombre, motivo))
    if nombre == "Polestar":
        UI = G.Polestar and G.Polestar.UI
        if not H.envolverRegistro(UI):
            print("aviso: Polestar.UI.RegisterSection real no quedó; se usa mock_hub.lua")
            G.Polestar = G.Polestar or L.table()
            L.execute((AQUI / "mock_hub.lua").read_text(encoding="utf-8"))
            H.envolverRegistro(G.Polestar.UI)
    antes = H.actual
    H.actual = "(cliente)"
    H.disparar("ADDON_LOADED", nombre)
    H.actual = antes
    return True


def meta(nombre, campo):
    a = ADDONS.get(str(nombre))
    if not a:
        return None
    for k, v in a["meta"].items():
        if k.lower() == str(campo).lower():
            return v
    return None


LISTA = list(ADDONS)


def info(x):
    n = LISTA[int(x) - 1] if not isinstance(x, str) and str(x).isdigit() else str(x)
    a = ADDONS.get(n)
    if not a:
        return n, None, None, False, "MISSING", "INSECURE", False
    return n, meta(n, "Title") or n, meta(n, "Notes") or "", True, None, "INSECURE", False


G.PY = L.table_from({
    "cargar": lambda n: cargar_addon(str(n), "LoadAddOn desde " + str(H.actual)),
    "cargado": lambda n: CARGADOS.get(str(n), False),
    "meta": meta, "info": info, "num": lambda: len(LISTA),
    "lod": lambda n: bool(ADDONS.get(str(n), {}).get("lod")),
    "existe": lambda n: str(n) in ADDONS,
})
L.execute(r"""
C_AddOns = {
	LoadAddOn = function(n) local ok = PY.cargar(n); if ok then return true end return false, "MISSING" end,
	IsAddOnLoaded = function(n) local c = PY.cargado(n); return c, c end,
	GetAddOnMetadata = function(n, f) return PY.meta(n, f) end,
	GetNumAddOns = function() return PY.num() end,
	GetAddOnInfo = function(n) return PY.info(n) end,
	GetAddOnEnableState = function(n) return PY.existe(n) and 2 or 0 end,
	IsAddOnLoadOnDemand = function(n) return PY.lod(n) end,
	DoesAddOnExist = function(n) return PY.existe(n) end,
	IsAddOnLoadable = function(n) return PY.existe(n) end,
	EnableAddOn = function() end, DisableAddOn = function() end,
}
LoadAddOn = C_AddOns.LoadAddOn; IsAddOnLoaded = C_AddOns.IsAddOnLoaded; GetAddOnMetadata = C_AddOns.GetAddOnMetadata
GetNumAddOns = C_AddOns.GetNumAddOns; GetAddOnInfo = C_AddOns.GetAddOnInfo; GetAddOnEnableState = function(_, n) return C_AddOns.GetAddOnEnableState(n) end
IsAddOnLoadOnDemand = C_AddOns.IsAddOnLoadOnDemand
""")
JUEGO += ["LoadAddOn", "IsAddOnLoaded", "GetAddOnMetadata"]
JUEGO = list(dict.fromkeys(JUEGO))  # sin repetidos
L.eval("function(t) local o = {} for i = 1, #t do o[i] = t[i] end H.instalarTrampa(o) end")(L.table_from(JUEGO))
SIN_DEFINIR = list(H.sinDefinir.values()) if H.sinDefinir else []

# ---------------------------------------------------------------------------------------------------------------
# 6) La carga: pasada 1 (no LoD, dependencias primero, alfabético), eventos, ticks, pasada 2 (LoD, a pedido).
# ---------------------------------------------------------------------------------------------------------------
ROMPE = r"""
local addon = ...
SlashCmdList = SlashCmdList or {}
SLASH_ZZROMPER1 = "/capa"
SlashCmdList.ZZROMPER = function() end
hooksecurefunc(GameTooltip, "SetHyperlink", function() end)
GameTooltip:HookScript("OnTooltipSetItem", function() end)
error("roto a proposito")
"""
for nombre in LISTA:
    if not ADDONS[nombre]["lod"]:
        cargar_addon(nombre)
if ROMPER:
    H.cargarArchivo(ROMPE, "ZZ_Romper/Romper.lua", "ZZ_Romper", L.table())
    L.execute('H.actual = "ZZ_Romper"; GameTooltip:HookScript("OnTooltipSetItem", function() end); H.actual = "(prueba)"')
PASADA1 = len(ORDEN)
G.LOGUEADO = True
n_login = H.disparar("PLAYER_LOGIN")
n_mundo = H.disparar("PLAYER_ENTERING_WORLD", True, False)
corridos = sum(H.tic(s) for s in (0, 0.1, 0.5, 1, 2, 5))
for nombre in LISTA:
    if ADDONS[nombre]["lod"] and nombre not in CARGADOS:
        cargar_addon(nombre, "segunda pasada (a pedido)")
corridos += sum(H.tic(s) for s in (0, 0.5, 1, 5, 30))


# ---------------------------------------------------------------------------------------------------------------
# 7) El informe.
# ---------------------------------------------------------------------------------------------------------------
def lista(t):
    return [t[i] for i in range(1, len(t) + 1)] if t else []


def lado(addon):
    return "Mamba" if not str(addon).startswith("Polestar") and str(addon) not in (
        "ForeverCore", "ForeverLootSparkles", "SkillUpForever", "WhatsTraining") else "incluido"


print(f"Paquete: {PAQUETE} ({len(ADDONS)} addons) · SavedVariables: {len(SV_CARGADAS)} archivos reales (cuenta + {PJ})")
if SV_ERRORES:
    print("SavedVariables que NO cargaron:", SV_ERRORES)
print(f"Orden de carga, pasada 1 ({PASADA1}):", ", ".join(n for n, _ in ORDEN[:PASADA1]))
print(f"Pasada 2 / a pedido ({len(ORDEN) - PASADA1}):", ", ".join(n for n, _ in ORDEN[PASADA1:]))
cargados_por_loadaddon = [f"{n} ({m})" for n, m in ORDEN if m.startswith("LoadAddOn")]
if cargados_por_loadaddon:
    print("Cargados por LoadAddOn durante la carga:", "; ".join(cargados_por_loadaddon))
print(f"Eventos: PLAYER_LOGIN → {n_login} marcos, PLAYER_ENTERING_WORLD → {n_mundo} marcos; C_Timer: {corridos} callbacks; "
      f"pendientes en cola: {len(lista(H.cola))}")
if FALTA_ARCHIVO:
    print("ARCHIVOS DEL .toc QUE NO EXISTEN:", FALTA_ARCHIVO)

errores = lista(H.errores)
print(f"\n== ERRORES DE LUA: {len(errores)}")
RUTAS = [f"{n}/{lua}" for n in CARGADOS for rel in ADDONS[n]["archivos"] for lua in archivos_lua(PAQUETE / n, rel)]


def resolver(lugar):
    """Lua recorta las rutas largas ("...ras/libs/x.lua:12"): se completa con la ruta cargada que termina igual."""
    m = re.match(r"(?:\.\.\.)?(.+\.lua):(\d+)$", lugar)
    if not m or m.group(1) in RUTAS:
        return lugar
    cand = [r for r in RUTAS if r.endswith(m.group(1))]
    return f"{cand[0]}:{m.group(2)}" if len(cand) == 1 else lugar


vistos = {}
for e in errores:
    clave = (resolver(str(e.lugar)), str(e.msg)[:200])
    vistos.setdefault(clave, []).append(e)
for (lugar, msg), es in vistos.items():
    e = es[0]
    veces = f" (x{len(es)})" if len(es) > 1 else ""
    print(f"  - {lugar}{veces} [{e.addon} · {e.contexto}] {msg[:300]}")

pisadas = lista(H.pisadas)
cambiadas = []
for k in JUEGO:
    a = H.ANTES[k]
    d = H.JUEGO[k]
    if a is not None and not L.eval("rawequal")(a, d):
        cambiadas.append(k)
# hooksecurefunc del simulado reemplaza la función global (en el juego la envuelve sin reasignar): no cuenta
hookeadas = {str(h.objetivo) for h in lista(H.hooks) if str(h.tipo) == "hooksecurefunc"}
cambiadas = [k for k in cambiadas if k not in hookeadas or any(str(p.nombre) == k for p in pisadas)]
print(f"\n== GLOBALES DEL JUEGO PISADAS (escrituras: {len(pisadas)}; cambiadas rawequal: {len(cambiadas)})")
for p in pisadas:
    print(f"  - {p.donde} [{p.addon}] escribe {p.nombre}" + (" (mismo valor: igual la contamina)" if p.mismo else " (OTRO valor)"))
for k in cambiadas:
    if not any(str(p.nombre) == k for p in pisadas):
        print(f"  - {k}: cambió sin pasar por la trampa (rawset o setfenv)")
if SIN_DEFINIR:
    print("  (no vigiladas porque el simulado no las define:", ", ".join(SIN_DEFINIR) + ")")

# Comandos
slash = lista(H.slash)
por_texto = {}
for s in slash:
    if s.valor is None:
        continue
    m = re.match(r"SLASH_(.+?)(\d+)$", str(s.nombre))
    clave = m.group(1) if m else str(s.nombre)
    por_texto.setdefault(str(s.valor).lower(), []).append((clave, str(s.addon), str(s.donde), str(s.nombre)))
# Comandos propios del cliente (lista conservadora; /rl NO es del juego, lo agregan los addons). NO VERIFICADA
# contra el cliente de Forever: un choque con esta lista se revisa a mano.
JUEGO_CMDS = {"/run", "/script", "/reload", "/console", "/dump", "/tinspect", "/help", "/who", "/w", "/whisper", "/s", "/say",
              "/g", "/p", "/r", "/e", "/emote", "/follow", "/invite", "/cast", "/use", "/target", "/assist", "/macro", "/logout",
              "/camp", "/afk", "/dnd", "/stopwatch", "/roll", "/random", "/framestack", "/fstack", "/eventtrace", "/etrace", "/api",
              "/join", "/leave", "/ignore", "/friends", "/guild", "/raid", "/rw", "/bg", "/i", "/instance", "/played", "/quit",
              "/exit", "/inspect", "/trade", "/duel", "/sit", "/stand", "/dance", "/castsequence", "/stopmacro", "/click", "/equip",
              "/focus", "/pet", "/timetest", "/calendar", "/settings", "/addons", "/mount", "/dismount", "/clear", "/chatlog", "/combatlog",
              "/editmode", "/help", "/loc", "/ui", "/ping"}
choques_cmd = []
for texto, usos in por_texto.items():
    claves = {u[0] for u in usos}
    if len(claves) > 1:
        choques_cmd.append(f"{texto}: " + " · ".join(f"{u[3]} en {u[2]} [{u[1]}]" for u in usos))
    if texto in JUEGO_CMDS:
        choques_cmd.append(f"{texto}: pisa un comando del juego · " + " · ".join(f"{u[3]} en {u[2]} [{u[1]}]" for u in usos))
for s in slash:
    if s.habia:
        choques_cmd.append(f"{s.nombre}: escrito dos veces (otra vez en {s.donde} [{s.addon}])")
dueno_clave = {}
for k in lista(H.slashkeys):
    if k.borrar:
        continue
    dueno_clave.setdefault(str(k.clave), []).append((str(k.addon), str(k.donde)))
for clave, usos in dueno_clave.items():
    if len({u[0] for u in usos}) > 1:
        choques_cmd.append(f"SlashCmdList.{clave}: escrita por varios addons · " + " · ".join(f"{d} [{a}]" for a, d in usos))
    elif len(usos) > 1:
        choques_cmd.append(f"SlashCmdList.{clave}: escrita {len(usos)} veces por {usos[0][0]} · " + " · ".join(d for _, d in usos))
sin_funcion = sorted({k for _, usos in por_texto.items() for k, *_ in usos} - set(dueno_clave) - set(str(k) for k in H.SLASHCMDS.keys()))
print(f"\n== CHOQUES DE COMANDOS: {len(choques_cmd)} (comandos registrados: {len(por_texto)})")
for c in choques_cmd:
    print("  -", c)
if sin_funcion:
    print("  (aviso) SLASH_* sin función en SlashCmdList:", ", ".join(sin_funcion))

# Hooks
hooks = lista(H.hooks)
por_obj = {}
for h in hooks:
    por_obj.setdefault((str(h.tipo), str(h.objetivo)), []).append(h)
dup = {k: v for k, v in por_obj.items() if len({str(h.addon) for h in v}) > 1}
print(f"\n== HOOKS SOBRE EL JUEGO: {len(hooks)} ({len(por_obj)} objetivos) · DUPLICADOS entre addons (aviso): {len(dup)}")
for (tipo, obj), v in sorted(dup.items()):
    print(f"  - {tipo} {obj}: " + " · ".join(f"{h.donde} [{h.addon}]" for h in v))
reemplazos = [h for h in hooks if str(h.tipo) == "SetScript"]
for h in reemplazos:
    print(f"  (aviso) SetScript REEMPLAZA el script del juego {h.objetivo}: {h.donde} [{h.addon}]")
ausentes = [h for h in hooks if h.extra]
for h in ausentes:
    print(f"  (simulado) hooksecurefunc sobre {h.objetivo} — {h.extra}: {h.donde} [{h.addon}] (NO VERIFICADO)")

# Riel
# K109: la entrada «Talentos» de Polestar (T.SOON: «Próximamente») la reemplaza a propósito el planificador de Mamba.
REEMPLAZOS_RIEL = {"Talents": "Asistente"}
secs = lista(H.secciones)
por_clave = {}
for s in secs:
    por_clave.setdefault(str(s.clave), []).append(s)
avisos_riel = []
for k, v in por_clave.items():
    if k in REEMPLAZOS_RIEL and [str(s.addon) for s in v][-1] == REEMPLAZOS_RIEL[k]:
        continue  # reemplazo a propósito (abajo)
    if len({str(s.addon) for s in v}) > 1:
        avisos_riel.append(f"clave {k} registrada por varios addons: " + " · ".join(f"{s.donde} [{s.addon}]" for s in v))
    elif len(v) > 1:
        avisos_riel.append(f"clave {k} registrada {len(v)} veces: " + " · ".join(s.donde for s in v))
riel = []
P = G.Polestar and G.Polestar.UI and G.Polestar.UI.Picker
if P and P.Sections:
    try:
        riel = [(str(s.key), s.order, bool(s.foot)) for s in lista(P.Sections())]
    except Exception as e:  # noqa: BLE001
        print("aviso: no se pudo leer el riel real:", e)
por_orden = {}
for k, o, pie in riel:
    por_orden.setdefault((o if o is not None else 100, pie), []).append(k)
for (o, pie), ks in por_orden.items():
    if len(ks) > 1:
        avisos_riel.append(f"empate de order={o}{' (pie)' if pie else ''} en el riel: {', '.join(ks)} (table.sort no es estable: orden incierto)")
print(f"\n== RIEL DE POLESTAR: {len(secs)} registros · {len(riel)} secciones · avisos: {len(avisos_riel)}")
print("  orden:", " › ".join(f"{k}({o})" + ("·pie" if pie else "") for k, o, pie in riel))
for a in avisos_riel:
    print("  -", a)

# K109: ninguna sección visible del riel en «Próximamente» ni vacía. Se abre el hub y cada sección, como un clic.
if ROMPER:
    L.execute("""
    H.actual = "ZZ_Romper"
    if Polestar and Polestar.UI and Polestar.UI.RegisterSection then
      Polestar.UI.RegisterSection({ key = "ZZFalsa", label = "Falsa", order = 999,
        build = function(f) local t = f:CreateFontString(); t:SetText("Próximamente") end, render = function() end })
    end
    H.actual = "(prueba)"
    """)
L.execute(r"""
function H.revisarRiel()
  local out, noAbre, UI = {}, {}, Polestar and Polestar.UI
  local P = UI and UI.Picker
  if not (UI and UI.ShowPicker and P and P.Sections and P.ShowSection) then return out, false end
  local ok, e = pcall(UI.ShowPicker)
  if not ok then out[#out + 1] = { "(hub)", "no se abre: " .. tostring(e) } return out, true end
  local function bajo(x, f)
    local p = x
    while p do if p == f then return true end p = p.padre end
    return false
  end
  for _, s in ipairs(P.Sections()) do
    if not s.builtin then
      local ok2, e2 = pcall(P.ShowSection, s.key)
      if not ok2 then
        noAbre[#noAbre + 1] = { s.key, tostring(e2):sub(1, 160) }
      elseif s.psFrame then
        local n, malo = 0, nil
        for _, x in ipairs(TODOS) do
          local t = type(x.text) == "string" and x.text or nil
          if t and t:gsub("%s", "") ~= "" and x:IsVisible() and bajo(x, s.psFrame) then
            n = n + 1
            if t:find("Próximamente", 1, true) or t:find("Coming soon", 1, true) then malo = t end
          end
        end
        if malo then out[#out + 1] = { s.key, "muestra «" .. malo:sub(1, 60) .. "»" }
        elseif n == 0 then out[#out + 1] = { s.key, "vacía: ningún texto a la vista" } end
      end
    end
  end
  H.rielNoAbre = noAbre
  return out, true
end
""")
riel_malas, riel_revisado = L.eval("function() local o, r = H.revisarRiel(); return o, r end")()
riel_no_abre = [(str(x[1]), str(x[2])) for x in lista(H.rielNoAbre)] if H.rielNoAbre else []
riel_malas = [(str(x[1]), str(x[2])) for x in lista(riel_malas)] if riel_malas else []
print(f"\n== RIEL SIN «PRÓXIMAMENTE» NI VACÍAS (K109): {'revisado' if riel_revisado else 'NO REVISADO (sin el hub real)'} · fallas: {len(riel_malas)}")
for k, m in riel_malas:
    print(f"  - {k}: {m}")
for k, m in riel_no_abre:
    print(f"  (NO VERIFICADO) {k}: el simulado no la pudo abrir: {m}")

# K124 (regla de Cristian, 19-11): todo lo de Mamba que se ve o actúa solo se enciende y se apaga desde Ajustes ›
# Mamba › Qué se muestra (MambaAPI.Interruptor, Asistente/Interruptores.lua). Se recorre cada addon de Mamba del
# paquete: si creó un marco que escucha eventos del juego o que cuelga de la pantalla (UIParent/Minimap), tiene que
# haber publicado al menos un interruptor con su nombre de addon. Los que todavía no lo tienen están en
# tools/asistente/interruptores_pendientes.json con su dueño: la lista solo puede achicarse (si uno ya tiene su
# interruptor y sigue en la lista, también FALLA, para sacarlo). Además, cada interruptor cumple su contrato: get()
# da un booleano, set(no v) lo da vuelta y set(v) lo deja como estaba.
import json
PENDIENTES_K124 = json.loads((AQUI.parent / "interruptores_pendientes.json").read_text(encoding="utf-8"))["pendientes"]
if ROMPER:
    L.execute("""
    H.actual = "ZZ_SinInterruptor"
    local f = CreateFrame("Frame", "ZZSinInterruptorMarco", UIParent)
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    H.actual = "ZZ_Romper"
    if MambaAPI and MambaAPI.Interruptor then
      MambaAPI.Interruptor({ id = "zz.roto", addon = "ZZ_Romper", nombre = "Roto", grupo = "Otros",
        get = function() return true end, set = function() end })
      local zz = true
      MambaAPI.Interruptor({ id = "zz.sinGuardar", addon = "ZZ_Romper", nombre = "Sin guardar", grupo = "Otros",
        get = function() return zz end, set = function(v) zz = v end })
    end
    H.actual = "(prueba)"
    """)
L.execute(r"""
-- Lo que «se ve o actúa solo»: un marco del addon que escucha eventos que no son solo de carga, o que cuelga
-- directo de la pantalla o del minimapa.
local CARGA = { ADDON_LOADED = true, PLAYER_LOGIN = true, PLAYER_ENTERING_WORLD = true, VARIABLES_LOADED = true,
  PLAYER_LOGOUT = true, GET_ITEM_INFO_RECEIVED = true }
function H.k124Actividad()
  local act = {}
  for _, f in ipairs(TODOS) do
    local d = rawget(f, "__dueno")
    if d and d ~= "(prueba)" then
      local motivo
      for e in pairs(rawget(f, "ev") or {}) do if type(e) == "string" and not CARGA[e] then motivo = "escucha " .. e break end end
      if not motivo and rawget(f, "todos") then motivo = "escucha todos los eventos" end
      local p = rawget(f, "padre")
      if not motivo and (p == UIParent or p == Minimap) and type(rawget(f, "nombre")) == "string" then motivo = "marco " .. rawget(f, "nombre") .. " en pantalla" end
      if motivo and not act[d] then act[d] = motivo end
    end
  end
  return act
end
""")
act_k124 = {str(k): str(v) for k, v in L.eval("function() return H.k124Actividad() end")().items()}
api_k124 = G.MambaAPI
interruptores = []
if api_k124 is not None and api_k124.Interruptores is not None:
    interruptores = [dict(id=str(x.id), addon=str(x.addon), grupo=str(x.grupo), nombre=str(x.nombre)) for x in lista(api_k124.Interruptores())]
con_interruptor = {x["addon"] for x in interruptores}
k124_sin, k124_viejos, k124_contrato = [], [], []
for addon in sorted(set(act_k124) | set(PENDIENTES_K124)):
    if lado(addon) != "Mamba":
        continue
    tiene = addon in con_interruptor
    if addon in act_k124 and not tiene and addon not in PENDIENTES_K124:
        k124_sin.append((addon, act_k124[addon]))
    if tiene and addon in PENDIENTES_K124:
        k124_viejos.append(addon)
# contrato: por cada interruptor, get -> bool; set(no v) lo da vuelta; set(v) lo devuelve
probar_k124 = L.eval("""function(id)
  local api = MambaAPI
  local v0 = api.InterruptorEncendido(id)
  if type(v0) ~= "boolean" then return "get no da un booleano" end
  local spec
  for _, x in ipairs(api._InterruptoresCrudos and api._InterruptoresCrudos() or {}) do if x.id == id then spec = x end end
  if not spec then return "no está en el registro" end
  local ok, e = pcall(spec.set, not v0)
  if not ok then return "set falla: " .. tostring(e):sub(1, 100) end
  if api.InterruptorEncendido(id) ~= (not v0) then return "set(" .. tostring(not v0) .. ") no lo cambia" end
  ok, e = pcall(spec.set, v0)
  if not ok then return "set falla al volver: " .. tostring(e):sub(1, 100) end
  if api.InterruptorEncendido(id) ~= v0 then return "set(" .. tostring(v0) .. ") no lo deja como estaba" end
  return nil
end""")
for x in interruptores:
    m = probar_k124(x["id"])
    if m is not None:
        k124_contrato.append((x["id"], str(m)))
# revisor t9: que set y get coincidan no basta. Cada interruptor tiene que GUARDARSE (cambia alguna SavedVariable:
# o una CVar, que el cliente guarda en Config.wtf; si no, se pierde al salir del juego) y, en los de Asistente, Tasador, Medidor y Errores, tener EFECTO medido (el
# marco o el gancho dejan de actuar). Un interruptor sin prueba de efecto aquí sale como NO VERIFICADO.
L.execute(r"""
function H.k124Foto(nombres)
  local partes = {}
  local function ser(v, prof, vistos)
    local t = type(v)
    if t ~= "table" then return t == "string" and ("%q"):format(v) or tostring(v) end
    if prof > 14 or vistos[v] then return "{...}" end
    vistos[v] = true
    local ks = {}
    for k in pairs(v) do ks[#ks + 1] = k end
    table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
    local o = {}
    for _, k in ipairs(ks) do o[#o + 1] = tostring(k) .. "=" .. ser(v[k], prof + 1, vistos) end
    vistos[v] = nil
    return "{" .. table.concat(o, ",") .. "}"
  end
  for _, n in ipairs(nombres) do partes[#partes + 1] = n .. "=" .. ser(rawget(_G, n) or _G[n], 0, {}) end
  partes[#partes + 1] = "CVars=" .. ser(CVARS, 0, {})
  return table.concat(partes, ";")
end
function H.k124Spec(id)
  for _, x in ipairs(MambaAPI._InterruptoresCrudos()) do if x.id == id then return x end end
end
-- Efecto de cada interruptor propio: fn(encendido) -> nil si se comporta como dice, o el motivo.
local function espiar(t, k, fn)
  local orig = t[k]
  local llamado = false
  t[k] = function(...) llamado = true; if fn then return fn(...) end return orig(...) end
  return function() t[k] = orig; return llamado end
end
local function mostrado(nombre)
  local f = rawget(_G, nombre) or _G[nombre]
  if type(f) ~= "table" or not f.IsShown then return nil end
  return f:IsShown() and true or false
end
H.k124Efecto = {
  ["tasador.cuadro"] = function(en)
    local T = Tasador
    local fin = espiar(T, "TextosDeDatos", function() error("espía") end)
    pcall(T.AgregarLineas, GameTooltip, "item:6948", nil)
    if fin() ~= en then return "el bloque del cuadro " .. (en and "no se agrega" or "se sigue agregando") end
  end,
  ["tasador.recompensa"] = function(en)
    local R = Polestar and Polestar.QoL and Polestar.QoL.Rewards
    if not (R and R.Rank) then return "NO VERIFICADO" end
    local fin = espiar(Tasador, "RecompensaDe", function() return nil end)
    pcall(R.Rank, {})
    if fin() ~= en then return "la recomendación " .. (en and "no se calcula" or "se sigue calculando") end
  end,
  ["tasador.escanear"] = function(en)
    local habia = rawget(_G, "AuctionHouseFrame")
    if not habia then rawset(_G, "AuctionHouseFrame", CreateFrame("Frame")) end
    pcall(Tasador.AplicarBotonEscanear)
    local v = mostrado("TasadorBotonEscanear")
    if not habia then rawset(_G, "AuctionHouseFrame", nil) end
    if v == nil and en then return "el botón no aparece con la subasta abierta" end
    if v ~= nil and v ~= en then return "el botón " .. (en and "no se ve" or "se sigue viendo") end
  end,
  ["ventana.boton"] = function(en)
    local v = mostrado("MambaBotonMinimapa")
    if v ~= nil and v ~= en then return "el botón del minimapa " .. (en and "no se ve" or "se sigue viendo") end
    if v == nil and en then return "no hay botón del minimapa" end
  end,
  ["capa.cuadro"] = function(en)
    local v = mostrado("AsistenteCapa")
    if v ~= nil and v ~= en then return "el cuadro de la capa " .. (en and "no se ve" or "se sigue viendo") end
    if v == nil and en then return "no hay cuadro de la capa" end
  end,
  ["capa.aviso"] = function(en)
    local A = Asistente
    local C = A.Capa
    local mapa = A.MapaActual and A.MapaActual() or nil
    local antesC, antesG = C.actual, UnitGUID
    C.actual = { zona = "1", clave = "1:2:1", cuando = 0, mapa = mapa }
    UnitGUID = function() return "Creature-0-1-2-99-3-4" end
    local fin = espiar(A, "Decir", function() end)
    pcall(C.Observar, "target")
    local dijo = fin()
    UnitGUID, C.actual = antesG, antesC
    if dijo ~= en then return "el aviso de cambio de capa " .. (en and "no sale" or "sigue saliendo") end
  end,
  ["medidor.reloj"] = function(en)
    local M = Medidor
    M.pausa = false -- como al entrar al juego: lo que manda es lo guardado
    pcall(M.Iniciar)
    if (not M.pausa) ~= en then return "al volver a entrar el reloj queda " .. (M.pausa and "en pausa" or "andando") end
  end,
  ["errores.anotar"] = function(en)
    local db = MambaErroresDB
    if type(db) ~= "table" or type(db.lista) ~= "table" then return "NO VERIFICADO" end
    local n = #db.lista
    H.k124n = (H.k124n or 0) + 1
    H.disparar("ADDON_ACTION_BLOCKED", "ZZ_K124", "Prueba" .. H.k124n)
    local anoto = #db.lista > n
    if anoto ~= en then return "el error " .. (en and "no se anota" or "se sigue anotando") end
  end,
}
""")
svs_de = {n: [str(x) for x in ADDONS[n]["sv"] + ADDONS[n]["svpj"]] for n in ADDONS}
todas_svs = sorted({s for v in svs_de.values() for s in v})
foto = L.eval("function(t) return H.k124Foto(t) end")
spec_de = L.eval("function(id) return H.k124Spec(id) end")
efecto_de = L.eval("function(id) return H.k124Efecto[id] end")
fijar_k124 = L.eval("function(s, v) pcall(s.set, v) end")
leer_k124 = L.eval("function(s) local ok, v = pcall(s.get); return ok and v and true or false end")
correr_efecto = L.eval("function(f, en) local ok, m = pcall(f, en); if not ok then return 'la prueba de efecto falla: ' .. tostring(m) end; return m end")
k124_sin_efecto = []
for x in interruptores:
    s = spec_de(x["id"])
    if s is None:
        continue
    v0 = bool(leer_k124(s))
    propias = L.table_from(svs_de.get(x["addon"], []))
    antes_p = foto(propias)
    fijar_k124(s, not v0)
    cambio = foto(propias) != antes_p
    if not cambio:
        # puede guardarlo en las SavedVariables de otro addon (p. ej. AsistenteDB): se miran todas
        todas = L.table_from(todas_svs)
        fijar_k124(s, v0)
        antes_t = foto(todas)
        fijar_k124(s, not v0)
        cambio = foto(todas) != antes_t
    if not cambio:
        k124_contrato.append((x["id"], "set no guarda nada en SavedVariables: se pierde al salir del juego"))
    fn = efecto_de(x["id"])
    if fn is not None:
        for en in (not v0, v0):
            fijar_k124(s, en)
            m = correr_efecto(fn, en)
            if m == "NO VERIFICADO":
                k124_sin_efecto.append(x["id"])
                break
            if m is not None:
                k124_contrato.append((x["id"], f"{'encendido' if en else 'apagado'}: {m}"))
                break
    else:
        k124_sin_efecto.append(x["id"])
    fijar_k124(s, v0)

# y que llegan a la ventana de ajustes de Polestar: Ajustes › Mamba › «Qué se muestra», un control por interruptor
en_ajustes = L.eval("""function()
  local W = Polestar and Polestar.Widgets
  if not (W and W.OnOptionsRegistered) then return -1 end
  local n = 0
  W.OnOptionsRegistered(function(spec)
    if spec.page == "Mamba" and spec.tab == "Qué se muestra" then
      for _, c in ipairs(spec.controls or {}) do if c.kind == "toggle" then n = n + 1 end end
    end
  end)
  return n
end""")()
if en_ajustes != -1 and en_ajustes != len(interruptores):
    k124_contrato.append(("(Ajustes)", f"«Qué se muestra» tiene {en_ajustes} controles y hay {len(interruptores)} interruptores"))
print(f"\n== K124: TODO SE APAGA DESDE «QUÉ SE MUESTRA»: {len(interruptores)} interruptores de {len(con_interruptor)} addons · "
      f"sin interruptor: {len(k124_sin)} · pendientes con dueño: {len([a for a in PENDIENTES_K124 if a not in con_interruptor])} · "
      f"lista vieja: {len(k124_viejos)} · contrato roto: {len(k124_contrato)} · en Ajustes: {en_ajustes if en_ajustes != -1 else 'NO VERIFICADO'} · efecto sin medir: {len(k124_sin_efecto)}")
for a, m in k124_sin:
    print(f"  - FALLA {a}: {m} y no publicó ningún interruptor (MambaAPI.Interruptor)")
for a in k124_viejos:
    print(f"  - FALLA {a} ya tiene interruptor: sacarlo de tools/asistente/interruptores_pendientes.json")
for i, m in k124_contrato:
    print(f"  - FALLA interruptor {i}: {m}")
if k124_sin_efecto:
    print("  (NO VERIFICADO, efecto sin prueba aquí; sí se miden el contrato y el guardado) " + ", ".join(k124_sin_efecto))
for a, d in sorted(PENDIENTES_K124.items()):
    if a not in con_interruptor:
        print(f"  (pendiente) {a}: {act_k124.get(a, 'sin actividad en el simulado')} · dueño: {d}")
k124_falla = len(k124_sin) + len(k124_viejos) + len(k124_contrato)

falto = lista(G.FALTO)
print(f"\n== AGREGADO AL SIMULADO EN ESTA PRUEBA ({len(falto)} entradas; los mocks compartidos no se tocaron):")
print("  " + "; ".join(str(x) for x in falto))
if XML_SIN_ARCHIVO:
    print("  NO VERIFICADO (marcos/plantillas en XML que el simulado no crea):", ", ".join(sorted(set(XML_SIN_ARCHIVO))))
nil_leidas = {str(k): str(v) for k, v in H.nil_leidas.items()}
if DETALLE:
    print(f"  globales con nombre de API leídas y ausentes en el simulado ({len(nil_leidas)}):")
    for k in sorted(nil_leidas):
        print(f"    {k}  ({nil_leidas[k]})")
else:
    print(f"  ({len(nil_leidas)} globales con nombre de API leídas y ausentes: --detalle las lista; la mayoría son addons opcionales)")
print(f"  SavedVariables de addons fuera del paquete, no cargadas (como el cliente): {len(SV_FUERA)}")

falla = len(errores) > 0 or len(pisadas) > 0 or len(cambiadas) > 0 or len(choques_cmd) > 0 or len(riel_malas) > 0 or k124_falla > 0
print(f"\nRESULTADO: {len(ADDONS)} addons, {len(errores)} errores de Lua, {len(pisadas)} globales pisadas, "
      f"{len(choques_cmd)} choques de comandos, {len(riel_malas)} secciones del riel en Próximamente o vacías, {k124_falla} fallas K124, {len(dup)} hooks duplicados (aviso), {len(avisos_riel)} avisos del riel"
      f" → {'FALLA' if falla else 'OK'}" + (" [--romper]" if ROMPER else ""))
sys.exit(1 if falla else 0)
