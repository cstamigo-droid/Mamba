-- Tasador: agrega al cuadro de información de cada objeto qué hacer con él, cuánto vale y si es mejora.
-- Licencia: GPL-3.0.
local _, T = ...

local COLOR = {
	[T.ACCION.SUBASTA] = { 0.2, 1, 0.2 },
	[T.ACCION.VENDEDOR] = { 1, 0.82, 0 },
	[T.ACCION.GUARDAR] = { 0.4, 0.8, 1 },
	[T.ACCION.BOTAR] = { 0.6, 0.6, 0.6 },
	[T.ACCION.REVISAR] = { 1, 0.5, 0.2 },
}

-- datos = lo que entrega el cliente con el cuadro (sirve para saber si ya está ligado).
function T.AgregarLineas(tooltip, link, datos)
	local ligado = T.LigadoEnTextos(T.TextosDeDatos(datos))
	local info = T.InfoDe(link, ligado)
	if not info then return end
	local okM, mejoraTxt, esMejora = pcall(T.TextoMejora, info)
	if not okM then mejoraTxt, esMejora = nil, false end
	info.mejora = esMejora == true
	local r = T.Evaluar(info, T.Ajustes())
	local c = COLOR[r.accion] or { 1, 1, 1 }
	tooltip:AddLine(" ")
	tooltip:AddLine("Tasador: " .. r.accion, c[1], c[2], c[3])
	tooltip:AddLine(r.motivo, 0.85, 0.85, 0.85, true)
	local vend = (info.vendedor or 0) > 0 and T.Dinero(info.vendedor) or "no lo compra"
	local sub = info.subasta and T.Dinero(info.subasta) or "sin datos"
	tooltip:AddDoubleLine("Vendedor: " .. vend, "Subasta: " .. sub, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
	if r.nivel then
		local col = (r.nivel == "Caro" and "|cff00ff00") or (r.nivel == "Vale la pena" and "|cffffff00") or "|cffaaaaaa"
		tooltip:AddLine("Equipo: " .. col .. r.nivel .. "|r")
	end
	if r.aviso then tooltip:AddLine(r.aviso, 1, 0.5, 0.2, true) end
	if mejoraTxt then tooltip:AddLine(mejoraTxt, 1, 1, 1, true) end
	tooltip:Show()
end

local function LinkDe(tooltip, datos)
	if tooltip.GetItem then
		local ok, _, link = pcall(tooltip.GetItem, tooltip)
		link = ok and T.Leer(link)
		if type(link) == "string" then return link end
	end
	local id = type(datos) == "table" and T.Leer(datos.id)
	if type(id) == "number" then return "item:" .. id end
end

function T.InstalarTooltip()
	local function alMostrar(tooltip, datos)
		if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
		local link = LinkDe(tooltip, datos)
		if link then
			local ok, err = pcall(T.AgregarLineas, tooltip, link, datos)
			if not ok and T.db and T.db.depurar then T.Decir("error: " .. tostring(err)) end
		end
	end
	-- Forever usa el cliente moderno: TooltipDataProcessor. (OnTooltipSetItem ya no existe allí.)
	if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
		pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.Item, alMostrar)
	end
end
