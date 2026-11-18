-- Tasador: reglas de tasación (sin llamadas al juego, para poder probarlas fuera de WoW).
-- Licencia: GPL-3.0 (ver LICENSE).
local _, T = ...
T = T or {}
Tasador = T

-- Ajustes por defecto. El jugador puede cambiarlos con /tasador.
T.DEFAULTS = {
	comision = 0.05,      -- comisión de la casa de subastas (5 %: NO VERIFICADO en Forever, por eso es ajustable)
	margen = 1.5,         -- la subasta neta tiene que pagar al menos 1,5 veces lo del vendedor
	minimoCobre = 2000,   -- y al menos 20 de plata más POR MONTÓN (por el tiempo y el depósito)
	diasViejo = 7,        -- un precio de subasta de más de 7 días se marca como viejo
	-- Comerciante (Comercio.lua). Lo marcado NO VERIFICADO es un supuesto ajustable, no un dato de Forever.
	depositoPct = 0.15,   -- depósito = 15 % de lo que paga el vendedor por unidad y por 12 h (MODELO, NO VERIFICADO)
	depositoMin = 100,    -- mínimo por publicación: 1 plata (ORO.md: Timesaver, hasta el 17-11; el cambio a 1 cobre
	                      -- que anunció Warcraft Tavern se postergó al 17-11 según Blizzard: revisar en el juego)
	horasPublicacion = 24, -- duración de la publicación que usas (NO VERIFICADO cuáles ofrece Forever)
	minVentasDia = 5,     -- reventa: solo si se venden al menos 5 unidades al día
	minMargen = 0.10,     -- reventa: margen neto mínimo 10 % (para no confundir ruido con ventaja)
	minGanancia = 10000,  -- reventa: ganancia neta mínima 1 oro por operación
	minVendedor = 100,    -- reventa al vendedor: ganancia mínima 1 plata
	probMin = 0.2,        -- reventa: probabilidad mínima de vender en una publicación
	maxDiasVender = 2,    -- reventa: no comprar lo que tardaría más de 2 días en venderse
	riesgoDia = 0.08,     -- reventa: se descuenta 8 % por día de espera (SUPUESTO; ORO.md: caídas de 50 % en una semana ≈ 7-10 %/día)
	edadFotoMax = 3600,   -- comprar: el escaneo tiene que ser de hace 60 min o menos
	edadFotoVenta = 21600, -- vender: el escaneo tiene que ser de hace 6 h o menos
}

-- Tipos del juego (Enum.ItemClass / bindType). Copiados como números por si el cliente no trae Enum.
T.CLASE_REACTIVO, T.CLASE_ARMA, T.CLASE_ARMADURA, T.CLASE_COMERCIO, T.CLASE_MISION = 5, 2, 4, 7, 12
T.LIGA_RECOGER, T.LIGA_EQUIPAR, T.LIGA_MISION = 1, 2, 4

T.ACCION = {
	VENDEDOR = "Vender al vendedor",
	SUBASTA = "Subastar",
	GUARDAR = "Guardar",
	BOTAR = "Sin valor: puedes botarlo",
	REVISAR = "Revisa la subasta",
}

