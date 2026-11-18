-- Mamba_Combate: "Cómo jugar" (C1b) de guerrero, pícaro, sacerdote, chamán, mago, brujo y paladín.
-- Datos escritos a mano, sin copiar texto ajeno. Mismo esquema que Jugar_DRUID_HUNTER.lua:
--   M.JUGAR[CLASE] = { fuentes = { { nombre, url, fecha } }, specs = { spec, ... } }
--   spec = { clave, nombre (del árbol), arbol (1-3), rol = "daño"|"tanque"|"sanar", forma = id de forma o nil,
--            casos = { solo, varios, mazmorra, jcj, jefe, emergencia } }   (o usa = "clave de otra spec")
--   caso = { pasos = { paso, ... }, nota = "texto" }   (4 a 6 pasos, en orden de prioridad)
--   paso = { h = id del hechizo (rango 1), cuando = "texto", c = { condición, ... } }
--   condiciones: sinDebuff, sinBuff, buff, vidaObj<, vida<, mana<, energia>=, ira>=, combo>=, enemigos>=,
--     forma, sinForma, mascota, amenaza>=, fueraDeCombate. En "cuando", {id} se cambia por el nombre en español.
-- Los ids (rango 1) se comprobaron contra SpellName.csv y SkillLineAbility.csv de Wago 1.15.9.70576 (Classic Era).
-- Las prioridades salen del conocimiento general de Classic 1.12: NO VERIFICADO contra una guía (ninguna se pudo
-- leer el 18-11-2026) y NO VERIFICADO que Forever no las cambie (CAMBIOS_FOREVER.md). Licencia: GPL-3.0-only.
-- PALADIN: en Forever podría ser jugable por la Horda; no se sabe. Se escribe igual.
local _, M = ...
M.JUGAR = M.JUGAR or {}

local BATALLA, DEFENSIVA, BERSERKER = 2457, 71, 2458
local NOTA_SANAR = "Mamba no puede leer la vida de tus compañeros en número (Forever la oculta): mira los marcos de Curación."

local FUENTES_BASE = {
	{ "Datos de hechizos de Classic Era (Wago 1.15.9.70576): solo para comprobar ids y clases", "https://wago.tools/db2/SpellName", "2026-11-18" },
}

