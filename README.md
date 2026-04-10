# <img src="https://raw.githubusercontent.com/pcbogota/pcb-cleaner/refs/heads/main/build/PCBCleaner.ico" alt="PCB Cleaner Icon" style="width: 40px; "> PCBogota Clean Script v1.0.0

Script de limpieza y mantenimiento para Windows 10 / 11 que integra BleachBit Portable, reglas `winapp2.ini` y comandos nativos del sistema (DISM, CompactOS, vaciado de cachés, desactivación de hibernación, etc.).
Incluye un **instalador creado con Inno Setup** que permite programar la limpieza automática al inicio de sesión.

## Características principales

- Limpieza profunda del sistema sin afectar datos personales (cookies, sesiones, etc.).
- Cierre automático de Google Chrome para liberar su caché (sin borrar perfiles).
- Integración con BleachBit Portable usando la configuración predefinida (`.ini`).
- Descarga y aplicación de `winapp2.ini` (reglas de limpieza de la comunidad).
- Comandos nativos:
  - `DISM /StartComponentCleanup /ResetBase`
  - `compact /compactos:always`
  - `powercfg /h off`
  - `cleanmgr /sagerun:1`
  - `Clear-RecycleBin`
- Medición del espacio liberado paso a paso.
- Instalación con opciona de creación de tarea programada al iniciar sesión.
- Ejecución manual mediante acceso directo en escritorio / menú inicio.

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
- [BleachBit portable (.zip)](https://www.bleachbit.org/download/windows) (versión 5.0.2 o compatible)
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

1. Asegúrate de que el script `CleanTemps.ps1`, `Limpiar.cmd`, `IniData.psd1` y el icono estén en `build\`.
1. Abre `installer\installer.iss` con Inno Setup.
1. Ve al menú **Build** > **Compile** (o presiona `Ctrl+B`).

El instalador se generará en la carpeta `output\` con el nombre `Setup PCBogota Cleaner Script v1.0.0.exe` (la versión pude cambiar).

#### 💡 Personalización de la tarea programada

El instalador registra una tarea que ejecuta el script al **iniciar sesión**.
Si deseas modificar su comportamiento (horario, condiciones, etc.), edita la variable `$xml` dentro de `CleanTemps.ps1` (sección `if ($Install)`).

---

## 📄 Archivos de configuración (`.ini`)

El script de Powershell `CleanTemps.ps1` genera automáticamente dos archivos durante la instalación (`CleanTemps.ps1 -install`):

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
PCBCleaner_Project/
├── Clean temps.code-workspace  <-- Archivo de configuración de vscode para el proyecto
├── LICENSE                     <-- Licencia del proyecto
├── README.md                   <-- Este archivo
├── .gitignore                  <-- Archivo de omisión de archivos y careptas ejecutables
│
├── build/      <-- Todo lo que el instalador empaquetará
│ ├── CleanTemps.ps1             <-- Script de ejecución
│ ├── Limpiar.cmd                <-- Lanzador principal (solicita ejecución como administrador)
│ ├── IniData.psd1               <-- Datos para generar BleachBit.ini

│ └── PCBCleaner.ico             <-- Icono del proyecto
│ └── BleachBit-5.0.2-portable/  <-- Carpeta con BleachBit Portable version 5.0.2
│
├── installer/  <-- Archivos específicos para uso de Inno Setup
│ ├── installer.iss   <-- Script de compilación para el instalador
│ ├── license.txt     <-- Licencia del proyecto para el instalador (duplicado con la de la raiz de la carpeta)
│ └── assets/   <-- Imágenes para el asistente de instalación (Se deben genrar)
│   ├── png_WizardImage_dpi-xx.png        <-- Imagenes para el asistente de instalación
│   ├── png_WizardSmallImage_dpi-XXX.png  <-- Imagenes para el icono superior en el asistente de instalación
│   └── readme.txt                        <-- Listado de los archivos requeridos para el instalador
├── output/     <-- Carpeta con el ejecutable de instalación
│
├── src/        <-- Editables de diseño
│ ├── icon/     <-- Editables relacionados con el icono de la aplicación
│ │  └── SVG_icon.svg         <-- Archivo editable del icono del proyecto
│ └ wizard branding
│    └── SVG_branding.svg  <-- Archivo editable de imagenes para el instalador.
│
└── tools/      <-- Pruebas y herramientas internas
  ├── sliming_bleachbit.ps1 <-- Script de prueba para minificar BleachBit (No recomendado su uso)
  └── PCB_Windows_TASK.xml <-- XML de tarea programada de muestra
```

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un _issue_ o _pull request_ en [GitHub](https://github.com/PCBogota/pcb-cleaner).

## 📜 Licencia

Este proyecto se distribuye bajo la licencia que figura en el archivo LICENSE (y también se muestra durante la instalación).
