-- Asistente_Clase: qué profesiones le convienen a cada clase y raza, para qué y según quién.
-- Escrito a mano el 16-11-2026 a partir de PROFESIONES_POR_CLASE.md (mismo contenido, con enlaces).
-- Cada consejo dice sus fuentes (ids de F). Lo que ninguna fuente dice va con verificado = false.
-- Nada copiado de Wowhead ni Warcraft Tavern: solo se cita el enlace.
-- Licencia: GPL-3.0-only.
local _, ns = ...

local F = {
	wiki = { "warcraft.wiki.gg, página Forever", "https://warcraft.wiki.gg/wiki/Forever", "sin fecha (dice lanzado 4-11-2026)" },
	wtprof = { "Warcraft Tavern, guía de profesiones", "https://www.warcrafttavern.com/forever/guides/professions/", "sin fecha" },
	wtrazas = { "Warcraft Tavern, guía de razas", "https://www.warcrafttavern.com/forever/guides/races/", "sin fecha" },
	bliz_razas = { "Blizzard, razas y clases", "https://worldofwarcraft.blizzard.com/news/24304075/", "2026-09-22" },
	bliz_prof = { "Blizzard, profesiones y campamento", "https://worldofwarcraft.blizzard.com/news/24303313", "2026-09-13" },
	bliz_hot = { "Blizzard, hotfixes de Forever", "https://news.blizzard.com/en-us/article/24315281", "2026-11-13" },
	rb = { "RankedBoost (ojo: vende servicios de subida)", "https://rankedboost.com/world-of-warcraft/forever/professions/best-professions/", "2026-11-11" },
	cc = { "Conquest Capped", "https://conquestcapped.com/guides/wow-forever/wow-forever-best-professions/", "2026-11-07" },
	mm = { "Mein-MMO", "https://mein-mmo.de/en/wow-forever-professions-the-best-for-all-classes-in-pve-and-pvp,1593990/", "2026-11-16" },
	kl = { "Kami Labs (antes del lanzamiento)", "https://kami-labs.fr/en/wow-forever/metier-par-classe-wow-forever/", "2026-10-25" },
	lepre_war = { "Leprestore, guerrero Armas", "https://leprestore.com/guides/world-of-warcraft-forever/", "2026-11-04" },
}
ns.FUENTES_PROF = F