M.JUGAR.WARRIOR = {
	fuentes = {
		FUENTES_BASE[1],
		{ "Guías de guerrero en Classic (Icy Veins): NO leídas, la página dio error 403", "https://www.icy-veins.com/wow-classic/", "sin fecha leída" },
	},
	specs = {
		{ clave = "armas", nombre = "Armas", arbol = 1, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 100, cuando = "Para abrir, desde {2457}: {100}", c = { { "fueraDeCombate" }, { "forma", BATALLA } } },
				{ h = 6673, cuando = "Si no tienes tu {6673}", c = { { "sinBuff", 6673 } } },
				{ h = 5308, cuando = "Si le queda menos del 20 %: {5308}", c = { { "vidaObj<", 20 }, { "ira>=", 15 } } },
				{ h = 772, cuando = "Si no tiene tu {772}", c = { { "sinDebuff", 772 }, { "ira>=", 10 }, { "forma", BATALLA } } },
				{ h = 12294, cuando = "Si lo tienes: {12294}", c = { { "ira>=", 30 } } },
				{ h = 78, cuando = "Para gastar ira: {78}", c = { { "ira>=", 15 } } },
			}, nota = "Sin mucha ira, deja que el enemigo llegue y pega normal: la ira sube al golpear y al recibir golpes." },
			varios = { pasos = {
				{ h = 12292, cuando = "Si lo tienes y hay 2 o más: {12292}", c = { { "enemigos>=", 2 } } },
				{ h = 6343, cuando = "Con 3 o más cerca, en {2457}: {6343}", c = { { "enemigos>=", 3 }, { "ira>=", 20 }, { "forma", BATALLA } } },
				{ h = 845, cuando = "Con 2 o más: {845} pega a dos a la vez", c = { { "enemigos>=", 2 }, { "ira>=", 20 } } },
				{ h = 12294, cuando = "Al que tienes de frente: {12294}", c = { { "ira>=", 30 } } },
			}, nota = "{6343} frena el ataque de todos los que tienes cerca. Pelea con la espalda contra una pared para que no te rodeen." },
			mazmorra = { pasos = {
				{ h = 6673, cuando = "Si no tienes tu {6673}", c = { { "sinBuff", 6673 } } },
				{ h = 5308, cuando = "Si le queda menos del 20 %: {5308}", c = { { "vidaObj<", 20 }, { "ira>=", 15 } } },
				{ h = 12294, cuando = "Si lo tienes: {12294}", c = { { "ira>=", 30 } } },
				{ h = 7384, cuando = "Justo después de que esquive: {7384}", c = { { "ira>=", 5 }, { "forma", BATALLA } } },
				{ h = 78, cuando = "Solo si te sobra ira: {78}", c = { { "ira>=", 50 } } },
			}, nota = "No le pases el enemigo al tanque: espera 2 o 3 golpes suyos. Para cortar un lanzamiento usa {6552} desde {2458}." },
			jcj = { pasos = {
				{ h = 5308, cuando = "Si le queda menos del 20 %: {5308}", c = { { "vidaObj<", 20 }, { "ira>=", 15 } } },
				{ h = 100, cuando = "Para llegar a él: {100}", c = { { "fueraDeCombate" }, { "forma", BATALLA } } },
				{ h = 1715, cuando = "Para que no huya: {1715}", c = { { "sinDebuff", 1715 }, { "ira>=", 10 } } },
				{ h = 12294, cuando = "Si lo tienes: {12294} baja lo que le curan", c = { { "ira>=", 30 } } },
				{ h = 7384, cuando = "Después de que esquive: {7384}", c = { { "ira>=", 5 }, { "forma", BATALLA } } },
			}, nota = "Contra miedo usa {18499} desde {2458}. Para cortar a un lanzador usa {6552} desde {2458}." },
			jefe = { pasos = {
				{ h = 6673, cuando = "Si no tienes tu {6673}", c = { { "sinBuff", 6673 } } },
				{ h = 5308, cuando = "Si le queda menos del 20 %: {5308}", c = { { "vidaObj<", 20 }, { "ira>=", 15 } } },
				{ h = 12294, cuando = "Si lo tienes: {12294}", c = { { "ira>=", 30 } } },
				{ h = 7384, cuando = "Justo después de que esquive: {7384}", c = { { "ira>=", 5 }, { "forma", BATALLA } } },
				{ h = 78, cuando = "Solo si te sobra ira: {78}", c = { { "ira>=", 50 } } },
			}, nota = "Deja que el tanque agarre al jefe antes de pegar fuerte." },
			emergencia = { pasos = {
				{ h = 5246, cuando = "Vida baja y varios encima: {5246} los hace huir", c = { { "vida<", 35 }, { "enemigos>=", 2 } } },
				{ h = DEFENSIVA, cuando = "Cámbiate a {71}: recibes menos daño", c = { { "vida<", 30 } } },
				{ h = 2565, cuando = "Con escudo y en {71}: {2565}", c = { { "vida<", 35 }, { "forma", DEFENSIVA }, { "ira>=", 10 } } },
				{ h = 871, cuando = "Con escudo y en {71}: {871} baja mucho el daño", c = { { "vida<", 25 }, { "forma", DEFENSIVA } } },
			}, nota = "Sin escudo solo sirven el grito y la huida: usa vendas y pociones." },
		} },
		{ clave = "furia", nombre = "Furia", arbol = 2, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 6673, cuando = "Si no tienes tu {6673}", c = { { "sinBuff", 6673 } } },
				{ h = 5308, cuando = "Si le queda menos del 20 %: {5308}", c = { { "vidaObj<", 20 }, { "ira>=", 15 } } },
				{ h = 23881, cuando = "Si lo tienes: {23881}", c = { { "ira>=", 30 } } },
				{ h = 1680, cuando = "En {2458}: {1680}", c = { { "forma", BERSERKER }, { "ira>=", 25 } } },
				{ h = 78, cuando = "Solo si te sobra ira: {78}", c = { { "ira>=", 50 } } },
			}, nota = "Con dos armas, la ira sube más rápido: gástala sin miedo." },
			varios = { pasos = {
				{ h = 6673, cuando = "Si no tienes tu {6673}", c = { { "sinBuff", 6673 } } },
				{ h = 1680, cuando = "Con 2 o más, en {2458}: {1680}", c = { { "enemigos>=", 2 }, { "forma", BERSERKER }, { "ira>=", 25 } } },
				{ h = 845, cuando = "Con 2 o más: {845}", c = { { "enemigos>=", 2 }, { "ira>=", 20 } } },
				{ h = 23881, cuando = "Si lo tienes: {23881}", c = { { "ira>=", 30 } } },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 6673, cuando = "Si no tienes tu {6673}", c = { { "sinBuff", 6673 } } },
				{ h = 5308, cuando = "Si le queda menos del 20 %: {5308}", c = { { "vidaObj<", 20 }, { "ira>=", 15 } } },
				{ h = 23881, cuando = "Si lo tienes: {23881}", c = { { "ira>=", 30 } } },
				{ h = 1680, cuando = "En {2458}: {1680}", c = { { "forma", BERSERKER }, { "ira>=", 25 } } },
				{ h = 78, cuando = "Solo si te sobra ira: {78}", c = { { "ira>=", 50 } } },
			}, nota = "No le pases el enemigo al tanque: espera 2 o 3 golpes suyos. Para cortar un lanzamiento usa {6552}." },
			jcj = { pasos = {
				{ h = 5308, cuando = "Si le queda menos del 20 %: {5308}", c = { { "vidaObj<", 20 }, { "ira>=", 15 } } },
				{ h = 20252, cuando = "Para llegar a él, en {2458}: {20252}", c = { { "forma", BERSERKER }, { "ira>=", 10 } } },
				{ h = 1715, cuando = "Para que no huya: {1715}", c = { { "sinDebuff", 1715 }, { "ira>=", 10 } } },
				{ h = 23881, cuando = "Si lo tienes: {23881}", c = { { "ira>=", 30 } } },
				{ h = 1680, cuando = "En {2458}: {1680}", c = { { "forma", BERSERKER }, { "ira>=", 25 } } },
			}, nota = "Contra miedo usa {18499}. Para cortar a un lanzador usa {6552}." },
			jefe = { pasos = {
				{ h = 6673, cuando = "Si no tienes tu {6673}", c = { { "sinBuff", 6673 } } },
				{ h = 12328, cuando = "Al empezar, si lo tienes: {12328} sube tu daño", c = {} },
				{ h = 5308, cuando = "Si le queda menos del 20 %: {5308}", c = { { "vidaObj<", 20 }, { "ira>=", 15 } } },
				{ h = 23881, cuando = "Si lo tienes: {23881}", c = { { "ira>=", 30 } } },
				{ h = 1680, cuando = "En {2458}: {1680}", c = { { "forma", BERSERKER }, { "ira>=", 25 } } },
				{ h = 78, cuando = "Solo si te sobra ira: {78}", c = { { "ira>=", 50 } } },
			}, nota = "Deja que el tanque agarre al jefe antes de pegar fuerte." },
			emergencia = { pasos = {
				{ h = 5246, cuando = "Vida baja y varios encima: {5246} los hace huir", c = { { "vida<", 35 }, { "enemigos>=", 2 } } },
				{ h = DEFENSIVA, cuando = "Cámbiate a {71}: recibes menos daño", c = { { "vida<", 30 } } },
				{ h = 2565, cuando = "Con escudo y en {71}: {2565}", c = { { "vida<", 35 }, { "forma", DEFENSIVA }, { "ira>=", 10 } } },
				{ h = 871, cuando = "Con escudo y en {71}: {871} baja mucho el daño", c = { { "vida<", 25 }, { "forma", DEFENSIVA } } },
			}, nota = "Sin escudo solo sirven el grito y la huida: usa vendas y pociones." },
		} },
		{ clave = "proteccion", nombre = "Protección", arbol = 3, rol = "tanque", forma = DEFENSIVA, casos = {
			solo = { pasos = {
				{ h = 6572, cuando = "Después de esquivar, parar o bloquear: {6572}", c = { { "ira>=", 5 } } },
				{ h = 23922, cuando = "Si lo tienes: {23922}", c = { { "ira>=", 20 } } },
				{ h = 7386, cuando = "Si no tiene tu {7386}", c = { { "sinDebuff", 7386 }, { "ira>=", 15 } } },
				{ h = 6343, cuando = "Con 2 o más: {6343}", c = { { "enemigos>=", 2 }, { "ira>=", 20 } } },
				{ h = 78, cuando = "Para gastar ira: {78}", c = { { "ira>=", 30 } } },
			}, nota = "Para subir de nivel solo, Armas o Furia matan mucho más rápido que Protección." },
			varios = { pasos = {
				{ h = 6343, cuando = "{6343} a todos los que tienes cerca", c = { { "enemigos>=", 2 }, { "ira>=", 20 } } },
				{ h = 1160, cuando = "{1160} si no lo tienen", c = { { "enemigos>=", 2 }, { "sinDebuff", 1160 }, { "ira>=", 10 } } },
				{ h = 6572, cuando = "Después de esquivar, parar o bloquear: {6572}", c = { { "ira>=", 5 } } },
				{ h = 23922, cuando = "Si lo tienes: {23922}", c = { { "ira>=", 20 } } },
				{ h = 845, cuando = "Con 2 o más: {845}", c = { { "enemigos>=", 2 }, { "ira>=", 20 } } },
			}, nota = "Marca uno para el grupo y no dejes que se vayan hacia el sanador." },
			mazmorra = { pasos = {
				{ h = 6572, cuando = "Después de esquivar, parar o bloquear: {6572}", c = { { "ira>=", 5 } } },
				{ h = 23922, cuando = "Si lo tienes: {23922}", c = { { "ira>=", 20 } } },
				{ h = 7386, cuando = "Si no tiene tu {7386}", c = { { "sinDebuff", 7386 }, { "ira>=", 15 } } },
				{ h = 6343, cuando = "Con 2 o más: {6343}", c = { { "enemigos>=", 2 }, { "ira>=", 20 } } },
				{ h = 1160, cuando = "Con 2 o más, si no lo tienen: {1160}", c = { { "enemigos>=", 2 }, { "sinDebuff", 1160 }, { "ira>=", 10 } } },
				{ h = 78, cuando = "Para gastar ira: {78}", c = { { "ira>=", 30 } } },
			}, nota = "Ve en {71}. Si pierdes un enemigo, {355}; si se van varios, {1161}. Para cortar un lanzamiento usa {72} con escudo." },
			jcj = { pasos = {
				{ h = 12809, cuando = "Si lo tienes: {12809} lo aturde", c = { { "ira>=", 15 } } },
				{ h = 6572, cuando = "Después de esquivar, parar o bloquear: {6572}", c = { { "ira>=", 5 } } },
				{ h = 23922, cuando = "Si lo tienes: {23922}", c = { { "ira>=", 20 } } },
				{ h = 676, cuando = "En {71}, contra el que pega fuerte con arma: {676}", c = { { "forma", DEFENSIVA }, { "ira>=", 20 } } },
				{ h = 6343, cuando = "{6343} frena su ataque", c = { { "ira>=", 20 } } },
				{ h = 72, cuando = "Para cortar un lanzamiento (con escudo): {72}", c = { { "ira>=", 10 } } },
			}, nota = "En JcJ el tanque aguanta y corta; el daño lo ponen otros." },
			jefe = { pasos = {
				{ h = 7386, cuando = "{7386}: repítelo hasta 5 marcas (Mamba solo ve la primera)", c = { { "ira>=", 15 } } },
				{ h = 6572, cuando = "Después de esquivar, parar o bloquear: {6572}", c = { { "ira>=", 5 } } },
				{ h = 23922, cuando = "Si lo tienes: {23922}", c = { { "ira>=", 20 } } },
				{ h = 2565, cuando = "Cuando pega fuerte: {2565}", c = { { "forma", DEFENSIVA }, { "ira>=", 10 } } },
				{ h = 1160, cuando = "Si no lo tiene: {1160}", c = { { "sinDebuff", 1160 }, { "ira>=", 10 } } },
				{ h = 78, cuando = "Para gastar ira: {78}", c = { { "ira>=", 30 } } },
			}, nota = "Mantén las marcas de {7386} en el jefe: sube tu amenaza y el daño de todos." },
			emergencia = { pasos = {
				{ h = 2565, cuando = "{2565}", c = { { "vida<", 50 }, { "forma", DEFENSIVA }, { "ira>=", 10 } } },
				{ h = 12975, cuando = "Si lo tienes: {12975} sube tu vida", c = { { "vida<", 30 } } },
				{ h = 871, cuando = "En {71}: {871} baja mucho el daño", c = { { "vida<", 25 }, { "forma", DEFENSIVA } } },
				{ h = 5246, cuando = "Con varios encima: {5246}", c = { { "vida<", 30 }, { "enemigos>=", 2 } } },
			}, nota = "Avisa al grupo antes de usar {871}: dura poco." },
		} },
	},
}

