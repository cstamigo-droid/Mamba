-- Mamba_Panel: sus interruptores en Opciones (K124: todo se prende y se apaga desde Opciones, sin comandos).
--   panel.lineas        "Mamba en el panel de la guía"         el bloque «Mamba · tu plan» (K56)
--   panel.aviso.<tipo>  "Avisos: ya que estás aquí", "…"       cada tipo de aviso de oportunidad (K103), el mismo
--                                                              estado que «No avisar más de esto» del clic derecho
--   panel.misiones      "Lo que falta en Calabozos › Misiones"  el estado, lo que falta y «Guíame» (K100)
-- Cada uno se aplica en el momento, sin recargar. Licencia: GPL-3.0-only.
local _, N = ...

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

-- Calabozos › Misiones vuelve a pintarse si está a la vista.
local function repintarCalabozos()
	local P = _G.Polestar
	local DS = P and P.UI and P.UI.DungeonsSection
	if DS and DS.Render then pcall(DS.Render) end
end

publicar({ id = "panel.lineas", addon = "Mamba_Panel", nombre = "Mamba en el panel de la guía", grupo = "Ventanas y botones",
	ayuda = "Lo que recomienda tu plan, dentro del panel de la guía, con su cómo y su botón Llévame.",
	get = function() return not N.PJ().apagado end,
	set = function(v) N.PJ().apagado = (not v) or nil; N.Refrescar(true) end })

local AVISOS = {
	{ "lugar", "Avisos: ya que estás aquí", "Cuando estás donde se cumple algo de tu plan (un instructor, un vendedor)." },
	{ "subasta", "Avisos: qué vender en la subasta", "Con la subasta abierta, lo que conviene subastar y a cuánto, con Publicar." },
	{ "espacio", "Avisos: bolsas llenas", "Con las bolsas casi llenas, qué vender para hacer espacio." },
	{ "botin", "Avisos: botín útil", "Al saquear, un material que pide tu plan o que se vende caro." },
}
for _, a in ipairs(AVISOS) do
	local tipo = a[1]
	publicar({ id = "panel.aviso." .. tipo, addon = "Mamba_Panel", nombre = a[2], grupo = "Avisos", ayuda = a[3],
		get = function() return not N.Silenciado(tipo) end,
		set = function(v) N.Silenciar(tipo, not v); N.Refrescar(true) end })
end

publicar({ id = "panel.misiones", addon = "Mamba_Panel", nombre = "Lo que falta en Calabozos › Misiones", grupo = "Misiones",
	ayuda = "En cada misión de mazmorra: lo que falta, el estado de cada paso de la cadena y el botón Guíame.",
	get = function() return not N.PJ().sinMisiones end,
	set = function(v) N.PJ().sinMisiones = (not v) or nil; repintarCalabozos() end })
