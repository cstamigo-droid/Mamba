# Tasador 0.2: tu primer módulo del addon propio

## Qué hace
1. **Al pasar el ratón sobre cualquier objeto**, te dice:
   - **Qué hacer:** *Subastar*, *Vender al vendedor*, *Guardar*, *Sin valor: puedes botarlo* o *Revisa la subasta*.
   - **Por qué**, con cuánto te queda en la subasta después de la comisión y cuánto paga el vendedor.
   - Si es **equipo**: si es *Caro*, *Vale la pena* o *Barato* comparado con lo que paga el vendedor.
   - **Si es una MEJORA** para ti, comparado con lo que llevas puesto, según tu rol (Equilibrio, Restauración o Feral). También te dice si no lo puedes usar (por ejemplo, placas o mallas) o si te sirve recién a cierto nivel.
2. **`/tasador`**: revisa todas tus bolsas y las agrupa en qué subastar, qué vender y qué guardar, con el total en oro.
3. **`/tasador baratos`**: los materiales que **hoy** están más baratos que su precio normal de los últimos días (para comprar y fabricar, o para revender).
4. **`/tasador hierbas`**: las hierbas que más pagan hoy, por unidad y por montón de 20. Te sirve para elegir qué farmear con Herboristería.
5. **Alerta de enemigos**: cuando un jugador de la **Alianza** al que puedes atacar aparece cerca, sale un aviso grande en pantalla con sonido y queda escrito en el chat. Dice su nombre, nivel y clase, y marca **PELIGRO** si es 3 niveles o más que tú o si su nivel es "??". Avisa una sola vez por jugador cada minuto, y el sonido suena como mucho una vez cada 10 segundos. Se apaga dentro de mazmorras, bandas y campos de batalla.

## Lo que necesitas
- **Auctionator** (ya lo tienes). De él salen los precios de la subasta. **Abre la casa de subastas y haz un escaneo completo** con Auctionator de vez en cuando; para "baratos" hacen falta al menos 3 días con escaneo.
- **Placas de nombre de enemigos encendidas** (tecla **V** o Mayús+V), para que la alerta detecte a los enemigos de lejos. Sin placas, avisa solo cuando les pasas el ratón o los seleccionas.

## Comandos
| Comando | Para qué |
|---|---|
| `/tasador` o `/tas` | Revisar tus bolsas |
| `/tasador baratos` | Materiales baratos hoy |
| `/tasador hierbas` | Hierbas que más pagan |
| `/tasador rol sanacion` (o `equilibrio`, `feral`, `auto`) | Con qué rol comparar equipo. `auto` = la rama de talentos donde tienes más puntos (la lee de la ventana de talentos de Forever) |
| `/tasador alerta si` / `no` | Encender o apagar la alerta de enemigos |
| `/tasador comision 5` | Comisión de la subasta en % |
| `/tasador ayuda` | Ver esta lista |

## Cambios de la versión 0.2 (16-11-2026)
- La ganancia mínima de 20 de plata para subastar se mide **por montón** (antes por unidad: mandaba a vender materiales que sí convenía subastar).
- El rol automático lee los **talentos de Forever** (antes no funcionaba).
- La comparación de equipo cuenta las bonificaciones **"Equipar:"** (sanación, daño de hechizos, maná cada 5 s, crítico, golpe). Si una pieza tiene un efecto que no sabe medir, **no dice "MEJORA"**: te pide compararlo tú.
- Si llevas un **arma de dos manos**, un objeto de mano izquierda ya no dice "póntelo". Las armas de mano izquierda salen como "no lo puedes usar".
- Las **mejoras** y las **herramientas** (pico, caña de pescar...) salen como "Guardar".
- Un objeto que **ya está ligado** a ti no se manda a subastar.
- Los objetos con **sufijo** ("del Oso"...) no usan el precio de otra versión.
- "Baratos" y "hierbas" usan solo precios de **hoy o ayer** y muestran **cuántos hay a la venta**. Revisan la subasta por partes para no trabar el juego.

## Lo que NO hace (a propósito)
- **No vende, no compra, no equipa ni ataca por ti.** Solo te aconseja. Automatizar el juego va contra las reglas de Blizzard.
- **No adivina precios:** si nunca se escaneó un objeto en la subasta, te dice "Revisa la subasta" en vez de inventar un número.