M.JUGAR.ROGUE = {
	fuentes = {
		FUENTES_BASE[1],
		{ "Guías de pícaro en Classic (Icy Veins): NO leídas, la página dio error 403", "https://www.icy-veins.com/wow-classic/", "sin fecha leída" },
	},
	specs = {
		{ clave = "asesinato", nombre = "Asesinato", arbol = 1, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 8676, cuando = "Desde sigilo, con daga: {8676}", c = { { "buff", 1784 }, { "energia>=", 60 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 53, cuando = "Por la espalda, con daga: {53}", c = { { "energia>=", 60 } } },
				{ h = 1752, cuando = "Si no estás detrás: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "{53} solo funciona desde atrás: ponte detrás del enemigo antes de pegar." },
			varios = { pasos = {
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 1776, cuando = "Si se suma otro y vas perdiendo: {1776}", c = { { "enemigos>=", 2 }, { "vida<", 60 }, { "energia>=", 45 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 53, cuando = "Por la espalda: {53}", c = { { "energia>=", 60 } } },
				{ h = 1752, cuando = "Si no estás detrás: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "El pícaro no tiene daño en área: mata de a uno y controla al otro. {6770} duerme a un humanoide si lo haces desde sigilo y fuera de combate." },
			mazmorra = { pasos = {
				{ h = 1966, cuando = "Si tu amenaza pasa del 90 %: {1966}", c = { { "amenaza>=", 90 }, { "energia>=", 20 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 53, cuando = "Por la espalda, con daga: {53}", c = { { "energia>=", 60 } } },
				{ h = 1752, cuando = "Si no estás detrás: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "Abre desde atrás con {703} o {8676}. Para cortar un lanzamiento usa {1766}." },
			jcj = { pasos = {
				{ h = 2098, cuando = "Para rematar, con 3 o más puntos: {2098}", c = { { "vidaObj<", 35 }, { "combo>=", 3 }, { "energia>=", 35 } } },
				{ h = 1833, cuando = "Para abrir desde sigilo: {1833} lo aturde", c = { { "buff", 1784 }, { "energia>=", 60 } } },
				{ h = 408, cuando = "Con 3 o más puntos: {408}", c = { { "combo>=", 3 }, { "energia>=", 25 } } },
				{ h = 53, cuando = "Por la espalda: {53}", c = { { "energia>=", 60 } } },
				{ h = 1752, cuando = "Para juntar puntos: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "Para cortar a un lanzador usa {1766}. Para escapar usa {1856} o {2983}." },
			jefe = { pasos = {
				{ h = 1966, cuando = "Si tu amenaza pasa del 90 %: {1966}", c = { { "amenaza>=", 90 }, { "energia>=", 20 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 14177, cuando = "Con 5 puntos, antes de {2098}: {14177}", c = { { "combo>=", 5 }, { "sinBuff", 14177 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 53, cuando = "Por la espalda, con daga: {53}", c = { { "energia>=", 60 } } },
				{ h = 1752, cuando = "Si no estás detrás: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "Mantén {5171} siempre puesto." },
			emergencia = { pasos = {
				{ h = 5277, cuando = "Te pegan cuerpo a cuerpo: {5277}", c = { { "vida<", 45 } } },
				{ h = 408, cuando = "Aturde con puntos de combo: {408}", c = { { "vida<", 35 }, { "combo>=", 1 }, { "energia>=", 25 } } },
				{ h = 1776, cuando = "Si no tienes puntos: {1776}", c = { { "vida<", 35 }, { "energia>=", 45 } } },
				{ h = 1856, cuando = "Desaparecer: {1856}", c = { { "vida<", 20 } } },
				{ h = 2983, cuando = "Huir: {2983}", c = { { "vida<", 25 } } },
			}, nota = "Después de huir, véndate o bebe una poción antes de volver." },
		} },
		{ clave = "combate", nombre = "Combate", arbol = 2, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 1833, cuando = "Para abrir desde sigilo: {1833}", c = { { "buff", 1784 }, { "energia>=", 60 } } },
				{ h = 14251, cuando = "Si lo tienes, tras parar un golpe: {14251}", c = { { "energia>=", 10 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 1752, cuando = "Para juntar puntos: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "Con arma lenta de una mano, {1752} es tu golpe principal." },
			varios = { pasos = {
				{ h = 13750, cuando = "Si lo tienes y hay 3 o más: {13750}", c = { { "enemigos>=", 3 } } },
				{ h = 13877, cuando = "Si lo tienes y hay 2 o más: {13877}", c = { { "enemigos>=", 2 }, { "energia>=", 25 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 1752, cuando = "Para juntar puntos: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 1966, cuando = "Si tu amenaza pasa del 90 %: {1966}", c = { { "amenaza>=", 90 }, { "energia>=", 20 } } },
				{ h = 13877, cuando = "Si lo tienes y hay 2 o más: {13877}", c = { { "enemigos>=", 2 }, { "energia>=", 25 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 1752, cuando = "Para juntar puntos: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "Para cortar un lanzamiento usa {1766}." },
			jcj = { pasos = {
				{ h = 2098, cuando = "Para rematar, con 3 o más puntos: {2098}", c = { { "vidaObj<", 35 }, { "combo>=", 3 }, { "energia>=", 35 } } },
				{ h = 1833, cuando = "Para abrir desde sigilo: {1833} lo aturde", c = { { "buff", 1784 }, { "energia>=", 60 } } },
				{ h = 408, cuando = "Con 3 o más puntos: {408}", c = { { "combo>=", 3 }, { "energia>=", 25 } } },
				{ h = 1776, cuando = "Si te cae mucho daño: {1776}", c = { { "vida<", 50 }, { "energia>=", 45 } } },
				{ h = 1752, cuando = "Para juntar puntos: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "Para cortar a un lanzador usa {1766}. Para escapar usa {1856} o {2983}." },
			jefe = { pasos = {
				{ h = 1966, cuando = "Si tu amenaza pasa del 90 %: {1966}", c = { { "amenaza>=", 90 }, { "energia>=", 20 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 13750, cuando = "Al empezar, si lo tienes: {13750}", c = {} },
				{ h = 13877, cuando = "Si lo tienes: {13877} sube tu velocidad de golpe", c = { { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 1752, cuando = "Para juntar puntos: {1752}", c = { { "energia>=", 45 } } },
			}, nota = "Mantén {5171} siempre puesto." },
			emergencia = { pasos = {
				{ h = 5277, cuando = "Te pegan cuerpo a cuerpo: {5277}", c = { { "vida<", 45 } } },
				{ h = 408, cuando = "Aturde con puntos de combo: {408}", c = { { "vida<", 35 }, { "combo>=", 1 }, { "energia>=", 25 } } },
				{ h = 1776, cuando = "Si no tienes puntos: {1776}", c = { { "vida<", 35 }, { "energia>=", 45 } } },
				{ h = 1856, cuando = "Desaparecer: {1856}", c = { { "vida<", 20 } } },
				{ h = 2983, cuando = "Huir: {2983}", c = { { "vida<", 25 } } },
			}, nota = "Después de huir, véndate o bebe una poción antes de volver." },
		} },
		{ clave = "sutileza", nombre = "Sutileza", arbol = 3, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 14183, cuando = "Desde sigilo, antes de abrir: {14183}", c = { { "buff", 1784 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 16511, cuando = "Para juntar puntos: {16511}", c = { { "energia>=", 35 } } },
				{ h = 14278, cuando = "Si lo tienes: {14278}", c = { { "energia>=", 40 } } },
			}, nota = "{16511} y {14278} son talentos: sin ellos, usa {1752} para juntar puntos." },
			varios = { pasos = {
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 16511, cuando = "Para juntar puntos: {16511}", c = { { "energia>=", 35 } } },
				{ h = 14278, cuando = "Si lo tienes: {14278}", c = { { "energia>=", 40 } } },
			}, nota = "No tiene daño en área: mata de a uno. {6770} duerme a un humanoide desde sigilo y fuera de combate." },
			mazmorra = { pasos = {
				{ h = 1966, cuando = "Si tu amenaza pasa del 90 %: {1966}", c = { { "amenaza>=", 90 }, { "energia>=", 20 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 16511, cuando = "Para juntar puntos: {16511}", c = { { "energia>=", 35 } } },
				{ h = 14278, cuando = "Si lo tienes: {14278}", c = { { "energia>=", 40 } } },
			}, nota = "Para cortar un lanzamiento usa {1766}." },
			jcj = { pasos = {
				{ h = 2098, cuando = "Para rematar, con 3 o más puntos: {2098}", c = { { "vidaObj<", 35 }, { "combo>=", 3 }, { "energia>=", 35 } } },
				{ h = 1833, cuando = "Para abrir desde sigilo: {1833} lo aturde", c = { { "buff", 1784 }, { "energia>=", 60 } } },
				{ h = 408, cuando = "Con 3 o más puntos: {408}", c = { { "combo>=", 3 }, { "energia>=", 25 } } },
				{ h = 16511, cuando = "Para juntar puntos: {16511}", c = { { "energia>=", 35 } } },
			}, nota = "Para cortar a un lanzador usa {1766}. Con {1856} y {5277} gastados, {14185} te los devuelve." },
			jefe = { pasos = {
				{ h = 1966, cuando = "Si tu amenaza pasa del 90 %: {1966}", c = { { "amenaza>=", 90 }, { "energia>=", 20 } } },
				{ h = 5171, cuando = "Con 2 o más puntos y sin {5171}", c = { { "sinBuff", 5171 }, { "combo>=", 2 }, { "energia>=", 25 } } },
				{ h = 2098, cuando = "Con 5 puntos: {2098}", c = { { "combo>=", 5 }, { "energia>=", 35 } } },
				{ h = 16511, cuando = "Para juntar puntos: {16511}", c = { { "energia>=", 35 } } },
				{ h = 14278, cuando = "Si lo tienes: {14278}", c = { { "energia>=", 40 } } },
			}, nota = "Mantén {5171} siempre puesto." },
			emergencia = { pasos = {
				{ h = 5277, cuando = "Te pegan cuerpo a cuerpo: {5277}", c = { { "vida<", 45 } } },
				{ h = 408, cuando = "Aturde con puntos de combo: {408}", c = { { "vida<", 35 }, { "combo>=", 1 }, { "energia>=", 25 } } },
				{ h = 1776, cuando = "Si no tienes puntos: {1776}", c = { { "vida<", 35 }, { "energia>=", 45 } } },
				{ h = 1856, cuando = "Desaparecer: {1856}", c = { { "vida<", 20 } } },
				{ h = 14185, cuando = "Si lo tienes, después de {1856} y {5277}: {14185}", c = { { "vida<", 30 } } },
			}, nota = "Después de huir, véndate o bebe una poción antes de volver." },
		} },
	},
}

M.JUGAR.PRIEST = {
	fuentes = {
		FUENTES_BASE[1],
		{ "Guías de sacerdote en Classic (Icy Veins): NO leídas, la página dio error 403", "https://www.icy-veins.com/wow-classic/", "sin fecha leída" },
	},
	specs = {
		{ clave = "disciplina", nombre = "Disciplina", arbol = 1, rol = "sanar", casos = {
			solo = { pasos = {
				{ h = 588, cuando = "Antes de pelear: {588}", c = { { "fueraDeCombate" }, { "sinBuff", 588 } } },
				{ h = 17, cuando = "Si te empiezan a pegar: {17}", c = { { "sinBuff", 17 }, { "vida<", 80 } } },
				{ h = 14914, cuando = "Para abrir: {14914}", c = { { "fueraDeCombate" } } },
				{ h = 589, cuando = "Si no tiene tu {589}", c = { { "sinDebuff", 589 } } },
				{ h = 8092, cuando = "{8092} cuando esté listo", c = {} },
				{ h = 585, cuando = "Relleno: {585}", c = {} },
			}, nota = "Cuando al enemigo le quede poca vida, remátalo con la varita para ahorrar maná." },
			varios = { pasos = {
				{ h = 17, cuando = "Si te empiezan a pegar: {17}", c = { { "sinBuff", 17 }, { "vida<", 80 } } },
				{ h = 8122, cuando = "Con 3 o más encima: {8122}", c = { { "enemigos>=", 3 }, { "vida<", 60 } } },
				{ h = 589, cuando = "{589} a cada uno que no lo tenga", c = { { "sinDebuff", 589 } } },
				{ h = 8092, cuando = "{8092} cuando esté listo", c = {} },
				{ h = 585, cuando = "Relleno: {585}", c = {} },
			}, nota = "Contra varios, pelea con la espalda contra una pared y usa {8122} antes de que te rodeen." },
			mazmorra = { pasos = {
				{ h = 1243, cuando = "Antes de empezar, a cada compañero: {1243}", c = { { "fueraDeCombate" } } },
				{ h = 139, cuando = "{139} al tanque", c = {} },
				{ h = 17, cuando = "{17} a quien va a recibir golpes", c = {} },
				{ h = 2060, cuando = "Daño fuerte: {2060}", c = {} },
				{ h = 2061, cuando = "Emergencia: {2061} rápido", c = {} },
				{ h = 596, cuando = "Varios heridos: {596}", c = {} },
			}, nota = NOTA_SANAR .. " Quita enfermedades con {552} y beneficios del enemigo con {527}." },
			jcj = { pasos = {
				{ h = 17, cuando = "Si te empiezan a pegar: {17}", c = { { "sinBuff", 17 }, { "vida<", 80 } } },
				{ h = 8122, cuando = "Si te alcanzan: {8122}", c = { { "vida<", 60 } } },
				{ h = 2061, cuando = "Vida baja: {2061}", c = { { "vida<", 50 } } },
				{ h = 139, cuando = "Si no tienes {139}", c = { { "sinBuff", 139 }, { "vida<", 80 } } },
				{ h = 589, cuando = "Si no tiene tu {589}", c = { { "sinDebuff", 589 } } },
				{ h = 527, cuando = "Para quitarle un beneficio: {527}", c = {} },
			}, nota = "Contra pícaros, {8122} y alejarte. Contra lanzadores, aléjate y no te quedes quieto." },
			jefe = { pasos = {
				{ h = 139, cuando = "{139} al tanque siempre", c = {} },
				{ h = 2060, cuando = "Daño fuerte: {2060}", c = {} },
				{ h = 2061, cuando = "Emergencia: {2061}", c = {} },
				{ h = 596, cuando = "Daño a todo el grupo: {596}", c = {} },
				{ h = 10060, cuando = "Si lo tienes: {10060} cura más y gasta menos maná", c = { { "mana<", 50 } } },
			}, nota = NOTA_SANAR .. " Dejar de lanzar 5 segundos recupera maná: no cures de más." },
			emergencia = { pasos = {
				{ h = 17, cuando = "{17} sobre ti", c = { { "vida<", 60 }, { "sinBuff", 17 } } },
				{ h = 8122, cuando = "Si te pegan cuerpo a cuerpo: {8122}", c = { { "vida<", 45 }, { "enemigos>=", 1 } } },
				{ h = 2061, cuando = "Cúrate: {2061}", c = { { "vida<", 50 } } },
				{ h = 139, cuando = "Mientras corres: {139}", c = { { "vida<", 70 }, { "sinBuff", 139 } } },
				{ h = 586, cuando = "Si tu amenaza es alta: {586}", c = { { "amenaza>=", 70 } } },
			}, nota = "Primero cúrate, después sigue: muerto no ayudas a nadie." },
		} },
		{ clave = "sagrado", nombre = "Sagrado", arbol = 2, rol = "sanar", usa = "disciplina" },
		{ clave = "sombras", nombre = "Sombras", arbol = 3, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 15473, cuando = "Si lo tienes: {15473}", c = { { "sinBuff", 15473 }, { "fueraDeCombate" } } },
				{ h = 15286, cuando = "Si lo tienes: {15286}", c = { { "sinBuff", 15286 } } },
				{ h = 589, cuando = "Si no tiene tu {589}", c = { { "sinDebuff", 589 } } },
				{ h = 8092, cuando = "{8092} cuando esté listo", c = {} },
				{ h = 15407, cuando = "Relleno, si lo tienes: {15407}", c = {} },
			}, nota = "Con {15473} no puedes usar hechizos sagrados: cuando aún no la tengas, rellena con {585}." },
			varios = { pasos = {
				{ h = 8122, cuando = "Con 3 o más encima: {8122}", c = { { "enemigos>=", 3 }, { "vida<", 60 } } },
				{ h = 589, cuando = "{589} a cada uno que no lo tenga", c = { { "sinDebuff", 589 } } },
				{ h = 8092, cuando = "{8092} cuando esté listo", c = {} },
				{ h = 15407, cuando = "Relleno: {15407} también frena al que se acerca", c = {} },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 586, cuando = "Si tu amenaza pasa del 90 %: {586}", c = { { "amenaza>=", 90 } } },
				{ h = 15473, cuando = "Si lo tienes: {15473}", c = { { "sinBuff", 15473 }, { "fueraDeCombate" } } },
				{ h = 15286, cuando = "Si lo tienes: {15286} cura al grupo", c = { { "sinBuff", 15286 } } },
				{ h = 589, cuando = "Si no tiene tu {589}", c = { { "sinDebuff", 589 } } },
				{ h = 8092, cuando = "{8092} cuando esté listo", c = {} },
				{ h = 15407, cuando = "Relleno: {15407}", c = {} },
			}, nota = "Deja que el tanque agarre antes de empezar con tus daños." },
			jcj = { pasos = {
				{ h = 8122, cuando = "Si te alcanzan: {8122}", c = { { "vida<", 50 } } },
				{ h = 589, cuando = "Si no tiene tu {589}", c = { { "sinDebuff", 589 } } },
				{ h = 8092, cuando = "{8092} cuando esté listo", c = {} },
				{ h = 15407, cuando = "{15407} frena a quien va hacia ti", c = {} },
			}, nota = "Para cortar un lanzamiento usa {15487}, si lo tienes. Contra pícaros, {8122} y te alejas." },
			jefe = { pasos = {
				{ h = 586, cuando = "Si tu amenaza pasa del 90 %: {586}", c = { { "amenaza>=", 90 } } },
				{ h = 15473, cuando = "Si lo tienes: {15473}", c = { { "sinBuff", 15473 }, { "fueraDeCombate" } } },
				{ h = 15286, cuando = "Si lo tienes: {15286}", c = { { "sinBuff", 15286 } } },
				{ h = 589, cuando = "Si no tiene tu {589}", c = { { "sinDebuff", 589 } } },
				{ h = 8092, cuando = "{8092} cuando esté listo", c = {} },
				{ h = 15407, cuando = "Relleno: {15407}", c = {} },
			}, nota = "La pelea larga es de maná: cuida cuánto gastas." },
			emergencia = { pasos = {
				{ h = 8122, cuando = "Si te pegan cuerpo a cuerpo: {8122}", c = { { "vida<", 45 }, { "enemigos>=", 1 } } },
				{ h = 17, cuando = "{17} sobre ti", c = { { "vida<", 60 }, { "sinBuff", 17 } } },
				{ h = 2061, cuando = "Cúrate: {2061}", c = { { "vida<", 50 } } },
				{ h = 586, cuando = "Si tu amenaza es alta: {586}", c = { { "amenaza>=", 70 } } },
			}, nota = "Con {15473} no puedes curarte: sal de la forma o huye." },
		} },
	},
}

M.JUGAR.SHAMAN = {
	fuentes = {
		FUENTES_BASE[1],
		{ "Guías de chamán en Classic (Icy Veins): NO leídas, la página dio error 403", "https://www.icy-veins.com/wow-classic/", "sin fecha leída" },
	},
	specs = {
		{ clave = "elemental", nombre = "Elemental", arbol = 1, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 403, cuando = "Para abrir, desde lejos: {403}", c = { { "fueraDeCombate" } } },
				{ h = 8050, cuando = "Si no tiene tu {8050}", c = { { "sinDebuff", 8050 } } },
				{ h = 8042, cuando = "{8042} cada vez que esté listo", c = {} },
				{ h = 403, cuando = "Relleno: {403}", c = {} },
			}, nota = "Pon un tótem de fuego como {3599} al empezar peleas largas." },
			varios = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 8190, cuando = "Con 3 o más: {8190}", c = { { "enemigos>=", 3 } } },
				{ h = 421, cuando = "Con 2 o más: {421}", c = { { "enemigos>=", 2 } } },
				{ h = 8050, cuando = "Si no tiene tu {8050}", c = { { "sinDebuff", 8050 } } },
				{ h = 403, cuando = "Relleno: {403}", c = {} },
			}, nota = "Si se te acercan, {2484} los frena." },
			mazmorra = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 421, cuando = "Con 2 o más: {421}", c = { { "enemigos>=", 2 } } },
				{ h = 8050, cuando = "Si no tiene tu {8050}", c = { { "sinDebuff", 8050 } } },
				{ h = 403, cuando = "Daño principal: {403}", c = {} },
			}, nota = "Pon tus tótems al empezar. Para cortar un lanzamiento usa {8042}." },
			jcj = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 8050, cuando = "Si no tiene tu {8050}", c = { { "sinDebuff", 8050 } } },
				{ h = 8056, cuando = "Para frenar al que huye: {8056}", c = { { "vidaObj<", 40 } } },
				{ h = 8042, cuando = "{8042} corta lanzamientos", c = {} },
				{ h = 403, cuando = "Relleno: {403}", c = {} },
			}, nota = "Contra lanzadores, {8177} se come un hechizo. Contra miedo, {8143}. {370} le quita un beneficio." },
			jefe = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 16166, cuando = "Al empezar, si lo tienes: {16166}", c = {} },
				{ h = 403, cuando = "Daño principal: {403}", c = {} },
				{ h = 421, cuando = "Con 2 o más: {421}", c = { { "enemigos>=", 2 } } },
			}, nota = "La pelea larga es de maná: no lances de más." },
			emergencia = { pasos = {
				{ h = 8004, cuando = "Si ya la tienes: {8004}", c = { { "vida<", 45 } } },
				{ h = 331, cuando = "Cúrate: {331}", c = { { "vida<", 40 } } },
				{ h = 2484, cuando = "Si te persiguen: {2484} los frena", c = { { "vida<", 50 }, { "enemigos>=", 1 } } },
				{ h = 2645, cuando = "Huir: {2645}", c = { { "vida<", 25 }, { "sinForma" } } },
			}, nota = "Primero cúrate, después sigue: muerto no haces daño." },
		} },
		{ clave = "mejora", nombre = "Mejora", arbol = 2, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 403, cuando = "Para abrir, desde lejos: {403}", c = { { "fueraDeCombate" } } },
				{ h = 17364, cuando = "Si lo tienes: {17364}", c = {} },
				{ h = 8042, cuando = "{8042} cada vez que esté listo", c = {} },
			}, nota = "Antes de pelear, pon un arma encantada: {8017} al inicio, {8232} desde el nivel 30." },
			varios = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 8190, cuando = "Con 3 o más: {8190}", c = { { "enemigos>=", 3 } } },
				{ h = 17364, cuando = "Si lo tienes: {17364}", c = {} },
				{ h = 8042, cuando = "{8042} cada vez que esté listo", c = {} },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 17364, cuando = "Si lo tienes: {17364}", c = {} },
				{ h = 8042, cuando = "{8042} cada vez que esté listo", c = {} },
				{ h = 8190, cuando = "Con 3 o más: {8190}", c = { { "enemigos>=", 3 } } },
			}, nota = "Pon {8512} si el grupo pega cuerpo a cuerpo. Para cortar un lanzamiento usa {8042}." },
			jcj = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 17364, cuando = "Si lo tienes: {17364}", c = {} },
				{ h = 8056, cuando = "Para frenar al que huye: {8056}", c = { { "vidaObj<", 40 } } },
				{ h = 8042, cuando = "{8042} corta lanzamientos", c = {} },
			}, nota = "{2645} te deja alcanzar a quien huye. {370} le quita un beneficio. Contra lanzadores, {8177}." },
			jefe = { pasos = {
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 17364, cuando = "Si lo tienes: {17364}", c = {} },
				{ h = 8042, cuando = "{8042} cada vez que esté listo", c = {} },
				{ h = 403, cuando = "Para abrir, si empieza lejos: {403}", c = { { "fueraDeCombate" } } },
			}, nota = "" },
			emergencia = { pasos = {
				{ h = 8004, cuando = "Si ya la tienes: {8004}", c = { { "vida<", 45 } } },
				{ h = 331, cuando = "Cúrate: {331}", c = { { "vida<", 40 } } },
				{ h = 2484, cuando = "Si te persiguen: {2484} los frena", c = { { "vida<", 50 }, { "enemigos>=", 1 } } },
				{ h = 2645, cuando = "Huir: {2645}", c = { { "vida<", 25 }, { "sinForma" } } },
			}, nota = "Primero cúrate, después sigue: muerto no haces daño." },
		} },
		{ clave = "resto", nombre = "Restauración", arbol = 3, rol = "sanar", casos = {
			solo = { pasos = {
				{ h = 331, cuando = "Vida baja: {331}", c = { { "vida<", 40 } } },
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 8050, cuando = "Si no tiene tu {8050}", c = { { "sinDebuff", 8050 } } },
				{ h = 8042, cuando = "{8042} cada vez que esté listo", c = {} },
				{ h = 403, cuando = "Relleno: {403}", c = {} },
			}, nota = "Para subir solo, Elemental o Mejora matan mucho más rápido que Restauración." },
			varios = { pasos = {
				{ h = 331, cuando = "Vida baja: {331}", c = { { "vida<", 40 } } },
				{ h = 324, cuando = "Si no tienes {324}", c = { { "sinBuff", 324 } } },
				{ h = 421, cuando = "Con 2 o más: {421}", c = { { "enemigos>=", 2 } } },
				{ h = 8050, cuando = "Si no tiene tu {8050}", c = { { "sinDebuff", 8050 } } },
				{ h = 403, cuando = "Relleno: {403}", c = {} },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 16190, cuando = "Poco maná, si lo tienes: {16190}", c = { { "mana<", 30 } } },
				{ h = 331, cuando = "Al tanque: {331}", c = {} },
				{ h = 8004, cuando = "Emergencia: {8004} rápido", c = {} },
				{ h = 1064, cuando = "Varios heridos: {1064}", c = {} },
			}, nota = NOTA_SANAR .. " Quita venenos con {526} y enfermedades con {2870}." },
			jcj = { pasos = {
				{ h = 8004, cuando = "Vida baja: {8004}", c = { { "vida<", 45 } } },
				{ h = 2484, cuando = "Si te persiguen: {2484}", c = { { "vida<", 60 }, { "enemigos>=", 1 } } },
				{ h = 8056, cuando = "{8056} frena al que huye", c = { { "vidaObj<", 40 } } },
				{ h = 8042, cuando = "{8042} corta lanzamientos", c = {} },
			}, nota = "{8143} te protege del miedo. {370} le quita un beneficio." },
			jefe = { pasos = {
				{ h = 16190, cuando = "Poco maná, si lo tienes: {16190}", c = { { "mana<", 30 } } },
				{ h = 331, cuando = "Al tanque: {331}", c = {} },
				{ h = 1064, cuando = "Daño a varios: {1064}", c = {} },
				{ h = 8004, cuando = "Emergencia: {8004}", c = {} },
			}, nota = NOTA_SANAR .. " Con {16188} (si lo tienes) el próximo {331} sale al instante." },
			emergencia = { pasos = {
				{ h = 8004, cuando = "Si ya la tienes: {8004}", c = { { "vida<", 45 } } },
				{ h = 331, cuando = "Cúrate: {331}", c = { { "vida<", 40 } } },
				{ h = 2484, cuando = "Si te persiguen: {2484} los frena", c = { { "vida<", 50 }, { "enemigos>=", 1 } } },
				{ h = 2645, cuando = "Huir: {2645}", c = { { "vida<", 25 }, { "sinForma" } } },
			}, nota = "Primero cúrate, después sigue." },
		} },
	},
}