-- Convierte cobre a texto "1o 23p 45c".
function T.Dinero(cobre)
	cobre = math.floor((cobre or 0) + 0.5)
	if cobre <= 0 then return "0c" end
	local o = math.floor(cobre / 10000)
	local p = math.floor((cobre % 10000) / 100)
	local c = cobre % 100
	local partes = {}
	if o > 0 then partes[#partes + 1] = o .. "o" end
	if p > 0 then partes[#partes + 1] = p .. "p" end
	if c > 0 then partes[#partes + 1] = c .. "c" end
	return table.concat(partes, " ")
end

local function EsEquipo(info)
	return info.clase == T.CLASE_ARMA or info.clase == T.CLASE_ARMADURA
end

-- Material de profesión: lo que el juego marca como reactivo de fabricación, más las clases
-- "Reactivo" (5) y "Objetos comerciables" (7), porque no todos los clientes marcan el reactivo.
function T.EsMaterial(info)
	return info.reactivo == true or info.clase == T.CLASE_REACTIVO or info.clase == T.CLASE_COMERCIO
end

-- ¿Qué tan caro es un equipo? Compara la subasta neta con lo que paga el vendedor.
function T.NivelPrecio(neto, vendedor)
	if not neto or neto <= 0 then return nil end
	if not vendedor or vendedor <= 0 then return "Caro" end
	local veces = neto / vendedor
	if veces >= 10 then return "Caro" end
	if veces >= 3 then return "Vale la pena" end
	return "Barato"
end

-- info = {
--   calidad (0 gris .. 4 épico), clase, liga (bindType), vendedor (cobre por unidad),
--   subasta (cobre por unidad o nil), diasSubasta (o nil), reactivo (true/false),
--   esMision (true/false), pila (tamaño máximo del montón, 1 si no se apila),
--   ligado (true si ESTE objeto ya está ligado a ti), herramienta (true/false),
--   mejora (true si es mejora para ti), avisoPrecio (texto o nil)
-- }
-- Devuelve { accion, motivo, neto, nivel, aviso }
function T.Evaluar(info, ajustes)
	ajustes = ajustes or T.DEFAULTS
	local vendedor = info.vendedor or 0
	local r = { neto = nil, nivel = nil, aviso = nil }

	if info.esMision or info.clase == T.CLASE_MISION or info.liga == T.LIGA_MISION then
		r.accion, r.motivo = T.ACCION.GUARDAR, "Objeto de misión: no lo botes."
		return r
	end

	if info.herramienta then
		r.accion, r.motivo = T.ACCION.GUARDAR, "Herramienta de profesión: la necesitas para trabajar."
		return r
	end

	if info.mejora then
		r.accion, r.motivo = T.ACCION.GUARDAR, "Es mejora para ti: no lo vendas."
		if info.subasta and info.subasta > 0 and info.liga ~= T.LIGA_RECOGER and not info.ligado then
			r.motivo = r.motivo .. " (Si prefieres el oro, en subasta te quedarían " .. T.Dinero(info.subasta * (1 - ajustes.comision)) .. ".)"
		end
		return r
	end

	if info.calidad == 0 then
		if vendedor > 0 then
			r.accion, r.motivo = T.ACCION.VENDEDOR, "Objeto gris: solo sirve para venderlo."
		else
			r.accion, r.motivo = T.ACCION.BOTAR, "Gris y el vendedor no paga nada."
		end
		return r
	end

	local material = T.EsMaterial(info)
	local subastable = info.liga ~= T.LIGA_RECOGER and not info.ligado
	if not subastable then
		if vendedor > 0 then
			r.accion, r.motivo = T.ACCION.VENDEDOR, "Ya está ligado a ti: no se puede subastar."
		elseif material then
			r.accion, r.motivo = T.ACCION.GUARDAR, "Ligado y sin precio, pero es material de profesión."
		else
			-- Nunca "botar" algo ligado que no sea gris: puede ser la Piedra de hogar, una llave o una herramienta.
			r.accion, r.motivo = T.ACCION.GUARDAR, "Ligado y el vendedor no lo compra: probablemente es importante (llave, herramienta, piedra de hogar)."
		end
		return r
	end

	r.aviso = info.avisoPrecio
	if info.subasta and info.subasta > 0 then
		local neto = info.subasta * (1 - ajustes.comision)
		r.neto = neto
		if info.diasSubasta and info.diasSubasta > ajustes.diasViejo then
			r.aviso = "Precio de subasta de hace " .. info.diasSubasta .. " días: puede haber cambiado."
		end
		if EsEquipo(info) then
			r.nivel = T.NivelPrecio(neto, vendedor)
		end
		-- La ganancia mínima se mide por MONTÓN: 1 plata más por unidad en un montón de 20 sí compensa.
		-- En las bolsas se cuenta lo que TIENES (si tienes 2 de un montón de 20, la ganancia es por 2).
		local pila = math.max(1, tonumber(info.pila) or 1)
		if tonumber(info.cantidad) then pila = math.max(1, math.min(pila, tonumber(info.cantidad))) end
		if neto >= vendedor * ajustes.margen and (neto - vendedor) * pila >= ajustes.minimoCobre then
			r.accion = T.ACCION.SUBASTA
			r.motivo = "En subasta te quedan " .. T.Dinero(neto) .. " (el vendedor da " .. T.Dinero(vendedor) .. ")."
		elseif vendedor > 0 then
			r.accion = T.ACCION.VENDEDOR
			if neto < vendedor then
				r.motivo = "El vendedor paga más (" .. T.Dinero(vendedor) .. " contra " .. T.Dinero(neto) .. " en subasta)."
			else
				r.motivo = "La subasta no compensa: diferencia de " .. T.Dinero(neto - vendedor) .. "."
			end
		elseif neto * pila >= ajustes.minimoCobre then
			r.accion = T.ACCION.SUBASTA
			r.motivo = "El vendedor no lo compra; en subasta te quedan " .. T.Dinero(neto) .. "."
		else
			r.accion = T.ACCION.REVISAR
			r.motivo = "El vendedor no lo compra y la subasta deja muy poco (" .. T.Dinero(neto) .. ")."
		end
		if material and r.accion ~= T.ACCION.SUBASTA and neto >= vendedor then
			r.accion, r.motivo = T.ACCION.GUARDAR, "Material de profesión y la subasta no paga mucho: úsalo."
		end
		return r
	end

	-- Sin precio de subasta conocido.
	if EsEquipo(info) and (info.calidad or 0) >= 2 then
		r.accion = T.ACCION.REVISAR
		r.motivo = "Equipo verde o mejor que se puede subastar: busca su precio en la casa de subastas antes de venderlo."
	elseif material then
		r.accion = T.ACCION.GUARDAR
		r.motivo = "Material de profesión sin precio conocido: guárdalo o revisa la subasta."
	elseif vendedor > 0 then
		r.accion, r.motivo = T.ACCION.VENDEDOR, "Sin precio de subasta conocido."
	else
		r.accion, r.motivo = T.ACCION.REVISAR, "El vendedor no lo compra y no hay precio de subasta."
	end
	return r
end