## Cosas que todavía no están confirmadas (por eso son ajustables)
- La comisión de la subasta en Forever: puse 5 %, como en el WoW clásico. NO VERIFICADO para Forever; cámbiala con `/tasador comision` si ves otra cifra.
- Los pesos para comparar equipo vienen de Polestar y wowsims (créditos dentro de `Mejora.lua`). Son una buena guía, no una verdad absoluta.

## Cómo se instaló
La carpeta `Tasador` se copia en
`C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\Tasador`.
Después hay que **cerrar el juego por completo y volver a abrirlo**: un `/reload` no carga carpetas nuevas.
En la lista de accesorios aparece como **Tasador**.

## Próximos módulos (lo que pediste y viene después)
- **Qué farmear para ganar oro**: cruzar los precios de hoy con **dónde cae** cada material y **de quién** (con % de caída), y calcular **oro por hora** aproximado.
- **Acompañante**: un panel que te diga el siguiente paso (misión, farmear, vender, aprender en el instructor), usando las guías que ya trae Polestar.
- **Comprar para fabricar**: qué recetas tuyas (Alquimia, Cocina, Primeros auxilios) dejan ganancia con los precios de hoy.

## Pruebas
`addon\pruebas\test_tasador.py` prueba las reglas, la comparación de equipo, el mercado, la alerta y los comandos con Lua 5.1 (la versión del juego), simulando el juego. **No reemplaza probarlo dentro del juego**: la primera vez que lo uses, mira si aparece algún error en rojo.

## 0.3.0 (16-11-2026): escaneo de subasta PROPIO
- Ya no hace falta Auctionator (que es de licencia cerrada). En la casa de subastas aparece el botón **"Escanear (Tasador)"**: un clic y lee todos los precios. Solo lee: no compra, no vende, no publica.
- El juego permite un escaneo completo cada 15 minutos.
- El cuadro de cada objeto usa el precio desde el primer escaneo. `/tasador baratos` y `/tasador hierbas` necesitan 3 días distintos de escaneo.
- Si también tienes Auctionator, gana el precio más reciente de los dos (detalle en `ARQUITECTURA.md` §7).
- Respaldo de la 0.2: `respaldos/Tasador_0.2.0_2026-11-16/`. Pruebas: `python -I pruebas/test_escaneo.py Tasador` (37 OK) y `test_tasador.py` (118 OK).

## 0.4.0 (18-11-2026): el comerciante
Pedido de Cristian (17-11): que el addon mire la subasta y diga **cómo ganar oro comerciando**: qué es caro, cuándo vender y a cuánto, y qué comprar para revender.

**Solo aconseja.** Cada compra y cada publicación las haces tú, con tu clic, en la ventana de subasta del juego. Una prueba automática comprueba que el addon no llama a ninguna función de comprar, publicar ni cancelar.

### Comandos nuevos
| Comando | Qué te dice |
|---|---|
| `/tasador op` | Ventana **Oportunidades**, ordenada por ganancia, con pestañas: Todo, Reventa, Al PNJ, Vender lo tuyo y Fabricar. Pasa el ratón por una fila para ver el detalle |
| `/tasador reventa` | Qué comprar barato para revender: hasta qué precio comprar, cuántas, a cuánto revender, y la ganancia en oro y en % |
| `/tasador pnj` | Subastas más baratas que lo que paga el vendedor (PNJ): las compras y se las vendes a él |
| `/tasador vender` | Para cada cosa de tus bolsas: a cuánto publicarla, cuántas por día y si es **VENDE YA**, **vende**, **espera**, **al vendedor** o **no lo publiques** |
| `/tasador fabricar` | Qué recetas tuyas dejan ganancia hoy. Antes abre **una vez** la ventana de cada profesión (Alquimia, Cocina, Primeros auxilios): el addon anota tus recetas. Si pasas por un vendedor de viales o especias, anota sus precios |
| `/tasador eventos` | Mide si las bandas del 9-12 suben el precio de hierbas y consumibles. Es una hipótesis: el addon la mide, no la da por cierta |
| `/tasador deposito 15` · `/tasador duracion 24` | Ajustes del depósito supuesto y de la duración de tus publicaciones |

