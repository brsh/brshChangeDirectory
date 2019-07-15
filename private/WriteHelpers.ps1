function Set-SavedAlias {
	param(
		[string] $Alias = '',
		[string] $Path = '',
		[switch] $DoNotPersist = $false
	)
	$retval = "Error: !! Nothing Happened !!"

	# ! Needed: A way to convert Persisted to NotPersisted (and vice versa)

	if ($DoNotPersist) {
		$hash = @{
			Alias     = $Alias
			Directory = $Path
		}
		$script:InMemory += $hash
		$retval = $hash.Alias
	} else {
		if (($Alias) -and ($path)) {
			[string] $SavePath = "$($script:cdFolder)\$Alias.txt"

			try {
				$Path | Out-File $SavePath
				$retval = $SavePath
			} catch {
				$retval = "Error: $($_.Exception.Message)"
			}
		}
	}
	$retval
}

function Remove-Persisted {
	param (
		[string] $Alias,
		[switch] $Confirm = $false
	)
	$hash = [ordered] @{
		Alias = $Alias
		Type  = 'Persisted'
	}
	$cdFolder = Get-cdFolder
	if ($cdFolder.Exists) {
		try {
			$file = "$($cdFolder.Folder)\${Alias}.txt"
			Remove-Item -Path $file -Confirm:$Confirm
			$hash.Result = Switch (test-path $file) {
				$true { "!! Still Exists !!" }
				$false { "Removed" }
			}
		} catch {
			$hash.Result = "$($_.Exception.Message)"
		}
	} else {
		$hash.Result = "Alias Folder doesn't exists ?!?!"
	}

	$out = New-Object -TypeName psobject -Property $hash
	$out.PSObject.TypeNames.Insert(0, 'brshCD.RemovedAlias')
	$out
}

function Remove-NonPersisted {
	param (
		[string] $Alias
	)
	$hash = [ordered] @{
		Alias = $Alias
		Type  = 'Non-Persisted'
	}

	try {
		if ($script:InMemory.Alias.Contains($Alias)) {
			try {
				$script:InMemory = $script:InMemory | Where-Object { $_.Alias -ne $Alias }
				if ($null -eq $(Get-cdAlias -Filter "^${Alias}`$" | Where-Object { -not $_.Persist })) {
					$hash.Result = "Removed"
				} else {
					$hash.Result = "!! Still Exists !!"
				}
			} catch {
				$hash.Result = "$($_.Exception.Message)"
			}
		} else {
			$hash.Result = "Alias doesn't exists ?!?!"
		}
	} catch {
		$hash.Result = $($_.Exception.Message)
	}

	$out = New-Object -TypeName psobject -Property $hash
	$out.PSObject.TypeNames.Insert(0, 'brshCD.RemovedAlias')
	$out
}