ns.PROFESIONES = {
	-- 12 en total según tres fuentes de terceros. Blizzard no publica una lista completa: NO VERIFICADO oficialmente.
	primarias = { "Alquimia", "Herrería", "Encantamiento", "Ingeniería", "Herboristería", "Peletería", "Minería", "Desuello", "Sastrería" },
	secundarias = { "Cocina", "Primeros auxilios", "Pesca" },
	fuentesLista = { "wiki", "wtprof", "kl" },
	notaLista = "No hay Joyería ni Inscripción. Se pueden tener 2 primarias y las 3 secundarias. Tope de habilidad 300.",

	-- Bonos de raza que tocan profesiones (ya no son el +15 del juego clásico).
	razas = {
		Gnome = { bono = "Especialización en Ingeniería: tus aparatos fallan menos (no suma habilidad).", sugiere = "Ingeniería", fuentes = { "wtrazas", "cc" }, verificado = true },
		Tauren = { bono = "Cultivo: saca hierbas doble y puede recogerlas aun sin Herboristería.", sugiere = "Herboristería", fuentes = { "wtrazas" }, verificado = true },
		Dwarf = { bono = "Precisión de artesano: la fuente no explica qué hace.", sugiere = nil, fuentes = { "wtrazas" }, verificado = false },
	},
	notaRazas = "Humano, elfo de la noche, orco, trol, no-muerto y skyborne: ninguna fuente les da bono de profesión.",

	-- Por clase: subir / mazmorra (al 60) / jcj / oro. Cada uno: dos profesiones, por qué y fuentes.
	-- porSpec: cuando las fuentes separan por especialización (nombres del árbol del juego, en inglés).
	clases = {
		DRUID = {
			subir = { { "Desuello", "Peletería" }, "Juntas cuero al matar bestias y te haces tu armadura de cuero.", { "rb", "cc" } },
			mazmorra = { { "Herboristería", "Alquimia" }, "Pociones y elíxires para sanar o hacer daño con hechizos.", { "rb", "cc" },
				porSpec = { ["Feral Combat"] = { { "Peletería", "Desuello" }, "Cuero con agilidad para el gato y el oso.", { "cc", "mm" } } } },
			jcj = { { "Ingeniería", "Minería" }, "Redes, bombas y aparatos para el combate contra jugadores.", { "rb", "mm" } },
			oro = { { "Herboristería", "Desuello" }, "Elección del addon con la regla de Conquest Capped: recolectar no gasta materiales.", { "cc" } },
			desacuerdo = "RankedBoost también propone Encantamiento para Feral.",
		},
		HUNTER = {
			subir = { { "Desuello", "Peletería" }, "Matas muchas bestias: el cuero sale solo y te haces armadura.", { "rb", "cc" } },
			mazmorra = { { "Ingeniería", "Minería" }, "Mirillas para el arma y munición mejor.", { "rb", "mm" } },
			jcj = { { "Ingeniería", "Minería" }, "Redes, bombas y aparatos para el combate contra jugadores.", { "rb", "mm" } },
			oro = { { "Desuello", "Minería" }, "Elección del addon con la regla de Conquest Capped: recolectar no gasta materiales.", { "cc" } },
			desacuerdo = "Conquest Capped recomienda Desuello + Peletería para esta clase (no separa el 60); RankedBoost y Mein-MMO ponen Ingeniería al 60.",
		},
		MAGE = {
			subir = { { "Sastrería", "Encantamiento" }, "Usas tela: te haces tu ropa y desencantas lo que no sirve.", { "rb", "cc" } },
			mazmorra = { { "Sastrería", "Encantamiento" }, "Varias piezas de tela que se fabrican sirven al 60.", { "rb", "mm", "kl" } },
			jcj = { { "Ingeniería", "Sastrería" }, "Aparatos de Ingeniería y ropa de tela propia.", { "rb", "kl" } },
			oro = { { "Sastrería", "Encantamiento" }, "Conquest Capped la llama la mejor pareja de oro al 60; Kami Labs también la prefiere.", { "cc", "kl" } },
		},
		PALADIN = {
			subir = { { "Minería", "Herrería" }, "Placas y armas propias.", { "rb", "cc" } },
			mazmorra = { { "Ingeniería", "Minería" }, "Para Protección y Reprensión.", { "rb" },
				porSpec = { Holy = { { "Herboristería", "Alquimia" }, "Pociones de maná y elíxires para sanar.", { "rb" } } } },
			jcj = { { "Ingeniería", "Minería" }, "Redes, bombas y aparatos.", { "rb" } },
			oro = { { "Minería", "Herboristería" }, "Elección del addon con la regla de Conquest Capped y Leprestore: recolectar no gasta materiales.", { "cc", "lepre_war" } },
			desacuerdo = "Kami Labs prefiere Herrería + Peletería al 60 (muchas piezas fabricadas).",
		},
		PRIEST = {
			subir = { { "Sastrería", "Encantamiento" }, "Usas tela: te haces tu ropa y desencantas.", { "rb", "cc" } },
			mazmorra = { { "Sastrería", "Encantamiento" }, "Piezas de tela fabricadas para sanar o para Sombra.", { "rb", "mm", "cc", "kl" } },
			jcj = { { "Sastrería", "Ingeniería" }, "Ropa propia y aparatos para escapar.", { "rb", "kl" } },
			oro = { { "Sastrería", "Encantamiento" }, "Conquest Capped la llama la mejor pareja de oro al 60.", { "cc" } },
		},
		ROGUE = {
			subir = { { "Desuello", "Peletería" }, "Cuero con agilidad para ti.", { "rb", "cc" } },
			mazmorra = { { "Ingeniería", "Minería" }, "Aparatos y bombas útiles en grupo.", { "rb", "mm" } },
			jcj = { { "Ingeniería", "Minería" }, "Redes, bombas y aparatos.", { "rb", "cc" } },
			oro = { { "Desuello", "Minería" }, "Elección del addon con la regla de Conquest Capped: recolectar no gasta materiales.", { "cc" } },
			desacuerdo = "Conquest Capped recomienda Desuello + Peletería para esta clase (no separa el 60); RankedBoost y Mein-MMO ponen Ingeniería al 60.",
		},
		SHAMAN = {
			subir = { { "Desuello", "Peletería" }, "Cuero y malla para ti.", { "rb", "cc" } },
			mazmorra = { { "Herboristería", "Alquimia" }, "Para Restauración y Elemental: pociones de maná y elíxires.", { "rb" },
				porSpec = { Enhancement = { { "Ingeniería", "Minería" }, "Para Mejora, cuerpo a cuerpo.", { "rb", "mm" } } } },
			jcj = { { "Ingeniería", "Minería" }, "Redes, bombas y aparatos.", { "rb", "mm" } },
			oro = { { "Herboristería", "Desuello" }, "Elección del addon con la regla de Conquest Capped: recolectar no gasta materiales.", { "cc" } },
			desacuerdo = "Kami Labs prefiere Peletería + Sastrería al 60 (la clase con más piezas fabricadas).",
		},
		WARLOCK = {
			subir = { { "Sastrería", "Encantamiento" }, "Usas tela: te haces tu ropa y desencantas.", { "rb", "cc" } },
			mazmorra = { { "Sastrería", "Encantamiento" }, "Igual que el mago.", { "rb", "mm", "kl" } },
			jcj = { { "Ingeniería", "Alquimia" }, "Aparatos y pociones.", { "mm" } },
			oro = { { "Sastrería", "Encantamiento" }, "Conquest Capped la llama la mejor pareja de oro al 60.", { "cc" } },
		},
		WARRIOR = {
			subir = { { "Minería", "Herrería" }, "Placas y armas propias.", { "rb", "cc" } },
			mazmorra = { { "Ingeniería", "Minería" }, "Aparatos y bombas.", { "rb", "mm" } },
			jcj = { { "Ingeniería", "Minería" }, "Redes, bombas y aparatos.", { "rb" } },
			oro = { { "Minería", "Herboristería" }, "Leprestore lo propone para el guerrero que quiere oro.", { "lepre_war" } },
			desacuerdo = "Kami Labs prefiere Herrería + Peletería para tanques. Leprestore: ninguna pareja está probada al 60.",
		},
	},
	notaOro = "Oro: Conquest Capped (7-11) dice que la mejor pareja al 60 es Sastrería + Encantamiento, y que Encantamiento y Alquimia dan el oro más estable. Para las clases que no usan tela, la pareja de recolección la eligió el addon con otra regla de esa fuente (recolectar no gasta materiales): NO VERIFICADO como la mejor.",
	notaGeneral = "Casi todo viene de guías hechas con la beta (que llegaba al nivel 20-30). Las bandas abren el 9-12: hasta entonces, lo del 60 es teoría. Las granadas 'Saf T' y 'EZ-Thro' las puede usar cualquiera, así que Ingeniería vale algo menos que en el juego clásico.",
}

-- Consejo para una clase, un uso y (si se sabe) la especialización. -> par, por qué, fuentes | nil
function ns.Clase.Profesiones(clase, uso, spec)
	local c = ns.PROFESIONES.clases[clase]
	local u = c and c[uso]
	if not u then return nil end
	local s = spec and u.porSpec and u.porSpec[spec]
	if s then return s[1], s[2], s[3] end
	return u[1], u[2], u[3]
end

-- Bono de raza (token en inglés, como UnitRace devuelve en el segundo valor). -> tabla | nil
function ns.Clase.BonoRaza(raza)
	return ns.PROFESIONES.razas[raza]
end