M.JUGAR.MAGE = {
	fuentes = {
		FUENTES_BASE[1],
		{ "Guías de mago en Classic (Icy Veins): NO leídas, la página dio error 403", "https://www.icy-veins.com/wow-classic/", "sin fecha leída" },
	},
	specs = {
		{ clave = "arcano", nombre = "Arcano", arbol = 1, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 6117, cuando = "Antes de pelear: {6117}", c = { { "fueraDeCombate" }, { "sinBuff", 6117 } } },
				{ h = 1459, cuando = "Antes de pelear: {1459}", c = { { "fueraDeCombate" }, { "sinBuff", 1459 } } },
				{ h = 5143, cuando = "Si tienes {12536}: {5143} sale gratis", c = { { "buff", 12536 } } },
				{ h = 122, cuando = "Si te alcanza: {122} y te alejas", c = { { "vida<", 70 } } },
				{ h = 116, cuando = "Relleno: {116}", c = {} },
			}, nota = "Cuando al enemigo le quede poca vida, remátalo con la varita para ahorrar maná." },
			varios = { pasos = {
				{ h = 1449, cuando = "Con 3 o más cerca: {1449}", c = { { "enemigos>=", 3 } } },
				{ h = 122, cuando = "Con 2 o más encima: {122}", c = { { "enemigos>=", 2 }, { "vida<", 70 } } },
				{ h = 5143, cuando = "Si tienes {12536}: {5143} sale gratis", c = { { "buff", 12536 } } },
				{ h = 116, cuando = "Relleno: {116}", c = {} },
			}, nota = "{1449} gasta mucho maná: úsala con el grupo cerca y bebe después." },
			mazmorra = { pasos = {
				{ h = 1459, cuando = "Antes de empezar, a cada compañero: {1459}", c = { { "fueraDeCombate" } } },
				{ h = 5143, cuando = "Si tienes {12536}: {5143} sale gratis", c = { { "buff", 12536 } } },
				{ h = 1449, cuando = "Con 3 o más cerca: {1449}", c = { { "enemigos>=", 3 } } },
				{ h = 116, cuando = "Daño principal: {116}", c = {} },
			}, nota = "Duerme a uno con {118} (humanoides y bestias). Para cortar un lanzamiento usa {2139}." },
			jcj = { pasos = {
				{ h = 122, cuando = "Si te alcanza: {122} y te alejas", c = { { "vida<", 70 } } },
				{ h = 2136, cuando = "Para rematar: {2136}", c = { { "vidaObj<", 30 } } },
				{ h = 5143, cuando = "Si tienes {12536}: {5143} sale gratis", c = { { "buff", 12536 } } },
				{ h = 116, cuando = "Relleno: {116} lo frena", c = {} },
			}, nota = "{2139} corta un lanzamiento. {118} deja fuera de pelea a un sanador. {1953} te saca de apuros." },
			jefe = { pasos = {
				{ h = 12042, cuando = "Al empezar, si lo tienes: {12042}", c = {} },
				{ h = 5143, cuando = "Si tienes {12536}: {5143} sale gratis", c = { { "buff", 12536 } } },
				{ h = 12051, cuando = "Muy poco maná: {12051}", c = { { "mana<", 15 } } },
				{ h = 116, cuando = "Daño principal: {116}", c = {} },
			}, nota = "La pelea larga es de maná: {12051} recupera mucho, pero no la uses con enemigos cerca." },
			emergencia = { pasos = {
				{ h = 122, cuando = "Si te pegan cuerpo a cuerpo: {122}", c = { { "vida<", 55 }, { "enemigos>=", 1 } } },
				{ h = 1463, cuando = "{1463}", c = { { "vida<", 50 }, { "sinBuff", 1463 } } },
				{ h = 1953, cuando = "Escapar: {1953}", c = { { "vida<", 40 } } },
				{ h = 118, cuando = "Duerme al más peligroso: {118}", c = { { "vida<", 35 } } },
			}, nota = "Congela y aléjate; después cúrate o bebe." },
		} },
		{ clave = "fuego", nombre = "Fuego", arbol = 2, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 6117, cuando = "Antes de pelear: {6117}", c = { { "fueraDeCombate" }, { "sinBuff", 6117 } } },
				{ h = 11366, cuando = "Para abrir, si lo tienes: {11366}", c = { { "fueraDeCombate" } } },
				{ h = 122, cuando = "Si te alcanza: {122} y te alejas", c = { { "vida<", 70 } } },
				{ h = 2136, cuando = "Para rematar: {2136}", c = { { "vidaObj<", 20 } } },
				{ h = 133, cuando = "Relleno: {133}", c = {} },
			}, nota = "Cuando al enemigo le quede poca vida, remátalo con la varita para ahorrar maná." },
			varios = { pasos = {
				{ h = 122, cuando = "Con 2 o más encima: {122}", c = { { "enemigos>=", 2 }, { "vida<", 70 } } },
				{ h = 11113, cuando = "Si lo tienes: {11113}", c = { { "enemigos>=", 2 } } },
				{ h = 2120, cuando = "Con 3 o más juntos: {2120}", c = { { "enemigos>=", 3 } } },
				{ h = 133, cuando = "Relleno: {133}", c = {} },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 1459, cuando = "Antes de empezar, a cada compañero: {1459}", c = { { "fueraDeCombate" } } },
				{ h = 11366, cuando = "Para abrir, si lo tienes: {11366}", c = { { "fueraDeCombate" } } },
				{ h = 2136, cuando = "Para rematar: {2136}", c = { { "vidaObj<", 20 } } },
				{ h = 133, cuando = "Daño principal: {133}", c = {} },
			}, nota = "Duerme a uno con {118} (humanoides y bestias). Para cortar un lanzamiento usa {2139}." },
			jcj = { pasos = {
				{ h = 122, cuando = "Si te alcanza: {122} y te alejas", c = { { "vida<", 70 } } },
				{ h = 11113, cuando = "Si lo tienes y está pegado a ti: {11113}", c = { { "vida<", 70 } } },
				{ h = 2136, cuando = "Para rematar: {2136}", c = { { "vidaObj<", 35 } } },
				{ h = 133, cuando = "Relleno: {133}", c = {} },
			}, nota = "{2139} corta un lanzamiento. {118} deja fuera de pelea a un sanador. {1953} te saca de apuros." },
			jefe = { pasos = {
				{ h = 1459, cuando = "Antes de empezar: {1459}", c = { { "fueraDeCombate" }, { "sinBuff", 1459 } } },
				{ h = 11129, cuando = "Al empezar, si lo tienes: {11129}", c = {} },
				{ h = 12051, cuando = "Muy poco maná: {12051}", c = { { "mana<", 15 } } },
				{ h = 133, cuando = "Daño principal: {133}", c = {} },
			}, nota = "La pelea larga es de maná: {12051} recupera mucho, pero no la uses con enemigos cerca." },
			emergencia = { pasos = {
				{ h = 122, cuando = "Si te pegan cuerpo a cuerpo: {122}", c = { { "vida<", 55 }, { "enemigos>=", 1 } } },
				{ h = 1463, cuando = "{1463}", c = { { "vida<", 50 }, { "sinBuff", 1463 } } },
				{ h = 1953, cuando = "Escapar: {1953}", c = { { "vida<", 40 } } },
				{ h = 118, cuando = "Duerme al más peligroso: {118}", c = { { "vida<", 35 } } },
			}, nota = "Congela y aléjate; después cúrate o bebe." },
		} },
		{ clave = "escarcha", nombre = "Escarcha", arbol = 3, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 6117, cuando = "Antes de pelear: {6117}", c = { { "fueraDeCombate" }, { "sinBuff", 6117 } } },
				{ h = 11426, cuando = "Si lo tienes y no estás protegido: {11426}", c = { { "sinBuff", 11426 } } },
				{ h = 122, cuando = "Si te alcanza: {122} y te alejas", c = { { "vida<", 70 } } },
				{ h = 2136, cuando = "Para rematar: {2136}", c = { { "vidaObj<", 20 } } },
				{ h = 116, cuando = "Daño principal: {116} lo frena", c = {} },
			}, nota = "Cuando al enemigo le quede poca vida, remátalo con la varita para ahorrar maná." },
			varios = { pasos = {
				{ h = 11426, cuando = "Si lo tienes y no estás protegido: {11426}", c = { { "sinBuff", 11426 } } },
				{ h = 122, cuando = "Con 2 o más encima: {122}", c = { { "enemigos>=", 2 }, { "vida<", 70 } } },
				{ h = 120, cuando = "Con 2 o más pegados a ti: {120}", c = { { "enemigos>=", 2 } } },
				{ h = 10, cuando = "Con 3 o más juntos: {10}", c = { { "enemigos>=", 3 } } },
				{ h = 116, cuando = "Relleno: {116}", c = {} },
			}, nota = "{10} se lanza sobre ellos y dura mientras no te muevas." },
			mazmorra = { pasos = {
				{ h = 1459, cuando = "Antes de empezar, a cada compañero: {1459}", c = { { "fueraDeCombate" } } },
				{ h = 11426, cuando = "Si lo tienes y no estás protegido: {11426}", c = { { "sinBuff", 11426 } } },
				{ h = 10, cuando = "Con 3 o más juntos: {10}", c = { { "enemigos>=", 3 } } },
				{ h = 116, cuando = "Daño principal: {116}", c = {} },
			}, nota = "Duerme a uno con {118} (humanoides y bestias). Para cortar un lanzamiento usa {2139}." },
			jcj = { pasos = {
				{ h = 11958, cuando = "Si lo tienes y vas a morir: {11958}", c = { { "vida<", 20 } } },
				{ h = 122, cuando = "Si te alcanza: {122} y te alejas", c = { { "vida<", 70 } } },
				{ h = 120, cuando = "Si está pegado a ti: {120} lo frena", c = { { "vida<", 70 } } },
				{ h = 2136, cuando = "Para rematar: {2136}", c = { { "vidaObj<", 30 } } },
				{ h = 116, cuando = "Relleno: {116} lo frena", c = {} },
			}, nota = "{2139} corta un lanzamiento. {118} deja fuera de pelea a un sanador. {1953} te saca de apuros." },
			jefe = { pasos = {
				{ h = 6117, cuando = "Antes de pelear: {6117}", c = { { "fueraDeCombate" }, { "sinBuff", 6117 } } },
				{ h = 1459, cuando = "Antes de pelear: {1459}", c = { { "fueraDeCombate" }, { "sinBuff", 1459 } } },
				{ h = 12051, cuando = "Muy poco maná: {12051}", c = { { "mana<", 15 } } },
				{ h = 116, cuando = "Daño principal: {116}", c = {} },
			}, nota = "La pelea larga es de maná: {12051} recupera mucho, pero no la uses con enemigos cerca." },
			emergencia = { pasos = {
				{ h = 11426, cuando = "Si lo tienes: {11426}", c = { { "vida<", 70 }, { "sinBuff", 11426 } } },
				{ h = 122, cuando = "Si te pegan cuerpo a cuerpo: {122}", c = { { "vida<", 55 }, { "enemigos>=", 1 } } },
				{ h = 1463, cuando = "{1463}", c = { { "vida<", 50 }, { "sinBuff", 1463 } } },
				{ h = 1953, cuando = "Escapar: {1953}", c = { { "vida<", 40 } } },
				{ h = 11958, cuando = "Si lo tienes: {11958}", c = { { "vida<", 25 } } },
			}, nota = "Congela y aléjate; después cúrate o bebe." },
		} },
	},
}

