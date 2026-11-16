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
