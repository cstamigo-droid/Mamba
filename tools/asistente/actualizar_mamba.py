"""Mamba se actualiza sola cuando Polestar publica una versión (pedido de Cristian, 17-11 20:20: "que sea todo
automático, y que si falla nosotros metamos mano"). SIN Claude: lo lanza el Programador de tareas de Windows.

    python -I tools/asistente/actualizar_mamba.py                corrida normal (la de la tarea programada)
    python -I tools/asistente/actualizar_mamba.py --prueba --addons D:/rust/prueba_addons
        prueba de punta a punta sobre una carpeta de instalación de PRUEBA (los avisos dicen [PRUEBA])
    ... --forzar-fallo ETAPA     la etapa ETAPA falla a propósito (probar la alerta y que nada quede tocado)
    ... --sin-construir          salta la construcción (probar instalar con lo ya construido)
    ... --simular                ENSAYO: hace todo menos copiar; instalar_mamba.ps1 corre con -Simular contra el AddOns
                                 de verdad (solo lo lee) y deja el diff contra lo instalado en diff_vX.txt

Construye e instala por el MISMO camino que Mamba 1.0 (18-11 10:52): construir_noche.sh + compilar_addon.sh
(vía seguir_polestar.sh --construir), armar_instalar.py (ALCANCE: Horda, esMX y esES), control_zip.py --estricto e
instalar_mamba.ps1 (respaldo de lo que cambia + WTF y VOLVER_ATRAS.ps1). Las carpetas que ALCANCE apaga no se instalan.

Etapas, cada una con su criterio de éxito MEDIDO POR EFECTO (no por el código de salida):
  recuperar   si una corrida anterior murió a mitad de instalar (marca instalando.json, o el diario y las carpetas
              *.mamba_vieja del instalador anterior), vuelve a poner lo viejo con VOLVER_ATRAS.ps1 y avisa.
  versiones   última publicada (GitHub) contra la INSTALADA (Polestar.toc). Igual o más nueva → nada, sin aviso.
  fusion      seguir_polestar.sh --preparar vX: la etiqueta dentro de fusion/vX, registro LISTO y 0 pruebas falladas.
              Si vX ya está construida en la copia sobre el asistente de hoy (marca con el commit), se reusa.
  construir   seguir_polestar.sh --construir (~1,5 h): estado LISTO escrito DESPUÉS de empezar, compilar.log LISTO y
              guías regeneradas. Con forge o el juego ocupados: ESPERA (no es un fallo; la próxima corrida reintenta).
  controles   incluidos.py revisar: 0 errores.
  armar       armar_instalar.py → paquete propio de la tarea (no D:/rust/mamba_instalar, que usan las sesiones).
  control_zip control_zip.py --estricto con el manifiesto de esta construcción: "0 rechazos".
  simular     instalar_mamba.ps1 -Simular: qué copia y qué mueve; diff carpeta por carpeta contra lo instalado.
  instalar    (juego cerrado) instalar_mamba.ps1 con un respaldo propio; después se comprueba cada carpeta copiada
              contra el paquete (sha256), las movidas fuera y Polestar.toc con X-Mamba y la versión nueva. Si algo
              no cuadra se corre VOLVER_ATRAS.ps1 y se comprueba que lo instalado quedó como antes.
Avisos por Telegram (notificador de OLIMPO): "Mamba actualizada a vX" o "falló en <etapa>, registro en <ruta>".
Un mismo fallo se avisa una vez (y otra vez a las 24 h si sigue); un aviso que Telegram no aceptó se reintenta en la
corrida siguiente. Lo que necesita juicio (funciones nuevas, estética) NO frena: queda en polestar_versiones/vX.md.
Salida: 0 al día / actualizada / en espera · 1 falló · 3 otra corrida en curso.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
REPO = Path(r"C:\Users\<usuario>\Mamba")
FUSION = Path(r"C:\Users\<usuario>\Mamba-fusion")
ADDONS_REAL = Path(r"C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns")
WOW = Path(r"C:\Users\<usuario>\OneDrive\Escritorio\WOW_FOREVER")
BASH = r"C:\Program Files\Git\bin\bash.exe"
OLIMPO_ALERTAS = Path(r"C:\Users\<usuario>\OneDrive\Escritorio\OLIMPO\ALERTAS")
CONSTRUCCION_ESTADO = Path("D:/rust/noche/ESTADO.txt")
COMPILAR_LOG = Path("D:/rust/noche/compilar.log")
CERROJO = Path("D:/rust/actualizar/EN_CURSO")  # uno solo para la tarea y las pruebas: comparten Mamba-fusion
# La marca "vX ya construida" describe la copia Mamba-fusion, no una instalación: una sola para tarea y ensayos.
CONSTRUIDAS = Path("D:/rust/actualizar")
POWERSHELL = r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
RESPALDOS = Path("D:/rust/respaldos")
VIEJA, NUEVA = ".mamba_vieja", ".mamba_nueva"  # del instalador anterior (solo para recuperar restos)


class Espera(Exception):
    """No es un fallo: falta una condición (juego abierto, forge ocupado). La próxima corrida reintenta."""


class Fallo(Exception):
    pass


def huellas(raiz: Path):
    return {p.relative_to(raiz).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in raiz.rglob("*") if p.is_file()}


class Corrida:
    def __init__(self, a):
        self.a = a
        self.addons = Path(a.addons) if a.addons else ADDONS_REAL
        self.dir = Path(a.estado or ("D:/rust/actualizar_prueba" if a.prueba else "D:/rust/actualizar"))
        self.dir.mkdir(parents=True, exist_ok=True)
        self.log = self.dir / f"registro_{dt.datetime.now():%Y-%m-%d_%H%M}.log"
        self.diario = self.addons / "Mamba_instalando.json"  # diario del instalador anterior (restos)
        self.marca_inst = self.dir / "instalando.json"  # instalar_mamba.ps1 en curso: su respaldo y VOLVER_ATRAS
        self.paquete = self.dir / "paquete"
        self.manifiesto = self.dir / "manifiesto_paquete.json"
        self.wtf = Path(a.wtf) if a.wtf else None
        self.etapa = "inicio"
        self.tag = None
        self.instalada = None
        self.desde = None

    # ------------------------------------------------------------------ utilidades
    def anota(self, texto):
        linea = f"[{dt.datetime.now():%H:%M:%S}] {texto}"
        print(linea)
        with open(self.log, "a", encoding="utf-8") as f:
            f.write(linea + "\n")

    def corre(self, args, env=None):
        self.anota("$ " + " ".join(str(x) for x in args))
        r = subprocess.run(args, capture_output=True, env=env)
        salida = (r.stdout + r.stderr).decode("utf-8", errors="replace")
        with open(self.log, "a", encoding="utf-8") as f:
            f.write(salida + "\n")
        return r.returncode, salida

    def forzar(self, etapa):
        if self.a.forzar_fallo == etapa:
            if etapa == "limpiar":  # simula que el proceso MUERE (corte de luz): sin avisos ni limpieza propia
                self.anota("MUERTE SIMULADA durante la limpieza (prueba)")
                os._exit(9)
            raise Fallo(f"fallo forzado a propósito en «{etapa}» (prueba)")

    def escribir_diario(self, d):
        """De una sola vez: un corte a mitad no deja un diario roto (temporal + reemplazo atómico)."""
        tmp = self.diario.with_suffix(".tmp")
        tmp.write_text(json.dumps(d), encoding="utf-8")
        os.replace(tmp, self.diario)

    def mandar(self, texto) -> bool:
        if self.a.sin_aviso:
            self.anota("(sin aviso) " + texto)
            return True
        os.environ["OLIMPO_TG_REAL"] = "1"  # tarea programada: manda de verdad (OLIMPO/ALERTAS/notify.py)
        try:
            if str(OLIMPO_ALERTAS) not in sys.path:
                sys.path.insert(0, str(OLIMPO_ALERTAS))
            import notify  # noqa: E402
            ok = bool(notify.cristian(texto))  # devuelve False si Telegram no lo aceptó: NO lanza excepción
        except Exception as e:
            self.anota(f"error del notificador: {e}")
            ok = False
        self.anota(("AVISADO: " if ok else "NO PUDE AVISAR (se reintenta en la próxima corrida): ") + texto)
        return ok

    def avisar(self, texto, clave=None):
        """clave: el mismo fallo no se repite cada 2 h (sí a las 24 h). Lo que no salió queda en pendiente."""
        texto = ("[PRUEBA] " if self.a.prueba else "") + texto
        marcas = self.dir / "avisos.json"
        try:
            m = json.loads(marcas.read_text(encoding="utf-8"))
        except Exception:
            m = {}
        ahora = dt.datetime.now().timestamp()
        if clave and m.get(clave, 0) > ahora - 24 * 3600:
            self.anota(f"(aviso ya dado, no se repite) {texto}")
            return
        if self.mandar(texto):
            if clave:
                m[clave] = ahora
                marcas.write_text(json.dumps(m), encoding="utf-8")
        else:  # queda pendiente UNA vez por clave (sin Telegram un día entero no se juntan 12 iguales)
            pend = self.dir / "avisos_pendientes.json"
            try:
                d = json.loads(pend.read_text(encoding="utf-8"))
            except Exception:
                d = {}
            d[clave or texto] = texto
            pend.write_text(json.dumps(d, ensure_ascii=False), encoding="utf-8")

    def reintentar_avisos(self):
        p = self.dir / "avisos_pendientes.json"
        if not p.exists():
            return
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            d = {}
        quedan, marcas = {}, self.dir / "avisos.json"
        try:
            m = json.loads(marcas.read_text(encoding="utf-8"))
        except Exception:
            m = {}
        for k, t in d.items():
            if self.mandar(t):
                m[k] = dt.datetime.now().timestamp()  # ya dado: si el mismo fallo sigue, no sale dos veces
            else:
                quedan[k] = t
        marcas.write_text(json.dumps(m), encoding="utf-8")
        if quedan:
            p.write_text(json.dumps(quedan, ensure_ascii=False), encoding="utf-8")
        else:
            p.unlink()

    def estado(self, texto):
        (self.dir / "ESTADO.txt").write_text(f"{dt.datetime.now():%Y-%m-%d %H:%M} {texto}\n", encoding="utf-8")

    @staticmethod
    def corriendo(exe):
        r = subprocess.run(["tasklist", "/FI", f"IMAGENAME eq {exe}"], capture_output=True)
        if r.returncode != 0:  # si no se pudo mirar, se asume que SÍ corre (nunca instalar a ciegas)
            return True
        return exe.lower() in r.stdout.decode("utf-8", errors="replace").lower()

    def juego_abierto(self):
        return self.corriendo("Wow.exe") and not self.a.ignorar_juego

    # ------------------------------------------------------------------ etapas
    def recuperar(self):
        """Una corrida anterior murió a mitad de instalar: lo viejo vuelve a su lugar."""
        self.etapa = "recuperar"
        viejas = sorted(self.addons.glob("*" + VIEJA))
        nuevas = sorted(self.addons.glob("*" + NUEVA))
        cortada = self.marca_inst.exists()
        if not (viejas or nuevas or self.diario.exists() or cortada):
            return
        if self.a.simular:  # el ensayo no cambia nada: solo lo dice
            raise Fallo("hay una instalación cortada por recuperar; el ensayo no la toca (lo hace la corrida normal)")
        if self.juego_abierto():
            raise Espera("hay una instalación cortada para recuperar, pero el juego está abierto")
        if cortada:
            self.recuperar_cortada()
            if not (viejas or nuevas or self.diario.exists()):
                return
        if self.juego_abierto():
            raise Espera("hay una instalación cortada para recuperar, pero el juego está abierto")
        try:
            d = json.loads(self.diario.read_text(encoding="utf-8")) if self.diario.exists() else {}
        except Exception:
            d = {}
        errores = []
        if d.get("fase") == "limpiando":
            # La instalación ya estaba COMPROBADA completa y se cortó al borrar lo viejo: se termina hacia adelante.
            self.anota(f"TERMINANDO la limpieza de una instalación ya comprobada: {len(viejas)} carpetas viejas")
            for v in viejas:
                try:
                    shutil.rmtree(v)
                except Exception as e:
                    errores.append(f"{v.name}: {e}")
            for n in nuevas:
                shutil.rmtree(n, ignore_errors=True)
            if errores:  # la instalación está bien: no es un "falló"; se reintenta borrar en la próxima corrida
                self.anota("quedan copias viejas por borrar: " + "; ".join(errores[:5]))
                self.avisar("Mamba está instalada bien, pero no pude borrar copias viejas en AddOns (" + "; ".join(errores[:3])
                            + "). Bórralas a mano (carpetas que terminan en .mamba_vieja) con el juego cerrado.",
                            clave="restos_viejos")
                return
            self.diario.unlink(missing_ok=True)
            # el proceso que instaló murió antes de avisar: el aviso de éxito sale ahora (misma clave: no se repite)
            if d.get("tag"):
                self.avisar(f"Mamba actualizada a {d['tag']} (la corrida que instaló se cortó al final; ya quedó limpia).",
                            clave=f"exito_{d['tag']}")
            return
        self.anota(f"RECUPERANDO una instalación cortada: {len(viejas)} carpetas viejas, {len(nuevas)} a medio copiar")
        # las carpetas que la instalación cortada AGREGÓ (no existían antes) se quitan
        for c in d.get("agregadas", []):
            dst = self.addons / c
            if dst.is_dir() and not (self.addons / (c + VIEJA)).exists():
                try:
                    shutil.rmtree(dst)
                except Exception as e:
                    errores.append(f"{c}: {e}")
        for v in viejas:
            dst = self.addons / v.name[: -len(VIEJA)]
            try:
                if dst.exists():
                    shutil.rmtree(dst)
                v.rename(dst)
            except Exception as e:
                errores.append(f"{dst.name}: {e}")
        for n in nuevas:
            try:
                shutil.rmtree(n)
            except Exception as e:
                errores.append(f"{n.name}: {e}")
        if errores or list(self.addons.glob("*" + VIEJA)):
            raise Fallo("no pude recuperar la instalación cortada: " + "; ".join(errores[:5]))
        self.diario.unlink(missing_ok=True)
        self.avisar("Mamba: una actualización se había cortado a mitad de instalar. Volví a poner la versión "
                    "anterior completa. La próxima corrida intenta de nuevo.")

    def recuperar_cortada(self):
        """instalar_mamba.ps1 murió a mitad (corte de luz): VOLVER_ATRAS.ps1 de SU respaldo deja todo como antes."""
        try:
            m = json.loads(self.marca_inst.read_text(encoding="utf-8"))
        except Exception:
            m = {}
        volver = Path(m.get("respaldo", "")) / "VOLVER_ATRAS.ps1" if m.get("respaldo") else None
        if not (volver and volver.exists()):
            # murió antes de escribir VOLVER_ATRAS: el respaldo va ANTES de copiar, así que no se copió nada
            self.anota("instalación cortada antes de copiar (sin VOLVER_ATRAS): no hay nada que deshacer")
            self.marca_inst.unlink(missing_ok=True)
            return
        self.anota(f"RECUPERANDO una instalación cortada con {volver}")
        rc, salida = self.corre([POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(volver)])
        if rc != 0 or "Listo" not in salida:
            raise Fallo(f"no pude volver atrás la instalación cortada ({volver}, salida {rc})")
        self.marca_inst.unlink(missing_ok=True)
        self.avisar("Mamba: una actualización se había cortado a mitad de instalar. Volví a poner la versión "
                    f"anterior con {volver}. La próxima corrida intenta de nuevo.")

    def versiones(self):
        self.etapa = "versiones"
        sys.path.insert(0, str(AQUI / "generador"))
        import polestar_al_dia as v  # noqa: E402
        ultima = self.a.version or v.ultima_version()
        toc = self.addons / "Polestar" / "Polestar.toc"
        m = re.search(r"^## Version:\s*(\S+)", toc.read_text(encoding="utf-8", errors="replace"), re.M) if toc.exists() else None
        self.instalada = re.sub(r"-asistente.*$", "", m.group(1)) if m else None
        self.anota(f"última publicada {ultima} · instalada {self.instalada or 'ninguna'} · carpeta {self.addons}")
        if not self.instalada:
            raise Fallo(f"no encuentro Polestar instalado en {self.addons}")
        # Si lo instalado es Polestar OFICIAL (sin la marca X-Mamba en Polestar.toc: CurseForge o Polestar Client lo
        # reemplazaron, MAMBA.md), hay que poner Mamba aunque el número de versión sea el mismo.
        if "X-Mamba" not in toc.read_text(encoding="utf-8", errors="replace"):
            if (self.dir / f"instalada_v{self.instalada.lstrip('v')}").exists():
                # Mamba ya había instalado esta versión y algo la pisó con la oficial (CurseForge, Polestar Client):
                # no se pelea con él cada 2 horas. Se avisa una vez; lo arregla una persona.
                self.anota("Polestar oficial PISÓ a Mamba ya instalada: no se reinstala solo")
                self.avisar(f"Mamba: algo reemplazó Mamba {self.instalada} por el Polestar OFICIAL (casi seguro CurseForge o "
                            "Polestar Client). Desactiva las actualizaciones automáticas de Polestar ahí; después borra "
                            f"D:\\rust\\actualizar\\instalada_v{self.instalada.lstrip('v')} y Mamba se vuelve a instalar sola.",
                            clave=f"pisada_{self.instalada}")
                return None
            self.anota("lo instalado es Polestar OFICIAL (sin X-Mamba): se instala Mamba")
            return ultima if v.numeros(ultima) >= v.numeros(self.instalada) else None
        return ultima if v.numeros(ultima) > v.numeros(self.instalada) else None

    def marca_construida(self):
        return CONSTRUIDAS / f"construida_{self.tag}.json"

    def ya_construida(self):
        """Misma copia, limpia, y hecha sobre el asistente de HOY: si asistente avanzó (otra instalación a mano), se
        reconstruye; si no, reinstalaría una construcción vieja sin lo nuevo."""
        mc = self.marca_construida()
        if not mc.exists():
            return False
        head = subprocess.run(["git", "-C", str(FUSION), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
        limpio = not subprocess.run(["git", "-C", str(FUSION), "status", "--porcelain"], capture_output=True, text=True).stdout.strip()
        sobre_hoy = subprocess.run(["git", "-C", str(FUSION), "merge-base", "--is-ancestor", "asistente", "HEAD"]).returncode == 0
        d = json.loads(mc.read_text(encoding="utf-8"))
        if d.get("commit") == head and limpio and sobre_hoy and d.get("desde"):
            self.desde = d["desde"]
            return True
        return False

    def fusion(self):
        self.etapa = "fusion"
        self.forzar("fusion")
        _, salida = self.corre([BASH, str(AQUI / "seguir_polestar.sh"), "--preparar", self.tag])
        if "ESTADO: OCUPADO" in salida:
            raise Espera("otra corrida de seguir_polestar.sh está trabajando")
        rlog = Path("D:/rust/seguir") / f"fusion_{self.tag}.log"
        texto = rlog.read_text(encoding="utf-8", errors="replace") if rlog.exists() else ""
        dentro = subprocess.run(["git", "-C", str(FUSION), "merge-base", "--is-ancestor", self.tag, "HEAD"]).returncode == 0
        rama = subprocess.run(["git", "-C", str(FUSION), "branch", "--show-current"], capture_output=True, text=True).stdout.strip()
        fallas = re.findall(r"ℹ fail [1-9]|FALLAS [1-9]|^ALTO", texto, re.M)
        if not (dentro and rama == f"fusion/{self.tag}" and "LISTO:" in texto and not fallas
                and "ESTADO: FUSIONADA Y PROBADA" in salida):
            raise Fallo(f"la fusión no quedó: etiqueta dentro={dentro}, rama={rama}, LISTO={'LISTO:' in texto}, "
                        f"fallas={fallas[:3]} (registro {rlog})")

    def construir(self):
        self.etapa = "construir"
        self.forzar("construir")
        if self.a.sin_construir:
            self.anota("construcción saltada (--sin-construir)")
            return
        if self.corriendo("forge.exe"):
            raise Espera("forge.exe está corriendo (otra construcción)")
        if self.juego_abierto():
            raise Espera("el juego está abierto: forge lee el cliente y el lanzador podría actualizarlo a mitad")
        inicio = dt.datetime.now().timestamp()
        self.desde = dt.datetime.now().replace(microsecond=0).isoformat()  # armar_instalar: generados de ESTA construcción
        env = dict(os.environ)
        if self.a.ignorar_juego:  # solo en ensayos: forge solo LEE el cliente (construir_noche.sh, MAMBA_JUEGO_ABIERTO_OK)
            env["MAMBA_JUEGO_ABIERTO_OK"] = "1"
        _, salida = self.corre([BASH, str(AQUI / "seguir_polestar.sh"), "--construir"], env=env)
        if "ESTADO: OCUPADO" in salida:
            raise Espera("forge u otra corrida ocupados")
        est = CONSTRUCCION_ESTADO.read_text(encoding="utf-8", errors="replace") if CONSTRUCCION_ESTADO.exists() else ""
        if "NO CORRIÓ: el juego" in est:
            raise Espera("el juego se abrió antes de construir")
        nuevo = lambda p: p.exists() and p.stat().st_mtime > inicio  # noqa: E731
        guias = [p for p in (FUSION / "addon").glob("Polestar_Guides*/*.lua") if nuevo(p)]
        compilado = nuevo(COMPILAR_LOG) and COMPILAR_LOG.read_text(encoding="utf-8", errors="replace").rstrip().endswith("LISTO")
        if not (nuevo(CONSTRUCCION_ESTADO) and est.startswith("LISTO") and compilado and guias and "LISTA PARA INSTALAR" in salida):
            raise Fallo(f"la construcción no quedó: estado «{est.strip()[:80]}», compilado={compilado}, "
                        f"guías regeneradas={len(guias)} (registros en D:/rust/noche)")

    def controles(self):
        self.etapa = "controles"
        self.forzar("controles")
        _, salida = self.corre([sys.executable, "-I", str(FUSION / "tools/asistente/incluidos.py"), "revisar"])
        if not re.search(r"addons incluidos, 0 errores", salida):
            raise Fallo("un addon incluido no coincide con su huella: " + salida.strip()[-200:])

    def armar(self):
        """El mismo armado que la 1.0: ALCANCE (Horda, esMX y esES) y el manifiesto de esta construcción."""
        self.etapa = "armar"
        self.forzar("armar")
        args = [sys.executable, "-I", str(FUSION / "tools/asistente/armar_instalar.py"),
                "--dest", str(self.paquete), "--manifiesto", str(self.manifiesto)]
        if self.desde:
            args += ["--desde", self.desde]
        rc, salida = self.corre(args)
        m = re.search(r"^(\d+) carpetas en el armado", salida, re.M)
        if rc != 0 or not m or not (self.paquete / "Polestar" / "Polestar.toc").exists() or not self.manifiesto.exists():
            raise Fallo(f"el armado no quedó (salida {rc}): " + salida.strip()[-200:])
        # ALCANCE por efecto: ninguna carpeta apagada entró al paquete
        sys.path.insert(0, str(FUSION / "tools/asistente"))
        try:
            import armar_instalar as ai  # noqa: E402
            apagadas = {k for k, v in ai.ALCANCE.items() if not v}
        finally:
            sys.path.pop(0)
        dentro = sorted(apagadas & {p.name for p in self.paquete.iterdir() if p.is_dir()})
        if dentro:
            raise Fallo("el paquete trae carpetas que ALCANCE apaga: " + ", ".join(dentro))
        self.anota(f"paquete: {m.group(1)} carpetas en {self.paquete}; apagadas por ALCANCE: {len(apagadas)}")

    def control_zip(self):
        self.etapa = "control_zip"
        self.forzar("control_zip")
        rc, salida = self.corre([sys.executable, "-I", str(FUSION / "tools/asistente/control_zip.py"), str(self.paquete),
                                 "--manifiesto", str(self.manifiesto), "--estricto"])
        if rc != 0 or not re.search(r"^0 rechazos", salida, re.M):
            rech = [l for l in salida.splitlines() if l.startswith("RECHAZO")]
            raise Fallo(f"control_zip --estricto rechazó {len(rech)} archivos (p. ej. {rech[:2]})")

    def ps1(self, *extra):
        args = [POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                str(FUSION / "tools/asistente/instalar_mamba.ps1"), "-Paquete", str(self.paquete), "-AddOns", str(self.addons)]
        if self.wtf:
            args += ["-WTF", str(self.wtf)]
        if self.a.ignorar_juego:  # el .ps1 lo acepta solo con AddOns y WTF de prueba
            args += ["-IgnorarJuego"]
        return self.corre(args + list(extra))

    @staticmethod
    def lista(salida, nombre):
        m = re.search(rf"^{nombre}: ?(.*)$", salida, re.M)
        if not m:
            raise Fallo(f"instalar_mamba.ps1 no dijo {nombre}")
        return [x for x in m.group(1).strip().split("|") if x]

    def simular(self):
        """instalar_mamba.ps1 -Simular (solo lee) y el diff carpeta por carpeta contra lo instalado."""
        self.etapa = "simular"
        rc, salida = self.ps1("-Simular")
        if rc != 0 or "SIMULACI" not in salida:
            raise Fallo(f"instalar_mamba.ps1 -Simular no terminó (salida {rc}): " + salida.strip()[-200:])
        copiar, mover = self.lista(salida, "LISTA_COPIAR"), self.lista(salida, "LISTA_MOVER")
        if "Polestar" not in copiar:
            raise Fallo("la simulación no copiaría Polestar")
        filas, iguales = [], 0
        for c in copiar:
            nueva = huellas(self.paquete / c)
            vieja = huellas(self.addons / c) if (self.addons / c).is_dir() else None
            if vieja is None:
                filas.append(f"NUEVA     {c} ({len(nueva)} archivos)")
            elif nueva == vieja:
                iguales += 1
                filas.append(f"igual     {c}")
            else:
                cambian = sorted(k for k in nueva if k in vieja and nueva[k] != vieja[k])
                filas.append(f"CAMBIA    {c}: {len(cambian)} archivos cambian, {len(set(nueva) - set(vieja))} nuevos, "
                             f"{len(set(vieja) - set(nueva))} se van")
                filas += [f"            ~ {k}" for k in cambian[:15]]
        filas += [f"SE MUEVE  {c} (al respaldo)" for c in mover]
        tocs = {}
        for lado, raiz in (("instalada", self.addons), ("paquete", self.paquete)):
            t = raiz / "Polestar" / "Polestar.toc"
            texto = t.read_text(encoding="utf-8", errors="replace") if t.exists() else ""
            v = re.search(r"^## Version:\s*(\S+)", texto, re.M)
            tocs[lado] = f"{v.group(1) if v else '?'}{' con X-Mamba' if 'X-Mamba' in texto else ' SIN X-Mamba'}"
        resumen = (f"Polestar instalada {tocs['instalada']} -> paquete {tocs['paquete']}. Copiaría {len(copiar)} carpetas "
                   f"({len(copiar) - iguales} cambian o son nuevas, {iguales} iguales) y movería {len(mover)} al respaldo.")
        diff = self.dir / f"diff_{self.tag}.txt"
        diff.write_text(resumen + "\n\n" + "\n".join(filas) + "\n\n--- instalar_mamba.ps1 -Simular ---\n" + salida,
                        encoding="utf-8")
        self.anota(resumen + f" Diff: {diff}")
        return copiar, mover, resumen

    def instalar(self, copiar, mover):
        self.etapa = "instalar"
        base = self.dir / "respaldos" if self.a.prueba else RESPALDOS
        respaldo = base / f"mamba_auto_{self.tag}_{dt.datetime.now():%Y-%m-%d_%H%M%S}"
        antes = self.instaladas(copiar + mover)
        self.marca_inst.write_text(json.dumps({"tag": self.tag, "respaldo": str(respaldo),
                                               "inicio": dt.datetime.now().isoformat()}), encoding="utf-8")
        if self.juego_abierto():  # justo antes de copiar (instalar_mamba.ps1 lo vuelve a mirar dos veces)
            self.marca_inst.unlink(missing_ok=True)
            raise Espera("el juego está abierto: se instala en la próxima corrida con el juego cerrado")
        rc, salida = self.ps1("-Respaldo", str(respaldo))
        try:
            if "NO SE INSTALA: Wow.exe" in salida or "durante el respaldo" in salida:
                if self.instaladas(copiar + mover) != antes:
                    raise Fallo("el juego se abrió y lo instalado cambió igual")
                raise Espera("el juego se abrió justo antes de copiar: no se copió nada")
            if rc != 0 or "INSTALADO." not in salida:
                raise Fallo(f"instalar_mamba.ps1 no terminó (salida {rc}): " + salida.strip()[-200:])
            self.forzar("instalar")  # cae DESPUÉS de copiar: prueba la vuelta atrás con VOLVER_ATRAS.ps1
            for c in copiar:
                if huellas(self.addons / c) != huellas(self.paquete / c):
                    raise Fallo(f"{c} instalada no coincide con el paquete")
            for c in mover:
                if (self.addons / c).exists():
                    raise Fallo(f"{c} debía ir al respaldo y sigue en AddOns")
            toc = (self.addons / "Polestar" / "Polestar.toc").read_text(encoding="utf-8", errors="replace")
            if "X-Mamba" not in toc:
                raise Fallo("después de instalar, Polestar.toc no tiene la marca X-Mamba")
            if not re.search(rf"^## Version:\s*{re.escape(self.tag.lstrip('v'))}(\s|$)", toc, re.M):
                raise Fallo("después de instalar, Polestar.toc no dice la versión nueva")
        except Espera:
            self.marca_inst.unlink(missing_ok=True)
            raise
        except Exception as e:
            volver = respaldo / "VOLVER_ATRAS.ps1"
            if volver.exists() and self.instaladas(copiar + mover) != antes:
                self.anota(f"VUELTA ATRÁS con {volver}")
                rcv, sv = self.corre([POWERSHELL, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(volver)])
                if rcv != 0 or "Listo" not in sv:
                    raise Fallo(f"{e}; y VOLVER_ATRAS.ps1 también falló (salida {rcv}): queda marcada para recuperar") from e
            self.marca_inst.unlink(missing_ok=True)
            raise
        self.marca_inst.unlink(missing_ok=True)
        # se guardan solo los 5 respaldos automáticos más nuevos (cada uno ~120 MB con la WTF)
        for viejo in sorted(respaldo.parent.glob("mamba_auto_*"), key=lambda p: p.stat().st_mtime)[:-5]:
            shutil.rmtree(viejo, ignore_errors=True)
        self.anota(f"instalada {self.tag}: {len(copiar)} carpetas comprobadas; respaldo y VOLVER_ATRAS en {respaldo}")
        return respaldo

    def instaladas(self, carpetas):
        return {c: huellas(self.addons / c) for c in carpetas if (self.addons / c).is_dir()}

    # ------------------------------------------------------------------ corrida
    def ejecutar(self):
        antes = None
        try:
            self.reintentar_avisos()
            self.recuperar()
            self.tag = self.versiones()
            if not self.tag:
                self.estado("AL DÍA")
                self.anota("AL DÍA: nada que hacer")
                return 0
            if self.ya_construida():
                self.anota(f"{self.tag} ya está fusionada y construida en la copia sobre el asistente de hoy: se reusa")
            else:
                self.fusion()
                self.construir()
                if not self.a.sin_construir:
                    head = subprocess.run(["git", "-C", str(FUSION), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
                    self.marca_construida().write_text(json.dumps({"commit": head, "desde": self.desde}), encoding="utf-8")
            self.controles()
            self.armar()
            self.control_zip()
            copiar, mover, resumen = self.simular()
            if self.a.simular:
                self.estado(f"ENSAYO OK ({self.tag}): {resumen}")
                self.anota("ENSAYO OK: no se copió nada")
                return 0
            if self.juego_abierto():
                self.etapa = "instalar"
                raise Espera("el juego está abierto: se instala en la próxima corrida con el juego cerrado")
            antes = self.instaladas(copiar + mover)
            respaldo = self.instalar(copiar, mover)
            (self.dir / f"instalada_{self.tag}").write_text(dt.datetime.now().isoformat(), encoding="utf-8")
            self.estado(f"ACTUALIZADA a {self.tag}")
            self.avisar(f"Mamba actualizada a {self.tag} ({len(copiar)} carpetas"
                        + (f", {len(mover)} movidas al respaldo" if mover else "")
                        + f"). Si algo anda mal, con el juego cerrado: {respaldo}\\VOLVER_ATRAS.ps1. Lo nuevo de Polestar "
                          f"queda para mirar con calma en polestar_versiones/{self.tag}.md.", clave=f"exito_{self.tag}")
            return 0
        except Espera as e:
            self.estado(f"EN ESPERA ({self.tag}): {e}")
            self.anota(f"EN ESPERA: {e}")
            if self.tag and self.etapa == "instalar":
                self.avisar(f"Mamba {self.tag} está lista para instalarse. Se instala sola en la próxima revisión "
                            f"(cada 2 horas) con el juego cerrado.", clave=f"espera_{self.tag}")
            return 0
        except Exception as e:
            if antes is not None:
                intacto = (" Lo instalado quedó como estaba." if self.instaladas(list(antes)) == antes
                           else " ⚠️ OJO: lo instalado NO quedó igual que antes; la próxima corrida intenta recuperarlo.")
            else:
                intacto = " No se tocó lo instalado."
            self.estado(f"FALLÓ en {self.etapa} ({self.tag}): {e}")
            self.anota(f"FALLÓ en {self.etapa}: {e}")
            self.avisar(f"Mamba {self.tag or ''}: falló en «{self.etapa}». {e}.{intacto} Registro: {self.log}",
                        clave=f"fallo_{self.tag}_{self.etapa}_{str(e)[:60]}")
            return 1


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser()
    p.add_argument("--addons", help="carpeta AddOns (por defecto la del juego)")
    p.add_argument("--estado", help="carpeta de registros y estado")
    p.add_argument("--version", help="tratar esta etiqueta como la última publicada (pruebas)")
    p.add_argument("--prueba", action="store_true", help="avisos marcados [PRUEBA]; respaldo en la carpeta de estado")
    p.add_argument("--forzar-fallo", choices=["fusion", "construir", "controles", "armar", "control_zip", "instalar"])
    p.add_argument("--sin-construir", action="store_true")
    p.add_argument("--sin-aviso", action="store_true", help="no mandar Telegram (solo registro)")
    p.add_argument("--ignorar-juego", action="store_true",
                   help="solo en pruebas: construir (forge solo lee el cliente) e instalar en la carpeta de prueba con el juego abierto")
    p.add_argument("--simular", action="store_true", help="ensayo: todo menos copiar (instalar_mamba.ps1 -Simular)")
    p.add_argument("--wtf", help="carpeta WTF de prueba (obligatoria con --addons de prueba sin --simular)")
    a = p.parse_args()
    if (a.ignorar_juego or a.forzar_fallo or a.sin_construir) and not (a.prueba and (a.addons or a.simular)):
        p.error("--ignorar-juego, --forzar-fallo y --sin-construir solo valen con --prueba y (--simular o una carpeta --addons de prueba)")
    if a.prueba and not a.simular and not (a.addons and a.wtf):
        p.error("--prueba sin --simular necesita --addons y --wtf de prueba (VOLVER_ATRAS.ps1 restaura la WTF)")
    if a.forzar_fallo == "instalar" and a.simular:
        p.error("--forzar-fallo instalar necesita instalar de verdad en una carpeta de prueba (sin --simular)")
    CERROJO.parent.mkdir(parents=True, exist_ok=True)
    if CERROJO.exists():  # de una corrida que murió (corte de luz): su proceso ya no existe, o pasaron 8 h
        m = re.search(r"pid (\d+)", CERROJO.read_text(encoding="utf-8", errors="replace"))
        vivo = False
        if m:
            r = subprocess.run(["tasklist", "/FI", f"PID eq {m.group(1)}"], capture_output=True)
            vivo = r.returncode != 0 or f" {m.group(1)} " in r.stdout.decode("utf-8", errors="replace")
        if not vivo or dt.datetime.now().timestamp() - CERROJO.stat().st_mtime > 8 * 3600:
            CERROJO.unlink(missing_ok=True)
    try:
        fd = os.open(CERROJO, os.O_CREAT | os.O_EXCL | os.O_WRONLY)  # crear-si-no-existe en un solo paso
    except FileExistsError:
        print("OCUPADO: otra corrida en curso desde", CERROJO.read_text(encoding="utf-8", errors="replace"))
        return 3
    os.write(fd, f"{dt.datetime.now():%Y-%m-%d %H:%M} pid {os.getpid()}".encode())
    os.close(fd)
    try:
        return Corrida(a).ejecutar()
    finally:
        CERROJO.unlink(missing_ok=True)


if __name__ == "__main__":
    sys.exit(main())
