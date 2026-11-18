-- Mamba_Combate: "Cómo jugar" (C1b) del druida y del cazador. Datos escritos a mano, sin copiar texto ajeno.
-- Esquema (lo lee Jugar.lua y el motor de Rotacion.lua):
--   M.JUGAR[CLASE] = { fuentes = { { nombre, url, fecha } }, specs = { spec, ... } }
--   spec = { clave, nombre (del árbol), arbol (1-3), rol = "daño"|"tanque"|"sanar", forma = id de forma o nil,
--            casos = { solo, varios, mazmorra, jcj, jefe, emergencia } }
--   caso = { pasos = { paso, ... }, nota = "texto" }   (4 a 6 pasos, en orden de prioridad)
--   paso = { h = id del hechizo (rango 1: el juego usa el rango más alto que sabes), cuando = "texto",
--            c = { condición, ... } }   (todas tienen que cumplirse; las que el juego no deja leer quedan "?")
--   condiciones: { "sinDebuff", id } el objetivo no tiene ese efecto tuyo · { "sinBuff", id } tú no lo tienes ·
--     { "buff", id } tú lo tienes · { "vidaObj<", %} · { "vida<", %} · { "mana<", %} · { "energia>=", n } ·
--     { "ira>=", n } · { "combo>=", n } · { "enemigos>=", n } · { "forma", id } · { "sinForma" } · { "mascota" } ·
--     { "amenaza>=", %} · { "fueraDeCombate" }
--   En "cuando", {id} se cambia por el nombre del hechizo en el idioma del juego.
-- Los nombres de los árboles salen del juego (GetTalentTabInfo); "nombre" es solo el de respaldo.
-- Fuentes: prioridades clásicas de cada especialización (guías listadas), NO VERIFICADO que Forever no las cambie
-- (Forever cambió talentos y hechizos: CAMBIOS_FOREVER.md). Licencia: GPL-3.0-only.
local _, M = ...
M.JUGAR = M.JUGAR or {}

local OSO, GATO, LECHUCICO = 5487, 768, 24858