M.JUGAR.WARLOCK = {
	fuentes = {
		FUENTES_BASE[1],
		{ "Guías de brujo en Classic (Icy Veins): NO leídas, la página dio error 403", "https://www.icy-veins.com/wow-classic/", "sin fecha leída" },
	},
	specs = {
		{ clave = "afliccion", nombre = "Aflicción", arbol = 1, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 1454, cuando = "Poco maná y vida alta: {1454}", c = { { "mana<", 20 }, { "vida>=", 60 } } },
				{ h = 1120, cuando = "Si le queda menos del 25 %: {1120} da un fragmento de alma", c = { { "vidaObj<", 25 } } },
				{ h = 172, cuando = "Si no tiene tu {172}", c = { { "sinDebuff", 172 } } },
				{ h = 980, cuando = "Si no tiene tu {980}", c = { { "sinDebuff", 980 } } },
				{ h = 18265, cuando = "Si lo tienes: {18265}", c = { { "sinDebuff", 18265 } } },
				{ h = 686, cuando = "Relleno: {686}", c = {} },
			}, nota = "Llama a tu esbirro ({688} o {697}) y deja que ataque primero. {1454} gasta vida: no la uses con poca." },
			varios = { pasos = {
				{ h = 5740, cuando = "Con 3 o más juntos: {5740}", c = { { "enemigos>=", 3 } } },
				{ h = 5484, cuando = "Si te rodean y vas perdiendo: {5484}", c = { { "enemigos>=", 3 }, { "vida<", 50 } } },
				{ h = 172, cuando = "{172} a cada uno que no la tenga", c = { { "sinDebuff", 172 } } },
				{ h = 980, cuando = "{980} a cada uno que no la tenga", c = { { "sinDebuff", 980 } } },
				{ h = 686, cuando = "Relleno: {686}", c = {} },
			}, nota = "Que tu esbirro aguante a uno; a otro puedes mandarlo lejos con {5782}." },
			mazmorra = { pasos = {
				{ h = 1454, cuando = "Poco maná y vida alta: {1454}", c = { { "mana<", 20 }, { "vida>=", 60 } } },
				{ h = 980, cuando = "Si no tiene tu {980}", c = { { "sinDebuff", 980 } } },
				{ h = 172, cuando = "Si no tiene tu {172}", c = { { "sinDebuff", 172 } } },
				{ h = 18265, cuando = "Si lo tienes: {18265}", c = { { "sinDebuff", 18265 } } },
				{ h = 686, cuando = "Daño principal: {686}", c = {} },
			}, nota = "Solo puedes tener una maldición tuya en cada objetivo. Un enemigo se puede desterrar con {710} (demonios y elementales)." },
			jcj = { pasos = {
				{ h = 6789, cuando = "Vida baja: {6789} te cura y lo asusta", c = { { "vida<", 40 } } },
				{ h = 5782, cuando = "Para controlarlo: {5782}", c = { { "vida<", 60 } } },
				{ h = 172, cuando = "Si no tiene tu {172}", c = { { "sinDebuff", 172 } } },
				{ h = 980, cuando = "Si no tiene tu {980}", c = { { "sinDebuff", 980 } } },
				{ h = 18265, cuando = "Si lo tienes: {18265}", c = { { "sinDebuff", 18265 } } },
				{ h = 686, cuando = "Relleno: {686}", c = {} },
			}, nota = "Contra lanzadores pon {1714}. {5484} aleja a varios de golpe." },
			jefe = { pasos = {
				{ h = 1454, cuando = "Poco maná y vida alta: {1454}", c = { { "mana<", 20 }, { "vida>=", 60 } } },
				{ h = 980, cuando = "Si no tiene tu {980}", c = { { "sinDebuff", 980 } } },
				{ h = 172, cuando = "Si no tiene tu {172}", c = { { "sinDebuff", 172 } } },
				{ h = 18265, cuando = "Si lo tienes: {18265}", c = { { "sinDebuff", 18265 } } },
				{ h = 686, cuando = "Daño principal: {686}", c = {} },
			}, nota = "En banda te pueden pedir otra maldición: {1490}, {17862} o {1714}." },
			emergencia = { pasos = {
				{ h = 6789, cuando = "{6789} te cura y lo asusta", c = { { "vida<", 40 } } },
				{ h = 5484, cuando = "Con varios encima: {5484}", c = { { "vida<", 40 }, { "enemigos>=", 2 } } },
				{ h = 5782, cuando = "Si es uno solo: {5782}", c = { { "vida<", 50 } } },
				{ h = 689, cuando = "Si estás a salvo: {689}", c = { { "vida<", 35 } } },
			}, nota = "Usa tu piedra de salud (se hace con {5699})." },
		} },
		{ clave = "demonologia", nombre = "Demonología", arbol = 2, rol = "daño", usa = "afliccion" },
		{ clave = "destruccion", nombre = "Destrucción", arbol = 3, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 1454, cuando = "Poco maná y vida alta: {1454}", c = { { "mana<", 20 }, { "vida>=", 60 } } },
				{ h = 17877, cuando = "Para rematar, si lo tienes: {17877} (gasta un fragmento)", c = { { "vidaObj<", 20 } } },
				{ h = 348, cuando = "Si no tiene tu {348}", c = { { "sinDebuff", 348 } } },
				{ h = 980, cuando = "Si no tiene tu {980}", c = { { "sinDebuff", 980 } } },
				{ h = 686, cuando = "Relleno: {686}", c = {} },
			}, nota = "Llama a tu esbirro ({688} o {697}) y deja que ataque primero." },
			varios = { pasos = {
				{ h = 5740, cuando = "Con 3 o más juntos: {5740}", c = { { "enemigos>=", 3 } } },
				{ h = 5484, cuando = "Si te rodean y vas perdiendo: {5484}", c = { { "enemigos>=", 3 }, { "vida<", 50 } } },
				{ h = 348, cuando = "{348} a cada uno que no la tenga", c = { { "sinDebuff", 348 } } },
				{ h = 686, cuando = "Relleno: {686}", c = {} },
			}, nota = "Que tu esbirro aguante a uno; a otro puedes mandarlo lejos con {5782}." },
			mazmorra = { pasos = {
				{ h = 1454, cuando = "Poco maná y vida alta: {1454}", c = { { "mana<", 20 }, { "vida>=", 60 } } },
				{ h = 348, cuando = "Si no tiene tu {348}", c = { { "sinDebuff", 348 } } },
				{ h = 980, cuando = "Si no tiene tu {980}", c = { { "sinDebuff", 980 } } },
				{ h = 686, cuando = "Daño principal: {686}", c = {} },
			}, nota = "Solo puedes tener una maldición tuya en cada objetivo. Un enemigo se puede desterrar con {710} (demonios y elementales)." },
			jcj = { pasos = {
				{ h = 6789, cuando = "Vida baja: {6789} te cura y lo asusta", c = { { "vida<", 40 } } },
				{ h = 17877, cuando = "Para rematar, si lo tienes: {17877}", c = { { "vidaObj<", 20 } } },
				{ h = 5782, cuando = "Para controlarlo: {5782}", c = { { "vida<", 60 } } },
				{ h = 348, cuando = "Si no tiene tu {348}", c = { { "sinDebuff", 348 } } },
				{ h = 980, cuando = "Si no tiene tu {980}", c = { { "sinDebuff", 980 } } },
				{ h = 686, cuando = "Relleno: {686}", c = {} },
			}, nota = "Contra lanzadores pon {1714}. {5484} aleja a varios de golpe." },
			jefe = { pasos = {
				{ h = 1454, cuando = "Poco maná y vida alta: {1454}", c = { { "mana<", 20 }, { "vida>=", 60 } } },
				{ h = 980, cuando = "Si no tiene tu {980}", c = { { "sinDebuff", 980 } } },
				{ h = 348, cuando = "Si no tiene tu {348}", c = { { "sinDebuff", 348 } } },
				{ h = 686, cuando = "Daño principal: {686}", c = {} },
			}, nota = "En banda te pueden pedir otra maldición: {1490}, {17862} o {1714}." },
			emergencia = { pasos = {
				{ h = 6789, cuando = "{6789} te cura y lo asusta", c = { { "vida<", 40 } } },
				{ h = 5484, cuando = "Con varios encima: {5484}", c = { { "vida<", 40 }, { "enemigos>=", 2 } } },
				{ h = 5782, cuando = "Si es uno solo: {5782}", c = { { "vida<", 50 } } },
				{ h = 689, cuando = "Si estás a salvo: {689}", c = { { "vida<", 35 } } },
			}, nota = "Usa tu piedra de salud (se hace con {5699})." },
		} },
	},
}

