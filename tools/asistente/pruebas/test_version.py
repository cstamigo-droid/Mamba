"""Pruebas de Mamba_Version (aviso de versión nueva entre compañeros), con Lua 5.1 (lupa). 19-11-2026.
Uso: python test_version.py [carpeta addon] [--romper]
--romper: control negativo; carga una Version.lua que nunca avisa. Las pruebas del aviso tienen que fallar."""
import pathlib
import sys

sys.stdout.reconfigure(encoding="utf-8")
from lupa.lua51 import LuaRuntime

AQUI = pathlib.Path(__file__).parent
args = [a for a in sys.argv[1:] if not a.startswith("--")]
ROMPER = "--romper" in sys.argv
BASE = pathlib.Path(args[0]) if args else AQUI.parents[2] / "addon"
ok = fail = 0


def check(cond, msg):
    global ok, fail
    if cond:
        ok += 1
    else:
        fail += 1
        print("FALLA:", msg)


ENTORNO = r'''
chat, errores, handlers, enviados, prefijos = {}, {}, {}, {}, {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(chat, m) end }
UIErrorsFrame = { AddMessage = function(_, m) table.insert(errores, m) end }
T = 100
function GetTime() return T end
GRUPO, BANDA, BLOQUEO = true, false, false
LE_PARTY_CATEGORY_INSTANCE = 2
function IsInGroup(cat) if cat == 2 then return false end return GRUPO end
function IsInRaid() return BANDA end
function UnitName() return "Yo" end
function Ambiguate(n) return (n:gsub("%-.*", "")) end
C_ChatInfo = {
  RegisterAddonMessagePrefix = function(p) prefijos[p] = true end,
  InChatMessagingLockdown = function() return BLOQUEO end,
  SendAddonMessage = function(p, m, c, d) table.insert(enviados, { p = p, m = m, c = c, d = d }) end,
}
function CreateFrame()
  local f = { ev = {} }
  function f:RegisterEvent(e) self.ev[e] = true end
  function f:SetScript(_, fn) table.insert(handlers, { f = self, fn = fn }) end
  return f
end
function Fire(e, ...) for _, h in ipairs(handlers) do if h.f.ev[e] then h.fn(h.f, e, ...) end end end
'''

ROTA = 'MambaVersion = { Recibir = function() end, Codificar = function() return "" end, Decodificar = function() end }'


def nuevo(build, db=None):
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute(ENTORNO)
    if db:
        L.execute(db)
    cargar = L.eval('function(src, name) local f, e = loadstring(src, "@"..name); if not f then error(e) end; f("Mamba_Version", {}) end')
    cargar((BASE / "Mamba_Version" / "Sello.lua").read_text(encoding="utf-8"), "Sello.lua")
    L.execute(f'MambaSello.build = {build}; MambaSello.texto = "beta {build}"')
    src = ROTA if ROMPER else (BASE / "Mamba_Version" / "Version.lua").read_text(encoding="utf-8")
    cargar(src, "Version.lua")
    L.execute('Fire("PLAYER_LOGIN")')
    return L


toc = (BASE / "Mamba_Version" / "Mamba_Version.toc").read_text(encoding="utf-8")
check(toc.splitlines()[0].startswith("## Interface: 16001"), "el .toc es para el cliente de Forever (16001)")
check("Sello.lua" in toc and toc.index("Sello.lua") < toc.index("Version.lua"), "Sello.lua carga antes que Version.lua")
check("## Category: Mamba" in toc, "va en la categoría Mamba de la lista de addons")

# 1. Al entrar a un grupo manda su sello con su prefijo propio
L = nuevo(202611191200)
check(L.eval("prefijos.MAMBAver") is True, "registra el prefijo MAMBAver")
L.execute('Fire("GROUP_ROSTER_UPDATE")')
check(L.eval("#enviados") == 1 and L.eval("enviados[1].p") == "MAMBAver" and L.eval("enviados[1].c") == "PARTY",
      "manda su versión al grupo")
check(L.eval("enviados[1] and enviados[1].m") == "V1|202611191200|beta 202611191200", "el mensaje lleva build y texto")
L.execute('Fire("GROUP_ROSTER_UPDATE")')
check(L.eval("#enviados") == 1, "no repite el envío antes de 30 s")
L.execute('T = 140; Fire("GROUP_ROSTER_UPDATE")')
check(L.eval("#enviados") == 2, "pasados 30 s vuelve a mandar")
L.execute('T = 200; BANDA = true; Fire("GROUP_ROSTER_UPDATE")')
check(L.eval("enviados[#enviados] and enviados[#enviados].c") == "RAID", "en banda usa RAID")