M.JUGAR.DRUID = {
	fuentes = {
		{ "Icy Veins, druida Equilibrio en Classic", "https://www.icy-veins.com/wow-classic/balance-druid-dps-pve-guide", "sin fecha leída" },
		{ "Icy Veins, druida Feral en Classic", "https://www.icy-veins.com/wow-classic/feral-druid-dps-pve-guide", "sin fecha leída" },
		{ "Icy Veins, druida tanque en Classic", "https://www.icy-veins.com/wow-classic/feral-druid-tank-pve-guide", "sin fecha leída" },
		{ "Icy Veins, druida Restauración en Classic", "https://www.icy-veins.com/wow-classic/restoration-druid-healer-pve-guide", "sin fecha leída" },
	},
	specs = {
		{ clave = "equilibrio", nombre = "Equilibrio", arbol = 1, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 2912, cuando = "Para abrir, desde lejos: {2912} pega fuerte antes de que llegue", c = { { "fueraDeCombate" } } },
				{ h = 8921, cuando = "Si el objetivo no tiene tu {8921}", c = { { "sinDebuff", 8921 } } },
				{ h = 5570, cuando = "Si tienes {5570} y no lo tiene", c = { { "sinDebuff", 5570 } } },
				{ h = 2912, cuando = "Si tienes Augurio de claridad: {2912} sale gratis", c = { { "buff", 16870 } } },
				{ h = 5176, cuando = "Relleno: {5176}", c = {} },
				{ h = 339, cuando = "Si se te acerca: {339} y te alejas", c = { { "sinDebuff", 339 }, { "vida<", 80 } } },
			}, nota = "Con poco maná, termina a los enemigos en forma felina en vez de beber entre cada pelea." },
			varios = { pasos = {
				{ h = 16914, cuando = "Si hay 3 o más juntos: {16914}", c = { { "enemigos>=", 3 } } },
				{ h = 8921, cuando = "{8921} a cada uno que no lo tenga", c = { { "sinDebuff", 8921 } } },
				{ h = 339, cuando = "{339} al que se te acerque", c = { { "sinDebuff", 339 } } },
				{ h = 5176, cuando = "Relleno: {5176}", c = {} },
			}, nota = "Contra varios, controla a uno con {339} o {2637} (bestias y dragones) y mata de a uno." },
			mazmorra = { pasos = {
				{ h = 770, cuando = "Si nadie puso {770} en el objetivo", c = { { "sinDebuff", 770 } } },
				{ h = 2912, cuando = "Daño principal: {2912}", c = {} },
				{ h = 8921, cuando = "Solo si te mueves: {8921}", c = {} },
				{ h = 29166, cuando = "{29166} al sanador (o a ti) con poco maná", c = { { "mana<", 30 } } },
			}, nota = "No pases al tanque en amenaza: espera 2-3 golpes antes del primer {2912}." },
			jcj = { pasos = {
				{ h = 339, cuando = "Controlar: {339} al que viene a pegarte", c = { { "sinDebuff", 339 } } },
				{ h = 8921, cuando = "Al moverte: {8921} no te frena", c = { { "sinDebuff", 8921 } } },
				{ h = 2912, cuando = "Con el enemigo enraizado: {2912}", c = {} },
				{ h = 783, cuando = "Escapar: {783} (quita la lentitud)", c = { { "vida<", 40 } } },
			}, nota = "Contra pícaros y guerreros, distancia con {339}. Al pasar a oso empiezas sin ira: {5211} no te sirve para cortar desde Equilibrio." },
			jefe = { pasos = {
				{ h = 770, cuando = "Si nadie puso {770}", c = { { "sinDebuff", 770 } } },
				{ h = 2912, cuando = "{2912} sin parar", c = {} },
				{ h = 29166, cuando = "{29166} a ti al 20 % de maná", c = { { "mana<", 20 } } },
			}, nota = "La pelea larga es de maná: no gastes en {8921} si no te mueves." },
			emergencia = { pasos = {
				{ h = 8936, cuando = "Vida baja: {8936}", c = { { "vida<", 40 }, { "sinBuff", 8936 } } },
				{ h = 5185, cuando = "Si tienes tiempo: {5185}", c = { { "vida<", 40 } } },
				{ h = OSO, cuando = "Si te pegan cuerpo a cuerpo: {5487} aguanta más", c = { { "vida<", 30 } } },
			}, nota = "Primero cúrate, después sigue: muerto no haces daño." },
		} },
		{ clave = "gato", nombre = "Combate feral (felino)", arbol = 2, rol = "daño", forma = GATO, casos = {
			solo = { pasos = {
				{ h = 9005, cuando = "Desde {5215}: abrir con {9005}", c = { { "buff", 5215 } } },
				{ h = 16857, cuando = "Si no tiene {16857}", c = { { "sinDebuff", 16857 } } },
				{ h = 1822, cuando = "Si no tiene tu {1822}", c = { { "sinDebuff", 1822 }, { "energia>=", 40 } } },
				{ h = 22568, cuando = "Con 4-5 puntos: {22568}", c = { { "combo>=", 4 }, { "energia>=", 35 } } },
				{ h = 1082, cuando = "Para juntar puntos: {1082}", c = { { "energia>=", 45 } } },
			}, nota = "Con Augurio de claridad el próximo golpe es gratis: úsalo en {1082}." },
			varios = { pasos = {
				{ h = OSO, cuando = "Si hay 3 o más: pasa a {5487}", c = { { "enemigos>=", 3 } } },
				{ h = 779, cuando = "En oso: {779} a todos", c = { { "forma", OSO } } },
				{ h = 1082, cuando = "Uno por uno: {1082}", c = { { "energia>=", 45 } } },
			}, nota = "El gato no tiene daño en área: contra varios, oso." },
			mazmorra = { pasos = {
				{ h = 5221, cuando = "Desde atrás: {5221}", c = { { "energia>=", 60 } } },
				{ h = 1079, cuando = "Con 5 puntos y el jefe con vida: {1079}", c = { { "combo>=", 5 }, { "sinDebuff", 1079 } } },
				{ h = 22568, cuando = "Con 5 puntos si ya tiene {1079}: {22568}", c = { { "combo>=", 5 } } },
				{ h = 1082, cuando = "Si no puedes ir atrás: {1082}", c = { { "energia>=", 45 } } },
			}, nota = "Si tu amenaza pasa del 90 %, deja de pegar 2 segundos o usa {8998}." },
			jcj = { pasos = {
				{ h = 9005, cuando = "Desde {5215}: {9005} aturde y sangra", c = { { "buff", 5215 } } },
				{ h = 16857, cuando = "{16857}: no se puede esconder", c = { { "sinDebuff", 16857 } } },
				{ h = 1082, cuando = "Juntar puntos: {1082}", c = { { "energia>=", 45 } } },
				{ h = 22568, cuando = "Rematar con {22568}", c = { { "combo>=", 4 } } },
				{ h = 783, cuando = "Escapar: {783}", c = { { "vida<", 35 } } },
			}, nota = "Cambiar de forma quita las raíces y la lentitud." },
			jefe = { pasos = {
				{ h = 5221, cuando = "{5221} desde atrás", c = { { "energia>=", 60 } } },
				{ h = 1079, cuando = "Con 5 puntos: {1079}", c = { { "combo>=", 5 }, { "sinDebuff", 1079 } } },
				{ h = 22568, cuando = "Con 5 puntos y {1079} puesto: {22568}", c = { { "combo>=", 5 } } },
			}, nota = "Mantén {1079} siempre: es la mayor parte del daño en peleas largas." },
			emergencia = { pasos = {
				{ h = OSO, cuando = "Te pegan mucho: {5487}", c = { { "vida<", 35 } } },
				{ h = 8936, cuando = "Fuera de forma: {8936}", c = { { "vida<", 40 } } },
				{ h = 783, cuando = "Huir: {783}", c = { { "vida<", 20 } } },
			}, nota = "" },
		} },
		{ clave = "oso", nombre = "Combate feral (oso)", arbol = 2, rol = "tanque", forma = OSO, casos = {
			solo = { pasos = {
				{ h = 5229, cuando = "Al empezar: {5229} da ira", c = {} },
				{ h = 99, cuando = "Si no tiene {99}", c = { { "sinDebuff", 99 }, { "ira>=", 10 } } },
				{ h = 6807, cuando = "{6807} con 15 de ira", c = { { "ira>=", 15 } } },
				{ h = 779, cuando = "Varios cerca: {779}", c = { { "enemigos>=", 2 }, { "ira>=", 20 } } },
			}, nota = "El oso sube más lento que el gato, pero casi no necesita beber." },
			varios = { pasos = {
				{ h = 99, cuando = "{99} a todos", c = { { "sinDebuff", 99 } } },
				{ h = 779, cuando = "{779} a los que tienes cerca", c = { { "ira>=", 20 } } },
				{ h = 6807, cuando = "{6807} al principal", c = { { "ira>=", 15 } } },
			}, nota = "" },
			mazmorra = { pasos = {
				{ h = 16857, cuando = "Tirar desde lejos: {16857}", c = { { "fueraDeCombate" } } },
				{ h = 6795, cuando = "Si alguien te quita uno: {6795}", c = {} },
				{ h = 779, cuando = "Varios: {779} sin parar", c = { { "enemigos>=", 2 }, { "ira>=", 20 } } },
				{ h = 6807, cuando = "Uno: {6807}", c = { { "ira>=", 15 } } },
				{ h = 414644, cuando = "Desde el 42: {414644} suma amenaza con el tiempo", c = { { "ira>=", 15 } } },
				{ h = 99, cuando = "{99} si no lo tiene", c = { { "sinDebuff", 99 } } },
			}, nota = "Marca cuál matar primero y espera al sanador antes del siguiente grupo." },
			jcj = { pasos = {
				{ h = 5211, cuando = "Cortar un lanzamiento: {5211}", c = { { "ira>=", 10 } } },
				{ h = 6807, cuando = "{6807}", c = { { "ira>=", 15 } } },
				{ h = 22842, cuando = "Vida baja: {22842}", c = { { "vida<", 35 } } },
			}, nota = "En JcJ el oso aguanta y corta; el daño lo pone el gato." },
			jefe = { pasos = {
				{ h = 99, cuando = "Siempre {99} puesto", c = { { "sinDebuff", 99 } } },
				{ h = 6807, cuando = "{6807}", c = { { "ira>=", 15 } } },
				{ h = 414644, cuando = "Desde el 42: {414644}", c = { { "ira>=", 15 } } },
				{ h = 16857, cuando = "{16857} si no lo tiene", c = { { "sinDebuff", 16857 } } },
			}, nota = "" },
			emergencia = { pasos = {
				{ h = 22842, cuando = "{22842}: ira en vida", c = { { "vida<", 30 } } },
				{ h = 5209, cuando = "Se escapan varios hacia el sanador: {5209}", c = {} },
			}, nota = "Avisa al grupo antes de usar {5209}: dura poco." },
		} },
		{ clave = "resto", nombre = "Restauración", arbol = 3, rol = "sanar", casos = {
			mazmorra = { pasos = {
				{ h = 774, cuando = "{774} al tanque antes de que reciba golpes", c = {} },
				{ h = 8936, cuando = "Si el tanque baja del 70 %: {8936}", c = {} },
				{ h = 5185, cuando = "Daño fuerte: {5185} (un rango bajo ahorra maná)", c = {} },
				{ h = 18562, cuando = "Emergencia: {18562} sobre {774} o {8936}", c = {} },
				{ h = 2782, cuando = "Limpiar maldiciones con {2782} y venenos con {8946}", c = {} },
				{ h = 29166, cuando = "Poco maná: {29166} a ti", c = { { "mana<", 25 } } },
			}, nota = "Mamba no puede leer la vida de tus compañeros en número (Forever la oculta): mira los marcos de Curación." },
			jefe = { pasos = {
				{ h = 774, cuando = "{774} al tanque siempre", c = {} },
				{ h = 5185, cuando = "{5185} de rango bajo", c = {} },
				{ h = 740, cuando = "Daño a todo el grupo: {740}", c = {} },
				{ h = 29166, cuando = "{29166} al 25 % de maná", c = { { "mana<", 25 } } },
			}, nota = "Dejar de lanzar 5 segundos recupera maná: no cures de más." },
			solo = { pasos = {
				{ h = 8921, cuando = "{8921}", c = { { "sinDebuff", 8921 } } },
				{ h = 5176, cuando = "{5176}", c = {} },
				{ h = 774, cuando = "Vida baja: {774}", c = { { "vida<", 60 }, { "sinBuff", 774 } } },
			}, nota = "Para subir solo, Equilibrio o felino matan más rápido que Restauración." },
			emergencia = { pasos = {
				{ h = 17116, cuando = "{17116} y después {5185} instantáneo", c = {} },
				{ h = 18562, cuando = "{18562}", c = {} },
			}, nota = "" },
		} },
	},
}

