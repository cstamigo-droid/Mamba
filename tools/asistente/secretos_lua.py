"""K111: busca en los addons de Mamba los usos de valores que Forever puede devolver SECRETOS (19-11-2026).

En Forever (las mismas reglas que Midnight), muchas lecturas de unidades, auras, lanzamientos y amenaza
devuelven un "valor secreto" en combate o en instancias. Se puede mostrar (SetText, SetValue), pero el juego
tira error si el addon lo usa en un if, un and/or/not, una comparación o una cuenta. Así se rompió Medidor el
19-11: `if M.pausa or UnitIsAFK("player") then` dio 32.573 errores en una mazmorra.

En el simulado (Lua 5.1 o lupa) la prueba booleana NO se puede interceptar: una tabla siempre es "verdadera" y no
hay metamétodo para `if x`. Por eso este chequeo es ESTÁTICO y corre en gate_tanda.sh antes de cada instalación.

Marca, en Asistente*, Mamba_*, Medidor y Tasador (no en Polestar ni en addons de terceros):
  1. una llamada a una API de la lista usada DIRECTO como condición, con and/or/not, en una comparación o en
     una cuenta: `if UnitIsAFK("player") then`, `UnitHealth(u) / max`, `UnitHealth(u) or 0`;
  2. una variable local que recibe esa API sin envoltorio y en las 40 líneas siguientes se usa así, sin pasar
     antes por issecretvalue(variable) ni reasignarse.
Lo que pasa por un envoltorio (Legible(...), M.Num(...), issecretvalue(...), cualquier función) no se marca: la
API queda como argumento. Una línea con `-- secreto-ok` se acepta a mano (dejar escrita la razón).

Uso: python -I tools/asistente/secretos_lua.py addon [--todo]   -> sale 1 si encuentra algo.
     python -I tools/asistente/secretos_lua.py --probar          -> control positivo y negativo del detector.
"""
import pathlib
import re
import sys

# API que pueden devolver un valor secreto en Forever. Conservadora: vida, poder, amenaza, lanzamientos, auras,
# muerte/ausencia y la identidad de unidades que no son el jugador. Nombre, nivel y clase de "player" no cuentan.
API = [
    "UnitHealth", "UnitHealthMax", "UnitPower", "UnitPowerMax", "UnitGetIncomingHeals", "UnitGetTotalAbsorbs",
    "UnitIsAFK", "UnitIsDND", "UnitIsDead", "UnitIsGhost", "UnitIsDeadOrGhost", "UnitIsFeignDeath",
    "UnitDetailedThreatSituation", "UnitThreatSituation", "UnitCastingInfo", "UnitChannelInfo",
    "UnitXP", "UnitXPMax", "UnitAura", "UnitBuff", "UnitDebuff",
    "C_UnitAuras.GetAuraDataByIndex", "C_UnitAuras.GetAuraDataBySlot", "C_UnitAuras.GetPlayerAuraBySpellID",
    "C_UnitAuras.GetAuraDataByAuraInstanceID", "C_UnitAuras.GetBuffDataByIndex", "C_UnitAuras.GetDebuffDataByIndex",
    "AuraUtil.FindAuraByName", "UnitGUID", "UnitName", "UnitLevel",
]
SOLO_OTRAS = {"UnitName", "UnitLevel", "UnitGUID"}  # con "player" no se marcan
CARPETAS = re.compile(r"^(Asistente.*|Mamba_.*|Medidor|Tasador)$")
OPS_DESPUES = re.compile(r"^\s*(and\b|or\b|then\b|do\b|==|~=|<=|>=|<|>|\+|-(?!-)|\*|/|%|\^)")
# antes de la llamada: `x and API()` / `x or API()` NO prueban el resultado (lo devuelven tal cual), salvo que
# todo sea la condición de un if/while (eso lo mira en_condicion)
OPS_ANTES = re.compile(r"(\bif|\belseif|\bwhile|\buntil|\bnot|==|~=|<=|>=|<|>|\+|-|\*|/|%|\^)\s*$")
COND = re.compile(r"^\s*(if|elseif|while)\b")
NOMBRE_API = "|".join(re.escape(a) for a in sorted(API, key=len, reverse=True))
LLAMADA = re.compile(r"(?<![\w.:])(" + NOMBRE_API + r")\s*\(")
ASIGNA = re.compile(r"^\s*(?:local\s+)?([A-Za-z_][\w]*(?:\s*,\s*[A-Za-z_][\w]*)*)\s*=\s*(" + NOMBRE_API + r")\s*\(")


def sin_comentario(linea):
    # quita el comentario -- (sin entrar en cadenas, aproximado: suficiente para el código de Mamba)
    fuera, i, q = [], 0, None
    while i < len(linea):
        c = linea[i]
        if q:
            fuera.append(c)
            if c == "\\":
                fuera.append(linea[i + 1:i + 2]); i += 2; continue
            if c == q:
                q = None
        elif c in "\"'":
            q = c; fuera.append(c)
        elif linea.startswith("--", i):
            break
        else:
            fuera.append(c)
        i += 1
    return "".join(fuera)


def cerrar(texto, i):
    """i apunta al '(': devuelve el índice después del ')' que lo cierra (o len si no cierra en la línea)."""
    nivel = 0
    for j in range(i, len(texto)):
        if texto[j] == "(":
            nivel += 1
        elif texto[j] == ")":
            nivel -= 1
            if nivel == 0:
                return j + 1
    return len(texto)


def en_condicion(linea, i):
    """¿la posición i está en la condición de un if/elseif/while, fuera de paréntesis?"""
    m = COND.match(linea)
    if not m:
        return False
    cola = re.search(r"\b(then|do)\b",linea[m.end():])
    corte = m.end() + cola.start() if cola else len(linea)
    if i >= corte:
        return False
    nivel = 0
    for c in linea[m.end():i]:
        nivel += (c == "(") - (c == ")")
    return nivel == 0


