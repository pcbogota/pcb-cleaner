function Disable-HibernationIfConfigured {
	# Verificar estado de hibernación desde la instalación
	$regPath = "HKLM:\Software\PCBogota\PCB Cleaner"
	$userChoice = Get-ItemProperty -Path $regPath -Name "DisableHibernation" -ErrorAction SilentlyContinue
	if ($null -eq $userChoice -or $userChoice.DisableHibernation -ne 1) {
		return
	}

	# Vereficar estado actual de hibernación
	$hibernateReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -ErrorAction SilentlyContinue
	$currentlyEnabled = if ($hibernateReg) { $hibernateReg.HibernateEnabled -eq 1 } else { $true }
	if ($currentlyEnabled) {
		winfo "Desactivando hibernación del sistema." -Wider
		powercfg /hibernate off
		Set-Snapshot -Name "Deshabilitar Hibernación"

		# Cuando la hibernación está desactivada por comandos, Windows la considera una característica completamente apagada,.
		# La configuración de energía (Panel de control > Opciones de energía > Cambiar configuración del plan >
		# Cambiar configuración avanzada de energía) no muestra ningún ajuste de hibernación. Simplemente desaparece.

		# La única manera de recuperarla es desde la consola con powercfg /hibernate off.
		# Para que el limpiador no vuelva a activarla se debe modificar también HKLM\Software\PCBogota\PCB Cleaner HibernateDisabled

		# Para revertir y reactivar la hibernación manualmente (ejecutar como administrador):
		# powercfg /hibernate on; Set-ItemProperty -Path "HKLM:\Software\PCBogota\PCB Cleaner" -Name "HibernateDisabled" -Value 0
	}
}
