using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Threading;

namespace WindowSim
{
    #region PublicTypes
    public class WindowInfo
    {
        public IntPtr Handle { get; set; }
        public string Title { get; set; }
        public string ClassName { get; set; }
        public uint ProcessId { get; set; }
        public RECT Rect { get; set; }
        public bool IsVisible { get; set; }
        public bool IsMinimized { get; set; }
        public bool IsMaximized { get; set; }
        public bool IsForeground { get; set; }
        public string FrameworkId { get; set; }
    }
    #endregion

    #region Win32Structs
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct WINDOWPLACEMENT
    {
        public int length;
        public int flags;
        public int showCmd;
        public POINT ptMinPosition;
        public POINT ptMaxPosition;
        public RECT rcNormalPosition;
    }
    #endregion

    #region Win32Imports
    internal static class NativeMethods
    {
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int maxCount);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetClassName(IntPtr hWnd, StringBuilder text, int maxCount);

        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

        [DllImport("user32.dll")]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

        [DllImport("user32.dll")]
        public static extern bool IsIconic(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool IsZoomed(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool GetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT lpwndpl);

        // ====== NUEVOS EXACTOS ======
        [DllImport("kernel32.dll")]
        public static extern uint GetCurrentThreadId();

        [DllImport("user32.dll")]
        public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

        [DllImport("user32.dll")]
        public static extern bool BringWindowToTop(IntPtr hWnd);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
            int X, int Y, int cx, int cy, uint uFlags);

        [DllImport("user32.dll")]
        public static extern bool AllowSetForegroundWindow(int dwProcessId);

        [DllImport("user32.dll")]
        public static extern bool SetActiveWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern bool SwitchToThisWindow(IntPtr hWnd, bool fAltTab);

