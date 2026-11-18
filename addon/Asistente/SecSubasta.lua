-- Asistente/SecSubasta.lua: la sección «Subasta» del hub (el Tasador con todas sus vistas), el menú del objeto
-- (Alt + clic derecho sobre un objeto de las bolsas, o clic derecho en una fila) y los interruptores de vender la
-- basura sola y reparar solo. Las vistas leen los datos del Tasador (T.Analizar, T.ConsejosBolsas, T.Recorrer,
-- T.ConsejosFabricar): nada pasa por el chat y nunca se reemplaza Tasador.Decir.
-- Mamba solo SUGIERE: publicar en la subasta o vender al vendedor lo hace un botón aparte, que solo funciona con
-- el subastador o el vendedor abiertos, y el último clic en la subasta es tuyo.
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = A.Hub
local format, floor = string.format, math.floor

local CLAVE = "MambaSubasta"
local function T() local t = _G.Tasador; return type(t) == "table" and t or nil end

local abierto = { subasta = false, vendedor = false }
local ev = CreateFrame("Frame")
for _, e in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "MERCHANT_SHOW", "MERCHANT_CLOSED", "BAG_UPDATE_DELAYED" }) do pcall(ev.RegisterEvent, ev, e) end

---------------------------------------------------------------- qué hacer con cada objeto
local SUG = { subastar = "Subastar", vendedor = "Al vendedor", guardar = "Guardar", basura = "Basura" }
local SUGCOL = { subastar = "|cffc7adff", vendedor = "|cff94c9ff", guardar = "|cff6bd999", basura = "|cff9d9d9d" }

local function db()
	A.PrepararDB()
	AsistenteDB.objetos = AsistenteDB.objetos or {}
	return AsistenteDB.objetos
end

local function deAccion(t, accion)
	local AC = t.ACCION
	if accion == AC.VENDEDOR then return "vendedor" end
	if accion == AC.SUBASTA or accion == AC.REVISAR then return "subastar" end
	if accion == AC.BOTAR then return "basura" end
	return "guardar"
end