def es_player(args):
    return args.strip().strip("()").strip() in ('"player"', "'player'")


def revisar_texto(texto, nombre="?"):
    hallazgos = []
    lineas = texto.splitlines()
    vigiladas = {}  # variable -> (línea donde se asignó, api)
    for n, cruda in enumerate(lineas, 1):
        if "secreto-ok" in cruda:
            continue
        linea = sin_comentario(cruda)
        if not linea.strip():
            continue
        # 1. uso directo
        for m in LLAMADA.finditer(linea):
            api = m.group(1)
            fin = cerrar(linea, m.end() - 1)
            if api in SOLO_OTRAS and es_player(linea[m.end() - 1:fin]):
                continue
            antes, despues = linea[:m.start()], linea[fin:]
            if OPS_DESPUES.match(despues) or OPS_ANTES.search(antes) or en_condicion(linea, m.start()):
                hallazgos.append((nombre, n, api, cruda.strip()))
        # 2b. usos de variables vigiladas
        for var, (desde, api) in list(vigiladas.items()):
            if n - desde > 40:
                del vigiladas[var]; continue
            if re.search(r"(?i)secret\w*\s*\(\s*" + re.escape(var) + r"\s*\)", linea):
                del vigiladas[var]; continue
            if re.match(r"^\s*(?:local\s+)?" + re.escape(var) + r"\s*=(?!=)", linea) and n != desde:
                del vigiladas[var]; continue
            if n == desde:
                continue
            for u in re.finditer(r"(?<![\w.:\"'])" + re.escape(var) + r"(?![\w(\[.:])", linea):
                antes, despues = linea[:u.start()], linea[u.end():]
                if OPS_DESPUES.match(despues) or OPS_ANTES.search(antes) or en_condicion(linea, u.start()):
                    hallazgos.append((nombre, n, api + " (vía " + var + ", línea " + str(desde) + ")", cruda.strip()))
                    break
        # 2a. asignación sin envoltorio: la llamada debe terminar la expresión
        a = ASIGNA.match(linea)
        if a:
            api = a.group(2)
            fin = cerrar(linea, a.end() - 1)
            if not (api in SOLO_OTRAS and es_player(linea[a.end() - 1:fin])) and not linea[fin:].strip(" ;"):
                for var in a.group(1).split(","):
                    var = var.strip()
                    if var and var != "_":
                        vigiladas[var] = (n, api)
    return hallazgos


def revisar(raiz, todo=False):
    hallazgos = []
    for carpeta in sorted(pathlib.Path(raiz).iterdir()):
        if not carpeta.is_dir() or not (todo or CARPETAS.match(carpeta.name)):
            continue
        for f in sorted(carpeta.rglob("*.lua")):
            hallazgos += revisar_texto(f.read_text(encoding="utf-8", errors="replace"), str(f.relative_to(raiz)))
    return hallazgos


def probar():
    ok = fallas = 0

    def check(c, msg):
        nonlocal ok, fallas
        if c: ok += 1
        else: fallas += 1; print("FALLA:", msg)
    malos = {
        "medidor 19-11": 'if M.pausa or UnitIsAFK("player") then return end',
        "cuenta": "local p = UnitHealth(u) / UnitHealthMax(u)",
        "or por defecto": "local v = UnitHealth(u) or 0",
        "comparación": "if UnitPower(u) > 10 then x() end",
        "not": "if not UnitIsDeadOrGhost(u) then x() end",
        "variable": 'local nombre, _, _, _, _, _, _, noInt = UnitCastingInfo(u)\nif noInt then x() end',
        "nombre de otro": "if UnitName(u) == objetivo then x() end",
        "dentro de un if con and": 'if guid and UnitIsDead("target") then x() end',
        "guarda y or": 'local xp = UnitXP and UnitXP("player") or 0',
    }
    buenos = {
        "envuelto": 'if M.pausa or Legible(UnitIsAFK("player")) then return end',
        "mostrar": "barra:SetValue(UnitHealth(u)); t:SetText(UnitName(u))",
        "nombre del jugador": 'local n = (UnitName("player") or "?")',
        "variable revisada": "local v = UnitHealth(u)\nif issecretvalue(v) then return end\nif v > 0 then x() end",
        "comentario": "-- if UnitIsAFK('player') then",
        "aceptado": "if UnitIsDead('player') then x() end -- secreto-ok: el propio jugador fuera de combate",
        "argumento": "if Num(UnitHealth(u)) > 0 then x() end",
        "guarda de existencia": 'local p = M.Num(UnitPower and UnitPower("player", 0))',
        "revisada con M.Secreto": "local q = UnitName(u)\nif M.Secreto(q) or not q then q = 'x' end",
    }
    for k, t in malos.items():
        check(revisar_texto(t), "no detecta: " + k)
    for k, t in buenos.items():
        h = revisar_texto(t)
        check(not h, "falso positivo: " + k + " " + str(h))
    print(f"{ok} OK, {fallas} fallas")
    return fallas


if __name__ == "__main__":
    if "--probar" in sys.argv:
        sys.exit(1 if probar() else 0)
    raiz = next((a for a in sys.argv[1:] if not a.startswith("--")), "addon")
    h = revisar(raiz, "--todo" in sys.argv)
    for nombre, n, api, texto in h:
        print(f"{nombre}:{n}: {api}: {texto[:140]}")
    print(f"{len(h)} usos de valores secretos sin revisar" if h else "0 usos de valores secretos sin revisar")
    print(f"{0 if not h else len(h)} fallas" if h else "OK, 0 fallas")
    sys.exit(1 if h else 0)
