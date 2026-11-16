# Asistente 0.1 + buscador de servicios: cómo instalar y probar

16-11-2026. Sin instalar todavía.

## Qué hace
- Al entrar a **Orgrimmar**, **Cima del Trueno** o **Entrañas** se abre la ventana "Servicios de ...": banco, subasta, buzón, posada, maestro de vuelo, establos, reparar, instructores (tu clase primero) y vendedores.
- Clic en una fila → elige **el más cercano**, lo marca en el mapa y en el minimapa, y aparece una **flecha** arriba de la pantalla.
- Si tienes Polestar, la flecha te lleva **por el camino a pie** (rutas de Polestar Nav). Sin Polestar, apunta en línea recta y lo dice.
- A menos de 5 yardas dice "Llegaste" y quita las marcas. Clic derecho en la flecha la quita.
- Las filas de "Reparar" llevan `*`: se deduce del título del PNJ (vendedor de armas o armaduras). Puede fallar alguno.

## Comandos
| Comando | Qué hace |
|---|---|
| `/servicios` | abre la lista de la ciudad donde estás |
| `/servicios banco` | busca; si hay uno solo, la flecha te lleva directo. Sirve también: `alquimia`, `instructor de druida`, `reparar`, `vuelo`, `buzón`, `reactivos` |
| `/servicios parar` | quita la flecha y las marcas |
| `/servicios auto no` | que no se abra sola al entrar a una ciudad (`auto si` para volver) |
| `/asis` | ayuda y módulos · `/asis creditos`: de dónde viene cada dato |

Ejemplo útil para Hope en Orgrimmar: `/servicios druida` responde que el instructor de druida está en Cima del Trueno.

## Instalar (con el juego CERRADO)
Copiar estas dos carpetas a `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`:
- `WOW_FOREVER\addon\Asistente`
- `WOW_FOREVER\addon\Asistente_Servicios`

En la lista de addons salen juntas bajo "Asistente".

## Qué mirar en la primera prueba (NO VERIFICADO fuera del juego)
1. ¿Sale algún error en rojo al entrar a Orgrimmar?
2. ¿Se ven los iconos de cada fila? (rutas `Interface\Minimap\Tracking\...`)
3. ¿La flecha gira bien al caminar? (usa `GetPlayerFacing`; si Forever lo oculta, la flecha no aparece y solo se ve la distancia)
4. ¿La marca cae encima del banco en el mapa del mundo y en el minimapa?
5. Con Polestar: ¿la flecha dobla las esquinas en vez de ir en línea recta?

## Datos
forever-db 2026.11.1 (Polestar, GPL-3.0), build 1.60.1.70532. Para volver a generarlos:
```
cd WOW_FOREVER/generador
python -I servicios.py _descargas/polestar ../addon/Asistente_Servicios
```
Pruebas: `python -I addon/pruebas/test_servicios.py addon generador/_descargas/polestar` → 97 OK.