# 2. Recibe una más nueva: avisa UNA vez y lo recuerda
L = nuevo(202611191200)
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611221800|beta 3", "PARTY", "Kud-Forever")')
check(L.eval("#chat") == 1 and "versión nueva" in (L.eval("chat[1]") or ""), "avisa en el chat que hay versión nueva")
check("Kud" in (L.eval("chat[1]") or "") and "beta 3" in (L.eval("chat[1]") or ""), "el aviso dice quién la tiene y cuál es")
check(L.eval("#errores") == 1, "también lo muestra en el centro de la pantalla")
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611231800|beta 4", "PARTY", "Otro")')
check(L.eval("#chat") == 1, "avisa una sola vez por sesión")
check(L.eval("MambaVersionDB and MambaVersionDB.masNueva") == 202611231800, "guarda la más nueva vista")

# 3. Al volver a entrar con la vieja, recuerda; con la nueva instalada, no
L = nuevo(202611191200, 'MambaVersionDB = { masNueva = 202611221800, texto = "beta 3", quien = "Kud" }')
check(L.eval("#chat") == 1, "al entrar con la vieja, recuerda que hay una nueva")
L = nuevo(202611221800, 'MambaVersionDB = { masNueva = 202611221800, texto = "beta 3", quien = "Kud" }')
check(L.eval("#chat") == 0, "ya actualizado: no avisa")

# 4. Recibe una más vieja: no avisa y le responde al atrasado por susurro (una vez por minuto)
L = nuevo(202611221800)
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "Atrasado-Forever")')
check(L.eval("#chat") == 0, "una versión más vieja no genera aviso")
check(L.eval("#enviados") == 1 and L.eval("enviados[1].c") == "WHISPER" and L.eval("enviados[1].d") == "Atrasado-Forever",
      "le responde al atrasado por susurro, con su nombre COMPLETO (llega aunque sea de otro reino)")
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "Atrasado-Forever")')
check(L.eval("#enviados") == 1, "no le responde dos veces seguidas")

# 5. Lo que no debe hacer
L = nuevo(202611191200)
L.execute('Fire("CHAT_MSG_ADDON", "Polestar", "V1|209999999999|x", "PARTY", "Oficial")')
check(L.eval("#chat") == 0, "ignora los mensajes de otros prefijos (Polestar oficial)")
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "basura", "PARTY", "X")')
check(L.eval("#chat") == 0, "ignora mensajes mal formados")
L.execute('BLOQUEO = true; T = 999; Fire("GROUP_ROSTER_UPDATE")')
check(L.eval("#enviados") == 0, "con el chat de addons bloqueado (mazmorra) no manda")
L = nuevo(0)
L.execute('Fire("GROUP_ROSTER_UPDATE")')
check(L.eval("#enviados") == 0, "una copia sin sellar no anuncia")
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "X")')
check(L.eval("#chat") == 1, "una copia sin sellar sí escucha (y avisa)")
L = nuevo(202611191200)
L.execute('GRUPO = false; Fire("PLAYER_ENTERING_WORLD")')
check(L.eval("#enviados") == 0, "solo, sin grupo, no manda nada")

# 6. Banda con muchos atrasados: tope global de susurros (revisor t6)
L = nuevo(202611221800)
L.execute('BANDA = true')
L.execute('for i = 1, 20 do Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "RAID", "Atr" .. i .. "-Forever") end')
check(L.eval("(function() local n = 0 for _, e in ipairs(enviados) do if e.c == 'WHISPER' then n = n + 1 end end return n end)()") == 1,
      "20 atrasados a la vez: un solo susurro (tope de 1 cada 2 s)")
check(L.eval("(function() local n = 0 for _, e in ipairs(enviados) do if e.c == 'RAID' then n = n + 1 end end return n end)()") == 1,
      "y un solo anuncio a la banda, que les llega a todos los demás")