-- Las bolsas, una fila por objeto: { id, link, cantidad, calidad, vendedor, sug, motivo, elegido, precio }
local bolsasCache
local function bolsas()
	local t = T()
	if not t then return {} end
	if bolsasCache then return bolsasCache end
	local a = t.AjustesComercio and t.AjustesComercio() or t.Ajustes()
	local lista = t.LeerBolsas()
	local por, orden = {}, {}
	for _, x in ipairs(lista) do
		local id = t.ItemID(x.info.link)
		if id then
			local o = por[id]
			if not o then
				local ok, r = pcall(t.Evaluar, x.info, a)
				o = { id = id, link = x.info.link, cantidad = 0, calidad = x.info.calidad or 1, vendedor = x.info.vendedor or 0,
					sug = ok and r and deAccion(t, r.accion) or "guardar", motivo = ok and r and r.motivo or "" }
				por[id] = o
				orden[#orden + 1] = o
			end
			o.cantidad = o.cantidad + (x.cantidad or 1)
		end
	end
	local okC, consejos = pcall(t.ConsejosBolsas)
	if okC and type(consejos) == "table" then
		for _, c in ipairs(consejos) do
			local o = por[c.id]
			if o and c.c then o.precio, o.consejo = c.c.precio, c.c.accion end
		end
	end
	local marcas = db()
	for _, o in ipairs(orden) do o.elegido = marcas[o.id] end
	table.sort(orden, function(p, q)
		local vp = (p.precio or p.vendedor or 0) * p.cantidad
		local vq = (q.precio or q.vendedor or 0) * q.cantidad
		if vp ~= vq then return vp > vq end
		return p.id < q.id
	end)
	bolsasCache = orden
	return orden
end
A.BolsasMamba = bolsas

local function decision(o) return o.elegido or o.sug end

-- dónde está un objeto en las bolsas: lista de { bolsa, ranura }
local function ubicar(id)
	local out, C = {}, C_Container
	if not (C and C.GetContainerNumSlots and C.GetContainerItemID) then return out end
	for b = 0, 4 do
		for s = 1, (C.GetContainerNumSlots(b) or 0) do
			if C.GetContainerItemID(b, s) == id then out[#out + 1] = { b, s } end
		end
	end
	return out
end

---------------------------------------------------------------- las acciones (botón aparte, con la ventana del juego abierta)
local function venderAlVendedor(id)
	if not abierto.vendedor then return false, "Habla con un vendedor primero." end
	local C = C_Container
	for _, u in ipairs(ubicar(id)) do pcall(C.UseContainerItem, u[1], u[2]) end
	return true
end

-- Pone el objeto en la pestaña Vender de la subasta con el precio ya puesto. Publicar lo aprietas tú.
local function ponerEnSubasta(id, precio)
	if not abierto.subasta then return false, "Habla con el subastador primero." end
	local u = ubicar(id)[1]
	if not u then return false, "Ya no está en tus bolsas." end
	local H = _G.AuctionHouseFrame
	if H and ItemLocation and ItemLocation.CreateFromBagAndSlot then
		local loc = ItemLocation:CreateFromBagAndSlot(u[1], u[2])
		local commodity = C_AuctionHouse and C_AuctionHouse.GetItemCommodityStatus and C_AuctionHouse.GetItemCommodityStatus(loc) == 2
		if H.SetDisplayMode and AuctionHouseFrameDisplayMode then
			pcall(H.SetDisplayMode, H, commodity and AuctionHouseFrameDisplayMode.CommoditiesSell or AuctionHouseFrameDisplayMode.ItemSell)
		end
		local f = commodity and H.CommoditiesSellFrame or H.ItemSellFrame
		if f and f.SetItem then pcall(f.SetItem, f, loc) end
		if precio and f and f.PriceInput and f.PriceInput.SetAmount then pcall(f.PriceInput.SetAmount, f.PriceInput, precio) end
		return true
	end
	local AF = _G.AuctionFrame
	if AF and C_Container and C_Container.PickupContainerItem and ClickAuctionSellItemButton then
		if AuctionFrameTab3 and AuctionFrameTab3.Click then pcall(AuctionFrameTab3.Click, AuctionFrameTab3) end
		pcall(C_Container.PickupContainerItem, u[1], u[2])
		pcall(ClickAuctionSellItemButton)
		if ClearCursor then ClearCursor() end
		if precio and StartPrice and MoneyInputFrame_SetCopper then
			pcall(MoneyInputFrame_SetCopper, StartPrice, precio)
			if BuyoutPrice then pcall(MoneyInputFrame_SetCopper, BuyoutPrice, precio) end
		end
		return true
	end
	return false, "No encontré la ventana de la subasta."
end

local aviso -- lo último que pasó con un botón, para mostrarlo arriba de la lista
local function marcar(id, que)
	local m = db()
	m[id] = que
	bolsasCache = nil
	Hub.Redibujar()
end

-- El menú del objeto (Alt + clic derecho en la bolsa, o clic derecho en una fila de «Vender lo mío»).
function A.MenuObjeto(anchor, id)
	local P = _G.Polestar
	local W = P and P.Widgets
	if not (W and W.ShowMenu) then return end
	bolsasCache = nil
	local o
	for _, x in ipairs(bolsas()) do if x.id == id then o = x end end
	if not o then return end
	local items = {
		{ text = (o.link or "?") .. "   |cff9ba2b9Mamba sugiere:|r " .. SUGCOL[o.sug] .. SUG[o.sug] .. "|r", disabled = true },
		{ text = "|cff9ba2b9Tú eliges qué hacer con él:|r", disabled = true },
	}
	for _, k in ipairs({ "subastar", "vendedor", "guardar", "basura" }) do
		local txt = ({ subastar = "Subastar" .. (o.precio and (" · " .. A.Monedas(o.precio)) or ""),
			vendedor = "Al vendedor" .. (o.vendedor > 0 and (" · " .. A.Monedas(o.vendedor * o.cantidad)) or " · no lo compra"),
			guardar = "Guardar (no venderlo nunca)", basura = "Marcar como basura" })[k]
		items[#items + 1] = { text = txt, checked = o.elegido == k, onClick = function() marcar(id, k) end }
	end
	if o.elegido then items[#items + 1] = { text = "Volver a lo que sugiere Mamba", onClick = function() marcar(id, nil) end } end
	if abierto.subasta then items[#items + 1] = { text = "|cffe6ba66Poner en la subasta ahora|r", onClick = function() aviso = select(2, ponerEnSubasta(id, o.precio)) end } end
	if abierto.vendedor and o.vendedor > 0 then items[#items + 1] = { text = "|cffe6ba66Venderlo ahora|r", onClick = function() aviso = select(2, venderAlVendedor(id)) end } end
	pcall(W.ShowMenu, anchor, items, { point = "TOPLEFT", relPoint = "BOTTOMRIGHT", minWidth = 280 })
end

-- Alt + clic derecho sobre un objeto de las bolsas (las del juego, Bagnon o cualquiera: se lee el cuadro del objeto).
local function altClic(_, boton)
	if boton ~= "RightButton" or not (IsAltKeyDown and IsAltKeyDown()) then return end
	local tip = GameTooltip
	if not (tip and tip:IsShown() and tip.GetItem) then return end
	local _, link = tip:GetItem()
	local id = link and tonumber(link:match("item:(%d+)"))
	if not id or #ubicar(id) == 0 then return end
	local owner = tip:GetOwner() or UIParent
	A.MenuObjeto(owner, id)
end
pcall(ev.RegisterEvent, ev, "GLOBAL_MOUSE_DOWN")

---------------------------------------------------------------- análisis del Tasador (con número de pedido)
local pedidos, datos = 0, {}
local function pedir(vista)
	local t = T()
	if not t then return end
	pedidos = pedidos + 1
	local n = pedidos
	datos[vista] = { cargando = true, n = n }
	local function listo(lista, err)
		if not datos[vista] or datos[vista].n ~= n then return end -- una respuesta vieja: se descarta
		datos[vista] = { lista = lista, err = err, n = n, hora = time() }
		Hub.Redibujar()
	end
	if vista == "oport" or vista == "reventa" or vista == "pnj" then
		local ok, e = pcall(t.Analizar, function(lista, err) listo(lista, err) end)
		if not ok then listo(nil, tostring(e)) end
	elseif vista == "baratos" then
		local ok, e = pcall(t.Recorrer, function(clase) return clase == 7 or clase == 5 end, true, listo)
		if not ok then listo(nil, tostring(e)) end
	elseif vista == "hierbas" then
		local ok, e = pcall(t.Recorrer, function(clase, sub) return clase == 7 and sub == 9 end, false, listo)
		if not ok then listo(nil, tostring(e)) end
	end
end

local function dato(vista)
	local d = datos[vista]
	if vista == "reventa" or vista == "pnj" then d = datos.oport or d; vista = "oport" end
	if not d then pedir(vista); d = datos[vista] end
	return d
end

---------------------------------------------------------------- dibujo
local function sinEscaneo(V, t)
	local edad = t.EdadFoto and t.EdadFoto()
	if edad then return false end
	V:Vacio("Sin datos aún", "Todavía no hay precios de la subasta. Habla con un subastador y aprieta «Escanear (Tasador)», abajo a la derecha de su ventana.",
		abierto.subasta and { "Escanear ahora", function() t.Escanear() end } or nil)
	return true
end

local function cabeceraEscaneo(V, t)
	local edad = t.EdadFoto and t.EdadFoto()
	local txt = edad and ("Precios del escaneo de hace " .. t.Horas(edad) .. ".") or "Sin escaneo todavía."
	local bot = {}
	if abierto.subasta then bot[#bot + 1] = { "Escanear ahora", function() t.Escanear() end } end
	bot[#bot + 1] = { "Volver a calcular", function() datos = {}; bolsasCache = nil end }
	V:Botones(bot, txt)
end

local function filasOport(V, t, lista, tipo, max)
	local n = 0
	V:Columnas({ { "Objeto", 300 }, { "Comprar", 170 }, { "Vender", 160 }, { "Ganas", 200 } })
	for _, o in ipairs(lista or {}) do
		if (not tipo or o.tipo == tipo) and n < (max or 30) then
			n = n + 1
			local id = tonumber(tostring(o.link):match("item:(%d+)"))
			V:Fila({ icono = id, item = o.link, celdas = {
				{ tostring(o.link):gsub("[%[%]]", ""), o.tipo == "vendedor" and "subasta → vendedor" or "comprar para revender" },
				{ o.unidades .. " a " .. A.Monedas(o.comprarHasta), "o menos, cada uno" },
				{ A.Monedas(o.venta), o.tipo == "vendedor" and "lo paga el vendedor" or (floor(o.ventasDia or 0) .. " se venden al día") },
				{ "|cff6bd999+" .. A.Monedas(o.ganancia) .. "|r", o.pct and A.Pct(o.pct * 100, 0) or "" },
			}, tipExtra = t.DetalleOportunidad and t.DetalleOportunidad(o) or nil })
		end
	end
	if n == 0 then V:Vacio("Nada por ahora", "Ninguna compra cumple todas las condiciones: margen, ventas medidas y un precio que no venga bajando. Es normal; vuelve después de otro escaneo.") end
end

local function vistaAsync(V, t, vista, fn)
	if sinEscaneo(V, t) then return end
	cabeceraEscaneo(V, t)
	local d = dato(vista)
	if d.cargando then V:Vacio("Calculando…", "El Tasador está revisando todos los precios. Tarda unos segundos.") return end
	if not d.lista then V:Vacio("Sin datos aún", tostring(d.err or "No pude calcular.")) return end
	fn(d.lista, d.err)
end

local function vistaVender(est, V, t)
	local lista = bolsas()
	V:Interruptor("Vender la basura sola al abrir un vendedor", _G.Polestar and _G.Polestar.Get and _G.Polestar.Get("qol.sellJunk"),
		function(v) if _G.Polestar and _G.Polestar.Set then _G.Polestar.Set("qol.sellJunk", v) end end)
	V:Interruptor("Reparar solo al abrir un vendedor", _G.Polestar and _G.Polestar.Get and _G.Polestar.Get("qol.autoRepair"),
		function(v) if _G.Polestar and _G.Polestar.Set then _G.Polestar.Set("qol.autoRepair", v) end end)
	local basura = 0
	for _, o in ipairs(lista) do if decision(o) == "basura" then basura = basura + o.vendedor * o.cantidad end end
	V:Nota("Basura en tus bolsas: " .. A.Monedas(basura) .. " · Alt + clic derecho sobre un objeto de tus bolsas (o clic derecho en una fila) abre su menú.")
	if aviso then V:Nota("|cfffabf4d" .. aviso .. "|r"); aviso = nil end
	local sel
	for _, o in ipairs(lista) do if o.id == est.sel then sel = o end end
	V:Botones({
		{ "Poner en la subasta", function() if sel then aviso = select(2, ponerEnSubasta(sel.id, sel.precio)) end end, apagado = not (abierto.subasta and sel) },
		{ "Vender al vendedor", function() if sel then aviso = select(2, venderAlVendedor(sel.id)) end end, apagado = not (abierto.vendedor and sel and sel.vendedor > 0) },
	}, sel and ("Elegido: " .. tostring(sel.link)) or "Elige un objeto de la lista. Los botones se activan al hablar con el subastador o con un vendedor; el último clic es tuyo.")
	V:Columnas({ { "Objeto", 270 }, { "Vendedor (total)", 150 }, { "Subasta (total)", 150 }, { "Mamba sugiere, y por qué", 270 } })
	local n = 0
	for _, o in ipairs(lista) do
		local d = decision(o)
		if not est.filtro or est.filtro == "todo" or est.filtro == d then
			n = n + 1
			local vend = o.vendedor > 0 and A.Monedas(o.vendedor * o.cantidad) or "|cff9ba2b9no lo compra|r"
			local sub = o.precio and A.Monedas(o.precio * o.cantidad) or "|cff9ba2b9sin datos aún|r"
			local etiqueta = o.elegido and (SUGCOL[d] .. SUG[d] .. "|r |cff9ba2b9(elegiste tú)|r") or (SUGCOL[d] .. SUG[d] .. "|r")
			V:Fila({ icono = o.id, item = o.link, celdas = {
				{ (est.sel == o.id and "› " or "") .. tostring(o.link):gsub("[%[%]]", ""), "× " .. o.cantidad },
				{ vend, (o.cantidad > 1 and o.vendedor > 0) and ("cada uno " .. A.Monedas(o.vendedor)) or "" },
				{ sub, (o.cantidad > 1 and o.precio) and ("cada uno " .. A.Monedas(o.precio)) or "" },
				{ etiqueta, o.elegido and "" or o.motivo },
			}, clic = function() est.sel = o.id end, derecho = function(self) A.MenuObjeto(self, o.id) end })
		end
	end
	if n == 0 then V:Vacio("Sin resultados", "No hay objetos con este filtro en tus bolsas.", { "Ver todo", function() est.filtro = "todo" end }) end
end

local function vistaFabricar(V, t)
	local ok, lista = pcall(t.ConsejosFabricar)
	if not ok or not lista then
		V:Vacio("No conozco tus recetas", "Abre una vez la ventana de tu profesión (Alquimia, Cocina, Primeros auxilios…) y vuelve aquí.")
		return
	end
	if sinEscaneo(V, t) then return end
	cabeceraEscaneo(V, t)
	V:Columnas({ { "Receta", 300 }, { "Materiales", 170 }, { "Vendes", 160 }, { "Ganas", 200 } })
	for _, f in ipairs(lista) do
		local link = t.InfoComercio and t.InfoComercio(f.producto)
		local nombre = link and link.link or ("objeto " .. f.producto)
		local gan = f.ganancia and ((f.ganancia >= 0 and "|cff6bd999+" or "|cfff57373-") .. A.Monedas(math.abs(f.ganancia)) .. "|r") or "|cff9ba2b9sin datos aún|r"
		local nota = f.noSeVende and "casi no se vende: no lo fabriques para vender" or (f.falta and "falta el precio de un material: escanea" or (f.prof or ""))
		V:Fila({ icono = f.producto, item = f.producto, celdas = {
			{ tostring(nombre):gsub("[%[%]]", "") .. ((f.n or 1) > 1 and (" × " .. f.n) or ""), nota },
			{ f.costo and A.Monedas(f.costo) or "—" }, { f.venta and A.Monedas(f.venta) or "—" },
			{ gan, f.pct and A.Pct(f.pct * 100, 0) or "" } } })
	end
	V:Nota("Ganancia: lo que cobras tras la comisión y el depósito que puedes perder, menos lo que valen los materiales en la subasta. Si es negativa, vende los materiales.")
end

local function vistaHistorial(V, t, lista, baratos)
	V:Columnas({ { "Objeto", 300 }, { baratos and "Hoy" or "Precio de hoy", 170 }, { baratos and "Su media" or "Te quedan por 20", 170 }, { baratos and "Más barato" or "A la venta", 190 } })
	if baratos then table.sort(lista, function(a, b) return (a.h.hoy / a.h.media) < (b.h.hoy / b.h.media) end)
	else table.sort(lista, function(a, b) return a.h.hoy > b.h.hoy end) end
	local a = t.Ajustes()
	for i = 1, math.min(25, #lista) do
		local x = lista[i]
		local id = tonumber(tostring(x.link):match("item:(%d+)"))
		V:Fila({ icono = id, item = x.link, celdas = {
			{ tostring(x.link):gsub("[%[%]]", ""), x.h.esHoy and "precio de hoy" or "precio de ayer" },
			{ A.Monedas(x.h.hoy) },
			{ baratos and A.Monedas(x.h.media) or A.Monedas(floor(x.h.hoy * 20 * (1 - (a.comision or 0.05)))) },
			{ baratos and ("|cff6bd999" .. A.Pct((1 - x.h.hoy / x.h.media) * 100, 0) .. " menos|r") or (x.h.disponible and (x.h.disponible .. "") or "—") },
		} })
	end
	if #lista == 0 then V:Vacio("Nada por ahora", baratos and "Nada claramente barato hoy. Escanea otra vez mañana para tener más historia." or "No hay hierbas con precio en tus escaneos.") end
end

local PESTANAS = {
	{ key = "oport", label = "Oportunidades" }, { key = "vender", label = "Vender lo mío" }, { key = "reventa", label = "Reventa" },
	{ key = "pnj", label = "Al vendedor" }, { key = "baratos", label = "Baratos" }, { key = "hierbas", label = "Hierbas" }, { key = "fabricar", label = "Fabricar" },
}
local TITULOS = {
	oport = { "Oportunidades", "Lo que más ganas hoy comprando en la subasta" },
	vender = { "Vender lo mío", "Lo que hay en tus bolsas y qué te conviene hacer con cada cosa" },
	reventa = { "Reventa", "Comprar barato en la subasta para volver a venderlo" },
	pnj = { "Al vendedor", "Subastas más baratas que lo que paga un vendedor" },
	baratos = { "Baratos", "Materiales más baratos hoy que su media" },
	hierbas = { "Hierbas", "Las hierbas que más pagan hoy" },
	fabricar = { "Fabricar", "Tus recetas con los precios de hoy" },
}

Hub.Seccion({
	clave = CLAVE, nombre = "Subasta", icono = "qol-coin", orden = 110, addon = "Tasador",
	pestanas = PESTANAS,
	titulo = function(est) local x = TITULOS[est.pestana or "oport"]; return x[1], x[2] end,
	nav = function(est)
		if est.pestana ~= "vender" then return {}, nil end
		local cuenta = { subastar = 0, vendedor = 0, guardar = 0, basura = 0 }
		local lista = bolsas()
		for _, o in ipairs(lista) do local d = decision(o); cuenta[d] = cuenta[d] + 1 end
		local items = { { key = "todo", label = "Todo", count = #lista } }
		for _, k in ipairs({ "subastar", "vendedor", "guardar", "basura" }) do
			if cuenta[k] > 0 then items[#items + 1] = { key = k, label = SUG[k], count = cuenta[k] } end
		end
		return items, est.filtro or "todo"
	end,
	buscar = nil,
	dibujar = function(est, V)
		local t = T()
		if not t then V:Vacio("Falta el Tasador", "Activa «Tasador» en la lista de accesorios.") return end
		local p = est.pestana or "oport"
		if p == "vender" then vistaVender(est, V, t)
		elseif p == "oport" then vistaAsync(V, t, "oport", function(l) filasOport(V, t, l, nil, 15) end)
		elseif p == "reventa" then vistaAsync(V, t, "reventa", function(l) filasOport(V, t, l, "reventa") end)
		elseif p == "pnj" then vistaAsync(V, t, "pnj", function(l) filasOport(V, t, l, "vendedor") end)
		elseif p == "baratos" then vistaAsync(V, t, "baratos", function(l) vistaHistorial(V, t, l, true) end)
		elseif p == "hierbas" then vistaAsync(V, t, "hierbas", function(l) vistaHistorial(V, t, l, false) end)
		else vistaFabricar(V, t) end
	end,
})

---------------------------------------------------------------- eventos
ev:SetScript("OnEvent", function(_, e, boton)
	if e == "GLOBAL_MOUSE_DOWN" then pcall(altClic, nil, boton) return end
	if e == "AUCTION_HOUSE_SHOW" then abierto.subasta = true
	elseif e == "AUCTION_HOUSE_CLOSED" then abierto.subasta = false
	elseif e == "MERCHANT_SHOW" then
		abierto.vendedor = true
		-- lo que TÚ marcaste como basura se vende con la basura gris, si el interruptor está encendido
		local P = _G.Polestar
		if P and P.Get and P.Get("qol.sellJunk") and not (IsShiftKeyDown and IsShiftKeyDown()) then
			for id, que in pairs(db()) do if que == "basura" then venderAlVendedor(id) end end
		end
	elseif e == "MERCHANT_CLOSED" then abierto.vendedor = false
	elseif e == "BAG_UPDATE_DELAYED" then bolsasCache = nil end
	Hub.Redibujar()
end)
