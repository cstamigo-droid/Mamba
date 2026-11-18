-- Mamba_Plan: macros útiles por clase. Los hechizos van por su número (id): el nombre lo pone el juego en tu
-- idioma al crear la macro, así no hay nombres escritos a mano. Una macro solo se ofrece si conoces todos sus
-- hechizos. Base: BARRAS_Y_MACROS_HOPE.md (A-G del druida) y las equivalentes de cada clase.
-- Que cada condición ([@mouseover], [stance], !) funcione en Forever: NO VERIFICADO hasta probarla en el juego;
-- la macro lo dice en su ayuda. Licencia: GPL-3.0-only.
-- cuerpo: texto con {id} donde va el nombre del hechizo id. usa: hechizos que hay que conocer.
local _, M = ...

M.MACROS = {
	DRUID = {
		{ clave = "druRejuRaton", titulo = "Curar a quien apuntas con el ratón (Rejuvenecimiento)", rol = "sanar", usa = { 774 },
			cuerpo = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {774}",
			detalle = "Curas sin cambiar de objetivo: pasas el ratón por el marco y aprietas la tecla." },
		{ clave = "druRecreRaton", titulo = "Curar a quien apuntas con el ratón (Recrecimiento)", rol = "sanar", usa = { 8936 },
			cuerpo = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {8936}" },
		{ clave = "druToqueRaton", titulo = "Curar a quien apuntas con el ratón (Toque de sanación)", rol = "sanar", usa = { 5185 },
			cuerpo = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {5185}" },
		{ clave = "druSalirCurar", titulo = "Salir de la forma y curarte", usa = { 5185 },
			cuerpo = "#showtooltip {5185}\n/cancelform [form]\n/cast [@mouseover,help,nodead][@player] {5185}",
			detalle = "Para cuando eres oso o gato y te quedas sin vida." },
		{ clave = "druEscapar", titulo = "Escapar: romper raíces y ralentización (Forma de viaje)", usa = { 783 },
			cuerpo = "#showtooltip\n/cancelform\n/cast !{783}" },
		{ clave = "druGato", titulo = "Forma felina que no se apaga al apretar dos veces", rol = "danio", usa = { 768 },
			cuerpo = "#showtooltip\n/cast !{768}" },
		{ clave = "druOso", titulo = "Forma de oso que no se apaga al apretar dos veces", rol = "tanque", usa = { 5487 },
			cuerpo = "#showtooltip\n/cast !{5487}" },
		{ clave = "druAbrir", titulo = "Felino: abrir desde sigilo y después golpear", rol = "danio", usa = { 9005, 1082 },
			cuerpo = "#showtooltip\n/startattack\n/cast [stealth] {9005}; {1082}" },
		{ clave = "druRaicesFoco", titulo = "Raíces enredadoras al foco sin cambiar de objetivo", usa = { 339 },
			cuerpo = "#showtooltip\n/cast [@focus,harm,nodead][] {339}" },
		{ clave = "druLunarRaton", titulo = "Fuego lunar al enemigo bajo el ratón", usa = { 8921 },
			cuerpo = "#showtooltip\n/cast [@mouseover,harm,nodead][] {8921}" },
	},
	HUNTER = {
		{ clave = "hunMascota", titulo = "Mascota: llamarla, revivirla o curarla con un botón", usa = { 883, 982, 136 },
			cuerpo = "#showtooltip\n/cast [nopet] {883}; [@pet,dead] {982}; {136}",
			detalle = "Un solo botón para tu mascota, según cómo esté." },
		{ clave = "hunAtaque", titulo = "Atacar con la mascota y disparar", usa = { 75 },
			cuerpo = "#showtooltip\n/petattack\n/cast !{75}" },
		{ clave = "hunArcano", titulo = "Disparo Arcano sin cortar el disparo automático", usa = { 75, 3044 },
			cuerpo = "#showtooltip {3044}\n/cast !{75}\n/cast {3044}" },
		{ clave = "hunPicadura", titulo = "Picadura de serpiente al enemigo bajo el ratón", usa = { 1978 },
			cuerpo = "#showtooltip\n/cast [@mouseover,harm,nodead][] {1978}" },
		{ clave = "hunMarca", titulo = "Marca del cazador y que la mascota ataque", usa = { 1130 },
			cuerpo = "#showtooltip\n/cast {1130}\n/petattack" },
	},
	PRIEST = {
		{ clave = "priRenRaton", titulo = "Renovar a quien apuntas con el ratón", rol = "sanar", usa = { 139 },
			cuerpo = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {139}" },
		{ clave = "priEscudoRaton", titulo = "Palabra de poder: escudo a quien apuntas con el ratón", usa = { 17 },
			cuerpo = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {17}" },
	},
	SHAMAN = {
		{ clave = "chaOlaRaton", titulo = "Ola de sanación a quien apuntas con el ratón", rol = "sanar", usa = { 331 },
			cuerpo = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {331}" },
	},
	PALADIN = {
		{ clave = "palLuzRaton", titulo = "Luz Sagrada a quien apuntas con el ratón", rol = "sanar", usa = { 635 },
			cuerpo = "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] {635}" },
	},
	WARLOCK = {
		{ clave = "bruMiedoFoco", titulo = "Miedo al foco sin cambiar de objetivo", usa = { 5782 },
			cuerpo = "#showtooltip\n/cast [@focus,harm,nodead][] {5782}" },
		{ clave = "bruMascota", titulo = "Que tu demonio ataque y lanzar Descarga de las Sombras", usa = { 686 },
			cuerpo = "#showtooltip {686}\n/petattack\n/cast {686}" },
	},
	MAGE = {
		{ clave = "magPoliFoco", titulo = "Polimorfia al foco sin cambiar de objetivo", usa = { 118 },
			cuerpo = "#showtooltip\n/cast [@focus,harm,nodead][] {118}" },
	},
	ROGUE = {
		{ clave = "picAbrir", titulo = "Abrir desde sigilo y después golpear", usa = { 1833, 1752 },
			cuerpo = "#showtooltip\n/startattack\n/cast [stealth] {1833}; {1752}" },
	},
	WARRIOR = {
		{ clave = "guerCarga", titulo = "Cargar o Interceptar según la actitud", usa = { 100 },
			cuerpo = "#showtooltip\n/cast [stance:1] {100}; [stance:3] {20252}; {100}" },
	},
}