L.execute('T = T + 3; Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "RAID", "Nuevo-Forever")')
check(L.eval("enviados[#enviados] and enviados[#enviados].d") == "Nuevo-Forever", "pasados 2 s vuelve a susurrar")
# 7. Las esperas se marcan solo si salió algo (revisor t7)
L = nuevo(202611221800)
L.execute('BLOQUEO = true; Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "X-Forever")')
check(L.eval("#enviados") == 0, "con el chat de addons bloqueado no sale el susurro")
L.execute('BLOQUEO = false; T = T + 1; Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "X-Forever")')
check(L.eval("#enviados") == 0, "tras un fallo, pausa de 5 s antes de reintentar (no reintenta con cada mensaje)")
L.execute('T = T + 5; Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "X-Forever")')
check(L.eval("#enviados") == 1 and L.eval("enviados[1].d") == "X-Forever",
      "pasada la pausa, a X se le responde (no quedó 60 s marcado sin aviso)")
L = nuevo(202611221800)
L.execute('Fire("GROUP_ROSTER_UPDATE")')  # anuncio al grupo: la espera de 30 s del grupo queda corriendo
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "A-Forever")')  # susurro: tope global
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "B-Forever")')  # tope y anuncio en espera
n = L.eval("#enviados")
L.execute('T = T + 3; Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "B-Forever")')
check(L.eval("#enviados") == n + 1 and L.eval("enviados[#enviados].d") == "B-Forever",
      "a B, que no recibió nada por el tope, se le responde en cuanto pasa el tope (no 60 s después)")

L = nuevo(202611191200)
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611221800|beta 3", "PARTY", "Kud-OtroReino")')
check("Kud" in (L.eval("chat[1]") or "") and "OtroReino" not in (L.eval("chat[1]") or ""), "el aviso muestra el nombre corto")

# 8. El juego frena el envío (devuelve un código de rechazo): no cuenta como enviado (revisor t7)
L = nuevo(202611221800)
L.execute('RESULTADO = 3; C_ChatInfo.SendAddonMessage = function(p, m, c, d) table.insert(enviados, { p = p, m = m, c = c, d = d }); return RESULTADO end')
check(L.eval("MambaVersion.Salio(true, 0)") is True and L.eval("MambaVersion.Salio(true, 3)") is False,
      "código 0 = salió; 3 (tope del juego) = no salió")
check(L.eval("MambaVersion.Salio(true)") is True and L.eval("MambaVersion.Salio(true, false)") is False
      and L.eval("MambaVersion.Salio(false)") is False, "booleano o nada (clientes viejos) y error de Lua")
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "Y-Forever")')
L.execute('RESULTADO = 0; T = T + 6; Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611191200|beta 1", "PARTY", "Y-Forever")')
check(L.eval("#enviados") == 2, "un susurro frenado por el juego se reintenta (no se marcó el minuto de espera)")

# 9. K124: los dos interruptores de Ajustes (sin comandos)
L = nuevo(202611191200)
L.execute('INT = {}; for _, s in ipairs(MambaInterruptoresPendientes or {}) do INT[s.id] = s end')
check(L.eval("INT['version.aviso'] ~= nil and INT['version.responder'] ~= nil"),
      "publica sus dos interruptores (en la cola, porque aquí no hay MambaAPI)")
check(L.eval("INT['version.aviso'] and INT['version.aviso'].addon") == "Mamba_Version", "con addon = Mamba_Version")
for i in ("version.aviso", "version.responder"):
    check(L.eval(f"INT['{i}'].get()") is True, f"{i}: encendido por defecto")
    L.execute(f"INT['{i}'].set(false)")
    check(L.eval(f"INT['{i}'].get()") is False, f"{i}: set(false) lo apaga")
L.execute('Fire("CHAT_MSG_ADDON", "MAMBAver", "V1|202611221800|beta 3", "PARTY", "Kud-Forever")')
check(L.eval("#chat") == 0, "con el aviso apagado no avisa")
check(L.eval("MambaVersionDB.masNueva") == 202611221800, "pero sigue anotando la versión más nueva")
L.execute('T = 999; Fire("GROUP_ROSTER_UPDATE")')
check(L.eval("#enviados") == 0, "con «contarle a tu grupo» apagado no manda nada")
L.execute("INT['version.aviso'].set(true); INT['version.responder'].set(true)")
check(L.eval("INT['version.aviso'].get()") is True and L.eval("MambaVersionDB.sinAviso") is None, "set(true) lo vuelve a encender")

print(f"{ok} OK, {fail} fallas")
sys.exit(1 if fail else 0)
