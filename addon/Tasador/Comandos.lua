-- Tasador: arranque, ajustes guardados y comando /tasador (también /tas).
-- Licencia: GPL-3.0.
local _, T = ...

function T.Decir(texto)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffTasador|r " .. tostring(texto))
end

local ORDEN = { T.ACCION.SUBASTA, T.ACCION.REVISAR, T.ACCION.VENDEDOR, T.ACCION.GUARDAR, T.ACCION.BOTAR }

function T.Bolsas()
	local lista, sinCargar = T.LeerBolsas()
	local a = T.Ajustes()
	local grupos, totalVendedor, totalSubasta = {}, 0, 0
	for _, x in ipairs(lista) do
		local r = T.Evaluar(x.info, a)
		grupos[r.accion] = grupos[r.accion] or {}
		local valor = 0
		if r.accion == T.ACCION.SUBASTA then
			valor = (r.neto or 0) * x.cantidad
			totalSubasta = totalSubasta + valor
		elseif r.accion == T.ACCION.VENDEDOR then
			valor = (x.info.vendedor or 0) * x.cantidad
			totalVendedor = totalVendedor + valor
		end
		table.insert(grupos[r.accion], { x = x, valor = valor })
	end
	T.Decir("|cffffd100Tus bolsas|r")
	for _, accion in ipairs(ORDEN) do
		local g = grupos[accion]
		if g and #g > 0 then
			table.sort(g, function(p, q) return p.valor > q.valor end)
			T.Decir("|cffffffff" .. accion .. "|r (" .. #g .. "):")
			for i = 1, math.min(8, #g) do
				local e = g[i]
				local extra = e.valor > 0 and ("  " .. T.Dinero(e.valor)) or ""
				if e.x.info.duda then extra = extra .. "  |cffffd100(compáralo antes de vender)|r" end
				T.Decir("   " .. e.x.info.link .. (e.x.cantidad > 1 and (" x" .. e.x.cantidad) or "") .. extra)
			end
			if #g > 8 then T.Decir("   ... y " .. (#g - 8) .. " más") end
		end
	end
	T.Decir(string.format("Total: vendedor %s · subasta (neto) %s", T.Dinero(totalVendedor), T.Dinero(totalSubasta)))
	if sinCargar > 0 then T.Decir("(" .. sinCargar .. " objetos aún cargando: repite /tasador en unos segundos)") end
end

local AYUDA = {
	"/tasador  › qué hacer con cada cosa de tus bolsas y cuánto vale",
	"/tasador escanear  › escanea la subasta (con la casa de subastas abierta; igual que el botón)",
	"/tasador baratos  › materiales que hoy están más baratos que de costumbre",
	"/tasador hierbas  › hierbas que más pagan hoy (para farmear)",
	"/tasador rol sanacion | equilibrio | feral | auto  › para comparar equipo",
	"/tasador alerta si | no  › aviso de enemigos cerca",
	"/tasador comision 5  › comisión de la subasta en % (5 por defecto, NO VERIFICADO)",
	"/tasador op  › ventana de oportunidades: revender, vender al PNJ, qué vender tuyo y qué fabricar",
	"/tasador reventa  › comprar barato para revender (con margen, ventas medidas y depósito)",
	"/tasador pnj  › subastas más baratas que lo que paga el vendedor",
	"/tasador vender  › a cuánto vender lo de tus bolsas y si es momento (\"vende ya\" o \"espera\")",
	"/tasador fabricar  › qué recetas tuyas dejan ganancia hoy (abre antes tu ventana de profesión)",
	"/tasador eventos  › mide si las bandas del 9-12 mueven hierbas y consumibles",
	"/tasador deposito 15  › depósito en % de lo que paga el vendedor (supuesto, NO VERIFICADO)",
	"/tasador duracion 24  › horas de tus publicaciones (las que te ofrezca la subasta: 2, 8, 12, 24, 48...)",
	"Pasa el ratón sobre cualquier objeto para ver su tasación y si es mejora.",
	"Precios de subasta: aprieta \"Escanear (Tasador)\" en la casa de subastas (o usa Auctionator si lo tienes).",
}

local function Comando(msg)
	-- Quitar tildes ANTES de pasar a minúsculas: lower() puede estropear las letras con tilde según el idioma del PC.
	msg = (msg or ""):gsub("\195[\179\147]", "o"):gsub("\195[\173\141]", "i") -- ó Ó -> o, í Í -> i
	msg = msg:lower():gsub("^%s+", ""):gsub("%s+$", "")
	local cmd, arg = msg:match("^(%S*)%s*(.*)$")
	T.db.ajustes = T.db.ajustes or {}
	if cmd == "" then
		T.Bolsas()
	elseif cmd == "escanear" or cmd == "scan" then
		T.Escanear() -- lo mismo que el botón, por si el botón no aparece
	elseif cmd == "diag" then
		T.Diagnostico(true)
	elseif cmd == "baratos" then
		T.MostrarBaratos()
	elseif cmd == "hierbas" then
		T.MostrarHierbas()
	elseif cmd == "rol" and (arg == "sanacion" or arg == "equilibrio" or arg == "feral" or arg == "auto") then
		T.db.ajustes.rol = arg
		local okR, rol, fuente = pcall(T.RolActual)
		if not okR then rol, fuente = arg, "no pude leer tus talentos" end
		T.Decir("Comparo equipo para: " .. (T.ROL_NOMBRE[rol] or rol) .. (arg == "auto" and (" (automático: " .. fuente .. ")") or ""))
	elseif cmd == "alerta" and (arg == "si" or arg == "no") then
		T.db.ajustes.alerta = (arg == "si")
		T.Decir("Alerta de enemigos: " .. (arg == "si" and "encendida" or "apagada"))
	elseif cmd == "op" or cmd == "oportunidades" then
		T.AbrirOportunidades()
	elseif cmd == "reventa" then
		T.MostrarReventa("reventa")
	elseif cmd == "pnj" or cmd == "vendedor" then
		T.MostrarReventa("vendedor")
	elseif cmd == "vender" then
		T.MostrarVender()
	elseif cmd == "fabricar" then
		T.MostrarFabricar()
	elseif cmd == "eventos" then
		T.MostrarEventos()
	elseif cmd == "deposito" and tonumber(arg) and tonumber(arg) >= 0 and tonumber(arg) <= 100 then
		T.db.ajustes.depositoPct = tonumber(arg) / 100
		T.Decir("Depósito supuesto: " .. tonumber(arg) .. "% de lo que paga el vendedor (si la subasta del juego lo calcula, uso el suyo).")
	elseif cmd == "duracion" and tonumber(arg) and tonumber(arg) >= 1 and tonumber(arg) <= 72 then
		T.db.ajustes.horasPublicacion = tonumber(arg)
		T.Decir("Tus publicaciones duran " .. tonumber(arg) .. " horas.")
	elseif cmd == "comision" and tonumber(arg) then
		local p = tonumber(arg)
		if p >= 0 and p <= 50 then
			T.db.ajustes.comision = p / 100
			T.Decir("Comisión de subasta: " .. p .. "%")
		end
	else
		for _, l in ipairs(AYUDA) do T.Decir(l) end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, _, nombre)
	if nombre ~= "Tasador" then return end
	TasadorDB = TasadorDB or {}
	TasadorDB.ajustes = TasadorDB.ajustes or {}
	T.db = TasadorDB
	T.InstalarTooltip()
	SLASH_TASADOR1, SLASH_TASADOR2 = "/tasador", "/tas"
	SlashCmdList.TASADOR = Comando
	if not Auctionator then
		T.Decir("Sin Auctionator: uso mi propio escaneo. Aprieta \"Escanear (Tasador)\" en la casa de subastas.")
	end
	self:UnregisterEvent("ADDON_LOADED")
end)