        [DllImport("user32.dll")]
        public static extern bool SetFocus(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern IntPtr GetLastActivePopup(IntPtr hWnd);

        [DllImport("user32.dll")]
        public static extern int SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll")]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

        // Constantes
        public const byte VK_MENU = 0x12;

        public const int SW_RESTORE = 9;
        public const int SW_SHOW = 5;
        public const int SW_SHOWDEFAULT = 10;
        public const int SW_SHOWNORMAL = 1;
        public const int SW_SHOWMAXIMIZED = 3;

        public const uint SWP_NOSIZE = 0x0001;
        public const uint SWP_NOMOVE = 0x0002;
        public const uint SWP_SHOWWINDOW = 0x0040;
        public const uint SWP_NOACTIVATE = 0x0010;

        public const uint WM_ACTIVATE = 0x0006;
        public const uint WA_ACTIVE = 1;
        public const uint WA_CLICKACTIVE = 2;
        public const uint KEYEVENTF_KEYUP = 0x2;

        public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        public static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);
        public static readonly IntPtr HWND_TOP = new IntPtr(0);
    }
    #endregion

    #region PublicClass
    public static class WindowHelper
    {
        public static WindowInfo[] GetWindows()
        {
            var list = new List<WindowInfo>();
            NativeMethods.EnumWindows((hWnd, lParam) =>
            {
                if (hWnd == IntPtr.Zero) return true;

                var info = new WindowInfo();
                info.Handle = hWnd;

                var sb = new StringBuilder(1024);
                NativeMethods.GetWindowText(hWnd, sb, sb.Capacity);
                info.Title = sb.ToString();

                var sbc = new StringBuilder(256);
                NativeMethods.GetClassName(hWnd, sbc, sbc.Capacity);
                info.ClassName = sbc.ToString();

                uint pid;
                NativeMethods.GetWindowThreadProcessId(hWnd, out pid);
                info.ProcessId = pid;

                RECT r;
                if (NativeMethods.GetWindowRect(hWnd, out r))
                    info.Rect = r;

                info.IsVisible = NativeMethods.IsWindowVisible(hWnd);

                WINDOWPLACEMENT wp = new WINDOWPLACEMENT();
                wp.length = Marshal.SizeOf(typeof(WINDOWPLACEMENT));
                if (NativeMethods.GetWindowPlacement(hWnd, ref wp))
                {
                    info.IsMinimized = (wp.showCmd == 2);
                    info.IsMaximized = (wp.showCmd == 3);
                }
                else
                {
                    info.IsMinimized = NativeMethods.IsIconic(hWnd);
                    info.IsMaximized = NativeMethods.IsZoomed(hWnd);
                }

                info.IsForeground = (NativeMethods.GetForegroundWindow() == hWnd);

                try
                {
                    var proc = Process.GetProcessById((int)pid);
                    info.FrameworkId = proc.ProcessName;
                }
                catch { }

                list.Add(info);
                return true;
            }, IntPtr.Zero);

            return list.ToArray();
        }

        public static WindowInfo GetActiveWindowInfo()
        {
            IntPtr h = NativeMethods.GetForegroundWindow();
            if (h == IntPtr.Zero) return null;

            var all = GetWindows();
            foreach (var w in all)
                if (w.Handle == h) return w;

            var info = new WindowInfo();
            info.Handle = h;

            var sb = new StringBuilder(1024);
            NativeMethods.GetWindowText(h, sb, sb.Capacity);
            info.Title = sb.ToString();

            var sbc = new StringBuilder(256);
            NativeMethods.GetClassName(h, sbc, sbc.Capacity);
            info.ClassName = sbc.ToString();

            uint pid;
            NativeMethods.GetWindowThreadProcessId(h, out pid);
            info.ProcessId = pid;

            RECT r;
            if (NativeMethods.GetWindowRect(h, out r)) info.Rect = r;

            WINDOWPLACEMENT wp = new WINDOWPLACEMENT();
            wp.length = Marshal.SizeOf(typeof(WINDOWPLACEMENT));
            if (NativeMethods.GetWindowPlacement(h, ref wp))
            {
                info.IsMinimized = (wp.showCmd == 2);
                info.IsMaximized = (wp.showCmd == 3);
            }
            else
            {
                info.IsMinimized = NativeMethods.IsIconic(h);
                info.IsMaximized = NativeMethods.IsZoomed(h);
            }

            info.IsVisible = NativeMethods.IsWindowVisible(h);
            info.IsForeground = true;

            return info;
        }

        // ===================== VERSIÓN MEJORADA DE BringWindowToFront =====================
        public static bool BringWindowToFront(IntPtr hWnd)
        {
            if (hWnd == IntPtr.Zero) return false;

            // Primero, obtener el estado actual de la ventana
            WINDOWPLACEMENT wp = new WINDOWPLACEMENT();
            wp.length = Marshal.SizeOf(typeof(WINDOWPLACEMENT));
            bool hasPlacement = NativeMethods.GetWindowPlacement(hWnd, ref wp);

            // Si la ventana está minimizada, restaurarla ANTES de intentar traerla al frente
            bool wasMinimized = false;
            if (hasPlacement)
            {
                wasMinimized = (wp.showCmd == 2); // SW_SHOWMINIMIZED

                if (wasMinimized)
                {
                    // Primero restaurar a estado normal
                    NativeMethods.ShowWindow(hWnd, NativeMethods.SW_RESTORE);

                    // Dar tiempo a que se complete la restauración
                    Thread.Sleep(50);

                    // Actualizar el placement después de restaurar
                    hasPlacement = NativeMethods.GetWindowPlacement(hWnd, ref wp);
                }
            }
            else
            {
                wasMinimized = NativeMethods.IsIconic(hWnd);
                if (wasMinimized)
                {
                    NativeMethods.ShowWindow(hWnd, NativeMethods.SW_RESTORE);
                    Thread.Sleep(50);
                }
            }

            // Si ya es la ventana activa, retornar true
            if (NativeMethods.GetForegroundWindow() == hWnd)
                return true;

            // Obtener información del thread y proceso
            uint targetPid;
            uint targetThread = NativeMethods.GetWindowThreadProcessId(hWnd, out targetPid);
            uint currentThread = NativeMethods.GetCurrentThreadId();

            bool attached = false;
            bool result = false;

            try
            {
                // Intentar permitir que el proceso objetivo establezca ventana foreground
                try { NativeMethods.AllowSetForegroundWindow((int)targetPid); }
                catch { }

                // Adjuntar threads si son diferentes
                if (targetThread != currentThread)
                {
                    attached = NativeMethods.AttachThreadInput(currentThread, targetThread, true);
                }

                // ESTRATEGIA 1: Intentar SetForegroundWindow directamente
                if (NativeMethods.SetForegroundWindow(hWnd))
                {
                    result = true;
                }
                else
                {
                    // ESTRATEGIA 2: Usar SwitchToThisWindow (alternativa a Alt+Tab)
                    NativeMethods.SwitchToThisWindow(hWnd, true);

                    // Dar un pequeño tiempo
                    Thread.Sleep(30);

                    // Verificar si funcionó
                    if (NativeMethods.GetForegroundWindow() == hWnd)
                    {
                        result = true;
                    }
                    else
                    {
                        // ESTRATEGIA 3: Secuencia más agresiva

                        // Asegurarse de que la ventana es visible
                        NativeMethods.ShowWindow(hWnd, NativeMethods.SW_SHOWNORMAL);

                        // Traer al tope de la Z-order
                        NativeMethods.BringWindowToTop(hWnd);

                        // Activar la ventana
                        NativeMethods.SetActiveWindow(hWnd);

                        // Enviar mensaje de activación
                        NativeMethods.SendMessage(hWnd, NativeMethods.WM_ACTIVATE,
                            new IntPtr(NativeMethods.WA_ACTIVE), IntPtr.Zero);

                        // Intentar establecer foco
                        NativeMethods.SetFocus(hWnd);

                        // Pequeña pausa
                        Thread.Sleep(20);

                        // Verificar resultado final
                        result = (NativeMethods.GetForegroundWindow() == hWnd);
                    }
                }

                // Si la ventana estaba minimizada y ahora está activa,
                // asegurarse de que esté en el estado correcto
                if (result && wasMinimized)
                {
                    // Si tenía un estado maximizado antes de minimizar, restaurarlo
                    if (hasPlacement && wp.showCmd == 3) // SW_SHOWMAXIMIZED
                    {
                        Thread.Sleep(100);
                        NativeMethods.ShowWindow(hWnd, NativeMethods.SW_SHOWMAXIMIZED);
                    }
                }

                return result;
            }
            finally
            {
                // Desadjuntar threads si fueron adjuntados
                if (attached)
                {
                    NativeMethods.AttachThreadInput(currentThread, targetThread, false);
                }
            }
        }

        // ===================== MÉTODO ALTERNATIVO ESPECÍFICO PARA VENTANAS MINIMIZADAS =====================
        public static bool RestoreAndFocusWindow(IntPtr hWnd)
        {
            if (hWnd == IntPtr.Zero) return false;

            // Verificar si está minimizada
            bool isMinimized = NativeMethods.IsIconic(hWnd);

            if (!isMinimized)
            {
                // Si no está minimizada, usar el método normal
                return BringWindowToFront(hWnd);
            }

            // Obtener el placement para restaurar al estado correcto
            WINDOWPLACEMENT wp = new WINDOWPLACEMENT();
            wp.length = Marshal.SizeOf(typeof(WINDOWPLACEMENT));

            if (NativeMethods.GetWindowPlacement(hWnd, ref wp))
            {
                // Guardar el estado de restauración (normal o maximizado)
                int restoreCmd = wp.showCmd;

                // Restaurar la ventana
                NativeMethods.ShowWindow(hWnd, NativeMethods.SW_RESTORE);

                // Pausa para que se complete la restauración
                Thread.Sleep(100);

                // Ahora traer al frente
                bool success = BringWindowToFront(hWnd);

                // Si estaba maximizada antes, restaurar ese estado
                if (success && restoreCmd == 3) // SW_SHOWMAXIMIZED
                {
                    Thread.Sleep(50);
                    NativeMethods.ShowWindow(hWnd, NativeMethods.SW_SHOWMAXIMIZED);
                }

                return success;
            }

            return false;
        }

        // ================================================================
        //public static WindowInfo FindWindowByTitle(string titleContains)
        //{
        //    if (titleContains == null) return null;
        //    var list = GetWindows();
        //    foreach (var w in list)
        //    {
        //        if (string.IsNullOrEmpty(w.Title)) continue;
        //        if (w.Title.IndexOf(titleContains, StringComparison.OrdinalIgnoreCase) >= 0)
        //            return w;
        //    }
        //    return null;
        //}
        // ================================================================

        // devuelve todas las ventanas cuyo título contenga el texto
        public static WindowInfo[] FindAllWindowsByTitle(string titleContains)
        {
            if (titleContains == null) return new WindowInfo[0];
            var list = new List<WindowInfo>();
            var all = GetWindows();
            foreach (var w in all)
            {
                if (!string.IsNullOrEmpty(w.Title) &&
                    w.Title.IndexOf(titleContains, StringComparison.OrdinalIgnoreCase) >= 0)
                    list.Add(w);
            }
            return list.ToArray();
        }

        // trae la ventana al frente con el truco de presionar Alt (mucho más fiable)
        public static bool ForceForegroundWindow(IntPtr hWnd)
        {
            if (hWnd == IntPtr.Zero) return false;

            if (NativeMethods.IsIconic(hWnd))
                NativeMethods.ShowWindow(hWnd, NativeMethods.SW_RESTORE);

            NativeMethods.ShowWindow(hWnd, NativeMethods.SW_SHOW);
            NativeMethods.BringWindowToTop(hWnd);

            // Simular Alt para obtener permiso de foreground
            NativeMethods.keybd_event(NativeMethods.VK_MENU, 0, 0, UIntPtr.Zero);
            NativeMethods.keybd_event(NativeMethods.VK_MENU, 0, NativeMethods.KEYEVENTF_KEYUP, UIntPtr.Zero);

            bool result = NativeMethods.SetForegroundWindow(hWnd);
            if (result)
            {
                NativeMethods.SetActiveWindow(hWnd);
                NativeMethods.SetFocus(hWnd);
            }
            return result;
        }

        public static WindowInfo[] FindWindowsByProcessName(string processName)
        {
            if (string.IsNullOrEmpty(processName)) return new WindowInfo[0];
            var all = GetWindows();
            var result = new List<WindowInfo>();
            foreach (var w in all)
            {
                if (string.Equals(w.FrameworkId, processName, StringComparison.OrdinalIgnoreCase))
                    result.Add(w);
            }
            return result.ToArray();
        }
    }
    #endregion
}
