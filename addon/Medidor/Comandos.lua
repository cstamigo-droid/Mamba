-- Medidor: comandos de chat. Licencia GPL-3.0-only.
local _, M = ...

local function Decir(t) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[Medidor]|r " .. t) end
M.Decir = Decir

local function Lista()
	local n = {}
	for a in pairs(M.ACTIVIDADES) do n[#n + 1] = a end
	table.sort(n)
	return table.concat(n, ", ")
end

local AYUDA = {
	"/medidor — lo medido en esta sesión",
	"/medidor todo — todo lo guardado de este personaje, por zona y actividad",
	"/medidor act <actividad> — qué estás haciendo: " .. Lista() .. " (en mazmorras y campos de batalla se elige sola)",
	"/medidor mejor — qué te deja más oro por hora de juego (zona y actividad con 5 min o más)",
	"/medidor pausa — detiene o reanuda el reloj",
	"/medidor borrar si — borra lo guardado de este personaje",
	"dinero = monedas que entraron menos las que salieron · botín = valor de lo que entró a tus bolsas sin vender todavía (precio de subasta tras comisión, o de vendedor) · total = dinero + botín",
}

local function Informe(cubos, titulo)
	local lista = M.Agrupar(cubos)
	if #lista == 0 then Decir(titulo .. ": nada medido todavía."); return end
	Decir(titulo .. ":")
	for _, c in ipairs(lista) do Decir(M.Linea(c)) end
end

local function Sin(t) return (t or ""):lower():gsub("^%s+", ""):gsub("%s+$", "") end

function M.Comando(msg)
	if not M.pj then Decir("todavía cargando."); return end
	local cmd, resto = Sin(msg):match("^(%S*)%s*(.-)$")
	if cmd == "" then
		Informe(M.sesion, "Esta sesión" .. (M.pausa and " (EN PAUSA)" or ""))
		local a = M.actual
		if a then Decir("Ahora: " .. a.zona .. " · " .. a.act .. " · nivel " .. a.nivel) end
	elseif cmd == "todo" then
		Informe(M.pj.cubos, "Total guardado")
	elseif cmd == "mejor" then
		local r = M.Ranking(M.pj.cubos)
		if #r == 0 then Decir("todavía no hay nada con 5 minutos o más."); return end
		Decir("Oro por hora de juego, de mayor a menor (dinero + botín; negativo = perdiste):")
		for i = 1, math.min(#r, 5) do
			local c = r[i]
			local linea = i .. ". " .. c.zona .. " · " .. c.act .. ": " .. M.Dinero(c.totalHora) .. "/h"
			if c.pasadas > 0 then
				linea = linea .. " · " .. M.Dinero((c.ganado - c.gastado + c.valor) / c.pasadas) .. " por pasada"
			end
			Decir(linea .. " (" .. math.floor(c.seg / 60) .. " min medidos)")
		end
	elseif cmd == "act" then
		if M.ACTIVIDADES[resto] then
			M.pj.act = resto
			M.ActualizarClave()
			Decir("actividad: " .. resto .. ".")
		else
			Decir("actividad desconocida. Usa una de: " .. Lista() .. ".")
		end
	elseif cmd == "pausa" then
		M.FijarReloj(M.pausa) -- revisor t9: lo mismo que el interruptor, también entre sesiones
		Decir(M.pausa and "reloj en pausa." or "reloj andando.")
	elseif cmd == "borrar" then
		if resto == "si" or resto == "sí" then
			M.pj.cubos, M.pj.precios, M.sesion = {}, {}, {}
			M.TomarBase()
			Decir("datos de este personaje borrados.")
		else
			Decir("para borrar escribe: /medidor borrar si")
		end
	else
		for _, l in ipairs(AYUDA) do Decir(l) end
	end
end

SLASH_MEDIDOR1 = "/medidor"
SlashCmdList.MEDIDOR = M.Comando

-- La sección «Medidor» de la ventana de Mamba lee los datos desde aquí.
_G.Medidor = M

-- El reloj, encendido o apagado: lo usan el interruptor de «Qué se muestra» y /medidor pausa, y queda guardado
-- (MedidorDB.apagado) para la próxima sesión.
function M.FijarReloj(encendido)
	M.pausa = not encendido
	MedidorDB = MedidorDB or {}
	MedidorDB.apagado = (not encendido) or nil
end

-- K124: interruptor en Ajustes › Mamba › Qué se muestra (registro: Asistente/Interruptores.lua).
local function publicar(spec)
	local api = _G.MambaAPI
	if type(api) == "table" and api.Interruptor then
		local ok, err = api.Interruptor(spec)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	else
		_G.MambaInterruptoresPendientes = _G.MambaInterruptoresPendientes or {}
		table.insert(_G.MambaInterruptoresPendientes, spec)
	end
end
publicar({ id = "medidor.reloj", addon = "Medidor", nombre = "Medir oro y experiencia por hora", grupo = "Oro",
	ayuda = "Cuenta, mientras juegas, cuánto oro y experiencia ganas por hora en cada actividad.",
	get = function() return not M.pausa end,
	set = function(v) M.FijarReloj(v) end })
