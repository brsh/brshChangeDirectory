Function Get-cdFolder {
	<#
	.SYNOPSIS
	Returns the path to the data file for Set-cdLocation

	.DESCRIPTION
	This function lists the folder where all of the directory aliases are stored.

	.EXAMPLE
	Get-cdFolder

Folder                                              Exists
------                                              ------
C:\Users\user\AppData\Roaming\brshChangeDirectory   True
	#>

	$hash = @{
		Folder = [string] ''
		Exists = [bool] $false
	}

	if ($script:cdFolder) {
		Write-Verbose "`$script:cdFolder = $($script:cdFolder)"
		$hash.Folder = $script:cdFolder
		$hash.Exists = test-path $script:cdFolder -ErrorAction SilentlyContinue
	} else {
		Write-Status -Message "cdFolder is not set." -Type 'Error' -Level 0
		Write-Status -Message "Use Set-cdFolder to correct that." -Type 'Info' -Level 1
	}
	New-Object -TypeName psobject -Property $Hash
}

Function Get-cdAlias {
	<#
	.SYNOPSIS
	Returns the list of all active directory aliases

	.DESCRIPTION
	This function will return a list of all directory aliases - those saved
	in the config files as well as those active in memory only (temp aliases).

	You can filter the list via the -Filter command - which accepts regex!

	.PARAMETER Filter
	A regex to filter the names

	.EXAMPLE
	Get-cdAlias

	Returns the full list

	.EXAMPLE
	Get-cdAlias -Filter '\d'

	Returns a list of all items with digits in the name

	.EXAMPLE
	Get-cdAlias -Filter D

	Returns a list of all items that start with D
	#>
	param (
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Get-cdAlias -Filter "$WordToComplete").Alias
				} else {
					(Get-cdAlias).Alias
				}
			})]
		[Alias('Alias', 'Name')]
		[string] $Filter = '',
		[switch] $DoNotTestExistence = $false
	)

	if ($script:InMemory.Count -gt 0) {
		$script:InMemory | ForEach-Object {
			$Dir = $_.Directory

			[bool] $Exists = $false
			if (-not $DoNoTestExistence) { $Exists = test-path $Dir -ErrorAction SilentlyContinue }
			$hash = [ordered] @{
				PathExists = $Exists
				Persist    = $false
				Alias      = $_.Alias
				Directory  = $Dir
			}
			$retval = New-Object -TypeName PSCustomObject -Property $Hash
			if ($DoNotTestExistence) {
				$retval.PSTypeNames.Insert(0, "brshCD.AliasObjectsUnVerified")
			} else {
				$retval.PSTypeNames.Insert(0, "brshCD.AliasObjects")
			}
			if ($filter) {
				if ($retval.Alias -match "^$Filter") { $retval }
			} else {
				$retval
			}
		}
	}

	$Folder = (Get-cdFolder).Folder

	if ($Folder) {
		if (test-path $Folder -ErrorAction SilentlyContinue) {
			try {
				[System.IO.FileInfo[]] $list = Get-ChildItem $Folder -Filter '*.txt' -ErrorAction Stop | Sort-Object BaseName
				if ($filter) {
					$list = $list | Where-Object { $_.BaseName -match "^$Filter" }
				}
				if ($null -ne $list) {
					$list | ForEach-Object {
						$Dir = Get-Content $_.FullName
						[bool] $Exists = $false
						if (-not $DoNoTestExistence) { $Exists = test-path $Dir -ErrorAction SilentlyContinue }
						$hash = [ordered] @{
							PathExists = $Exists
							Persist    = $True
							Alias      = $_.BaseName
							Directory  = $Dir
						}
						$retval = New-Object -TypeName PSCustomObject -Property $Hash
						if ($DoNotTestExistence) {
							$retval.PSTypeNames.Insert(0, "brshCD.AliasObjectsUnVerified")
						} else {
							$retval.PSTypeNames.Insert(0, "brshCD.AliasObjects")
						}
						$retval
					}
				}
			} catch {
				Write-Status -Message "Could not list directory!" -E $_ -Type 'Error'
			}
		} else {
			Write-Status -Message "cdFolder ($Folder) does not exist." -Type 'Error' -Level 0
			Write-Status -Message "Try Get-cdFolder or Set-cdFolder." -Type 'Info' -Level 1
		}
	} else {
		Write-Status -Message "No cdFolder defined." -Type 'Error' -Level 0
		Write-Status -Message "Try Get-cdFolder or Set-cdFolder." -Type 'Info' -Level 1
	}
}


