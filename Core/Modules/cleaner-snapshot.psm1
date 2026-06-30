function Get-Snapshot {
	param (
		[string]$Name,
		[object[]]$shots = $global:snapshots
	)
	if (-not $name) {
		return $shots
	}
	foreach ($s in $shots) {
		if ($s.Name -eq $Name) {
			return $s
		}
	}
	return $null
}
function Set-Snapshot {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Name,
		[object]$Dates,
		[switch]$Return
	)

	$minDates = [PSCustomObject]@{
		start  = [datetime]::Now
		finish = [datetime]::MinValue
	}

	$newDates = if ($null -eq $Dates) {
		[PSCustomObject]@{
			start  = $minDates.start
			finish = $minDates.finish
		}
	} else {
		$props = @{
			start  = $minDates.start
			finish = $minDates.finish
		}
		foreach ($prop in $Dates.PSObject.Properties) {
			$props[$prop.Name] = $prop.Value
		}
		[PSCustomObject]$props
	}

	$snapshot = [PSCustomObject]@{
		Name   = $name
		Drives = Measure-AllDrives
		Dates  = $newDates
	}
	$global:snapshots += $snapshot
	if ($Return) {
		return $snapshot
	}
}

function Set-SnapshotFinishTime {
	param (
		[string] $Name
	)
	$timeNow = [datetime]::Now
	if ($Name -ne '') {
		$shot = Get-Snapshot -Name $Name
		$Shot.Dates.Finish = $timeNow
	} elseif (($global:snapshots.Length) -ge 1) {
		($global:snapshots[-1]).Dates.Finish = $timeNow
	}
}
