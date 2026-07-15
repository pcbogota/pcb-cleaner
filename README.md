# <img src="https://raw.githubusercontent.com/pcbogota/pcb-cleaner/refs/heads/main/Assets/Common/icon/PCBCleaner.ico" alt="PCB Cleaner Icon" style="width: 40px; "> PCBogota Clean Script v1.1.1

Script de limpieza y mantenimiento para Windows 10 / 11 que integra BleachBit Portable, reglas `winapp2.ini` y comandos nativos del sistema (DISM, CompactOS, vaciado de cachés, desactivación de hibernación, etc.).
Incluye un **instalador creado con Inno Setup** que permite programar la limpieza automática al inicio de sesión.

## Características principales

- Limpieza profunda del sistema sin afectar datos personales de usuario.
- Cierre automático de Google Chrome para liberar su caché (sin borrar perfiles).
- Integración con BleachBit Portable usando una configuración predefinida (`.ini`).
- Descarga y aplicación de `winapp2.ini` (reglas de limpieza de la comunidad).
- Eliminación de caché de Windows Update
- Eliminación de repostes de errores de Windows
- Comandos nativos:
  - `DISM /StartComponentCleanup /ResetBase`
  - `compact /compactos:always`
  - `powercfg /h off`
  - `cleanmgr /sagerun:999`
  - `Clear-RecycleBin`
- Medición del espacio liberado paso a paso.
- Ejecución manual mediante acceso directo en escritorio / menú inicio.
- Instalación con opciones para:
  - Creación de tarea programada al iniciar sesión.
  - Forzar deshabilitar hibernación en caso de requerirse

## Ejecución del script de limpieza luego de instalar

### ▶️ Ejecución manual

- Acceso directo: Una vez instalado el programa, aparecen dos accesos directos:
  - `Limpieza Manual` en el menú inicio.
  - `Limpieza Manual` en el escritorio.

Ambos apuntan a `Limpiar.cmd`, que solicita elevación de permisos y lanza el script de PowerShell.

### ⏰ Tarea programada automática

- Durante la instalación, si marcas la opción _"Programar limpieza automática al inicio de sesión"_, se creará una tarea en el **Programador de tareas de Windows** con nombre `PCB_Limpieza De Windows`.
- La tarea ejecuta el script cada vez que **cualquier usuario inicia sesión**, con privilegios de administrador.
- Puedes deshabilitar o modificar la tarea desde `taskschd.msc`.

### ⌨️ Ejecución por línea de comandos

#### Símbolo de sistema

```cmd
"C:\Program Files\PCBogota Cleaner Script\Limpiar.cmd"
```

#### Powershell

```
$file = "C:\Program Files\PCBogota Cleaner Script\CleanTemps.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $file
```

> 🔐 PowerShell debe ejecutarse como administrador y con la política de ejecución de scripts adecuada (el propio `Limpiar.cmd` ya se encarga de ello).

### 🖥️ Configuración manual de BleachBit (si deseas cambiar la selección)

Si quieres modificar qué elementos limpia BleachBit, sigue estos pasos antes de compilar el instalador o directamente en el equipo destino:

1. Ejecuta `BleachBit.exe` (portable) desde la carpeta `BleachBit-portable\`.
1. Al **icono de la parte superior izquierda de BleachBit** da click y selecciona `Preferencias`:
   - **Activa**: _Descargar y actualizar los limpiadores de la comunidad (winapp2.ini)_
   - **Desactiva**: _Ocultar los limpiadores irrelevantes_
1. Cierra y vuelve a abrir BleachBit.
1. Verifica que el archivo `BleachBit-portable\cleaners\winapp2.ini` exista.
1. Comenta las líneas con `FileExts` (puedes usar un editor de texto. El script lo hace automáticamente **UNICAMENTE** al instalar).
1. Selecciona las casillas de los limpiadores que deseas (recuerda **no marcar nada de Google Chrome** si quieres conservar sesiones y cookies).
1. Cierra BleachBit.
   La selección se guardará en `BleachBit.ini` y será usada por el script cuando ejecute `bleachbit_console.exe --preset --clean`.

---

## 📦 Requisitos previos para compilar el instalador

(No requerido para ejecución)

- [Inno Setup](https://jrsoftware.org/isdl.php) (versión 6 o superior)
- [BleachBit portable (.zip)](https://www.bleachbit.org/download/windows) (versión 6.0.0 o compatible)
- Opcional (para generar assets gráficos):
  - [InkScape](https://inkscape.app/es/descargar/) – para editar archivos `.svg`
  - [GIMP](https://www.gimp.org/downloads/)– para generar el icono `.ico`

> ⚠️ Los binarios de BleachBit no se incluyen en el repositorio por licencia y tamaño. La instalación se realiza automáticamente si el computador está conectado a internet

---

### ⚠️ Nota importante sobre SmartScreen

Al ejecutar el instalador generado, Windows puede mostrar una advertencia de "**editor desconocido**" (SmartScreen).
Verifica que el instalador haya sido descargado desde el [repositorio oficial de PCBogota](https://www.github.com/pcbogota/pcb-cleaner) y permite su ejecución.

---

## 🛠️ Preparación previa a la compilación (assets gráficos)

El script de Inno Setup `(.iss)` espera imágenes en formatos específicos (`.png` multipíxel e .ico).
Si no dispones de ellas, puedes generarlas a partir de los archivos fuente incluidos en `src/`:

- `src/icon/SVG_icon.svg` → genera el icono `PCBCleaner.ico` (múltiples resoluciones).
- `src/wizard branding/SVG_branding.svg` → genera las imágenes:
  - `WizardImage` (lateral izquierdo del asistente)
  - `WizardSmallImage` (esquina superior derecha)

Los archivos resultantes deben colocarse en `installer/assets/` con la nomenclatura que usa el `installer.iss` (ej. `png_WizardImage_dpi-100.png` …).
Revisa la directiva `#define MultiImage` en el script para ver los nombres esperados.