### Cada cuánto escanear
- **Cada 1 a 4 horas mientras juegas**, con el botón "Escanear (Tasador)" en la casa de subastas. El juego permite uno cada 15 minutos.
- El addon compara cada escaneo con el anterior. Lo que desaparece antes de vencer casi siempre se vendió, y así mide **cuánto se vende de cada cosa al día**.
- Con más de **8 horas** entre dos escaneos no se puede medir nada (todo pudo vencer). El escaneo igual sirve para los precios.
- **Para comprar**, el escaneo tiene que ser de hace **60 minutos o menos**: los precios cambian rápido.
- Si puedes, escanea a **horas distintas** (mañana, tarde y noche). Solo mide las horas en que escaneas.

### Qué te va a decir la primera semana (y qué no)
| Días con escaneo | Lo que ya sirve | Lo que todavía NO |
|---|---|---|
| Día 1 | Precio de hoy de cada cosa (mínimo y el del 20 % más barato), **reventa al PNJ**, y "vende" con el precio de hoy | Ventas por día, reventa y "espera" |
| Tras unas 12 horas de escaneos repartidos | **Ventas por día** de lo que más se mueve (el addon usa un límite bajo, por prudencia) | Si un precio sube o baja |
| Día 4 | **Tendencia** (bajando o subiendo), "vende ya", "espera" y **reventa** | Saber si una tendencia sigue mañana: es un dato, no una predicción |
| Día 7 | Un precio "normal" de una semana | Si un patrón se repite cada semana: hacen falta varias semanas |

**Lo que una semana NO te puede decir**, y por qué:
- **Si lo que viste se repite.** En una semana, una racha puede ser suerte, igual que en el trading: pocas observaciones no hacen una ventaja. Los precios de Forever vienen cayendo desde el lanzamiento (ORO.md: los materiales bajaron a la mitad en la primera semana).
- **Cuánto exacto se vende.** El addon ve lo que **desaparece**: una cancelación del más barato o **tus propias compras** también cuentan. Por eso usa el límite bajo y no compra más de lo que se vende en un día.
- **El efecto de las bandas (9-12).** Recién **una semana después** del 9-12 hay datos de antes y de después. Aun así es una sola semana: una pista, no una regla.

### Las cuentas (para que sepas qué hay detrás de cada número)
- **Reventa.** Ganancia = lo que cobras tras la comisión − lo que pagas − el depósito que puedes perder si no se vende − un 8 % por cada día de espera (por si el precio baja).
  - Solo aparece con todo esto a la vez: margen de 10 % o más, 1 oro o más, 5 ventas o más por día (límite bajo), 4 días de historia, precio que no viene bajando, y que se venda en 2 días o menos.
  - El precio de reventa es el **más bajo** de tres: el normal de los días anteriores, el de lo que se vendió y el del 20 % más barato que queda hoy.
- **"Vende ya"**: el precio bajó 10 % o más en los últimos días (contando la tendencia de todos los días, no uno suelto).
- **"Espera"**: unos pocos rematan muy barato, pero la mayoría sigue a precio normal y el precio no viene bajando. Si todo el mercado de hoy está más bajo, el addon dice **"vende"**: ese es el precio nuevo.
- **"Al vendedor"**: la subasta, después de la comisión y del depósito, no deja al menos 1,5 veces lo que paga el PNJ.
- **"No lo publiques"**: con lo que hay delante y lo poco que se vende, perderías más en depósitos de lo que cobras.

### NO VERIFICADO en Forever (todo se puede ajustar)
- Comisión 5 % (`/tasador comision`).
- Depósito: supuesto de 15 % de lo que paga el vendedor por cada 12 h, mínimo 1 plata (`/tasador deposito`). Si la subasta del juego sabe calcularlo, el addon usa el del juego.
- Duraciones de publicación (`/tasador duracion`).
- Cuánto tiempo le queda a una subasta en cada tramo (se usa el límite más corto conocido).
- Si Forever usa la subasta moderna o la antigua (el addon funciona con las dos).
- Si la subasta se comparte con la Alianza.

### Pruebas
`tools/asistente/pruebas/test_comercio.py`: 138 pruebas con Lua 5.1, más `test_escaneo.py` (37) y `test_tasador.py` (118). Incluye:
- la simulación de subastas que desaparecen (ventas, cancelaciones, republicar a otro precio y dueño desconocido);
- la prueba de que nada compra ni publica sin tu clic, con su control positivo.

La tarea automática `Mamba_Actualizar` corre estas pruebas en cada versión nueva de Polestar. Criterios de aceptación versionados: `WOW_FOREVER/addon/TASADOR_0.4_CRITERIOS.md`.
