function Get-ElevatedPrivileges {
	<#
	.SYNOPSIS
		Eleva los privilegios del token de proceso actual.

	.DESCRIPTION
		Esta función ajusta los privilegios del token de acceso del proceso actual,
		permitiendo que el script realice operaciones que requieren privilegios elevados.
		**Precaución:** Usar esta función puede tener implicaciones de seguridad.
		Solo debe utilizarse cuando sea estrictamente necesario y con pleno conocimiento
		de los riesgos involucrados.

	.PARAMETER Privilege
		El nombre del privilegio que se va a habilitar. Este parámetro es obligatorio.
		Algunos privilegios comunes son:
			* `SeDebugPrivilege`: Permite realizar operaciones de depuración.
			* `SeTakeOwnershipPrivilege`: Permite tomar posesión de objetos.
			* `SeSecurityPrivilege`: Permite realizar tareas relacionadas con la seguridad.
		Consulta la documentación de Microsoft para obtener una lista completa de privilegios.

	.EXAMPLE
		Get-ElevatedPrivileges SeDebugPrivilege
		Habilita el privilegio de depuración para el proceso actual.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2023-08-07
		Versión: 1.0.0
		**Advertencia de seguridad:** La elevación de privilegios puede representar un riesgo
		de seguridad si se utiliza incorrectamente.  Asegúrate de comprender las implicaciones
		antes de usar esta función.  Utiliza el principio de mínimo privilegio: concede solo
		los privilegios necesarios y durante el tiempo mínimo requerido.

	.INPUTS
		System.String

	.OUTPUTS
		System.Boolean (Devuelve True si la operación fue exitosa, False si falló).

	.LINK
		(Opcional: Si hay un enlace relevante, añádelo aquí, por ejemplo a la documentación de Microsoft sobre privilegios)
	#>
	param($Privilege)
	$Definition = @"
    using System;
    using System.Runtime.InteropServices;

    public class AdjPriv {
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr rele);

        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
            internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

        [DllImport("advapi32.dll", SetLastError = true)]
            internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

        [StructLayout(LayoutKind.Sequential, Pack = 1)]
            internal struct TokPriv1Luid {
                public int Count;
                public long Luid;
                public int Attr;
            }

        internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
        internal const int TOKEN_QUERY = 0x00000008;
        internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;

        public static bool EnablePrivilege(long processHandle, string privilege) {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = new IntPtr(processHandle);
            IntPtr htok = IntPtr.Zero;
            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
            tp.Count = 1;
            tp.Luid = 0;
            tp.Attr = SE_PRIVILEGE_ENABLED;
            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            return retVal;
        }
    }
"@
	$ProcessHandle = (Get-Process -Id $pid).Handle
	$type = Add-Type $definition -PassThru
	return $type[0]::EnablePrivilege($processHandle, $Privilege)
}