### 📦 Compilación del instalador

1. Asegúrate que los archivos requeridos se listan en el archivo de instalación y existen en el dispositivo.
1. Abre `installer\installer.iss` con Inno Setup.
1. Ve al menú **Build** > **Compile** (o presiona `Ctrl+B`).

El instalador se generará en la carpeta `output\` con el nombre `Setup PCBogota Cleaner Script v1.1.0.exe` (la versión pude cambiar).

#### 💡 Personalización de la tarea programada

El instalador registra una tarea que ejecuta el script al **iniciar sesión**.
Si deseas modificar su comportamiento (horario, condiciones, etc.), edita la variable `$xml` dentro del archivo `cleaner-install.psm1` (función `New-CleanerScheduledTask`).

---

## 📄 Archivos de configuración (`.ini`)

El script de Powershell `CleanTemps.ps1` genera automáticamente dos archivos durante la instalación (`Start-BasicClean.ps1 -install`):

### `BleachBit.ini`

- **Ubicación**: `{app}\BleachBit-portable\BleachBit.ini`
- **Propósito**: Define qué limpiadores ejecuta BleachBit en modo consola (`--preset`).
- **Modificaciones aplicadas por el script**:
  - Desactiva actualizaciones automáticas del programa y de `winapp2.ini`.
  - Activa todos los limpiadores excepto:
    - `google chrome` (para no borrar cookies/sesiones)
    - `chromium`

### `winapp2.ini`

- **Ubicación**: `{app}\BleachBit-portable\cleaners\winapp2.ini`
- **Origen**: Descargado automáticamente desde [MoscaDotTo/Winapp2](https://github.com/MoscaDotTo/Winapp2)
- **Modificación aplicada**:
  - Se comentan (`;`) todas las líneas que contengan la palabra `FileExts`.
    Esto evita que BleachBit elimine las asociaciones de archivos personalizadas (ej. que los .pdf vuelvan a abrirse con Microsoft Edge).

---

## Estructura del proyecto

```text

