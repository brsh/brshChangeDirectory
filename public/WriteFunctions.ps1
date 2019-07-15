Function Set-cdFolder {
	<#
	.SYNOPSIS
	Set (and save) the location of the files that hold Directory Aliases

	.DESCRIPTION
	This will set the location of the folder that contains Directory Aliases
	files. By default, this folder is $env:APPDATA\brshChangeDirectory, but
	you can store the files elsewhere if you want.
	Your choice. Just use this command if you want something different.

	.PARAMETER file
	The folder path to use

	.PARAMETER default
	Sets the module default of $env:APPDATA\brshChangeDirectory

	.PARAMETER clobber
	Save the folder so it's the default going forward

	.EXAMPLE
	Set-cdFolder -folder c:\temp -clobber

	This will set the active folder to c:\temp and save it. C:\temp will then be the default until the next -clobber

	.EXAMPLE
	Set-cdFolder -file c:\temp

	This will set the active folder to c:\temp but not save it. The previous default file will be active at the next instantiation.

	.EXAMPLE
	Set-cdFolder -default -clobber

	Resets the saved default to $env:APPDATA\brshChangeDirectory for the active session and future sessions

	#>
	[CmdletBinding(DefaultParameterSetName = "Default")]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Set', Position = 0)]
		[ValidateNotNullOrEmpty()]
		[Alias('Directory', 'Dir')]
		[string] $folder,
		[Parameter(Mandatory = $false, ParameterSetName = 'Set')]
		[Parameter(Mandatory = $false, ParameterSetName = 'Default')]
		[Alias('Force')]
		[switch] $clobber = $false,
		[Parameter(Mandatory = $true, ParameterSetName = 'Default')]
		[switch] $default = $false
	)
	if ($PSCmdlet.ParameterSetName -eq "Default") {
		$folder = "$env:APPDATA\brshChangeDirectory"
	}

	[bool] $DoSet = $false
	if (Test-Path $folder) {
		Write-Status -Message "Folder '$folder' exists" -Type 'Good' -Level 0
		$DoSet = $true
	} else {
		Write-Status -Message "Folder '$folder' does not exist." -Type 'Error' -Level 0
		if (-not $Clobber) {
			$answer = Set-TimedPrompt -prompt "Create it?" -SecondsToWait 20 -Options 'Yes', 'No'
		}
		Write-Host ''
		if (($answer.Response -eq 'Yes') -or $clobber) {
			try {
				$created = New-Item -path "$folder" -ItemType Directory -ErrorAction Stop
				if ($created) {
					Write-Status "Folder '$folder' created." -Type 'Good' -Level 1
					$DoSet = $true
				} else {
					Write-Status -Message "Could not create '$folder'. No error returned." -Type 'Error' -Level 1
					$DoSet = $false
				}
			} catch {
				Write-Status -Message "There was an error creating '$folder'." -Type 'Error' -Level 1 -E $_
				$DoSet = $false
			}
		} else {
			Write-Status -Message "You chose No, so '$folder' NOT created." -Type 'Warning' -Level 1
			$DoSet = $false
		}
	}

	if ($DoSet) {
		$script:cdFolder = $folder
		Write-Status -Message "cdFolder is $script:cdFolder" -Type 'Info' -Level 1

		if ($clobber) {
			if (-not $(Test-Path -Path $script:ScriptPath\Config)) {
				New-Item -path $script:ScriptPath\config -ItemType Directory -ErrorAction SilentlyContinue
			}
			try {
				Set-Content -Path "$ScriptPath\Config\DataFolderPath.txt" -Value $script:cdFolder
				Write-Status -Message "The change has been saved" -Type 'Good' -Level 1
			} catch {
				Write-Status -Message "Could not save the file." -Type 'Error' -Level 1 -E $_
			}
		}
	} else {
		Write-Status -Message 'Not changing the cdFolder folder' -Type 'Warning' -Level 1
	}
}