M.JUGAR.PALADIN = {
	fuentes = {
		FUENTES_BASE[1],
		{ "Guías de paladín en Classic (Icy Veins): NO leídas, la página dio error 403", "https://www.icy-veins.com/wow-classic/", "sin fecha leída" },
	},
	specs = {
		{ clave = "sagrado", nombre = "Sagrado", arbol = 1, rol = "sanar", casos = {
			solo = { pasos = {
				{ h = 635, cuando = "Vida baja: {635}", c = { { "vida<", 35 } } },
				{ h = 19750, cuando = "Si ya la tienes: {19750}", c = { { "vida<", 55 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
				{ h = 26573, cuando = "Con 2 o más: {26573}", c = { { "enemigos>=", 2 } } },
			}, nota = "Para subir solo, Reprensión mata más rápido que Sagrado." },
			varios = { pasos = {
				{ h = 635, cuando = "Vida baja: {635}", c = { { "vida<", 35 } } },
				{ h = 26573, cuando = "Con 3 o más: {26573}", c = { { "enemigos>=", 3 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 19746, cuando = "Antes de empezar: {19746}", c = { { "fueraDeCombate" }, { "sinBuff", 19746 } } },
				{ h = 19750, cuando = "Daño pequeño: {19750}", c = {} },
				{ h = 635, cuando = "Daño fuerte al tanque: {635}", c = {} },
				{ h = 20473, cuando = "Si lo tienes: {20473}", c = {} },
				{ h = 4987, cuando = "Quitar veneno, enfermedad o magia: {4987}", c = {} },
			}, nota = NOTA_SANAR .. " Con {20216} (si lo tienes) el próximo {635} es crítico seguro." },
			jcj = { pasos = {
				{ h = 642, cuando = "Si vas a morir: {642}", c = { { "vida<", 20 } } },
				{ h = 19750, cuando = "Vida baja: {19750}", c = { { "vida<", 50 } } },
				{ h = 853, cuando = "Para aturdirlo: {853}", c = {} },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
			}, nota = "{1044} te libera de lo que te frena." },
			jefe = { pasos = {
				{ h = 20216, cuando = "Si lo tienes, antes de {635}: {20216}", c = {} },
				{ h = 635, cuando = "Daño fuerte al tanque: {635}", c = {} },
				{ h = 19750, cuando = "Daño pequeño: {19750}", c = {} },
				{ h = 20473, cuando = "Si lo tienes: {20473}", c = {} },
			}, nota = NOTA_SANAR .. " Dejar de lanzar 5 segundos recupera maná: no cures de más." },
			emergencia = { pasos = {
				{ h = 853, cuando = "Si te pegan cuerpo a cuerpo: {853}", c = { { "vida<", 45 } } },
				{ h = 642, cuando = "{642} te protege unos segundos", c = { { "vida<", 20 } } },
				{ h = 633, cuando = "Última carta: {633}", c = { { "vida<", 15 } } },
				{ h = 635, cuando = "Si estás a salvo: {635}", c = { { "vida<", 35 } } },
				{ h = 19750, cuando = "Cúrate: {19750}", c = { { "vida<", 50 } } },
			}, nota = "No puedes usar {642} y {633} seguidos: espera un rato entre uno y otro." },
		} },
		{ clave = "proteccion", nombre = "Protección", arbol = 2, rol = "tanque", casos = {
			solo = { pasos = {
				{ h = 635, cuando = "Vida baja: {635}", c = { { "vida<", 35 } } },
				{ h = 20925, cuando = "Si lo tienes: {20925}", c = { { "sinBuff", 20925 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
				{ h = 26573, cuando = "Con 2 o más: {26573}", c = { { "enemigos>=", 2 } } },
			}, nota = "Para subir solo, Reprensión mata más rápido que Protección." },
			varios = { pasos = {
				{ h = 25780, cuando = "Si no tienes {25780}", c = { { "sinBuff", 25780 } } },
				{ h = 20925, cuando = "Si lo tienes: {20925}", c = { { "sinBuff", 20925 } } },
				{ h = 26573, cuando = "Con 2 o más: {26573}", c = { { "enemigos>=", 2 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
			}, nota = "No tienes provocar: mantén a los enemigos pegados a ti con {26573}." },
			mazmorra = { pasos = {
				{ h = 465, cuando = "Antes de empezar: {465}", c = { { "fueraDeCombate" }, { "sinBuff", 465 } } },
				{ h = 25780, cuando = "Si no tienes {25780}", c = { { "sinBuff", 25780 } } },
				{ h = 20925, cuando = "Si lo tienes: {20925}", c = { { "sinBuff", 20925 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
				{ h = 26573, cuando = "Con 2 o más: {26573}", c = { { "enemigos>=", 2 } } },
			}, nota = "No tienes provocar. {853} detiene a uno por unos segundos." },
			jcj = { pasos = {
				{ h = 642, cuando = "Si vas a morir: {642}", c = { { "vida<", 20 } } },
				{ h = 853, cuando = "Para aturdirlo: {853}", c = {} },
				{ h = 20164, cuando = "Contra el que huye: {20164}", c = { { "sinBuff", 20164 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20164 } } },
				{ h = 20925, cuando = "Si lo tienes: {20925}", c = { { "sinBuff", 20925 } } },
			}, nota = "{1044} te libera de lo que te frena." },
			jefe = { pasos = {
				{ h = 25780, cuando = "Si no tienes {25780}", c = { { "sinBuff", 25780 } } },
				{ h = 20925, cuando = "Si lo tienes: {20925}", c = { { "sinBuff", 20925 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
				{ h = 26573, cuando = "Si te sobra maná: {26573}", c = { { "enemigos>=", 1 } } },
			}, nota = "Con {20166} puesto, tu {20271} le devuelve maná a quienes le pegan al jefe." },
			emergencia = { pasos = {
				{ h = 853, cuando = "Si te pegan cuerpo a cuerpo: {853}", c = { { "vida<", 45 } } },
				{ h = 642, cuando = "{642} te protege unos segundos", c = { { "vida<", 20 } } },
				{ h = 633, cuando = "Última carta: {633}", c = { { "vida<", 15 } } },
				{ h = 635, cuando = "Si estás a salvo: {635}", c = { { "vida<", 35 } } },
				{ h = 19750, cuando = "Cúrate: {19750}", c = { { "vida<", 50 } } },
			}, nota = "No puedes usar {642} y {633} seguidos: espera un rato entre uno y otro." },
		} },
		{ clave = "reprension", nombre = "Reprensión", arbol = 3, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 635, cuando = "Vida baja: {635}", c = { { "vida<", 35 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
				{ h = 24275, cuando = "Si le queda menos del 20 %: {24275}", c = { { "vidaObj<", 20 } } },
				{ h = 26573, cuando = "Con 2 o más: {26573}", c = { { "enemigos>=", 2 } } },
			}, nota = "Si tienes {20375}, úsalo en vez de {20154} con arma de dos manos. {879} solo sirve contra muertos vivientes y demonios." },
			varios = { pasos = {
				{ h = 635, cuando = "Vida baja: {635}", c = { { "vida<", 35 } } },
				{ h = 7294, cuando = "Antes de pelear: {7294}", c = { { "fueraDeCombate" }, { "sinBuff", 7294 } } },
				{ h = 26573, cuando = "Con 3 o más: {26573}", c = { { "enemigos>=", 3 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 7294, cuando = "Antes de empezar: {7294}", c = { { "fueraDeCombate" }, { "sinBuff", 7294 } } },
				{ h = 19740, cuando = "Antes de empezar: {19740}", c = { { "fueraDeCombate" }, { "sinBuff", 19740 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
				{ h = 24275, cuando = "Si le queda menos del 20 %: {24275}", c = { { "vidaObj<", 20 } } },
				{ h = 26573, cuando = "Con 3 o más: {26573}", c = { { "enemigos>=", 3 } } },
			}, nota = "Si tienes {20218}, úsala en vez de {7294}. {853} detiene a uno por unos segundos." },
			jcj = { pasos = {
				{ h = 642, cuando = "Si vas a morir: {642}", c = { { "vida<", 20 } } },
				{ h = 24275, cuando = "Si le queda menos del 20 %: {24275}", c = { { "vidaObj<", 20 } } },
				{ h = 853, cuando = "Para aturdirlo: {853}", c = {} },
				{ h = 20066, cuando = "Si lo tienes y vas mal: {20066} te da un respiro", c = { { "vida<", 50 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
			}, nota = "{1044} te libera de lo que te frena." },
			jefe = { pasos = {
				{ h = 7294, cuando = "Antes de empezar: {7294}", c = { { "fueraDeCombate" }, { "sinBuff", 7294 } } },
				{ h = 19740, cuando = "Antes de empezar: {19740}", c = { { "fueraDeCombate" }, { "sinBuff", 19740 } } },
				{ h = 20154, cuando = "Si no tienes {20154}", c = { { "sinBuff", 20154 } } },
				{ h = 20271, cuando = "Con el sello puesto: {20271}", c = { { "buff", 20154 } } },
				{ h = 24275, cuando = "Si le queda menos del 20 %: {24275}", c = { { "vidaObj<", 20 } } },
			}, nota = "Deja que el tanque agarre al jefe antes de pegar fuerte." },
			emergencia = { pasos = {
				{ h = 853, cuando = "Si te pegan cuerpo a cuerpo: {853}", c = { { "vida<", 45 } } },
				{ h = 642, cuando = "{642} te protege unos segundos", c = { { "vida<", 20 } } },
				{ h = 633, cuando = "Última carta: {633}", c = { { "vida<", 15 } } },
				{ h = 635, cuando = "Si estás a salvo: {635}", c = { { "vida<", 35 } } },
				{ h = 19750, cuando = "Cúrate: {19750}", c = { { "vida<", 50 } } },
			}, nota = "No puedes usar {642} y {633} seguidos: espera un rato entre uno y otro." },
		} },
	},
}