Clean temps/                                     # Repositorio Git (monorepo)
├── Assets/                                      # Recursos gráficos y de marca
│   └── Common/                                  # Compartidos entre ediciones
│       ├── Icon/                                # Iconos (.ico, .png)
│       │   ├── PCBCleaner.ico                   # Icono principal del proyecto
│       │   ├── PCBNotifyAlertImage.png          # Imagen para de advertencia para notificaciones
│       │   ├── PCBNotifyErrorImage.png          # Imagen para de error para notificaciones
│       │   ├── PCBNotifyInfoImage.png           # Imagen para de información para notificaciones
│       │   ├── PCB_icon-Alert.ico               # Icono para de advertencia
│       │   ├── PCB_icon-Error.ico               # Icono para de error
│       │   └── PCB_icon-Info.ico                # Icono para de información
│       └── wizzard_branding/                    # Imágenes del asistente (varios DPI)
│           ├── png_WizardImage_dpi-XXX.png      # Imágen del lateral Wizard (Con escala de pantalla)
│           ├── png_WizardSmallImage_dpi-XXX.png # Imágen a la derecha del wizzard (Con escala de pantalla)
│           └── readme.txt                       # Información de nombres de archivo requeridos
│
├── Core/                                     # Núcleo lógico (PowerShell)
│   ├── Data/                                 # Archivos de configuración y datos
│   │   ├── bleachbit-config.psd1             # Datos para bleachbit.ini y datos de descarga
│   │   ├── bleachbit-manual-instructions.txt # Instrucciones de instalación manual de BleachBit portable
│   │   └── processes-core.psd1               # Parametros y configuraciones para cerrar procesos
│   ├── Modules/                              # Módulos reutilizables
│   │   ├── Cleaners/                         # Scripts de limpieza individuales
│   │   │   ├── Windows-error-report.psm1     # Comandos de limpieza de Reportes de Windows
│   │   │   ├── Windows-update-cache.psm1     # Comandos de limpieza para caché de Windows Update
│   │   │   ├── bleachbit-portable.psm1       # Comandos de ejecución de limpiador BleachBit
│   │   │   ├── clean-manager.psm1            # Comandos para automatizar el Liberador de espacio en Windows
│   │   │   ├── compactOs.psm1                # Comnados para ejecutr la compactación de Windows
│   │   │   ├── disable-hibernation.psm1      # Comandos para deshabilitar hibernación del dispositivo
│   │   │   ├── google-chrome.psm1            # Comandos para eliminar cache de Google Chrome
│   │   │   ├── recycle-bin.psm1              # Comandos de limpieza de papelera de reciclaje
│   │   │   ├── system-resotre-points.psm1    # Comandos para eliminar puntos de restauración del sistema
│   │   │   ├── system-temps.psm1             # Comandos para limpiar carpetas temporales y logs del sistema
│   │   │   └── winsxs.psm1                   # Comandos para borrar componentes obsoletos de Windows Update
│   │   ├── Lib/                              # Código externo (C#)
│   │   │   └── windowsim.cs                  # Librería para manejo de ventanas
│   │   ├── cleaner-display.psm1              # Funciones para mostrar elementos en pantalla
│   │   ├── cleaner-drive-utils.psm1          # Gestión de información sobre de unidades de alamacenamiento
│   │   ├── cleaner-install.psm1              # Comandos de instalación del proyecto
│   │   ├── cleaner-process.psm1              # Funciones para manejo de procesos durante la ejecución
│   │   ├── cleaner-registry.psm1             # Código relativo al manejo de detos en registro de Windows
│   │   ├── cleaner-snapshot.psm1             # Funciones para instantáneas de información en la ejecución
│   │   ├── cleaner-utils.psm1                # Utilidades adicionales para el limpiador
│   │   ├── pcb-00-bootstrap.psm1             # Funciones y utilidades de PCBogota - Inicializador
│   │   ├── pcb-Take-own.psm1                 # Funciones y utilidades de PCBogota - Manejo de Privilegios
│   │   ├── pcb-Window-sim.psm1               # Funciones y utilidades de PCBogota - Manejo de Ventanas
│   │   ├── pcb-Write-to-user.psm1            # Funciones y utilidades de PCBogota - Escritura en pantalla
│   │   └── pcb-modules-functions.psm1        # Funciones y utilidades de PCBogota - Archivos de modulos
│   └── cleaner-initialize.ps1                # Inicializador de modulos y variables para el limpiador
│
├── Editions/                    # Ediciones empaquetadas
│   └── Basic/                   # Edición de limpiador básica
│       ├── Limpiar.cmd          # Lanzador del script de Powershell
│       └── Start-BasicClean.ps1 # Script principal del Proyecto
│
├── installer/                     # Scripts del instalador (Inno Setup)
│   ├── installer-BasicEdition.iss # Instalación de edición básica
│   └── license.txt                # Licencia de uso y reconocimiento a creadores
│
├── src/                                  # Fuentes originales de recursos gráficos
│   ├── icon/                             # Iconos SVG editables
│   │   ├── SVG_icon_basicEdition.svg     # Icono principal del proyecto
│   │   ├── SVG_icon_typeAlert.svg        # Icono para de advertencia
│   │   ├── SVG_icon_typeError.svg        # Icono para de error
│   │   └── SVG_icon_typeInfo.svg         # Icono para de información
│   └── wizard branding/                  # SVG y tipografía de elementos de wizzard
│       ├── SVG_basicEdition_branding.svg # Editable para los elementos gráficos del instalador
│       └── future-earth.ttf              # Tipografía usada en los elementos gráficos
│
├── tools/                               # Utilidades no necesarias para ejecutar el limpiador
│   ├── PCB_Limpieza De Windows_TASK.xml # Muestra del XML para la tarea programada
│   └── sliming_bleachbit.ps1            # Script para obtener una versión ligera de BleachBit
│
├── LICENSE   # Licencia de uso del proyecto
└── README.md # El documento que estás leyendo
```

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un _issue_ o _pull request_ en [GitHub](https://github.com/PCBogota/pcb-cleaner).

## 📜 Licencia

Este proyecto se distribuye bajo la licencia que figura en el archivo LICENSE (y también se muestra durante la instalación).