Function Add-cdAlias {
	<#
	.SYNOPSIS
	Add a Directory Alias

	.DESCRIPTION
	To use directory aliases with this module (brshChangeDirectory, in case you didn't know),
	you first need to save some directory aliases to ... um ... use with this module. That's
	what this function does... um ... adds directory aliases.

	Directory aliases can either persist (that is, they will be saved to disk for use in every
	PowerShell session) or can evaporate when the session ends (that is, they aren't saved and
	poof - are gone when the session ends). By default, they will persist, but you can use the
	-DoNotPersist switch to ... um ... not persist ... um ... it.

	And, with that DoNotPersist switch, you can temporarily over-ride a persisted Alias. Just
	create a DoNotPersist alias (with the clobber switch to show that you mean it), and the
	Set-cdLocation function will use the non-persisted Alias over the persisted one.

	You can pipe directories to this function - but if you use PSDrives, it will map to the
	actual filesystem path - not the PSDrive path. Sorry about that. Prolly easy enough to
	fix, but I don't expect to use it much :)

	.PARAMETER Alias
	The name of the Alias - this is the shortcut alias name

	.PARAMETER Path
	The actual path the alias will refer to (as a string)

	.PARAMETER FullName
	The actual path the alias will refer to (as a string)

	.PARAMETER DoNotPersist
	Do not store this Directory Alias to disk - it will disappear when the PS session ends

	.PARAMETER Clobber
	Overwrite an existing alias if it exists

	.EXAMPLE
	Add-cdAlias -Alias 'MyDir'

	This will save the current directory under the Alias 'MyDir'

	.EXAMPLE
	Add-cdAlias -Alias 'MyHome' -Path "$env:USERPROFILE"

	This will save the current user's profile (usually c:\users\UserName) under the Alias 'MyHome'

	#>

	[CmdletBinding(DefaultParameterSetName = 'string')]
	param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'string')]
		[ValidateNotNullOrEmpty()]
		[ArgumentCompleter( {
				param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
				if ($WordToComplete) {
					(Get-cdAlias -Filter "$WordToComplete").Alias
				} else {
					(Get-cdAlias).Alias
				}
			})]
		[Alias('Name')]
		[string] $Alias,
		[Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'string')]
		[Alias('Dir', 'Directory', 'Location')]
		[string] $Path = $pwd.Path,
		[Parameter(Mandatory = $true, ParameterSetName = 'DirObject', ValueFromPipeline = $true)]
		[System.IO.DirectoryInfo] $DirectoryObject,
		[Parameter(Mandatory = $false, ParameterSetName = 'string')]
		[Parameter(Mandatory = $false, ParameterSetName = 'DirObject')]
		[Alias('InMemory')]
		[switch] $DoNotPersist = $false,
		[Parameter(Mandatory = $false, ParameterSetName = 'string')]
		[Parameter(Mandatory = $false, ParameterSetName = 'DirObject')]
		[Alias('Force')]
		[switch] $Clobber = $false,
		[Parameter(Mandatory = $false, ParameterSetName = 'string')]
		[switch] $LiteralPath = $false
	)

	if ($PSCmdlet.ParameterSetName -eq 'string') {
		if ($Path -eq '.') {
			if ($LiteralPath) {
				$Path = $pwd.ProviderPath
			} else {
				$Path = $pwd.Path
			}
		}
	} else {
		if ($null -ne $FullName) {
			$Path = $FullName.FullName
		}
	}

	[bool] $DoIt = $true

	$hash = @{
		Alias        = $Alias
		Path         = $Path
		DoNotPersist = $DoNotPersist
	}
	$Existing = get-cdAlias -filter "^$Alias$"
	if ($DoNotPersist) { $Clobber = $true }

	if ($Existing) {
		if ($Clobber) {
			Write-Status -Message "Alias Exists!" -Type 'Warning' -Level 0
			Write-Status -Message "View with `'Get-cdAlias -filter ^${Alias}`$`'" -Type 'Info' -Level 1
			try {
				if ($script:InMemory.Alias.Contains($Alias)) {
					$result = Remove-NonPersisted -Alias $Alias
					if ($result.Result -eq 'Removed') {
						Write-Status -Message 'Removed existing non-persisted Alias' -Type 'Info' -Level 1
					} else {
						Write-Status -Message "Not not remove non-persisted Alias $Alias" -Type 'Error' -Level 1
						Write-Status -Message "$($Result.Result)" -Type 'Warning' -Level 2
					}
				}
			} catch { }
		} else {
			Write-Status -Message "Alias Exists! " -Type 'Error' -Level 0
			Write-Status -Message "Please use the -Clobber switch if you want to over-write the Alias." -Type 'Info' -Level 1
		}
		$DoIt = $Clobber
	}

	if ($DoIt) {
		$retval = Set-SavedAlias @hash

		if ($retval -match "Error: ") {
			Write-Status -Message "There was an error saving the Alias." -Type 'Error' -Level 0
			Write-Status -Message  "  $retval" -Type 'Warning' -Level 1
		} else {
			Write-Status -Message "Alias has been stored!" -Type 'Good' -Level 0
			Get-cdAlias -filter "^${Alias}`$" | Where-Object { $_.Persist -ne $DoNotPersist }
		}
	} else {
		Write-Status -Message 'Not saving the Alias' -Type 'Warning' -Level 0
	}
}

