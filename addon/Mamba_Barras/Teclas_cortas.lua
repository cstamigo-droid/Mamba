-- Mamba_Barras: teclas cortas en los botones ("c1" en vez de "CTRL-1", que no cabe: medido en el juego el
-- 18-11). LibActionButton pide LibKeyBound-1.0:ToShortKey para eso; Mamba no trae esa librería (su licencia
-- no está declarada), así que esta es una propia, mínima y con el mismo nombre: si otro addon carga la
-- LibKeyBound real (versión más alta), la real la reemplaza. Licencia: GPL-3.0-only.
local L = LibStub:NewLibrary("LibKeyBound-1.0", 1)
if not L then return end

local CORTO = {
	MOUSEWHEELUP = "RuA", MOUSEWHEELDOWN = "RuB", BUTTON3 = "R3", BUTTON4 = "R4", BUTTON5 = "R5",
	SPACE = "Esp", BACKSPACE = "Ret", ESCAPE = "Esc", ENTER = "Ent", INSERT = "Ins", DELETE = "Supr",
	HOME = "Ini", END = "Fin", PAGEUP = "RPg", PAGEDOWN = "AvPg", CAPSLOCK = "Mayús", TAB = "Tab",
	UP = "↑", DOWN = "↓", LEFT = "←", RIGHT = "→",
}

function L:ToShortKey(key)
	if type(key) ~= "string" or key == "" then return key end
	local t = key:upper()
	t = t:gsub("CTRL%-", "c"):gsub("SHIFT%-", "s"):gsub("ALT%-", "a"):gsub("META%-", "m")
	t = t:gsub("NUMPADPLUS", "N+"):gsub("NUMPADMINUS", "N-"):gsub("NUMPAD", "N")
	-- el nombre más largo primero ("MOUSEWHEELUP" antes que "UP")
	local claves = {}
	for largo in pairs(CORTO) do claves[#claves + 1] = largo end
	table.sort(claves, function(a, b) return #a > #b end)
	for _, largo in ipairs(claves) do
		if t:sub(-#largo) == largo then t = t:sub(1, #t - #largo) .. CORTO[largo]; break end
	end
	return t
end

-- LibActionButton llama a Set al pasar el ratón (modo de teclas de LibKeyBound); Mamba tiene su propio modo
-- "Asignar teclas", así que aquí no hace nada.
function L:Set() end