M.JUGAR.HUNTER = {
	fuentes = {
		{ "Icy Veins, cazador en Classic", "https://www.icy-veins.com/wow-classic/hunter-dps-pve-guide", "sin fecha leída" },
		{ "Icy Veins, cazador para subir de nivel en Classic", "https://www.icy-veins.com/wow-classic/hunter-leveling-guide", "sin fecha leída" },
	},
	specs = {
		{ clave = "bestias", nombre = "Dominio de bestias", arbol = 1, rol = "daño", casos = {
			solo = { pasos = {
				{ h = 1130, cuando = "Al empezar: {1130}", c = { { "sinDebuff", 1130 } } },
				{ h = 13165, cuando = "A distancia con {13165} puesto", c = { { "sinBuff", 13165 } } },
				{ h = 1978, cuando = "Si va a vivir: {1978}", c = { { "sinDebuff", 1978 } } },
				{ h = 3044, cuando = "{3044} entre disparos automáticos", c = {} },
				{ h = 2973, cuando = "Si te alcanza: {2973}", c = {} },
				{ h = 136, cuando = "Mascota con poca vida: {136}", c = { { "mascota" } } },
			}, nota = "Que la mascota pegue primero 2-3 segundos: así no te quita el objetivo." },
			varios = { pasos = {
				{ h = 2643, cuando = "{2643} si están juntos", c = { { "enemigos>=", 2 } } },
				{ h = 13795, cuando = "{13795} donde vienen", c = {} },
				{ h = 1499, cuando = "Al sobrante: {1499}", c = {} },
				{ h = 3044, cuando = "{3044}", c = {} },
			}, nota = "La mascota aguanta a uno; tú controla al otro con {1499}." },
			mazmorra = { pasos = {
				{ h = 1130, cuando = "{1130} al objetivo marcado", c = { { "sinDebuff", 1130 } } },
				{ h = 19434, cuando = "Si lo tienes: {19434} entre disparos", c = {} },
				{ h = 2643, cuando = "{2643}", c = {} },
				{ h = 3044, cuando = "{3044}", c = {} },
				{ h = 5384, cuando = "Amenaza alta: {5384}", c = { { "amenaza>=", 90 } } },
			}, nota = "Pon a la mascota en modo pasivo o defensivo para que no tire grupos." },
			jcj = { pasos = {
				{ h = 3034, cuando = "Contra sanadores y lanzadores: {3034}", c = { { "sinDebuff", 3034 } } },
				{ h = 5116, cuando = "Si viene hacia ti: {5116}", c = {} },
				{ h = 1499, cuando = "Contra cuerpo a cuerpo: {1499} y te alejas", c = {} },
				{ h = 3044, cuando = "{3044}", c = {} },
				{ h = 2974, cuando = "Pegado a ti: {2974} y aléjate", c = { { "sinDebuff", 2974 } } },
			}, nota = "Mantén distancia: a menos de 8 metros no puedes disparar." },
			jefe = { pasos = {
				{ h = 3045, cuando = "Al principio: {3045}", c = {} },
				{ h = 19574, cuando = "Si lo tienes: {19574}", c = {} },
				{ h = 1130, cuando = "{1130}", c = { { "sinDebuff", 1130 } } },
				{ h = 19434, cuando = "{19434}", c = {} },
				{ h = 2643, cuando = "{2643}", c = {} },
			}, nota = "El disparo automático es la base: no lo cortes moviéndote." },
			emergencia = { pasos = {
				{ h = 5384, cuando = "{5384}", c = { { "vida<", 25 } } },
				{ h = 19263, cuando = "{19263}", c = { { "vida<", 35 } } },
				{ h = 5118, cuando = "Huir: {5118}", c = {} },
			}, nota = "" },
		} },
		{ clave = "punteria", nombre = "Puntería", arbol = 2, rol = "daño", usa = "bestias" },
		{ clave = "supervivencia", nombre = "Supervivencia", arbol = 3, rol = "daño", usa = "bestias" },
	},
}
